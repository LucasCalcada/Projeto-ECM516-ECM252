interface AppConfig {
  port: number;
  dbConnectionString: string;
}

const config: AppConfig = {
  port: 8002,
  dbConnectionString: 'postgresql://admin:adminPasswd@localhost:5432/deliveryDb',
};

export default config;
