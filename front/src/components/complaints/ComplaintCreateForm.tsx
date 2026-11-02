import { useEffect, useId, useRef, useState, type FormEvent } from 'react';
import { useTranslation } from 'react-i18next';
import { ArrowLeft, Send } from 'lucide-react';
import { complaintCategories, type ComplaintDraft } from '../../types/Complaint';

export default function ComplaintCreateForm({
  draft,
  onChange,
  onCancel,
  onSubmit,
  pending,
}: {
  draft: ComplaintDraft;
  onChange: (draft: ComplaintDraft) => void;
  onCancel: () => void;
  onSubmit: () => void;
  pending: boolean;
}) {
  const { t } = useTranslation('complaints');
  const [submitted, setSubmitted] = useState(false);
  const form = useRef<HTMLFormElement>(null);
  useEffect(() => {
    form.current?.querySelector('input')?.focus();
  }, []);
  const id = useId();
  const invalidTitle =
    !draft.title.trim() || draft.title.trim().length > 200 || draft.title.includes('\0');
  const invalidCategory = !complaintCategories.includes(draft.category as never);
  const invalidDescription =
    !draft.description.trim() ||
    draft.description.trim().length > 10000 ||
    draft.description.includes('\0');
  function submit(event: FormEvent) {
    event.preventDefault();
    setSubmitted(true);
    if (invalidTitle || invalidCategory || invalidDescription) {
      window.setTimeout(
        () => form.current?.querySelector<HTMLElement>('[aria-invalid="true"]')?.focus(),
        0,
      );
      return;
    }
    onSubmit();
  }
  return (
    <section className="complaint-panel complaint-create">
      <button
        type="button"
        className="complaint-button complaint-tertiary"
        onClick={onCancel}
        disabled={pending}
      >
        <ArrowLeft size={16} aria-hidden="true" />
        {t('back')}
      </button>
      <h2>{t('newTitle')}</h2>
      <p className="complaint-secondary-text">{t('form.help')}</p>
      <form ref={form} onSubmit={submit} noValidate className="complaint-form">
        <label htmlFor={`${id}-title`}>
          {t('form.title')} <span aria-hidden="true">*</span>
        </label>
        <input
          id={`${id}-title`}
          value={draft.title}
          maxLength={200}
          required
          disabled={pending}
          onChange={(e) => onChange({ ...draft, title: e.target.value })}
          aria-invalid={submitted && invalidTitle}
          aria-describedby={`${id}-title-help${submitted && invalidTitle ? ` ${id}-title-error` : ''}`}
        />
        <p id={`${id}-title-help`} className="complaint-help">
          {t('form.counter', { count: draft.title.length, max: 200 })}
        </p>
        {submitted && invalidTitle && (
          <p id={`${id}-title-error`} className="complaint-field-error">
            {t('form.titleError')}
          </p>
        )}
        <label htmlFor={`${id}-category`}>
          {t('form.category')} <span aria-hidden="true">*</span>
        </label>
        <select
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
          <p id={`${id}-category-error`} className="complaint-field-error">
            {t('form.categoryError')}
          </p>
        )}
        <label htmlFor={`${id}-description`}>
          {t('form.description')} <span aria-hidden="true">*</span>
        </label>
        <textarea
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
        <p id={`${id}-description-help`} className="complaint-help">
          {t('form.counter', { count: draft.description.length, max: 10000 })}
        </p>
        {submitted && invalidDescription && (
          <p id={`${id}-description-error`} className="complaint-field-error">
            {t('form.descriptionError')}
          </p>
        )}
        <div className="complaint-actions">
          <button
            type="button"
            className="complaint-button complaint-secondary"
            onClick={onCancel}
            disabled={pending}
          >
            {t('cancel')}
          </button>
          <button type="submit" className="complaint-button complaint-primary" disabled={pending}>
            <Send size={16} aria-hidden="true" />
            {pending ? t('sending') : t('form.submit')}
          </button>
        </div>
      </form>
    </section>
  );
}
