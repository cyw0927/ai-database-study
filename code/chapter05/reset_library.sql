-- Chapter 05. 도서 대여 시스템 초기화
-- 주의: public.members, public.books, public.loans와 모든 데이터를 삭제합니다.
-- 실습을 처음부터 다시 시작해야 할 때만 사용합니다.
-- current_schema 값과 관계없이 스키마를 명시한 public 테이블만 삭제합니다.

SELECT current_database();
SELECT current_user;
SELECT current_schema();
SHOW search_path;

SELECT
    to_regclass('public.members') AS members_before_reset,
    to_regclass('public.books') AS books_before_reset,
    to_regclass('public.loans') AS loans_before_reset;

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

    -- 외래키를 가진 자식 테이블부터 삭제합니다.
    DROP TABLE IF EXISTS public.loans;
    DROP TABLE IF EXISTS public.books;
    DROP TABLE IF EXISTS public.members;
END
$$;

SELECT
    to_regclass('public.members') AS members_after_reset,
    to_regclass('public.books') AS books_after_reset,
    to_regclass('public.loans') AS loans_after_reset;

-- 다시 시작하는 순서
-- 1. 01_library_schema.sql
-- 2. 02_library_seed.sql
-- 3. 03_library_validation.sql
