import { InferInsertModel, InferSelectModel } from 'drizzle-orm';
import { pgTable, text, boolean } from 'drizzle-orm/pg-core';

const building = pgTable('buildings', {
  id: text('id').primaryKey(),
  name: text('name'),
  active: boolean('active'),
});

export default building;
export type Building = InferSelectModel<typeof building>;
export type BuildingInsert = InferInsertModel<typeof building>;
