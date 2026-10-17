interface AppConfig {
  coreUrl: string;
  authUrl: string;
  deliveryUrl: string;
  reservationUrl: string;
  visitorAccessUrl: string;
  communicationUrl: string;
}

const config: AppConfig = {
  coreUrl: import.meta.env.VITE_CORE_URL ?? 'http://localhost:8000',
  authUrl: import.meta.env.VITE_AUTH_URL ?? 'http://localhost:8001',
  deliveryUrl: import.meta.env.VITE_DELIVERY_URL ?? 'http://localhost:8002',
  reservationUrl: import.meta.env.VITE_RESERVATION_URL ?? 'http://localhost:8005',
  visitorAccessUrl: import.meta.env.VITE_VISITOR_URL ?? 'http://localhost:8003',
  communicationUrl: import.meta.env.VITE_COMMUNICATION_URL ?? 'http://localhost:8006',
};

export default config;
