-- Chapter 13. 정상 경로와 업무 정합성 검증
-- 실행 전 01→05 파일을 순서대로 실행합니다.
-- 데이터를 변경하지 않습니다.

SELECT current_database();
SELECT current_schema();
SHOW search_path;

DO $$
BEGIN
    IF current_database() <> 'ai_database_book' THEN
        RAISE EXCEPTION
            '검증 중단: 현재 데이터베이스는 %입니다.',
            current_database();
    END IF;

    IF to_regclass('ai_review_lab.payments') IS NULL
       OR (SELECT COUNT(*) FROM ai_review_lab.bad_enrollments) <> 3
       OR (SELECT COUNT(*) FROM ai_review_lab.students) <> 3
       OR (SELECT COUNT(*) FROM ai_review_lab.instructors) <> 2
       OR (SELECT COUNT(*) FROM ai_review_lab.courses) <> 3
       OR (SELECT COUNT(*) FROM ai_review_lab.enrollments) <> 4
       OR (SELECT COUNT(*) FROM ai_review_lab.payments) <> 4 THEN
        RAISE EXCEPTION
            '검증 중단: 01→05 기준 상태가 준비되지 않았습니다.';
    END IF;
END
$$;

-- ============================================================
-- P13-V06-1. 기준 행 수와 정상 JOIN
-- ============================================================
SELECT
    (SELECT COUNT(*) FROM ai_review_lab.bad_enrollments)
        AS bad_rows_expected_3,
    (SELECT COUNT(*) FROM ai_review_lab.students)
        AS students_expected_3,
    (SELECT COUNT(*) FROM ai_review_lab.instructors)
        AS instructors_expected_2,
    (SELECT COUNT(*) FROM ai_review_lab.courses)
        AS courses_expected_3,
    (SELECT COUNT(*) FROM ai_review_lab.enrollments)
        AS enrollments_expected_4,
    (SELECT COUNT(*) FROM ai_review_lab.payments)
        AS payments_expected_4,
    (SELECT SUM(recorded_amount) FROM ai_review_lab.enrollments)
        AS recorded_amount_expected_470000,
    (SELECT SUM(amount) FROM ai_review_lab.payments)
        AS payment_amount_expected_470000;

SELECT
    e.id AS enrollment_id,
    s.id AS student_id,
    s.name AS student_name,
    s.email AS student_email,
    c.id AS course_id,
    c.course_code,
    c.title AS course_title,
    c.price AS current_course_price,
    i.name AS instructor_name,
    e.status AS enrollment_status,
    e.recorded_amount,
    p.payment_status,
    p.amount AS payment_amount,
    p.paid_at,
    p.refunded_at,
    p.payment_reference
FROM ai_review_lab.enrollments AS e
JOIN ai_review_lab.students AS s
    ON s.id = e.student_id
JOIN ai_review_lab.courses AS c
    ON c.id = e.course_id
JOIN ai_review_lab.instructors AS i
    ON i.id = c.instructor_id
LEFT JOIN ai_review_lab.payments AS p
    ON p.enrollment_id = e.id
ORDER BY e.id;

-- ============================================================
-- P13-V06-2. 기대 결과 0행인 이상 조회
-- ============================================================

-- 학생·강사 이메일 중복
SELECT email, COUNT(*) AS duplicate_count
FROM ai_review_lab.students
GROUP BY email
HAVING COUNT(*) > 1;

SELECT email, COUNT(*) AS duplicate_count
FROM ai_review_lab.instructors
GROUP BY email
HAVING COUNT(*) > 1;

-- 필수 문자열 공백
SELECT id, name, email
FROM ai_review_lab.students
WHERE char_length(trim(name)) = 0
   OR char_length(trim(email)) = 0;

SELECT id, name, email, specialty
FROM ai_review_lab.instructors
WHERE char_length(trim(name)) = 0
   OR char_length(trim(email)) = 0
   OR char_length(trim(specialty)) = 0;

SELECT id, course_code, title
FROM ai_review_lab.courses
WHERE char_length(trim(course_code)) = 0
   OR char_length(trim(title)) = 0;

SELECT id, payment_reference
FROM ai_review_lab.payments
WHERE char_length(trim(payment_reference)) = 0;

-- 신청 시점 기록 금액과 결제 상태 기록 금액 불일치
-- P13-D06: 이 단순 샘플은 전액 결제·전액 환불만 사용합니다.
SELECT
    e.id AS enrollment_id,
    e.recorded_amount,
    p.amount AS payment_amount
FROM ai_review_lab.enrollments AS e
JOIN ai_review_lab.payments AS p
    ON p.enrollment_id = e.id
WHERE e.recorded_amount <> p.amount;

-- 결제·환불 시각 조합 위반
SELECT
    id,
    enrollment_id,
    payment_status,
    paid_at,
    refunded_at
