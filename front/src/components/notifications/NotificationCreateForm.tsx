import { type FormEvent, useState } from 'react';
import { Building2, Home, Send } from 'lucide-react';
import { useTranslation } from 'react-i18next';
import { useToast } from '../Toast';
import useService from '../../helpers/useService';
import useResidencies from '../../helpers/useResidencies';
import ResidencyPicker from './ResidencyPicker';
import type { NotificationAudience } from './types';

const inputClass =
  'w-full rounded-md border border-neutral-700 bg-neutral-950 px-3 py-2 text-sm text-neutral-100';

export default function NotificationCreateForm() {
  const { t } = useTranslation();
  const [title, setTitle] = useState('');
  const [description, setDescription] = useState('');
  const [eventAt, setEventAt] = useState('');
  const [audience, setAudience] = useState<NotificationAudience>('building');
  const [residencyIds, setResidencyIds] = useState<string[]>([]);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const { notifyError, notifySuccess, notifyWarning } = useToast();
  const communicationService = useService('communication');
  const { groups, isLoading: isLoadingResidencies, error: residenciesError } = useResidencies();

  function resetForm() {
    setTitle('');
    setDescription('');
    setEventAt('');
    setResidencyIds([]);
  }

  async function handleSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();

    if (!title.trim() || !description.trim()) {
      notifyWarning(
        t('notifications:form.toast.requiredTitle'),
        t('notifications:form.toast.requiredMessage'),
      );
      return;
    }

    if (audience === 'residencies' && residencyIds.length === 0) {
      notifyWarning(
        t('notifications:form.toast.requiredTitle'),
        t('notifications:form.toast.residenciesRequired'),
      );
      return;
    }

    setIsSubmitting(true);
    try {
      await communicationService.post('/posts', {
        title: title.trim(),
        description: description.trim(),
        eventAt: eventAt ? new Date(eventAt).toISOString() : null,
        residencyIds: audience === 'residencies' ? residencyIds : [],
      });

      notifySuccess(
        t('notifications:form.toast.successTitle'),
        t('notifications:form.toast.successMessage'),
      );
      resetForm();
    } catch (error) {
      console.error(error);
      notifyError(t('common:error'), t('notifications:form.toast.createError'));
    } finally {
      setIsSubmitting(false);
    }
  }

  const audienceOptions = [
    { value: 'building' as const, icon: Building2 },
    { value: 'residencies' as const, icon: Home },
  ];

  return (
    <section className="rounded-lg border border-neutral-800 bg-neutral-900/40 p-4">
      <form className="grid grid-cols-1 gap-4 md:grid-cols-2" onSubmit={handleSubmit}>
        <label className="block md:col-span-2">
          <span className="mb-1 block text-sm text-neutral-300">
            {t('notifications:form.title')}
          </span>
          <input
            className={inputClass}
            value={title}
            maxLength={160}
            onChange={(event) => setTitle(event.target.value)}
            placeholder={t('notifications:form.titlePlaceholder')}
          />
        </label>

        <label className="block md:col-span-2">
          <span className="mb-1 block text-sm text-neutral-300">{t('common:description')}</span>
          <textarea
            className={`${inputClass} min-h-28 resize-y`}
            value={description}
            onChange={(event) => setDescription(event.target.value)}
            placeholder={t('notifications:form.descriptionPlaceholder')}
          />
        </label>

        <label className="block">
          <span className="mb-1 block text-sm text-neutral-300">
            {t('notifications:form.eventAt')}
          </span>
          <input
            type="datetime-local"
            className={`${inputClass} [color-scheme:dark]`}
            value={eventAt}
            onChange={(event) => setEventAt(event.target.value)}
          />
          <span className="mt-1 block text-xs text-neutral-500">
            {t('notifications:form.eventAtHint')}
          </span>
        </label>

        <div>
          <span className="mb-1 block text-sm text-neutral-300">
            {t('notifications:form.audience')}
          </span>
          <div className="flex flex-wrap gap-2">
            {audienceOptions.map(({ value, icon: Icon }) => {
              const isActive = audience === value;
              return (
                <button
                  key={value}
                  type="button"
                  aria-pressed={isActive}
                  className={`inline-flex items-center gap-2 rounded-md border px-3 py-2 text-sm font-semibold transition ${
                    isActive
                      ? 'border-cyan-300 bg-cyan-300/10 text-cyan-200'
                      : 'border-neutral-700 bg-neutral-950 text-neutral-200 hover:bg-neutral-800'
                  }`}
                  onClick={() => setAudience(value)}
                >
                  <Icon size={16} />
                  {t(`notifications:audience.options.${value}`)}
                </button>
              );
            })}
          </div>
        </div>

        {audience === 'residencies' && (
          <div className="md:col-span-2">
            <div className="mb-2 flex items-center justify-between">
              <span className="text-sm text-neutral-300">
                {t('notifications:form.residencies')}
              </span>
              <span className="text-xs text-neutral-500">
                {t('notifications:form.selectedCount', { count: residencyIds.length })}
              </span>
            </div>
            {isLoadingResidencies ? (
              <p className="text-sm text-neutral-400">{t('common:loadingEllipsis')}</p>
            ) : residenciesError ? (
              <p className="text-sm text-red-300">
                {t('notifications:form.toast.loadResidenciesError')}
              </p>
            ) : (
              <ResidencyPicker
                groups={groups}
                selectedIds={residencyIds}
                onChange={setResidencyIds}
                disabled={isSubmitting}
              />
            )}
          </div>
        )}

        <button
          type="submit"
          className="inline-flex items-center justify-center gap-2 rounded-md bg-cyan-300 px-3 py-2 text-sm font-semibold text-neutral-950 transition hover:bg-cyan-200 disabled:cursor-not-allowed disabled:opacity-60 md:col-span-2"
          disabled={isSubmitting}
        >
          <Send size={16} />
          {isSubmitting ? t('notifications:form.submitting') : t('notifications:form.submit')}
        </button>
      </form>
    </section>
  );
}
