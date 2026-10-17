CREATE TABLE "buildings" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"name" text,
	"active" boolean
);
--> statement-breakpoint
CREATE TABLE "groups" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"building" uuid,
	"name" text
);
--> statement-breakpoint
CREATE TABLE "residencies" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"groupId" uuid,
	"code" text,
	"name" text,
	CONSTRAINT "residencies_groupId_code_unique" UNIQUE("groupId","code")
);
--> statement-breakpoint
CREATE TABLE "users" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"accountId" uuid,
	"residencyId" uuid,
	"buildingId" uuid,
	"name" text,
	"permissions" text[],
	"active" boolean
);
--> statement-breakpoint
ALTER TABLE "groups" ADD CONSTRAINT "groups_building_buildings_id_fk" FOREIGN KEY ("building") REFERENCES "public"."buildings"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "residencies" ADD CONSTRAINT "residencies_groupId_groups_id_fk" FOREIGN KEY ("groupId") REFERENCES "public"."groups"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "users" ADD CONSTRAINT "users_residencyId_residencies_id_fk" FOREIGN KEY ("residencyId") REFERENCES "public"."residencies"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "users" ADD CONSTRAINT "users_buildingId_buildings_id_fk" FOREIGN KEY ("buildingId") REFERENCES "public"."buildings"("id") ON DELETE no action ON UPDATE no action;