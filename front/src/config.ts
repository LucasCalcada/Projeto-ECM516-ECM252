interface AppConfig {
  coreUrl: string;
  authUrl: string;
  deliveryUrl: string;
  reservationUrl: string;
  visitorAccessUrl: string;
}

const config: AppConfig = {
  coreUrl: 'http://localhost:8000',
  authUrl: 'http://localhost:8001',
  deliveryUrl: 'http://localhost:8002',
  reservationUrl: 'http://localhost:8005',
  visitorAccessUrl: 'http://localhost:8003',
};

export default config;
