-- Persist the residence at creation time. Historical records with no verified
-- residence stay unassigned and remain available to building-level viewers.
ALTER TABLE complaints ADD COLUMN IF NOT EXISTS residency_id uuid;
CREATE INDEX IF NOT EXISTS complaints_residency_created_idx
    ON complaints (building_id, residency_id, created_at DESC, id DESC);

-- Before this migration only administrators could respond.
ALTER TABLE complaint_responses
    ADD COLUMN IF NOT EXISTS is_administrative boolean NOT NULL DEFAULT true;
