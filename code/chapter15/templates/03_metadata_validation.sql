-- Chapter 15. tutor_project 실제 메타데이터 검증
-- P15-V03: 문서의 개수가 아니라 PostgreSQL 카탈로그의 정확한 객체 정의를 검증합니다.
-- 데이터를 변경하지 않습니다.

SELECT current_database();
SELECT current_schema();
SHOW search_path;

DO $$
BEGIN
    IF current_database() <> 'ai_database_book' THEN
        RAISE EXCEPTION '검증 중단: 현재 데이터베이스는 %입니다.', current_database();
    END IF;
    IF to_regnamespace('tutor_project') IS NULL THEN
        RAISE EXCEPTION '검증 중단: tutor_project 스키마가 없습니다.';
    END IF;
END
$$;

-- 실제 테이블·VIEW·컬럼·제약조건·인덱스를 사람이 확인하는 조회
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'tutor_project'
  AND table_type = 'BASE TABLE'
ORDER BY table_name;

SELECT table_name
FROM information_schema.views
WHERE table_schema = 'tutor_project'
ORDER BY table_name;

SELECT
    table_name,
    ordinal_position,
    column_name,
    data_type,
    is_nullable,
    is_identity,
    identity_generation,
    column_default
FROM information_schema.columns
WHERE table_schema = 'tutor_project'
ORDER BY table_name, ordinal_position;

SELECT
    conrelid::regclass::text AS table_name,
    conname AS constraint_name,
    contype AS constraint_type,
    pg_get_constraintdef(oid) AS constraint_definition
FROM pg_constraint
WHERE connamespace = 'tutor_project'::regnamespace
ORDER BY conrelid::regclass::text, contype, conname;

SELECT tablename, indexname, indexdef
FROM pg_indexes
WHERE schemaname = 'tutor_project'
ORDER BY tablename, indexname;

-- 정확한 구조 자동 판정
DO $$
DECLARE
    table_difference_count INTEGER;
    missing_constraint_count INTEGER;
    foreign_key_mismatch_count INTEGER;
    identity_pk_count INTEGER;
    business_index_count INTEGER;
    sensitive_column_count INTEGER;
