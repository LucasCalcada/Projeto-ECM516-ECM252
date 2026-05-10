import { InferInsertModel, InferSelectModel } from 'drizzle-orm';
import { pgTable, text, timestamp, uuid } from 'drizzle-orm/pg-core';

export const visitorAccesses = pgTable('visitor_accesses', {
  id: uuid('id').primaryKey().notNull().defaultRandom(),
  residencyId: uuid('residency_id').notNull(),
  rg: text('rg').notNull(),
  cpf: text('cpf').notNull(),
  name: text('name').notNull(),
  entryAt: timestamp('entry_at').notNull().defaultNow(),
});

export type VisitorAccess = InferSelectModel<typeof visitorAccesses>;
export type VisitorAccessInsert = InferInsertModel<typeof visitorAccesses>;
