interface AppConfig {
  coreUrl: string;
  authUrl: string;
}

const config: AppConfig = {
  coreUrl: 'http://localhost:8000',
  authUrl: 'http://localhost:8001',
};

export default config;
