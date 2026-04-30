import { pgEnum, pgTable, timestamp, uuid, varchar } from 'drizzle-orm/pg-core';
export const packageStatusEnum = pgEnum('package_status', ['PENDING', 'DELIVERED', 'CANCELED']);
export const packages = pgTable('packages', {
  id: uuid('id').primaryKey().defaultRandom(),
  residencyId: uuid('residency_id').notNull(),
  description: varchar('description', { length: 255 }).notNull(),
  status: packageStatusEnum('status').default('PENDING').notNull(),
  createdAt: timestamp('created_at').defaultNow().notNull(),
  updatedAt: timestamp('updated_at').defaultNow().notNull(),
  deliveredAt: timestamp('delivered_at'),
});
