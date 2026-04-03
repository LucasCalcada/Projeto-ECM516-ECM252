import { InferInsertModel, InferSelectModel } from 'drizzle-orm';
import { pgTable, text, unique, uuid } from 'drizzle-orm/pg-core';
import { groups } from '@app/db/schema/group';

export const residencies = pgTable(
  'residencies',
  {
    id: uuid('id').primaryKey().notNull().defaultRandom(),
    groupId: uuid('groupId').references(() => groups.id),
    code: text('code'),
    name: text('name'),
  },
  (r) => [unique().on(r.groupId, r.code)],
);

export type Residency = InferSelectModel<typeof residencies>;
export type ResidencyInsert = InferInsertModel<typeof residencies>;
