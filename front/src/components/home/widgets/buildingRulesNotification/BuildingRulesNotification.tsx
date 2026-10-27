import { useEffect, useState } from 'react';
import { useTranslation } from 'react-i18next';
import { ClipboardList } from 'lucide-react';
import './styles.css';

interface BuildingRulesNotificationProps {
  isOpen: boolean;
  onClose: () => void;
  residentName: string;
  commonAreaName: string;
  reservationDate: string;
}

export function BuildingRulesNotification({
  isOpen,
  onClose,
  residentName,
  commonAreaName,
  reservationDate,
}: BuildingRulesNotificationProps) {
  const { i18n, t } = useTranslation();
  const [isVisible, setIsVisible] = useState(false);
  const locale = i18n.resolvedLanguage || i18n.language;

  useEffect(() => {
    if (isOpen) {
      setIsVisible(true);
    }
  }, [isOpen]);

  function handleClose() {
    setIsVisible(false);
    setTimeout(onClose, 300);
  }

  const rules = [
    {
      icon: '🔇',
      title: t('reservations:rules.items.quietHours.title'),
      description: t('reservations:rules.items.quietHours.description'),
    },
    {
      icon: '🧹',
      title: t('reservations:rules.items.cleaning.title'),
      description: t('reservations:rules.items.cleaning.description'),
    },
    {
      icon: '📢',
      title: t('reservations:rules.items.volume.title'),
      description: t('reservations:rules.items.volume.description'),
    },
    {
      icon: '🚫',
      title: t('reservations:rules.items.forbidden.title'),
      description: t('reservations:rules.items.forbidden.description'),
    },
    {
      icon: '👥',
      title: t('reservations:rules.items.capacity.title'),
      description: t('reservations:rules.items.capacity.description', { count: 50 }),
    },
    {
      icon: '⏰',
      title: t('reservations:rules.items.returnArea.title'),
      description: t('reservations:rules.items.returnArea.description'),
    },
  ];

  if (!isOpen) return null;

  return (
    <div
      className={`rules-notification-overlay ${isVisible ? 'visible' : ''}`}
      onClick={handleClose}
    >
      <div
        className={`rules-notification-modal ${isVisible ? 'visible' : ''}`}
        onClick={(e) => e.stopPropagation()}
      >
        <div className="rules-notification-header">
          <h2>✅ {t('reservations:rules.title')}</h2>
          <button type="button" className="close-btn" onClick={handleClose}>
            ✕
          </button>
        </div>

        <div className="rules-notification-content">
          <div className="reservation-details">
            <p className="detail-line">
              <span className="label">{t('reservations:rules.resident')}</span>
              <span className="value">{residentName}</span>
            </p>
            <p className="detail-line">
              <span className="label">{t('reservations:rules.commonArea')}</span>
              <span className="value">{commonAreaName}</span>
            </p>
            <p className="detail-line">
              <span className="label">{t('reservations:rules.date')}</span>
              <span className="value">{new Date(reservationDate).toLocaleDateString(locale)}</span>
            </p>
          </div>

          <div className="rules-section">
            <h3>
              <ClipboardList size={18} />
              {t('reservations:rules.importantRules')}
            </h3>
            <div className="rules-grid">
              {rules.map((rule, index) => (
                <div key={index} className="rule-card">
                  <div className="rule-icon">{rule.icon}</div>
                  <div className="rule-content">
                    <h4>{rule.title}</h4>
                    <p>{rule.description}</p>
                  </div>
                </div>
              ))}
            </div>
          </div>

          <div className="rules-notification-footer">
            <p className="acknowledgment">{t('reservations:rules.acknowledgment')}</p>
            <button type="button" className="confirm-btn" onClick={handleClose}>
              {t('reservations:rules.understood')}
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}
