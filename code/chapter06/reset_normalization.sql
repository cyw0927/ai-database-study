-- Chapter 06. 정규화 실습 초기화
-- 주의: Chapter 06 실습 테이블·제약조건·인덱스와 모든 데이터를 삭제합니다.
-- 처음부터 다시 시작해야 할 때만 사용합니다.
-- current_schema 값과 관계없이 스키마를 명시한 public 객체만 삭제합니다.

SELECT current_database();
SELECT current_user;
SELECT current_schema();
SHOW search_path;

SELECT
    to_regclass('public.library_records_raw') AS raw_before_reset,
    to_regclass('public.members_nf') AS members_before_reset,
    to_regclass('public.books_nf') AS books_before_reset,
    to_regclass('public.loans_nf') AS loans_before_reset;

DO $$
BEGIN
    IF current_database() <> 'ai_database_book' THEN
        RAISE EXCEPTION
            '초기화 중단: 현재 데이터베이스는 %입니다. ai_database_book에 연결하세요.',
            current_database();
    END IF;

    IF to_regnamespace('public') IS NULL THEN
        RAISE EXCEPTION '초기화 중단: public 스키마가 존재하지 않습니다.';
    END IF;

    IF current_setting('transaction_read_only')::boolean THEN
        RAISE EXCEPTION '초기화 중단: 현재 연결이 읽기 전용입니다.';
    END IF;

    -- 부분 인덱스와 제약조건은 테이블 삭제 시 함께 제거됩니다.
    -- 외래키를 가진 자식 테이블부터 삭제합니다.
    DROP TABLE IF EXISTS public.loans_nf;
    DROP TABLE IF EXISTS public.books_nf;
    DROP TABLE IF EXISTS public.members_nf;
    DROP TABLE IF EXISTS public.library_records_raw;
END
$$;

SELECT
    to_regclass('public.library_records_raw') AS raw_after_reset,
    to_regclass('public.members_nf') AS members_after_reset,
    to_regclass('public.books_nf') AS books_after_reset,
    to_regclass('public.loans_nf') AS loans_after_reset;

-- 다시 시작하는 순서
-- 1. 01_normalization_schema.sql
-- 2. 02_normalization_seed.sql
-- 3. 03_normalization_compare.sql
-- 4. 04_add_integrity_rules.sql
-- 5. 05_integrity_tests.sql에서 필요한 테스트만 한 번에 하나씩 실행
