import axios, { type AxiosInstance } from 'axios';
import {
  complaintCategories,
  type ComplaintDetail,
  type ComplaintDraft,
  type ComplaintFailure,
  type ComplaintFilters,
  type ComplaintScope,
  type ComplaintStatus,
  type ComplaintSummary,
} from '../types/Complaint';

export class ComplaintRequestError extends Error {
  readonly reason: ComplaintFailure;
  readonly status: number | undefined;
  constructor(reason: ComplaintFailure, status?: number) {
    super(reason);
    this.reason = reason;
    this.status = status;
  }
}
function record(value: unknown): Record<string, unknown> {
  if (!value || typeof value !== 'object' || Array.isArray(value))
    throw new ComplaintRequestError('server');
  return value as Record<string, unknown>;
}
function text(value: unknown): string {
  if (typeof value !== 'string') throw new ComplaintRequestError('server');
  return value;
}
function date(value: unknown): string {
  const result = text(value);
  if (!Number.isFinite(Date.parse(result))) throw new ComplaintRequestError('server');
  return result;
}
function status(value: unknown): ComplaintStatus {
  return value === 'aberta' || value === 'em_analise' || value === 'encerrada' ? value : 'unknown';
}
function summary(value: unknown): ComplaintSummary {
  const dto = record(value);
  return {
    id: text(dto.id),
    title: text(dto.title),
    description: text(dto.description),
    category: complaintCategories.includes(dto.category as never)
      ? (dto.category as ComplaintSummary['category'])
      : 'unknown',
    status: status(dto.status),
    createdAt: date(dto.createdAt),
    updatedAt: date(dto.updatedAt),
    closedAt: dto.closedAt == null ? null : date(dto.closedAt),
  };
}
function detail(value: unknown): ComplaintDetail {
  const dto = record(value);
  if (!Array.isArray(dto.responses) || !Array.isArray(dto.history))
    throw new ComplaintRequestError('server');
  return {
    ...summary(dto),
    responses: dto.responses.map((value) => {
      const row = record(value);
      return { id: text(row.id), message: text(row.message), createdAt: date(row.createdAt) };
    }),
    history: dto.history.map((value) => {
      const row = record(value);
      return {
        id: text(row.id),
        previousStatus: row.previousStatus == null ? null : status(row.previousStatus),
        status: status(row.status),
        createdAt: date(row.createdAt),
      };
    }),
  };
}
function failure(error: unknown): ComplaintRequestError {
  if (error instanceof ComplaintRequestError) return error;
  if (!axios.isAxiosError(error)) return new ComplaintRequestError('server');
  const httpStatus = error.response?.status;
  const code = error.response?.data?.error?.code;
  if (httpStatus === 401) return new ComplaintRequestError('unauthorized', httpStatus);
  if (httpStatus === 403) return new ComplaintRequestError('forbidden', httpStatus);
  if (httpStatus === 404) return new ComplaintRequestError('notFound', httpStatus);
  if (httpStatus === 409)
    return new ComplaintRequestError(
      code === 'response_required'
        ? 'responseRequired'
        : code === 'complaint_closed'
          ? 'closed'
          : 'conflict',
      httpStatus,
    );
  if (httpStatus === 400 || httpStatus === 413 || httpStatus === 415)
    return new ComplaintRequestError('invalid', httpStatus);
  return new ComplaintRequestError(httpStatus ? 'server' : 'network', httpStatus);
}

export function createComplaintsRepository(client: AxiosInstance) {
  async function request<T>(operation: () => Promise<T>): Promise<T> {
    try {
      return await operation();
    } catch (error) {
      throw failure(error);
    }
  }
  return {
    list: (
      scope: ComplaintScope,
      filters: ComplaintFilters,
      offset: number,
      limit: number,
      signal?: AbortSignal,
    ) =>
      request(async () => {
        const params = {
          ...(filters.status ? { status: filters.status } : {}),
          ...(filters.category ? { category: filters.category } : {}),
          limit,
          offset,
        };
        const response = await client.get<unknown>(
          scope === 'mine' ? '/complaints/mine' : '/complaints',
          { params, signal, timeout: 15000 },
        );
        if (!Array.isArray(response.data)) throw new ComplaintRequestError('server');
        return response.data.map(summary);
      }),
    getDetail: (id: string, signal?: AbortSignal) =>
      request(async () =>
        detail(
          (await client.get(`/complaints/${encodeURIComponent(id)}`, { signal, timeout: 15000 }))
            .data,
        ),
      ),
    create: (draft: ComplaintDraft) =>
      request(async () =>
        detail(
          (
            await client.post(
              '/complaints',
              {
                title: draft.title.trim(),
                category: draft.category,
                description: draft.description.trim(),
              },
              { timeout: 15000 },
            )
          ).data,
        ),
      ),
    respond: (id: string, message: string) =>
      request(async () =>
        detail(
          (
            await client.post(
              `/complaints/${encodeURIComponent(id)}/responses`,
              { message: message.trim() },
              { timeout: 15000 },
            )
          ).data,
        ),
      ),
    changeStatus: (id: string, nextStatus: 'em_analise' | 'encerrada') =>
      request(async () =>
        detail(
          (
            await client.patch(
              `/complaints/${encodeURIComponent(id)}/status`,
              { status: nextStatus },
              { timeout: 15000 },
            )
          ).data,
        ),
      ),
  };
}
export type ComplaintsRepository = ReturnType<typeof createComplaintsRepository>;
