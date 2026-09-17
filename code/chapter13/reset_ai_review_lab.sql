-- Chapter 13. ai_review_lab 초기화
-- 주의: ai_review_lab의 알려진 Chapter 13 객체만 삭제합니다.
-- 기존 프로젝트·앞 장 스키마·Role은 변경하지 않습니다.
-- 예상하지 못한 객체가 남아 있으면 DROP SCHEMA가 실패하고 전체 초기화를 ROLLBACK합니다.

SELECT current_user;
SELECT current_database();
SELECT current_schema();
SHOW search_path;
SHOW transaction_read_only;

DO $$
BEGIN
    IF current_database() <> 'ai_database_book' THEN
        RAISE EXCEPTION
            '초기화 중단: 현재 데이터베이스는 %입니다. ai_database_book에서만 실행하세요.',
            current_database();
    END IF;

    IF current_setting('transaction_read_only') = 'on' THEN
        RAISE EXCEPTION
            '초기화 중단: 현재 연결은 읽기 전용입니다.';
    END IF;
END
$$;

BEGIN;

-- 자식 → 부모 순서로 Chapter 13이 알고 있는 객체만 삭제합니다.
DROP TABLE IF EXISTS ai_review_lab.payments;
DROP TABLE IF EXISTS ai_review_lab.enrollments;
DROP TABLE IF EXISTS ai_review_lab.courses;
DROP TABLE IF EXISTS ai_review_lab.instructors;
DROP TABLE IF EXISTS ai_review_lab.students;
DROP TABLE IF EXISTS ai_review_lab.bad_enrollments;

-- CASCADE를 사용하지 않습니다.
-- keep_me 같은 예상 밖 객체가 있으면 여기서 실패하여 위 DROP도 모두 취소됩니다.
DROP SCHEMA IF EXISTS ai_review_lab;

COMMIT;

DO $$
BEGIN
    IF to_regnamespace('ai_review_lab') IS NOT NULL THEN
        RAISE EXCEPTION
            '초기화 검증 실패: ai_review_lab 스키마가 남아 있습니다.';
    END IF;

    RAISE NOTICE 'Chapter 13 ai_review_lab reset passed';
END
$$;

-- 삭제 후 실행 순서:
-- 1. 01_ai_review_lab_schema.sql
-- 2. 02_bad_design_seed.sql
-- 3. 03_good_design_schema.sql
-- 4. 04_good_design_seed.sql
-- 5. 05_metadata_validation.sql
-- 6. 06_business_validation.sql
-- 7. 07_negative_tests.sql
-- 8. 08_ai_review_lab_validation.sql
