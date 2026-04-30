import { useEffect, useState } from 'react';
import Table from '../components/PackageTable/Table';
import type Package from '../types/Packages';
import config from '../config';
export default function PackagesView() {
  const [packages, setPackages] = useState<Package[]>([]);
  const [loading, setLoading] = useState<boolean>(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    async function fetchPackages() {
      try {
        setLoading(true);
        setError(null);
        const response = await fetch(`${config.deliveryUrl}/packages/view`, {
          headers: {
            Authorization: `Bearer ${localStorage.getItem('accessToken')}`,
          },
        });
        const data = await response.json();
        setPackages(data);
      } catch (err) {
        console.error('Erro ao buscar encomendas:', err);
        setError('Ocorreu um erro ao carregar as encomendas. Tente novamente mais tarde.');
      } finally {
        setLoading(false);
      }
    }

    fetchPackages();
  }, []);

  return (
    <div className="packages-view-container">
      <header className="packages-header">
        <h1>Minhas Encomendas</h1>
        <p>Acompanhe aqui os pacotes recebidos na portaria.</p>
      </header>

      {error && <div className="error-message">{error}</div>}

      <section className="packages-content">
        <Table packages={packages} isLoading={loading} />
      </section>
    </div>
  );
}
