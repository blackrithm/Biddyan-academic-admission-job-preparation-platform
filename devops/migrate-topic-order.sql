ALTER TABLE topics
ADD COLUMN IF NOT EXISTS sort_order INTEGER NOT NULL DEFAULT 0;

CREATE INDEX IF NOT EXISTS idx_topics_parent_order
ON topics(parent_id, sort_order, name);