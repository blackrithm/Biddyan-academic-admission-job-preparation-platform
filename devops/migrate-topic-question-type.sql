ALTER TABLE topics
ADD COLUMN IF NOT EXISTS question_type VARCHAR(16) NOT NULL DEFAULT 'mcq';

DO $$
BEGIN
	IF NOT EXISTS (
		SELECT 1 FROM pg_constraint
		WHERE conname = 'topics_question_type_check'
			AND conrelid = 'topics'::regclass
	) THEN
		ALTER TABLE topics
		ADD CONSTRAINT topics_question_type_check
		CHECK (question_type IN ('mcq', 'written'));
	END IF;
END
$$;