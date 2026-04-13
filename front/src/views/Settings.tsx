import { useState, useEffect } from 'react';
import { useTranslation } from 'react-i18next';
import { useTheme } from '../contexts/useThemeHook';
import { Globe, User } from 'lucide-react';

interface UserProfile {
  name: string;
  email: string;
  phone: string;
  apartment: string;
  avatar: string;
}

export default function Settings() {
  const { i18n, t } = useTranslation();
  const { theme } = useTheme();

  const [profile, setProfile] = useState<UserProfile>({
    name: 'João Silva',
    email: 'joao.silva@email.com',
    phone: '+55 (11) 98765-4321',
    apartment: 'Apto 41',
    avatar: 'JS',
  });

  const [editingProfile, setEditingProfile] = useState(false);
  const [successMessage, setSuccessMessage] = useState('');

  useEffect(() => {
    if (successMessage) {
      const timer = setTimeout(() => setSuccessMessage(''), 3000);
      return () => clearTimeout(timer);
    }
  }, [successMessage]);

  function handleProfileChange(key: keyof UserProfile, value: string) {
    setProfile((prev) => ({ ...prev, [key]: value }));
  }

  function handleSaveProfile() {
    localStorage.setItem('userProfile', JSON.stringify(profile));
    setEditingProfile(false);
    setSuccessMessage(t('settings.messages.profileUpdated'));
  }

  return (
    <div className="h-full p-4 transition-colors md:p-8">
      <div className="mb-8">
        <h1 className="text-3xl font-bold text-neutral-100">{t('settings.title')}</h1>
        <p className={`mt-2 ${theme === 'light' ? 'text-neutral-600' : 'text-neutral-400'}`}>
          {t('settings.subtitle')}
        </p>
      </div>

      {/* Success Message */}
      {successMessage && (
        <div className="mb-4 animate-pulse rounded-lg border border-green-500 bg-green-500/20 p-3 text-green-300">
          ✓ {successMessage}
        </div>
      )}

      <div className="grid grid-cols-1 gap-6 lg:grid-cols-2">
        {/* Perfil */}
        <section
          className={`rounded-xl border transition-colors lg:col-span-1 ${theme === 'light' ? 'border-neutral-300 bg-white' : 'border-neutral-800 bg-neutral-900/40'} p-6`}
        >
          <div className="mb-4 flex items-center gap-2 text-xl font-bold text-neutral-100">
            <User />
            <p>{t('settings.profile.title')}</p>
          </div>

          <div className="mb-6 flex flex-col items-center gap-4">
            <div className="flex h-16 w-16 items-center justify-center rounded-full bg-gradient-to-br from-blue-500 to-purple-600 text-2xl font-bold text-white">
              {profile.avatar}
            </div>
            <div className="text-center">
              <p className="font-semibold text-neutral-100">{profile.name}</p>
              <p
                className={`text-sm ${theme === 'light' ? 'text-neutral-600' : 'text-neutral-400'}`}
              >
                {profile.apartment}
              </p>
            </div>
          </div>

          {!editingProfile ? (
            <>
              <div className="mb-4 space-y-3">
                <div>
                  <p
                    className={`text-xs font-semibold uppercase ${theme === 'light' ? 'text-neutral-600' : 'text-neutral-500'}`}
                  >
                    {t('settings.profile.email')}
                  </p>
                  <p className="text-neutral-300">{profile.email}</p>
                </div>
                <div>
                  <p
                    className={`text-xs font-semibold uppercase ${theme === 'light' ? 'text-neutral-600' : 'text-neutral-500'}`}
                  >
                    {t('settings.profile.phone')}
                  </p>
                  <p className="text-neutral-300">{profile.phone}</p>
                </div>
              </div>
              <button
                onClick={() => setEditingProfile(true)}
                className="w-full rounded-lg bg-blue-600 py-2 font-medium text-white transition hover:bg-blue-700"
              >
                {t('settings.profile.edit')}
              </button>
            </>
          ) : (
            <>
              <div className="mb-4 space-y-3">
                <input
                  type="text"
                  value={profile.name}
                  onChange={(e) => handleProfileChange('name', e.target.value)}
                  placeholder="Nome completo"
                  className={`w-full rounded-lg px-3 py-2 transition ${theme === 'light' ? 'border border-neutral-300 bg-neutral-100 text-neutral-900' : 'border border-neutral-700 bg-neutral-800 text-neutral-100 placeholder-neutral-500 focus:border-blue-500'} focus:outline-none`}
                />
                <input
                  type="email"
                  value={profile.email}
                  onChange={(e) => handleProfileChange('email', e.target.value)}
                  placeholder="Email"
                  className={`w-full rounded-lg px-3 py-2 transition ${theme === 'light' ? 'border border-neutral-300 bg-neutral-100 text-neutral-900' : 'border border-neutral-700 bg-neutral-800 text-neutral-100 placeholder-neutral-500 focus:border-blue-500'} focus:outline-none`}
                />
                <input
                  type="tel"
                  value={profile.phone}
                  onChange={(e) => handleProfileChange('phone', e.target.value)}
                  placeholder="Telefone"
                  className={`w-full rounded-lg px-3 py-2 transition ${theme === 'light' ? 'border border-neutral-300 bg-neutral-100 text-neutral-900' : 'border border-neutral-700 bg-neutral-800 text-neutral-100 placeholder-neutral-500 focus:border-blue-500'} focus:outline-none`}
                />
              </div>
              <div className="flex gap-2">
                <button
                  onClick={handleSaveProfile}
                  className="flex-1 rounded-lg bg-green-600 py-2 font-medium text-white transition hover:bg-green-700"
                >
                  {t('settings.profile.save')}
                </button>
                <button
                  onClick={() => setEditingProfile(false)}
                  className={`flex-1 rounded-lg py-2 font-medium transition ${theme === 'light' ? 'bg-neutral-200 text-neutral-900 hover:bg-neutral-300' : 'bg-neutral-700 text-white hover:bg-neutral-600'}`}
                >
                  {t('settings.profile.cancel')}
                </button>
              </div>
            </>
          )}
        </section>

        {/* Idioma */}
        <section
          className={`rounded-xl border transition-colors lg:col-span-1 ${theme === 'light' ? 'border-neutral-300 bg-white' : 'border-neutral-800 bg-neutral-900/40'} p-6`}
        >
          <div className="mb-4 flex items-center gap-2 text-xl font-bold text-neutral-100">
            <Globe />
            <p>{t('settings.language.title')}</p>
          </div>

          <div className="space-y-3">
            {[
              { code: 'pt', flag: '🇧🇷', name: 'Português' },
              { code: 'en', flag: '🇺🇸', name: 'English' },
              { code: 'es', flag: '🇪🇸', name: 'Español' },
            ].map(({ code, flag, name }) => (
              <button
                key={code}
                onClick={() => i18n.changeLanguage(code)}
                className={`flex w-full items-center gap-3 rounded-lg border p-3 transition ${
                  i18n.language === code
                    ? 'border-blue-500 bg-blue-600/20 text-blue-300'
                    : theme === 'light'
                      ? 'border-neutral-300 bg-neutral-100 text-neutral-900 hover:bg-neutral-200'
                      : 'border-neutral-700 bg-neutral-800 text-neutral-300 hover:bg-neutral-700/50'
                }`}
              >
                <span className="text-xl">{flag}</span>
                <span className="font-medium">{name}</span>
                {i18n.language === code && <span className="ml-auto">✓</span>}
              </button>
            ))}
          </div>
        </section>
      </div>
    </div>
  );
}
