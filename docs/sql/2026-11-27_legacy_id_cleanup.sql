-- ============================================================================
-- 2026-11-27 클라우드 옛 ID 중복 줄 정리 (계정 접두어 8dc4777d 한 곳만)
-- 배경: 같은 항목이 옛 ID(s1)와 새 ID(<uid8>_s1)로 두 번 저장돼 있었음. 앱(v37)은 불러올 때
--       최신 줄만 쓰지만, 학부모 링크 RPC는 옛 줄을 고를 수 있어 정리한다.
-- 지우는 조건: 같은 계정에 새 ID 쌍둥이 줄이 있고, 그 줄이 같거나 더 최근일 때만.
-- 지우기 전 fairy_backup 스키마(외부 API에 노출되지 않음)에 그대로 복사해 둔다.
-- ============================================================================
BEGIN;

CREATE SCHEMA IF NOT EXISTS fairy_backup;
REVOKE ALL ON SCHEMA fairy_backup FROM PUBLIC, anon, authenticated;

-- students
CREATE TABLE IF NOT EXISTS fairy_backup.students_legacy_20261127 AS SELECT * FROM public.fairy_students_v1 WHERE false;
INSERT INTO fairy_backup.students_legacy_20261127
SELECT o.* FROM public.fairy_students_v1 o
 WHERE o.user_id::text LIKE '8dc4777d%'
   AND EXISTS (SELECT 1 FROM public.fairy_students_v1 n WHERE n.user_id = o.user_id AND n.id = left(o.user_id::text, 8) || '_' || o.id AND coalesce(n.updated_at, '-infinity'::timestamptz) >= coalesce(o.updated_at, '-infinity'::timestamptz));
DELETE FROM public.fairy_students_v1 o
 WHERE o.user_id::text LIKE '8dc4777d%'
   AND EXISTS (SELECT 1 FROM public.fairy_students_v1 n WHERE n.user_id = o.user_id AND n.id = left(o.user_id::text, 8) || '_' || o.id AND coalesce(n.updated_at, '-infinity'::timestamptz) >= coalesce(o.updated_at, '-infinity'::timestamptz));

-- lessons
CREATE TABLE IF NOT EXISTS fairy_backup.lessons_legacy_20261127 AS SELECT * FROM public.fairy_lessons_v1 WHERE false;
INSERT INTO fairy_backup.lessons_legacy_20261127
SELECT o.* FROM public.fairy_lessons_v1 o
 WHERE o.user_id::text LIKE '8dc4777d%'
   AND EXISTS (SELECT 1 FROM public.fairy_lessons_v1 n WHERE n.user_id = o.user_id AND n.id = left(o.user_id::text, 8) || '_' || o.id AND coalesce(n.updated_at, '-infinity'::timestamptz) >= coalesce(o.updated_at, '-infinity'::timestamptz));
DELETE FROM public.fairy_lessons_v1 o
 WHERE o.user_id::text LIKE '8dc4777d%'
   AND EXISTS (SELECT 1 FROM public.fairy_lessons_v1 n WHERE n.user_id = o.user_id AND n.id = left(o.user_id::text, 8) || '_' || o.id AND coalesce(n.updated_at, '-infinity'::timestamptz) >= coalesce(o.updated_at, '-infinity'::timestamptz));

-- notes
CREATE TABLE IF NOT EXISTS fairy_backup.notes_legacy_20261127 AS SELECT * FROM public.fairy_notes_v1 WHERE false;
INSERT INTO fairy_backup.notes_legacy_20261127
SELECT o.* FROM public.fairy_notes_v1 o
 WHERE o.user_id::text LIKE '8dc4777d%'
   AND EXISTS (SELECT 1 FROM public.fairy_notes_v1 n WHERE n.user_id = o.user_id AND n.id = left(o.user_id::text, 8) || '_' || o.id AND coalesce(n.updated_at, '-infinity'::timestamptz) >= coalesce(o.updated_at, '-infinity'::timestamptz));
DELETE FROM public.fairy_notes_v1 o
 WHERE o.user_id::text LIKE '8dc4777d%'
   AND EXISTS (SELECT 1 FROM public.fairy_notes_v1 n WHERE n.user_id = o.user_id AND n.id = left(o.user_id::text, 8) || '_' || o.id AND coalesce(n.updated_at, '-infinity'::timestamptz) >= coalesce(o.updated_at, '-infinity'::timestamptz));

-- questions
CREATE TABLE IF NOT EXISTS fairy_backup.questions_legacy_20261127 AS SELECT * FROM public.fairy_questions_v1 WHERE false;
INSERT INTO fairy_backup.questions_legacy_20261127
SELECT o.* FROM public.fairy_questions_v1 o
 WHERE o.user_id::text LIKE '8dc4777d%'
   AND EXISTS (SELECT 1 FROM public.fairy_questions_v1 n WHERE n.user_id = o.user_id AND n.id = left(o.user_id::text, 8) || '_' || o.id AND coalesce(n.updated_at, '-infinity'::timestamptz) >= coalesce(o.updated_at, '-infinity'::timestamptz));
DELETE FROM public.fairy_questions_v1 o
 WHERE o.user_id::text LIKE '8dc4777d%'
   AND EXISTS (SELECT 1 FROM public.fairy_questions_v1 n WHERE n.user_id = o.user_id AND n.id = left(o.user_id::text, 8) || '_' || o.id AND coalesce(n.updated_at, '-infinity'::timestamptz) >= coalesce(o.updated_at, '-infinity'::timestamptz));

