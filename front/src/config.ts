interface AppConfig {
  coreUrl: string;
  authUrl: string;
  deliveryUrl: string;
  visitorAccessUrl: string;
  communicationUrl: string;
}

const config: AppConfig = {
  coreUrl: 'http://localhost:8000',
  authUrl: 'http://localhost:8001',
  deliveryUrl: 'http://localhost:8002',
  visitorAccessUrl: 'http://localhost:8003',
  communicationUrl: 'http://localhost:8005',
};

export default config;
