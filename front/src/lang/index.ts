import i18n from 'i18next';
import { initReactI18next } from 'react-i18next';
import pt from './pt/';
import en from './en/';
import es from './es/';

i18n.use(initReactI18next).init({
  lng: localStorage.getItem('language') || 'pt',

  ns: [
    'shell',
    'login',
    'announcements',
    'reservations',
    'calendar',
    'packages',
    'visitorAccess',
    'common',
  ],
  defaultNS: 'shell',

  resources: {
    pt,
    en,
    es,
  },
});

i18n.on('languageChanged', (language) => {
  localStorage.setItem('language', language);
  document.documentElement.lang = language;
});

document.documentElement.lang = i18n.language;

export default i18n;
