-- ============================================================================
-- 2026-11-27 보안 수정: 공유 리포트 전체 조회 차단
-- 사용법: Supabase Dashboard -> SQL Editor -> New Query 에 이 파일 전체를 붙여 넣고 [Run]
-- 여러 번 실행해도 안전함. (supabase_schema.sql에도 같은 내용이 반영되어 있음)
-- ============================================================================

-- 1) 학부모 열람용 RPC 먼저 만들기 (링크 id와 정확히 같은 리포트 1건만 반환)
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

-- 2) "누구나 전부 읽기" 정책 삭제 + 비로그인 직접 조회 권한 회수
DROP POLICY IF EXISTS "Public read shared reports" ON public.fairy_shared_reports_v1;
DROP POLICY IF EXISTS "Allow public access to fairy_shared_reports_v1" ON public.fairy_shared_reports_v1;
REVOKE ALL ON TABLE public.fairy_shared_reports_v1 FROM anon;

-- 3) 선생님 본인 읽기/쓰기 정책은 그대로 유지 (없으면 다시 만듦)
DROP POLICY IF EXISTS "Owner write shared reports" ON public.fairy_shared_reports_v1;
CREATE POLICY "Owner write shared reports"
  ON public.fairy_shared_reports_v1 FOR ALL TO authenticated
  USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- PostgREST가 새 함수를 바로 인식하도록 스키마 캐시 새로고침
NOTIFY pgrst, 'reload schema';
