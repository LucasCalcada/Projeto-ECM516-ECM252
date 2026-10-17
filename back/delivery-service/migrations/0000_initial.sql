CREATE TYPE "public"."package_status" AS ENUM('PENDING', 'DELIVERED', 'CANCELED');--> statement-breakpoint
CREATE TABLE "packages" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"building_id" uuid NOT NULL,
	"residency_id" uuid NOT NULL,
	"description" varchar(255) NOT NULL,
	"status" "package_status" DEFAULT 'PENDING' NOT NULL,
	"created_at" timestamp DEFAULT now() NOT NULL,
	"delivered_at" timestamp
);
