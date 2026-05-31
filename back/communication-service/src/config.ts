interface AppConfig {
  port: number;
  dbConnectionString: string;
  jwtSecret: string;
  coreUrl: string;
  eventBusUrl: string;
  serviceUrl: string;
  internalSecret: string;
}

const config: AppConfig = {
  port: 8006,
  dbConnectionString: 'postgresql://admin:adminPasswd@localhost:5432/communicationdb',
  jwtSecret: 'test-token',
  coreUrl: 'http://localhost:8000',
  eventBusUrl: 'http://localhost:8004',
  serviceUrl: 'http://localhost:8006',
  internalSecret: 'internal-service-token',
};

export default config;
