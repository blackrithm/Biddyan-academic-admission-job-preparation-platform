-- Enable UUID generation support
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Drop existing tables if they exist to allow clean rebuilds
DROP TABLE IF EXISTS user_answers CASCADE;
DROP TABLE IF EXISTS user_exam_attempts CASCADE;
DROP TABLE IF EXISTS exam_questions CASCADE;
DROP TABLE IF EXISTS exams CASCADE;
DROP TABLE IF EXISTS questions CASCADE;
DROP TABLE IF EXISTS topics CASCADE;

-- 1. Topics Table (Hierarchical category lookup e.g. Subject > Chapter > Sub-topic)
CREATE TABLE topics (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    parent_id UUID REFERENCES topics(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- B-Tree index for quick resolution of subtopic listings
CREATE INDEX idx_topics_parent_id ON topics(parent_id);

-- 2. Questions Table
CREATE TABLE questions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    topic_id UUID NOT NULL REFERENCES topics(id) ON DELETE RESTRICT,
    question_text TEXT NOT NULL,
    option_a TEXT NOT NULL,
    option_b TEXT NOT NULL,
    option_c TEXT NOT NULL,
    option_d TEXT NOT NULL,
    correct_option CHAR(1) NOT NULL CHECK (correct_option IN ('A', 'B', 'C', 'D')),
    explanation TEXT,
    previous_years TEXT[] DEFAULT '{}', -- e.g. ARRAY['43rd BCS', 'Primary 2022']
    difficulty_level VARCHAR(50) DEFAULT 'medium' CHECK (difficulty_level IN ('easy', 'medium', 'hard')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Optimize filters by category
CREATE INDEX idx_questions_topic_id ON questions(topic_id);
-- GIN (Generalized Inverted Index) for array intersections (millions of rows lookups on tags in microseconds)
CREATE INDEX idx_questions_previous_years ON questions USING gin(previous_years);

-- 3. Exams Table
CREATE TABLE exams (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title VARCHAR(255) NOT NULL,
    topic_id UUID REFERENCES topics(id) ON DELETE SET NULL,
    total_marks DECIMAL(6, 2) NOT NULL,
    negative_marking_per_wrong DECIMAL(4, 2) NOT NULL DEFAULT 0.25,
    duration_minutes INT NOT NULL,
    is_live BOOLEAN NOT NULL DEFAULT FALSE,
    starts_at TIMESTAMP WITH TIME ZONE,
    ends_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_exams_is_live ON exams(is_live, starts_at);

-- 4. Exam Questions Junction Table
CREATE TABLE exam_questions (
    exam_id UUID NOT NULL REFERENCES exams(id) ON DELETE CASCADE,
    question_id UUID NOT NULL REFERENCES questions(id) ON DELETE CASCADE,
    PRIMARY KEY (exam_id, question_id)
);

CREATE INDEX idx_exam_questions_question_id ON exam_questions(question_id);

-- 5. User Exam Attempts (History and Persistent Analytics)
CREATE TABLE user_exam_attempts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL, -- Ties directly to user profiles (UUID)
    exam_id UUID NOT NULL REFERENCES exams(id) ON DELETE CASCADE,
    score DECIMAL(6, 2) NOT NULL,
    correct_count INT NOT NULL,
    wrong_count INT NOT NULL,
    rank INT DEFAULT NULL,
    submitted_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_user_exam_attempts_user_id ON user_exam_attempts(user_id);
-- Compound Index covering scores and time - ensures rapid pagination of high-scores fallback directly in DB
CREATE INDEX idx_attempts_leaderboard_fallback ON user_exam_attempts(exam_id, score DESC, submitted_at ASC);

-- 6. User Answers (Granular item analysis)
CREATE TABLE user_answers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    attempt_id UUID NOT NULL REFERENCES user_exam_attempts(id) ON DELETE CASCADE,
    question_id UUID NOT NULL REFERENCES questions(id) ON DELETE CASCADE,
    selected_option CHAR(1) NOT NULL CHECK (selected_option IN ('A', 'B', 'C', 'D')),
    is_correct BOOLEAN NOT NULL
);

CREATE INDEX idx_user_answers_attempt_id ON user_answers(attempt_id);
