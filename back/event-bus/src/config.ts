interface AppConfig {
  port: number;
  internalSecret: string;
}

const config: AppConfig = {
  port: 8004,
  internalSecret: 'internal-service-token',
};

export default config;
