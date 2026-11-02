import { useEffect, useId, useRef } from 'react';
import { useTranslation } from 'react-i18next';

export default function ComplaintConfirmation({
  title,
  message,
  confirmLabel,
  pending = false,
  onConfirm,
  onCancel,
}: {
  title: string;
  message: string;
  confirmLabel: string;
  pending?: boolean;
  onConfirm: () => void;
  onCancel: () => void;
}) {
  const { t } = useTranslation('complaints');
  const dialog = useRef<HTMLDialogElement>(null);
  const id = useId();
  useEffect(() => {
    const previous = document.activeElement;
    dialog.current?.showModal();
    return () => {
      if (previous instanceof HTMLElement && previous.isConnected) previous.focus();
    };
  }, []);
  return (
    <dialog
      ref={dialog}
      className="complaint-dialog"
      aria-labelledby={`${id}-title`}
      aria-describedby={`${id}-message`}
      onCancel={(event) => {
        event.preventDefault();
        if (!pending) onCancel();
      }}
    >
      <h2 id={`${id}-title`}>{title}</h2>
      <p id={`${id}-message`}>{message}</p>
      <div className="complaint-actions">
        <button
          type="button"
          autoFocus
          className="complaint-button complaint-secondary"
          disabled={pending}
          onClick={onCancel}
        >
          {t('cancel')}
        </button>
        <button
          type="button"
          className="complaint-button complaint-primary"
          disabled={pending}
          onClick={onConfirm}
        >
          {pending ? t('saving') : confirmLabel}
        </button>
      </div>
    </dialog>
  );
}
