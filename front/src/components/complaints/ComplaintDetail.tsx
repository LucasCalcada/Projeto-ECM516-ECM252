import { useCallback, useEffect, useId, useRef, useState, type FormEvent } from 'react';
import axios, { type AxiosResponse } from 'axios';
import { useTranslation } from 'react-i18next';
import { CheckCheck, Clock3, Send } from 'lucide-react';
import useService from '../../helpers/useService';
import {
  complaintCategories,
  type ComplaintDetail as Detail,
  type ComplaintFailure,
  type ComplaintSummary,
} from '../../types/Complaint';
import ComplaintStatusBadge from './ComplaintStatusBadge';
import ComplaintFeedback from './ComplaintFeedback';
import ComplaintConfirmation from './ComplaintConfirmation';

function readDetail(value: Detail): Detail {
  if (
    !value ||
    typeof value.id !== 'string' ||
    typeof value.title !== 'string' ||
    typeof value.description !== 'string' ||
    !Number.isFinite(Date.parse(value.createdAt)) ||
    !Number.isFinite(Date.parse(value.updatedAt)) ||
    (value.closedAt != null && !Number.isFinite(Date.parse(value.closedAt))) ||
    !Array.isArray(value.responses) ||
    !Array.isArray(value.history) ||
    value.responses.some(
      (item) =>
        !item || typeof item.message !== 'string' || !Number.isFinite(Date.parse(item.createdAt)),
    ) ||
    value.history.some((item) => !item || !Number.isFinite(Date.parse(item.createdAt)))
  )
    throw new Error('Invalid complaint');
  return {
    ...value,
    status: ['aberta', 'em_analise', 'encerrada'].includes(value.status) ? value.status : 'unknown',
    category: complaintCategories.includes(value.category as never) ? value.category : 'unknown',
    responses: value.responses.map((item) => ({
      ...item,
      isAdministrative: item.isAdministrative === true,
    })),
  };
}

