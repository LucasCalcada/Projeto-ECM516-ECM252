import { useState } from 'react';
import { useTranslation } from 'react-i18next';
import { Building2, CalendarCheck2, Home } from 'lucide-react';
import BuildingReservationsList from '../components/reservations/BuildingReservationsList';
import FutureReservationsList from '../components/reservations/FutureReservationsList';
import ReservationCalendarPanel from '../components/reservations/ReservationCalendarPanel';
import hasResidency from '../helpers/hasResidency';
import hasPermission from '../helpers/hasPermission';

type ReservationViewMode = 'create' | 'building' | 'residency';

interface ReservationViewOption {
  mode: ReservationViewMode;
}

const CREATE_RESERVATION_PERMISSION = '@reservation:create';
const VIEW_BUILDING_RESERVATION_PERMISSION = '@reservation:view:building';
const VIEW_RESIDENCY_RESERVATION_PERMISSION = '@reservation:view:residency';

function getAvailableViews() {
  const options: ReservationViewOption[] = [];

  if (hasPermission([CREATE_RESERVATION_PERMISSION]) && hasResidency()) {
    options.push({ mode: 'create', label: 'Registrar' });
  }

  if (hasPermission([VIEW_BUILDING_RESERVATION_PERMISSION])) {
    options.push({ mode: 'building', label: 'Prédio' });
  }

  if (hasPermission([VIEW_RESIDENCY_RESERVATION_PERMISSION]) && hasResidency()) {
    options.push({ mode: 'residency', label: 'Minha unidade' });
  }

  return options;
}

const iconByMode = {
  create: CalendarCheck2,
  building: Building2,
  residency: Home,
};

function ReservationsHeader({
  activeMode,
  options,
  onModeChange,
}: {
  activeMode: ReservationViewMode;
  options: ReservationViewOption[];
  onModeChange: (mode: ReservationViewMode) => void;
}) {
  const { t } = useTranslation();
  const ActiveIcon = iconByMode[activeMode];

  return (
    <header className="mb-6 flex shrink-0 flex-wrap items-center justify-between gap-3">
      <div>
        <div className="flex items-center gap-2 text-cyan-300">
          <ActiveIcon size={22} />
          <h1 className="text-2xl font-bold text-neutral-100">
            {t(`reservations:views.${activeMode}.title`)}
          </h1>
        </div>
        <p className="text-neutral-400">{t(`reservations:views.${activeMode}.description`)}</p>
      </div>

      {options.length > 1 && (
        <div className="flex flex-wrap items-center gap-2">
          {options.map((option) => {
            const Icon = iconByMode[option.mode];
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
                {t(`reservations:views.${option.mode}.label`)}
              </button>
            );
          })}
        </div>
      )}
    </header>
  );
}

function ReservationsCreate() {
  return (
    <div className="min-h-0 flex-1">
      <ReservationCalendarPanel />
    </div>
  );
}

function ReservationsBuildingView() {
  return (
    <div className="min-h-0 flex-1">
      <BuildingReservationsList />
    </div>
  );
}

function ReservationsResidencyView() {
  return (
    <div className="min-h-0 flex-1">
      <FutureReservationsList />
    </div>
  );
}

function renderReservationsView(mode: ReservationViewMode) {
  if (mode === 'create') {
    return <ReservationsCreate />;
  }

  if (mode === 'building') {
    return <ReservationsBuildingView />;
  }

  return <ReservationsResidencyView />;
}

export default function Reservations() {
  const { t } = useTranslation();
  const options = getAvailableViews();
  const [activeMode, setActiveMode] = useState<ReservationViewMode>(options[0]?.mode ?? 'create');
  const currentMode = options.some((option) => option.mode === activeMode)
    ? activeMode
    : options[0]?.mode;

  if (!currentMode) {
    return (
      <div className="flex h-screen items-center justify-center">
        <h1 className="text-2xl font-bold text-neutral-100">{t('common:accessDenied')}</h1>
      </div>
    );
  }

  return (
    <div className="flex h-[calc(100vh-1rem)] max-h-[calc(100vh-1rem)] min-h-0 w-full flex-col overflow-hidden p-3 md:p-4">
      <ReservationsHeader activeMode={currentMode} options={options} onModeChange={setActiveMode} />
      {renderReservationsView(currentMode)}
    </div>
  );
}
