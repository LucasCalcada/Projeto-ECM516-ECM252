import { useCallback, useEffect, useState } from 'react';
import useService from './useService';

export interface ResidencyOption {
  id: string;
  name: string;
}

export interface ResidencyGroupOption {
  id: string;
  name: string;
  residencies: ResidencyOption[];
}

interface BuildingDetailsResponse {
  residentData: {
    id: string;
    name: string | null;
    residencies: { id: string; name: string | null }[];
  }[];
}

// Residencies of the current building, grouped by tower/block.
export default function useResidencies() {
  const coreService = useService('core');
  const [groups, setGroups] = useState<ResidencyGroupOption[]>([]);
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<unknown>(null);

  const fetchResidencies = useCallback(async () => {
    const buildingId = localStorage.getItem('buildingId');
    if (!buildingId) return;

    setIsLoading(true);
    setError(null);
    try {
      const response = await coreService.get<BuildingDetailsResponse>(
        `/building/${buildingId}/details`,
      );

      const options = response.data.residentData
        .map((group) => ({
          id: group.id,
          name: group.name ?? '',
          residencies: group.residencies
            .filter((residency): residency is ResidencyOption => residency.name !== null)
            .sort((a, b) => a.name.localeCompare(b.name)),
        }))
        .filter((group) => group.residencies.length > 0)
        .sort((a, b) => a.name.localeCompare(b.name));

      setGroups(options);
    } catch (err) {
      console.error(err);
      setError(err);
    } finally {
      setIsLoading(false);
    }
  }, [coreService]);

  useEffect(() => {
    fetchResidencies();
  }, [fetchResidencies]);

  return { groups, isLoading, error, refetch: fetchResidencies };
}
