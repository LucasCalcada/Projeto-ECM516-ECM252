import { InferInsertModel, InferSelectModel } from 'drizzle-orm';
import { pgTable, text, unique, uuid } from 'drizzle-orm/pg-core';
import group from '@app/db/schema/group';

const residency = pgTable(
  'residencies',
  {
    id: uuid('id').primaryKey().notNull().defaultRandom(),
    groupId: uuid('groupId').references(() => group.id),
    code: text('code'),
    name: text('name'),
  },
  (r) => [unique().on(r.groupId, r.code)],
);

export default residency;
export type Residency = InferSelectModel<typeof residency>;
export type ResidencyInsert = InferInsertModel<typeof residency>;
