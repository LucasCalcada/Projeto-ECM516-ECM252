interface AppConfig {
  port: number;
  dbConnectionString: string;
  jwtSecret: string;
  coreUrl: string;
  eventBusUrl: string;
  serviceUrl: string;
  internalSecret: string;
}

const config: AppConfig = {
  port: Number(process.env.PORT ?? 8006),
  dbConnectionString:
    process.env.DATABASE_URL ?? 'postgresql://admin:adminPasswd@localhost:5432/communicationDb',
  jwtSecret: process.env.JWT_SECRET ?? 'test-token',
  coreUrl: process.env.CORE_URL ?? 'http://localhost:8000',
  eventBusUrl: process.env.EVENT_BUS_URL ?? 'http://localhost:8004',
  serviceUrl: process.env.SERVICE_URL ?? 'http://localhost:8006',
  internalSecret: process.env.INTERNAL_SECRET ?? 'internal-service-token',
};

export default config;
