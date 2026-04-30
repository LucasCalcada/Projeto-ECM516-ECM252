import type Package from '../../types/Packages';

interface PackagesTableProps {
  packages: Package[];
  isLoading: boolean;
}

export default function PackagesTable({ packages, isLoading }: PackagesTableProps) {
  if (isLoading) {
    return <div className="loading-container">Carregando encomendas...</div>;
  }

  if (packages.length === 0) {
    return <div className="empty-state">Nenhuma encomenda encontrada para esta residência.</div>;
  }

  return (
    <div className="table-container">
      <table className="packages-table">
        <thead>
          <tr>
            <th>Descrição</th>
            <th>Status</th>
            <th>Data de Recebimento</th>
            <th>Data de Entrega</th>
          </tr>
        </thead>
        <tbody>
          {packages.map((pkg) => (
            <tr key={pkg.id}>
              <td>{pkg.description}</td>
              <td>
                <span className={`status-badge ${pkg.status.toLowerCase()}`}>{pkg.status}</span>
              </td>
              <td>{new Date(pkg.createdAt).toLocaleDateString('pt-BR')}</td>
              <td>{pkg.deliveryAt ? new Date(pkg.deliveryAt).toLocaleDateString('pt-BR') : '-'}</td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}
