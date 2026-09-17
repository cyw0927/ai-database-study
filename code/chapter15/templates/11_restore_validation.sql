-- Chapter 15. 별도 복원 DB 검증
-- P15-V09: custom-format 백업을 별도 tutor_project_restore DB에 복원한 뒤 구조·데이터·owner·IDENTITY·분석 VIEW를 검증합니다.
-- tutor_project_restore에서만 실행합니다.

SELECT current_user AS current_user_name;
SELECT current_database();
SELECT current_schema();
SHOW search_path;
SELECT current_setting('server_version') AS postgresql_version;

DO $$
DECLARE
    object_count INTEGER;
    owner_mismatch_count INTEGER;
    anomaly_count BIGINT;
    students_next BIGINT;
    tutors_next BIGINT;
    questions_next BIGINT;
    answers_next BIGINT;
    materials_next BIGINT;
BEGIN
    IF current_database() <> 'tutor_project_restore' THEN
        RAISE EXCEPTION
            '복원 검증 중단: 현재 데이터베이스는 %입니다. tutor_project_restore에서 실행하세요.',
            current_database();
    END IF;

    IF to_regclass('tutor_project.students') IS NULL
       OR to_regclass('tutor_project.question_analysis_dataset') IS NULL
       OR to_regclass('tutor_project.student_question_summary') IS NULL
       OR to_regclass('tutor_project.tutor_answer_summary') IS NULL THEN
        RAISE EXCEPTION '복원 검증 실패: 핵심 테이블 또는 분석 VIEW가 없습니다.';
    END IF;

    IF (SELECT COUNT(*) FROM tutor_project.students) <> 4
       OR (SELECT COUNT(*) FROM tutor_project.tutors) <> 3
       OR (SELECT COUNT(*) FROM tutor_project.questions) <> 5
       OR (SELECT COUNT(*) FROM tutor_project.answers) <> 5
       OR (SELECT COUNT(*) FROM tutor_project.learning_materials) <> 6
       OR (SELECT COUNT(*) FROM tutor_project.question_materials) <> 7 THEN
        RAISE EXCEPTION '복원 검증 실패: 기준 행 수가 다릅니다.';
    END IF;

    SELECT COUNT(*) INTO object_count
    FROM pg_class AS c
    JOIN pg_namespace AS n ON n.oid = c.relnamespace
    WHERE n.nspname = 'tutor_project'
      AND c.relkind IN ('r', 'S', 'v');

    IF object_count <> 15 THEN
        RAISE EXCEPTION '복원 검증 실패: table·sequence·view 객체는 15개여야 하나 %개입니다.', object_count;
    END IF;

    SELECT COUNT(*) INTO owner_mismatch_count
    FROM pg_class AS c
    JOIN pg_namespace AS n ON n.oid = c.relnamespace
    WHERE n.nspname = 'tutor_project'
      AND c.relkind IN ('r', 'S', 'v')
      AND pg_get_userbyid(c.relowner) <> current_user;

    IF owner_mismatch_count <> 0
       OR (SELECT pg_get_userbyid(nspowner) FROM pg_namespace WHERE nspname = 'tutor_project') <> current_user THEN
        RAISE EXCEPTION '복원 검증 실패: --no-owner 복원 객체 소유자가 현재 복원 역할과 다릅니다.';
    END IF;

    IF (SELECT COUNT(*) FROM pg_constraint WHERE connamespace = 'tutor_project'::regnamespace) <> 36
       OR (SELECT COUNT(*) FROM pg_constraint WHERE connamespace = 'tutor_project'::regnamespace AND contype = 'f') <> 5
       OR (SELECT COUNT(*) FROM pg_indexes WHERE schemaname = 'tutor_project' AND indexname IN (
            'idx_tutor_project_questions_student_status_created',
            'idx_tutor_project_answers_question_created',
            'idx_tutor_project_qm_material'
          )) <> 3 THEN
        RAISE EXCEPTION '복원 검증 실패: 제약조건·FK·업무 인덱스가 다릅니다.';
    END IF;

    SELECT COUNT(*) INTO anomaly_count
    FROM (
        SELECT q.id::text AS anomaly
        FROM tutor_project.questions AS q
        JOIN tutor_project.students AS s ON s.id = q.student_id
        WHERE (q.created_at AT TIME ZONE 'Asia/Seoul')::date < s.joined_at
        UNION ALL
        SELECT a.id::text
        FROM tutor_project.answers AS a
        JOIN tutor_project.questions AS q ON q.id = a.question_id
        JOIN tutor_project.tutors AS t ON t.id = a.tutor_id
        WHERE a.created_at < q.created_at OR a.created_at < t.created_at
        UNION ALL
        SELECT (qm.question_id::text || ':' || qm.material_id::text)
        FROM tutor_project.question_materials AS qm
        JOIN tutor_project.questions AS q ON q.id = qm.question_id
        WHERE qm.created_at < q.created_at
    ) AS anomalies;

    IF anomaly_count <> 0 THEN
        RAISE EXCEPTION '복원 검증 실패: 시간 관계 이상이 %건 있습니다.', anomaly_count;
    END IF;

    IF (SELECT COUNT(*) FROM tutor_project.question_analysis_dataset) <> 5
       OR (SELECT SUM(answer_count) FROM tutor_project.question_analysis_dataset) <> 5
       OR (SELECT SUM(material_count) FROM tutor_project.question_analysis_dataset) <> 7
       OR (SELECT COUNT(*) FROM tutor_project.student_question_summary) <> 4
       OR (SELECT COUNT(*) FROM tutor_project.tutor_answer_summary) <> 3 THEN
        RAISE EXCEPTION '복원 검증 실패: 분석 VIEW 결과가 다릅니다.';
    END IF;

    SELECT CASE WHEN is_called THEN last_value + 1 ELSE last_value END INTO students_next FROM tutor_project.students_id_seq;
    SELECT CASE WHEN is_called THEN last_value + 1 ELSE last_value END INTO tutors_next FROM tutor_project.tutors_id_seq;
    SELECT CASE WHEN is_called THEN last_value + 1 ELSE last_value END INTO questions_next FROM tutor_project.questions_id_seq;
    SELECT CASE WHEN is_called THEN last_value + 1 ELSE last_value END INTO answers_next FROM tutor_project.answers_id_seq;
    SELECT CASE WHEN is_called THEN last_value + 1 ELSE last_value END INTO materials_next FROM tutor_project.learning_materials_id_seq;

    IF students_next <= 104 OR tutors_next <= 203 OR questions_next <= 305
       OR answers_next <= 405 OR materials_next <= 506 THEN
        RAISE EXCEPTION '복원 검증 실패: IDENTITY 다음 값이 최대 ID보다 크지 않습니다.';
    END IF;

    RAISE NOTICE 'Chapter 15 restore validation passed';
END
$$;

SELECT
    n.nspname AS schema_name,
    c.relname AS object_name,
    c.relkind,
    pg_get_userbyid(c.relowner) AS owner_name,
    c.relacl
FROM pg_class AS c
JOIN pg_namespace AS n ON n.oid = c.relnamespace
WHERE n.nspname = 'tutor_project'
  AND c.relkind IN ('r', 'S', 'v')
ORDER BY c.relkind, c.relname;

-- --no-privileges 복원 뒤 Role·GRANT를 재적용했다면 08_operations_checks.sql과 실제 허용·차단 시험을 별도로 수행합니다.
