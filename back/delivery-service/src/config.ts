interface AppConfig {
  port: number;
  dbConnectionString: string;
  jwtSecret: string;
  coreServiceUrl: string;
  eventBusUrl: string;
}

const config: AppConfig = {
  port: Number(process.env.PORT ?? 8002),
  dbConnectionString:
    process.env.DATABASE_URL ?? 'postgresql://admin:adminPasswd@localhost:5432/deliveryDb',
  jwtSecret: process.env.JWT_SECRET ?? 'test-token',
  coreServiceUrl: process.env.CORE_URL ?? 'http://localhost:8000',
  eventBusUrl: process.env.EVENT_BUS_URL ?? 'http://localhost:8004',
};

export default config;