FROM ai_review_lab.payments
WHERE
    (payment_status IN ('결제대기', '결제실패')
     AND (paid_at IS NOT NULL OR refunded_at IS NOT NULL))
 OR (payment_status = '결제완료'
     AND (paid_at IS NULL OR refunded_at IS NOT NULL))
 OR (payment_status = '환불'
     AND (
         paid_at IS NULL
         OR refunded_at IS NULL
         OR refunded_at < paid_at
     ));

-- 고아 관계
SELECT e.*
FROM ai_review_lab.enrollments AS e
LEFT JOIN ai_review_lab.students AS s
    ON s.id = e.student_id
WHERE s.id IS NULL;

SELECT e.*
FROM ai_review_lab.enrollments AS e
LEFT JOIN ai_review_lab.courses AS c
    ON c.id = e.course_id
WHERE c.id IS NULL;

SELECT p.*
FROM ai_review_lab.payments AS p
LEFT JOIN ai_review_lab.enrollments AS e
    ON e.id = p.enrollment_id
WHERE e.id IS NULL;

-- 활성 신청 중복
SELECT
    student_id,
    course_id,
    COUNT(*) AS active_count
FROM ai_review_lab.enrollments
WHERE status IN ('신청', '수강중')
GROUP BY student_id, course_id
HAVING COUNT(*) > 1;

-- 샘플 시나리오 상태 조합
-- 완료는 결제완료, 취소는 환불이어야 합니다.
-- 신청은 결제가 없어도 되며, 결제 행이 있다면 결제대기여야 합니다.
-- 수강중은 결제 행이 있다면 결제완료여야 합니다.
-- IS DISTINCT FROM을 사용해 필수 결제 누락의 NULL도 발견합니다.
SELECT
    e.id AS enrollment_id,
    e.status AS enrollment_status,
    p.id AS payment_id,
    p.payment_status
FROM ai_review_lab.enrollments AS e
LEFT JOIN ai_review_lab.payments AS p
    ON p.enrollment_id = e.id
WHERE
    (e.status = '완료'
     AND p.payment_status IS DISTINCT FROM '결제완료')
 OR (e.status = '취소'
     AND p.payment_status IS DISTINCT FROM '환불')
 OR (e.status = '신청'
     AND p.id IS NOT NULL
     AND p.payment_status IS DISTINCT FROM '결제대기')
 OR (e.status = '수강중'
     AND p.id IS NOT NULL
     AND p.payment_status IS DISTINCT FROM '결제완료');

-- ============================================================
-- P13-V06-3. 정보용 차이: 기대 1행
-- 현재 강의 가격과 신청 시점 기록 금액 차이는 할인·가격 변경일 수 있습니다.
-- ============================================================
SELECT
    e.id AS enrollment_id,
    c.course_code,
    c.price AS current_course_price,
    e.recorded_amount
FROM ai_review_lab.enrollments AS e
JOIN ai_review_lab.courses AS c
    ON c.id = e.course_id
WHERE c.price <> e.recorded_amount
ORDER BY e.id;

-- ============================================================
-- P13-V06-4. 전체 업무 정합성 자동 판정
-- ============================================================
DO $$
DECLARE
    joined_count BIGINT;
    price_difference_count BIGINT;
