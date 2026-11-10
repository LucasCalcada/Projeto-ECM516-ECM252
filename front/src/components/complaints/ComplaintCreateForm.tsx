import { useEffect, useId, useRef, useState, type FormEvent } from 'react';
import axios from 'axios';
import { useTranslation } from 'react-i18next';
import { ArrowLeft, Send } from 'lucide-react';
import useService from '../../helpers/useService';
import {
  complaintCategories,
  type ComplaintDraft,
  type ComplaintFailure,
} from '../../types/Complaint';
import ComplaintConfirmation from './ComplaintConfirmation';
import ComplaintFeedback from './ComplaintFeedback';
import { useToast } from '../Toast';

const emptyDraft: ComplaintDraft = { title: '', category: '', description: '' };

export default function ComplaintCreateForm({
  onCreated,
  onCancel,
  onDirtyChange,
  onPendingChange,
  onUnauthorized,
}: {
  onCreated: () => void;
  onCancel: () => void;
  onDirtyChange: (dirty: boolean) => void;
  onPendingChange: (pending: boolean) => void;
  onUnauthorized: () => void;
}) {
  const { t } = useTranslation('complaints');
  const service = useService('complaint');
  const { notify } = useToast();
  const [draft, onChange] = useState<ComplaintDraft>(emptyDraft);
  const [pending, setPending] = useState(false);
  const [submitted, setSubmitted] = useState(false);
  const [discard, setDiscard] = useState(false);
  const [error, setError] = useState<ComplaintFailure | null>(null);
  const [notice, setNotice] = useState<string | null>(null);
  const form = useRef<HTMLFormElement>(null);
  const mounted = useRef(false);
  const locked = useRef(false);
  const id = useId();
  const dirty = Boolean(draft.title || draft.category || draft.description);
  useEffect(() => {
    mounted.current = true;
    return () => {
      mounted.current = false;
      onDirtyChange(false);
      onPendingChange(false);
    };
  }, [onDirtyChange, onPendingChange]);
  useEffect(() => {
    onDirtyChange(dirty);
  }, [dirty, onDirtyChange]);
  useEffect(() => {
    onPendingChange(pending);
  }, [pending, onPendingChange]);
  const invalidTitle =
    !draft.title.trim() || draft.title.trim().length > 200 || draft.title.includes('\0');
  const invalidCategory = !complaintCategories.includes(draft.category as never);
  const invalidDescription =
    !draft.description.trim() ||
    draft.description.trim().length > 10000 ||
    draft.description.includes('\0');

  async function submit(event: FormEvent) {
    event.preventDefault();
    if (locked.current) return;
    setSubmitted(true);
    if (invalidTitle || invalidCategory || invalidDescription) {
      window.setTimeout(
        () => form.current?.querySelector<HTMLElement>('[aria-invalid="true"]')?.focus(),
        0,
      );
      return;
    }
    locked.current = true;
    setPending(true);
    setError(null);
    setNotice(null);
    try {
      const result = await service.post(
        '/complaints',
        {
          title: draft.title.trim(),
          category: draft.category,
          description: draft.description.trim(),
        },
        { timeout: 15000 },
      );
      if (!mounted.current) return;
      if (!result.data || typeof result.data.id !== 'string') throw new Error('Invalid complaint');
      onChange(emptyDraft);
      setSubmitted(false);
      setNotice('created');
      notify(t('title'), t('notices.created'), 'success');
      onDirtyChange(false);
      onCreated();
    } catch (failure) {
      if (!mounted.current) return;
      const status = axios.isAxiosError(failure) ? failure.response?.status : undefined;
      if (status === 401) {
        onUnauthorized();
        return;
      }
      setError(
        status === 403
          ? 'forbidden'
          : [400, 413, 415].includes(status ?? 0)
            ? 'invalid'
            : axios.isAxiosError(failure) && !failure.response
              ? 'network'
              : 'server',
      );
    } finally {
      locked.current = false;
      if (mounted.current) setPending(false);
    }
  }
  function leave() {
    setDiscard(false);
    onChange(emptyDraft);
    setSubmitted(false);
    onDirtyChange(false);
    onCancel();
  }
  function cancel() {
    if (locked.current) return;
    if (dirty) setDiscard(true);
    else leave();
  }
  return (
    <section data-testid="complaint-create" className="min-w-0 rounded-lg bg-neutral-900 p-4">
      <button
        type="button"
        className="inline-flex min-h-11 min-w-11 cursor-pointer items-center justify-center gap-2 rounded-md px-3 py-2 text-sm font-semibold text-neutral-300 transition-colors hover:bg-neutral-700 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-cyan-300 disabled:cursor-not-allowed disabled:opacity-60 motion-reduce:transition-none"
        onClick={cancel}
        disabled={pending}
      >
        <ArrowLeft size={16} aria-hidden="true" />
        {t('back')}
      </button>
      <h2 className="text-xl font-semibold wrap-anywhere text-neutral-100">{t('newTitle')}</h2>
      <p className="text-base wrap-anywhere text-neutral-400">{t('form.help')}</p>
      <ComplaintFeedback error={error} notice={notice} />
      <form ref={form} onSubmit={submit} noValidate className="mt-4 flex flex-col gap-2">
        <label htmlFor={`${id}-title`} className="text-sm font-medium">
          {t('form.title')} <span aria-hidden="true">*</span>
        </label>
        <input
          className="block min-h-11 w-full rounded-md border border-neutral-500 bg-neutral-950 px-3 py-2 text-sm text-neutral-100 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-cyan-300 disabled:cursor-not-allowed disabled:opacity-60 aria-invalid:border-red-400"
          id={`${id}-title`}
          value={draft.title}
          maxLength={200}
          required
          disabled={pending}
          onChange={(e) => onChange({ ...draft, title: e.target.value })}
          aria-invalid={submitted && invalidTitle}
          aria-describedby={`${id}-title-help${submitted && invalidTitle ? ` ${id}-title-error` : ''}`}
        />
        <p id={`${id}-title-help`} className="text-xs wrap-anywhere text-neutral-400">
          {t('form.counter', { length: draft.title.length, max: 200 })}
        </p>
        {submitted && invalidTitle && (
          <p id={`${id}-title-error`} className="text-sm text-red-400">
            {t('form.titleError')}
          </p>
        )}
        <label htmlFor={`${id}-category`} className="mt-2 text-sm font-medium">
          {t('form.category')} <span aria-hidden="true">*</span>
        </label>
        <select
          className="block min-h-11 w-full rounded-md border border-neutral-500 bg-neutral-950 px-3 py-2 text-sm text-neutral-100 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-cyan-300 disabled:cursor-not-allowed disabled:opacity-60 aria-invalid:border-red-400"
          id={`${id}-category`}
          value={draft.category}
          required
          disabled={pending}
          onChange={(e) => onChange({ ...draft, category: e.target.value })}
          aria-invalid={submitted && invalidCategory}
          aria-describedby={submitted && invalidCategory ? `${id}-category-error` : undefined}
        >
          <option value="">{t('form.chooseCategory')}</option>
          {complaintCategories.map((category) => (
            <option key={category} value={category}>
              {t(`category.${category}`)}
            </option>
          ))}
        </select>
        {submitted && invalidCategory && (
          <p id={`${id}-category-error`} className="text-sm text-red-400">
            {t('form.categoryError')}
          </p>
        )}
        <label htmlFor={`${id}-description`} className="mt-2 text-sm font-medium">
          {t('form.description')} <span aria-hidden="true">*</span>
        </label>
        <textarea
          className="block min-h-11 w-full resize-y rounded-md border border-neutral-500 bg-neutral-950 px-3 py-2 text-sm text-neutral-100 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-cyan-300 disabled:cursor-not-allowed disabled:opacity-60 aria-invalid:border-red-400"
          id={`${id}-description`}
          value={draft.description}
          maxLength={10000}
          rows={7}
          required
          disabled={pending}
          onChange={(e) => onChange({ ...draft, description: e.target.value })}
          aria-invalid={submitted && invalidDescription}
          aria-describedby={`${id}-description-help${submitted && invalidDescription ? ` ${id}-description-error` : ''}`}
        />
        <p id={`${id}-description-help`} className="text-xs wrap-anywhere text-neutral-400">
          {t('form.counter', { length: draft.description.length, max: 10000 })}
        </p>
        {submitted && invalidDescription && (
          <p id={`${id}-description-error`} className="text-sm text-red-400">
            {t('form.descriptionError')}
          </p>
        )}
        <div className="mt-4 flex flex-wrap gap-2">
          <button
            type="button"
            className="inline-flex min-h-11 min-w-11 cursor-pointer items-center justify-center gap-2 rounded-md bg-neutral-800 px-3 py-2 text-sm font-semibold text-neutral-100 transition-colors hover:bg-neutral-700 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-cyan-300 disabled:cursor-not-allowed disabled:opacity-60 motion-reduce:transition-none"
            onClick={cancel}
            disabled={pending}
          >
            {t('cancel')}
          </button>
          <button
            type="submit"
            className="inline-flex min-h-11 min-w-11 cursor-pointer items-center justify-center gap-2 rounded-md bg-cyan-300 px-3 py-2 text-sm font-semibold text-neutral-950 transition-colors hover:bg-cyan-200 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-cyan-300 disabled:cursor-not-allowed disabled:opacity-60 motion-reduce:transition-none"
            disabled={pending}
          >
            <Send size={16} aria-hidden="true" />
            {pending ? t('sending') : t('form.submit')}
          </button>
        </div>
      </form>
      {discard && (
        <ComplaintConfirmation
          title={t('discardTitle')}
          message={t('discardMessage')}
          confirmLabel={t('discard')}
          onCancel={() => setDiscard(false)}
          onConfirm={leave}
        />
      )}
    </section>
  );
}
