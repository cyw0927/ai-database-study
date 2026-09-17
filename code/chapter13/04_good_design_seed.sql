-- Chapter 13. 좋은 설계 기준 데이터
-- 실행 전 01→03 파일을 순서대로 실행합니다.
-- 명시적 ID를 사용하고 마지막에 IDENTITY 다음 값을 조정합니다.

SELECT current_database();
SELECT current_schema();
SHOW search_path;

-- ============================================================
-- P13-V04. 테이블 존재·빈 상태 확인
-- ============================================================
DO $$
BEGIN
    IF current_database() <> 'ai_database_book' THEN
        RAISE EXCEPTION
            '실행 중단: 현재 데이터베이스는 %입니다.',
            current_database();
    END IF;

    IF to_regclass('ai_review_lab.students') IS NULL
       OR to_regclass('ai_review_lab.instructors') IS NULL
       OR to_regclass('ai_review_lab.courses') IS NULL
       OR to_regclass('ai_review_lab.enrollments') IS NULL
       OR to_regclass('ai_review_lab.payments') IS NULL THEN
        RAISE EXCEPTION
            '실행 중단: 좋은 설계 테이블이 모두 존재해야 합니다.';
    END IF;

    IF (SELECT COUNT(*) FROM ai_review_lab.students) <> 0
       OR (SELECT COUNT(*) FROM ai_review_lab.instructors) <> 0
       OR (SELECT COUNT(*) FROM ai_review_lab.courses) <> 0
       OR (SELECT COUNT(*) FROM ai_review_lab.enrollments) <> 0
       OR (SELECT COUNT(*) FROM ai_review_lab.payments) <> 0 THEN
        RAISE EXCEPTION
            '실행 중단: 좋은 설계 테이블은 모두 비어 있어야 합니다.';
    END IF;
END
$$;

BEGIN;

INSERT INTO ai_review_lab.students (
    id, name, email, joined_at
)
VALUES
    (101, '김학생', 'kim.review@example.com', '2026-07-01'),
    (102, '이학생', 'lee.review@example.com', '2026-07-02'),
    (103, '박학생', 'park.review@example.com', '2026-07-03');

INSERT INTO ai_review_lab.instructors (
    id, name, email, specialty
)
VALUES
    (201, '박강사', 'teacher-park.review@example.com', 'Database'),
    (202, '이강사', 'teacher-lee.review@example.com', 'AI Data Analysis');

INSERT INTO ai_review_lab.courses (
    id,
    instructor_id,
    course_code,
    title,
    description,
    level,
    price,
    opened_at
)
VALUES
(
    301,
    201,
    'DB-101',
    '데이터베이스 입문',
    '관계형 데이터베이스와 SQL 기초',
    'basic',
    100000,
    '2026-07-01'
),
(
    302,
    202,
    'AI-201',
    'AI 데이터 분석',
    'AI 기반 데이터 분석 입문',
    'intermediate',
    180000,
    '2026-07-02'
),
(
    303,
    201,
    'SQL-301',
    'SQL 실습 심화',
    'JOIN과 트랜잭션 심화',
    'advanced',
    120000,
    '2026-07-03'
);

INSERT INTO ai_review_lab.enrollments (
    id,
    student_id,
    course_id,
    status,
    recorded_amount,
    enrolled_at
)
VALUES
    (1001, 101, 301, '완료', 100000, '2026-07-01'),
    -- 현재 강의 가격은 180000원이지만 신청 시점 기록 금액은 150000원입니다.
    (1002, 101, 302, '완료', 150000, '2026-07-02'),
    (1003, 102, 301, '신청', 100000, '2026-07-02'),
    (1004, 103, 303, '취소', 120000, '2026-07-03');

-- payments는 ai_review_lab의 격리 리뷰 시나리오입니다.
-- amount는 실제 결제 상태에 기록된 금액이며 enrollment의 신청 시점 기록 금액과 구분합니다.
INSERT INTO ai_review_lab.payments (
    id,
    enrollment_id,
    amount,
    payment_status,
    paid_at,
    refunded_at,
    payment_reference
)
VALUES
(
    9001,
    1001,
    100000,
    '결제완료',
    '2026-07-01 10:00:00+09',
    NULL,
    'PAY-REVIEW-TEST-001'
),
(
    9002,
    1002,
    150000,
    '결제완료',
    '2026-07-02 11:00:00+09',
    NULL,
    'PAY-REVIEW-TEST-002'
),
(
    9003,
    1003,
    100000,
    '결제대기',
    NULL,
    NULL,
    'PAY-REVIEW-TEST-003'
),
(
    9004,
    1004,
    120000,
    '환불',
    '2026-07-03 12:00:00+09',
    '2026-07-03 15:00:00+09',
    'PAY-REVIEW-TEST-004'
);

