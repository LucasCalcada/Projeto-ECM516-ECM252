import i18n from 'i18next';
import { initReactI18next } from 'react-i18next';
import pt from './pt/';
import en from './en/';
import es from './es/';

i18n.use(initReactI18next).init({
  lng: 'pt',

  ns: ['shell', 'login', 'announcements', 'reservations', 'calendar', 'packages', 'common'],
  defaultNS: 'shell',

  resources: {
    pt,
    en,
    es,
  },
});

export default i18n;
