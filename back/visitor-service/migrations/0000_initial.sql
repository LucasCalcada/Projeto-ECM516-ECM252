CREATE TABLE "visitor_accesses" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"building_id" uuid NOT NULL,
	"residency_id" uuid NOT NULL,
	"residency_name" text,
	"rg" text NOT NULL,
	"cpf" text NOT NULL,
	"name" text NOT NULL,
	"entry_at" timestamp DEFAULT now() NOT NULL
);
