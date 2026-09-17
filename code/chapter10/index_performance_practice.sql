-- Chapter 10. 실행 계획으로 인덱스 효과 검증하기
-- 기존 링크 호환용 읽기 전용 안내·상태 확인 진입점입니다.
-- 실제 실습은 01→07을 순서대로 실행합니다.

SELECT current_database();
SELECT current_schema();
SHOW search_path;
SHOW server_version;

DO $$
DECLARE
    v_requested_count bigint;
    v_learning_count bigint;
    v_completed_count bigint;
    v_cancelled_count bigint;
    v_total_amount numeric(20,0);
BEGIN
    IF current_database() <> 'ai_database_book' THEN
        RAISE EXCEPTION
            '실행 중단: 현재 데이터베이스는 %입니다.', current_database();
    END IF;

    IF to_regclass('course_project.students') IS NULL
       OR to_regclass('course_project.instructors') IS NULL
       OR to_regclass('course_project.courses') IS NULL
       OR to_regclass('course_project.enrollments') IS NULL THEN
        RAISE EXCEPTION
            '실행 중단: Chapter 07·08 course_project 기준 데이터를 먼저 준비하세요.';
    END IF;

    IF (SELECT COUNT(*) FROM course_project.students) <> 3
       OR (SELECT COUNT(*) FROM course_project.instructors) <> 2
       OR (SELECT COUNT(*) FROM course_project.courses) <> 3
       OR (SELECT COUNT(*) FROM course_project.enrollments) <> 5 THEN
        RAISE EXCEPTION
            '실행 중단: Chapter 07·08 기준 행 수 3/2/3/5와 다릅니다.';
    END IF;

    SELECT
        COUNT(*) FILTER (WHERE status = '신청'),
        COUNT(*) FILTER (WHERE status = '수강중'),
        COUNT(*) FILTER (WHERE status = '완료'),
        COUNT(*) FILTER (WHERE status = '취소'),
        COALESCE(SUM(recorded_amount), 0)
    INTO v_requested_count, v_learning_count, v_completed_count, v_cancelled_count, v_total_amount
    FROM course_project.enrollments;

    IF v_requested_count <> 2
       OR v_learning_count <> 1
       OR v_completed_count <> 1
       OR v_cancelled_count <> 1
       OR v_total_amount <> 590000 THEN
        RAISE EXCEPTION
            '실행 중단: Chapter 07·08 상태 2/1/1/1 또는 전체 기록 금액 590000과 다릅니다.';
    END IF;
END
$$;

-- 보호 대상 기준 상태
SELECT
    (SELECT COUNT(*) FROM course_project.students) AS project_students,
    (SELECT COUNT(*) FROM course_project.instructors) AS project_instructors,
    (SELECT COUNT(*) FROM course_project.courses) AS project_courses,
    (SELECT COUNT(*) FROM course_project.enrollments) AS project_enrollments,
    (SELECT SUM(recorded_amount) FROM course_project.enrollments) AS project_recorded_amount;

-- performance_lab 준비 상태
SELECT
    to_regclass('performance_lab.students') AS students_table,
    to_regclass('performance_lab.instructors') AS instructors_table,
    to_regclass('performance_lab.courses') AS courses_table,
    to_regclass('performance_lab.enrollments') AS enrollments_table;

-- 준비된 상태에서 참고할 기대값:
-- students / instructors / courses / enrollments = 10003 / 2 / 2003 / 100005
-- candidate indexes before 04 = 0, after 04 = 3

SELECT tablename, indexname, indexdef
FROM pg_indexes
WHERE schemaname = 'performance_lab'
ORDER BY tablename, indexname;

-- 실제 실행 순서:
-- 1. 01_performance_lab_schema.sql
-- 2. 02_performance_lab_seed.sql
-- 3. 03_baseline_explain.sql
-- 4. 04_create_candidate_indexes.sql
-- 5. 05_after_index_explain.sql
-- 6. 06_index_review.sql
-- 7. 07_result_validation.sql
-- 처음부터 다시 시작할 때만 reset_performance_lab.sql을 사용합니다.
