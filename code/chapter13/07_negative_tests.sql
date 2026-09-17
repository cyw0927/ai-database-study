-- Chapter 13. 안전한 반례·정상 경계값 테스트
-- 실행 전 01→06 파일을 순서대로 실행합니다.
-- 각 테스트는 PostgreSQL 예외 블록의 독립 하위 트랜잭션에서 실행됩니다.
-- 테스트 SQL은 성공하더라도 의도적으로 예외를 발생시켜 자동 취소합니다.

SELECT current_database();
SELECT current_schema();
SHOW search_path;

DO $$
BEGIN
    IF current_database() <> 'ai_database_book' THEN
        RAISE EXCEPTION
            '테스트 중단: 현재 데이터베이스는 %입니다.',
            current_database();
    END IF;

    IF to_regclass('ai_review_lab.payments') IS NULL
       OR (SELECT COUNT(*) FROM ai_review_lab.students) <> 3
       OR (SELECT COUNT(*) FROM ai_review_lab.instructors) <> 2
       OR (SELECT COUNT(*) FROM ai_review_lab.courses) <> 3
       OR (SELECT COUNT(*) FROM ai_review_lab.enrollments) <> 4
       OR (SELECT COUNT(*) FROM ai_review_lab.payments) <> 4 THEN
        RAISE EXCEPTION
            '테스트 중단: 01→06 기준 상태가 준비되지 않았습니다.';
    END IF;
END
$$;

DROP TABLE IF EXISTS pg_temp.negative_test_results;

CREATE TEMP TABLE negative_test_results (
    test_order INTEGER PRIMARY KEY,
    test_id TEXT NOT NULL,
    test_name TEXT NOT NULL,
    expected_result TEXT NOT NULL,
    expected_sqlstate TEXT,
    actual_sqlstate TEXT,
    expected_constraint TEXT,
    actual_constraint TEXT,
    actual_table TEXT,
    actual_column TEXT,
    actual_result TEXT NOT NULL,
    detail TEXT
);

