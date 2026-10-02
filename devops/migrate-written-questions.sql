CREATE TABLE IF NOT EXISTS written_questions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    topic_id UUID NOT NULL REFERENCES topics(id) ON DELETE CASCADE,
    question_text TEXT NOT NULL,
    model_answer TEXT NOT NULL DEFAULT '',
    marks DECIMAL(6, 2) NOT NULL DEFAULT 10 CHECK (marks > 0),
    previous_years TEXT[] NOT NULL DEFAULT '{}',
    difficulty_level VARCHAR(50) NOT NULL DEFAULT 'medium'
        CHECK (difficulty_level IN ('easy', 'medium', 'hard')),
    exam_type VARCHAR(100),
    question_set VARCHAR(100),
    source VARCHAR(100) NOT NULL DEFAULT 'admin',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_written_questions_topic_id
    ON written_questions(topic_id);

CREATE TABLE IF NOT EXISTS written_question_sets (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    topic_id UUID NOT NULL REFERENCES topics(id) ON DELETE CASCADE,
    format VARCHAR(16) NOT NULL CHECK (format IN ('cq', 'written')),
    title VARCHAR(255) NOT NULL DEFAULT '',
    stimulus TEXT NOT NULL DEFAULT '',
    exam_type VARCHAR(100),
    question_set VARCHAR(100),
    previous_years TEXT[] NOT NULL DEFAULT '{}',
    difficulty_level VARCHAR(50) NOT NULL DEFAULT 'medium'
        CHECK (difficulty_level IN ('easy', 'medium', 'hard')),
    source VARCHAR(100) NOT NULL DEFAULT 'admin',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE written_questions
    ADD COLUMN IF NOT EXISTS set_id UUID REFERENCES written_question_sets(id) ON DELETE CASCADE,
    ADD COLUMN IF NOT EXISTS item_order INTEGER NOT NULL DEFAULT 1;

CREATE INDEX IF NOT EXISTS idx_written_questions_set_order
    ON written_questions(set_id, item_order);

CREATE TABLE IF NOT EXISTS written_exam_submissions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL,
    topic_id UUID NOT NULL REFERENCES topics(id) ON DELETE CASCADE,
    answers JSONB NOT NULL,
    review_status VARCHAR(24) NOT NULL DEFAULT 'pending'
        CHECK (review_status IN ('pending', 'reviewed')),
    submitted_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_written_submissions_user
    ON written_exam_submissions(user_id, submitted_at DESC);