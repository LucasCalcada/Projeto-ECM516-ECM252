import { defineConfig } from 'i18next-cli';

export default defineConfig({
  locales: ['en', 'pt', 'es'],
  extract: {
    input: './src/**/*.{ts,tsx,js,jsx}',
    output: './src/lang/{{language}}.json',
    ignore: ['node_modules/**', './src/lang/'],

    functions: ['t'],
    useTranslationNames: ['useTranslation'],

    defaultNS: false,
    preservePatterns: ['apps.calendar.months.*', 'apps.reservations.status.*', 'sidebar.routes.*'],

    sort: false,
    acceptedAttributes: ['*'],
  },
});
