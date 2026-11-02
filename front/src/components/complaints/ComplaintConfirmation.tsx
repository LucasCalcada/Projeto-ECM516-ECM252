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
      className="m-auto max-h-[calc(100dvh-2rem)] w-[calc(100%-2rem)] max-w-xl overflow-auto rounded-lg border-0 bg-neutral-800 p-6 text-neutral-300 backdrop:bg-black/60"
      aria-labelledby={`${id}-title`}
      aria-describedby={`${id}-message`}
      onCancel={(event) => {
        event.preventDefault();
        if (!pending) onCancel();
      }}
    >
      <h2 id={`${id}-title`} className="text-xl font-semibold wrap-anywhere text-neutral-100">
        {title}
      </h2>
      <p id={`${id}-message`} className="mt-4 wrap-anywhere">
        {message}
      </p>
      <div className="mt-4 flex flex-wrap gap-2">
        <button
          type="button"
          autoFocus
          className="inline-flex min-h-11 min-w-11 cursor-pointer items-center justify-center gap-2 rounded-md bg-neutral-800 px-3 py-2 text-sm font-semibold text-neutral-100 transition-colors hover:bg-neutral-700 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-cyan-300 disabled:cursor-not-allowed disabled:opacity-60 motion-reduce:transition-none"
          disabled={pending}
          onClick={onCancel}
        >
          {t('cancel')}
        </button>
        <button
          type="button"
          className="inline-flex min-h-11 min-w-11 cursor-pointer items-center justify-center gap-2 rounded-md bg-cyan-300 px-3 py-2 text-sm font-semibold text-neutral-950 transition-colors hover:bg-cyan-200 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-cyan-300 disabled:cursor-not-allowed disabled:opacity-60 motion-reduce:transition-none"
          disabled={pending}
          onClick={onConfirm}
        >
          {pending ? t('saving') : confirmLabel}
        </button>
      </div>
    </dialog>
  );
}
