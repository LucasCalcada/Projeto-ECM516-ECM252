interface AppConfig {
  port: number;
  dbConnectionString: string;
  jwtSecret: string;
  coreServiceUrl: string;
}

const config: AppConfig = {
  port: 8002,
  dbConnectionString: 'postgresql://admin:adminPasswd@localhost:5432/deliveryDb',
  jwtSecret: 'test-token',
  coreServiceUrl: 'http://localhost:8000',
};

export default config;
