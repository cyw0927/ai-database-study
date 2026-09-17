-- Chapter 13. 역할이 섞인 나쁜 설계 샘플
-- 실행 전 01_ai_review_lab_schema.sql을 먼저 실행합니다.
-- 실제 카드번호·개인정보가 아닌 명확한 가상값만 사용합니다.

SELECT current_database();
SELECT current_schema();
SHOW search_path;

-- ============================================================
-- P13-V02. 재실행과 부분 입력 방지
-- ============================================================
DO $$
BEGIN
    IF current_database() <> 'ai_database_book' THEN
        RAISE EXCEPTION
            '실행 중단: 현재 데이터베이스는 %입니다.',
            current_database();
    END IF;

    IF to_regclass('ai_review_lab.bad_enrollments') IS NULL THEN
        RAISE EXCEPTION
            '실행 중단: bad_enrollments가 없습니다. 01 파일을 먼저 실행하세요.';
    END IF;

    IF (SELECT COUNT(*) FROM ai_review_lab.bad_enrollments) <> 0 THEN
        RAISE EXCEPTION
            '실행 중단: bad_enrollments는 비어 있어야 합니다. 기존 데이터를 확인하세요.';
    END IF;
END
$$;

BEGIN;

INSERT INTO ai_review_lab.bad_enrollments (
    id,
    student_name,
    student_email,
    course_title,
    course_price,
    instructor_name,
    payment_status,
    sensitive_value_plaintext,
    enrollment_status,
    created_at
)
VALUES
(
    1,
    '김학생',
    'kim.review@example.com',
    '데이터베이스 입문',
    '100000',
    '박강사',
    'paid',
    'TEST-SENSITIVE-PLAINTEXT-01',
    'completed',
    '2026-07-01'
),
(
    2,
    '김학생',
    'kim.review@example.com',
    'AI 데이터 분석',
    '150000',
    '이강사',
    'paid',
    'TEST-SENSITIVE-PLAINTEXT-01',
    'completed',
    '2026-07-02'
),
(
    3,
    '이학생',
    'lee.review@example.com',
    '데이터베이스 입문',
    'one hundred thousand',
    '박강사',
    'done',
    'TEST-SENSITIVE-PLAINTEXT-02',
    'finished',
    'yesterday'
);

-- 명시적 ID 입력은 IDENTITY 내부 시퀀스를 자동으로 이동시키지 않습니다.
ALTER TABLE ai_review_lab.bad_enrollments
    ALTER COLUMN id RESTART WITH 4;

-- 나쁜 설계의 의도한 문제 자체가 재현되는지 COMMIT 전에 확인합니다.
DO $$
BEGIN
    IF (SELECT COUNT(*) FROM ai_review_lab.bad_enrollments) <> 3 THEN
        RAISE EXCEPTION
            '샘플 입력 중단: bad_enrollments는 3행이어야 합니다.';
    END IF;

    IF (
        SELECT COUNT(*)
        FROM ai_review_lab.bad_enrollments
        WHERE student_email = 'kim.review@example.com'
    ) <> 2 THEN
        RAISE EXCEPTION
            '샘플 입력 중단: 의도한 학생 이메일 반복이 재현되지 않았습니다.';
    END IF;

    IF (
        SELECT COUNT(*)
        FROM ai_review_lab.bad_enrollments
        WHERE course_price !~ '^[0-9]+$'
    ) <> 1
       OR (
            SELECT COUNT(*)
            FROM ai_review_lab.bad_enrollments
            WHERE created_at = 'yesterday'
       ) <> 1
       OR (
            SELECT COUNT(*)
            FROM ai_review_lab.bad_enrollments
            WHERE payment_status = 'done'
       ) <> 1
       OR (
            SELECT COUNT(*)
            FROM ai_review_lab.bad_enrollments
            WHERE enrollment_status = 'finished'
       ) <> 1 THEN
        RAISE EXCEPTION
            '샘플 입력 중단: 약한 타입·통제되지 않은 상태값 반례가 기대와 다릅니다.';
    END IF;

    IF (
        SELECT COUNT(DISTINCT sensitive_value_plaintext)
        FROM ai_review_lab.bad_enrollments
    ) <> 2 THEN
        RAISE EXCEPTION
            '샘플 입력 중단: 평문 민감값 형태의 반복 문제가 재현되지 않았습니다.';
    END IF;
END
$$;

COMMIT;

-- 전체 민감값은 표시하지 않고 일부만 확인합니다.
SELECT
    id,
    student_email,
    course_title,
    course_price,
    payment_status,
    LEFT(sensitive_value_plaintext, 14) || '...' AS unsafe_value_preview,
    enrollment_status,
    created_at
FROM ai_review_lab.bad_enrollments
ORDER BY id;

-- 반복 데이터와 통제되지 않은 상태값 확인
SELECT
    student_email,
    COUNT(*) AS duplicated_rows
FROM ai_review_lab.bad_enrollments
GROUP BY student_email
HAVING COUNT(*) > 1;

SELECT DISTINCT payment_status
FROM ai_review_lab.bad_enrollments
ORDER BY payment_status;

SELECT DISTINCT enrollment_status
FROM ai_review_lab.bad_enrollments
ORDER BY enrollment_status;

SELECT
    COUNT(*) AS bad_enrollment_count,
    MIN(id) AS min_id,
    MAX(id) AS max_id
FROM ai_review_lab.bad_enrollments;

-- 기대 결과: 3 / 1 / 3

DO $$
BEGIN
    RAISE NOTICE 'Chapter 13 bad design seed passed';
END
$$;
