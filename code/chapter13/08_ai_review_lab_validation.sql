-- Chapter 13. ai_review_lab 최종 자동 검증
-- 실행 순서: 01→02→03→04→05→06→07→08
-- 07과 08은 같은 PostgreSQL 세션에서 이어서 실행해야 합니다.
-- 07의 임시 테스트 증거 30/30이 없으면 이 파일은 최종 통과로 처리하지 않습니다.

SELECT current_database();
SELECT current_schema();
SHOW search_path;

DO $$
BEGIN
    IF current_database() <> 'ai_database_book' THEN
        RAISE EXCEPTION
            '최종 검증 중단: 현재 데이터베이스는 %입니다.',
            current_database();
    END IF;

    IF to_regclass('course_project.students') IS NULL
       OR to_regclass('course_project.instructors') IS NULL
       OR to_regclass('course_project.courses') IS NULL
       OR to_regclass('course_project.enrollments') IS NULL
       OR to_regclass('ai_review_lab.bad_enrollments') IS NULL
       OR to_regclass('ai_review_lab.students') IS NULL
       OR to_regclass('ai_review_lab.instructors') IS NULL
       OR to_regclass('ai_review_lab.courses') IS NULL
       OR to_regclass('ai_review_lab.enrollments') IS NULL
       OR to_regclass('ai_review_lab.payments') IS NULL THEN
        RAISE EXCEPTION
            '최종 검증 중단: Chapter 07 또는 ai_review_lab 핵심 테이블이 없습니다.';
    END IF;

    IF to_regclass('pg_temp.negative_test_results') IS NULL THEN
        RAISE EXCEPTION
            '최종 검증 중단: 07의 임시 테스트 증거가 없습니다. 07과 08을 같은 세션에서 순서대로 실행하세요.';
    END IF;
END
$$;

-- ============================================================
-- P13-V08-1. 기준 행과 JOIN
-- ============================================================
SELECT
    (SELECT COUNT(*) FROM course_project.enrollments) AS source_enrollments,
    (SELECT SUM(recorded_amount) FROM course_project.enrollments) AS source_recorded_amount,
    (SELECT COUNT(*) FROM ai_review_lab.bad_enrollments) AS bad_rows,
    (SELECT COUNT(*) FROM ai_review_lab.students) AS students,
    (SELECT COUNT(*) FROM ai_review_lab.instructors) AS instructors,
    (SELECT COUNT(*) FROM ai_review_lab.courses) AS courses,
    (SELECT COUNT(*) FROM ai_review_lab.enrollments) AS enrollments,
    (SELECT COUNT(*) FROM ai_review_lab.payments) AS payments,
    (SELECT SUM(recorded_amount) FROM ai_review_lab.enrollments) AS lab_recorded_amount,
    (SELECT SUM(amount) FROM ai_review_lab.payments) AS lab_payment_amount,
    (
        SELECT COUNT(*)
        FROM ai_review_lab.enrollments AS e
        JOIN ai_review_lab.students AS s ON s.id = e.student_id
        JOIN ai_review_lab.courses AS c ON c.id = e.course_id
        JOIN ai_review_lab.instructors AS i ON i.id = c.instructor_id
        LEFT JOIN ai_review_lab.payments AS p ON p.enrollment_id = e.id
    ) AS joined_rows;

-- ============================================================
-- P13-V08-2. IDENTITY 시퀀스 다음 값
-- 다음 값은 기존 최대 ID보다 커야 합니다.
-- ============================================================
SELECT
    'bad_enrollments' AS table_name,
    CASE WHEN is_called THEN last_value + 1 ELSE last_value END AS next_value,
    (SELECT MAX(id) FROM ai_review_lab.bad_enrollments) AS max_id
FROM ai_review_lab.bad_enrollments_id_seq
UNION ALL
SELECT
    'students',
    CASE WHEN is_called THEN last_value + 1 ELSE last_value END,
    (SELECT MAX(id) FROM ai_review_lab.students)
