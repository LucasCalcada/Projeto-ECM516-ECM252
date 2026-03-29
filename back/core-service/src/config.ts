interface AppConfig {
  port: number;
  dbConnectionString: string;
}

const config: AppConfig = {
  port: 8000,
  dbConnectionString: 'postgresql://admin:adminPasswd@localhost:5432',
};

export default config;
