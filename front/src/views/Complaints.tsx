import { useCallback, useRef, useState } from 'react';
import { useNavigate } from 'react-router';
import { useTranslation } from 'react-i18next';
import hasPermission from '../helpers/hasPermission';
import hasResidency from '../helpers/hasResidency';
import type { ComplaintSummary } from '../types/Complaint';
import ComplaintsHeader, {
  type ComplaintViewMode,
} from '../components/complaints/ComplaintsHeader';
import ComplaintsList from '../components/complaints/ComplaintsList';
import ComplaintCreateForm from '../components/complaints/ComplaintCreateForm';

function getAvailableViews(): ComplaintViewMode[] {
  const views: ComplaintViewMode[] = [];
  if (hasPermission(['@complaint:view:building'])) views.push('building');
  if (hasResidency() && hasPermission(['@complaint:view:residency'])) views.push('mine');
  if (localStorage.getItem('buildingId') && hasPermission(['@complaint:create']))
    views.push('create');
  return views;
}

export default function Complaints() {
  const { t } = useTranslation('complaints');
  const navigate = useNavigate();
  const options = getAvailableViews();
  const [activeMode, setActiveMode] = useState<ComplaintViewMode>(options[0] ?? 'create');
  const lastListMode = useRef(options.find((mode) => mode !== 'create'));
  const [dirty, setDirty] = useState(false);
  const [pending, setPending] = useState(false);
  const currentMode = options.includes(activeMode) ? activeMode : options[0];
  const residencyId = localStorage.getItem('residencyId');
  const canRespondBuilding = hasPermission(['@complaint:respond:building']);
  const canRespondResidency = hasResidency() && hasPermission(['@complaint:respond:residency']);
  const canChangeStatus = hasPermission(['@complaint:update:status']);
  const canRespondTo = useCallback(
    (complaint: ComplaintSummary) =>
      canRespondBuilding || (canRespondResidency && complaint.residencyId === residencyId),
    [canRespondBuilding, canRespondResidency, residencyId],
  );
  const handleUnauthorized = useCallback(() => {
    localStorage.removeItem('userToken');
    localStorage.removeItem('permissions');
    localStorage.removeItem('exp');
    navigate(localStorage.getItem('accountToken') ? '/buildingSelector' : '/login', {
      replace: true,
    });
  }, [navigate]);
  function changeMode(mode: ComplaintViewMode) {
    if (!options.includes(mode)) return;
    if (mode !== 'create') lastListMode.current = mode;
    setDirty(false);
    setPending(false);
    setActiveMode(mode);
  }
  return (
    <div
      data-testid="complaints-page"
      className="w-full min-w-0 p-4 text-neutral-300 @3xl/app-content:p-8"
    >
      <ComplaintsHeader
        activeMode={currentMode}
        options={options}
        dirty={dirty}
        pending={pending}
        onModeChange={changeMode}
      />
      {currentMode === 'create' ? (
        <ComplaintCreateForm
          onCreated={() => changeMode(lastListMode.current ?? 'create')}
          onCancel={() => changeMode(lastListMode.current ?? 'create')}
          onDirtyChange={setDirty}
          onPendingChange={setPending}
          onUnauthorized={handleUnauthorized}
        />
      ) : currentMode ? (
        <ComplaintsList
          key={currentMode}
          scope={currentMode}
          canRespondTo={canRespondTo}
          canChangeStatus={canChangeStatus}
          onDirtyChange={setDirty}
          onPendingChange={setPending}
          onUnauthorized={handleUnauthorized}
        />
      ) : (
        <p role="status" className="rounded-lg bg-neutral-900 p-4 text-neutral-400">
          {t('errors.forbidden')}
        </p>
      )}
    </div>
  );
}
