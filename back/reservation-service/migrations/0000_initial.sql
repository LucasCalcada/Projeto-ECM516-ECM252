CREATE TABLE "common_areas" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"building_id" uuid NOT NULL,
	"name" text NOT NULL,
	"limit" integer NOT NULL,
	"created_at" timestamp DEFAULT now() NOT NULL,
	CONSTRAINT "common_areas_building_id_name_unique" UNIQUE("building_id","name")
);
--> statement-breakpoint
CREATE TABLE "reservations" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"user_id" uuid NOT NULL,
	"resident_name" text NOT NULL,
	"residency_id" uuid NOT NULL,
	"building_id" uuid NOT NULL,
	"common_area_id" varchar(80) NOT NULL,
	"common_area_name" text NOT NULL,
	"reservation_date" date NOT NULL,
	"created_at" timestamp DEFAULT now() NOT NULL,
	CONSTRAINT "reservations_building_id_common_area_id_reservation_date_unique" UNIQUE("building_id","common_area_id","reservation_date")
);
