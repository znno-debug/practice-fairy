-- 2026-11-27 옛 ID 중복 줄 미리보기 (읽기 전용, 아무것도 바꾸지 않음)
-- pairs = 옛 ID(s1)와 새 ID(<uid8>_s1)가 둘 다 있는 쌍, safe = 새 ID 줄이 같거나 더 최근인 쌍(지워도 앱 화면이 바뀌지 않음)
SELECT * FROM (
  SELECT 'students' AS tbl, left(o.user_id::text, 8) AS acct,
         count(*) FILTER (WHERE EXISTS (SELECT 1 FROM public.fairy_students_v1 n WHERE n.user_id = o.user_id AND n.id = left(o.user_id::text, 8) || '_' || o.id)) AS pairs,
         count(*) FILTER (WHERE EXISTS (SELECT 1 FROM public.fairy_students_v1 n WHERE n.user_id = o.user_id AND n.id = left(o.user_id::text, 8) || '_' || o.id AND coalesce(n.updated_at, '-infinity'::timestamptz) >= coalesce(o.updated_at, '-infinity'::timestamptz))) AS safe
    FROM public.fairy_students_v1 o GROUP BY 2
  UNION ALL
  SELECT 'lessons' AS tbl, left(o.user_id::text, 8) AS acct,
         count(*) FILTER (WHERE EXISTS (SELECT 1 FROM public.fairy_lessons_v1 n WHERE n.user_id = o.user_id AND n.id = left(o.user_id::text, 8) || '_' || o.id)) AS pairs,
         count(*) FILTER (WHERE EXISTS (SELECT 1 FROM public.fairy_lessons_v1 n WHERE n.user_id = o.user_id AND n.id = left(o.user_id::text, 8) || '_' || o.id AND coalesce(n.updated_at, '-infinity'::timestamptz) >= coalesce(o.updated_at, '-infinity'::timestamptz))) AS safe
    FROM public.fairy_lessons_v1 o GROUP BY 2
  UNION ALL
  SELECT 'notes' AS tbl, left(o.user_id::text, 8) AS acct,
         count(*) FILTER (WHERE EXISTS (SELECT 1 FROM public.fairy_notes_v1 n WHERE n.user_id = o.user_id AND n.id = left(o.user_id::text, 8) || '_' || o.id)) AS pairs,
         count(*) FILTER (WHERE EXISTS (SELECT 1 FROM public.fairy_notes_v1 n WHERE n.user_id = o.user_id AND n.id = left(o.user_id::text, 8) || '_' || o.id AND coalesce(n.updated_at, '-infinity'::timestamptz) >= coalesce(o.updated_at, '-infinity'::timestamptz))) AS safe
    FROM public.fairy_notes_v1 o GROUP BY 2
  UNION ALL
  SELECT 'questions' AS tbl, left(o.user_id::text, 8) AS acct,
         count(*) FILTER (WHERE EXISTS (SELECT 1 FROM public.fairy_questions_v1 n WHERE n.user_id = o.user_id AND n.id = left(o.user_id::text, 8) || '_' || o.id)) AS pairs,
         count(*) FILTER (WHERE EXISTS (SELECT 1 FROM public.fairy_questions_v1 n WHERE n.user_id = o.user_id AND n.id = left(o.user_id::text, 8) || '_' || o.id AND coalesce(n.updated_at, '-infinity'::timestamptz) >= coalesce(o.updated_at, '-infinity'::timestamptz))) AS safe
    FROM public.fairy_questions_v1 o GROUP BY 2
  UNION ALL
  SELECT 'practice' AS tbl, left(o.user_id::text, 8) AS acct,
         count(*) FILTER (WHERE EXISTS (SELECT 1 FROM public.fairy_practice_v1 n WHERE n.user_id = o.user_id AND n."studentId" = left(o.user_id::text, 8) || '_' || o."studentId")) AS pairs,
         count(*) FILTER (WHERE EXISTS (SELECT 1 FROM public.fairy_practice_v1 n WHERE n.user_id = o.user_id AND n."studentId" = left(o.user_id::text, 8) || '_' || o."studentId" AND coalesce(n.updated_at, '-infinity'::timestamptz) >= coalesce(o.updated_at, '-infinity'::timestamptz))) AS safe
    FROM public.fairy_practice_v1 o GROUP BY 2
  UNION ALL
  SELECT 'sessions' AS tbl, left(o.user_id::text, 8) AS acct,
         count(*) FILTER (WHERE EXISTS (SELECT 1 FROM public.fairy_sessions_v1 n WHERE n.user_id = o.user_id AND n."studentId" = left(o.user_id::text, 8) || '_' || o."studentId")) AS pairs,
         count(*) FILTER (WHERE EXISTS (SELECT 1 FROM public.fairy_sessions_v1 n WHERE n.user_id = o.user_id AND n."studentId" = left(o.user_id::text, 8) || '_' || o."studentId" AND coalesce(n.updated_at, '-infinity'::timestamptz) >= coalesce(o.updated_at, '-infinity'::timestamptz))) AS safe
    FROM public.fairy_sessions_v1 o GROUP BY 2
) x WHERE pairs > 0 ORDER BY acct, tbl;
