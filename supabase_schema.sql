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

-- 9. 학생별 고정 학부모 링크 (fairy_parent_links_v1)
-- 1단계: 토큰 기반 비로그인 실시간 조회 / 3단계: parent_user_id로 학부모 계정 연결 확장
CREATE TABLE IF NOT EXISTS public.fairy_parent_links_v1 (
  token TEXT PRIMARY KEY,
  user_id UUID NOT NULL,
  student_id TEXT NOT NULL,
  is_active BOOLEAN NOT NULL DEFAULT true,
  parent_user_id UUID,
  label TEXT,
  revoked_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
ALTER TABLE public.fairy_parent_links_v1 ADD COLUMN IF NOT EXISTS parent_user_id UUID;
ALTER TABLE public.fairy_parent_links_v1 ADD COLUMN IF NOT EXISTS label TEXT;
ALTER TABLE public.fairy_parent_links_v1 ADD COLUMN IF NOT EXISTS revoked_at TIMESTAMPTZ;
ALTER TABLE public.fairy_parent_links_v1 ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ NOT NULL DEFAULT now();
ALTER TABLE public.fairy_parent_links_v1 ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT now();

CREATE INDEX IF NOT EXISTS idx_fairy_parent_links_user_student
  ON public.fairy_parent_links_v1 (user_id, student_id);
CREATE INDEX IF NOT EXISTS idx_fairy_parent_links_parent_uid
  ON public.fairy_parent_links_v1 (parent_user_id)
  WHERE parent_user_id IS NOT NULL;

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

-- 비로그인(anon)은 공유 리포트·학부모 링크 테이블을 직접 읽을 수 없음. 열람은 전용 RPC로만.
REVOKE ALL ON TABLE public.fairy_shared_reports_v1 FROM anon;
GRANT ALL ON TABLE public.fairy_shared_reports_v1 TO authenticated;

REVOKE ALL ON TABLE public.fairy_parent_links_v1 FROM anon;
GRANT ALL ON TABLE public.fairy_parent_links_v1 TO authenticated;

ALTER TABLE public.fairy_teacher_profile_v1 ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.fairy_students_v1 ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.fairy_lessons_v1 ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.fairy_notes_v1 ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.fairy_practice_v1 ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.fairy_questions_v1 ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.fairy_sessions_v1 ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.fairy_shared_reports_v1 ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.fairy_parent_links_v1 ENABLE ROW LEVEL SECURITY;

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

-- 9번 학생별 고정 학부모 링크: 선생님 본인만 관리. 비로그인 열람은 아래 get_parent_student_status(p_token) RPC로만.
DROP POLICY IF EXISTS "Owner access to fairy_parent_links_v1" ON public.fairy_parent_links_v1;
CREATE POLICY "Owner access to fairy_parent_links_v1"
  ON public.fairy_parent_links_v1 FOR ALL TO authenticated
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
-- 🔗 학생별 고정 학부모 링크 실시간 현황 RPC: 활성 토큰 1건에 해당하는 학생 1명의
-- 허용된(화이트리스트) 항목만 반환. 선생님 내부 메모·연락처·약력·타 학생 정보는 제외.
-- ============================================================================
CREATE OR REPLACE FUNCTION public.get_parent_student_status(p_token TEXT)
RETURNS JSONB
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_link public.fairy_parent_links_v1%ROWTYPE;
  v_prefix TEXT;
  v_local_sid TEXT;
  v_cloud_sid TEXT;
  v_student RECORD;
  v_teacher_name TEXT := '';
  v_bank_name TEXT := '';
  v_account_number TEXT := '';
  v_account_holder TEXT := '';
  v_next_lesson JSONB := NULL;
  v_recent_lessons JSONB := '[]'::jsonb;
  v_recent_notes JSONB := '[]'::jsonb;
  v_pending_makeup INTEGER := 0;
  v_total_pass INTEGER := 8;
  v_used_pass INTEGER := 0;
  v_remain_pass INTEGER := 0;
BEGIN
  IF p_token IS NULL OR length(trim(p_token)) < 16 THEN
    RETURN NULL;
  END IF;

  SELECT *
    INTO v_link
    FROM public.fairy_parent_links_v1
   WHERE token = trim(p_token)
     AND is_active = true
   LIMIT 1;

  IF NOT FOUND THEN
    RETURN NULL;
  END IF;

  v_prefix := left(v_link.user_id::text, 8) || '_';
  IF v_link.student_id LIKE (v_prefix || '%') THEN
    v_local_sid := substr(v_link.student_id, length(v_prefix) + 1);
    v_cloud_sid := v_link.student_id;
  ELSE
    v_local_sid := v_link.student_id;
    v_cloud_sid := v_prefix || v_link.student_id;
  END IF;

  SELECT
    name,
    subject,
    type,
    grade,
    "totalPass",
    "usedPass",
    fee,
    schedule,
    "currentPiece"
    INTO v_student
    FROM public.fairy_students_v1
   WHERE user_id = v_link.user_id
     AND id IN (v_local_sid, v_cloud_sid)
   LIMIT 1;

  IF NOT FOUND THEN
    RETURN NULL;
  END IF;

  v_total_pass := greatest(1, coalesce(v_student."totalPass", 8));
  v_used_pass := greatest(0, coalesce(v_student."usedPass", 0));
  v_remain_pass := greatest(0, v_total_pass - v_used_pass);

  SELECT
    coalesce(name, ''),
    CASE
      WHEN nullif(trim(coalesce("accountNumber", '')), '') IS NULL
        OR trim("accountNumber") = '3333-01-2345678' THEN ''
      ELSE coalesce("bankName", '')
    END,
    CASE
      WHEN nullif(trim(coalesce("accountNumber", '')), '') IS NULL
        OR trim("accountNumber") = '3333-01-2345678' THEN ''
      ELSE trim("accountNumber")
    END,
    CASE
      WHEN nullif(trim(coalesce("accountNumber", '')), '') IS NULL
        OR trim("accountNumber") = '3333-01-2345678' THEN ''
      ELSE coalesce(nullif(trim(coalesce("accountHolder", '')), ''), coalesce(name, ''))
    END
    INTO v_teacher_name, v_bank_name, v_account_number, v_account_holder
    FROM public.fairy_teacher_profile_v1
   WHERE user_id = v_link.user_id
   LIMIT 1;

  SELECT jsonb_build_object(
           'date', coalesce(date, ''),
           'time', coalesce(time, ''),
           'type', coalesce(type, '정규')
         )
    INTO v_next_lesson
    FROM public.fairy_lessons_v1
   WHERE user_id = v_link.user_id
     AND "studentId" IN (v_local_sid, v_cloud_sid)
     AND coalesce(status, '예정') = '예정'
   ORDER BY date ASC, time ASC
   LIMIT 1;

  SELECT count(*)::integer
    INTO v_pending_makeup
    FROM public.fairy_lessons_v1
   WHERE user_id = v_link.user_id
     AND "studentId" IN (v_local_sid, v_cloud_sid)
     AND status = '결석'
     AND coalesce("makeupResolved", false) = false;

  SELECT coalesce(jsonb_agg(item), '[]'::jsonb)
    INTO v_recent_lessons
    FROM (
      SELECT jsonb_build_object(
               'date', coalesce(date, ''),
               'time', coalesce(time, ''),
               'type', coalesce(type, '정규'),
               'status', coalesce(status, '출석'),
               'sessionNum', "sessionNum",
               'makeupResolved', coalesce("makeupResolved", false)
             ) AS item
        FROM public.fairy_lessons_v1
       WHERE user_id = v_link.user_id
         AND "studentId" IN (v_local_sid, v_cloud_sid)
         AND coalesce(status, '') NOT IN ('', '예정')
       ORDER BY date DESC, time DESC, updated_at DESC
       LIMIT 8
    ) sub;

  SELECT coalesce(jsonb_agg(item), '[]'::jsonb)
    INTO v_recent_notes
    FROM (
      SELECT jsonb_build_object(
               'date', coalesce(date, ''),
               'sessionNum', "sessionNum",
               'piece', coalesce(piece, ''),
               'technique', coalesce(technique, ''),
               'badge', coalesce(badge, ''),
               'feedback', coalesce(feedback, ''),
               'homework', coalesce(homework, ''),
               'parentMsg', coalesce("parentMsg", ''),
               'youtubeUrl', coalesce("youtubeUrl", '')
             ) AS item
        FROM public.fairy_notes_v1
       WHERE user_id = v_link.user_id
         AND "studentId" IN (v_local_sid, v_cloud_sid)
       ORDER BY date DESC, "createdAt" DESC, updated_at DESC
       LIMIT 5
    ) sub;

  RETURN jsonb_build_object(
    'updatedAt', now(),
    'student', jsonb_build_object(
      'name', coalesce(v_student.name, '수강생'),
      'subject', coalesce(v_student.subject, '음악'),
      'type', coalesce(v_student.type, 'child'),
      'grade', coalesce(v_student.grade, ''),
      'totalPass', v_total_pass,
      'usedPass', v_used_pass,
      'remainPass', v_remain_pass,
      'fee', coalesce(v_student.fee, 0),
      'schedule', coalesce(v_student.schedule, ''),
      'currentPiece', coalesce(v_student."currentPiece", '')
    ),
    'teacher', jsonb_build_object(
      'name', coalesce(v_teacher_name, ''),
      'bankName', coalesce(v_bank_name, ''),
      'accountNumber', coalesce(v_account_number, ''),
      'accountHolder', coalesce(v_account_holder, '')
    ),
    'nextLesson', v_next_lesson,
    'pendingMakeupCount', coalesce(v_pending_makeup, 0),
    'recentLessons', v_recent_lessons,
    'recentNotes', v_recent_notes
  );
END;
$$;

REVOKE ALL ON FUNCTION public.get_parent_student_status(TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_parent_student_status(TEXT) TO anon, authenticated;

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

  DELETE FROM public.fairy_parent_links_v1 WHERE user_id = v_uid;
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
