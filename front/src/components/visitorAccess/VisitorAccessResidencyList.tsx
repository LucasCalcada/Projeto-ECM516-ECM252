import { type ChangeEvent, useCallback, useState } from 'react';
import { ListChecks } from 'lucide-react';
import config from '../../config';
import type { VisitorAccess } from '../../types/VisitorAccess';
import { useToast } from '../Toast';
import VisitorAccessHeader from './VisitorAccessHeader';

export default function VisitorAccessResidencyList() {
  const [residencyQuery, setResidencyQuery] = useState('');
  const [accesses, setAccesses] = useState<VisitorAccess[]>([]);
  const [isLoading, setIsLoading] = useState(false);
  const { notify } = useToast();

  const fetchAccesses = useCallback(
    async (residencyId: string) => {
      if (!residencyId) {
        setAccesses([]);
        return;
      }

      setIsLoading(true);
      try {
        const response = await fetch(
          `${config.visitorAccessUrl}/access?residencyId=${encodeURIComponent(residencyId)}`,
          {
            headers: {
              Authorization: `Bearer ${localStorage.getItem('accessToken')}`,
            },
          },
        );

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
    },
    [notify],
  );

  function handleResidencyQueryChange(event: ChangeEvent<HTMLInputElement>) {
    const nextResidencyId = event.target.value;

    setResidencyQuery(nextResidencyId);
    fetchAccesses(nextResidencyId);
  }

  return (
    <div className="h-full overflow-auto p-4 md:p-8">
      <VisitorAccessHeader outletName="Historico de visitas" />

      <section className="rounded-lg border border-neutral-800 bg-neutral-900/40 p-4">
        <div className="mb-4 flex items-center gap-2 text-neutral-100">
          <ListChecks size={18} />
          <h2 className="text-lg font-semibold">Historico por residencia</h2>
        </div>

        <label className="mb-4 block">
          <span className="mb-1 block text-sm text-neutral-300">ResidencyId</span>
          <input
            className="w-full rounded-md border border-neutral-700 bg-neutral-950 px-3 py-2 text-sm"
            value={residencyQuery}
            onChange={handleResidencyQueryChange}
            placeholder="UUID da residencia"
          />
        </label>

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
                  <th className="py-2">CPF</th>
                  <th className="py-2">RG</th>
                  <th className="py-2">Entrada</th>
                </tr>
              </thead>
              <tbody className="text-neutral-200">
                {accesses.map((access) => (
                  <tr key={access.id} className="border-t border-neutral-800">
                    <td className="py-2">{access.name}</td>
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
