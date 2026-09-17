-- Chapter 13. ai_review_lab 스키마와 나쁜 설계 테이블 생성
-- 목적: 기존 프로젝트를 보호하면서 AI 설계 검토를 격리합니다.
-- 주의: 기존 스키마나 테이블을 자동으로 삭제하지 않습니다.

SELECT current_user AS current_user_name;
SELECT current_database();
SELECT current_schema();
SHOW search_path;
SHOW transaction_read_only;

-- ============================================================
-- P13-V01. 실행 위치와 Chapter 07·08 기준 상태 보호
-- ============================================================
DO $$
DECLARE
    recorded_amount_type_ok BOOLEAN;
    v_project_named_constraint_count BIGINT;
    v_project_not_null_count BIGINT;
BEGIN
    IF current_database() <> 'ai_database_book' THEN
        RAISE EXCEPTION
            '실행 중단: 현재 데이터베이스는 %입니다. ai_database_book에 연결하세요.',
            current_database();
    END IF;

    IF current_setting('transaction_read_only') = 'on' THEN
        RAISE EXCEPTION
            '실행 중단: 현재 연결은 읽기 전용입니다. ai_review_lab을 생성할 수 없습니다.';
    END IF;

    IF to_regclass('course_project.students') IS NULL
       OR to_regclass('course_project.instructors') IS NULL
       OR to_regclass('course_project.courses') IS NULL
       OR to_regclass('course_project.enrollments') IS NULL THEN
        RAISE EXCEPTION
            '실행 중단: Chapter 07 course_project 핵심 테이블이 준비되지 않았습니다.';
    END IF;

    IF to_regclass('course_project.uq_course_enrollments_active') IS NULL THEN
        RAISE EXCEPTION
            '실행 중단: Chapter 07 활성 신청 부분 고유 인덱스가 없습니다.';
    END IF;

    SELECT EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = 'course_project'
          AND table_name = 'enrollments'
          AND column_name = 'recorded_amount'
          AND data_type = 'numeric'
          AND numeric_precision = 12
          AND numeric_scale = 0
    )
    INTO recorded_amount_type_ok;

    IF NOT recorded_amount_type_ok THEN
        RAISE EXCEPTION
            '실행 중단: course_project.enrollments.recorded_amount는 NUMERIC(12,0)이어야 합니다.';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = 'course_project'
          AND table_name = 'enrollments'
          AND column_name = 'paid_amount'
    ) THEN
        RAISE EXCEPTION
            '실행 중단: 현재 기준에 없는 이전 금액 컬럼이 발견되었습니다.';
    END IF;

    IF (SELECT COUNT(*) FROM course_project.students) <> 3
       OR (SELECT COUNT(*) FROM course_project.instructors) <> 2
       OR (SELECT COUNT(*) FROM course_project.courses) <> 3
       OR (SELECT COUNT(*) FROM course_project.enrollments) <> 5 THEN
        RAISE EXCEPTION
            '실행 중단: Chapter 07·08 기준 행 수는 3/2/3/5여야 합니다.';
    END IF;

    IF (SELECT COUNT(*) FROM course_project.enrollments WHERE status = '신청') <> 2
       OR (SELECT COUNT(*) FROM course_project.enrollments WHERE status = '수강중') <> 1
       OR (SELECT COUNT(*) FROM course_project.enrollments WHERE status = '완료') <> 1
       OR (SELECT COUNT(*) FROM course_project.enrollments WHERE status = '취소') <> 1 THEN
        RAISE EXCEPTION
            '실행 중단: Chapter 07·08 상태 분포는 신청2/수강중1/완료1/취소1이어야 합니다.';
    END IF;

    IF (SELECT COALESCE(SUM(recorded_amount), 0) FROM course_project.enrollments) <> 590000
       OR (
            SELECT COUNT(*)
            FROM course_project.enrollments
            WHERE status IN ('신청', '수강중')
       ) <> 3
       OR (
            SELECT COALESCE(SUM(recorded_amount), 0)
            FROM course_project.enrollments
            WHERE status IN ('신청', '수강중')
       ) <> 340000
       OR (
            SELECT COUNT(*)
            FROM course_project.enrollments
            WHERE status <> '취소'
       ) <> 4
       OR (
            SELECT COALESCE(SUM(recorded_amount), 0)
            FROM course_project.enrollments
            WHERE status <> '취소'
       ) <> 440000 THEN
        RAISE EXCEPTION
            '실행 중단: 기록 금액 기준은 전체590000/활성3·340000/취소제외4·440000이어야 합니다.';
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM course_project.enrollments
        WHERE id = 1001 AND status = '완료' AND recorded_amount = 100000
    ) OR NOT EXISTS (
        SELECT 1 FROM course_project.enrollments
        WHERE id = 1004 AND status = '취소' AND recorded_amount = 150000
    ) OR NOT EXISTS (
        SELECT 1 FROM course_project.enrollments
        WHERE id = 1005 AND status = '신청' AND recorded_amount = 120000
    ) THEN
        RAISE EXCEPTION
            '실행 중단: 핵심 신청 1001/1004/1005가 Chapter 07·08 기준과 다릅니다.';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM course_project.enrollments
        WHERE status IN ('신청', '수강중')
        GROUP BY student_id, course_id
        HAVING COUNT(*) > 1
    ) THEN
        RAISE EXCEPTION
            '실행 중단: Chapter 07·08 원본에 활성 신청 중복이 있습니다.';
    END IF;

    IF NOT has_database_privilege(current_user, current_database(), 'CREATE') THEN
        RAISE EXCEPTION
            '실행 중단: 현재 역할 %에는 데이터베이스 %의 CREATE 권한이 없습니다.',
            current_user, current_database();
    END IF;

    SELECT COUNT(*)
    INTO v_project_named_constraint_count
    FROM pg_constraint
    WHERE conrelid IN (
        'course_project.students'::regclass,
        'course_project.instructors'::regclass,
        'course_project.courses'::regclass,
        'course_project.enrollments'::regclass
    )
      AND conname IN (
        'uq_course_students_email',
        'chk_course_students_name_not_blank',
        'chk_course_students_email_not_blank',
        'uq_course_instructors_email',
        'chk_course_instructors_name_not_blank',
        'chk_course_instructors_email_not_blank',
        'chk_course_instructors_specialty_not_blank',
        'fk_course_courses_instructor',
        'chk_course_courses_title_not_blank',
        'chk_course_courses_level',
        'chk_course_courses_price',
        'fk_course_enrollments_student',
        'fk_course_enrollments_course',
        'chk_course_enrollments_status',
        'chk_course_enrollments_recorded_amount'
      );

    SELECT COUNT(*)
    INTO v_project_not_null_count
    FROM information_schema.columns
    WHERE table_schema = 'course_project'
      AND table_name IN ('students', 'instructors', 'courses', 'enrollments')
      AND is_nullable = 'NO';

    IF v_project_named_constraint_count <> 15
       OR v_project_not_null_count <> 20 THEN
        RAISE EXCEPTION
            '실행 중단: Chapter 07 구조 기준과 다릅니다. named_constraints=%, not_null_columns=%',
            v_project_named_constraint_count, v_project_not_null_count;
    END IF;

    IF EXISTS (
        SELECT 1
        FROM pg_namespace
        WHERE nspname = 'ai_review_lab'
    ) THEN
        RAISE EXCEPTION
            '실행 중단: ai_review_lab이 이미 존재합니다. 보존 여부를 확인한 뒤 reset_ai_review_lab.sql 사용을 검토하세요.';
    END IF;
