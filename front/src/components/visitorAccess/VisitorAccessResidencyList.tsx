import { useCallback, useEffect, useState } from 'react';
import { ListChecks, RefreshCw } from 'lucide-react';
import config from '../../config';
import type { VisitorAccess } from '../../types/VisitorAccess';
import { useToast } from '../Toast';
import VisitorAccessHeader from './VisitorAccessHeader';

function getResidencyLabel(access: VisitorAccess) {
  return access.residencyCode ?? access.residencyName ?? access.residencyId;
}

export default function VisitorAccessResidencyList() {
  const [accesses, setAccesses] = useState<VisitorAccess[]>([]);
  const [isLoading, setIsLoading] = useState(false);
  const { notify } = useToast();

  const fetchAccesses = useCallback(async () => {
    setIsLoading(true);
    try {
      const response = await fetch(`${config.visitorAccessUrl}/access`, {
        headers: {
          Authorization: localStorage.getItem('accountToken') ?? '',
          'X-User-Token': localStorage.getItem('userToken') ?? '',
        },
      });

      if (!response.ok) {
        throw new Error('Falha ao carregar acessos.');
      }

      const data = (await response.json()) as VisitorAccess[];
      setAccesses(data);
    } catch (error) {
      console.error(error);
      notify('Erro', 'Nao foi possivel listar os acessos.', 'error');
    } finally {
      setIsLoading(false);
    }
  }, [notify]);

  useEffect(() => {
    fetchAccesses();
  }, [fetchAccesses]);

  function handleRefresh() {
    fetchAccesses();
  }

  return (
    <div className="h-full overflow-auto p-4 md:p-8">
      <VisitorAccessHeader outletName="Histórico de visitas" />

      <section className="rounded-lg border border-neutral-800 bg-neutral-900/40 p-4">
        <div className="mb-4 flex flex-wrap items-center justify-between gap-3">
          <div className="flex items-center gap-2 text-neutral-100">
            <ListChecks size={18} />
            <h2 className="text-lg font-semibold">Histórico do prédio</h2>
          </div>
          <button
            type="button"
            className="inline-flex items-center gap-2 rounded-md bg-cyan-300 px-3 py-2 text-sm font-semibold text-neutral-950 transition hover:bg-cyan-200 disabled:cursor-not-allowed disabled:opacity-60"
            onClick={handleRefresh}
            disabled={isLoading}
          >
            <RefreshCw size={16} />
            {isLoading ? 'Atualizando...' : 'Atualizar'}
          </button>
        </div>

        {isLoading ? (
          <div className="text-sm text-neutral-400">Carregando...</div>
        ) : accesses.length === 0 ? (
          <div className="text-sm text-neutral-400">Nenhum acesso encontrado.</div>
        ) : (
          <div className="overflow-x-auto">
            <table className="min-w-full text-left text-sm">
              <thead className="text-xs text-neutral-400 uppercase">
                <tr>
                  <th className="py-2">Visitante</th>
                  <th className="py-2">Residência</th>
                  <th className="py-2">CPF</th>
                  <th className="py-2">RG</th>
                  <th className="py-2">Entrada</th>
                </tr>
              </thead>
              <tbody className="text-neutral-200">
                {accesses.map((access) => (
                  <tr key={access.id} className="border-t border-neutral-800">
                    <td className="py-2">{access.name}</td>
                    <td className="py-2">{getResidencyLabel(access)}</td>
                    <td className="py-2">{access.cpf}</td>
                    <td className="py-2">{access.rg}</td>
                    <td className="py-2">{new Date(access.entryAt).toLocaleString('pt-BR')}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </section>
    </div>
  );
}
