import { type FormEvent, useCallback, useEffect, useMemo, useState } from 'react';
import { PackagePlus, RefreshCw } from 'lucide-react';
import { useToast } from '../Toast';
import useService from '../../helpers/useService';

interface ResidencyDetails {
  id: string;
  name: string | null;
}

interface ResidencyGroupDetails {
  id: string;
  name: string | null;
  residencies: ResidencyDetails[];
}

interface BuildingDetailsResponse {
  residentData: ResidencyGroupDetails[];
}

interface ResidencyOption {
  id: string;
  name: string;
  label: string;
}

interface PackageCreateFormProps {
  buildingId: string | null;
}

const initialDescription = '';

export default function PackageCreateForm({ buildingId }: PackageCreateFormProps) {
  const [residencies, setResidencies] = useState<ResidencyOption[]>([]);
  const [selectedResidencyName, setSelectedResidencyName] = useState('');
  const [description, setDescription] = useState(initialDescription);
  const [isLoadingResidencies, setIsLoadingResidencies] = useState(false);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const { notifyError, notifySuccess, notifyWarning } = useToast();
  const coreService = useService('core');
  const deliveryService = useService('delivery');

  const sortedResidencies = useMemo(
    () => [...residencies].sort((a, b) => a.label.localeCompare(b.label)),
    [residencies],
  );

  const fetchResidencies = useCallback(async () => {
    if (!buildingId) {
      notifyError('Erro', 'Não foi possível identificar o prédio do usuário.');
      return;
    }

    setIsLoadingResidencies(true);
    try {
      const response = await coreService.get<BuildingDetailsResponse>(
        `/building/${buildingId}/details`,
      );

      const options = response.data.residentData.flatMap((group) =>
        group.residencies
          .filter((residency): residency is { id: string; name: string } => residency.name !== null)
          .map((residency) => ({
            id: residency.id,
            name: residency.name,
            label: residency.name,
          })),
      );

      setResidencies(options);
      setSelectedResidencyName((current) => current || options[0]?.name || '');
    } catch (error) {
      console.error(error);
      notifyError('Erro', 'Não foi possível carregar as residências.');
    } finally {
      setIsLoadingResidencies(false);
    }
  }, [buildingId, coreService, notifyError]);

  useEffect(() => {
    fetchResidencies();
  }, [fetchResidencies]);

  async function handleSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();

    if (!selectedResidencyName || !description.trim()) {
      notifyWarning('Campos obrigatórios', 'Selecione uma residência e informe a descrição.');
      return;
    }

    setIsSubmitting(true);
    try {
      await deliveryService.post('/packages', {
        residencyName: selectedResidencyName,
        description: description.trim(),
      });

      notifySuccess('Encomenda registrada', 'O pacote foi registrado com sucesso.');
      setDescription(initialDescription);
    } catch (error) {
      console.error(error);
      notifyError('Erro', 'Não foi possível registrar a encomenda.');
    } finally {
      setIsSubmitting(false);
    }
  }

  return (
    <section className="rounded-lg border border-neutral-800 bg-neutral-900/40 p-4">
      <div className="mb-4 flex flex-wrap items-center justify-between gap-3">
        <div className="flex items-center gap-2 text-neutral-100">
          <PackagePlus size={18} />
          <h2 className="text-lg font-semibold">Nova encomenda</h2>
        </div>
        <button
          type="button"
          className="inline-flex items-center gap-2 rounded-md bg-neutral-800 px-3 py-2 text-sm font-semibold text-neutral-100 transition hover:bg-neutral-700 disabled:cursor-not-allowed disabled:opacity-60"
          onClick={fetchResidencies}
          disabled={isLoadingResidencies}
        >
          <RefreshCw size={16} />
          {isLoadingResidencies ? 'Atualizando...' : 'Atualizar residências'}
        </button>
      </div>

      <form className="grid grid-cols-1 gap-3 md:grid-cols-2" onSubmit={handleSubmit}>
        <label className="block">
          <span className="mb-1 block text-sm text-neutral-300">Residência</span>
          <select
            className="w-full rounded-md border border-neutral-700 bg-neutral-950 px-3 py-2 text-sm"
            value={selectedResidencyName}
            onChange={(event) => setSelectedResidencyName(event.target.value)}
            disabled={isLoadingResidencies || sortedResidencies.length === 0}
          >
            {sortedResidencies.length === 0 ? (
              <option value="">Nenhuma residência encontrada</option>
            ) : (
              sortedResidencies.map((residency) => (
                <option key={residency.id} value={residency.name}>
                  {residency.label}
                </option>
              ))
            )}
          </select>
        </label>

        <label className="block">
          <span className="mb-1 block text-sm text-neutral-300">Descrição</span>
          <input
            className="w-full rounded-md border border-neutral-700 bg-neutral-950 px-3 py-2 text-sm"
            value={description}
            onChange={(event) => setDescription(event.target.value)}
            placeholder="Ex.: Pacote Amazon"
          />
        </label>

        <button
          type="submit"
          className="rounded-md bg-cyan-300 px-3 py-2 text-sm font-semibold text-neutral-950 transition hover:bg-cyan-200 disabled:cursor-not-allowed disabled:opacity-60 md:col-span-2"
          disabled={isSubmitting || isLoadingResidencies || sortedResidencies.length === 0}
        >
          {isSubmitting ? 'Registrando...' : 'Registrar encomenda'}
        </button>
      </form>
    </section>
  );
}
