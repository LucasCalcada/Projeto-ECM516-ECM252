interface AppConfig {
  port: number;
  dbConnectionString: string;
  jwtSecret: string;
}

const config: AppConfig = {
  port: 8000,
  dbConnectionString: 'postgresql://admin:adminPasswd@localhost:5432/coreDb',
  jwtSecret: 'test-token',
};

export default config;
