interface AppConfig {
  port: number;
  dbConnectionString: string;
  jwtSecret: string;
}

const config: AppConfig = {
  port: Number(process.env.PORT ?? 8005),
  dbConnectionString:
    process.env.DATABASE_URL ?? 'postgresql://admin:adminPasswd@localhost:5432/reservationDb',
  jwtSecret: process.env.JWT_SECRET ?? 'test-token',
};

export default config;
