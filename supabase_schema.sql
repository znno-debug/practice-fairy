-- ============================================================================
-- 🧚‍♀️ 연습요정 (Practice Fairy) Supabase 클라우드 DB 초기화 SQL
-- 사용법: Supabase Dashboard -> SQL Editor -> New Query 에 전체 복사 후 [Run] 클릭
-- 특징: 로그인 없이 개인/다중 기기 실시간 동기화를 위해 7개 테이블 생성 및 anon 권한 허용
-- ============================================================================

-- 1. 선생님 프로필 및 입금 계좌 (fairy_teacher_profile_v1)
CREATE TABLE IF NOT EXISTS public.fairy_teacher_profile_v1 (
  id TEXT PRIMARY KEY DEFAULT 'default',
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

-- 2. 수강생 명단 및 수강권 정보 (fairy_students_v1)
CREATE TABLE IF NOT EXISTS public.fairy_students_v1 (
  id TEXT PRIMARY KEY,
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

-- 3. 수업 일정 및 5대 출결 기록 (fairy_lessons_v1)
CREATE TABLE IF NOT EXISTS public.fairy_lessons_v1 (
  id TEXT PRIMARY KEY,
  "studentId" TEXT,
  date TEXT,
  time TEXT,
  type TEXT,
  status TEXT,
  "sessionNum" INTEGER,
  "makeupResolved" BOOLEAN DEFAULT false,
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- 4. 레슨 노트 및 학부모 리포트 (fairy_notes_v1)
CREATE TABLE IF NOT EXISTS public.fairy_notes_v1 (
  id TEXT PRIMARY KEY,
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

-- 5. 수강생별 연습 체크리스트 (fairy_practice_v1)
CREATE TABLE IF NOT EXISTS public.fairy_practice_v1 (
  "studentId" TEXT PRIMARY KEY,
  items JSONB NOT NULL DEFAULT '[]'::jsonb,
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- 6. 수강생 질문 보관함 (fairy_questions_v1)
CREATE TABLE IF NOT EXISTS public.fairy_questions_v1 (
  id TEXT PRIMARY KEY,
  "studentId" TEXT,
  text TEXT,
  category TEXT,
  date TEXT,
  answered BOOLEAN DEFAULT false,
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- 7. 마이 연습실 세션 타임라인 (fairy_sessions_v1)
CREATE TABLE IF NOT EXISTS public.fairy_sessions_v1 (
  "studentId" TEXT PRIMARY KEY,
  sessions JSONB NOT NULL DEFAULT '[]'::jsonb,
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- ============================================================================
-- 🔓 RLS (Row Level Security) 설정: 별도 로그인 없이 anon 키로 읽기/쓰기 허용
-- ============================================================================
ALTER TABLE public.fairy_teacher_profile_v1 ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.fairy_students_v1 ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.fairy_lessons_v1 ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.fairy_notes_v1 ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.fairy_practice_v1 ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.fairy_questions_v1 ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.fairy_sessions_v1 ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Allow public access to fairy_teacher_profile_v1" ON public.fairy_teacher_profile_v1;
CREATE POLICY "Allow public access to fairy_teacher_profile_v1"
  ON public.fairy_teacher_profile_v1 FOR ALL TO anon, authenticated USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Allow public access to fairy_students_v1" ON public.fairy_students_v1;
CREATE POLICY "Allow public access to fairy_students_v1"
  ON public.fairy_students_v1 FOR ALL TO anon, authenticated USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Allow public access to fairy_lessons_v1" ON public.fairy_lessons_v1;
CREATE POLICY "Allow public access to fairy_lessons_v1"
  ON public.fairy_lessons_v1 FOR ALL TO anon, authenticated USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Allow public access to fairy_notes_v1" ON public.fairy_notes_v1;
CREATE POLICY "Allow public access to fairy_notes_v1"
  ON public.fairy_notes_v1 FOR ALL TO anon, authenticated USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Allow public access to fairy_practice_v1" ON public.fairy_practice_v1;
CREATE POLICY "Allow public access to fairy_practice_v1"
  ON public.fairy_practice_v1 FOR ALL TO anon, authenticated USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Allow public access to fairy_questions_v1" ON public.fairy_questions_v1;
CREATE POLICY "Allow public access to fairy_questions_v1"
  ON public.fairy_questions_v1 FOR ALL TO anon, authenticated USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Allow public access to fairy_sessions_v1" ON public.fairy_sessions_v1;
CREATE POLICY "Allow public access to fairy_sessions_v1"
  ON public.fairy_sessions_v1 FOR ALL TO anon, authenticated USING (true) WITH CHECK (true);
