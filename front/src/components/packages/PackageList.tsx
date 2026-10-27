import { useCallback, useEffect, useState } from 'react';
import { CheckCircle2, ListChecks, RefreshCw } from 'lucide-react';
import type Package from '../../types/Packages';
import { useToast } from '../Toast';
import useService from '../../helpers/useService';
import { useTranslation } from 'react-i18next';

interface PackageListProps {
  scope: 'building' | 'residency';
}

function formatDate(value: string | null, locale: string) {
  if (!value) return '-';
  return new Date(value).toLocaleString(locale);
}

export default function PackageList({ scope }: PackageListProps) {
  const { i18n, t } = useTranslation();
  const [packages, setPackages] = useState<Package[]>([]);
  const [isLoading, setIsLoading] = useState(false);
  const [confirmingId, setConfirmingId] = useState<string | null>(null);
  const { notifyError, notifySuccess } = useToast();
  const deliveryService = useService('delivery');
  const isResidencyScope = scope === 'residency';
  const locale = i18n.resolvedLanguage || i18n.language;

  const fetchPackages = useCallback(async () => {
    setIsLoading(true);
    try {
      const response = await deliveryService.get<Package[]>('/packages/view', {
        params: { scope },
      });
      setPackages(response.data);
    } catch (error) {
      console.error(error);
      notifyError(t('common:error'), t('packages:list.toast.listError'));
    } finally {
      setIsLoading(false);
    }
  }, [deliveryService, notifyError, scope, t]);

  useEffect(() => {
    fetchPackages();
  }, [fetchPackages]);

  async function handleConfirm(packageId: string) {
    setConfirmingId(packageId);
    try {
      await deliveryService.put('/packages', { packageId });
      notifySuccess(t('packages:list.toast.confirmTitle'), t('packages:list.toast.confirmMessage'));
      fetchPackages();
    } catch (error) {
      console.error(error);
      notifyError(t('common:error'), t('packages:list.toast.confirmError'));
    } finally {
      setConfirmingId(null);
    }
  }

  return (
    <section className="rounded-lg border border-neutral-800 bg-neutral-900/40 p-4">
      <div className="mb-4 flex flex-wrap items-center justify-between gap-3">
        <button
          type="button"
          className="ml-auto inline-flex items-center gap-2 rounded-md bg-cyan-300 px-3 py-2 text-sm font-semibold text-neutral-950 transition hover:bg-cyan-200 disabled:cursor-not-allowed disabled:opacity-60"
          onClick={fetchPackages}
          disabled={isLoading}
        >
          <RefreshCw size={16} />
          {isLoading ? t('packages:list.updating') : t('packages:list.refresh')}
        </button>
      </div>

      {isLoading ? (
        <div className="text-sm text-neutral-400">{t('common:loadingEllipsis')}</div>
      ) : packages.length === 0 ? (
        <div className="text-sm text-neutral-400">{t('packages:list.empty')}</div>
      ) : (
        <div className="overflow-x-auto">
          <table className="min-w-full text-left text-sm">
            <thead className="text-xs text-neutral-400 uppercase">
              <tr>
                {!isResidencyScope && (
                  <th className="py-2 pr-4">{t('packages:table.residency')}</th>
                )}
                <th className="py-2 pr-4">{t('packages:table.description')}</th>
                <th className="py-2 pr-4">{t('packages:table.status')}</th>
                <th className="py-2 pr-4">{t('packages:table.receivedAt')}</th>
                <th className="py-2 pr-4">{t('packages:table.deliveredAt')}</th>
                {isResidencyScope && (
                  <th className="py-2 text-right">{t('packages:table.action')}</th>
                )}
              </tr>
            </thead>
            <tbody className="text-neutral-200">
              {packages.map((pkg) => (
                <tr key={pkg.id} className="border-t border-neutral-800">
                  {!isResidencyScope && <td className="py-2 pr-4">{pkg.residencyName}</td>}
                  <td className="py-2 pr-4">{pkg.description}</td>
                  <td className="py-2 pr-4">
                    <span className="inline-flex rounded-md border border-neutral-700 bg-neutral-950 px-2 py-1 text-xs font-semibold text-neutral-100">
                      {t(`packages:statusValue.${pkg.status}`, { defaultValue: pkg.status })}
                    </span>
                  </td>
                  <td className="py-2 pr-4">{formatDate(pkg.createdAt, locale)}</td>
                  <td className="py-2 pr-4">{formatDate(pkg.deliveredAt, locale)}</td>
                  {isResidencyScope && (
                    <td className="py-2 text-right">
                      <button
                        type="button"
                        className="inline-flex items-center gap-2 rounded-md bg-cyan-300 px-3 py-2 text-sm font-semibold text-neutral-950 transition hover:bg-cyan-200 disabled:cursor-not-allowed disabled:opacity-60"
                        onClick={() => handleConfirm(pkg.id)}
                        disabled={pkg.status !== 'PENDING' || confirmingId === pkg.id}
                      >
                        <CheckCircle2 size={16} />
                        {confirmingId === pkg.id
                          ? t('packages:list.confirming')
                          : t('packages:list.confirm')}
                      </button>
                    </td>
                  )}
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </section>
  );
}
