-- Enable UUID generation support
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Drop existing tables if they exist to allow clean rebuilds
DROP TABLE IF EXISTS user_answers CASCADE;
DROP TABLE IF EXISTS user_exam_attempts CASCADE;
DROP TABLE IF EXISTS users CASCADE;
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

-- Default Biddyan taxonomy: one main category is selected before its
-- sub-categories and questions are assigned.
INSERT INTO topics (name) VALUES
    ('Academic'),
    ('Admission'),
    ('Job');

INSERT INTO topics (name, parent_id)
SELECT child.name, parent.id
FROM (VALUES
    ('SSC', 'Academic'),
    ('HSC', 'Academic'),
    ('Varsity', 'Admission'),
    ('Engineering', 'Admission'),
    ('Medical', 'Admission'),
    ('Agriculture', 'Admission'),
    ('BCS', 'Job'),
    ('Bank', 'Job')
) AS child(name, parent_name)
JOIN topics parent ON parent.name = child.parent_name AND parent.parent_id IS NULL;

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
    exam_type VARCHAR(100),
    question_set VARCHAR(100),
    source VARCHAR(100) DEFAULT 'admin',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Optimize filters by category
CREATE INDEX idx_questions_topic_id ON questions(topic_id);
-- GIN (Generalized Inverted Index) for array intersections (millions of rows lookups on tags in microseconds)
CREATE INDEX idx_questions_previous_years ON questions USING gin(previous_years);
CREATE INDEX idx_questions_exam_type_set ON questions(exam_type, question_set);

-- Demo question-bank content
INSERT INTO topics (id, name, parent_id) VALUES
    ('10000000-0000-4000-8000-000000000001', 'বাংলা ভাষা ও সাহিত্য',
      (SELECT id FROM topics WHERE name = 'BCS' LIMIT 1)),
    ('10000000-0000-4000-8000-000000000002', 'বাংলাদেশ বিষয়াবলি',
      (SELECT id FROM topics WHERE name = 'BCS' LIMIT 1)),
    ('10000000-0000-4000-8000-000000000003', 'English Grammar',
      (SELECT id FROM topics WHERE name = 'BCS' LIMIT 1)),
    ('10000000-0000-4000-8000-000000000004', 'গণিত',
      (SELECT id FROM topics WHERE name = 'SSC' LIMIT 1))
ON CONFLICT (id) DO NOTHING;

INSERT INTO questions (
    id, topic_id, question_text, option_a, option_b, option_c, option_d,
    correct_option, explanation, previous_years, difficulty_level,
    exam_type, question_set, source
) VALUES
    ('20000000-0000-4000-8000-000000000001',
     '10000000-0000-4000-8000-000000000001',
     'বাংলা ভাষার আদি নিদর্শন কোনটি?', 'চর্যাপদ', 'শ্রীকৃষ্ণকীর্তন', 'মঙ্গলকাব্য', 'গীতাঞ্জলি',
     'A', 'চর্যাপদ বাংলা ভাষার প্রাচীনতম নিদর্শন।', ARRAY['43rd BCS'], 'easy', 'BCS প্রিলিমিনারি', 'Set A', 'demo'),
    ('20000000-0000-4000-8000-000000000002',
     '10000000-0000-4000-8000-000000000002',
     'বাংলাদেশের জাতীয় সংসদ ভবনের স্থপতি কে?', 'এফ আর খান', 'লুই আই কান', 'মাজহারুল ইসলাম', 'পল রুডলফ',
     'B', 'জাতীয় সংসদ ভবনের নকশা করেন লুই আই কান।', ARRAY['44th BCS'], 'easy', 'BCS প্রিলিমিনারি', 'Set A', 'demo'),
    ('20000000-0000-4000-8000-000000000003',
     '10000000-0000-4000-8000-000000000003',
     'Choose the correct article: He is ___ honest person.', 'a', 'an', 'the', 'no article',
     'B', 'Honest begins with a vowel sound, so an is correct.', ARRAY['Bank Job 2023'], 'easy', 'Bank Job', 'Set B', 'demo'),
    ('20000000-0000-4000-8000-000000000004',
     '10000000-0000-4000-8000-000000000004',
     'একটি সংখ্যার ২৫% কত?', 'সংখ্যাটির ১/২', 'সংখ্যাটির ১/৩', 'সংখ্যাটির ১/৪', 'সংখ্যাটির ১/৫',
     'C', '২৫% = ২৫/১০০ = ১/৪।', ARRAY['SSC 2024'], 'easy', 'SSC গণিত', 'Set A', 'demo')
ON CONFLICT (id) DO NOTHING;

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

-- Demo scheduled exam
INSERT INTO exams (
    id, title, topic_id, total_marks, negative_marking_per_wrong,
    duration_minutes, is_live, starts_at, ends_at
) VALUES (
    '30000000-0000-4000-8000-000000000001',
    'ডেমো BCS প্রিলিমিনারি মডেল টেস্ট',
    (SELECT id FROM topics WHERE name = 'BCS' LIMIT 1),
    4, 0.25, 10, true, NOW(), NOW() + INTERVAL '30 days'
)
ON CONFLICT (id) DO NOTHING;

-- 4. Exam Questions Junction Table
CREATE TABLE exam_questions (
    exam_id UUID NOT NULL REFERENCES exams(id) ON DELETE CASCADE,
    question_id UUID NOT NULL REFERENCES questions(id) ON DELETE CASCADE,
    PRIMARY KEY (exam_id, question_id)
);

CREATE INDEX idx_exam_questions_question_id ON exam_questions(question_id);

INSERT INTO exam_questions (exam_id, question_id) VALUES
    ('30000000-0000-4000-8000-000000000001', '20000000-0000-4000-8000-000000000001'),
    ('30000000-0000-4000-8000-000000000001', '20000000-0000-4000-8000-000000000002'),
    ('30000000-0000-4000-8000-000000000001', '20000000-0000-4000-8000-000000000003'),
    ('30000000-0000-4000-8000-000000000001', '20000000-0000-4000-8000-000000000004')
ON CONFLICT DO NOTHING;

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

-- Persistent application users
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    phone_number VARCHAR(30) UNIQUE,
    email VARCHAR(255) UNIQUE,
    display_name VARCHAR(255) NOT NULL DEFAULT 'Biddyan User',
    password_hash TEXT,
    role VARCHAR(30) NOT NULL DEFAULT 'user',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 6. User Answers (Granular item analysis)
CREATE TABLE user_answers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    attempt_id UUID NOT NULL REFERENCES user_exam_attempts(id) ON DELETE CASCADE,
    question_id UUID NOT NULL REFERENCES questions(id) ON DELETE CASCADE,
    selected_option CHAR(1) NOT NULL CHECK (selected_option IN ('A', 'B', 'C', 'D')),
    is_correct BOOLEAN NOT NULL
);

CREATE INDEX idx_user_answers_attempt_id ON user_answers(attempt_id);
