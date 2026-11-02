import { AlertCircle, CheckCircle2, RotateCw } from 'lucide-react';
import { useTranslation } from 'react-i18next';
import type { ComplaintFailure } from '../../types/Complaint';

export default function ComplaintFeedback({
  error,
  notice,
  retry,
}: {
  error?: ComplaintFailure | null;
  notice?: string | null;
  retry?: () => void;
}) {
  const { t } = useTranslation('complaints');
  if (!error && !notice) return null;
  return (
    <div
      className={`mb-4 flex flex-wrap items-start gap-3 rounded-lg bg-neutral-800 p-4 text-base ${error ? 'text-red-400' : 'text-green-400'}`}
      role={error ? 'alert' : 'status'}
    >
      {error ? (
        <AlertCircle size={20} className="shrink-0" aria-hidden="true" />
      ) : (
        <CheckCircle2 size={20} className="shrink-0" aria-hidden="true" />
      )}
      <p className="min-w-0 flex-1 wrap-anywhere">
        {error ? t(`errors.${error}`) : t(`notices.${notice}`)}
      </p>
      {retry && (
        <button
          className="inline-flex min-h-11 min-w-11 cursor-pointer items-center justify-center gap-2 rounded-md bg-neutral-800 px-3 py-2 text-sm font-semibold text-neutral-100 transition-colors hover:bg-neutral-700 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-cyan-300 motion-reduce:transition-none"
          type="button"
          onClick={retry}
        >
          <RotateCw size={16} aria-hidden="true" />
          {t('retry')}
        </button>
      )}
    </div>
  );
}