END
$$;

-- 앞 장 스키마는 존재 여부만 확인하고 변경하지 않습니다.
SELECT
    to_regnamespace('course_project') AS course_project_schema,
    to_regnamespace('transaction_lab') AS transaction_lab_schema,
    to_regnamespace('performance_lab') AS performance_lab_schema,
    to_regnamespace('security_lab') AS security_lab_schema,
    to_regnamespace('nosql_lab') AS nosql_lab_schema;

-- ============================================================
-- P13-T01. 나쁜 설계 기준선 생성
-- 중간 실패 시 일부 객체만 남지 않도록 하나의 트랜잭션으로 처리합니다.
-- ============================================================
BEGIN;

CREATE SCHEMA ai_review_lab;

-- 교육 목적상 역할 혼합, 약한 타입, FK 부재와 평문 민감정보 형태의
-- 문제를 의도적으로 포함합니다. 실제 개인정보·카드번호는 사용하지 않습니다.
CREATE TABLE ai_review_lab.bad_enrollments (
    id INTEGER GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    student_name TEXT,
    student_email TEXT,
    course_title TEXT,
    course_price TEXT,
    instructor_name TEXT,
    payment_status TEXT,
    sensitive_value_plaintext TEXT,
    enrollment_status TEXT,
    created_at TEXT
);

-- 생성 결과도 COMMIT 전에 판정합니다.
DO $$
DECLARE
    actual_tables TEXT[];
    constraint_count INTEGER;
    identity_count INTEGER;
    column_count INTEGER;
BEGIN
    SELECT array_agg(table_name ORDER BY table_name)
    INTO actual_tables
    FROM information_schema.tables
    WHERE table_schema = 'ai_review_lab';

    IF actual_tables IS DISTINCT FROM ARRAY['bad_enrollments']::TEXT[] THEN
        RAISE EXCEPTION
            '구조 생성 중단: 생성 직후 테이블 집합이 다릅니다. 실제=%',
            actual_tables;
    END IF;

    SELECT COUNT(*)
    INTO column_count
    FROM information_schema.columns
    WHERE table_schema = 'ai_review_lab'
      AND table_name = 'bad_enrollments';

    SELECT COUNT(*)
    INTO constraint_count
    FROM pg_constraint
    WHERE conrelid = 'ai_review_lab.bad_enrollments'::regclass;

    SELECT COUNT(*)
    INTO identity_count
    FROM information_schema.columns
    WHERE table_schema = 'ai_review_lab'
      AND table_name = 'bad_enrollments'
      AND column_name = 'id'
      AND is_identity = 'YES';

    IF column_count <> 10
       OR constraint_count <> 1
       OR identity_count <> 1 THEN
        RAISE EXCEPTION
            '구조 생성 중단: bad_enrollments 기준은 컬럼10/제약1/IDENTITY1입니다. 실제=%/%/%',
            column_count, constraint_count, identity_count;
    END IF;
END
$$;

COMMIT;

-- ============================================================
-- 생성 결과 확인
-- ============================================================
SELECT
    table_schema,
    table_name
FROM information_schema.tables
WHERE table_schema = 'ai_review_lab'
ORDER BY table_name;

SELECT
    to_regclass('ai_review_lab.bad_enrollments') IS NOT NULL
        AS bad_design_table_created;

DO $$
BEGIN
    RAISE NOTICE 'Chapter 13 bad design schema creation passed';
END
$$;
