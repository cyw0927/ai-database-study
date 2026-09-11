-- Chapter 04. students 실습 초기화
-- 주의: 이 파일은 public.students 테이블과 저장된 모든 데이터를 삭제합니다.
-- 실습을 처음부터 다시 시작해야 할 때만 사용합니다.
-- 현재 스키마가 public인지와 관계없이 스키마를 명시한 public.students만 삭제합니다.

SELECT current_database();
SELECT current_user;
SELECT current_schema();
SHOW search_path;
SELECT to_regclass('public.students') AS table_before_reset;

DO $$
BEGIN
    IF current_database() <> 'ai_database_book' THEN
        RAISE EXCEPTION
            '초기화 중단: 현재 데이터베이스는 %입니다. ai_database_book에 연결하세요.',
            current_database();
    END IF;

    IF to_regnamespace('public') IS NULL THEN
        RAISE EXCEPTION
            '초기화 중단: public 스키마가 존재하지 않습니다.';
    END IF;

    IF current_setting('transaction_read_only')::boolean THEN
        RAISE EXCEPTION
            '초기화 중단: 현재 연결이 읽기 전용입니다.';
    END IF;

    DROP TABLE IF EXISTS public.students;
END
$$;

SELECT to_regclass('public.students') AS table_after_reset;

-- 다시 시작하는 순서
-- 1. 01_create_students.sql
-- 2. 02_insert_students.sql
-- 3. verify_students.sql
