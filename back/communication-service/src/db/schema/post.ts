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

export const postRecipients = pgTable(
  'post_recipients',
  {
    id: uuid('id').primaryKey().notNull().defaultRandom(),
    postId: uuid('post_id')
      .notNull()
      .references(() => posts.id, { onDelete: 'cascade' }),
    userId: uuid('user_id').notNull(),
    createdAt: timestamp('created_at').defaultNow().notNull(),
  },
  (table) => [
    uniqueIndex('post_recipients_post_id_user_id_idx').on(table.postId, table.userId),
    index('post_recipients_user_id_idx').on(table.userId),
  ],
);

export type Post = InferSelectModel<typeof posts>;
export type PostInsert = InferInsertModel<typeof posts>;
export type PostRecipient = InferSelectModel<typeof postRecipients>;
export type PostRecipientInsert = InferInsertModel<typeof postRecipients>;
