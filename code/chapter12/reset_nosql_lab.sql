-- Chapter 12. nosql_lab 초기화
-- 주의: nosql_lab 스키마와 실습 데이터만 삭제합니다.
-- course_project, transaction_lab, performance_lab, security_lab, public 객체는 변경하지 않습니다.
-- CASCADE를 사용하지 않으므로 예상하지 못한 객체가 있으면 전체 초기화를 중단하고 ROLLBACK합니다.

SELECT current_user;
SELECT current_database();
SELECT current_schema();
SHOW search_path;

BEGIN;

DO $$
BEGIN
    IF current_database() <> 'ai_database_book' THEN
        RAISE EXCEPTION
            '초기화 중단: 현재 데이터베이스는 %입니다. ai_database_book에서만 실행하세요.',
            current_database();
    END IF;

    IF current_setting('transaction_read_only')::BOOLEAN THEN
        RAISE EXCEPTION
            '초기화 중단: 읽기 전용 연결에서는 nosql_lab을 삭제할 수 없습니다.';
    END IF;
END
$$;

DROP TABLE IF EXISTS nosql_lab.storage_choice_cases;
DROP TABLE IF EXISTS nosql_lab.key_value_cache_examples;
DROP TABLE IF EXISTS nosql_lab.course_documents;
DROP SCHEMA IF EXISTS nosql_lab;

COMMIT;

DO $$
BEGIN
    IF to_regnamespace('nosql_lab') IS NOT NULL THEN
        RAISE EXCEPTION
            'Chapter 12 초기화 검증 실패: nosql_lab 스키마가 남아 있습니다.';
    END IF;

    RAISE NOTICE 'Chapter 12 nosql lab reset passed';
END
$$;

-- 삭제 후 실행 순서:
-- 1. 01_nosql_lab_schema.sql
-- 2. 02_nosql_lab_seed.sql
-- 3. 03_document_jsonb_queries.sql
-- 4. 04_key_value_cache_queries.sql
-- 5. 05_storage_choice_review.sql
-- 6. 06_jsonb_index_candidates.sql
-- 7. 07_nosql_lab_validation.sql
