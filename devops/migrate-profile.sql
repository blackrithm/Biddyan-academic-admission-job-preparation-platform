-- Profile preferences persisted for student accounts.
ALTER TABLE users ADD COLUMN IF NOT EXISTS profile_image_url TEXT;
ALTER TABLE users ADD COLUMN IF NOT EXISTS preparation_categories TEXT[] NOT NULL DEFAULT '{}';
ALTER TABLE users ADD COLUMN IF NOT EXISTS notifications_enabled BOOLEAN NOT NULL DEFAULT TRUE;
ALTER TABLE users ADD COLUMN IF NOT EXISTS preferred_language VARCHAR(30) NOT NULL DEFAULT 'বাংলা';
ALTER TABLE users ADD COLUMN IF NOT EXISTS institution_type VARCHAR(20);
ALTER TABLE users ADD COLUMN IF NOT EXISTS institution_name VARCHAR(180);
ALTER TABLE users ADD COLUMN IF NOT EXISTS location VARCHAR(180);