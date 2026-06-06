import { defineConfig } from 'i18next-cli';

export default defineConfig({
  locales: ['pt', 'en', 'es'],
  extract: {
    input: './src/**/*.{ts,tsx,js,jsx}',
    output: './src/lang/{{language}}/{{namespace}}.json',
    ignore: ['node_modules/**', './src/lang/'],

    functions: ['t'],
    useTranslationNames: ['useTranslation'],

    defaultNS: 'shell',
    fallbackNS: 'common',

    preservePatterns: [
      'calendar:months.*',
      'packages:statusValue.*',
      'packages:views.*',
      'reservations:calendar.*',
      'reservations:relative.*',
      'reservations:rules.*',
      'reservations:status.*',
      'reservations:views.*',
      'shell:sidebar.routes.*',
      'visitorAccess:views.*',
    ],

    sort: false,
    acceptedAttributes: ['*'],
  },
});
