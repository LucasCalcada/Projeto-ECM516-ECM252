interface AppConfig {
  port: number;
  internalSecret: string;
}

const config: AppConfig = {
  port: Number(process.env.PORT ?? 8004),
  internalSecret: process.env.INTERNAL_SECRET ?? 'internal-service-token',
};

export default config;
