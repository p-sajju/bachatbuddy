import {
  clearTokens,
  getAccessToken,
  getRefreshToken,
  setTokens,
} from "./auth";
import type { ApiEnvelope, ApiError } from "./types";

const API_BASE =
  process.env.NEXT_PUBLIC_API_URL?.replace(/\/$/, "") ||
  "http://localhost:3000";

export class ApiRequestError extends Error {
  status: number;
  errors: ApiError[];
  requestId?: string;

  constructor(
    message: string,
    status: number,
    errors: ApiError[] = [],
    requestId?: string,
  ) {
    super(message);
    this.name = "ApiRequestError";
    this.status = status;
    this.errors = errors;
    this.requestId = requestId;
  }
}

type RequestOptions = {
  method?: string;
  body?: unknown;
  auth?: boolean;
  idempotency?: boolean | string;
  headers?: Record<string, string>;
  signal?: AbortSignal;
};

let refreshPromise: Promise<boolean> | null = null;

async function refreshAccessToken(): Promise<boolean> {
  const refreshToken = getRefreshToken();
  if (!refreshToken) return false;

  try {
    const res = await fetch(`${API_BASE}/api/v1/auth/refresh`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Accept: "application/json",
      },
      body: JSON.stringify({ refresh_token: refreshToken }),
    });

    if (!res.ok) {
      clearTokens();
      return false;
    }

    const json = (await res.json()) as ApiEnvelope<{
      access_token: string;
      refresh_token: string;
    }>;

    if (!json.data?.access_token || !json.data?.refresh_token) {
      clearTokens();
      return false;
    }

    setTokens({
      accessToken: json.data.access_token,
      refreshToken: json.data.refresh_token,
    });
    return true;
  } catch {
    clearTokens();
    return false;
  }
}

function ensureRefresh(): Promise<boolean> {
  if (!refreshPromise) {
    refreshPromise = refreshAccessToken().finally(() => {
      refreshPromise = null;
    });
  }
  return refreshPromise;
}

export async function api<T>(
  path: string,
  options: RequestOptions = {},
): Promise<ApiEnvelope<T>> {
  const method = (options.method || "GET").toUpperCase();
  const useAuth = options.auth !== false;
  const headers: Record<string, string> = {
    Accept: "application/json",
    ...options.headers,
  };

  if (options.body !== undefined) {
    headers["Content-Type"] = "application/json";
  }

  if (useAuth) {
    const token = getAccessToken();
    if (token) headers.Authorization = `Bearer ${token}`;
  }

  const isMutating = method === "POST" || method === "PUT" || method === "PATCH";
  if (isMutating && options.idempotency !== false) {
    const key =
      typeof options.idempotency === "string"
        ? options.idempotency
        : crypto.randomUUID();
    headers["Idempotency-Key"] = key;
  }

  const url = path.startsWith("http")
    ? path
    : `${API_BASE}${path.startsWith("/") ? path : `/${path}`}`;

  const doFetch = () =>
    fetch(url, {
      method,
      headers,
      body: options.body !== undefined ? JSON.stringify(options.body) : undefined,
      signal: options.signal,
    });

  let res = await doFetch();

  if (res.status === 401 && useAuth && getRefreshToken()) {
    const ok = await ensureRefresh();
    if (ok) {
      const token = getAccessToken();
      if (token) headers.Authorization = `Bearer ${token}`;
      if (isMutating && options.idempotency !== false) {
        // Keep same idempotency key on retry
      }
      res = await doFetch();
    }
  }

  const requestId = res.headers.get("X-Request-Id") || undefined;
  let json: ApiEnvelope<T> | null = null;
  const text = await res.text();
  if (text) {
    try {
      json = JSON.parse(text) as ApiEnvelope<T>;
    } catch {
      throw new ApiRequestError(
        "Invalid JSON response from API",
        res.status,
        [],
        requestId,
      );
    }
  }

  if (!res.ok) {
    const errors = json?.errors || [
      { code: "http_error", message: res.statusText || "Request failed" },
    ];
    if (res.status === 401) clearTokens();
    throw new ApiRequestError(
      errors[0]?.message || "Request failed",
      res.status,
      errors,
      requestId,
    );
  }

  return (
    json ||
    ({ data: null as T, meta: {}, errors: [] } as ApiEnvelope<T>)
  );
}

export const apiGet = <T>(path: string, opts?: Omit<RequestOptions, "method" | "body">) =>
  api<T>(path, { ...opts, method: "GET" });

export const apiPost = <T>(
  path: string,
  body?: unknown,
  opts?: Omit<RequestOptions, "method" | "body">,
) => api<T>(path, { ...opts, method: "POST", body });

export const apiPatch = <T>(
  path: string,
  body?: unknown,
  opts?: Omit<RequestOptions, "method" | "body">,
) => api<T>(path, { ...opts, method: "PATCH", body, idempotency: false });

export const apiDelete = <T>(
  path: string,
  opts?: Omit<RequestOptions, "method" | "body">,
) => api<T>(path, { ...opts, method: "DELETE", idempotency: false });

/** Multipart upload (e.g. profile photo). Do not set Content-Type — browser sets boundary. */
export async function apiUpload<T>(
  path: string,
  formData: FormData,
  method: "POST" | "PUT" | "PATCH" = "POST",
): Promise<ApiEnvelope<T>> {
  const headers: Record<string, string> = { Accept: "application/json" };
  const token = getAccessToken();
  if (token) headers.Authorization = `Bearer ${token}`;
  headers["Idempotency-Key"] = crypto.randomUUID();

  const url = path.startsWith("http")
    ? path
    : `${API_BASE}${path.startsWith("/") ? path : `/${path}`}`;

  let res = await fetch(url, { method, headers, body: formData });

  if (res.status === 401 && getRefreshToken()) {
    const ok = await ensureRefresh();
    if (ok) {
      const t = getAccessToken();
      if (t) headers.Authorization = `Bearer ${t}`;
      res = await fetch(url, { method, headers, body: formData });
    }
  }

  const requestId = res.headers.get("X-Request-Id") || undefined;
  const text = await res.text();
  let json: ApiEnvelope<T> | null = null;
  if (text) {
    try {
      json = JSON.parse(text) as ApiEnvelope<T>;
    } catch {
      throw new ApiRequestError("Invalid JSON response from API", res.status, [], requestId);
    }
  }

  if (!res.ok) {
    const errors = json?.errors || [
      { code: "http_error", message: res.statusText || "Upload failed" },
    ];
    throw new ApiRequestError(errors[0]?.message || "Upload failed", res.status, errors, requestId);
  }

  return json || ({ data: null as T, meta: {}, errors: [] } as ApiEnvelope<T>);
}

export { API_BASE };