FROM ai_review_lab.students_id_seq
UNION ALL
SELECT
    'instructors',
    CASE WHEN is_called THEN last_value + 1 ELSE last_value END,
    (SELECT MAX(id) FROM ai_review_lab.instructors)
FROM ai_review_lab.instructors_id_seq
UNION ALL
SELECT
    'courses',
    CASE WHEN is_called THEN last_value + 1 ELSE last_value END,
    (SELECT MAX(id) FROM ai_review_lab.courses)
FROM ai_review_lab.courses_id_seq
UNION ALL
SELECT
    'enrollments',
    CASE WHEN is_called THEN last_value + 1 ELSE last_value END,
    (SELECT MAX(id) FROM ai_review_lab.enrollments)
FROM ai_review_lab.enrollments_id_seq
UNION ALL
SELECT
    'payments',
    CASE WHEN is_called THEN last_value + 1 ELSE last_value END,
    (SELECT MAX(id) FROM ai_review_lab.payments)
FROM ai_review_lab.payments_id_seq;

-- ============================================================
-- P13-V08-3. 최종 자동 판정
-- ============================================================
DO $$
DECLARE
    actual_tables TEXT[];
    expected_tables CONSTANT TEXT[] := ARRAY[
        'bad_enrollments',
        'courses',
        'enrollments',
        'instructors',
        'payments',
        'students'
    ];
    good_constraint_count INTEGER;
    fk_count INTEGER;
    identity_count INTEGER;
    money_type_count INTEGER;
    price_difference_count INTEGER;
    active_index_definition TEXT;
    bad_next BIGINT;
    students_next BIGINT;
    instructors_next BIGINT;
    courses_next BIGINT;
    enrollments_next BIGINT;
    payments_next BIGINT;
    temp_total INTEGER;
    temp_passed INTEGER;
    temp_unexpected INTEGER;
    temp_failure_count INTEGER;
    temp_success_count INTEGER;
    v_project_named_constraint_count BIGINT;
    v_project_not_null_count BIGINT;
