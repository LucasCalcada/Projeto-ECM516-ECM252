interface AppConfig {
  port: number;
  dbConnectionString: string;
  jwtSecret: string;
  internalSecret: string;
}

const config: AppConfig = {
  port: Number(process.env.PORT ?? 8000),
  dbConnectionString:
    process.env.DATABASE_URL ?? 'postgresql://admin:adminPasswd@localhost:5432/coreDb',
  jwtSecret: process.env.JWT_SECRET ?? 'test-token',
  internalSecret: process.env.INTERNAL_SECRET ?? 'internal-service-token',
};

export default config;
