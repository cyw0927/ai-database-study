-- Chapter 04. students 실습 상태 확인
-- 목적: 현재 연결, 테이블 구조와 데이터 상태를 조회합니다.
-- 이 파일은 데이터를 변경하지 않으므로 반복 실행할 수 있습니다.

SELECT current_database();
SELECT current_user;
SELECT current_schema();
SHOW search_path;

SELECT to_regclass('public.students') AS students_table;

DO $$
BEGIN
    IF current_database() <> 'ai_database_book' THEN
        RAISE EXCEPTION
            '상태 확인 중단: 현재 데이터베이스는 %입니다. ai_database_book 연결을 선택하세요.',
            current_database();
    END IF;

    IF to_regclass('public.students') IS NULL THEN
        RAISE EXCEPTION
            '상태 확인 중단: public.students가 없습니다. 01_create_students.sql을 실행하세요.';
    END IF;
END
$$;

-- 열 구조
SELECT column_name,
       data_type,
       is_nullable,
       column_default
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'students'
ORDER BY ordinal_position;

-- 전체 상태
SELECT COUNT(*) AS student_count,
       COUNT(*) FILTER (WHERE major IS NULL) AS major_null_count,
       COUNT(*) FILTER (WHERE grade IS NULL) AS grade_null_count
FROM public.students;

-- 주요 실습 상태
SELECT
    (SELECT grade
     FROM public.students
     WHERE email = 'junho@example.com') AS junho_grade,
    EXISTS (
        SELECT 1
        FROM public.students
        WHERE email = 'seoyeon@example.com'
    ) AS seoyeon_exists;

-- 현재 데이터
SELECT id, name, email, major, grade, created_at
FROM public.students
ORDER BY id ASC;
