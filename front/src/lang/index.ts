import i18n from "i18next";
import { initReactI18next } from "react-i18next";

import pt from "./pt.json";
import en from "./en.json";

const resources = {
  pt: {
    translation: pt,
  },
  en: {
    translation: en,
  },
};

i18n.use(initReactI18next).init({
  resources,
  lng: "pt",
});

export default i18n;
