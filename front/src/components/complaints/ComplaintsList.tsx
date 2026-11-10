import { useCallback, useEffect, useId, useRef, useState } from 'react';
import axios from 'axios';
import { ChevronDown, Inbox, RefreshCw } from 'lucide-react';
import { useTranslation } from 'react-i18next';
import useService from '../../helpers/useService';
import {
  complaintCategories,
  type ComplaintDetail as Detail,
  type ComplaintFailure,
  type ComplaintFilters,
  type ComplaintScope,
  type ComplaintSummary,
} from '../../types/Complaint';
import ComplaintStatusBadge from './ComplaintStatusBadge';
import ComplaintFeedback from './ComplaintFeedback';
import ComplaintDetail from './ComplaintDetail';
import ComplaintConfirmation from './ComplaintConfirmation';

export default function ComplaintsList({
  scope,
  canRespondTo,
  canChangeStatus,
  onDirtyChange,
  onPendingChange,
  onUnauthorized,
}: {
  scope: ComplaintScope;
  canRespondTo: (complaint: ComplaintSummary) => boolean;
  canChangeStatus: boolean;
  onDirtyChange: (dirty: boolean) => void;
  onPendingChange: (pending: boolean) => void;
  onUnauthorized: () => void;
}) {
  const { t, i18n } = useTranslation('complaints');
  const service = useService('complaint');
  const [items, setItems] = useState<ComplaintSummary[]>([]);
  const [filters, setFilters] = useState<ComplaintFilters>({ status: '', category: '' });
  const [selectedId, setSelectedId] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<ComplaintFailure | null>(null);
  const [hasMore, setHasMore] = useState(false);
  const [disabled, setDisabled] = useState(false);
  const [dirty, setDirty] = useState(false);
  const [discard, setDiscard] = useState<{ action: () => void } | null>(null);
  const request = useRef<AbortController | null>(null);
  const offset = useRef(0);
  const listId = useId();
  const handleDirtyChange = useCallback(
    (value: boolean) => {
      setDirty(value);
      onDirtyChange(value);
    },
    [onDirtyChange],
  );
  const handlePendingChange = useCallback(
    (value: boolean) => {
      setDisabled(value);
      if (value) {
        request.current?.abort();
        setLoading(false);
      }
      onPendingChange(value);
    },
    [onPendingChange],
  );
  const fetchComplaints = useCallback(
    async (append = false) => {
      request.current?.abort();
      const controller = new AbortController();
      request.current = controller;
      setLoading(true);
      setError(null);
      const start = append ? offset.current : 0;
      try {
        const result = await service.get<ComplaintSummary[]>(
          scope === 'mine' ? '/complaints/residency' : '/complaints',
          {
            params: {
              ...(filters.status ? { status: filters.status } : {}),
              ...(filters.category ? { category: filters.category } : {}),
              offset: start,
              limit: 20,
            },
            signal: controller.signal,
            timeout: 15000,
          },
        );
        if (controller.signal.aborted) return;
        if (
          !Array.isArray(result.data) ||
          result.data.some(
            (item) =>
              !item ||
              typeof item.id !== 'string' ||
              typeof item.title !== 'string' ||
              !Number.isFinite(Date.parse(item.createdAt)),
          )
        )
          throw new Error('Invalid complaints');
        const rows = result.data.map(
          (item) =>
            ({
              ...item,
              status: ['aberta', 'em_analise', 'encerrada'].includes(item.status)
                ? item.status
                : 'unknown',
              category: complaintCategories.includes(item.category as never)
                ? item.category
                : 'unknown',
            }) as ComplaintSummary,
        );
        offset.current = start + rows.length;
        setHasMore(rows.length === 20);
        setItems((previous) => [
          ...new Map(
            (append ? [...previous, ...rows] : rows).map((item) => [item.id, item]),
          ).values(),
        ]);
      } catch (failure) {
        if (controller.signal.aborted) return;
        const status = axios.isAxiosError(failure) ? failure.response?.status : undefined;
        if (status === 401) {
          onUnauthorized();
          return;
        }
        setError(
          status === 403
            ? 'forbidden'
            : status === 404
              ? 'notFound'
              : axios.isAxiosError(failure) && !failure.response
                ? 'network'
                : 'server',
        );
      } finally {
        if (!controller.signal.aborted) setLoading(false);
      }
    },
    [filters, onUnauthorized, scope, service],
  );
  useEffect(() => {
    void fetchComplaints();
    return () => request.current?.abort();
  }, [fetchComplaints]);
  function navigateSafely(action: () => void) {
    if (disabled) return;
    if (dirty) setDiscard({ action });
    else action();
  }
  function onFilters(next: ComplaintFilters) {
    navigateSafely(() => {
      setSelectedId(null);
      setItems([]);
      setHasMore(false);
      setFilters(next);
    });
  }
  function onSelect(id: string) {
    navigateSafely(() => setSelectedId((previous) => (previous === id ? null : id)));
  }
  function onRefresh() {
    void fetchComplaints();
  }
  function onMore() {
    if (hasMore && !loading && !disabled) void fetchComplaints(true);
  }
  const handleUpdated = useCallback(
    (detail: Detail) => {
      setItems((previous) => previous.map((item) => (item.id === detail.id ? detail : item)));
      void fetchComplaints();
    },
    [fetchComplaints],
  );
  return (
    <section
      data-testid="complaint-list"
      className="@container min-w-0 rounded-lg bg-neutral-900 p-4"
      aria-label={t('listTitle')}
      aria-busy={loading}
    >
      <div className="mb-4 flex flex-wrap items-center justify-between gap-3">
        <h2 className="text-xl font-semibold wrap-anywhere text-neutral-100">{t('listTitle')}</h2>
        <button
          type="button"
          className="inline-flex min-h-11 min-w-11 cursor-pointer items-center justify-center gap-2 rounded-md bg-neutral-800 px-3 py-2 text-sm font-semibold text-neutral-100 transition-colors hover:bg-neutral-700 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-cyan-300 disabled:cursor-not-allowed disabled:opacity-60 motion-reduce:transition-none"
          disabled={disabled || loading}
          onClick={onRefresh}
        >
          <RefreshCw size={16} aria-hidden="true" />
          {t('refresh')}
        </button>
      </div>
      <div className="mb-4 grid grid-cols-1 gap-3 @sm:grid-cols-2">
        <label className="text-sm font-medium">
          {t('filter.status')}
          <select
            className="mt-2 block min-h-11 w-full rounded-md border border-neutral-500 bg-neutral-950 px-3 py-2 text-sm text-neutral-100 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-cyan-300 disabled:cursor-not-allowed disabled:opacity-60"
            value={filters.status}
            disabled={disabled}
            onChange={(e) => onFilters({ ...filters, status: e.target.value })}
          >
            <option value="">{t('all')}</option>
            {(['aberta', 'em_analise', 'encerrada'] as const).map((status) => (
              <option key={status} value={status}>
                {t(`status.${status}`)}
              </option>
            ))}
          </select>
        </label>
        <label className="text-sm font-medium">
          {t('filter.category')}
          <select
            className="mt-2 block min-h-11 w-full rounded-md border border-neutral-500 bg-neutral-950 px-3 py-2 text-sm text-neutral-100 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-cyan-300 disabled:cursor-not-allowed disabled:opacity-60"
            value={filters.category}
            disabled={disabled}
            onChange={(e) => onFilters({ ...filters, category: e.target.value })}
          >
            <option value="">{t('all')}</option>
            {complaintCategories.map((category) => (
              <option key={category} value={category}>
                {t(`category.${category}`)}
              </option>
            ))}
          </select>
        </label>
      </div>
      {(filters.status || filters.category) && (
        <button
          type="button"
          disabled={disabled}
          className="inline-flex min-h-11 min-w-11 cursor-pointer items-center justify-center gap-2 rounded-md px-3 py-2 text-sm font-semibold text-neutral-300 transition-colors hover:bg-neutral-700 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-cyan-300 disabled:cursor-not-allowed disabled:opacity-60 motion-reduce:transition-none"
          onClick={() => onFilters({ status: '', category: '' })}
        >
          {t('clearFilters')}
        </button>
      )}
      <ComplaintFeedback error={error} retry={onRefresh} />
      {loading && (
        <p role="status" className="text-base wrap-anywhere text-neutral-400">
          {items.length ? t('updating') : t('loading')}
        </p>
      )}
      {!loading && !error && !items.length && (
        <div className="flex flex-col items-center justify-center gap-4 px-4 py-8 text-center text-neutral-400">
          <Inbox size={32} aria-hidden="true" />
          <p>{filters.status || filters.category ? t('filteredEmpty') : t('empty')}</p>
        </div>
      )}
      <ul className="mt-4 flex list-none flex-col gap-3 p-0">
        {items.map((item) => (
          <li key={item.id} className="min-w-0 rounded-lg bg-neutral-950">
            <button
              data-complaint-id={item.id}
              className="group flex min-h-11 w-full cursor-pointer flex-col gap-2 rounded-lg bg-neutral-950 p-4 text-start text-neutral-300 hover:bg-neutral-800 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-cyan-300 disabled:cursor-not-allowed disabled:opacity-60 aria-expanded:bg-neutral-800"
              disabled={disabled}
              type="button"
              aria-expanded={selectedId === item.id}
              aria-controls={`${listId}-${item.id}`}
              onClick={() => onSelect(item.id)}
            >
              <span className="flex items-center justify-between gap-2">
                <span className="text-base font-semibold wrap-anywhere text-neutral-100">
                  {item.title}
                </span>
                <ChevronDown
                  size={18}
                  className="shrink-0 group-aria-expanded:rotate-180"
                  aria-hidden="true"
                />
              </span>
              <span className="text-sm text-neutral-400">{t(`category.${item.category}`)}</span>
              <span className="flex flex-wrap items-center justify-between gap-2">
                <ComplaintStatusBadge status={item.status} />
                <time dateTime={item.createdAt} className="text-xs text-neutral-400">
                  {new Intl.DateTimeFormat(i18n.language, {
                    dateStyle: 'medium',
                    timeStyle: 'short',
                  }).format(new Date(item.createdAt))}
                </time>
              </span>
            </button>
            <div id={`${listId}-${item.id}`} className="min-w-0" hidden={selectedId !== item.id}>
              {selectedId === item.id && (
                <ComplaintDetail
                  key={item.id}
                  id={item.id}
                  canRespondTo={canRespondTo}
                  canChangeStatus={canChangeStatus}
                  onUpdated={handleUpdated}
                  onDirtyChange={handleDirtyChange}
                  onPendingChange={handlePendingChange}
                  onUnauthorized={onUnauthorized}
                />
              )}
            </div>
          </li>
        ))}
      </ul>
      {discard && (
        <ComplaintConfirmation
          title={t('discardTitle')}
          message={t('discardMessage')}
          confirmLabel={t('discard')}
          onCancel={() => setDiscard(null)}
          onConfirm={() => {
            const action = discard.action;
            setDiscard(null);
            handleDirtyChange(false);
            action();
          }}
        />
      )}
      {hasMore && (
        <button
          type="button"
          className="mx-auto mt-4 flex min-h-11 min-w-11 cursor-pointer items-center justify-center gap-2 rounded-md bg-neutral-800 px-3 py-2 text-sm font-semibold text-neutral-100 transition-colors hover:bg-neutral-700 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-cyan-300 disabled:cursor-not-allowed disabled:opacity-60 motion-reduce:transition-none"
          disabled={loading || disabled}
          onClick={onMore}
        >
          {t('loadMore')}
        </button>
      )}
    </section>
  );
}
