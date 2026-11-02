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
      className={`complaint-feedback ${error ? 'complaint-feedback-error' : 'complaint-feedback-success'}`}
      role={error ? 'alert' : 'status'}
    >
      {error ? (
        <AlertCircle size={20} aria-hidden="true" />
      ) : (
        <CheckCircle2 size={20} aria-hidden="true" />
      )}
      <p>{error ? t(`errors.${error}`) : t(`notices.${notice}`)}</p>
      {retry && (
        <button className="complaint-button complaint-secondary" type="button" onClick={retry}>
          <RotateCw size={16} aria-hidden="true" />
          {t('retry')}
        </button>
      )}
    </div>
  );
}