CREATE OR REPLACE PROCEDURE pg_temp.expect_failure(
    p_test_order INTEGER,
    p_test_id TEXT,
    p_test_name TEXT,
    p_sql TEXT,
    p_expected_sqlstate TEXT,
    p_expected_constraint TEXT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_sqlstate TEXT;
    v_message TEXT;
    v_constraint TEXT;
    v_table TEXT;
    v_column TEXT;
BEGIN
    BEGIN
        EXECUTE p_sql;
        RAISE EXCEPTION USING
            ERRCODE = 'P0001',
            MESSAGE = '__UNEXPECTED_SUCCESS__';
    EXCEPTION
        WHEN OTHERS THEN
            GET STACKED DIAGNOSTICS
                v_sqlstate = RETURNED_SQLSTATE,
                v_message = MESSAGE_TEXT,
                v_constraint = CONSTRAINT_NAME,
                v_table = TABLE_NAME,
                v_column = COLUMN_NAME;

            IF v_sqlstate = 'P0001'
               AND v_message = '__UNEXPECTED_SUCCESS__' THEN
                INSERT INTO pg_temp.negative_test_results
                VALUES (
                    p_test_order, p_test_id, p_test_name,
                    'expected_failure', p_expected_sqlstate, NULL,
                    p_expected_constraint, NULL, NULL, NULL,
                    'unexpected_success',
                    'SQL이 예상과 달리 성공했습니다.'
                );
            ELSIF v_sqlstate = p_expected_sqlstate
                  AND (
                      p_expected_constraint IS NULL
                      OR v_constraint = p_expected_constraint
                  ) THEN
                INSERT INTO pg_temp.negative_test_results
                VALUES (
                    p_test_order, p_test_id, p_test_name,
                    'expected_failure', p_expected_sqlstate, v_sqlstate,
                    p_expected_constraint, v_constraint, v_table, v_column,
                    'expected_failure', v_message
                );
            ELSE
                INSERT INTO pg_temp.negative_test_results
                VALUES (
                    p_test_order, p_test_id, p_test_name,
                    'expected_failure', p_expected_sqlstate, v_sqlstate,
                    p_expected_constraint, v_constraint, v_table, v_column,
                    'unexpected_error', v_message
                );
            END IF;
    END;
END
$$;

CREATE OR REPLACE PROCEDURE pg_temp.expect_success(
    p_test_order INTEGER,
    p_test_id TEXT,
    p_test_name TEXT,
    p_sql TEXT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_sqlstate TEXT;
    v_message TEXT;
    v_constraint TEXT;
    v_table TEXT;
    v_column TEXT;
BEGIN
    BEGIN
        EXECUTE p_sql;
        RAISE EXCEPTION USING
            ERRCODE = 'P0001',
            MESSAGE = '__ROLLBACK_EXPECTED_SUCCESS__';
    EXCEPTION
        WHEN OTHERS THEN
            GET STACKED DIAGNOSTICS
                v_sqlstate = RETURNED_SQLSTATE,
                v_message = MESSAGE_TEXT,
                v_constraint = CONSTRAINT_NAME,
                v_table = TABLE_NAME,
                v_column = COLUMN_NAME;

            IF v_sqlstate = 'P0001'
               AND v_message = '__ROLLBACK_EXPECTED_SUCCESS__' THEN
                INSERT INTO pg_temp.negative_test_results
                VALUES (
                    p_test_order, p_test_id, p_test_name,
                    'expected_success', NULL, NULL,
                    NULL, NULL, NULL, NULL,
                    'expected_success',
                    '정상 경계값이 허용되었으며 변경은 자동 취소되었습니다.'
                );
            ELSE
                INSERT INTO pg_temp.negative_test_results
                VALUES (
                    p_test_order, p_test_id, p_test_name,
                    'expected_success', NULL, v_sqlstate,
                    NULL, v_constraint, v_table, v_column,
                    'unexpected_error', v_message
                );
            END IF;
    END;
END
$$;

-- ============================================================
-- P13-T01~P13-T24. 예상 실패 반례
-- ============================================================
CALL pg_temp.expect_failure(
    1, 'P13-T01', 'duplicate_student_email',
    $$INSERT INTO ai_review_lab.students (id, name, email, joined_at)
      VALUES (1901, '중복학생', 'kim.review@example.com', CURRENT_DATE)$$,
    '23505', 'uq_ai_review_students_email'
);

CALL pg_temp.expect_failure(
    2, 'P13-T02', 'blank_student_email',
    $$INSERT INTO ai_review_lab.students (id, name, email, joined_at)
      VALUES (1902, '공백학생', '   ', CURRENT_DATE)$$,
    '23514', 'chk_ai_review_students_email_not_blank'
);

CALL pg_temp.expect_failure(
    3, 'P13-T03', 'duplicate_instructor_email',
    $$INSERT INTO ai_review_lab.instructors (id, name, email, specialty)
      VALUES (2901, '중복강사', 'teacher-park.review@example.com', 'Database')$$,
    '23505', 'uq_ai_review_instructors_email'
);

CALL pg_temp.expect_failure(
    4, 'P13-T04', 'blank_instructor_specialty',
    $$INSERT INTO ai_review_lab.instructors (id, name, email, specialty)
      VALUES (2902, '강사', 'blank-specialty@example.com', ' ')$$,
    '23514', 'chk_ai_review_instructors_specialty_not_blank'
);

CALL pg_temp.expect_failure(
    5, 'P13-T05', 'missing_instructor_fk',
    $$INSERT INTO ai_review_lab.courses
      (id, instructor_id, course_code, title, level, price, opened_at)
      VALUES (3901, 999999, 'BAD-FK-I', '없는 강사', 'basic', 1000, CURRENT_DATE)$$,
    '23503', 'fk_ai_review_courses_instructor'
);

CALL pg_temp.expect_failure(
    6, 'P13-T06', 'invalid_course_level',
    $$INSERT INTO ai_review_lab.courses
      (id, instructor_id, course_code, title, level, price, opened_at)
      VALUES (3902, 201, 'BAD-LEVEL', '잘못된 레벨', 'expert', 1000, CURRENT_DATE)$$,
    '23514', 'chk_ai_review_courses_level'
);

CALL pg_temp.expect_failure(
    7, 'P13-T07', 'negative_course_price',
    $$INSERT INTO ai_review_lab.courses
      (id, instructor_id, course_code, title, level, price, opened_at)
      VALUES (3903, 201, 'BAD-PRICE', '음수 가격', 'basic', -1000, CURRENT_DATE)$$,
    '23514', 'chk_ai_review_courses_price'
);

CALL pg_temp.expect_failure(
    8, 'P13-T08', 'blank_course_code',
    $$INSERT INTO ai_review_lab.courses
      (id, instructor_id, course_code, title, level, price, opened_at)
      VALUES (3904, 201, '   ', '공백 코드', 'basic', 1000, CURRENT_DATE)$$,
    '23514', 'chk_ai_review_courses_code_not_blank'
);

CALL pg_temp.expect_failure(
    9, 'P13-T09', 'missing_student_fk',
    $$INSERT INTO ai_review_lab.enrollments
      (id, student_id, course_id, status, recorded_amount, enrolled_at)
      VALUES (19001, 999999, 301, '신청', 100000, CURRENT_DATE)$$,
    '23503', 'fk_ai_review_enrollments_student'
);

CALL pg_temp.expect_failure(
    10, 'P13-T10', 'missing_course_fk',
    $$INSERT INTO ai_review_lab.enrollments
      (id, student_id, course_id, status, recorded_amount, enrolled_at)
      VALUES (19002, 101, 999999, '신청', 100000, CURRENT_DATE)$$,
    '23503', 'fk_ai_review_enrollments_course'
);

CALL pg_temp.expect_failure(
    11, 'P13-T11', 'invalid_enrollment_status',
    $$INSERT INTO ai_review_lab.enrollments
      (id, student_id, course_id, status, recorded_amount, enrolled_at)
      VALUES (19003, 102, 302, '결제완료', 150000, CURRENT_DATE)$$,
    '23514', 'chk_ai_review_enrollments_status'
);

CALL pg_temp.expect_failure(
    12, 'P13-T12', 'negative_recorded_amount',
    $$INSERT INTO ai_review_lab.enrollments
      (id, student_id, course_id, status, recorded_amount, enrolled_at)
      VALUES (19004, 102, 302, '신청', -1000, CURRENT_DATE)$$,
    '23514', 'chk_ai_review_enrollments_amount'
);

CALL pg_temp.expect_failure(
    13, 'P13-T13', 'duplicate_active_enrollment',
    $$INSERT INTO ai_review_lab.enrollments
      (id, student_id, course_id, status, recorded_amount, enrolled_at)
      VALUES (19005, 102, 301, '수강중', 100000, CURRENT_DATE)$$,
    '23505', 'uq_ai_review_enrollments_active'
);

CALL pg_temp.expect_failure(
    14, 'P13-T14', 'missing_enrollment_fk',
    $$INSERT INTO ai_review_lab.payments
      (id, enrollment_id, amount, payment_status, paid_at, refunded_at, payment_reference)
      VALUES (9901, 999999, 100000, '결제대기', NULL, NULL, 'NEG-MISSING-ENROLLMENT')$$,
    '23503', 'fk_ai_review_payments_enrollment'
);

-- T15~T21은 각 목표 제약조건보다 enrollment_id UNIQUE가 먼저 실패하지 않도록
-- 같은 하위 트랜잭션에서 임시 완료 신청을 만든 뒤 결제를 입력합니다.
CALL pg_temp.expect_failure(
    15, 'P13-T15', 'negative_payment_amount',
    $$WITH new_enrollment AS (
          INSERT INTO ai_review_lab.enrollments
              (id, student_id, course_id, status, recorded_amount, enrolled_at)
          VALUES (19115, 101, 301, '완료', 100000, CURRENT_DATE)
          RETURNING id
      )
      INSERT INTO ai_review_lab.payments
          (id, enrollment_id, amount, payment_status, paid_at, refunded_at, payment_reference)
      SELECT 9915, id, -5000, '결제완료', CURRENT_TIMESTAMP, NULL, 'NEG-AMOUNT'
      FROM new_enrollment$$,
    '23514', 'chk_ai_review_payments_amount'
);

CALL pg_temp.expect_failure(
    16, 'P13-T16', 'invalid_payment_status',
    $$WITH new_enrollment AS (
          INSERT INTO ai_review_lab.enrollments
              (id, student_id, course_id, status, recorded_amount, enrolled_at)
          VALUES (19116, 101, 301, '완료', 100000, CURRENT_DATE)
          RETURNING id
      )
      INSERT INTO ai_review_lab.payments
          (id, enrollment_id, amount, payment_status, paid_at, refunded_at, payment_reference)
      SELECT 9916, id, 100000, '처리완료', CURRENT_TIMESTAMP, NULL, 'NEG-STATUS'
      FROM new_enrollment$$,
    '23514', 'chk_ai_review_payments_status'
);

CALL pg_temp.expect_failure(
    17, 'P13-T17', 'completed_without_paid_at',
    $$WITH new_enrollment AS (
          INSERT INTO ai_review_lab.enrollments
              (id, student_id, course_id, status, recorded_amount, enrolled_at)
          VALUES (19117, 101, 301, '완료', 100000, CURRENT_DATE)
          RETURNING id
      )
      INSERT INTO ai_review_lab.payments
          (id, enrollment_id, amount, payment_status, paid_at, refunded_at, payment_reference)
      SELECT 9917, id, 100000, '결제완료', NULL, NULL, 'NEG-PAID-NULL'
      FROM new_enrollment$$,
    '23514', 'chk_ai_review_payments_timestamps'
);

CALL pg_temp.expect_failure(
    18, 'P13-T18', 'refund_without_refunded_at',
    $$WITH new_enrollment AS (
          INSERT INTO ai_review_lab.enrollments
              (id, student_id, course_id, status, recorded_amount, enrolled_at)
          VALUES (19118, 101, 301, '취소', 100000, CURRENT_DATE)
          RETURNING id
      )
      INSERT INTO ai_review_lab.payments
          (id, enrollment_id, amount, payment_status, paid_at, refunded_at, payment_reference)
      SELECT 9918, id, 100000, '환불', CURRENT_TIMESTAMP, NULL, 'NEG-REFUND-NULL'
      FROM new_enrollment$$,
    '23514', 'chk_ai_review_payments_timestamps'
);

CALL pg_temp.expect_failure(
    19, 'P13-T19', 'refund_before_payment',
    $$WITH new_enrollment AS (
          INSERT INTO ai_review_lab.enrollments
              (id, student_id, course_id, status, recorded_amount, enrolled_at)
          VALUES (19119, 101, 301, '취소', 100000, CURRENT_DATE)
          RETURNING id
      )
      INSERT INTO ai_review_lab.payments
          (id, enrollment_id, amount, payment_status, paid_at, refunded_at, payment_reference)
      SELECT 9919, id, 100000, '환불', CURRENT_TIMESTAMP,
             CURRENT_TIMESTAMP - INTERVAL '1 day', 'NEG-REFUND-BEFORE'
      FROM new_enrollment$$,
    '23514', 'chk_ai_review_payments_timestamps'
);

CALL pg_temp.expect_failure(
    20, 'P13-T20', 'blank_payment_reference',
    $$WITH new_enrollment AS (
          INSERT INTO ai_review_lab.enrollments
              (id, student_id, course_id, status, recorded_amount, enrolled_at)
          VALUES (19120, 101, 301, '완료', 100000, CURRENT_DATE)
          RETURNING id
      )
      INSERT INTO ai_review_lab.payments
          (id, enrollment_id, amount, payment_status, paid_at, refunded_at, payment_reference)
      SELECT 9920, id, 100000, '결제완료', CURRENT_TIMESTAMP, NULL, '   '
      FROM new_enrollment$$,
    '23514', 'chk_ai_review_payments_reference_not_blank'
);

CALL pg_temp.expect_failure(
    21, 'P13-T21', 'duplicate_payment_reference',
    $$WITH new_enrollment AS (
          INSERT INTO ai_review_lab.enrollments
              (id, student_id, course_id, status, recorded_amount, enrolled_at)
          VALUES (19121, 101, 301, '완료', 100000, CURRENT_DATE)
          RETURNING id
      )
      INSERT INTO ai_review_lab.payments
          (id, enrollment_id, amount, payment_status, paid_at, refunded_at, payment_reference)
      SELECT 9921, id, 100000, '결제완료', CURRENT_TIMESTAMP, NULL,
             'PAY-REVIEW-TEST-001'
      FROM new_enrollment$$,
    '23505', 'uq_ai_review_payments_reference'
);

CALL pg_temp.expect_failure(
    22, 'P13-T22', 'duplicate_payment_for_enrollment',
    $$INSERT INTO ai_review_lab.payments
      (id, enrollment_id, amount, payment_status, paid_at, refunded_at, payment_reference)
      VALUES (9922, 1001, 100000, '결제완료', CURRENT_TIMESTAMP, NULL, 'NEG-DUP-ENROLLMENT')$$,
    '23505', 'uq_ai_review_payments_enrollment'
);

-- ============================================================
-- P13-T23~P13-T24. 삭제 RESTRICT 반례
-- ============================================================
CALL pg_temp.expect_failure(
    23, 'P13-T23', 'delete_referenced_instructor_restricted',
    $$DELETE FROM ai_review_lab.instructors WHERE id = 201$$,
    '23503', 'fk_ai_review_courses_instructor'
);

CALL pg_temp.expect_failure(
    24, 'P13-T24', 'delete_referenced_enrollment_restricted',
    $$DELETE FROM ai_review_lab.enrollments WHERE id = 1001$$,
    '23503', 'fk_ai_review_payments_enrollment'
);

-- ============================================================
-- P13-T25~P13-T30. 정상 경계값
-- ============================================================
CALL pg_temp.expect_success(
    25, 'P13-T25', 'zero_price_one_character_and_null_description',
    $$WITH new_instructor AS (
          INSERT INTO ai_review_lab.instructors (id, name, email, specialty)
          VALUES (2991, '가', 'boundary-instructor@example.com', 'D')
          RETURNING id
      )
      INSERT INTO ai_review_lab.courses
          (id, instructor_id, course_code, title, description, level, price, opened_at)
      SELECT 3991, id, 'ZERO-001', '나', NULL, 'basic', 0, CURRENT_DATE
      FROM new_instructor$$
);

CALL pg_temp.expect_success(
    26, 'P13-T26', 'application_without_payment',
    $$INSERT INTO ai_review_lab.enrollments
      (id, student_id, course_id, status, recorded_amount, enrolled_at)
      VALUES (19901, 103, 302, '신청', 0, CURRENT_DATE)$$
);

CALL pg_temp.expect_success(
    27, 'P13-T27', 'reenroll_after_completed_history',
    $$INSERT INTO ai_review_lab.enrollments
      (id, student_id, course_id, status, recorded_amount, enrolled_at)
      VALUES (19902, 101, 301, '신청', 100000, CURRENT_DATE)$$
);

CALL pg_temp.expect_success(
    28, 'P13-T28', 'reenroll_after_cancelled_history',
    $$INSERT INTO ai_review_lab.enrollments
      (id, student_id, course_id, status, recorded_amount, enrolled_at)
      VALUES (19903, 103, 303, '신청', 120000, CURRENT_DATE)$$
);

CALL pg_temp.expect_success(
    29, 'P13-T29', 'failed_zero_payment_with_null_timestamps',
    $$WITH new_enrollment AS (
          INSERT INTO ai_review_lab.enrollments
              (id, student_id, course_id, status, recorded_amount, enrolled_at)
          VALUES (19904, 102, 302, '신청', 0, CURRENT_DATE)
          RETURNING id
      )
      INSERT INTO ai_review_lab.payments
          (id, enrollment_id, amount, payment_status, paid_at, refunded_at, payment_reference)
      SELECT 9994, id, 0, '결제실패', NULL, NULL, 'BOUNDARY-FAILED-000'
      FROM new_enrollment$$
);

CALL pg_temp.expect_success(
    30, 'P13-T30', 'case_variant_student_email_allowed',
    $$INSERT INTO ai_review_lab.students (id, name, email, joined_at)
      VALUES (19905, '대소문자학생', 'Kim.review@example.com', CURRENT_DATE)$$
);

-- ============================================================
-- 결과와 전체 자동 판정
-- ============================================================
SELECT
    test_order,
    test_id,
    test_name,
    expected_result,
    expected_sqlstate,
    actual_sqlstate,
    expected_constraint,
    actual_constraint,
    actual_table,
    actual_column,
    actual_result,
    detail
FROM pg_temp.negative_test_results
ORDER BY test_order;

SELECT
    COUNT(*) AS total_tests_expected_30,
    COUNT(*) FILTER (
        WHERE actual_result IN ('expected_failure', 'expected_success')
    ) AS passed_tests_expected_30,
    COUNT(*) FILTER (
        WHERE actual_result LIKE 'unexpected%'
    ) AS unexpected_tests_expected_0,
    COUNT(*) FILTER (WHERE expected_result = 'expected_failure') AS expected_failures_expected_24,
    COUNT(*) FILTER (WHERE expected_result = 'expected_success') AS expected_successes_expected_6
FROM pg_temp.negative_test_results;

DO $$
DECLARE
    total_count INTEGER;
    pass_count INTEGER;
    unexpected_count INTEGER;
    expected_failure_count INTEGER;
    expected_success_count INTEGER;
BEGIN
    SELECT
        COUNT(*),
        COUNT(*) FILTER (
            WHERE actual_result IN ('expected_failure', 'expected_success')
        ),
        COUNT(*) FILTER (
            WHERE actual_result LIKE 'unexpected%'
        ),
        COUNT(*) FILTER (WHERE expected_result = 'expected_failure'),
        COUNT(*) FILTER (WHERE expected_result = 'expected_success')
    INTO total_count, pass_count, unexpected_count,
         expected_failure_count, expected_success_count
    FROM pg_temp.negative_test_results;

    IF total_count <> 30
       OR pass_count <> 30
       OR unexpected_count <> 0
       OR expected_failure_count <> 24
       OR expected_success_count <> 6 THEN
        RAISE EXCEPTION
            '반례 검증 실패: total %, passed %, unexpected %, failure %, success %.',
            total_count,
            pass_count,
            unexpected_count,
            expected_failure_count,
            expected_success_count;
    END IF;

    IF (SELECT COUNT(*) FROM ai_review_lab.students) <> 3
       OR (SELECT COUNT(*) FROM ai_review_lab.instructors) <> 2
       OR (SELECT COUNT(*) FROM ai_review_lab.courses) <> 3
       OR (SELECT COUNT(*) FROM ai_review_lab.enrollments) <> 4
       OR (SELECT COUNT(*) FROM ai_review_lab.payments) <> 4 THEN
        RAISE EXCEPTION
            '반례 검증 실패: 테스트 후 기준 행 수가 변경되었습니다.';
    END IF;

    RAISE NOTICE 'Chapter 13 negative and boundary tests passed: 30/30';
END
$$;

SELECT
    (SELECT COUNT(*) FROM ai_review_lab.students) AS students_expected_3,
    (SELECT COUNT(*) FROM ai_review_lab.instructors) AS instructors_expected_2,
    (SELECT COUNT(*) FROM ai_review_lab.courses) AS courses_expected_3,
    (SELECT COUNT(*) FROM ai_review_lab.enrollments) AS enrollments_expected_4,
    (SELECT COUNT(*) FROM ai_review_lab.payments) AS payments_expected_4;
