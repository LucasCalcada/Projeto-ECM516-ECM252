import { useEffect, useState } from 'react';
import { useBlocker } from 'react-router';
import { useTranslation } from 'react-i18next';
import { Building2, Home, MessageSquareWarning, Plus } from 'lucide-react';
import type { ComplaintScope } from '../../types/Complaint';
import ComplaintConfirmation from './ComplaintConfirmation';

export type ComplaintViewMode = ComplaintScope | 'create';

export default function ComplaintsHeader({
  activeMode,
  options,
  dirty,
  pending,
  onModeChange,
}: {
  activeMode: ComplaintViewMode | undefined;
  options: ComplaintViewMode[];
  dirty: boolean;
  pending: boolean;
  onModeChange: (mode: ComplaintViewMode) => void;
}) {
  const { t } = useTranslation('complaints');
  const [discardMode, setDiscardMode] = useState<ComplaintViewMode | null>(null);
  const creating = activeMode === 'create';
  const scopes = options.filter((mode) => mode !== 'create');
  const blocker = useBlocker(
    ({ currentLocation, nextLocation }) =>
      dirty &&
      Boolean(localStorage.getItem('userToken')) &&
      (currentLocation.pathname !== nextLocation.pathname ||
        currentLocation.search !== nextLocation.search),
  );
  useEffect(() => {
    if (!dirty) return;
    const unload = (event: BeforeUnloadEvent) => {
      event.preventDefault();
      event.returnValue = '';
    };
    window.addEventListener('beforeunload', unload);
    return () => window.removeEventListener('beforeunload', unload);
  }, [dirty]);
  function changeMode(mode: ComplaintViewMode) {
    if (pending || mode === activeMode) return;
    if (dirty) setDiscardMode(mode);
    else onModeChange(mode);
  }
  return (
    <>
      <header className="mb-6 flex flex-wrap items-center justify-between gap-4">
        <div>
          <div className="flex items-center gap-2 text-cyan-300">
            <MessageSquareWarning size={24} aria-hidden="true" />
            <h1 className="text-2xl font-bold text-neutral-100">{t('title')}</h1>
          </div>
          <p className="text-base wrap-anywhere text-neutral-400">
            {localStorage.getItem('buildingName') || t('subtitle')}
          </p>
        </div>
        {!creating && options.includes('create') && (
          <button
            type="button"
            className="inline-flex min-h-11 min-w-11 cursor-pointer items-center justify-center gap-2 rounded-md bg-cyan-300 px-3 py-2 text-sm font-semibold text-neutral-950 transition-colors hover:bg-cyan-200 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-cyan-300 disabled:cursor-not-allowed disabled:opacity-60 motion-reduce:transition-none"
            disabled={pending}
            onClick={() => changeMode('create')}
          >
            <Plus size={16} aria-hidden="true" />
            {t('new')}
          </button>
        )}
      </header>
      {!creating && scopes.length > 1 && (
        <div className="mb-6 flex flex-wrap gap-2" role="group" aria-label={t('scopeLabel')}>
          {scopes.map((scope) => {
            const Icon = scope === 'mine' ? Home : Building2;
            return (
              <button
                key={scope}
                type="button"
                aria-pressed={activeMode === scope}
                disabled={pending}
                className={`inline-flex min-h-11 min-w-11 cursor-pointer items-center justify-center gap-2 rounded-md px-3 py-2 text-sm font-semibold transition-colors focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-cyan-300 disabled:cursor-not-allowed disabled:opacity-60 motion-reduce:transition-none ${activeMode === scope ? 'bg-cyan-300 text-neutral-950 hover:bg-cyan-200' : 'bg-neutral-800 text-neutral-100 hover:bg-neutral-700'}`}
                onClick={() => changeMode(scope)}
              >
                <Icon size={16} aria-hidden="true" />
                {t(`scope.${scope}`)}
              </button>
            );
          })}
        </div>
      )}
      {discardMode && blocker.state !== 'blocked' && (
        <ComplaintConfirmation
          title={t('discardTitle')}
          message={t('discardMessage')}
          confirmLabel={t('discard')}
          onCancel={() => setDiscardMode(null)}
          onConfirm={() => {
            const mode = discardMode;
            setDiscardMode(null);
            onModeChange(mode);
          }}
        />
      )}
      {blocker.state === 'blocked' && (
        <ComplaintConfirmation
          title={t('discardTitle')}
          message={t('discardMessage')}
          confirmLabel={t('discard')}
          pending={pending}
          onCancel={() => blocker.reset()}
          onConfirm={() => blocker.proceed()}
        />
      )}
    </>
  );
}
