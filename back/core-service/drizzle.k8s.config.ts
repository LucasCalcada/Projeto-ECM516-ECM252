import base from './drizzle.config';

// Versioned migrations for a fresh Kubernetes database. Local Compose keeps push.
export default { ...base, out: './migrations' };
