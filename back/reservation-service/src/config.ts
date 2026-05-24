interface AppConfig {
  port: number;
  coreUrl: string;
  dbConnectionString: string;
  jwtSecret: string;
}

const config: AppConfig = {
  port: 8005,
  coreUrl: 'http://localhost:8000',
  dbConnectionString: 'postgresql://admin:adminPasswd@localhost:5432/reservationDb',
  jwtSecret: 'test-token',
};

export default config;
