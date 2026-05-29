import { Building2, Home, PackageIcon, PackagePlus } from 'lucide-react';
import type { PackageViewMode, PackageViewOption } from './types';

interface PackagesHeaderProps {
  activeMode: PackageViewMode;
  options: PackageViewOption[];
  onModeChange: (mode: PackageViewMode) => void;
}

const titleByMode: Record<PackageViewMode, string> = {
  create: 'Registrar encomenda',
  building: 'Encomendas do predio',
  residency: 'Minhas encomendas',
};

const iconByMode = {
  create: PackagePlus,
  building: Building2,
  residency: Home,
};

export default function PackagesHeader({ activeMode, options, onModeChange }: PackagesHeaderProps) {
  const ActiveIcon = iconByMode[activeMode];

  return (
    <header className="mb-6 flex flex-wrap items-center justify-between gap-3">
      <div className="flex items-center gap-2 text-cyan-300">
        <ActiveIcon size={22} />
        <h1 className="text-2xl font-bold text-neutral-100">{titleByMode[activeMode]}</h1>
      </div>

      {options.length > 1 && (
        <div className="flex flex-wrap items-center gap-2">
          {options.map((option) => {
            const Icon = iconByMode[option.mode] ?? PackageIcon;
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
