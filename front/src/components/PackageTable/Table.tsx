import { useTranslation } from 'react-i18next';
import type Package from '../../types/Packages';

interface PackagesTableProps {
  packages: Package[];
  isLoading: boolean;
}

export default function PackagesTable({ packages, isLoading }: PackagesTableProps) {
  const { i18n, t } = useTranslation();
  const locale = i18n.resolvedLanguage || i18n.language;

  if (isLoading) {
    return <div className="loading-container">{t('packages:loading')}</div>;
  }

  if (packages.length === 0) {
    return <div className="empty-state">{t('packages:notFound')}</div>;
  }

  return (
    <div className="table-container">
      <table className="packages-table">
        <thead>
          <tr>
            <th>{t('packages:table.description')}</th>
            <th>{t('packages:table.status')}</th>
            <th>{t('packages:table.receivedAt')}</th>
            <th>{t('packages:table.deliveredAt')}</th>
          </tr>
        </thead>
        <tbody>
          {packages.map((pkg) => (
            <tr key={pkg.id}>
              <td>{pkg.description}</td>
              <td>
                <span className={`status-badge ${pkg.status.toLowerCase()}`}>
                  {t(`packages:statusValue.${pkg.status}`, { defaultValue: pkg.status })}
                </span>
              </td>
              <td>{new Date(pkg.createdAt).toLocaleDateString(locale)}</td>
              <td>
                {pkg.deliveredAt ? new Date(pkg.deliveredAt).toLocaleDateString(locale) : '-'}
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}
