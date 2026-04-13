import i18n from 'i18next';
import { initReactI18next } from 'react-i18next';
import pt from './pt/';

i18n.use(initReactI18next).init({
  lng: 'pt',

  ns: ['shell', 'date', 'login', 'announcements', 'reservations', 'calendar'],
  defaultNS: 'shell',

  resources: {
    pt,
  },
});

export default i18n;