BEGIN
    SELECT COUNT(*)
    INTO joined_count
    FROM ai_review_lab.enrollments AS e
    JOIN ai_review_lab.students AS s ON s.id = e.student_id
    JOIN ai_review_lab.courses AS c ON c.id = e.course_id
    JOIN ai_review_lab.instructors AS i ON i.id = c.instructor_id
    LEFT JOIN ai_review_lab.payments AS p ON p.enrollment_id = e.id;

    IF joined_count <> 4 THEN
        RAISE EXCEPTION
            '업무 검증 실패: 정상 JOIN은 4행이어야 합니다. 실제=%',
            joined_count;
    END IF;

    IF (SELECT COALESCE(SUM(recorded_amount), 0) FROM ai_review_lab.enrollments) <> 470000
       OR (SELECT COALESCE(SUM(amount), 0) FROM ai_review_lab.payments) <> 470000 THEN
        RAISE EXCEPTION
            '업무 검증 실패: 신청 시점 기록 금액과 결제 상태 기록 금액 합계는 각각 470000이어야 합니다.';
    END IF;

    IF (SELECT COUNT(*) FROM ai_review_lab.enrollments WHERE status = '완료') <> 2
       OR (SELECT COUNT(*) FROM ai_review_lab.enrollments WHERE status = '신청') <> 1
       OR (SELECT COUNT(*) FROM ai_review_lab.enrollments WHERE status = '취소') <> 1
       OR (SELECT COUNT(*) FROM ai_review_lab.enrollments WHERE status = '수강중') <> 0 THEN
        RAISE EXCEPTION '업무 검증 실패: 신청 상태 분포가 기준과 다릅니다.';
    END IF;

    IF (SELECT COUNT(*) FROM ai_review_lab.payments WHERE payment_status = '결제완료') <> 2
       OR (SELECT COUNT(*) FROM ai_review_lab.payments WHERE payment_status = '결제대기') <> 1
       OR (SELECT COUNT(*) FROM ai_review_lab.payments WHERE payment_status = '환불') <> 1
       OR (SELECT COUNT(*) FROM ai_review_lab.payments WHERE payment_status = '결제실패') <> 0 THEN
        RAISE EXCEPTION '업무 검증 실패: 결제 상태 분포가 기준과 다릅니다.';
    END IF;

    IF EXISTS (
        SELECT 1 FROM ai_review_lab.students
        GROUP BY email HAVING COUNT(*) > 1
    ) OR EXISTS (
        SELECT 1 FROM ai_review_lab.instructors
        GROUP BY email HAVING COUNT(*) > 1
    ) THEN
        RAISE EXCEPTION '업무 검증 실패: 이메일 중복이 있습니다.';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM ai_review_lab.students
        WHERE char_length(trim(name)) = 0
           OR char_length(trim(email)) = 0
    ) OR EXISTS (
        SELECT 1
        FROM ai_review_lab.instructors
        WHERE char_length(trim(name)) = 0
           OR char_length(trim(email)) = 0
           OR char_length(trim(specialty)) = 0
    ) OR EXISTS (
        SELECT 1
        FROM ai_review_lab.courses
        WHERE char_length(trim(course_code)) = 0
           OR char_length(trim(title)) = 0
    ) OR EXISTS (
        SELECT 1
        FROM ai_review_lab.payments
        WHERE char_length(trim(payment_reference)) = 0
    ) THEN
        RAISE EXCEPTION '업무 검증 실패: 필수 문자열 공백이 있습니다.';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM ai_review_lab.enrollments AS e
        JOIN ai_review_lab.payments AS p ON p.enrollment_id = e.id
        WHERE e.recorded_amount <> p.amount
    ) THEN
        RAISE EXCEPTION '업무 검증 실패: 신청 시점 기록 금액과 결제 상태 기록 금액이 다릅니다.';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM ai_review_lab.payments
        WHERE
            (payment_status IN ('결제대기', '결제실패')
             AND (paid_at IS NOT NULL OR refunded_at IS NOT NULL))
         OR (payment_status = '결제완료'
             AND (paid_at IS NULL OR refunded_at IS NOT NULL))
         OR (payment_status = '환불'
             AND (
                 paid_at IS NULL
                 OR refunded_at IS NULL
                 OR refunded_at < paid_at
             ))
    ) THEN
        RAISE EXCEPTION '업무 검증 실패: 결제·환불 시각 조합이 잘못되었습니다.';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM ai_review_lab.enrollments AS e
        LEFT JOIN ai_review_lab.students AS s ON s.id = e.student_id
        WHERE s.id IS NULL
    ) OR EXISTS (
        SELECT 1
        FROM ai_review_lab.enrollments AS e
        LEFT JOIN ai_review_lab.courses AS c ON c.id = e.course_id
        WHERE c.id IS NULL
    ) OR EXISTS (
        SELECT 1
        FROM ai_review_lab.payments AS p
        LEFT JOIN ai_review_lab.enrollments AS e ON e.id = p.enrollment_id
        WHERE e.id IS NULL
    ) THEN
        RAISE EXCEPTION '업무 검증 실패: 고아 관계가 있습니다.';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM ai_review_lab.enrollments
        WHERE status IN ('신청', '수강중')
        GROUP BY student_id, course_id
        HAVING COUNT(*) > 1
    ) THEN
        RAISE EXCEPTION '업무 검증 실패: 활성 신청 중복이 있습니다.';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM ai_review_lab.enrollments AS e
        LEFT JOIN ai_review_lab.payments AS p ON p.enrollment_id = e.id
        WHERE
            (e.status = '완료'
             AND p.payment_status IS DISTINCT FROM '결제완료')
         OR (e.status = '취소'
             AND p.payment_status IS DISTINCT FROM '환불')
         OR (e.status = '신청'
             AND p.id IS NOT NULL
             AND p.payment_status IS DISTINCT FROM '결제대기')
         OR (e.status = '수강중'
             AND p.id IS NOT NULL
             AND p.payment_status IS DISTINCT FROM '결제완료')
    ) THEN
        RAISE EXCEPTION '업무 검증 실패: 샘플 상태 조합이 잘못되었습니다.';
    END IF;

    SELECT COUNT(*)
    INTO price_difference_count
    FROM ai_review_lab.enrollments AS e
    JOIN ai_review_lab.courses AS c ON c.id = e.course_id
    WHERE c.price <> e.recorded_amount;

    IF price_difference_count <> 1
       OR NOT EXISTS (
            SELECT 1
            FROM ai_review_lab.enrollments AS e
            JOIN ai_review_lab.courses AS c ON c.id = e.course_id
            WHERE e.id = 1002
              AND c.price = 180000
              AND e.recorded_amount = 150000
       ) THEN
        RAISE EXCEPTION
            '업무 검증 실패: 정보용 가격 차이는 1002 한 행이어야 합니다. 실제=%',
            price_difference_count;
    END IF;

    RAISE NOTICE 'Chapter 13 business validation passed';
END
$$;
