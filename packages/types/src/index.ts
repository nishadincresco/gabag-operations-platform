// Shared types for GABAG Operations Platform.
// Add cross-package types here (e.g. API request/response shapes, validation schemas).

export type ID = string;

export interface Paginated<T> {
  items: T[];
  total: number;
  page: number;
  pageSize: number;
}
