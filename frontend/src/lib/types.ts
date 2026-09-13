export type ApiError = {
  code: string;
  message: string;
  fields?: Record<string, string[]>;
};

export type ApiEnvelope<T> = {
  data: T;
  meta?: Record<string, unknown>;
  errors?: ApiError[];
};

export type User = {
  id: string;
  email: string;
  name: string | null;
  timezone: string;
  onboarding_completed?: boolean;
  created_at?: string;
};

export type AuthPayload = {
  user: User;
  access_token: string;
  refresh_token: string;
};

export type Category = {
  id: string;
  name: string;
  kind: "expense" | "income";
  icon?: string | null;
};

export type PaymentSource = {
  id: string;
  name: string;
  kind?: string;
};

export type Person = {
  id: string;
  name: string;
  relationship?: string | null;
  notes?: string | null;
  total_spent_paise?: number;
};

export type Income = {
  id: string;
  amount_paise: number;
  received_on: string;
  source?: string | null;
  note?: string | null;
  category_id?: string | null;
  payment_source_id?: string | null;
  category?: Category | null;
  payment_source?: PaymentSource | null;
};

export type Expense = {
  id: string;
  amount_paise: number;
  spent_on: string;
  note?: string | null;
  category_id?: string | null;
  person_id?: string | null;
  payment_source_id?: string | null;
  category?: Category | null;
  person?: Person | null;
  payment_source?: PaymentSource | null;
};

export type TransactionItem =
  | ({ type: "income" } & Income)
  | ({ type: "expense" } & Expense);

export type SavingsGoal = {
  id: string;
  name: string;
  target_paise: number;
  current_paise: number;
  target_date?: string | null;
  monthly_contribution_paise?: number;
  suggested_contribution_paise?: number;
  status?: string;
  notes?: string | null;
};

export type MoneyLock = {
  id: string;
  name: string;
  amount_paise: number;
  purpose?: string | null;
  status: "active" | "unlock_requested" | "unlocked" | "expired" | "cancelled";
  savings_goal_id?: string | null;
  unlock_available_at?: string | null;
  created_at?: string;
};

export type UnlockPreview = {
  lock: MoneyLock;
  cooling_off_hours?: number;
  requires_confirmation_phrase?: boolean;
  confirmation_phrase?: string;
  warnings?: string[];
};

export type RecurringExpense = {
  id: string;
  name: string;
  amount_paise: number;
  cadence: string;
  next_due_on?: string | null;
  category_id?: string | null;
  person_id?: string | null;
  active?: boolean;
  category?: Category | null;
  person?: Person | null;
};

export type NotificationItem = {
  id: string;
  title: string;
  body: string;
  kind?: string;
  read_at?: string | null;
  created_at: string;
};

export type DashboardInsight = {
  kind?: string;
  title: string;
  body: string;
};

export type DashboardSummary = {
  safe_to_spend_paise: number;
  income_paise: number;
  expenses_paise: number;
  locked_paise: number;
  saved_paise: number;
  period?: { start: string; end: string };
  breakdown?: Record<string, number>;
  top_spending?: { category_id?: string; name: string; amount_paise: number }[];
  protected_locks?: MoneyLock[];
  goals?: SavingsGoal[];
  insights?: DashboardInsight[];
  disclaimer?: string;
};

export type ReportSummary = {
  period: { start: string; end: string; label?: string };
  income_paise: number;
  expenses_paise: number;
  net_paise: number;
  by_category?: { name: string; amount_paise: number }[];
  by_person?: { name: string; amount_paise: number }[];
};
