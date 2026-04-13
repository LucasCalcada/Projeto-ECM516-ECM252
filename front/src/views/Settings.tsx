import { useState, useEffect } from 'react';
import { useTranslation } from 'react-i18next';
import { useTheme } from '../contexts/useThemeHook';

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
    setSuccessMessage(t('apps.settings.messages.profileUpdated'));
  }

  return (
    <div
      className={`h-full p-4 md:p-8 transition-colors ${theme === 'light' ? 'bg-neutral-100' : 'bg-gradient-to-br from-neutral-900/50 to-neutral-950'}`}
    >
      <div className="mb-8">
        <h1 className="text-3xl font-bold text-neutral-100">{t('apps.settings.title')}</h1>
        <p className={`mt-2 ${theme === 'light' ? 'text-neutral-600' : 'text-neutral-400'}`}>
          {t('apps.settings.subtitle')}
        </p>
      </div>

      {/* Success Message */}
      {successMessage && (
        <div className="mb-4 p-3 bg-green-500/20 border border-green-500 text-green-300 rounded-lg animate-pulse">
          ✓ {successMessage}
        </div>
      )}

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Perfil */}
        <section
          className={`lg:col-span-1 rounded-xl border transition-colors ${theme === 'light' ? 'border-neutral-300 bg-white' : 'border-neutral-800 bg-neutral-900/40'} p-6`}
        >
          <h2 className="text-xl font-bold text-neutral-100 mb-4">
            👤 {t('apps.settings.profile.title')}
          </h2>

          <div className="flex flex-col items-center gap-4 mb-6">
            <div className="w-16 h-16 rounded-full bg-gradient-to-br from-blue-500 to-purple-600 flex items-center justify-center text-white text-2xl font-bold">
              {profile.avatar}
            </div>
            <div className="text-center">
              <p className="text-neutral-100 font-semibold">{profile.name}</p>
              <p
                className={`text-sm ${theme === 'light' ? 'text-neutral-600' : 'text-neutral-400'}`}
              >
                {profile.apartment}
              </p>
            </div>
          </div>

          {!editingProfile ? (
            <>
              <div className="space-y-3 mb-4">
                <div>
                  <p
                    className={`text-xs font-semibold uppercase ${theme === 'light' ? 'text-neutral-600' : 'text-neutral-500'}`}
                  >
                    {t('apps.settings.profile.email')}
                  </p>
                  <p className="text-neutral-300">{profile.email}</p>
                </div>
                <div>
                  <p
                    className={`text-xs font-semibold uppercase ${theme === 'light' ? 'text-neutral-600' : 'text-neutral-500'}`}
                  >
                    {t('apps.settings.profile.phone')}
                  </p>
                  <p className="text-neutral-300">{profile.phone}</p>
                </div>
              </div>
              <button
                onClick={() => setEditingProfile(true)}
                className="w-full bg-blue-600 hover:bg-blue-700 text-white font-medium py-2 rounded-lg transition"
              >
                {t('apps.settings.profile.edit')}
              </button>
            </>
          ) : (
            <>
              <div className="space-y-3 mb-4">
                <input
                  type="text"
                  value={profile.name}
                  onChange={(e) => handleProfileChange('name', e.target.value)}
                  placeholder="Nome completo"
                  className={`w-full px-3 py-2 rounded-lg transition ${theme === 'light' ? 'bg-neutral-100 border border-neutral-300 text-neutral-900' : 'bg-neutral-800 border border-neutral-700 text-neutral-100 placeholder-neutral-500 focus:border-blue-500'} focus:outline-none`}
                />
                <input
                  type="email"
                  value={profile.email}
                  onChange={(e) => handleProfileChange('email', e.target.value)}
                  placeholder="Email"
                  className={`w-full px-3 py-2 rounded-lg transition ${theme === 'light' ? 'bg-neutral-100 border border-neutral-300 text-neutral-900' : 'bg-neutral-800 border border-neutral-700 text-neutral-100 placeholder-neutral-500 focus:border-blue-500'} focus:outline-none`}
                />
                <input
                  type="tel"
                  value={profile.phone}
                  onChange={(e) => handleProfileChange('phone', e.target.value)}
                  placeholder="Telefone"
                  className={`w-full px-3 py-2 rounded-lg transition ${theme === 'light' ? 'bg-neutral-100 border border-neutral-300 text-neutral-900' : 'bg-neutral-800 border border-neutral-700 text-neutral-100 placeholder-neutral-500 focus:border-blue-500'} focus:outline-none`}
                />
              </div>
              <div className="flex gap-2">
                <button
                  onClick={handleSaveProfile}
                  className="flex-1 bg-green-600 hover:bg-green-700 text-white font-medium py-2 rounded-lg transition"
                >
                  {t('apps.settings.profile.save')}
                </button>
                <button
                  onClick={() => setEditingProfile(false)}
                  className={`flex-1 font-medium py-2 rounded-lg transition ${theme === 'light' ? 'bg-neutral-200 text-neutral-900 hover:bg-neutral-300' : 'bg-neutral-700 text-white hover:bg-neutral-600'}`}
                >
                  {t('apps.settings.profile.cancel')}
                </button>
              </div>
            </>
          )}
        </section>

        {/* Idioma */}
        <section
          className={`lg:col-span-1 rounded-xl border transition-colors ${theme === 'light' ? 'border-neutral-300 bg-white' : 'border-neutral-800 bg-neutral-900/40'} p-6`}
        >
          <h2 className="text-xl font-bold text-neutral-100 mb-4">
            🌐 {t('apps.settings.language.title')}
          </h2>

          <div className="space-y-3">
            {[
              { code: 'pt', flag: '🇧🇷', name: 'Português' },
              { code: 'en', flag: '🇺🇸', name: 'English' },
              { code: 'es', flag: '🇪🇸', name: 'Español' },
            ].map(({ code, flag, name }) => (
              <button
                key={code}
                onClick={() => i18n.changeLanguage(code)}
                className={`w-full p-3 rounded-lg border transition flex items-center gap-3 ${
                  i18n.language === code
                    ? 'bg-blue-600/20 border-blue-500 text-blue-300'
                    : theme === 'light'
                      ? 'bg-neutral-100 border-neutral-300 text-neutral-900 hover:bg-neutral-200'
                      : 'bg-neutral-800 border-neutral-700 text-neutral-300 hover:bg-neutral-700/50'
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
