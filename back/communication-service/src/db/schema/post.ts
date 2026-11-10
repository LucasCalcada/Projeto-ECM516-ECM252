import { InferInsertModel, InferSelectModel } from 'drizzle-orm';
import { index, pgTable, text, timestamp, uniqueIndex, uuid, varchar } from 'drizzle-orm/pg-core';

export const posts = pgTable(
  'posts',
  {
    id: uuid('id').primaryKey().notNull().defaultRandom(),
    buildingId: uuid('building_id').notNull(),
    authorUserId: uuid('author_user_id').notNull(),
    title: varchar('title', { length: 160 }).notNull(),
    description: text('description').notNull(),
    eventAt: timestamp('event_at'),
    createdAt: timestamp('created_at').defaultNow().notNull(),
    updatedAt: timestamp('updated_at').defaultNow().notNull(),
  },
  (table) => [index('posts_building_id_idx').on(table.buildingId)],
);

// A post without residencies targets the whole building.
export const postResidencies = pgTable(
  'post_residencies',
  {
    id: uuid('id').primaryKey().notNull().defaultRandom(),
    postId: uuid('post_id')
      .notNull()
      .references(() => posts.id, { onDelete: 'cascade' }),
    residencyId: uuid('residency_id').notNull(),
    createdAt: timestamp('created_at').defaultNow().notNull(),
  },
  (table) => [
    uniqueIndex('post_residencies_post_id_residency_id_idx').on(table.postId, table.residencyId),
    index('post_residencies_residency_id_idx').on(table.residencyId),
  ],
);

export type Post = InferSelectModel<typeof posts>;
export type PostInsert = InferInsertModel<typeof posts>;
export type PostResidency = InferSelectModel<typeof postResidencies>;
export type PostResidencyInsert = InferInsertModel<typeof postResidencies>;
