import { InferInsertModel, InferSelectModel } from 'drizzle-orm';
import { date, pgTable, text, timestamp, unique, uuid, varchar } from 'drizzle-orm/pg-core';

export const reservations = pgTable(
  'reservations',
  {
    id: uuid('id').primaryKey().defaultRandom(),
    userId: uuid('user_id').notNull(),
    residentName: text('resident_name').notNull(),
    residencyId: uuid('residency_id').notNull(),
    buildingId: uuid('building_id').notNull(),
    commonAreaId: varchar('common_area_id', { length: 80 }).notNull(),
    commonAreaName: text('common_area_name').notNull(),
    reservationDate: date('reservation_date', { mode: 'string' }).notNull(),
    createdAt: timestamp('created_at').defaultNow().notNull(),
  },
  (r) => [unique().on(r.buildingId, r.commonAreaId, r.reservationDate)],
);

export type Reservation = InferSelectModel<typeof reservations>;
export type ReservationInsert = InferInsertModel<typeof reservations>;
