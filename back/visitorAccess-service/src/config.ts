interface AppConfig {
  port: number;
  dbConnectionString: string;
  jwtSecret: string;
  coreUrl: string;
}

const config: AppConfig = {
  port: 8003,
  dbConnectionString: 'postgresql://admin:adminPasswd@localhost:5432/visitorAccessDb',
  jwtSecret: 'test-token',
  coreUrl: 'http://localhost:8000',
};

export default config;
