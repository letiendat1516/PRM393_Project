# Database Schema

Database dùng cho project JobHub, chạy trên **Supabase / PostgreSQL**.

Chạy script bên dưới trong **Supabase SQL Editor** để tạo enum, bảng, trigger, khóa ngoại và index.

```sql
-- Supabase / PostgreSQL version
-- Run this script in Supabase SQL Editor.

-- =====================================================================
-- ENUM TYPES
-- =====================================================================
CREATE TYPE skill_source AS ENUM ('MANUAL', 'AI');
CREATE TYPE salary_period AS ENUM ('HOUR', 'MONTH', 'YEAR');
CREATE TYPE work_mode AS ENUM ('ONSITE', 'REMOTE', 'HYBRID');
CREATE TYPE job_type AS ENUM ('FULL_TIME', 'PART_TIME', 'INTERNSHIP', 'CONTRACT');
CREATE TYPE experience_level AS ENUM ('INTERN', 'FRESHER', 'JUNIOR', 'MID', 'SENIOR', 'LEAD');
CREATE TYPE job_status AS ENUM ('DRAFT', 'OPEN', 'PAUSED', 'CLOSED', 'EXPIRED');
CREATE TYPE application_status AS ENUM ('SUBMITTED', 'UNDER_REVIEW', 'INTERVIEW', 'OFFER', 'ACCEPTED', 'REJECTED', 'WITHDRAWN');
CREATE TYPE recommendation_status AS ENUM ('NEW', 'VIEWED', 'DISMISSED', 'APPLIED');

-- =====================================================================
-- UPDATED_AT TRIGGER FUNCTION
-- =====================================================================
CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- =====================================================================
-- 1. JOB SEEKER
-- =====================================================================
CREATE TABLE job_seeker (
  job_seeker_id BIGSERIAL PRIMARY KEY,
  full_name     VARCHAR(255) NOT NULL,
  email         VARCHAR(255) NOT NULL UNIQUE,
  password_hash VARCHAR(255) NOT NULL,
  phone         VARCHAR(20),
  address       TEXT,
  city          VARCHAR(100),
  headline      VARCHAR(255),
  profile_summary TEXT,
  is_verified   BOOLEAN DEFAULT FALSE,
  is_open_to_work BOOLEAN DEFAULT TRUE,
  created_at    TIMESTAMPTZ DEFAULT now(),
  updated_at    TIMESTAMPTZ DEFAULT now(),
  is_active     BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TRIGGER trg_job_seeker_updated_at
BEFORE UPDATE ON job_seeker
FOR EACH ROW
EXECUTE FUNCTION set_updated_at();

-- =====================================================================
-- 2. EMPLOYER
-- =====================================================================
CREATE TABLE employer (
  employer_id   BIGSERIAL PRIMARY KEY,
  company_name  VARCHAR(255) NOT NULL,
  email         VARCHAR(255) NOT NULL UNIQUE,
  password_hash VARCHAR(255) NOT NULL,
  phone         VARCHAR(20),
  website       VARCHAR(255),
  company_description TEXT,
  city          VARCHAR(100),
  contact_name  VARCHAR(255),                 -- Migration 001: người liên hệ
  gender        VARCHAR(10),                   -- Migration 001: 'male' | 'female'
  is_verified   BOOLEAN DEFAULT FALSE,
  created_at    TIMESTAMPTZ DEFAULT now(),
  updated_at    TIMESTAMPTZ DEFAULT now(),
  is_active     BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TRIGGER trg_employer_updated_at
BEFORE UPDATE ON employer
FOR EACH ROW
EXECUTE FUNCTION set_updated_at();

-- =====================================================================
-- 3. CATEGORY
-- =====================================================================
CREATE TABLE category (
  category_id BIGSERIAL PRIMARY KEY,
  name        VARCHAR(100) NOT NULL UNIQUE
);

-- =====================================================================
-- 4. SKILL
-- =====================================================================
CREATE TABLE skill (
  skill_id   BIGSERIAL PRIMARY KEY,
  skill_name VARCHAR(100) NOT NULL UNIQUE,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE TRIGGER trg_skill_updated_at
BEFORE UPDATE ON skill
FOR EACH ROW
EXECUTE FUNCTION set_updated_at();

-- =====================================================================
-- 5. RESUME
-- =====================================================================
CREATE TABLE resume (
  resume_id     BIGSERIAL PRIMARY KEY,
  job_seeker_id BIGINT NOT NULL,
  title         VARCHAR(255),
  file_name     VARCHAR(255),
  file_path     VARCHAR(500),
  is_primary    BOOLEAN DEFAULT FALSE,
  upload_date   TIMESTAMPTZ DEFAULT now(),
  CONSTRAINT fk_resume_job_seeker
      FOREIGN KEY (job_seeker_id) REFERENCES job_seeker(job_seeker_id)
      ON DELETE CASCADE
);

CREATE INDEX idx_resume_seeker ON resume (job_seeker_id);

-- =====================================================================
-- 6. AI ANALYSIS
-- =====================================================================
CREATE TABLE ai_analysis (
  analysis_id            BIGSERIAL PRIMARY KEY,
  resume_id              BIGINT NOT NULL,
  summary                TEXT,
  extracted_skills       JSONB,
  total_experience_years DECIMAL(4,1),
  education_level        VARCHAR(100),
  raw_text               TEXT,
  model_version          VARCHAR(50),
  analyzed_at            TIMESTAMPTZ DEFAULT now(),
  CONSTRAINT fk_analysis_resume
      FOREIGN KEY (resume_id) REFERENCES resume(resume_id)
      ON DELETE CASCADE
);

CREATE INDEX idx_analysis_resume ON ai_analysis (resume_id);
CREATE INDEX idx_analysis_extracted_skills ON ai_analysis USING GIN (extracted_skills);

-- =====================================================================
-- 7. WORK EXPERIENCE
-- =====================================================================
CREATE TABLE work_experience (
  experience_id BIGSERIAL PRIMARY KEY,
  job_seeker_id BIGINT NOT NULL,
  company_name  VARCHAR(255),
  position      VARCHAR(255),
  start_date    DATE,
  end_date      DATE,
  description   TEXT,
  CONSTRAINT fk_we_seeker
      FOREIGN KEY (job_seeker_id) REFERENCES job_seeker(job_seeker_id)
      ON DELETE CASCADE
);

CREATE INDEX idx_we_seeker ON work_experience (job_seeker_id);

-- =====================================================================
-- 8. EDUCATION
-- =====================================================================
CREATE TABLE education (
  education_id  BIGSERIAL PRIMARY KEY,
  job_seeker_id BIGINT NOT NULL,
  school_name   VARCHAR(255),
  degree        VARCHAR(100),
  major         VARCHAR(255),
  start_year    SMALLINT,
  end_year      SMALLINT,
  CONSTRAINT fk_edu_seeker
      FOREIGN KEY (job_seeker_id) REFERENCES job_seeker(job_seeker_id)
      ON DELETE CASCADE,
  CONSTRAINT chk_education_start_year CHECK (start_year IS NULL OR start_year BETWEEN 1900 AND 9999),
  CONSTRAINT chk_education_end_year CHECK (end_year IS NULL OR end_year BETWEEN 1900 AND 9999)
);

CREATE INDEX idx_edu_seeker ON education (job_seeker_id);

-- =====================================================================
-- 9. JOB SEEKER SKILL
-- =====================================================================
CREATE TABLE job_seeker_skill (
  job_seeker_id    BIGINT NOT NULL,
  skill_id         BIGINT NOT NULL,
  experience_years DECIMAL(4,1),
  skill_detail     TEXT,
  source           skill_source DEFAULT 'MANUAL',
  PRIMARY KEY (job_seeker_id, skill_id),
  CONSTRAINT fk_jss_job_seeker
      FOREIGN KEY (job_seeker_id) REFERENCES job_seeker(job_seeker_id)
      ON DELETE CASCADE,
  CONSTRAINT fk_jss_skill
      FOREIGN KEY (skill_id) REFERENCES skill(skill_id)
      ON DELETE CASCADE
);

CREATE INDEX idx_jss_skill ON job_seeker_skill (skill_id);

-- =====================================================================
-- 10. JOB
-- =====================================================================
CREATE TABLE job (
  job_id          BIGSERIAL PRIMARY KEY,
  employer_id     BIGINT NOT NULL,
  category_id     BIGINT NULL,

  job_title       VARCHAR(255) NOT NULL,
  job_description TEXT,

  salary_min      DECIMAL(15,2),
  salary_max      DECIMAL(15,2),
  salary_currency CHAR(3) DEFAULT 'VND',
  salary_period   salary_period DEFAULT 'MONTH',
  is_salary_negotiable BOOLEAN DEFAULT FALSE,

  location        VARCHAR(255),
  city            VARCHAR(100),
  country         VARCHAR(100) DEFAULT 'Vietnam',

  work_mode       work_mode NOT NULL DEFAULT 'ONSITE',
  job_type        job_type NOT NULL,
  experience_level experience_level,

  positions_available  INT DEFAULT 1,
  application_deadline DATE,

  status          job_status DEFAULT 'OPEN',

  created_at      TIMESTAMPTZ DEFAULT now(),
  updated_at      TIMESTAMPTZ DEFAULT now(),
  is_approved     BOOLEAN NOT NULL DEFAULT TRUE,
  CONSTRAINT fk_job_employer
      FOREIGN KEY (employer_id) REFERENCES employer(employer_id)
      ON DELETE CASCADE,
  CONSTRAINT fk_job_category
      FOREIGN KEY (category_id) REFERENCES category(category_id)
      ON DELETE SET NULL,
  CONSTRAINT chk_salary CHECK (salary_min IS NULL OR salary_max IS NULL OR salary_min <= salary_max)
);

CREATE TRIGGER trg_job_updated_at
BEFORE UPDATE ON job
FOR EACH ROW
EXECUTE FUNCTION set_updated_at();

CREATE INDEX idx_job_employer ON job (employer_id);
CREATE INDEX idx_job_filter ON job (status, job_type, work_mode, city);
CREATE INDEX idx_job_salary ON job (salary_min, salary_max);
CREATE INDEX ft_job ON job USING GIN (to_tsvector('simple', coalesce(job_title, '') || ' ' || coalesce(job_description, '')));

-- =====================================================================
-- 11. JOB SKILL
-- =====================================================================
CREATE TABLE job_skill (
  job_id               BIGINT NOT NULL,
  skill_id             BIGINT NOT NULL,
  is_required          BOOLEAN DEFAULT TRUE,
  min_experience_years DECIMAL(4,1) DEFAULT 0,
  weight               SMALLINT DEFAULT 1,
  PRIMARY KEY (job_id, skill_id),
  CONSTRAINT fk_js_job
      FOREIGN KEY (job_id) REFERENCES job(job_id)
      ON DELETE CASCADE,
  CONSTRAINT fk_js_skill
      FOREIGN KEY (skill_id) REFERENCES skill(skill_id)
      ON DELETE CASCADE
);

CREATE INDEX idx_js_skill ON job_skill (skill_id);

-- =====================================================================
-- 12. APPLICATION
-- =====================================================================
CREATE TABLE application (
  application_id   BIGSERIAL PRIMARY KEY,
  job_seeker_id    BIGINT NOT NULL,
  job_id           BIGINT NOT NULL,
  resume_id        BIGINT NULL,
  cover_letter     TEXT,
  application_date TIMESTAMPTZ DEFAULT now(),
  status           application_status DEFAULT 'SUBMITTED',
  updated_at       TIMESTAMPTZ DEFAULT now(),

  CONSTRAINT fk_application_job_seeker
      FOREIGN KEY (job_seeker_id) REFERENCES job_seeker(job_seeker_id)
      ON DELETE CASCADE,
  CONSTRAINT fk_application_job
      FOREIGN KEY (job_id) REFERENCES job(job_id)
      ON DELETE CASCADE,
  CONSTRAINT fk_application_resume
      FOREIGN KEY (resume_id) REFERENCES resume(resume_id)
      ON DELETE SET NULL,
  CONSTRAINT uq_application UNIQUE (job_seeker_id, job_id)
);

CREATE TRIGGER trg_application_updated_at
BEFORE UPDATE ON application
FOR EACH ROW
EXECUTE FUNCTION set_updated_at();

CREATE INDEX idx_app_seeker ON application (job_seeker_id);
CREATE INDEX idx_app_job ON application (job_id);

-- =====================================================================
-- 13. JOB RECOMMENDATION
-- =====================================================================
CREATE TABLE job_recommendation (
  recommendation_id     BIGSERIAL PRIMARY KEY,
  job_seeker_id         BIGINT NOT NULL,
  job_id                BIGINT NOT NULL,
  resume_id             BIGINT NULL,
  match_score           DECIMAL(5,2),
  recommendation_reason TEXT,
  status                recommendation_status DEFAULT 'NEW',
  generated_at          TIMESTAMPTZ DEFAULT now(),

  CONSTRAINT fk_rec_job_seeker
      FOREIGN KEY (job_seeker_id) REFERENCES job_seeker(job_seeker_id)
      ON DELETE CASCADE,
  CONSTRAINT fk_rec_job
      FOREIGN KEY (job_id) REFERENCES job(job_id)
      ON DELETE CASCADE,
  CONSTRAINT fk_rec_resume
      FOREIGN KEY (resume_id) REFERENCES resume(resume_id)
      ON DELETE SET NULL,
  CONSTRAINT uq_recommendation UNIQUE (job_seeker_id, job_id),
  CONSTRAINT chk_score CHECK (match_score BETWEEN 0 AND 100)
);

CREATE INDEX idx_rec_seeker_score ON job_recommendation (job_seeker_id, match_score DESC);

-- =====================================================================
-- 14. SAVED JOB
-- =====================================================================
CREATE TABLE saved_job (
  job_seeker_id BIGINT NOT NULL,
  job_id        BIGINT NOT NULL,
  saved_at      TIMESTAMPTZ DEFAULT now(),
  PRIMARY KEY (job_seeker_id, job_id),
  CONSTRAINT fk_sj_seeker
      FOREIGN KEY (job_seeker_id) REFERENCES job_seeker(job_seeker_id)
      ON DELETE CASCADE,
  CONSTRAINT fk_sj_job
      FOREIGN KEY (job_id) REFERENCES job(job_id)
      ON DELETE CASCADE
);

-- =====================================================================
-- 15. NOTIFICATION
-- =====================================================================
CREATE TABLE notification (
  notification_id BIGSERIAL PRIMARY KEY,
  job_seeker_id   BIGINT NULL,
  employer_id     BIGINT NULL,
  type            VARCHAR(50),
  title           VARCHAR(255),
  message         TEXT,
  is_read         BOOLEAN DEFAULT FALSE,
  created_at      TIMESTAMPTZ DEFAULT now(),
  CONSTRAINT fk_noti_seeker
      FOREIGN KEY (job_seeker_id) REFERENCES job_seeker(job_seeker_id)
      ON DELETE CASCADE,
  CONSTRAINT fk_noti_employer
      FOREIGN KEY (employer_id) REFERENCES employer(employer_id)
      ON DELETE CASCADE
);

CREATE INDEX idx_noti_seeker ON notification (job_seeker_id, is_read);

-- =====================================================================
-- 16. ADMIN
-- =====================================================================
CREATE TABLE admin (
  admin_id BIGSERIAL PRIMARY KEY,
  full_name VARCHAR(255),
  email VARCHAR(255) UNIQUE NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- =====================================================================
-- 17. AI MATCHING LOG
-- =====================================================================
CREATE TABLE ai_matching_log (
  log_id BIGSERIAL PRIMARY KEY,
  job_seeker_id BIGINT NULL,                     -- Migration 002: NULL cho AI matching ẩn danh
  prompt_text TEXT NOT NULL,
  response_text TEXT NOT NULL,
  model_name VARCHAR(100),
  total_jobs_sent INT,
  processing_time_ms INT,
  task VARCHAR(50),                               -- Migration 002
  tokens_in INTEGER DEFAULT 0,                    -- Migration 002
  tokens_out INTEGER DEFAULT 0,                   -- Migration 002
  success BOOLEAN DEFAULT TRUE,                   -- Migration 002
  error TEXT,                                     -- Migration 002
  created_at TIMESTAMPTZ DEFAULT now(),
  CONSTRAINT fk_ai_matching_log_job_seeker
      FOREIGN KEY (job_seeker_id) REFERENCES job_seeker(job_seeker_id)
      ON DELETE CASCADE
);

CREATE INDEX idx_ai_matching_log_job_seeker ON ai_matching_log (job_seeker_id);
ALTER TABLE employer
  ADD COLUMN IF NOT EXISTS contact_name VARCHAR(255),
  ADD COLUMN IF NOT EXISTS gender VARCHAR(10);
```
