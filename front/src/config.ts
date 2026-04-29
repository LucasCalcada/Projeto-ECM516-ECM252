interface AppConfig {
  coreUrl: string;
  authUrl: string;
  deliveryUrl: string;
}

const config: AppConfig = {
  coreUrl: 'http://localhost:8000',
  authUrl: 'http://localhost:8001',
  deliveryUrl: 'http://localhost:8002',
};

export default config;
