export const complaintCategories = [
  'barulho',
  'limpeza',
  'convivencia',
  'areas_comuns',
  'seguranca',
  'outros',
] as const;
export type ComplaintCategory = (typeof complaintCategories)[number];
export type ComplaintStatus = 'aberta' | 'em_analise' | 'encerrada' | 'unknown';
export type ComplaintScope = 'mine' | 'building';
export interface ComplaintSummary {
  id: string;
  title: string;
  category: ComplaintCategory | 'unknown';
  description: string;
  status: ComplaintStatus;
  createdAt: string;
  updatedAt: string;
  closedAt: string | null;
}
export interface ComplaintResponse {
  id: string;
  message: string;
  createdAt: string;
}
export interface ComplaintHistory {
  id: string;
  previousStatus: ComplaintStatus | null;
  status: ComplaintStatus;
  createdAt: string;
}
export interface ComplaintDetail extends ComplaintSummary {
  responses: ComplaintResponse[];
  history: ComplaintHistory[];
}
export interface ComplaintFilters {
  status: string;
  category: string;
}
export interface ComplaintDraft {
  title: string;
  category: string;
  description: string;
}
export type ComplaintFailure =
  | 'invalid'
  | 'unauthorized'
  | 'forbidden'
  | 'notFound'
  | 'conflict'
  | 'responseRequired'
  | 'closed'
  | 'network'
  | 'server';
