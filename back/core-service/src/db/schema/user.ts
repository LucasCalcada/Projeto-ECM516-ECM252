import { InferInsertModel, InferSelectModel } from 'drizzle-orm';
import { pgTable, text, uuid, boolean } from 'drizzle-orm/pg-core';
import residency from './residency';
import building from './building';

export const user = pgTable('users', {
  id: uuid('id').primaryKey().notNull().defaultRandom(),
  residencyId: uuid('residencyId').references(() => residency.id),
  buildingId: uuid('buildingId').references(() => building.id),
  name: text('name'),
  permissions: text('permissions').array(),
  active: boolean('active'),
});

export default user;
export type User = InferSelectModel<typeof user>;
export type UserInsert = InferInsertModel<typeof user>;
