-- Chapter 11. security_lab 초기화
-- 주의: security_lab 스키마와 실습 데이터만 삭제합니다.
-- course_project, transaction_lab, performance_lab, public 객체는 변경하지 않습니다.
-- 클러스터 전역 Role은 자동 삭제하지 않습니다.
-- 예상하지 못한 security_lab 객체가 있으면 DROP SCHEMA가 실패하고 전체 삭제가 ROLLBACK됩니다.

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

    IF current_setting('transaction_read_only')::boolean THEN
        RAISE EXCEPTION '초기화 중단: 읽기 전용 연결입니다.';
    END IF;
END
$$;

DROP TABLE IF EXISTS security_lab.enrollments;
DROP TABLE IF EXISTS security_lab.courses;
DROP TABLE IF EXISTS security_lab.students;

-- CASCADE를 사용하지 않습니다.
-- 예상하지 못한 객체가 남아 있으면 이 문장이 실패해 위 DROP도 함께 취소됩니다.
DROP SCHEMA IF EXISTS security_lab;

COMMIT;

DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_namespace WHERE nspname = 'security_lab') THEN
        RAISE EXCEPTION '초기화 검증 실패: security_lab 스키마가 남아 있습니다.';
    END IF;

    IF to_regclass('course_project.enrollments') IS NULL
       OR (SELECT COUNT(*) FROM course_project.enrollments) <> 5 THEN
        RAISE EXCEPTION '초기화 검증 실패: 보호 대상 course_project 상태가 달라졌습니다.';
    END IF;

    RAISE NOTICE 'Chapter 11 security lab reset passed';
END
$$;

-- 삭제 후 실행 순서:
-- 1. 01_security_lab_schema.sql
-- 2. 02_security_lab_seed.sql
-- 3. 03_role_permission_plan.sql에서 필요한 문장만 검토·선택 실행
-- 4. 04_permission_checks.sql
-- 5. 필요하면 05_permission_behavior_tests.sql
--
-- Role 정리는 자동 실행하지 않습니다.
-- 다른 DB·객체·멤버십과 소유권을 조사한 뒤
-- 03_role_permission_plan.sql의 정리 계획을 검토합니다.
