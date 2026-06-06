import { ListChecks, ShieldCheck, UserPlus } from 'lucide-react';
import { useTranslation } from 'react-i18next';

export type VisitorAccessViewMode = 'create' | 'view';

export interface VisitorAccessViewOption {
  mode: VisitorAccessViewMode;
  label: string;
}

interface VisitorAccessHeaderProps {
  activeMode: VisitorAccessViewMode;
  options: VisitorAccessViewOption[];
  onModeChange: (mode: VisitorAccessViewMode) => void;
}

const iconByMode = {
  create: UserPlus,
  view: ListChecks,
};

export default function VisitorAccessHeader({
  activeMode,
  options,
  onModeChange,
}: VisitorAccessHeaderProps) {
  const { t } = useTranslation();
  const ActiveIcon = iconByMode[activeMode] ?? ShieldCheck;

  return (
    <header className="mb-6 flex flex-wrap items-center justify-between gap-3">
      <div className="flex items-center gap-2 text-cyan-300">
        <ActiveIcon size={22} />
        <h1 className="text-2xl font-bold text-neutral-100">
          {t(`visitorAccess:views.${activeMode}.title`)}
        </h1>
      </div>

      {options.length > 1 && (
        <div className="flex flex-wrap items-center gap-2">
          {options.map((option) => {
            const Icon = iconByMode[option.mode] ?? ShieldCheck;
            const isActive = option.mode === activeMode;

            return (
              <button
                key={option.mode}
                type="button"
                className={`inline-flex items-center gap-2 rounded-md border px-3 py-2 text-sm font-semibold transition ${
                  isActive
                    ? 'border-cyan-300 bg-cyan-300 text-neutral-950'
                    : 'border-neutral-700 bg-neutral-950 text-neutral-200 hover:bg-neutral-800'
                }`}
                onClick={() => onModeChange(option.mode)}
              >
                <Icon size={16} />
                {option.label}
              </button>
            );
          })}
        </div>
      )}
    </header>
  );
}
