import { type FormEvent, useState } from 'react';
import { UserPlus } from 'lucide-react';
import { useToast } from '../Toast';
import useService from '../../helpers/useService';
import { useTranslation } from 'react-i18next';

interface AccessFormState {
  rg: string;
  cpf: string;
  name: string;
  entryAt: string;
}

const initialForm: AccessFormState = {
  rg: '',
  cpf: '',
  name: '',
  entryAt: '',
};

export default function VisitorAccessForm() {
  const { t } = useTranslation();
  const [form, setForm] = useState<AccessFormState>(initialForm);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const { notify } = useToast();
  const visitorService = useService('visitor');

  function updateForm<K extends keyof AccessFormState>(key: K, value: AccessFormState[K]) {
    setForm((prev) => ({ ...prev, [key]: value }));
  }

  async function handleSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();

    if (!form.name || !form.cpf || !form.rg) {
      notify(
        t('visitorAccess:form.toast.requiredTitle'),
        t('visitorAccess:form.toast.requiredMessage'),
        'warning',
      );
      return;
    }

    setIsSubmitting(true);
    try {
      await visitorService.post('/access/register', {
        rg: form.rg,
        cpf: form.cpf,
        name: form.name,
        entryAt: form.entryAt || undefined,
      });

      notify(
        t('visitorAccess:form.toast.successTitle'),
        t('visitorAccess:form.toast.successMessage'),
        'success',
      );
      setForm(initialForm);
    } catch (error) {
      console.error(error);
      notify(t('common:error'), t('visitorAccess:form.toast.createError'), 'error');
    } finally {
      setIsSubmitting(false);
    }
  }

  return (
    <section className="rounded-lg border border-neutral-800 bg-neutral-900/40 p-4">
      <div className="mb-4 flex items-center gap-2 text-neutral-100">
        <UserPlus size={18} />
        <h2 className="text-lg font-semibold">{t('visitorAccess:form.title')}</h2>
      </div>

      <form className="grid grid-cols-1 gap-3 md:grid-cols-2" onSubmit={handleSubmit}>
        <label className="block">
          <span className="mb-1 block text-sm text-neutral-300">{t('common:name')}</span>
          <input
            className="w-full rounded-md border border-neutral-700 bg-neutral-950 px-3 py-2 text-sm"
            value={form.name}
            onChange={(e) => updateForm('name', e.target.value)}
            placeholder={t('visitorAccess:form.namePlaceholder')}
          />
        </label>
        <label className="block">
          <span className="mb-1 block text-sm text-neutral-300">
            {t('visitorAccess:table.cpf')}
          </span>
          <input
            className="w-full rounded-md border border-neutral-700 bg-neutral-950 px-3 py-2 text-sm"
            value={form.cpf}
            onChange={(e) => updateForm('cpf', e.target.value)}
            placeholder="000.000.000-00"
          />
        </label>
        <label className="block">
          <span className="mb-1 block text-sm text-neutral-300">{t('visitorAccess:table.rg')}</span>
          <input
            className="w-full rounded-md border border-neutral-700 bg-neutral-950 px-3 py-2 text-sm"
            value={form.rg}
            onChange={(e) => updateForm('rg', e.target.value)}
            placeholder="00.000.000-0"
          />
        </label>
        <label className="block">
          <span className="mb-1 block text-sm text-neutral-300">{t('common:dateTime')}</span>
          <input
            type="datetime-local"
            className="w-full rounded-md border border-neutral-700 bg-neutral-950 px-3 py-2 text-sm"
            value={form.entryAt}
            onChange={(e) => updateForm('entryAt', e.target.value)}
          />
        </label>
        <button
          type="submit"
          className="rounded-md bg-cyan-300 px-3 py-2 text-sm font-semibold text-neutral-950 transition hover:bg-cyan-200 disabled:cursor-not-allowed disabled:opacity-60 md:col-span-2"
          disabled={isSubmitting}
        >
          {isSubmitting ? t('visitorAccess:form.submitting') : t('visitorAccess:form.submit')}
        </button>
      </form>
    </section>
  );
}