BEGIN
    -- Chapter 07·08 canonical source 보호
    IF (SELECT COUNT(*) FROM course_project.students) <> 3
       OR (SELECT COUNT(*) FROM course_project.instructors) <> 2
       OR (SELECT COUNT(*) FROM course_project.courses) <> 3
       OR (SELECT COUNT(*) FROM course_project.enrollments) <> 5
       OR (SELECT COUNT(*) FROM course_project.enrollments WHERE status = '신청') <> 2
       OR (SELECT COUNT(*) FROM course_project.enrollments WHERE status = '수강중') <> 1
       OR (SELECT COUNT(*) FROM course_project.enrollments WHERE status = '완료') <> 1
       OR (SELECT COUNT(*) FROM course_project.enrollments WHERE status = '취소') <> 1
       OR (SELECT COALESCE(SUM(recorded_amount), 0) FROM course_project.enrollments) <> 590000
       OR (
            SELECT COUNT(*) FROM course_project.enrollments
            WHERE status IN ('신청','수강중')
       ) <> 3
       OR (
            SELECT COALESCE(SUM(recorded_amount), 0) FROM course_project.enrollments
            WHERE status IN ('신청','수강중')
       ) <> 340000
       OR (
            SELECT COUNT(*) FROM course_project.enrollments
            WHERE status <> '취소'
       ) <> 4
       OR (
            SELECT COALESCE(SUM(recorded_amount), 0) FROM course_project.enrollments
            WHERE status <> '취소'
       ) <> 440000 THEN
        RAISE EXCEPTION
            '최종 검증 실패: Chapter 07·08 canonical source가 변경되었습니다.';
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
            '최종 검증 실패: Chapter 07·08 핵심 신청 1001/1004/1005가 변경되었습니다.';
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = 'course_project'
          AND table_name = 'enrollments'
          AND column_name = 'recorded_amount'
          AND data_type = 'numeric'
          AND numeric_precision = 12
          AND numeric_scale = 0
    ) OR EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = 'course_project'
          AND table_name = 'enrollments'
          AND column_name = 'paid_amount'
    ) THEN
        RAISE EXCEPTION
            '최종 검증 실패: Chapter 07·08 recorded_amount 구조가 기준과 다릅니다.';
    END IF;

    IF to_regclass('course_project.uq_course_enrollments_active') IS NULL
       OR EXISTS (
            SELECT 1
            FROM course_project.enrollments
            WHERE status IN ('신청', '수강중')
            GROUP BY student_id, course_id
            HAVING COUNT(*) > 1
       ) THEN
        RAISE EXCEPTION
            '최종 검증 실패: Chapter 07 활성 신청 정책이 기준과 다릅니다.';
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
            '최종 검증 실패: Chapter 07 구조 기준과 다릅니다. named_constraints=%, not_null_columns=%',
            v_project_named_constraint_count, v_project_not_null_count;
    END IF;

    -- Chapter 13 기준 행·합계·상태
    IF (SELECT COUNT(*) FROM ai_review_lab.bad_enrollments) <> 3
       OR (SELECT COUNT(*) FROM ai_review_lab.students) <> 3
       OR (SELECT COUNT(*) FROM ai_review_lab.instructors) <> 2
       OR (SELECT COUNT(*) FROM ai_review_lab.courses) <> 3
       OR (SELECT COUNT(*) FROM ai_review_lab.enrollments) <> 4
       OR (SELECT COUNT(*) FROM ai_review_lab.payments) <> 4 THEN
        RAISE EXCEPTION
            '최종 검증 실패: 기준 행 수 3/3/2/3/4/4가 유지되지 않았습니다.';
    END IF;

    IF (SELECT COALESCE(SUM(recorded_amount), 0) FROM ai_review_lab.enrollments) <> 470000
       OR (SELECT COALESCE(SUM(amount), 0) FROM ai_review_lab.payments) <> 470000
       OR (SELECT COUNT(*) FROM ai_review_lab.enrollments WHERE status = '완료') <> 2
       OR (SELECT COUNT(*) FROM ai_review_lab.enrollments WHERE status = '신청') <> 1
       OR (SELECT COUNT(*) FROM ai_review_lab.enrollments WHERE status = '취소') <> 1
       OR (SELECT COUNT(*) FROM ai_review_lab.enrollments WHERE status = '수강중') <> 0
       OR (SELECT COUNT(*) FROM ai_review_lab.payments WHERE payment_status = '결제완료') <> 2
       OR (SELECT COUNT(*) FROM ai_review_lab.payments WHERE payment_status = '결제대기') <> 1
       OR (SELECT COUNT(*) FROM ai_review_lab.payments WHERE payment_status = '환불') <> 1
       OR (SELECT COUNT(*) FROM ai_review_lab.payments WHERE payment_status = '결제실패') <> 0 THEN
        RAISE EXCEPTION
            '최종 검증 실패: Chapter 13 금액 합계 또는 상태 분포가 기준과 다릅니다.';
    END IF;

    IF (
        SELECT COUNT(*)
        FROM ai_review_lab.enrollments AS e
        JOIN ai_review_lab.students AS s ON s.id = e.student_id
        JOIN ai_review_lab.courses AS c ON c.id = e.course_id
        JOIN ai_review_lab.instructors AS i ON i.id = c.instructor_id
        LEFT JOIN ai_review_lab.payments AS p ON p.enrollment_id = e.id
    ) <> 4 THEN
        RAISE EXCEPTION '최종 검증 실패: 정상 JOIN은 4행이어야 합니다.';
    END IF;

    SELECT array_agg(table_name ORDER BY table_name)
    INTO actual_tables
    FROM information_schema.tables
    WHERE table_schema = 'ai_review_lab';

    IF actual_tables IS DISTINCT FROM expected_tables THEN
        RAISE EXCEPTION
            '최종 검증 실패: 정확한 테이블 집합이 아닙니다. 실제=%',
            actual_tables;
    END IF;

    SELECT COUNT(*)
    INTO good_constraint_count
    FROM pg_constraint
    WHERE connamespace = 'ai_review_lab'::regnamespace
      AND conrelid IN (
          'ai_review_lab.students'::regclass,
          'ai_review_lab.instructors'::regclass,
          'ai_review_lab.courses'::regclass,
          'ai_review_lab.enrollments'::regclass,
          'ai_review_lab.payments'::regclass
      );

    SELECT COUNT(*)
    INTO fk_count
    FROM information_schema.table_constraints
    WHERE constraint_schema = 'ai_review_lab'
      AND constraint_type = 'FOREIGN KEY';

    SELECT COUNT(*)
    INTO identity_count
    FROM information_schema.columns
    WHERE table_schema = 'ai_review_lab'
      AND column_name = 'id'
      AND is_identity = 'YES';

    SELECT COUNT(*)
    INTO money_type_count
    FROM information_schema.columns
    WHERE table_schema = 'ai_review_lab'
      AND (
          (table_name = 'courses' AND column_name = 'price')
          OR (table_name = 'enrollments' AND column_name = 'recorded_amount')
          OR (table_name = 'payments' AND column_name = 'amount')
      )
      AND data_type = 'numeric'
      AND numeric_precision = 12
      AND numeric_scale = 0
      AND is_nullable = 'NO';

    IF good_constraint_count <> 29
       OR fk_count <> 4
       OR identity_count <> 6
       OR money_type_count <> 3
       OR to_regclass('ai_review_lab.uq_ai_review_enrollments_active') IS NULL THEN
        RAISE EXCEPTION
            '최종 검증 실패: constraints %, FK %, IDENTITY %, money %, active index %.',
            good_constraint_count,
            fk_count,
            identity_count,
            money_type_count,
            to_regclass('ai_review_lab.uq_ai_review_enrollments_active');
    END IF;

    IF EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = 'ai_review_lab'
          AND table_name = 'enrollments'
          AND column_name = 'agreed_amount'
    ) THEN
        RAISE EXCEPTION
            '최종 검증 실패: 이전 신청 금액 컬럼 이름이 남아 있습니다.';
    END IF;

    SELECT pg_get_indexdef('ai_review_lab.uq_ai_review_enrollments_active'::regclass)
    INTO active_index_definition;

    IF active_index_definition NOT LIKE '%student_id, course_id%'
       OR active_index_definition NOT LIKE '%WHERE%'
       OR active_index_definition NOT LIKE '%신청%'
       OR active_index_definition NOT LIKE '%수강중%' THEN
        RAISE EXCEPTION
            '최종 검증 실패: 활성 신청 부분 고유 인덱스 정의가 다릅니다.';
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
        RAISE EXCEPTION '최종 검증 실패: 필수 문자열 공백이 있습니다.';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM ai_review_lab.enrollments
        WHERE status IN ('신청', '수강중')
        GROUP BY student_id, course_id
        HAVING COUNT(*) > 1
    ) THEN
        RAISE EXCEPTION '최종 검증 실패: 활성 신청 중복이 있습니다.';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM ai_review_lab.enrollments AS e
        LEFT JOIN ai_review_lab.students AS s ON s.id = e.student_id
        LEFT JOIN ai_review_lab.courses AS c ON c.id = e.course_id
        WHERE s.id IS NULL OR c.id IS NULL
    ) OR EXISTS (
        SELECT 1
        FROM ai_review_lab.payments AS p
        LEFT JOIN ai_review_lab.enrollments AS e ON e.id = p.enrollment_id
        WHERE e.id IS NULL
    ) THEN
        RAISE EXCEPTION '최종 검증 실패: 고아 관계가 있습니다.';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM ai_review_lab.enrollments AS e
        JOIN ai_review_lab.payments AS p ON p.enrollment_id = e.id
        WHERE e.recorded_amount <> p.amount
    ) THEN
        RAISE EXCEPTION '최종 검증 실패: 신청 시점 기록 금액과 결제 상태 기록 금액이 다릅니다.';
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
        RAISE EXCEPTION '최종 검증 실패: 결제·환불 시각 조합이 잘못되었습니다.';
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
        RAISE EXCEPTION '최종 검증 실패: 샘플 상태 조합이 잘못되었습니다.';
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
            '최종 검증 실패: 정보용 가격 차이는 1002 한 행이어야 합니다. 실제=%',
            price_difference_count;
    END IF;

    IF EXISTS (
        SELECT 1
        FROM ai_review_lab.payments
        WHERE payment_reference NOT LIKE 'PAY-REVIEW-TEST-%'
    ) THEN
        RAISE EXCEPTION
            '최종 검증 실패: 기준 Seed의 결제 참조값은 가상 테스트 값이어야 합니다.';
    END IF;

    SELECT CASE WHEN is_called THEN last_value + 1 ELSE last_value END
    INTO bad_next FROM ai_review_lab.bad_enrollments_id_seq;
    SELECT CASE WHEN is_called THEN last_value + 1 ELSE last_value END
    INTO students_next FROM ai_review_lab.students_id_seq;
    SELECT CASE WHEN is_called THEN last_value + 1 ELSE last_value END
    INTO instructors_next FROM ai_review_lab.instructors_id_seq;
    SELECT CASE WHEN is_called THEN last_value + 1 ELSE last_value END
    INTO courses_next FROM ai_review_lab.courses_id_seq;
    SELECT CASE WHEN is_called THEN last_value + 1 ELSE last_value END
    INTO enrollments_next FROM ai_review_lab.enrollments_id_seq;
    SELECT CASE WHEN is_called THEN last_value + 1 ELSE last_value END
    INTO payments_next FROM ai_review_lab.payments_id_seq;

    IF bad_next <= (SELECT MAX(id) FROM ai_review_lab.bad_enrollments)
       OR students_next <= (SELECT MAX(id) FROM ai_review_lab.students)
       OR instructors_next <= (SELECT MAX(id) FROM ai_review_lab.instructors)
       OR courses_next <= (SELECT MAX(id) FROM ai_review_lab.courses)
       OR enrollments_next <= (SELECT MAX(id) FROM ai_review_lab.enrollments)
       OR payments_next <= (SELECT MAX(id) FROM ai_review_lab.payments) THEN
        RAISE EXCEPTION
            '최종 검증 실패: IDENTITY 다음 값이 기존 최대 ID보다 크지 않습니다.';
    END IF;

    SELECT
        COUNT(*),
        COUNT(*) FILTER (
            WHERE actual_result IN ('expected_failure', 'expected_success')
        ),
        COUNT(*) FILTER (
            WHERE actual_result LIKE 'unexpected%'
        ),
        COUNT(*) FILTER (
            WHERE expected_result = 'expected_failure'
        ),
        COUNT(*) FILTER (
            WHERE expected_result = 'expected_success'
        )
    INTO temp_total, temp_passed, temp_unexpected,
         temp_failure_count, temp_success_count
    FROM pg_temp.negative_test_results;

    IF temp_total <> 30
       OR temp_passed <> 30
       OR temp_unexpected <> 0
       OR temp_failure_count <> 24
       OR temp_success_count <> 6 THEN
        RAISE EXCEPTION
            '최종 검증 실패: 테스트 total %, passed %, unexpected %, failure %, success %.',
            temp_total, temp_passed, temp_unexpected,
            temp_failure_count, temp_success_count;
    END IF;

    RAISE NOTICE 'Chapter 13 AI review lab validation passed: tests 30/30';
END
$$;
