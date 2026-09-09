-- Seed demo content into an existing Biddyan database.
-- Run after init-db.sql or migrate-question-bank.sql.

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

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
  ('20000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000001',
   'বাংলা ভাষার আদি নিদর্শন কোনটি?', 'চর্যাপদ', 'শ্রীকৃষ্ণকীর্তন', 'মঙ্গলকাব্য', 'গীতাঞ্জলি',
   'A', 'চর্যাপদ বাংলা ভাষার প্রাচীনতম নিদর্শন।', ARRAY['43rd BCS'], 'easy', 'BCS প্রিলিমিনারি', 'Set A', 'demo'),
  ('20000000-0000-4000-8000-000000000002', '10000000-0000-4000-8000-000000000002',
   'বাংলাদেশের জাতীয় সংসদ ভবনের স্থপতি কে?', 'এফ আর খান', 'লুই আই কান', 'মাজহারুল ইসলাম', 'পল রুডলফ',
   'B', 'জাতীয় সংসদ ভবনের নকশা করেন লুই আই কান।', ARRAY['44th BCS'], 'easy', 'BCS প্রিলিমিনারি', 'Set A', 'demo'),
  ('20000000-0000-4000-8000-000000000003', '10000000-0000-4000-8000-000000000003',
   'Choose the correct article: He is ___ honest person.', 'a', 'an', 'the', 'no article',
   'B', 'Honest begins with a vowel sound, so an is correct.', ARRAY['Bank Job 2023'], 'easy', 'Bank Job', 'Set B', 'demo'),
  ('20000000-0000-4000-8000-000000000004', '10000000-0000-4000-8000-000000000004',
   'একটি সংখ্যার ২৫% কত?', 'সংখ্যাটির ১/২', 'সংখ্যাটির ১/৩', 'সংখ্যাটির ১/৪', 'সংখ্যাটির ১/৫',
   'C', '২৫% = ২৫/১০০ = ১/৪।', ARRAY['SSC 2024'], 'easy', 'SSC গণিত', 'Set A', 'demo')
ON CONFLICT (id) DO NOTHING;

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

INSERT INTO exam_questions (exam_id, question_id) VALUES
  ('30000000-0000-4000-8000-000000000001', '20000000-0000-4000-8000-000000000001'),
  ('30000000-0000-4000-8000-000000000001', '20000000-0000-4000-8000-000000000002'),
  ('30000000-0000-4000-8000-000000000001', '20000000-0000-4000-8000-000000000003'),
  ('30000000-0000-4000-8000-000000000001', '20000000-0000-4000-8000-000000000004')
ON CONFLICT DO NOTHING;
