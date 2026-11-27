-- ============================================================================
-- 2026-11-27 학부모 연결 1단계: 학생별 고정 학부모 링크 테이블 & 전용 조회 RPC
-- 사용법: Supabase Dashboard -> SQL Editor -> New Query 에 전체 복사 후 [Run]
-- 여러 번 실행해도 안전함. (supabase_schema.sql에도 같은 내용이 반영되어 있음)
--
-- 보안 원칙 (0단계와 동일):
--   1) fairy_parent_links_v1 테이블은 anon 직접 조회/쓰기 완전 차단
--   2) 로그인한 선생님 본인(auth.uid() = user_id)만 자신의 링크 관리 가능
--   3) 비로그인 학부모는 추측 불가 토큰 1개로 허용된 항목만 받는
--      get_parent_student_status(p_token) RPC로만 실시간 조회
--   4) 선생님 내부 메모·연락처·약력·다른 학생 정보는 절대 반환하지 않음
-- ============================================================================

-- 1) 학생별 고정 학부모 링크 테이블 (3단계 학부모 계정 연결용 parent_user_id 미리 확보)
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

-- 2) 권한 및 RLS: 선생님 본인만 관리, anon 직접 접근 완전 차단
REVOKE ALL ON TABLE public.fairy_parent_links_v1 FROM anon;
GRANT ALL ON TABLE public.fairy_parent_links_v1 TO authenticated;

ALTER TABLE public.fairy_parent_links_v1 ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Owner access to fairy_parent_links_v1" ON public.fairy_parent_links_v1;
CREATE POLICY "Owner access to fairy_parent_links_v1"
  ON public.fairy_parent_links_v1 FOR ALL TO authenticated
  USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- 3) 학부모 실시간 현황 조회 RPC (화이트리스트 필드만 반환)
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
  -- 빈 토큰이나 너무 짧은 입력은 즉시 차단
  IF p_token IS NULL OR length(trim(p_token)) < 16 THEN
    RETURN NULL;
  END IF;

  -- 활성 상태(is_active = true)이고 토큰이 정확히 일치하는 1건만 조회
  SELECT *
    INTO v_link
    FROM public.fairy_parent_links_v1
   WHERE token = trim(p_token)
     AND is_active = true
   LIMIT 1;

  IF NOT FOUND THEN
    RETURN NULL;
  END IF;

  -- 로컬 ID / 클라우드 프리픽스 ID 모두 안전하게 매칭 (반드시 해당 선생님 user_id 범위로 제한)
  v_prefix := left(v_link.user_id::text, 8) || '_';
  IF v_link.student_id LIKE (v_prefix || '%') THEN
    v_local_sid := substr(v_link.student_id, length(v_prefix) + 1);
    v_cloud_sid := v_link.student_id;
  ELSE
    v_local_sid := v_link.student_id;
    v_cloud_sid := v_prefix || v_link.student_id;
  END IF;

  -- 1) 학생 정보 (허용된 필드만 화이트리스트 선택: 전화번호·내부메모 제외)
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

  -- 2) 선생님 이름 및 입금 계좌만 조회 (연락처·약력·사진 제외, 예전 예시 계좌 차단)
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

  -- 3) 다음 예정 수업 1건
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

  -- 4) 미해결 보강 대기 건수 (결석 후 보강 미완료)
  SELECT count(*)::integer
    INTO v_pending_makeup
    FROM public.fairy_lessons_v1
   WHERE user_id = v_link.user_id
     AND "studentId" IN (v_local_sid, v_cloud_sid)
     AND status = '결석'
     AND coalesce("makeupResolved", false) = false;

  -- 5) 최근 출결 내역 최대 8건 (예정 제외, 5대 출결 상태 포함)
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

  -- 6) 최근 레슨 노트 요약 최대 5건
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

-- 4) 회원 탈퇴 RPC에 학부모 링크 삭제도 포함
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

-- PostgREST 스키마 캐시 새로고침
NOTIFY pgrst, 'reload schema';
