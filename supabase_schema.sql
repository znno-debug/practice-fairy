-- ============================================================================
-- 🧚‍♀️ 연습요정 (Practice Fairy) Supabase 클라우드 DB 초기화 및 멀티유저 RLS SQL
-- 사용법: Supabase Dashboard -> SQL Editor -> New Query 에 전체 복사 후 [Run] 클릭
-- 특징:
--   1) 1~7번 선생님 업무 테이블은 user_id 컬럼 및 auth.uid() = user_id RLS 적용
--   2) 8번 공유 리포트 스냅샷(fairy_shared_reports_v1)은 학부모 비로그인 열람(SELECT) 허용
--   3) 기존 테이블이 이미 있는 경우에도 ADD COLUMN IF NOT EXISTS로 안전하게 반영
-- ============================================================================

-- 1. 선생님 프로필 및 입금 계좌 (fairy_teacher_profile_v1)
CREATE TABLE IF NOT EXISTS public.fairy_teacher_profile_v1 (
  id TEXT PRIMARY KEY DEFAULT 'default',
  user_id UUID,
  name TEXT,
  subject TEXT,
  phone TEXT,
  bio TEXT,
  "bankName" TEXT,
  "accountNumber" TEXT,
  "accountHolder" TEXT,
  "avatarUrl" TEXT,
  updated_at TIMESTAMPTZ DEFAULT now()
);
ALTER TABLE public.fairy_teacher_profile_v1 ADD COLUMN IF NOT EXISTS user_id UUID;

-- 2. 수강생 명단 및 수강권 정보 (fairy_students_v1)
CREATE TABLE IF NOT EXISTS public.fairy_students_v1 (
  id TEXT PRIMARY KEY,
  user_id UUID,
  type TEXT DEFAULT 'child',
  name TEXT NOT NULL,
  subject TEXT,
  grade TEXT,
  "totalPass" INTEGER DEFAULT 8,
  "usedPass" INTEGER DEFAULT 0,
  fee INTEGER DEFAULT 0,
  phone TEXT,
  schedule TEXT,
  "currentPiece" TEXT,
  updated_at TIMESTAMPTZ DEFAULT now()
);
ALTER TABLE public.fairy_students_v1 ADD COLUMN IF NOT EXISTS user_id UUID;

-- 3. 수업 일정 및 5대 출결 기록 (fairy_lessons_v1)
CREATE TABLE IF NOT EXISTS public.fairy_lessons_v1 (
  id TEXT PRIMARY KEY,
  user_id UUID,
  "studentId" TEXT,
  date TEXT,
  time TEXT,
  type TEXT,
  status TEXT,
  "sessionNum" INTEGER,
  "makeupResolved" BOOLEAN DEFAULT false,
  updated_at TIMESTAMPTZ DEFAULT now()
);
ALTER TABLE public.fairy_lessons_v1 ADD COLUMN IF NOT EXISTS user_id UUID;

-- 4. 레슨 노트 및 학부모 리포트 (fairy_notes_v1)
CREATE TABLE IF NOT EXISTS public.fairy_notes_v1 (
  id TEXT PRIMARY KEY,
  user_id UUID,
  "lessonId" TEXT,
  "studentId" TEXT,
  "studentName" TEXT,
  subject TEXT,
  date TEXT,
  "sessionNum" INTEGER,
  "totalPass" INTEGER,
  piece TEXT,
  technique TEXT,
  badge TEXT,
  feedback TEXT,
  homework TEXT,
  "parentMsg" TEXT,
  "youtubeUrl" TEXT,
  "createdAt" TEXT,
  updated_at TIMESTAMPTZ DEFAULT now()
);
ALTER TABLE public.fairy_notes_v1 ADD COLUMN IF NOT EXISTS user_id UUID;

-- 5. 수강생별 연습 체크리스트 (fairy_practice_v1)
CREATE TABLE IF NOT EXISTS public.fairy_practice_v1 (
  "studentId" TEXT PRIMARY KEY,
  user_id UUID,
  items JSONB NOT NULL DEFAULT '[]'::jsonb,
  updated_at TIMESTAMPTZ DEFAULT now()
);
ALTER TABLE public.fairy_practice_v1 ADD COLUMN IF NOT EXISTS user_id UUID;

-- 6. 수강생 질문 보관함 (fairy_questions_v1)
CREATE TABLE IF NOT EXISTS public.fairy_questions_v1 (
  id TEXT PRIMARY KEY,
  user_id UUID,
  "studentId" TEXT,
  text TEXT,
  category TEXT,
  date TEXT,
  answered BOOLEAN DEFAULT false,
  updated_at TIMESTAMPTZ DEFAULT now()
);
ALTER TABLE public.fairy_questions_v1 ADD COLUMN IF NOT EXISTS user_id UUID;

-- 7. 마이 연습실 세션 타임라인 (fairy_sessions_v1)
CREATE TABLE IF NOT EXISTS public.fairy_sessions_v1 (
  "studentId" TEXT PRIMARY KEY,
  user_id UUID,
  sessions JSONB NOT NULL DEFAULT '[]'::jsonb,
  updated_at TIMESTAMPTZ DEFAULT now()
);
ALTER TABLE public.fairy_sessions_v1 ADD COLUMN IF NOT EXISTS user_id UUID;

