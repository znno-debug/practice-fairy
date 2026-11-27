-- ============================================================================
-- 🧚‍♀️ 연습요정 (Practice Fairy) Supabase 클라우드 DB 초기화 및 멀티유저 RLS SQL
-- 사용법: Supabase Dashboard -> SQL Editor -> New Query 에 전체 복사 후 [Run] 클릭
-- 특징:
--   1) 1~7번 선생님 업무 테이블은 user_id 컬럼 및 auth.uid() = user_id RLS 적용
--   2) 8번 공유 리포트 스냅샷(fairy_shared_reports_v1)은 테이블 직접 조회 금지.
--      학부모는 링크 id 하나로 그 리포트만 받는 get_shared_report() RPC로만 열람
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

-- 비로그인(anon)은 공유 리포트 테이블을 직접 읽을 수 없음 (전체 목록 조회 차단). 열람은 get_shared_report() RPC로만.
REVOKE ALL ON TABLE public.fairy_shared_reports_v1 FROM anon;
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

-- 8번 공유 리포트 스냅샷: 작성자(authenticated) 본인만 읽기/쓰기.
-- (2026-11-27 보안 수정) 예전 "Public read shared reports"(USING true)는 anon 키로 전체 리포트를
-- 한꺼번에 조회할 수 있어 삭제함. 학부모 열람은 아래 get_shared_report(p_id) RPC로만 가능.
DROP POLICY IF EXISTS "Allow public access to fairy_shared_reports_v1" ON public.fairy_shared_reports_v1;
DROP POLICY IF EXISTS "Public read shared reports" ON public.fairy_shared_reports_v1;
DROP POLICY IF EXISTS "Owner write shared reports" ON public.fairy_shared_reports_v1;
CREATE POLICY "Owner write shared reports"
  ON public.fairy_shared_reports_v1 FOR ALL TO authenticated
  USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- ============================================================================
-- 🔗 학부모 리포트 열람 RPC: 링크 id와 정확히 같은 리포트 1건의 payload만 돌려줌
-- 목록 조회·검색 불가. 새 링크 id는 앱에서 추측 불가능한 해시(r_ + 32자리)로 만듦.
-- ============================================================================
CREATE OR REPLACE FUNCTION public.get_shared_report(p_id TEXT)
RETURNS JSONB
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT payload FROM public.fairy_shared_reports_v1 WHERE id = p_id LIMIT 1;
$$;

REVOKE ALL ON FUNCTION public.get_shared_report(TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_shared_report(TEXT) TO anon, authenticated;

-- ============================================================================
-- 🗑️ 앱 내 회원 탈퇴(계정 및 모든 데이터 영구 삭제) RPC 함수
-- 앱스토어 심사 필수 요건: 로그인한 본인(auth.uid())만 자신의 데이터 + auth.users 삭제 가능
-- ============================================================================
CREATE OR REPLACE FUNCTION public.delete_my_account()
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_uid UUID := auth.uid();
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  DELETE FROM public.fairy_shared_reports_v1 WHERE user_id = v_uid;
  DELETE FROM public.fairy_sessions_v1 WHERE user_id = v_uid;
  DELETE FROM public.fairy_questions_v1 WHERE user_id = v_uid;
  DELETE FROM public.fairy_practice_v1 WHERE user_id = v_uid;
  DELETE FROM public.fairy_notes_v1 WHERE user_id = v_uid;
  DELETE FROM public.fairy_lessons_v1 WHERE user_id = v_uid;
  DELETE FROM public.fairy_students_v1 WHERE user_id = v_uid;
  DELETE FROM public.fairy_teacher_profile_v1 WHERE user_id = v_uid;

  DELETE FROM auth.users WHERE id = v_uid;
END;
$$;

REVOKE ALL ON FUNCTION public.delete_my_account() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.delete_my_account() TO authenticated;
