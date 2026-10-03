-- =============================================================================
-- Optional reviewed data fix — known demo-account UTF-8 corruption
-- =============================================================================
-- Do not run automatically. Apply only after verifying the IDs and current
-- values in the target environment. The application code prevents new
-- filename mojibake; these guarded updates repair the already-corrupted demo.

BEGIN;

UPDATE public.job_seeker
SET city = 'Hồ Chí Minh'
WHERE job_seeker_id = 4
  AND email = 'seeker@jobhub.vn'
  AND city IS DISTINCT FROM 'Hồ Chí Minh';

UPDATE public.resume
SET file_name = '[FPTU] CV Intern Tester - Nguyễn Trần Gia Bảo.pdf.pdf'
WHERE resume_id = 5
  AND job_seeker_id = 4
  AND file_name IS DISTINCT FROM '[FPTU] CV Intern Tester - Nguyễn Trần Gia Bảo.pdf.pdf';

COMMIT;
