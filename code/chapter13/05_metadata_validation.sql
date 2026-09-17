-- Chapter 13. 실제 PostgreSQL 메타데이터 검증
-- 실행 전 01→04 파일을 순서대로 실행합니다.
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
       OR (SELECT COUNT(*) FROM ai_review_lab.students) <> 3
       OR (SELECT COUNT(*) FROM ai_review_lab.instructors) <> 2
       OR (SELECT COUNT(*) FROM ai_review_lab.courses) <> 3
       OR (SELECT COUNT(*) FROM ai_review_lab.enrollments) <> 4
       OR (SELECT COUNT(*) FROM ai_review_lab.payments) <> 4 THEN
        RAISE EXCEPTION
            '검증 중단: 01→04 기준 상태가 준비되지 않았습니다.';
    END IF;
END
$$;

-- ============================================================
-- P13-V05-1. 정확한 테이블 집합
-- ============================================================
SELECT
    table_schema,
    table_name
FROM information_schema.tables
WHERE table_schema = 'ai_review_lab'
ORDER BY table_name;

-- ============================================================
-- P13-V05-2. 컬럼·타입·NULL·IDENTITY
-- ============================================================
SELECT
    table_name,
    ordinal_position,
    column_name,
    data_type,
    character_maximum_length,
    numeric_precision,
    numeric_scale,
    is_nullable,
    is_identity,
    identity_generation,
    column_default
FROM information_schema.columns
WHERE table_schema = 'ai_review_lab'
ORDER BY table_name, ordinal_position;

-- ============================================================
-- P13-V05-3. 제약조건 실제 정의
-- ============================================================
SELECT
    conrelid::regclass::text AS table_name,
    conname AS constraint_name,
    CASE contype
        WHEN 'p' THEN 'PRIMARY KEY'
        WHEN 'f' THEN 'FOREIGN KEY'
        WHEN 'u' THEN 'UNIQUE'
        WHEN 'c' THEN 'CHECK'
        ELSE contype::text
    END AS constraint_type,
    pg_get_constraintdef(oid) AS constraint_definition
FROM pg_constraint
WHERE connamespace = 'ai_review_lab'::regnamespace
ORDER BY conrelid::regclass::text, contype, conname;

-- ============================================================
-- P13-V05-4. 외래키 이름·출발·대상·삭제 규칙
-- 기대 4개, 모두 RESTRICT/NO ACTION 계열
-- ============================================================
SELECT
    tc.table_name AS source_table,
    kcu.column_name AS source_column,
    ccu.table_name AS target_table,
    ccu.column_name AS target_column,
    rc.delete_rule,
    rc.update_rule,
    tc.constraint_name
FROM information_schema.table_constraints AS tc
JOIN information_schema.key_column_usage AS kcu
    ON kcu.constraint_schema = tc.constraint_schema
   AND kcu.constraint_name = tc.constraint_name
JOIN information_schema.constraint_column_usage AS ccu
    ON ccu.constraint_schema = tc.constraint_schema
   AND ccu.constraint_name = tc.constraint_name
JOIN information_schema.referential_constraints AS rc
    ON rc.constraint_schema = tc.constraint_schema
   AND rc.constraint_name = tc.constraint_name
WHERE tc.constraint_schema = 'ai_review_lab'
  AND tc.constraint_type = 'FOREIGN KEY'
ORDER BY source_table, source_column;

-- ============================================================
-- P13-V05-5. 자동·수동 인덱스와 활성 신청 정책
-- ============================================================
SELECT
    tablename,
    indexname,
    indexdef
FROM pg_indexes
WHERE schemaname = 'ai_review_lab'
ORDER BY tablename, indexname;

-- ============================================================
-- P13-R08 보안 증거
-- 컬럼명 검사만으로 카드정보 미저장을 완전히 증명할 수는 없습니다.
-- 전용 카드정보 컬럼 부재와 payment_reference 의미·Seed·로그·앱 흐름을 함께 검토합니다.
-- payment_reference도 실제 시스템에서는 조직 정책에 따라 보호 대상이 될 수 있습니다.
-- ============================================================
SELECT
    table_name,
    column_name
FROM information_schema.columns
WHERE table_schema = 'ai_review_lab'
  AND table_name IN (
      'students',
      'instructors',
      'courses',
      'enrollments',
      'payments'
  )
  AND lower(column_name) SIMILAR TO '%(card|password|secret|token|pan|cvv)%'
ORDER BY table_name, column_name;

-- ============================================================
-- P13-V05-6. 전체 자동 판정
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
    fk_signature_count INTEGER;
    good_constraint_count INTEGER;
    identity_count INTEGER;
    money_type_count INTEGER;
    recorded_amount_count INTEGER;
    active_index_definition TEXT;
