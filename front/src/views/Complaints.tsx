import { useCallback, useLayoutEffect, useMemo, useState } from 'react';
import { useBlocker, useNavigate } from 'react-router';
import { useTranslation } from 'react-i18next';
import { Building2, Home, MessageSquareWarning, Plus } from 'lucide-react';
import useService from '../helpers/useService';
import hasPermission from '../helpers/hasPermission';
import hasResidency from '../helpers/hasResidency';
import { createComplaintsRepository } from '../helpers/complaintsRepository';
import useComplaints from '../helpers/useComplaints';
import type { ComplaintDraft } from '../types/Complaint';
import ComplaintsList from '../components/complaints/ComplaintsList';
import ComplaintDetail from '../components/complaints/ComplaintDetail';
import ComplaintCreateForm from '../components/complaints/ComplaintCreateForm';
import ComplaintFeedback from '../components/complaints/ComplaintFeedback';
import ComplaintConfirmation from '../components/complaints/ComplaintConfirmation';
import '../components/complaints/complaints.css';

const emptyDraft: ComplaintDraft = { title: '', category: '', description: '' };

export default function Complaints() {
  const { t } = useTranslation('complaints');
  const navigate = useNavigate();
  const canCreate = hasResidency();
  const canManage = hasPermission(['@complaint:manage']);
  const buildingName = localStorage.getItem('buildingName') || '';
  const client = useService('complaint');
  const repository = useMemo(() => createComplaintsRepository(client), [client]);
  const handleUnauthorized = useCallback(() => {
    localStorage.removeItem('userToken');
    localStorage.removeItem('permissions');
    localStorage.removeItem('exp');
    navigate(localStorage.getItem('accountToken') ? '/buildingSelector' : '/login', {
      replace: true,
    });
  }, [navigate]);
  const data = useComplaints(repository, handleUnauthorized);
  const [creating, setCreating] = useState(false);
  const [draft, setDraft] = useState<ComplaintDraft>(emptyDraft);
  const [response, setResponse] = useState({ id: '', text: '' });
  const [discard, setDiscard] = useState<{ action: () => void } | null>(null);
  const [closing, setClosing] = useState<{ id: string; title: string } | null>(null);
  const pending = Boolean(data.pending);
  const dirty = Boolean(
    (creating && (draft.title || draft.category || draft.description)) || response.text,
  );
  const navigateSafely = useCallback(
    (action: () => void) => {
      if (pending) return;
      if (dirty) setDiscard({ action });
      else action();
    },
    [dirty, pending],
  );

  const blocker = useBlocker(
    ({ currentLocation, nextLocation }) =>
      dirty &&
      Boolean(localStorage.getItem('userToken')) &&
      (currentLocation.pathname !== nextLocation.pathname ||
        currentLocation.search !== nextLocation.search),
  );
  useLayoutEffect(() => {
    if (!dirty) return;
    const unload = (event: BeforeUnloadEvent) => {
      event.preventDefault();
      event.returnValue = '';
    };
    window.addEventListener('beforeunload', unload);
    return () => window.removeEventListener('beforeunload', unload);
  }, [dirty]);
  function resetDrafts() {
    setDraft(emptyDraft);
    setResponse({ id: '', text: '' });
  }
  async function create() {
    if (!canCreate || data.scope !== 'mine') return;
    if (await data.create(draft)) {
      setDraft(emptyDraft);
      setCreating(false);
    }
  }
  const current = data.detail;
  const responseText = response.id === data.selectedId ? response.text : '';
  return (
    <div className="complaints-page">
      <header className="complaints-header">
        <div>
          <div className="complaints-title">
            <MessageSquareWarning size={24} aria-hidden="true" />
            <h1>{t('title')}</h1>
          </div>
          <p className="complaint-secondary-text">{buildingName || t('subtitle')}</p>
        </div>
        {!creating && data.scope === 'mine' && canCreate && (
          <button
            type="button"
            className="complaint-button complaint-primary"
            disabled={pending}
            onClick={() =>
              navigateSafely(() => {
                resetDrafts();
                setCreating(true);
              })
            }
          >
            <Plus size={16} aria-hidden="true" />
            {t('new')}
          </button>
        )}
      </header>
      {canManage && !creating && (
        <div className="complaint-modes" role="group" aria-label={t('scopeLabel')}>
          {(['mine', 'building'] as const).map((scope) => {
            const Icon = scope === 'mine' ? Home : Building2;
            return (
              <button
                key={scope}
                type="button"
                className={`complaint-button ${data.scope === scope ? 'complaint-primary' : 'complaint-secondary'}`}
                aria-pressed={data.scope === scope}
                disabled={pending}
                onClick={() => {
                  if (scope !== data.scope)
                    navigateSafely(() => {
                      resetDrafts();
                      data.setScope(scope);
                    });
                }}
              >
                <Icon size={16} aria-hidden="true" />
                {t(`scope.${scope}`)}
              </button>
            );
          })}
        </div>
      )}
      {!canCreate && data.scope === 'mine' && !creating && (
        <p className="complaint-secondary-text complaint-eligibility">{t('noResidency')}</p>
      )}
      <ComplaintFeedback error={data.mutationError} notice={data.notice} />
      {creating ? (
        <ComplaintCreateForm
          draft={draft}
          onChange={setDraft}
          pending={pending}
          onSubmit={() => {
            void create();
          }}
          onCancel={() =>
            navigateSafely(() => {
              resetDrafts();
              setCreating(false);
            })
          }
        />
      ) : (
        <div className={`complaints-grid ${data.selectedId ? 'has-selection' : ''}`}>
          <ComplaintsList
            items={data.items}
            selectedId={data.selectedId}
            filters={data.filters}
            loading={data.listLoading}
            error={data.listError}
            hasMore={data.hasMore}
            disabled={pending}
            onFilters={(filters) =>
              navigateSafely(() => {
                resetDrafts();
                data.setFilters(filters);
              })
            }
            onSelect={(id) => {
              if (id !== data.selectedId)
                navigateSafely(() => {
                  resetDrafts();
                  void data.select(id);
                });
            }}
            onRefresh={() => {
              void data.reload();
            }}
            onMore={() => {
              void data.loadMore();
            }}
          />
          {data.selectedId && (
            <ComplaintDetail
              key={data.selectedId}
              detail={current}
              loading={data.detailLoading}
              error={data.detailError}
              pending={pending}
              canManage={canManage}
              response={responseText}
              onResponse={(text) => setResponse({ id: data.selectedId!, text })}
              onSend={async () => {
                const id = current?.id;
                  if (!id || !canManage || !['aberta', 'em_analise'].includes(current.status))
                  return;
                if (await data.respond(id, responseText)) setResponse({ id, text: '' });
              }}
              onAnalyse={() => {
                  if (current?.status === 'aberta' && canManage)
                  void data.changeStatus(current.id, 'em_analise');
              }}
              onClose={() => {
                  if (current && canManage && current.responses.length)
                  navigateSafely(() => {
                    resetDrafts();
                    setClosing({ id: current.id, title: current.title });
                  });
              }}
              onBack={() =>
                navigateSafely(() => {
                  const id = data.selectedId;
                  resetDrafts();
                  void data.select(null);
                  window.requestAnimationFrame(() => {
                    if (id)
                      document
                        .querySelector<HTMLButtonElement>(`[data-complaint-id="${CSS.escape(id)}"]`)
                        ?.focus();
                  });
                })
              }
              onRetry={() => {
                if (data.selectedId) void data.select(data.selectedId);
              }}
            />
          )}
        </div>
      )}
      {discard && blocker.state !== 'blocked' && (
        <ComplaintConfirmation
          title={t('discardTitle')}
          message={t('discardMessage')}
          confirmLabel={t('discard')}
          onCancel={() => {
            setDiscard(null);
          }}
          onConfirm={() => {
            const action = discard.action;
            setDiscard(null);
            resetDrafts();
            action();
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
          onConfirm={() => {
            resetDrafts();
            blocker.proceed();
          }}
        />
      )}
      {closing && (
        <ComplaintConfirmation
          title={t('closeTitle')}
          message={t('closeMessage', { title: closing.title })}
          confirmLabel={t('close')}
          pending={pending}
          onCancel={() => setClosing(null)}
          onConfirm={async () => {
            const id = closing.id;
            if (current?.id !== id || !current.responses.length || !canManage) return;
            await data.changeStatus(id, 'encerrada');
            setClosing(null);
          }}
        />
      )}
    </div>
  );
}
