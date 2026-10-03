-- =============================================================================
-- JobHub — FULL DATABASE SCHEMA (fresh install)
-- =============================================================================
-- Chạy toàn bộ script này trong Supabase SQL Editor để tạo lại database từ đầu.
-- Bao gồm: schema gốc + migration 001-005.
-- An toàn để chạy lại (idempotent).
-- =============================================================================

-- ============================== ENUM TYPES ===================================
DO $$ BEGIN
  CREATE TYPE public.skill_source AS ENUM ('MANUAL', 'AI');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE public.salary_period AS ENUM ('HOUR', 'MONTH', 'YEAR');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE public.work_mode AS ENUM ('ONSITE', 'REMOTE', 'HYBRID');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE public.job_type AS ENUM ('FULL_TIME', 'PART_TIME', 'INTERNSHIP', 'CONTRACT');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE public.experience_level AS ENUM ('INTERN', 'FRESHER', 'JUNIOR', 'MID', 'SENIOR', 'LEAD');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE public.job_status AS ENUM ('DRAFT', 'OPEN', 'PAUSED', 'CLOSED', 'EXPIRED');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE public.application_status AS ENUM ('SUBMITTED', 'UNDER_REVIEW', 'INTERVIEW', 'OFFER', 'ACCEPTED', 'REJECTED', 'WITHDRAWN');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE public.recommendation_status AS ENUM ('NEW', 'VIEWED', 'DISMISSED', 'APPLIED');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- ========================= UPDATED_AT TRIGGER ================================
CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ============================== 1. JOB SEEKER ================================
CREATE TABLE IF NOT EXISTS public.job_seeker (
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

DROP TRIGGER IF EXISTS trg_job_seeker_updated_at ON public.job_seeker;
CREATE TRIGGER trg_job_seeker_updated_at
  BEFORE UPDATE ON public.job_seeker
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- ============================== 2. EMPLOYER ==================================
-- (gồm Migration 001: contact_name, gender)
CREATE TABLE IF NOT EXISTS public.employer (
  employer_id   BIGSERIAL PRIMARY KEY,
  company_name  VARCHAR(255) NOT NULL,
  email         VARCHAR(255) NOT NULL UNIQUE,
  password_hash VARCHAR(255) NOT NULL,
  phone         VARCHAR(20),
  website       VARCHAR(255),
  company_description TEXT,
  city          VARCHAR(100),
  contact_name  VARCHAR(255),
  gender        VARCHAR(10),
  is_verified   BOOLEAN DEFAULT FALSE,
  created_at    TIMESTAMPTZ DEFAULT now(),
  updated_at    TIMESTAMPTZ DEFAULT now(),
  is_active     BOOLEAN NOT NULL DEFAULT TRUE
);

DROP TRIGGER IF EXISTS trg_employer_updated_at ON public.employer;
CREATE TRIGGER trg_employer_updated_at
  BEFORE UPDATE ON public.employer
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- ============================== 3. CATEGORY ==================================
CREATE TABLE IF NOT EXISTS public.category (
  category_id BIGSERIAL PRIMARY KEY,
  name        VARCHAR(100) NOT NULL UNIQUE
);

-- ============================== 4. SKILL =====================================
CREATE TABLE IF NOT EXISTS public.skill (
  skill_id   BIGSERIAL PRIMARY KEY,
  skill_name VARCHAR(100) NOT NULL UNIQUE,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

DROP TRIGGER IF EXISTS trg_skill_updated_at ON public.skill;
CREATE TRIGGER trg_skill_updated_at
  BEFORE UPDATE ON public.skill
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- ============================== 5. RESUME ====================================
CREATE TABLE IF NOT EXISTS public.resume (
  resume_id     BIGSERIAL PRIMARY KEY,
  job_seeker_id BIGINT NOT NULL,
  title         VARCHAR(255),
  file_name     VARCHAR(255),
  file_path     VARCHAR(500),
  is_primary    BOOLEAN DEFAULT FALSE,
  upload_date   TIMESTAMPTZ DEFAULT now(),
  CONSTRAINT fk_resume_job_seeker
    FOREIGN KEY (job_seeker_id) REFERENCES public.job_seeker(job_seeker_id)
    ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_resume_seeker ON public.resume (job_seeker_id);

-- ============================== 6. AI ANALYSIS ===============================
CREATE TABLE IF NOT EXISTS public.ai_analysis (
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
    FOREIGN KEY (resume_id) REFERENCES public.resume(resume_id)
    ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_analysis_resume ON public.ai_analysis (resume_id);
CREATE INDEX IF NOT EXISTS idx_analysis_extracted_skills ON public.ai_analysis USING GIN (extracted_skills);

-- ============================== 7. WORK EXPERIENCE ===========================
CREATE TABLE IF NOT EXISTS public.work_experience (
  experience_id BIGSERIAL PRIMARY KEY,
  job_seeker_id BIGINT NOT NULL,
  company_name  VARCHAR(255),
  position      VARCHAR(255),
  start_date    DATE,
  end_date      DATE,
  description   TEXT,
  CONSTRAINT fk_we_seeker
    FOREIGN KEY (job_seeker_id) REFERENCES public.job_seeker(job_seeker_id)
    ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_we_seeker ON public.work_experience (job_seeker_id);

-- ============================== 8. EDUCATION =================================
CREATE TABLE IF NOT EXISTS public.education (
  education_id  BIGSERIAL PRIMARY KEY,
  job_seeker_id BIGINT NOT NULL,
  school_name   VARCHAR(255),
  degree        VARCHAR(100),
  major         VARCHAR(255),
  start_year    SMALLINT,
  end_year      SMALLINT,
  CONSTRAINT fk_edu_seeker
    FOREIGN KEY (job_seeker_id) REFERENCES public.job_seeker(job_seeker_id)
    ON DELETE CASCADE,
  CONSTRAINT chk_education_start_year CHECK (start_year IS NULL OR start_year BETWEEN 1900 AND 9999),
  CONSTRAINT chk_education_end_year CHECK (end_year IS NULL OR end_year BETWEEN 1900 AND 9999)
);

CREATE INDEX IF NOT EXISTS idx_edu_seeker ON public.education (job_seeker_id);

-- ============================== 9. JOB SEEKER SKILL ==========================
CREATE TABLE IF NOT EXISTS public.job_seeker_skill (
  job_seeker_id    BIGINT NOT NULL,
  skill_id         BIGINT NOT NULL,
  experience_years DECIMAL(4,1),
  skill_detail     TEXT,
  source           public.skill_source DEFAULT 'MANUAL',
  PRIMARY KEY (job_seeker_id, skill_id),
  CONSTRAINT fk_jss_job_seeker
    FOREIGN KEY (job_seeker_id) REFERENCES public.job_seeker(job_seeker_id)
    ON DELETE CASCADE,
  CONSTRAINT fk_jss_skill
    FOREIGN KEY (skill_id) REFERENCES public.skill(skill_id)
    ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_jss_skill ON public.job_seeker_skill (skill_id);

-- ============================== 10. JOB ======================================
CREATE TABLE IF NOT EXISTS public.job (
  job_id          BIGSERIAL PRIMARY KEY,
  employer_id     BIGINT NOT NULL,
  category_id     BIGINT NULL,
  job_title       VARCHAR(255) NOT NULL,
  job_description TEXT,
  salary_min      DECIMAL(15,2),
  salary_max      DECIMAL(15,2),
  salary_currency CHAR(3) DEFAULT 'VND',
  salary_period   public.salary_period DEFAULT 'MONTH',
  is_salary_negotiable BOOLEAN DEFAULT FALSE,
  location        VARCHAR(255),
  city            VARCHAR(100),
  country         VARCHAR(100) DEFAULT 'Vietnam',
  work_mode       public.work_mode NOT NULL DEFAULT 'ONSITE',
  job_type        public.job_type NOT NULL,
  experience_level public.experience_level,
  positions_available  INT DEFAULT 1,
  application_deadline DATE,
  status          public.job_status DEFAULT 'OPEN',
  created_at      TIMESTAMPTZ DEFAULT now(),
  updated_at      TIMESTAMPTZ DEFAULT now(),
  is_approved     BOOLEAN NOT NULL DEFAULT FALSE,
  CONSTRAINT fk_job_employer
    FOREIGN KEY (employer_id) REFERENCES public.employer(employer_id)
    ON DELETE CASCADE,
  CONSTRAINT fk_job_category
    FOREIGN KEY (category_id) REFERENCES public.category(category_id)
    ON DELETE SET NULL,
  CONSTRAINT chk_salary CHECK (salary_min IS NULL OR salary_max IS NULL OR salary_min <= salary_max)
);

DROP TRIGGER IF EXISTS trg_job_updated_at ON public.job;
CREATE TRIGGER trg_job_updated_at
  BEFORE UPDATE ON public.job
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE INDEX IF NOT EXISTS idx_job_employer ON public.job (employer_id);
CREATE INDEX IF NOT EXISTS idx_job_filter ON public.job (status, job_type, work_mode, city);
CREATE INDEX IF NOT EXISTS idx_job_salary ON public.job (salary_min, salary_max);
CREATE INDEX IF NOT EXISTS idx_job_category_id ON public.job (category_id);

-- ============================== 11. JOB SKILL ================================
CREATE TABLE IF NOT EXISTS public.job_skill (
  job_id               BIGINT NOT NULL,
  skill_id             BIGINT NOT NULL,
  is_required          BOOLEAN DEFAULT TRUE,
  min_experience_years DECIMAL(4,1) DEFAULT 0,
  weight               SMALLINT DEFAULT 1,
  PRIMARY KEY (job_id, skill_id),
  CONSTRAINT fk_js_job
    FOREIGN KEY (job_id) REFERENCES public.job(job_id)
    ON DELETE CASCADE,
  CONSTRAINT fk_js_skill
    FOREIGN KEY (skill_id) REFERENCES public.skill(skill_id)
    ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_js_skill ON public.job_skill (skill_id);

-- ============================== 12. APPLICATION ==============================
CREATE TABLE IF NOT EXISTS public.application (
  application_id   BIGSERIAL PRIMARY KEY,
  job_seeker_id    BIGINT NOT NULL,
  job_id           BIGINT NOT NULL,
  resume_id        BIGINT NULL,
  cover_letter     TEXT,
  application_date TIMESTAMPTZ DEFAULT now(),
  status           public.application_status DEFAULT 'SUBMITTED',
  updated_at       TIMESTAMPTZ DEFAULT now(),
  CONSTRAINT fk_application_job_seeker
    FOREIGN KEY (job_seeker_id) REFERENCES public.job_seeker(job_seeker_id)
    ON DELETE CASCADE,
  CONSTRAINT fk_application_job
    FOREIGN KEY (job_id) REFERENCES public.job(job_id)
    ON DELETE CASCADE,
  CONSTRAINT fk_application_resume
    FOREIGN KEY (resume_id) REFERENCES public.resume(resume_id)
    ON DELETE SET NULL,
  CONSTRAINT uq_application UNIQUE (job_seeker_id, job_id)
);

DROP TRIGGER IF EXISTS trg_application_updated_at ON public.application;
CREATE TRIGGER trg_application_updated_at
  BEFORE UPDATE ON public.application
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE INDEX IF NOT EXISTS idx_app_seeker ON public.application (job_seeker_id);
CREATE INDEX IF NOT EXISTS idx_app_job ON public.application (job_id);
CREATE INDEX IF NOT EXISTS idx_app_status ON public.application (job_id, status);

-- ============== 13. APPLICATION STATUS HISTORY (Migration 004+005) ===========
CREATE TABLE IF NOT EXISTS public.application_status_history (
  id                BIGSERIAL PRIMARY KEY,
  application_id    BIGINT NOT NULL,
  old_status        public.application_status,
  new_status        public.application_status NOT NULL,
  changed_by        BIGINT NOT NULL,
  changed_by_role   VARCHAR(20),
  changed_at        TIMESTAMPTZ DEFAULT now(),
  CONSTRAINT fk_ash_application
    FOREIGN KEY (application_id) REFERENCES public.application(application_id)
    ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_ash_application
  ON public.application_status_history (application_id);

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conrelid = 'public.application_status_history'::regclass
      AND conname = 'chk_application_history_actor_role'
  ) THEN
    ALTER TABLE public.application_status_history
      ADD CONSTRAINT chk_application_history_actor_role
      CHECK (changed_by_role IS NULL OR changed_by_role IN ('job_seeker', 'employer', 'admin'));
  END IF;
END
$$;

-- Trigger: tự động ghi history khi có application mới
CREATE OR REPLACE FUNCTION public.trg_application_status_history()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.application_status_history (
    application_id, old_status, new_status, changed_by, changed_by_role
  ) VALUES (
    NEW.application_id, NULL, NEW.status, NEW.job_seeker_id, 'job_seeker'
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS after_application_insert ON public.application;
CREATE TRIGGER after_application_insert
  AFTER INSERT ON public.application
  FOR EACH ROW EXECUTE FUNCTION public.trg_application_status_history();

-- RPC: cập nhật trạng thái atomically (Migration 005)
DROP FUNCTION IF EXISTS public.update_application_status(BIGINT, public.application_status, public.application_status, BIGINT, VARCHAR);
DROP FUNCTION IF EXISTS public.update_application_status(BIGINT, VARCHAR, VARCHAR, BIGINT, VARCHAR);

CREATE OR REPLACE FUNCTION public.update_application_status(
  p_application_id BIGINT,
  p_expected_status public.application_status,
  p_new_status public.application_status,
  p_changed_by BIGINT,
  p_changed_by_role VARCHAR,
  p_employer_id BIGINT DEFAULT NULL,
  p_is_admin BOOLEAN DEFAULT FALSE
)
RETURNS TABLE (
  result_application_id BIGINT,
  result_status public.application_status,
  result_updated_at TIMESTAMPTZ,
  history_id BIGINT
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_current_status public.application_status;
  v_owning_employer_id BIGINT;
  v_saved_updated_at TIMESTAMPTZ;
  v_saved_history_id BIGINT;
BEGIN
  IF p_changed_by_role NOT IN ('employer', 'admin')
    OR (p_is_admin AND p_changed_by_role <> 'admin')
    OR (NOT p_is_admin AND p_changed_by_role <> 'employer') THEN
    RAISE EXCEPTION USING ERRCODE = '42501', MESSAGE = 'APPLICATION_FORBIDDEN';
  END IF;

  SELECT a.status, j.employer_id
  INTO v_current_status, v_owning_employer_id
  FROM public.application AS a
  JOIN public.job AS j ON j.job_id = a.job_id
  WHERE a.application_id = p_application_id
  FOR UPDATE OF a;

  IF NOT FOUND THEN
    RAISE EXCEPTION USING ERRCODE = 'P0002', MESSAGE = 'APPLICATION_NOT_FOUND';
  END IF;

  IF NOT p_is_admin AND v_owning_employer_id IS DISTINCT FROM p_employer_id THEN
    RAISE EXCEPTION USING ERRCODE = '42501', MESSAGE = 'APPLICATION_FORBIDDEN';
  END IF;

  IF v_current_status IS DISTINCT FROM p_expected_status THEN
    RAISE EXCEPTION USING ERRCODE = '40001', MESSAGE = 'APPLICATION_STATUS_CONFLICT';
  END IF;

  IF NOT (
    (v_current_status = 'SUBMITTED' AND p_new_status IN ('UNDER_REVIEW', 'ACCEPTED', 'REJECTED'))
    OR
    (v_current_status = 'UNDER_REVIEW' AND p_new_status IN ('ACCEPTED', 'REJECTED'))
  ) THEN
    RAISE EXCEPTION USING ERRCODE = '22023', MESSAGE = 'INVALID_STATUS_TRANSITION';
  END IF;

  UPDATE public.application
  SET status = p_new_status, updated_at = now()
  WHERE application_id = p_application_id
  RETURNING updated_at INTO v_saved_updated_at;

  INSERT INTO public.application_status_history (
    application_id, old_status, new_status, changed_by, changed_by_role, changed_at
  ) VALUES (
    p_application_id, v_current_status, p_new_status,
    p_changed_by, p_changed_by_role, now()
  )
  RETURNING id INTO v_saved_history_id;

  RETURN QUERY
  SELECT p_application_id, p_new_status, v_saved_updated_at, v_saved_history_id;
END;
$$;

REVOKE ALL ON FUNCTION public.update_application_status(
  BIGINT, public.application_status, public.application_status,
  BIGINT, VARCHAR, BIGINT, BOOLEAN
) FROM PUBLIC;

GRANT EXECUTE ON FUNCTION public.update_application_status(
  BIGINT, public.application_status, public.application_status,
  BIGINT, VARCHAR, BIGINT, BOOLEAN
) TO service_role;

-- ============================== 14. JOB RECOMMENDATION =======================
CREATE TABLE IF NOT EXISTS public.job_recommendation (
  recommendation_id     BIGSERIAL PRIMARY KEY,
  job_seeker_id         BIGINT NOT NULL,
  job_id                BIGINT NOT NULL,
  resume_id             BIGINT NULL,
  match_score           DECIMAL(5,2),
  recommendation_reason TEXT,
  status                public.recommendation_status DEFAULT 'NEW',
  generated_at          TIMESTAMPTZ DEFAULT now(),
  CONSTRAINT fk_rec_job_seeker
    FOREIGN KEY (job_seeker_id) REFERENCES public.job_seeker(job_seeker_id)
    ON DELETE CASCADE,
  CONSTRAINT fk_rec_job
    FOREIGN KEY (job_id) REFERENCES public.job(job_id)
    ON DELETE CASCADE,
  CONSTRAINT fk_rec_resume
    FOREIGN KEY (resume_id) REFERENCES public.resume(resume_id)
    ON DELETE SET NULL,
  CONSTRAINT uq_recommendation UNIQUE (job_seeker_id, job_id),
  CONSTRAINT chk_score CHECK (match_score BETWEEN 0 AND 100)
);

CREATE INDEX IF NOT EXISTS idx_rec_seeker_score
  ON public.job_recommendation (job_seeker_id, match_score DESC);

-- ============================== 15. SAVED JOB ================================
CREATE TABLE IF NOT EXISTS public.saved_job (
  job_seeker_id BIGINT NOT NULL,
  job_id        BIGINT NOT NULL,
  saved_at      TIMESTAMPTZ DEFAULT now(),
  PRIMARY KEY (job_seeker_id, job_id),
  CONSTRAINT fk_sj_seeker
    FOREIGN KEY (job_seeker_id) REFERENCES public.job_seeker(job_seeker_id)
    ON DELETE CASCADE,
  CONSTRAINT fk_sj_job
    FOREIGN KEY (job_id) REFERENCES public.job(job_id)
    ON DELETE CASCADE
);

-- ============================== 16. NOTIFICATION =============================
CREATE TABLE IF NOT EXISTS public.notification (
  notification_id BIGSERIAL PRIMARY KEY,
  job_seeker_id   BIGINT NULL,
  employer_id     BIGINT NULL,
  type            VARCHAR(50),
  title           VARCHAR(255),
  message         TEXT,
  is_read         BOOLEAN DEFAULT FALSE,
  created_at      TIMESTAMPTZ DEFAULT now(),
  CONSTRAINT fk_noti_seeker
    FOREIGN KEY (job_seeker_id) REFERENCES public.job_seeker(job_seeker_id)
    ON DELETE CASCADE,
  CONSTRAINT fk_noti_employer
    FOREIGN KEY (employer_id) REFERENCES public.employer(employer_id)
    ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_noti_seeker ON public.notification (job_seeker_id, is_read);

-- ============================== 17. ADMIN ====================================
CREATE TABLE IF NOT EXISTS public.admin (
  admin_id BIGSERIAL PRIMARY KEY,
  full_name VARCHAR(255),
  email VARCHAR(255) UNIQUE NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- ============== 18. AI MATCHING LOG (gồm Migration 002) ======================
CREATE TABLE IF NOT EXISTS public.ai_matching_log (
  log_id BIGSERIAL PRIMARY KEY,
  job_seeker_id BIGINT NULL,
  prompt_text TEXT NOT NULL,
  response_text TEXT NOT NULL,
  model_name VARCHAR(100),
  total_jobs_sent INT,
  processing_time_ms INT,
  task VARCHAR(50),
  tokens_in INTEGER DEFAULT 0,
  tokens_out INTEGER DEFAULT 0,
  success BOOLEAN DEFAULT TRUE,
  error TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  CONSTRAINT fk_ai_matching_log_job_seeker
    FOREIGN KEY (job_seeker_id) REFERENCES public.job_seeker(job_seeker_id)
    ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_ai_matching_log_job_seeker
  ON public.ai_matching_log (job_seeker_id);

-- =============================================================================
-- HOÀN TẤT — kiểm tra bằng:
-- SELECT table_name FROM information_schema.tables
-- WHERE table_schema = 'public' ORDER BY table_name;
-- =============================================================================
