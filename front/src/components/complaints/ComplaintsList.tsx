import { ChevronRight, Inbox, RefreshCw } from 'lucide-react';
import { useTranslation } from 'react-i18next';
import {
  complaintCategories,
  type ComplaintFailure,
  type ComplaintFilters,
  type ComplaintSummary,
} from '../../types/Complaint';
import ComplaintStatusBadge from './ComplaintStatusBadge';
import ComplaintFeedback from './ComplaintFeedback';
import complaintDate from '../../helpers/formatComplaintDate';

export default function ComplaintsList({
  items,
  selectedId,
  filters,
  loading,
  error,
  hasMore,
  disabled,
  onFilters,
  onSelect,
  onRefresh,
  onMore,
}: {
  items: ComplaintSummary[];
  selectedId: string | null;
  filters: ComplaintFilters;
  loading: boolean;
  error: ComplaintFailure | null;
  hasMore: boolean;
  disabled: boolean;
  onFilters: (filters: ComplaintFilters) => void;
  onSelect: (id: string) => void;
  onRefresh: () => void;
  onMore: () => void;
}) {
  const { t, i18n } = useTranslation('complaints');
  return (
    <section
      className="complaint-panel complaint-list"
      aria-label={t('listTitle')}
      aria-busy={loading}
    >
      <div className="complaint-section-heading">
        <h2>{t('listTitle')}</h2>
        <button
          type="button"
          className="complaint-button complaint-secondary"
          disabled={disabled || loading}
          onClick={onRefresh}
        >
          <RefreshCw size={16} aria-hidden="true" />
          {t('refresh')}
        </button>
      </div>
      <div className="complaint-filters">
        <label>
          {t('filter.status')}
          <select
            value={filters.status}
            disabled={disabled}
            onChange={(e) => onFilters({ ...filters, status: e.target.value })}
          >
            <option value="">{t('all')}</option>
            {(['aberta', 'em_analise', 'encerrada'] as const).map((status) => (
              <option key={status} value={status}>
                {t(`status.${status}`)}
              </option>
            ))}
          </select>
        </label>
        <label>
          {t('filter.category')}
          <select
            value={filters.category}
            disabled={disabled}
            onChange={(e) => onFilters({ ...filters, category: e.target.value })}
          >
            <option value="">{t('all')}</option>
            {complaintCategories.map((category) => (
              <option key={category} value={category}>
                {t(`category.${category}`)}
              </option>
            ))}
          </select>
        </label>
      </div>
      {(filters.status || filters.category) && (
        <button
          type="button"
          disabled={disabled}
          className="complaint-button complaint-tertiary"
          onClick={() => onFilters({ status: '', category: '' })}
        >
          {t('clearFilters')}
        </button>
      )}
      <ComplaintFeedback error={error} retry={onRefresh} />
      {loading && (
        <p role="status" className="complaint-secondary-text">
          {items.length ? t('updating') : t('loading')}
        </p>
      )}
      {!loading && !error && !items.length && (
        <div className="complaint-empty">
          <Inbox size={32} aria-hidden="true" />
          <p>{filters.status || filters.category ? t('filteredEmpty') : t('empty')}</p>
        </div>
      )}
      <ul className="complaint-items">
        {items.map((item) => (
          <li key={item.id}>
            <button
              data-complaint-id={item.id}
              className={`complaint-list-item ${selectedId === item.id ? 'is-selected' : ''}`}
              disabled={disabled}
              type="button"
              aria-pressed={selectedId === item.id}
              onClick={() => onSelect(item.id)}
            >
              <span className="complaint-item-heading">
                <span className="complaint-item-title">{item.title}</span>
                <ChevronRight size={18} aria-hidden="true" />
              </span>
              <span className="complaint-item-category">{t(`category.${item.category}`)}</span>
              <span className="complaint-item-footer">
                <ComplaintStatusBadge status={item.status} />
                <time dateTime={item.createdAt}>
                  {complaintDate(item.createdAt, i18n.language)}
                </time>
              </span>
            </button>
          </li>
        ))}
      </ul>
      {hasMore && (
        <button
          type="button"
          className="complaint-button complaint-secondary complaint-more"
          disabled={loading || disabled}
          onClick={onMore}
        >
          {t('loadMore')}
        </button>
      )}
    </section>
  );
}