-- practice
CREATE TABLE IF NOT EXISTS fairy_backup.practice_legacy_20261127 AS SELECT * FROM public.fairy_practice_v1 WHERE false;
INSERT INTO fairy_backup.practice_legacy_20261127
SELECT o.* FROM public.fairy_practice_v1 o
 WHERE o.user_id::text LIKE '8dc4777d%'
   AND EXISTS (SELECT 1 FROM public.fairy_practice_v1 n WHERE n.user_id = o.user_id AND n."studentId" = left(o.user_id::text, 8) || '_' || o."studentId" AND coalesce(n.updated_at, '-infinity'::timestamptz) >= coalesce(o.updated_at, '-infinity'::timestamptz));
DELETE FROM public.fairy_practice_v1 o
 WHERE o.user_id::text LIKE '8dc4777d%'
   AND EXISTS (SELECT 1 FROM public.fairy_practice_v1 n WHERE n.user_id = o.user_id AND n."studentId" = left(o.user_id::text, 8) || '_' || o."studentId" AND coalesce(n.updated_at, '-infinity'::timestamptz) >= coalesce(o.updated_at, '-infinity'::timestamptz));

-- sessions
CREATE TABLE IF NOT EXISTS fairy_backup.sessions_legacy_20261127 AS SELECT * FROM public.fairy_sessions_v1 WHERE false;
INSERT INTO fairy_backup.sessions_legacy_20261127
SELECT o.* FROM public.fairy_sessions_v1 o
 WHERE o.user_id::text LIKE '8dc4777d%'
   AND EXISTS (SELECT 1 FROM public.fairy_sessions_v1 n WHERE n.user_id = o.user_id AND n."studentId" = left(o.user_id::text, 8) || '_' || o."studentId" AND coalesce(n.updated_at, '-infinity'::timestamptz) >= coalesce(o.updated_at, '-infinity'::timestamptz));
DELETE FROM public.fairy_sessions_v1 o
 WHERE o.user_id::text LIKE '8dc4777d%'
   AND EXISTS (SELECT 1 FROM public.fairy_sessions_v1 n WHERE n.user_id = o.user_id AND n."studentId" = left(o.user_id::text, 8) || '_' || o."studentId" AND coalesce(n.updated_at, '-infinity'::timestamptz) >= coalesce(o.updated_at, '-infinity'::timestamptz));

COMMIT;

-- 결과: 백업(=삭제)된 줄 수
SELECT 'students' AS tbl, count(*) AS backed_up_and_deleted FROM fairy_backup.students_legacy_20261127
UNION ALL
SELECT 'lessons' AS tbl, count(*) AS backed_up_and_deleted FROM fairy_backup.lessons_legacy_20261127
UNION ALL
SELECT 'notes' AS tbl, count(*) AS backed_up_and_deleted FROM fairy_backup.notes_legacy_20261127
UNION ALL
SELECT 'questions' AS tbl, count(*) AS backed_up_and_deleted FROM fairy_backup.questions_legacy_20261127
UNION ALL
SELECT 'practice' AS tbl, count(*) AS backed_up_and_deleted FROM fairy_backup.practice_legacy_20261127
UNION ALL
SELECT 'sessions' AS tbl, count(*) AS backed_up_and_deleted FROM fairy_backup.sessions_legacy_20261127;

-- ============================================================================
-- 추가 정리 (같은 날): 선생님 프로필의 옛 'default' 행
-- 같은 계정에 id='default'(예전 예시 프로필)와 id=<user_id>(현재 행)가 함께 있어,
-- 앱이 불러올 때 아무 행이나 골라 옛 예시 프로필이 현재 행을 덮어쓴 일이 있었다.
-- 현재 행이 있는 경우에만 'default' 행을 백업 후 삭제한다.
-- ============================================================================
BEGIN;
CREATE SCHEMA IF NOT EXISTS fairy_backup;
REVOKE ALL ON SCHEMA fairy_backup FROM PUBLIC, anon, authenticated;
CREATE TABLE IF NOT EXISTS fairy_backup.teacher_profile_legacy_20261127 AS SELECT * FROM public.fairy_teacher_profile_v1 WHERE false;
INSERT INTO fairy_backup.teacher_profile_legacy_20261127
SELECT o.* FROM public.fairy_teacher_profile_v1 o
 WHERE o.user_id::text LIKE '8dc4777d%'
   AND o.id <> o.user_id::text
   AND EXISTS (SELECT 1 FROM public.fairy_teacher_profile_v1 n WHERE n.user_id = o.user_id AND n.id = o.user_id::text);
DELETE FROM public.fairy_teacher_profile_v1 o
 WHERE o.user_id::text LIKE '8dc4777d%'
   AND o.id <> o.user_id::text
   AND EXISTS (SELECT 1 FROM public.fairy_teacher_profile_v1 n WHERE n.user_id = o.user_id AND n.id = o.user_id::text);
COMMIT;

SELECT 'teacher_profile' AS tbl, count(*) AS backed_up_and_deleted FROM fairy_backup.teacher_profile_legacy_20261127
UNION ALL
SELECT 'teacher_profile_remaining', count(*) FROM public.fairy_teacher_profile_v1 WHERE user_id::text LIKE '8dc4777d%';