-- 명시적 ID 입력은 IDENTITY 시퀀스를 자동으로 이동시키지 않습니다.
ALTER TABLE ai_review_lab.students
    ALTER COLUMN id RESTART WITH 104;
ALTER TABLE ai_review_lab.instructors
    ALTER COLUMN id RESTART WITH 203;
ALTER TABLE ai_review_lab.courses
    ALTER COLUMN id RESTART WITH 304;
ALTER TABLE ai_review_lab.enrollments
    ALTER COLUMN id RESTART WITH 1005;
ALTER TABLE ai_review_lab.payments
    ALTER COLUMN id RESTART WITH 9005;

-- COMMIT 전 기준 상태 자동 판정
DO $$
BEGIN
    IF (SELECT COUNT(*) FROM ai_review_lab.students) <> 3
       OR (SELECT COUNT(*) FROM ai_review_lab.instructors) <> 2
       OR (SELECT COUNT(*) FROM ai_review_lab.courses) <> 3
       OR (SELECT COUNT(*) FROM ai_review_lab.enrollments) <> 4
       OR (SELECT COUNT(*) FROM ai_review_lab.payments) <> 4 THEN
        RAISE EXCEPTION
            '샘플 입력 중단: 기준 행 수가 예상과 다릅니다.';
    END IF;

    IF (SELECT COUNT(*) FROM ai_review_lab.enrollments WHERE status = '완료') <> 2
       OR (SELECT COUNT(*) FROM ai_review_lab.enrollments WHERE status = '신청') <> 1
       OR (SELECT COUNT(*) FROM ai_review_lab.enrollments WHERE status = '취소') <> 1
       OR (SELECT COUNT(*) FROM ai_review_lab.enrollments WHERE status = '수강중') <> 0 THEN
        RAISE EXCEPTION
            '샘플 입력 중단: 신청 상태 분포는 완료2/신청1/취소1/수강중0이어야 합니다.';
    END IF;

    IF (SELECT COUNT(*) FROM ai_review_lab.payments WHERE payment_status = '결제완료') <> 2
       OR (SELECT COUNT(*) FROM ai_review_lab.payments WHERE payment_status = '결제대기') <> 1
       OR (SELECT COUNT(*) FROM ai_review_lab.payments WHERE payment_status = '환불') <> 1
       OR (SELECT COUNT(*) FROM ai_review_lab.payments WHERE payment_status = '결제실패') <> 0 THEN
        RAISE EXCEPTION
            '샘플 입력 중단: 결제 상태 분포는 결제완료2/결제대기1/환불1/결제실패0이어야 합니다.';
    END IF;

    IF (SELECT COALESCE(SUM(recorded_amount), 0) FROM ai_review_lab.enrollments) <> 470000
       OR (SELECT COALESCE(SUM(amount), 0) FROM ai_review_lab.payments) <> 470000 THEN
        RAISE EXCEPTION
            '샘플 입력 중단: 신청 시점 기록 금액과 결제 상태 기록 금액 합계는 각각 470000이어야 합니다.';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM ai_review_lab.enrollments AS e
        JOIN ai_review_lab.payments AS p
            ON p.enrollment_id = e.id
        WHERE e.recorded_amount <> p.amount
    ) THEN
        RAISE EXCEPTION
            '샘플 입력 중단: 신청 시점 기록 금액과 결제 상태 기록 금액이 다릅니다.';
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM ai_review_lab.enrollments AS e
        JOIN ai_review_lab.courses AS c ON c.id = e.course_id
        WHERE e.id = 1002
          AND c.price = 180000
          AND e.recorded_amount = 150000
    ) THEN
        RAISE EXCEPTION
            '샘플 입력 중단: 현재 가격과 신청 시점 기록 금액 차이 예제가 준비되지 않았습니다.';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM ai_review_lab.payments
        WHERE payment_reference NOT LIKE 'PAY-REVIEW-TEST-%'
    ) THEN
        RAISE EXCEPTION
            '샘플 입력 중단: 결제 참조값은 가상 테스트 값만 사용해야 합니다.';
    END IF;
END
$$;

COMMIT;

SELECT
    (SELECT COUNT(*) FROM ai_review_lab.students) AS student_count,
    (SELECT COUNT(*) FROM ai_review_lab.instructors) AS instructor_count,
    (SELECT COUNT(*) FROM ai_review_lab.courses) AS course_count,
    (SELECT COUNT(*) FROM ai_review_lab.enrollments) AS enrollment_count,
    (SELECT COUNT(*) FROM ai_review_lab.payments) AS payment_count,
    (SELECT SUM(recorded_amount) FROM ai_review_lab.enrollments) AS recorded_amount_total,
    (SELECT SUM(amount) FROM ai_review_lab.payments) AS payment_amount_total;

-- 기대 결과: 3 / 2 / 3 / 4 / 4 / 470000 / 470000

DO $$
BEGIN
    RAISE NOTICE 'Chapter 13 good design seed passed';
END
$$;
