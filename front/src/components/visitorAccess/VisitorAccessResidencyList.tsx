import { useCallback, useEffect, useState } from 'react';
import { ListChecks, RefreshCw } from 'lucide-react';
import type { VisitorAccess } from '../../types/VisitorAccess';
import { useToast } from '../Toast';
import useService from '../../helpers/useService';
import { useTranslation } from 'react-i18next';

function getResidencyLabel(access: VisitorAccess) {
  return access.residencyCode ?? access.residencyName ?? access.residencyId;
}

export default function VisitorAccessResidencyList() {
  const { i18n, t } = useTranslation();
  const [accesses, setAccesses] = useState<VisitorAccess[]>([]);
  const [isLoading, setIsLoading] = useState(false);
  const { notify } = useToast();
  const visitorService = useService('visitor');

  const fetchAccesses = useCallback(async () => {
    setIsLoading(true);
    try {
      const response = await visitorService.get<VisitorAccess[]>('/access');
      setAccesses(response.data);
    } catch (error) {
      console.error(error);
      notify(t('common:error'), t('visitorAccess:list.toast.listError'), 'error');
    } finally {
      setIsLoading(false);
    }
  }, [notify, t, visitorService]);

  const locale = i18n.resolvedLanguage || i18n.language;

  useEffect(() => {
    fetchAccesses();
  }, [fetchAccesses]);

  function handleRefresh() {
    fetchAccesses();
  }

  return (
    <section className="rounded-lg border border-neutral-800 bg-neutral-900/40 p-4">
      <div className="mb-4 flex flex-wrap items-center justify-between gap-3">
        <button
          type="button"
          className="ml-auto inline-flex items-center gap-2 rounded-md bg-cyan-300 px-3 py-2 text-sm font-semibold text-neutral-950 transition hover:bg-cyan-200 disabled:cursor-not-allowed disabled:opacity-60"
          onClick={handleRefresh}
          disabled={isLoading}
        >
          <RefreshCw size={16} />
          {isLoading ? t('common:updating') : t('common:refresh')}
        </button>
      </div>

      {isLoading ? (
        <div className="text-sm text-neutral-400">{t('common:loadingEllipsis')}</div>
      ) : accesses.length === 0 ? (
        <div className="text-sm text-neutral-400">{t('visitorAccess:list.empty')}</div>
      ) : (
        <div className="overflow-x-auto">
          <table className="min-w-full text-left text-sm">
            <thead className="text-xs text-neutral-400 uppercase">
              <tr>
                <th className="py-2">{t('visitorAccess:table.visitor')}</th>
                <th className="py-2">{t('visitorAccess:table.residency')}</th>
                <th className="py-2">{t('visitorAccess:table.cpf')}</th>
                <th className="py-2">{t('visitorAccess:table.rg')}</th>
                <th className="py-2">{t('visitorAccess:table.entry')}</th>
              </tr>
            </thead>
            <tbody className="text-neutral-200">
              {accesses.map((access) => (
                <tr key={access.id} className="border-t border-neutral-800">
                  <td className="py-2">{access.name}</td>
                  <td className="py-2">{getResidencyLabel(access)}</td>
                  <td className="py-2">{access.cpf}</td>
                  <td className="py-2">{access.rg}</td>
                  <td className="py-2">{new Date(access.entryAt).toLocaleString(locale)}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </section>
  );
}
