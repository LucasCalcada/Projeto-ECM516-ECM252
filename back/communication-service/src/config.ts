interface AppConfig {
  port: number;
  dbConnectionString: string;
  jwtSecret: string;
}

const config: AppConfig = {
  port: 8005,
  dbConnectionString: 'postgresql://admin:adminPasswd@localhost:5432/communicationdb',
  jwtSecret: 'test-token',
};

export default config;
