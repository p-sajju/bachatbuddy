const ACCESS_KEY = "bb_access_token";
const REFRESH_KEY = "bb_refresh_token";

export type AuthTokens = {
  accessToken: string;
  refreshToken: string;
};

function canUseStorage(): boolean {
  return typeof window !== "undefined" && !!window.localStorage;
}

export function getAccessToken(): string | null {
  if (!canUseStorage()) return null;
  return localStorage.getItem(ACCESS_KEY);
}

export function getRefreshToken(): string | null {
  if (!canUseStorage()) return null;
  return localStorage.getItem(REFRESH_KEY);
}

export function setTokens(tokens: AuthTokens): void {
  if (!canUseStorage()) return;
  localStorage.setItem(ACCESS_KEY, tokens.accessToken);
  localStorage.setItem(REFRESH_KEY, tokens.refreshToken);
}

export function clearTokens(): void {
  if (!canUseStorage()) return;
  localStorage.removeItem(ACCESS_KEY);
  localStorage.removeItem(REFRESH_KEY);
}

export function isAuthenticated(): boolean {
  return !!getAccessToken();
}
