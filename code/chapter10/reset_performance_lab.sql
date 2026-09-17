-- Chapter 10. performance_lab 초기화
-- performance_lab만 삭제하고 Chapter 07·08 course_project를 보존합니다.
-- 처음부터 다시 시작해야 할 때만 사용합니다.

SELECT current_database();
SELECT current_schema();
SHOW search_path;
SHOW server_version;

BEGIN;

DO $$
DECLARE
    v_status_counts text;
    v_total_amount numeric(20,0);
BEGIN
    IF current_database() <> 'ai_database_book' THEN
        RAISE EXCEPTION
            '초기화 중단: 현재 데이터베이스는 %입니다. ai_database_book에 연결하세요.',
            current_database();
    END IF;

    IF current_setting('transaction_read_only')::boolean THEN
        RAISE EXCEPTION
            '초기화 중단: 현재 연결이 읽기 전용입니다.';
    END IF;

    IF to_regclass('course_project.students') IS NULL
       OR to_regclass('course_project.instructors') IS NULL
       OR to_regclass('course_project.courses') IS NULL
       OR to_regclass('course_project.enrollments') IS NULL THEN
        RAISE EXCEPTION
            '초기화 중단: 보호할 course_project 기준 테이블이 없습니다.';
    END IF;

    IF (SELECT COUNT(*) FROM course_project.students) <> 3
       OR (SELECT COUNT(*) FROM course_project.instructors) <> 2
       OR (SELECT COUNT(*) FROM course_project.courses) <> 3
       OR (SELECT COUNT(*) FROM course_project.enrollments) <> 5 THEN
        RAISE EXCEPTION
            '초기화 중단: Chapter 07·08 기준 행 수 3/2/3/5와 다릅니다.';
    END IF;

    SELECT concat_ws('/',
        COUNT(*) FILTER (WHERE status = '신청'),
        COUNT(*) FILTER (WHERE status = '수강중'),
        COUNT(*) FILTER (WHERE status = '완료'),
        COUNT(*) FILTER (WHERE status = '취소')
    ), COALESCE(SUM(recorded_amount), 0)
    INTO v_status_counts, v_total_amount
    FROM course_project.enrollments;

    IF v_status_counts <> '2/1/1/1' OR v_total_amount <> 590000 THEN
        RAISE EXCEPTION
            '초기화 중단: 보호 대상 course_project 상태·금액 기준이 다릅니다.';
    END IF;
END
$$;

DROP TABLE IF EXISTS performance_lab.enrollments;
DROP TABLE IF EXISTS performance_lab.courses;
DROP TABLE IF EXISTS performance_lab.instructors;
DROP TABLE IF EXISTS performance_lab.students;
DROP SCHEMA IF EXISTS performance_lab;

DO $$
DECLARE
    v_active_count bigint;
    v_active_amount numeric(20,0);
    v_non_cancelled_count bigint;
    v_non_cancelled_amount numeric(20,0);
BEGIN
    IF to_regnamespace('performance_lab') IS NOT NULL THEN
        RAISE EXCEPTION
            '초기화 검증 실패: performance_lab 스키마가 남아 있습니다.';
    END IF;

    IF (SELECT COUNT(*) FROM course_project.students) <> 3
       OR (SELECT COUNT(*) FROM course_project.instructors) <> 2
       OR (SELECT COUNT(*) FROM course_project.courses) <> 3
       OR (SELECT COUNT(*) FROM course_project.enrollments) <> 5
       OR (SELECT COALESCE(SUM(recorded_amount), 0) FROM course_project.enrollments) <> 590000 THEN
        RAISE EXCEPTION
            '초기화 검증 실패: course_project 기준 데이터가 변경되었습니다.';
    END IF;

    SELECT
        COUNT(*) FILTER (WHERE status IN ('신청', '수강중')),
        COALESCE(SUM(recorded_amount) FILTER (WHERE status IN ('신청', '수강중')), 0),
        COUNT(*) FILTER (WHERE status <> '취소'),
        COALESCE(SUM(recorded_amount) FILTER (WHERE status <> '취소'), 0)
    INTO v_active_count, v_active_amount, v_non_cancelled_count, v_non_cancelled_amount
    FROM course_project.enrollments;

    IF v_active_count <> 3
       OR v_active_amount <> 340000
       OR v_non_cancelled_count <> 4
       OR v_non_cancelled_amount <> 440000 THEN
        RAISE EXCEPTION
            '초기화 검증 실패: Chapter 07·08 활성/취소 제외 기준이 변경되었습니다.';
    END IF;

    RAISE NOTICE 'Chapter 10 performance lab reset passed';
END
$$;

COMMIT;

-- 삭제 후 실행 순서:
-- 1. 01_performance_lab_schema.sql
-- 2. 02_performance_lab_seed.sql
-- 3. 03_baseline_explain.sql
-- 4. 04_create_candidate_indexes.sql
-- 5. 05_after_index_explain.sql
-- 6. 06_index_review.sql
-- 7. 07_result_validation.sql
