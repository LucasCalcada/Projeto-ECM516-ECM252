interface AppConfig {
  coreUrl: string;
  authUrl: string;
  deliveryUrl: string;
  visitorAccessUrl: string;
}

const config: AppConfig = {
  coreUrl: 'http://localhost:8000',
  authUrl: 'http://localhost:8001',
  deliveryUrl: 'http://localhost:8002',
  visitorAccessUrl: 'http://localhost:8003',
};

export default config;
