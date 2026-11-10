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
    <span
      className={`inline-flex items-center gap-1 rounded-md py-1 text-xs font-semibold ${status === 'aberta' ? 'text-cyan-300' : status === 'em_analise' ? 'text-yellow-400' : 'text-neutral-300'}`}
    >
      <Icon size={14} aria-hidden="true" />
      {t(`status.${status}`)}
    </span>
  );
}
