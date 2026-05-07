import { useEffect, useState } from 'react';
import { ShieldCheck, UserPlus, ListChecks } from 'lucide-react';
import config from '../config';
import type { VisitorAccess } from '../types/VisitorAccess';
import { useToast } from '../components/Toast';

interface AccessFormState {
  residencyId: string;
  rg: string;
  cpf: string;
  name: string;
  entryAt: string;
}

const initialForm: AccessFormState = {
  residencyId: '',
  rg: '',
  cpf: '',
  name: '',
  entryAt: '',
};

export default function VisitorAccessView() {
  const [form, setForm] = useState<AccessFormState>(initialForm);
  const [residencyQuery, setResidencyQuery] = useState('');
  const [accesses, setAccesses] = useState<VisitorAccess[]>([]);
  const [isLoading, setIsLoading] = useState(false);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const { notify } = useToast();

  async function fetchAccesses(residencyId: string) {
    if (!residencyId) {
      setAccesses([]);
      return;
    }

    setIsLoading(true);
    try {
      const response = await fetch(`${config.visitorAccessUrl}/access?residencyId=${residencyId}`, {
        headers: {
          Authorization: `Bearer ${localStorage.getItem('accessToken')}`,
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
  }

  useEffect(() => {
    fetchAccesses(residencyQuery);
  }, [residencyQuery]);

  function updateForm<K extends keyof AccessFormState>(key: K, value: AccessFormState[K]) {
    setForm((prev) => ({ ...prev, [key]: value }));
  }

  async function handleSubmit(event: React.FormEvent<HTMLFormElement>) {
    event.preventDefault();

    if (!form.residencyId || !form.name || !form.cpf || !form.rg) {
      notify('Campos obrigatorios', 'Preencha residencyId, nome, CPF e RG.', 'warning');
      return;
    }

    setIsSubmitting(true);
    try {
      const response = await fetch(`${config.visitorAccessUrl}/access/register`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${localStorage.getItem('accessToken')}`,
        },
        body: JSON.stringify({
          residencyId: form.residencyId,
          rg: form.rg,
          cpf: form.cpf,
          name: form.name,
          entryAt: form.entryAt || undefined,
        }),
      });

      if (!response.ok) {
        const message = await response.text();
        throw new Error(message || 'Falha ao registrar acesso.');
      }

      notify('Acesso registrado', 'Entrada registrada com sucesso.', 'success');
      setForm(initialForm);
      setResidencyQuery(form.residencyId);
    } catch (error) {
      console.error(error);
      notify('Erro', 'Nao foi possivel registrar o acesso.', 'error');
    } finally {
      setIsSubmitting(false);
    }
  }

  return (
    <div className="h-full overflow-auto p-4 md:p-8">
      <div className="mb-6 flex flex-col gap-2">
        <div className="flex items-center gap-2 text-cyan-300">
          <ShieldCheck size={22} />
          <span className="text-sm font-semibold tracking-wide uppercase">Acessos</span>
        </div>
        <h1 className="text-2xl font-bold text-neutral-100">Gestao de acesso de visitantes</h1>
        <p className="max-w-3xl text-neutral-400">
          Registre entradas e consulte historico por residencia.
        </p>
      </div>

      <div className="grid grid-cols-1 gap-4 xl:grid-cols-2">
        <section className="rounded-lg border border-neutral-800 bg-neutral-900/40 p-4">
          <div className="mb-4 flex items-center gap-2 text-neutral-100">
            <UserPlus size={18} />
            <h2 className="text-lg font-semibold">Registrar entrada</h2>
          </div>

          <form className="grid grid-cols-1 gap-3 md:grid-cols-2" onSubmit={handleSubmit}>
            <label className="block md:col-span-2">
              <span className="mb-1 block text-sm text-neutral-300">ResidencyId</span>
              <input
                className="w-full rounded-md border border-neutral-700 bg-neutral-950 px-3 py-2 text-sm"
                value={form.residencyId}
                onChange={(e) => updateForm('residencyId', e.target.value)}
                placeholder="UUID da residencia"
              />
            </label>
            <label className="block">
              <span className="mb-1 block text-sm text-neutral-300">Nome</span>
              <input
                className="w-full rounded-md border border-neutral-700 bg-neutral-950 px-3 py-2 text-sm"
                value={form.name}
                onChange={(e) => updateForm('name', e.target.value)}
                placeholder="Ex.: Joao da Silva"
              />
            </label>
            <label className="block">
              <span className="mb-1 block text-sm text-neutral-300">CPF</span>
              <input
                className="w-full rounded-md border border-neutral-700 bg-neutral-950 px-3 py-2 text-sm"
                value={form.cpf}
                onChange={(e) => updateForm('cpf', e.target.value)}
                placeholder="000.000.000-00"
              />
            </label>
            <label className="block">
              <span className="mb-1 block text-sm text-neutral-300">RG</span>
              <input
                className="w-full rounded-md border border-neutral-700 bg-neutral-950 px-3 py-2 text-sm"
                value={form.rg}
                onChange={(e) => updateForm('rg', e.target.value)}
                placeholder="00.000.000-0"
              />
            </label>
            <label className="block">
              <span className="mb-1 block text-sm text-neutral-300">Data e hora</span>
              <input
                type="datetime-local"
                className="w-full rounded-md border border-neutral-700 bg-neutral-950 px-3 py-2 text-sm"
                value={form.entryAt}
                onChange={(e) => updateForm('entryAt', e.target.value)}
              />
            </label>
            <button
              type="submit"
              className="rounded-md bg-cyan-300 px-3 py-2 text-sm font-semibold text-neutral-950 transition hover:bg-cyan-200 md:col-span-2"
              disabled={isSubmitting}
            >
              {isSubmitting ? 'Registrando...' : 'Registrar acesso'}
            </button>
          </form>
        </section>

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
              onChange={(e) => setResidencyQuery(e.target.value)}
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
    </div>
  );
}
