import { CheckCheck, Clock3, CircleHelp, MessageCircle } from 'lucide-react';
import { useTranslation } from 'react-i18next';
import type { ComplaintStatus } from '../../types/Complaint';

export default function ComplaintStatusBadge({ status }: { status: ComplaintStatus }) {
  const { t } = useTranslation('complaints');
  const Icon =
    status === 'aberta'
      ? MessageCircle
      : status === 'em_analise'
        ? Clock3
        : status === 'encerrada'
          ? CheckCheck
          : CircleHelp;
  return (
    <span className={`complaint-status complaint-status-${status}`}>
      <Icon size={14} aria-hidden="true" />
      {t(`status.${status}`)}
    </span>
  );
}
