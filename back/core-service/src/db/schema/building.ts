import { InferInsertModel, InferSelectModel } from 'drizzle-orm';
import { pgTable, text, boolean, uuid } from 'drizzle-orm/pg-core';

const building = pgTable('buildings', {
  id: uuid('id').primaryKey().notNull().defaultRandom(),
  name: text('name'),
  active: boolean('active'),
});

export default building;
export type Building = InferSelectModel<typeof building>;
export type BuildingInsert = InferInsertModel<typeof building>;
