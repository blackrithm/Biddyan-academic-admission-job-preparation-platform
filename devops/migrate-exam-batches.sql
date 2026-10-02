CREATE TABLE IF NOT EXISTS exam_batches (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    exam_type VARCHAR(100) NOT NULL,
    description TEXT NOT NULL DEFAULT '',
    sort_order INTEGER NOT NULL DEFAULT 0,
    is_published BOOLEAN NOT NULL DEFAULT TRUE,
    created_by UUID REFERENCES users(id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

ALTER TABLE exam_batches ADD COLUMN IF NOT EXISTS image_url TEXT;
ALTER TABLE exam_batches ADD COLUMN IF NOT EXISTS sort_order INTEGER;

WITH ranked_batches AS (
    SELECT id, ROW_NUMBER() OVER (ORDER BY created_at DESC, id) - 1 AS position
    FROM exam_batches
)
UPDATE exam_batches AS batches
SET sort_order = ranked_batches.position
FROM ranked_batches
WHERE batches.id = ranked_batches.id AND batches.sort_order IS NULL;

ALTER TABLE exam_batches ALTER COLUMN sort_order SET DEFAULT 0;
ALTER TABLE exam_batches ALTER COLUMN sort_order SET NOT NULL;

CREATE TABLE IF NOT EXISTS exam_batch_exams (
    batch_id UUID NOT NULL REFERENCES exam_batches(id) ON DELETE CASCADE,
    exam_id UUID NOT NULL REFERENCES exams(id) ON DELETE CASCADE,
    starts_at TIMESTAMP WITH TIME ZONE NOT NULL,
    ends_at TIMESTAMP WITH TIME ZONE NOT NULL,
    PRIMARY KEY (batch_id, exam_id),
    CHECK (ends_at > starts_at)
);

CREATE INDEX IF NOT EXISTS idx_exam_batch_exams_schedule
    ON exam_batch_exams(starts_at, ends_at);

CREATE TABLE IF NOT EXISTS exam_batch_enrollments (
    batch_id UUID NOT NULL REFERENCES exam_batches(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    enrolled_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    PRIMARY KEY (batch_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_exam_batch_enrollments_user
    ON exam_batch_enrollments(user_id, enrolled_at DESC);