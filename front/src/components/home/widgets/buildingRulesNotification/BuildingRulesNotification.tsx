import { useEffect, useState } from 'react';
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
  const [isVisible, setIsVisible] = useState(false);

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
      title: 'Horário de Silêncio',
      description:
        'De segunda a sexta: turno noturno (22h às 8h). Finais de semana: todo dia até às 21h.',
    },
    {
      icon: '🧹',
      title: 'Equipe de Limpeza',
      description:
        'Terças e quintas-feiras, das 8h às 11h. Permitido circulação normal nestes períodos.',
    },
    {
      icon: '📢',
      title: 'Volume Máximo',
      description:
        'Respeite os vizinhos. Evite música alta, festas prolongadas e barulhos excessivos.',
    },
    {
      icon: '🚫',
      title: 'Proibido',
      description: 'Não é permitido bebidas alcoólicas fora do período autorizado (16h - 23h).',
    },
    {
      icon: '👥',
      title: 'Limite de Pessoas',
      description: `Máximo de ${50} pessoas simultâneas na área comum reservada.`,
    },
    {
      icon: '⏰',
      title: 'Devolução da Área',
      description: 'A área deve ser devolvida em perfeito estado ao final do período de reserva.',
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
          <h2>✅ Reserva Confirmada!</h2>
          <button type="button" className="close-btn" onClick={handleClose}>
            ✕
          </button>
        </div>

        <div className="rules-notification-content">
          <div className="reservation-details">
            <p className="detail-line">
              <span className="label">Morador:</span>
              <span className="value">{residentName}</span>
            </p>
            <p className="detail-line">
              <span className="label">Área Comum:</span>
              <span className="value">{commonAreaName}</span>
            </p>
            <p className="detail-line">
              <span className="label">Data:</span>
              <span className="value">{new Date(reservationDate).toLocaleDateString('pt-BR')}</span>
            </p>
          </div>

          <div className="rules-section">
            <h3>📋 Regras Importantes do Prédio:</h3>
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
            <p className="acknowledgment">
              Você reconhece que leu e concorda com as regras do condomínio.
            </p>
            <button type="button" className="confirm-btn" onClick={handleClose}>
              Entendido
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}
