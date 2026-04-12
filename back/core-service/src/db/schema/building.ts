import { InferInsertModel, InferSelectModel } from 'drizzle-orm';
import { pgTable, text, boolean, uuid } from 'drizzle-orm/pg-core';

export const buildings = pgTable('buildings', {
  id: uuid('id').primaryKey().notNull().defaultRandom(),
  name: text('name'),
  active: boolean('active'),
});

export type Building = InferSelectModel<typeof buildings>;
export type BuildingInsert = InferInsertModel<typeof buildings>;
