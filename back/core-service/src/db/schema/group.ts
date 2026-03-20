import { InferInsertModel, InferSelectModel } from "drizzle-orm";
import { pgTable, text, uuid } from "drizzle-orm/pg-core";
import building from "./building";

const group = pgTable("group", {
  id: uuid("id").primaryKey().defaultRandom(),
  building: text("building").references(() => building.id),
  name: text("name"),
});

export default group;
export type Group = InferSelectModel<typeof group>;
export type GroupInsert = InferInsertModel<typeof group>;
