interface AppConfig {
  port: number;
  dbConnectionString: string;
  jwtSecret: string;
  internalSecret: string;
}

const config: AppConfig = {
  port: 8000,
  dbConnectionString: 'postgresql://admin:adminPasswd@localhost:5432/coreDb',
  jwtSecret: 'test-token',
  internalSecret: 'internal-service-token',
};

export default config;