BEGIN
    WITH expected(table_name) AS (
        VALUES
            ('students'),
            ('tutors'),
            ('questions'),
            ('answers'),
            ('learning_materials'),
            ('question_materials')
    ), actual AS (
        SELECT table_name
        FROM information_schema.tables
        WHERE table_schema = 'tutor_project'
          AND table_type = 'BASE TABLE'
    ), differences AS (
        (SELECT table_name FROM expected EXCEPT SELECT table_name FROM actual)
        UNION ALL
        (SELECT table_name FROM actual EXCEPT SELECT table_name FROM expected)
    )
    SELECT COUNT(*) INTO table_difference_count FROM differences;

    IF table_difference_count <> 0 THEN
        RAISE EXCEPTION '메타데이터 검증 실패: 기대 테이블 집합과 실제 테이블 집합이 다릅니다.';
    END IF;

    WITH expected(constraint_name) AS (
        VALUES
            ('students_pkey'),
            ('uq_tutor_project_students_email'),
            ('chk_tutor_project_students_name'),
            ('chk_tutor_project_students_email'),
            ('tutors_pkey'),
            ('uq_tutor_project_tutors_email'),
            ('chk_tutor_project_tutors_name'),
            ('chk_tutor_project_tutors_email'),
            ('chk_tutor_project_tutors_specialty'),
            ('questions_pkey'),
            ('fk_tutor_project_questions_student'),
            ('uq_tutor_project_questions_code'),
            ('chk_tutor_project_questions_code'),
            ('chk_tutor_project_questions_title'),
            ('chk_tutor_project_questions_body'),
            ('chk_tutor_project_questions_status'),
            ('chk_tutor_project_questions_timestamps'),
            ('answers_pkey'),
            ('fk_tutor_project_answers_question'),
            ('fk_tutor_project_answers_tutor'),
            ('chk_tutor_project_answers_body'),
            ('learning_materials_pkey'),
            ('uq_tutor_project_materials_code'),
            ('chk_tutor_project_materials_code'),
            ('chk_tutor_project_materials_title'),
            ('chk_tutor_project_materials_summary'),
            ('chk_tutor_project_materials_type'),
            ('chk_tutor_project_materials_scope'),
            ('chk_tutor_project_materials_version'),
            ('chk_tutor_project_materials_hash'),
            ('chk_tutor_project_materials_url'),
            ('pk_tutor_project_question_materials'),
            ('fk_tutor_project_qm_question'),
            ('fk_tutor_project_qm_material'),
            ('uq_tutor_project_qm_display_order'),
            ('chk_tutor_project_qm_display_order')
    )
    SELECT COUNT(*) INTO missing_constraint_count
    FROM expected AS e
    LEFT JOIN pg_constraint AS c
        ON c.conname = e.constraint_name
       AND c.connamespace = 'tutor_project'::regnamespace
    WHERE c.oid IS NULL;

    IF missing_constraint_count <> 0 THEN
        RAISE EXCEPTION '메타데이터 검증 실패: 기대 제약조건이 %개 누락되었습니다.', missing_constraint_count;
    END IF;

    WITH expected(
        constraint_name, source_table, source_column, target_table, target_column
    ) AS (
        VALUES
            ('fk_tutor_project_questions_student', 'questions', 'student_id', 'students', 'id'),
            ('fk_tutor_project_answers_question', 'answers', 'question_id', 'questions', 'id'),
            ('fk_tutor_project_answers_tutor', 'answers', 'tutor_id', 'tutors', 'id'),
            ('fk_tutor_project_qm_question', 'question_materials', 'question_id', 'questions', 'id'),
            ('fk_tutor_project_qm_material', 'question_materials', 'material_id', 'learning_materials', 'id')
    ), actual AS (
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
        WHERE tc.constraint_schema = 'tutor_project'
          AND tc.constraint_type = 'FOREIGN KEY'
    )
    SELECT COUNT(*) INTO foreign_key_mismatch_count
    FROM expected AS e
    LEFT JOIN actual AS a
      ON a.constraint_name = e.constraint_name
     AND a.source_table = e.source_table
     AND a.source_column = e.source_column
     AND a.target_table = e.target_table
     AND a.target_column = e.target_column
     AND a.delete_rule IN ('RESTRICT', 'NO ACTION')
    WHERE a.constraint_name IS NULL;

    IF foreign_key_mismatch_count <> 0
       OR (SELECT COUNT(*) FROM pg_constraint WHERE connamespace = 'tutor_project'::regnamespace AND contype = 'f') <> 5 THEN
        RAISE EXCEPTION '메타데이터 검증 실패: FK 이름·컬럼·대상·삭제 규칙이 기대와 다릅니다.';
    END IF;

    SELECT COUNT(*) INTO identity_pk_count
    FROM information_schema.columns AS col
    WHERE col.table_schema = 'tutor_project'
      AND col.column_name = 'id'
      AND col.is_identity = 'YES'
      AND col.table_name IN ('students', 'tutors', 'questions', 'answers', 'learning_materials')
      AND EXISTS (
          SELECT 1
          FROM information_schema.table_constraints AS tc
          JOIN information_schema.key_column_usage AS kcu
            ON kcu.constraint_schema = tc.constraint_schema
           AND kcu.constraint_name = tc.constraint_name
          WHERE tc.constraint_schema = 'tutor_project'
            AND tc.table_name = col.table_name
            AND tc.constraint_type = 'PRIMARY KEY'
            AND kcu.column_name = 'id'
      );

    IF identity_pk_count <> 5 THEN
        RAISE EXCEPTION '메타데이터 검증 실패: IDENTITY PK는 5개여야 합니다.';
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE connamespace = 'tutor_project'::regnamespace
          AND conname = 'pk_tutor_project_question_materials'
          AND pg_get_constraintdef(oid) = 'PRIMARY KEY (question_id, material_id)'
    ) THEN
        RAISE EXCEPTION '메타데이터 검증 실패: 연결 테이블 복합 PK 정의가 다릅니다.';
    END IF;

    SELECT COUNT(*) INTO business_index_count
    FROM pg_indexes
    WHERE schemaname = 'tutor_project'
      AND (
          (indexname = 'idx_tutor_project_questions_student_status_created'
           AND indexdef ILIKE '%USING btree (student_id, status, created_at DESC)%')
       OR (indexname = 'idx_tutor_project_answers_question_created'
           AND indexdef ILIKE '%USING btree (question_id, created_at)%')
       OR (indexname = 'idx_tutor_project_qm_material'
           AND indexdef ILIKE '%USING btree (material_id)%')
      );

    IF business_index_count <> 3 THEN
        RAISE EXCEPTION '메타데이터 검증 실패: 업무 인덱스 정의가 기대와 다릅니다.';
    END IF;

    SELECT COUNT(*) INTO sensitive_column_count
    FROM information_schema.columns
    WHERE table_schema = 'tutor_project'
      AND lower(column_name) SIMILAR TO '%(password|secret|token|card|resident|ssn)%';

    IF sensitive_column_count <> 0 THEN
        RAISE EXCEPTION '메타데이터 검증 실패: 민감정보 형태 컬럼이 %개 있습니다.', sensitive_column_count;
    END IF;

    IF to_regclass('tutor_project.analysis_parameters') IS NULL THEN
        RAISE EXCEPTION '메타데이터 검증 실패: 분석 기준 VIEW가 없습니다.';
    END IF;

    RAISE NOTICE 'P15-V03 metadata validation passed';
END
$$;
