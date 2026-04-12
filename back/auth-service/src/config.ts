interface AppConfig {
  port: number;
  dbConnectionString: string;
  jwtToken: string;
}

const config: AppConfig = {
  port: 8001,
  dbConnectionString: 'postgresql://admin:adminPasswd@localhost:5432/authDb',
  jwtToken: 'test-token',
};

export default config;