-- 8. 학부모/수강생 공유용 1:1 리포트 단축 URL 스냅샷 (fairy_shared_reports_v1)
CREATE TABLE IF NOT EXISTS public.fairy_shared_reports_v1 (
  id TEXT PRIMARY KEY,
  user_id UUID,
  payload JSONB NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT now()
);
ALTER TABLE public.fairy_shared_reports_v1 ADD COLUMN IF NOT EXISTS user_id UUID;

-- ============================================================================
-- 🔒 테이블 권한(GRANT) 및 RLS (Row Level Security) 설정
-- 1~7번 테이블: 로그인한 선생님 본인(auth.uid() = user_id)만 읽기/쓰기 가능
-- 8번 테이블: 학부모 비로그인 열람을 위해 SELECT는 공개, 쓰기는 로그인한 작성자만 허용
-- ============================================================================
GRANT USAGE ON SCHEMA public TO anon, authenticated;

GRANT ALL ON TABLE public.fairy_teacher_profile_v1 TO authenticated;
GRANT ALL ON TABLE public.fairy_students_v1 TO authenticated;
GRANT ALL ON TABLE public.fairy_lessons_v1 TO authenticated;
GRANT ALL ON TABLE public.fairy_notes_v1 TO authenticated;
GRANT ALL ON TABLE public.fairy_practice_v1 TO authenticated;
GRANT ALL ON TABLE public.fairy_questions_v1 TO authenticated;
GRANT ALL ON TABLE public.fairy_sessions_v1 TO authenticated;

GRANT SELECT ON TABLE public.fairy_shared_reports_v1 TO anon;
GRANT ALL ON TABLE public.fairy_shared_reports_v1 TO authenticated;

ALTER TABLE public.fairy_teacher_profile_v1 ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.fairy_students_v1 ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.fairy_lessons_v1 ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.fairy_notes_v1 ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.fairy_practice_v1 ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.fairy_questions_v1 ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.fairy_sessions_v1 ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.fairy_shared_reports_v1 ENABLE ROW LEVEL SECURITY;

-- 기존 전체 공개 정책 제거 후 유저별 RLS 정책 적용 (1~7번)
DROP POLICY IF EXISTS "Allow public access to fairy_teacher_profile_v1" ON public.fairy_teacher_profile_v1;
DROP POLICY IF EXISTS "Owner access to fairy_teacher_profile_v1" ON public.fairy_teacher_profile_v1;
CREATE POLICY "Owner access to fairy_teacher_profile_v1"
  ON public.fairy_teacher_profile_v1 FOR ALL TO authenticated
  USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Allow public access to fairy_students_v1" ON public.fairy_students_v1;
DROP POLICY IF EXISTS "Owner access to fairy_students_v1" ON public.fairy_students_v1;
CREATE POLICY "Owner access to fairy_students_v1"
  ON public.fairy_students_v1 FOR ALL TO authenticated
  USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Allow public access to fairy_lessons_v1" ON public.fairy_lessons_v1;
DROP POLICY IF EXISTS "Owner access to fairy_lessons_v1" ON public.fairy_lessons_v1;
CREATE POLICY "Owner access to fairy_lessons_v1"
  ON public.fairy_lessons_v1 FOR ALL TO authenticated
  USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Allow public access to fairy_notes_v1" ON public.fairy_notes_v1;
DROP POLICY IF EXISTS "Owner access to fairy_notes_v1" ON public.fairy_notes_v1;
CREATE POLICY "Owner access to fairy_notes_v1"
  ON public.fairy_notes_v1 FOR ALL TO authenticated
  USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Allow public access to fairy_practice_v1" ON public.fairy_practice_v1;
DROP POLICY IF EXISTS "Owner access to fairy_practice_v1" ON public.fairy_practice_v1;
CREATE POLICY "Owner access to fairy_practice_v1"
  ON public.fairy_practice_v1 FOR ALL TO authenticated
  USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Allow public access to fairy_questions_v1" ON public.fairy_questions_v1;
DROP POLICY IF EXISTS "Owner access to fairy_questions_v1" ON public.fairy_questions_v1;
CREATE POLICY "Owner access to fairy_questions_v1"
  ON public.fairy_questions_v1 FOR ALL TO authenticated
  USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Allow public access to fairy_sessions_v1" ON public.fairy_sessions_v1;
DROP POLICY IF EXISTS "Owner access to fairy_sessions_v1" ON public.fairy_sessions_v1;
CREATE POLICY "Owner access to fairy_sessions_v1"
  ON public.fairy_sessions_v1 FOR ALL TO authenticated
  USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- 8번 공유 리포트 스냅샷: 비로그인 학부모 열람(SELECT) 허용 + 작성자(authenticated) 쓰기 허용
DROP POLICY IF EXISTS "Allow public access to fairy_shared_reports_v1" ON public.fairy_shared_reports_v1;
DROP POLICY IF EXISTS "Public read shared reports" ON public.fairy_shared_reports_v1;
DROP POLICY IF EXISTS "Owner write shared reports" ON public.fairy_shared_reports_v1;
CREATE POLICY "Public read shared reports"
  ON public.fairy_shared_reports_v1 FOR SELECT TO anon, authenticated
  USING (true);
CREATE POLICY "Owner write shared reports"
  ON public.fairy_shared_reports_v1 FOR ALL TO authenticated
  USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
