-- All identifiers are assigned by the application; other services own users
-- and buildings, so only aggregate-local foreign keys are declared here.
CREATE TABLE IF NOT EXISTS complaints (
    id uuid PRIMARY KEY,
    building_id uuid NOT NULL,
    resident_user_id uuid NOT NULL,
    title text NOT NULL CHECK (char_length(btrim(title)) BETWEEN 1 AND 200),
    category text NOT NULL CHECK (
        category IN ('barulho', 'limpeza', 'convivencia', 'areas_comuns', 'seguranca', 'outros')
    ),
    description text NOT NULL CHECK (char_length(btrim(description)) BETWEEN 1 AND 10000),
    status text NOT NULL DEFAULT 'aberta' CHECK (
        status IN ('aberta', 'em_analise', 'encerrada')
    ),
    created_at timestamptz NOT NULL,
    updated_at timestamptz NOT NULL,
    closed_at timestamptz,
    CHECK (updated_at >= created_at),
    CHECK (
        (status = 'encerrada' AND closed_at IS NOT NULL AND closed_at >= created_at)
        OR (status <> 'encerrada' AND closed_at IS NULL)
    )
);

CREATE TABLE IF NOT EXISTS complaint_responses (
    id uuid PRIMARY KEY,
    complaint_id uuid NOT NULL REFERENCES complaints(id),
    author_user_id uuid NOT NULL,
    message text NOT NULL CHECK (char_length(btrim(message)) BETWEEN 1 AND 5000),
    created_at timestamptz NOT NULL
);

CREATE TABLE IF NOT EXISTS complaint_status_history (
    id uuid PRIMARY KEY,
    complaint_id uuid NOT NULL REFERENCES complaints(id),
    previous_status text CHECK (
        previous_status IN ('aberta', 'em_analise', 'encerrada')
    ),
    status text NOT NULL CHECK (status IN ('aberta', 'em_analise', 'encerrada')),
    author_user_id uuid NOT NULL,
    created_at timestamptz NOT NULL,
    CHECK (
        (previous_status IS NULL AND status = 'aberta')
        OR (previous_status IS NOT NULL AND (
            (previous_status = 'aberta' AND status IN ('em_analise', 'encerrada'))
            OR (previous_status = 'em_analise' AND status = 'encerrada')
        ))
    )
);

CREATE INDEX IF NOT EXISTS complaints_building_created_idx
    ON complaints (building_id, created_at DESC, id DESC);
CREATE INDEX IF NOT EXISTS complaints_resident_created_idx
    ON complaints (building_id, resident_user_id, created_at DESC, id DESC);
CREATE INDEX IF NOT EXISTS complaints_status_category_idx
    ON complaints (building_id, status, category, created_at DESC, id DESC);
CREATE INDEX IF NOT EXISTS complaint_responses_timeline_idx
    ON complaint_responses (complaint_id, created_at, id);
CREATE INDEX IF NOT EXISTS complaint_status_history_timeline_idx
    ON complaint_status_history (complaint_id, created_at, id);
CREATE UNIQUE INDEX IF NOT EXISTS complaint_status_history_initial_idx
    ON complaint_status_history (complaint_id) WHERE previous_status IS NULL;
