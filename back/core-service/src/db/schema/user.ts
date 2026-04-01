import { InferInsertModel, InferSelectModel } from "drizzle-orm";
import { pgTable, text, uuid, boolean } from "drizzle-orm/pg-core";
import building from "./building";
import residency from "./residency";

export const user = pgTable("users", {
  id: uuid("id").primaryKey().notNull().defaultRandom(),
  building: text("building").references(() => building.id),
  residency: text("residency").references(() => residency.id),
  name: text("name"),
  permissions: text("permissions").array(),
  active: boolean("active"),
});

export default user;
export type User = InferSelectModel<typeof user>;
export type UserInsert = InferInsertModel<typeof user>;