BEGIN
    SELECT array_agg(table_name ORDER BY table_name)
    INTO actual_tables
    FROM information_schema.tables
    WHERE table_schema = 'ai_review_lab';

    IF actual_tables IS DISTINCT FROM expected_tables THEN
        RAISE EXCEPTION
            '메타데이터 검증 실패: 테이블 집합이 다릅니다. 실제=%',
            actual_tables;
    END IF;

    SELECT COUNT(*)
    INTO fk_signature_count
    FROM (
        SELECT
            tc.constraint_name,
            tc.table_name AS source_table,
            kcu.column_name AS source_column,
            ccu.table_name AS target_table,
            ccu.column_name AS target_column,
            rc.delete_rule
        FROM information_schema.table_constraints AS tc
        JOIN information_schema.key_column_usage AS kcu
            ON kcu.constraint_schema = tc.constraint_schema
           AND kcu.constraint_name = tc.constraint_name
        JOIN information_schema.constraint_column_usage AS ccu
            ON ccu.constraint_schema = tc.constraint_schema
           AND ccu.constraint_name = tc.constraint_name
        JOIN information_schema.referential_constraints AS rc
            ON rc.constraint_schema = tc.constraint_schema
           AND rc.constraint_name = tc.constraint_name
        WHERE tc.constraint_schema = 'ai_review_lab'
          AND tc.constraint_type = 'FOREIGN KEY'
          AND (
              (tc.constraint_name = 'fk_ai_review_courses_instructor'
               AND tc.table_name = 'courses'
               AND kcu.column_name = 'instructor_id'
               AND ccu.table_name = 'instructors'
               AND ccu.column_name = 'id')
           OR (tc.constraint_name = 'fk_ai_review_enrollments_student'
               AND tc.table_name = 'enrollments'
               AND kcu.column_name = 'student_id'
               AND ccu.table_name = 'students'
               AND ccu.column_name = 'id')
           OR (tc.constraint_name = 'fk_ai_review_enrollments_course'
               AND tc.table_name = 'enrollments'
               AND kcu.column_name = 'course_id'
               AND ccu.table_name = 'courses'
               AND ccu.column_name = 'id')
           OR (tc.constraint_name = 'fk_ai_review_payments_enrollment'
               AND tc.table_name = 'payments'
               AND kcu.column_name = 'enrollment_id'
               AND ccu.table_name = 'enrollments'
               AND ccu.column_name = 'id')
          )
          AND rc.delete_rule IN ('RESTRICT', 'NO ACTION')
    ) AS expected_fks;

    IF fk_signature_count <> 4 THEN
        RAISE EXCEPTION
            '메타데이터 검증 실패: 정확한 FK 관계는 4개여야 합니다. 실제=%',
            fk_signature_count;
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

    IF good_constraint_count <> 29 THEN
        RAISE EXCEPTION
            '메타데이터 검증 실패: 좋은 설계 제약조건은 29개여야 합니다. 실제=%',
            good_constraint_count;
    END IF;

    SELECT COUNT(*)
    INTO identity_count
    FROM information_schema.columns
    WHERE table_schema = 'ai_review_lab'
      AND column_name = 'id'
      AND is_identity = 'YES';

    IF identity_count <> 6 THEN
        RAISE EXCEPTION
            '메타데이터 검증 실패: IDENTITY 기본키는 6개여야 합니다. 실제=%',
            identity_count;
    END IF;

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

    IF money_type_count <> 3 THEN
        RAISE EXCEPTION
            '메타데이터 검증 실패: price/recorded_amount/payment amount는 모두 NUMERIC(12,0) NOT NULL이어야 합니다.';
    END IF;

    SELECT COUNT(*)
    INTO recorded_amount_count
    FROM information_schema.columns
    WHERE table_schema = 'ai_review_lab'
      AND table_name = 'enrollments'
      AND column_name = 'recorded_amount';

    IF recorded_amount_count <> 1
       OR EXISTS (
            SELECT 1
            FROM information_schema.columns
            WHERE table_schema = 'ai_review_lab'
              AND table_name = 'enrollments'
              AND column_name = 'agreed_amount'
       ) THEN
        RAISE EXCEPTION
            '메타데이터 검증 실패: 신청 시점 금액 컬럼은 recorded_amount 하나여야 합니다.';
    END IF;

    IF to_regclass('ai_review_lab.uq_ai_review_enrollments_active') IS NULL THEN
        RAISE EXCEPTION
            '메타데이터 검증 실패: 활성 신청 부분 고유 인덱스가 없습니다.';
    END IF;

    SELECT pg_get_indexdef('ai_review_lab.uq_ai_review_enrollments_active'::regclass)
    INTO active_index_definition;

    IF active_index_definition NOT LIKE '%student_id, course_id%'
       OR active_index_definition NOT LIKE '%WHERE%'
       OR active_index_definition NOT LIKE '%신청%'
       OR active_index_definition NOT LIKE '%수강중%' THEN
        RAISE EXCEPTION
            '메타데이터 검증 실패: 활성 신청 부분 고유 인덱스 정의가 기대와 다릅니다. 실제=%',
            active_index_definition;
    END IF;

    IF EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = 'ai_review_lab'
          AND table_name IN ('students','instructors','courses','enrollments','payments')
          AND lower(column_name) SIMILAR TO '%(card|password|secret|token|pan|cvv)%'
    ) THEN
        RAISE EXCEPTION
            '메타데이터 검증 실패: 카드정보·비밀 전용 컬럼 이름이 발견되었습니다.';
    END IF;

    RAISE NOTICE 'Chapter 13 metadata validation passed';
END
$$;
