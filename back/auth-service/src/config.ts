interface AppConfig {
  port: number;
  dbConnectionString: string;
  jwtToken: string;
}

const config: AppConfig = {
  port: Number(process.env.PORT ?? 8001),
  dbConnectionString:
    process.env.DATABASE_URL ?? 'postgresql://admin:adminPasswd@localhost:5432/authDb',
  jwtToken: process.env.JWT_SECRET ?? 'test-token',
};

export default config;