export default function ComplaintDetail({
  id: complaintId,
  canRespondTo,
  canChangeStatus,
  onUpdated,
  onDirtyChange,
  onPendingChange,
  onUnauthorized,
}: {
  id: string;
  canRespondTo: (complaint: ComplaintSummary) => boolean;
  canChangeStatus: boolean;
  onUpdated: (complaint: Detail) => void;
  onDirtyChange: (dirty: boolean) => void;
  onPendingChange: (pending: boolean) => void;
  onUnauthorized: () => void;
}) {
  const { t, i18n } = useTranslation('complaints');
  const service = useService('complaint');
  const [detail, setDetail] = useState<Detail | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<ComplaintFailure | null>(null);
  const [mutationError, setMutationError] = useState<ComplaintFailure | null>(null);
  const [notice, setNotice] = useState<string | null>(null);
  const [response, setResponse] = useState('');
  const [pending, setPending] = useState(false);
  const [submitted, setSubmitted] = useState(false);
  const [needsReview, setNeedsReview] = useState(false);
  const [closing, setClosing] = useState(false);
  const [discard, setDiscard] = useState<{ action: () => void } | null>(null);
  const mounted = useRef(false);
  const locked = useRef(false);
  const request = useRef<AbortController | null>(null);
  const id = useId();
  const responseInvalid =
    !response.trim() || response.trim().length > 5000 || response.includes('\0');
  const canRespond = detail ? canRespondTo(detail) : false;
  const open = !needsReview && (detail?.status === 'aberta' || detail?.status === 'em_analise');
  const complaintDate = (value: string, language: string) =>
    new Intl.DateTimeFormat(language, { dateStyle: 'medium', timeStyle: 'short' }).format(
      new Date(value),
    );
  const onResponse = setResponse;
  useEffect(() => {
    mounted.current = true;
    return () => {
      mounted.current = false;
      request.current?.abort();
      onDirtyChange(false);
      onPendingChange(false);
    };
  }, [onDirtyChange, onPendingChange]);
  useEffect(() => {
    onDirtyChange(Boolean(response));
  }, [response, onDirtyChange]);
  useEffect(() => {
    onPendingChange(pending);
  }, [pending, onPendingChange]);

  const loadDetail = useCallback(async () => {
    request.current?.abort();
    const controller = new AbortController();
    request.current = controller;
    setLoading(true);
    setError(null);
    try {
      const result = await service.get<Detail>('/complaints/' + encodeURIComponent(complaintId), {
        signal: controller.signal,
        timeout: 15000,
      });
      if (controller.signal.aborted) return null;
      const value = readDetail(result.data);
      if (value.id !== complaintId) throw new Error('Invalid complaint id');
      setDetail(value);
      setNeedsReview(false);
      return value;
    } catch (failure) {
      if (controller.signal.aborted) return null;
      const status = axios.isAxiosError(failure) ? failure.response?.status : undefined;
      if (status === 401) {
        onUnauthorized();
        return null;
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
      if (status === 404) setDetail(null);
      return null;
    } finally {
      if (!controller.signal.aborted) setLoading(false);
    }
  }, [complaintId, onUnauthorized, service]);
  useEffect(() => {
    void loadDetail();
    return () => request.current?.abort();
  }, [loadDetail]);
  function onRetry() {
    if (!locked.current) void loadDetail();
  }

  async function save(operation: () => Promise<AxiosResponse<Detail>>, success: string) {
    if (locked.current || !open || loading) return;
    locked.current = true;
    request.current?.abort();
    setPending(true);
    setMutationError(null);
    setNotice(null);
    try {
      const result = await operation();
      if (!mounted.current) return;
      const value = readDetail(result.data);
      if (value.id !== complaintId) throw new Error('Invalid complaint id');
      setDetail(value);
      setNotice(success);
      if (success === 'responded') {
        setResponse('');
        setSubmitted(false);
        onDirtyChange(false);
      }
      onUpdated(value);
    } catch (failure) {
      if (!mounted.current) return;
      const status = axios.isAxiosError(failure) ? failure.response?.status : undefined;
      const code = axios.isAxiosError(failure) ? failure.response?.data?.error?.code : undefined;
      if (status === 401) {
        onUnauthorized();
        return;
      }
      const reason: ComplaintFailure =
        status === 403
          ? 'forbidden'
          : status === 404
            ? 'notFound'
            : status === 409
              ? code === 'response_required'
                ? 'responseRequired'
                : code === 'complaint_closed'
                  ? 'closed'
                  : 'conflict'
              : [400, 413, 415].includes(status ?? 0)
                ? 'invalid'
                : axios.isAxiosError(failure) && !failure.response
                  ? 'network'
                  : 'server';
      setMutationError(reason);
      if (['network', 'conflict', 'closed', 'responseRequired', 'server'].includes(reason)) {
        setNeedsReview(true);
        const latest = await loadDetail();
        if (latest && mounted.current) onUpdated(latest);
      }
    } finally {
      locked.current = false;
      if (mounted.current) {
        setPending(false);
        setClosing(false);
      }
    }
  }
  function submit(event: FormEvent) {
    event.preventDefault();
    setSubmitted(true);
    if (responseInvalid) {
      document.getElementById(id + '-response')?.focus();
      return;
    }
    if (!canRespond) return;
    void save(
      () =>
        service.post(
          '/complaints/' + encodeURIComponent(complaintId) + '/responses',
          { message: response.trim() },
          { timeout: 15000 },
        ),
      'responded',
    );
  }
  function changeStatus(status: 'em_analise' | 'encerrada') {
    if (
      !canChangeStatus ||
      !detail ||
      (status === 'encerrada' && !detail.responses.some((item) => item.isAdministrative))
    )
      return;
    return save(
      () =>
        service.patch(
          '/complaints/' + encodeURIComponent(complaintId) + '/status',
          { status },
          { timeout: 15000 },
        ),
      'statusChanged',
    );
  }
  function navigateSafely(action: () => void) {
    if (locked.current) return;
    if (response) setDiscard({ action });
    else action();
  }
  function onAnalyse() {
    navigateSafely(() => {
      void changeStatus('em_analise');
    });
  }
  function onClose() {
    navigateSafely(() => setClosing(true));
  }
  return (
    <section
      data-testid="complaint-detail"
      className="min-w-0 p-4"
      aria-label={t('detailTitle')}
      aria-busy={loading}
    >
      {loading && <p role="status">{t('loadingDetail')}</p>}
      <ComplaintFeedback error={error} retry={onRetry} />
      <ComplaintFeedback
        error={mutationError}
        notice={notice}
        retry={needsReview ? onRetry : undefined}
      />
      {detail && !loading && (
        <>
          <div className="mt-4 flex flex-col items-start gap-2">
            <ComplaintStatusBadge status={detail.status} />
            <p className="text-sm text-neutral-400">{t(`category.${detail.category}`)}</p>
            <h2 className="text-xl font-semibold wrap-anywhere text-neutral-100">{detail.title}</h2>
            <p className="text-xs wrap-anywhere text-neutral-400">
              {t('identifier')}: <span className="wrap-anywhere">{detail.id}</span>
            </p>
          </div>
          <dl className="mt-6 flex flex-wrap gap-x-6 gap-y-4 text-sm">
            <div>
              <dt className="mb-1 text-neutral-400">{t('createdAt')}</dt>
              <dd>
                <time dateTime={detail.createdAt}>
                  {complaintDate(detail.createdAt, i18n.language)}
                </time>
              </dd>
            </div>
            <div>
              <dt className="mb-1 text-neutral-400">{t('updatedAt')}</dt>
              <dd>
                <time dateTime={detail.updatedAt}>
                  {complaintDate(detail.updatedAt, i18n.language)}
                </time>
              </dd>
            </div>
            {detail.closedAt && (
              <div>
                <dt className="mb-1 text-neutral-400">{t('closedAt')}</dt>
                <dd>
                  <time dateTime={detail.closedAt}>
                    {complaintDate(detail.closedAt, i18n.language)}
                  </time>
                </dd>
              </div>
            )}
          </dl>
          <section className="mt-6">
            <h3 className="mb-3 text-base font-semibold text-neutral-100">
              {t('form.description')}
            </h3>
            <p className="text-base wrap-anywhere whitespace-pre-wrap">{detail.description}</p>
          </section>
          <section className="mt-6">
            <h3 className="mb-3 text-base font-semibold text-neutral-100">{t('responses')}</h3>
            {!detail.responses.length ? (
              <p className="text-base wrap-anywhere text-neutral-400">{t('noResponses')}</p>
            ) : (
              <ol className="flex list-none flex-col gap-4 p-0">
                {detail.responses.map((item) => (
                  <li key={item.id} className="flex flex-col gap-2">
                    <p className="text-xs font-semibold text-neutral-400">
                      {t(item.isAdministrative ? 'responseByBuilding' : 'responseByResidency')}
                    </p>
                    <p className="text-base wrap-anywhere whitespace-pre-wrap">{item.message}</p>
                    <time dateTime={item.createdAt} className="text-xs text-neutral-400">
                      {complaintDate(item.createdAt, i18n.language)}
                    </time>
                  </li>
                ))}
              </ol>
            )}
          </section>
          <section className="mt-6">
            <h3 className="mb-3 text-base font-semibold text-neutral-100">{t('history')}</h3>
            <ol className="flex list-none flex-col gap-4 p-0">
              {detail.history.map((item) => (
                <li key={item.id} className="flex flex-col gap-2">
                  <p>
                    {item.previousStatus
                      ? t('historyChange', {
                          previous: t(`status.${item.previousStatus}`),
                          status: t(`status.${item.status}`),
                        })
                      : t('historyCreated')}
                  </p>
                  <time dateTime={item.createdAt} className="text-xs text-neutral-400">
                    {complaintDate(item.createdAt, i18n.language)}
                  </time>
                </li>
              ))}
            </ol>
          </section>
          {(canRespond || canChangeStatus) && open && (
            <section className="mt-6">
              <h3 className="mb-3 text-base font-semibold text-neutral-100">{t('management')}</h3>
              {canRespond && (
                <form className="mt-4 flex flex-col gap-2" onSubmit={submit} noValidate>
                  <label htmlFor={`${id}-response`} className="text-sm font-medium">
                    {t('responseLabel')} *
                  </label>
                  <textarea
                    className="block min-h-11 w-full resize-y rounded-md border border-neutral-500 bg-neutral-950 px-3 py-2 text-sm text-neutral-100 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-cyan-300 disabled:cursor-not-allowed disabled:opacity-60 aria-invalid:border-red-400"
                    id={`${id}-response`}
                    value={response}
                    maxLength={5000}
                    rows={4}
                    disabled={pending}
                    required
                    onChange={(e) => onResponse(e.target.value)}
                    aria-invalid={submitted && responseInvalid}
                    aria-describedby={`${id}-response-help${submitted && responseInvalid ? ` ${id}-response-error` : ''}`}
                  />
                  <p id={`${id}-response-help`} className="text-xs wrap-anywhere text-neutral-400">
                    {t('form.counter', { length: response.length, max: 5000 })}
                  </p>
                  {submitted && responseInvalid && (
                    <p id={`${id}-response-error`} className="text-sm text-red-400">
                      {t('responseError')}
                    </p>
                  )}
                  <button
                    className="inline-flex min-h-11 min-w-11 cursor-pointer items-center justify-center gap-2 self-start rounded-md bg-cyan-300 px-3 py-2 text-sm font-semibold text-neutral-950 transition-colors hover:bg-cyan-200 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-cyan-300 disabled:cursor-not-allowed disabled:opacity-60 motion-reduce:transition-none"
                    type="submit"
                    disabled={pending}
                  >
                    <Send size={16} aria-hidden="true" />
                    {pending ? t('saving') : t('respond')}
                  </button>
                </form>
              )}
              {canChangeStatus && (
                <div className="mt-4 flex flex-wrap gap-2">
                  {detail.status === 'aberta' && (
                    <button
                      type="button"
                      className="inline-flex min-h-11 min-w-11 cursor-pointer items-center justify-center gap-2 rounded-md bg-neutral-800 px-3 py-2 text-sm font-semibold text-neutral-100 transition-colors hover:bg-neutral-700 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-cyan-300 disabled:cursor-not-allowed disabled:opacity-60 motion-reduce:transition-none"
                      disabled={pending}
                      onClick={onAnalyse}
                    >
                      <Clock3 size={16} aria-hidden="true" />
                      {t('markInReview')}
                    </button>
                  )}
                  <button
                    type="button"
                    className="inline-flex min-h-11 min-w-11 cursor-pointer items-center justify-center gap-2 rounded-md bg-neutral-800 px-3 py-2 text-sm font-semibold text-neutral-100 transition-colors hover:bg-neutral-700 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-cyan-300 disabled:cursor-not-allowed disabled:opacity-60 motion-reduce:transition-none"
                    disabled={
                      pending || !detail.responses.some((response) => response.isAdministrative)
                    }
                    aria-describedby={
                      !detail.responses.some((response) => response.isAdministrative)
                        ? `${id}-close-help`
                        : undefined
                    }
                    onClick={onClose}
                  >
                    <CheckCheck size={16} aria-hidden="true" />
                    {t('close')}
                  </button>
                </div>
              )}
              {canChangeStatus &&
                !detail.responses.some((response) => response.isAdministrative) && (
                  <p id={`${id}-close-help`} className="text-xs wrap-anywhere text-neutral-400">
                    {t('responseRequired')}
                  </p>
                )}
            </section>
          )}
          {detail.status === 'encerrada' && (
            <p className="mt-6 text-neutral-400">{t('readOnly')}</p>
          )}
          {detail.status === 'unknown' && (
            <p className="mt-6 text-neutral-400">{t('unknownStatus')}</p>
          )}
        </>
      )}
      {discard && (
        <ComplaintConfirmation
          title={t('discardTitle')}
          message={t('discardMessage')}
          confirmLabel={t('discard')}
          onCancel={() => setDiscard(null)}
          onConfirm={() => {
            const action = discard.action;
            setDiscard(null);
            setResponse('');
            action();
          }}
        />
      )}
      {closing && (
        <ComplaintConfirmation
          title={t('closeTitle')}
          message={t('closeMessage', { title: detail?.title })}
          confirmLabel={t('close')}
          pending={pending}
          onCancel={() => setClosing(false)}
          onConfirm={() => {
            void changeStatus('encerrada');
          }}
        />
      )}
    </section>
  );
}
