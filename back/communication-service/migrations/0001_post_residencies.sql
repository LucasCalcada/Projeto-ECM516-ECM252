DROP TABLE "post_recipients" CASCADE;--> statement-breakpoint
CREATE TABLE "post_residencies" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"post_id" uuid NOT NULL,
	"residency_id" uuid NOT NULL,
	"created_at" timestamp DEFAULT now() NOT NULL
);
--> statement-breakpoint
ALTER TABLE "post_residencies" ADD CONSTRAINT "post_residencies_post_id_posts_id_fk" FOREIGN KEY ("post_id") REFERENCES "public"."posts"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
CREATE UNIQUE INDEX "post_residencies_post_id_residency_id_idx" ON "post_residencies" USING btree ("post_id","residency_id");--> statement-breakpoint
CREATE INDEX "post_residencies_residency_id_idx" ON "post_residencies" USING btree ("residency_id");