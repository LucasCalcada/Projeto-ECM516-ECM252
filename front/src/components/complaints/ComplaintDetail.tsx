import { useEffect, useId, useRef, useState, type FormEvent } from 'react';
import { useTranslation } from 'react-i18next';
import { ArrowLeft, CheckCheck, Clock3, Send } from 'lucide-react';
import type { ComplaintDetail as Detail, ComplaintFailure } from '../../types/Complaint';
import ComplaintStatusBadge from './ComplaintStatusBadge';
import ComplaintFeedback from './ComplaintFeedback';
import complaintDate from '../../helpers/formatComplaintDate';

export default function ComplaintDetail({
  detail,
  loading,
  error,
  pending,
  canManage,
  response,
  onResponse,
  onSend,
  onAnalyse,
  onClose,
  onBack,
  onRetry,
}: {
  detail: Detail | null;
  loading: boolean;
  error: ComplaintFailure | null;
  pending: boolean;
  canManage: boolean;
  response: string;
  onResponse: (text: string) => void;
  onSend: () => void;
  onAnalyse: () => void;
  onClose: () => void;
  onBack: () => void;
  onRetry: () => void;
}) {
  const { t, i18n } = useTranslation('complaints');
  const [submitted, setSubmitted] = useState(false);
  const id = useId();
  const heading = useRef<HTMLHeadingElement>(null);
  const detailId = detail?.id;
  useEffect(() => {
    if (detailId && !loading) heading.current?.focus();
  }, [detailId, loading]);
  const responseInvalid =
    !response.trim() || response.trim().length > 5000 || response.includes('\0');
  function submit(event: FormEvent) {
    event.preventDefault();
    setSubmitted(true);
    if (responseInvalid) {
      document.getElementById(`${id}-response`)?.focus();
      return;
    }
    setSubmitted(false);
    onSend();
  }
  const open = detail?.status === 'aberta' || detail?.status === 'em_analise';
  return (
    <section
      className="complaint-panel complaint-detail"
      aria-label={t('detailTitle')}
      aria-busy={loading}
    >
      <button
        type="button"
        className="complaint-button complaint-tertiary complaint-detail-back"
        disabled={pending}
        onClick={onBack}
      >
        <ArrowLeft size={16} aria-hidden="true" />
        {t('back')}
      </button>
      {loading && <p role="status">{t('loadingDetail')}</p>}
      <ComplaintFeedback error={error} retry={onRetry} />
      {detail && !loading && (
        <>
          <div className="complaint-detail-heading">
            <ComplaintStatusBadge status={detail.status} />
            <p className="complaint-item-category">{t(`category.${detail.category}`)}</p>
            <h2 ref={heading} tabIndex={-1}>
              {detail.title}
            </h2>
            <p className="complaint-help">
              {t('identifier')}: <span className="complaint-identifier">{detail.id}</span>
            </p>
          </div>
          <dl className="complaint-dates">
            <div>
              <dt>{t('createdAt')}</dt>
              <dd>
                <time dateTime={detail.createdAt}>
                  {complaintDate(detail.createdAt, i18n.language)}
                </time>
              </dd>
            </div>
            <div>
              <dt>{t('updatedAt')}</dt>
              <dd>
                <time dateTime={detail.updatedAt}>
                  {complaintDate(detail.updatedAt, i18n.language)}
                </time>
              </dd>
            </div>
            {detail.closedAt && (
              <div>
                <dt>{t('closedAt')}</dt>
                <dd>
                  <time dateTime={detail.closedAt}>
                    {complaintDate(detail.closedAt, i18n.language)}
                  </time>
                </dd>
              </div>
            )}
          </dl>
          <section className="complaint-detail-section">
            <h3>{t('form.description')}</h3>
            <p className="complaint-prose">{detail.description}</p>
          </section>
          <section className="complaint-detail-section">
            <h3>{t('responses')}</h3>
            {!detail.responses.length ? (
              <p className="complaint-secondary-text">{t('noResponses')}</p>
            ) : (
              <ol className="complaint-timeline">
                {detail.responses.map((item) => (
                  <li key={item.id}>
                    <p className="complaint-prose">{item.message}</p>
                    <time dateTime={item.createdAt}>
                      {complaintDate(item.createdAt, i18n.language)}
                    </time>
                  </li>
                ))}
              </ol>
            )}
          </section>
          <section className="complaint-detail-section">
            <h3>{t('history')}</h3>
            <ol className="complaint-timeline">
              {detail.history.map((item) => (
                <li key={item.id}>
                  <p>
                    {item.previousStatus
                      ? t('historyChange', {
                          previous: t(`status.${item.previousStatus}`),
                          status: t(`status.${item.status}`),
                        })
                      : t('historyCreated')}
                  </p>
                  <time dateTime={item.createdAt}>
                    {complaintDate(item.createdAt, i18n.language)}
                  </time>
                </li>
              ))}
            </ol>
          </section>
          {canManage && open && (
            <section className="complaint-detail-section complaint-management">
              <h3>{t('management')}</h3>
              <form className="complaint-form" onSubmit={submit} noValidate>
                <label htmlFor={`${id}-response`}>{t('responseLabel')} *</label>
                <textarea
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
                <p id={`${id}-response-help`} className="complaint-help">
                  {t('form.counter', { count: response.length, max: 5000 })}
                </p>
                {submitted && responseInvalid && (
                  <p id={`${id}-response-error`} className="complaint-field-error">
                    {t('responseError')}
                  </p>
                )}
                <button
                  className="complaint-button complaint-primary"
                  type="submit"
                  disabled={pending}
                >
                  <Send size={16} aria-hidden="true" />
                  {pending ? t('saving') : t('respond')}
                </button>
              </form>
              <div className="complaint-actions">
                {detail.status === 'aberta' && (
                  <button
                    type="button"
                    className="complaint-button complaint-secondary"
                    disabled={pending}
                    onClick={onAnalyse}
                  >
                    <Clock3 size={16} aria-hidden="true" />
                    {t('markInReview')}
                  </button>
                )}
                <button
                  type="button"
                  className="complaint-button complaint-secondary"
                  disabled={pending || !detail.responses.length}
                  aria-describedby={!detail.responses.length ? `${id}-close-help` : undefined}
                  onClick={onClose}
                >
                  <CheckCheck size={16} aria-hidden="true" />
                  {t('close')}
                </button>
              </div>
              {!detail.responses.length && (
                <p id={`${id}-close-help`} className="complaint-help">
                  {t('responseRequired')}
                </p>
              )}
            </section>
          )}
          {detail.status === 'encerrada' && <p className="complaint-read-only">{t('readOnly')}</p>}
          {detail.status === 'unknown' && (
            <p className="complaint-read-only">{t('unknownStatus')}</p>
          )}
        </>
      )}
    </section>
  );
}
