import { useTranslation } from 'react-i18next';
import { Globe } from 'lucide-react';

export default function Settings() {
  const { i18n, t } = useTranslation();
  const language = i18n.resolvedLanguage || i18n.language;

  return (
    <div className="h-full p-4 transition-colors md:p-8">
      <div className="mb-8">
        <h1 className="text-3xl font-bold text-neutral-100">{t('settings.title')}</h1>
        <p className="mt-2 text-neutral-400">{t('settings.subtitle')}</p>
      </div>

      <section className="max-w-xl rounded-lg border border-neutral-800 bg-neutral-900/40 p-6 transition-colors">
        <div className="mb-4 flex items-center gap-2 text-xl font-bold text-neutral-100">
          <Globe />
          <p>{t('settings.language.title')}</p>
        </div>

        <div className="space-y-3">
          {[
            { code: 'pt', flag: 'BR', name: t('settings.language.options.pt') },
            { code: 'en', flag: 'EN', name: t('settings.language.options.en') },
            { code: 'es', flag: 'ES', name: t('settings.language.options.es') },
          ].map(({ code, flag, name }) => (
            <button
              key={code}
              onClick={() => i18n.changeLanguage(code)}
              className={`flex w-full items-center gap-3 rounded-lg border p-3 transition ${
                language === code
                  ? 'border-blue-500 bg-blue-600/20 text-blue-300'
                  : 'border-neutral-700 bg-neutral-800 text-neutral-300 hover:bg-neutral-700/50'
              }`}
            >
              <span className="text-sm font-bold">{flag}</span>
              <span className="font-medium">{name}</span>
              {language === code && (
                <span className="ml-auto">{t('settings.language.selected')}</span>
              )}
            </button>
          ))}
        </div>
      </section>
    </div>
  );
}
