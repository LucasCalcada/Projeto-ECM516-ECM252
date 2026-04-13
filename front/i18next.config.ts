import { defineConfig } from 'i18next-cli';

export default defineConfig({
  locales: ['en', 'pt', 'es'],
  extract: {
    input: './src/**/*.{ts,tsx,js,jsx}',
    output: './src/lang/{{language}}/{{namespace}}.json',
    ignore: ['node_modules/**', './src/lang/'],

    functions: ['t'],
    useTranslationNames: ['useTranslation'],

    defaultNS: 'shell',
    fallbackNS: 'common',

    preservePatterns: ['calendar:months.*', 'reservations:status.*', 'shell:sidebar.routes.*'],

    sort: false,
    acceptedAttributes: ['*'],
  },
});
