import { useEffect, useState } from 'react';
import type { CommonArea } from '../types/CommonArea';
import useService from './useService';

export default function useCommonAreas() {
  const reservationService = useService('reservation');
  const [commonAreas, setCommonAreas] = useState<CommonArea[]>([]);
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<unknown>(null);

  useEffect(() => {
    async function fetchCommonAreas() {
      try {
        setIsLoading(true);
        setError(null);

        const response = await reservationService.get<CommonArea[]>('/common-areas');
        setCommonAreas(response.data);
      } catch (err) {
        console.error('Erro ao buscar áreas comuns:', err);
        setError(err);
      } finally {
        setIsLoading(false);
      }
    }

    fetchCommonAreas();
  }, [reservationService]);

  return {
    commonAreas,
    isLoading,
    error,
  };
}
