import { useCallback, useEffect, useState } from 'react';
import { CheckCircle2, ListChecks, RefreshCw } from 'lucide-react';
import type Package from '../../types/Packages';
import { useToast } from '../Toast';
import useService from '../../helpers/useService';

interface PackageListProps {
  scope: 'building' | 'residency';
}

function formatDate(value: string | null) {
  if (!value) return '-';
  return new Date(value).toLocaleString('pt-BR');
}

function getStatusLabel(status: Package['status']) {
  const labels: Record<Package['status'], string> = {
    PENDING: 'Pendente',
    DELIVERED: 'Entregue',
    CANCELED: 'Cancelada',
  };

  return labels[status] ?? status;
}

export default function PackageList({ scope }: PackageListProps) {
  const [packages, setPackages] = useState<Package[]>([]);
  const [isLoading, setIsLoading] = useState(false);
  const [confirmingId, setConfirmingId] = useState<string | null>(null);
  const { notifyError, notifySuccess } = useToast();
  const deliveryService = useService('delivery');
  const isResidencyScope = scope === 'residency';

  const fetchPackages = useCallback(async () => {
    setIsLoading(true);
    try {
      const response = await deliveryService.get<Package[]>('/packages/view', {
        params: { scope },
      });
      setPackages(response.data);
    } catch (error) {
      console.error(error);
      notifyError('Erro', 'Não foi possível listar as encomendas.');
    } finally {
      setIsLoading(false);
    }
  }, [deliveryService, notifyError, scope]);

  useEffect(() => {
    fetchPackages();
  }, [fetchPackages]);

  async function handleConfirm(packageId: string) {
    setConfirmingId(packageId);
    try {
      await deliveryService.put('/packages', { packageId });
      notifySuccess('Recebimento confirmado', 'A encomenda foi marcada como entregue.');
      fetchPackages();
    } catch (error) {
      console.error(error);
      notifyError('Erro', 'Não foi possível confirmar o recebimento.');
    } finally {
      setConfirmingId(null);
    }
  }

  return (
    <section className="rounded-lg border border-neutral-800 bg-neutral-900/40 p-4">
      <div className="mb-4 flex flex-wrap items-center justify-between gap-3">
        <div className="flex items-center gap-2 text-neutral-100">
          <ListChecks size={18} />
          <h2 className="text-lg font-semibold">
            {isResidencyScope ? 'Encomendas da residência' : 'Encomendas do prédio'}
          </h2>
        </div>
        <button
          type="button"
          className="inline-flex items-center gap-2 rounded-md bg-cyan-300 px-3 py-2 text-sm font-semibold text-neutral-950 transition hover:bg-cyan-200 disabled:cursor-not-allowed disabled:opacity-60"
          onClick={fetchPackages}
          disabled={isLoading}
        >
          <RefreshCw size={16} />
          {isLoading ? 'Atualizando...' : 'Atualizar'}
        </button>
      </div>

      {isLoading ? (
        <div className="text-sm text-neutral-400">Carregando...</div>
      ) : packages.length === 0 ? (
        <div className="text-sm text-neutral-400">Nenhuma encomenda encontrada.</div>
      ) : (
        <div className="overflow-x-auto">
          <table className="min-w-full text-left text-sm">
            <thead className="text-xs text-neutral-400 uppercase">
              <tr>
                {!isResidencyScope && <th className="py-2 pr-4">Residência</th>}
                <th className="py-2 pr-4">Descrição</th>
                <th className="py-2 pr-4">Status</th>
                <th className="py-2 pr-4">Recebida em</th>
                <th className="py-2 pr-4">Entregue em</th>
                {isResidencyScope && <th className="py-2 text-right">Ação</th>}
              </tr>
            </thead>
            <tbody className="text-neutral-200">
              {packages.map((pkg) => (
                <tr key={pkg.id} className="border-t border-neutral-800">
                  {!isResidencyScope && <td className="py-2 pr-4">{pkg.residencyName}</td>}
                  <td className="py-2 pr-4">{pkg.description}</td>
                  <td className="py-2 pr-4">
                    <span className="inline-flex rounded-md border border-neutral-700 bg-neutral-950 px-2 py-1 text-xs font-semibold text-neutral-100">
                      {getStatusLabel(pkg.status)}
                    </span>
                  </td>
                  <td className="py-2 pr-4">{formatDate(pkg.createdAt)}</td>
                  <td className="py-2 pr-4">{formatDate(pkg.deliveredAt)}</td>
                  {isResidencyScope && (
                    <td className="py-2 text-right">
                      <button
                        type="button"
                        className="inline-flex items-center gap-2 rounded-md bg-cyan-300 px-3 py-2 text-sm font-semibold text-neutral-950 transition hover:bg-cyan-200 disabled:cursor-not-allowed disabled:opacity-60"
                        onClick={() => handleConfirm(pkg.id)}
                        disabled={pkg.status !== 'PENDING' || confirmingId === pkg.id}
                      >
                        <CheckCircle2 size={16} />
                        {confirmingId === pkg.id ? 'Confirmando...' : 'Confirmar'}
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
