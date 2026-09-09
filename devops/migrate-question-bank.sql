-- Run this once on an existing Biddyan database before using the
-- admin question-bank metadata and bulk upload features.
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

ALTER TABLE questions
  ADD COLUMN IF NOT EXISTS exam_type VARCHAR(100),
  ADD COLUMN IF NOT EXISTS question_set VARCHAR(100),
  ADD COLUMN IF NOT EXISTS source VARCHAR(100) DEFAULT 'admin';

CREATE INDEX IF NOT EXISTS idx_questions_exam_type_set
  ON questions(exam_type, question_set);

CREATE TABLE IF NOT EXISTS users (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  phone_number VARCHAR(30) UNIQUE,
  email VARCHAR(255) UNIQUE,
  display_name VARCHAR(255) NOT NULL DEFAULT 'Biddyan User',
  password_hash TEXT,
  role VARCHAR(30) NOT NULL DEFAULT 'user',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
ALTER TABLE users ADD COLUMN IF NOT EXISTS password_hash TEXT;
