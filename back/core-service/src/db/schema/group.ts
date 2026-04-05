import { InferInsertModel, InferSelectModel } from 'drizzle-orm';
import { pgTable, text, uuid } from 'drizzle-orm/pg-core';
import { buildings } from './building';

export const groups = pgTable('groups', {
  id: uuid('id').primaryKey().notNull().defaultRandom(),
  building: uuid('building').references(() => buildings.id),
  name: text('name'),
});

export type Group = InferSelectModel<typeof groups>;
export type GroupInsert = InferInsertModel<typeof groups>;
