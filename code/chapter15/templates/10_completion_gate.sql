-- Chapter 15. 데이터베이스 완료 게이트
-- P15-V08: 구조·기준 데이터·트랜잭션·반례·분석 결과를 다시 실행해 판정합니다.
-- 모든 시험 변경은 마지막 ROLLBACK으로 취소됩니다.

SELECT current_user AS current_user_name;
SELECT current_database();
SELECT current_schema();
SHOW search_path;

DO $$
BEGIN
    IF current_database() <> 'ai_database_book' THEN
        RAISE EXCEPTION '완료 게이트 중단: 현재 데이터베이스는 %입니다.', current_database();
    END IF;

    IF to_regclass('tutor_project.question_analysis_dataset') IS NULL
       OR to_regclass('tutor_project.student_question_summary') IS NULL
       OR to_regclass('tutor_project.tutor_answer_summary') IS NULL
       OR to_regclass('tutor_project.analysis_parameters') IS NULL THEN
        RAISE EXCEPTION '완료 게이트 중단: 09_analysis_dataset.sql까지 실행하세요.';
    END IF;
END
$$;

BEGIN;

CREATE OR REPLACE FUNCTION pg_temp.expected_failure(
    p_statement TEXT,
    p_sqlstate TEXT,
    p_constraint TEXT
) RETURNS BOOLEAN
LANGUAGE plpgsql
AS $$
DECLARE
    v_sqlstate TEXT;
    v_constraint TEXT;
BEGIN
    BEGIN
        EXECUTE p_statement;
        RETURN FALSE;
    EXCEPTION WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS
            v_sqlstate = RETURNED_SQLSTATE,
            v_constraint = CONSTRAINT_NAME;
        RETURN v_sqlstate = p_sqlstate
           AND (p_constraint IS NULL OR v_constraint = p_constraint);
    END;
END
$$;

-- P15-T01을 게이트 안에서 재검증하고 예외로 하위 트랜잭션을 되돌립니다.
DO $$
DECLARE
    updated_rows INTEGER;
BEGIN
    BEGIN
        INSERT INTO tutor_project.answers(id, question_id, tutor_id, answer_body, created_at)
        VALUES(9991, 303, 201, '완료 게이트 트랜잭션 답변', TIMESTAMPTZ '2026-05-20 16:00:00+09');

        UPDATE tutor_project.questions
        SET status = 'answered', updated_at = TIMESTAMPTZ '2026-05-20 16:00:00+09'
        WHERE id = 303 AND status = 'open';
        GET DIAGNOSTICS updated_rows = ROW_COUNT;

        IF updated_rows <> 1
           OR (SELECT COUNT(*) FROM tutor_project.answers) <> 6
           OR (SELECT status FROM tutor_project.questions WHERE id = 303) IS DISTINCT FROM 'answered' THEN
            RAISE EXCEPTION '게이트 트랜잭션 내부 상태 실패';
        END IF;

        RAISE EXCEPTION USING ERRCODE = 'P1599', MESSAGE = 'rollback marker';
    EXCEPTION WHEN SQLSTATE 'P1599' THEN
        NULL;
    END;

    IF (SELECT COUNT(*) FROM tutor_project.answers) <> 5
       OR (SELECT status FROM tutor_project.questions WHERE id = 303) IS DISTINCT FROM 'open'
       OR EXISTS (SELECT 1 FROM tutor_project.answers WHERE id = 9991) THEN
        RAISE EXCEPTION '완료 게이트 실패: 트랜잭션 ROLLBACK 복구 실패.';
    END IF;
END
$$;

-- 핵심 실패 반례 14개를 게이트 안에서 다시 실행합니다.
DO $$
DECLARE
    passed_count INTEGER := 0;
BEGIN
    passed_count := passed_count + pg_temp.expected_failure(
        $sql$INSERT INTO tutor_project.students(id,name,email,joined_at) VALUES(9101,'중복','student.a@example.test',DATE '2026-05-01')$sql$, '23505', 'uq_tutor_project_students_email')::int;
    passed_count := passed_count + pg_temp.expected_failure(
        $sql$INSERT INTO tutor_project.tutors(id,name,email,specialty) VALUES(9201,'중복','tutor.sql@example.test','SQL')$sql$, '23505', 'uq_tutor_project_tutors_email')::int;
    passed_count := passed_count + pg_temp.expected_failure(
        $sql$INSERT INTO tutor_project.questions(id,student_id,question_code,title,body,status) VALUES(9301,999999,'NEG-Q-01','없는 학생','FK','open')$sql$, '23503', 'fk_tutor_project_questions_student')::int;
    passed_count := passed_count + pg_temp.expected_failure(
        $sql$INSERT INTO tutor_project.questions(id,student_id,question_code,title,body,status) VALUES(9302,101,'NEG-Q-02','상태','CHECK','waiting')$sql$, '23514', 'chk_tutor_project_questions_status')::int;
    passed_count := passed_count + pg_temp.expected_failure(
        $sql$INSERT INTO tutor_project.questions(id,student_id,question_code,title,body,status) VALUES(9303,101,'NEG-Q-03','   ','빈 제목','open')$sql$, '23514', 'chk_tutor_project_questions_title')::int;
    passed_count := passed_count + pg_temp.expected_failure(
        $sql$INSERT INTO tutor_project.answers(id,question_id,tutor_id,answer_body) VALUES(9401,999999,201,'없는 질문')$sql$, '23503', 'fk_tutor_project_answers_question')::int;
    passed_count := passed_count + pg_temp.expected_failure(
        $sql$INSERT INTO tutor_project.answers(id,question_id,tutor_id,answer_body) VALUES(9402,303,999999,'없는 튜터')$sql$, '23503', 'fk_tutor_project_answers_tutor')::int;
    passed_count := passed_count + pg_temp.expected_failure(
        $sql$INSERT INTO tutor_project.answers(id,question_id,tutor_id,answer_body) VALUES(9403,303,201,'   ')$sql$, '23514', 'chk_tutor_project_answers_body')::int;
    passed_count := passed_count + pg_temp.expected_failure(
        $sql$INSERT INTO tutor_project.learning_materials(id,material_code,title,material_type,content_summary,access_scope,source_version,content_hash) VALUES(9501,'NEG-M-01','유형','audio','오류','public','v1','demo')$sql$, '23514', 'chk_tutor_project_materials_type')::int;
    passed_count := passed_count + pg_temp.expected_failure(
        $sql$INSERT INTO tutor_project.learning_materials(id,material_code,title,material_type,content_summary,access_scope,source_version,content_hash) VALUES(9502,'NEG-M-02','범위','document','오류','secret','v1','demo')$sql$, '23514', 'chk_tutor_project_materials_scope')::int;
    passed_count := passed_count + pg_temp.expected_failure(
        $sql$INSERT INTO tutor_project.question_materials(question_id,material_id,display_order) VALUES(303,999999,2)$sql$, '23503', 'fk_tutor_project_qm_material')::int;
    passed_count := passed_count + pg_temp.expected_failure(
        $sql$INSERT INTO tutor_project.question_materials(question_id,material_id,display_order) VALUES(303,505,0)$sql$, '23514', 'chk_tutor_project_qm_display_order')::int;
    passed_count := passed_count + pg_temp.expected_failure(
        $sql$INSERT INTO tutor_project.question_materials(question_id,material_id,display_order) VALUES(301,501,3)$sql$, '23505', 'pk_tutor_project_question_materials')::int;
    passed_count := passed_count + pg_temp.expected_failure(
        $sql$INSERT INTO tutor_project.question_materials(question_id,material_id,display_order) VALUES(301,503,1)$sql$, '23505', 'uq_tutor_project_qm_display_order')::int;

    IF passed_count <> 14 THEN
        RAISE EXCEPTION '완료 게이트 실패: 핵심 반례 통과 수는 14여야 하나 %입니다.', passed_count;
    END IF;
END
$$;

DO $$
DECLARE
    table_count INTEGER;
    view_count INTEGER;
    constraint_count INTEGER;
    fk_count INTEGER;
    identity_count INTEGER;
    index_count INTEGER;
    anomaly_count BIGINT;
    students_next BIGINT;
    tutors_next BIGINT;
    questions_next BIGINT;
    answers_next BIGINT;
    materials_next BIGINT;
BEGIN
    SELECT COUNT(*) INTO table_count
    FROM information_schema.tables
    WHERE table_schema = 'tutor_project' AND table_type = 'BASE TABLE';

    SELECT COUNT(*) INTO view_count
    FROM information_schema.views
    WHERE table_schema = 'tutor_project'
      AND table_name IN (
          'analysis_parameters',
          'question_analysis_dataset',
          'student_question_summary',
          'tutor_answer_summary'
      );

    SELECT COUNT(*) INTO constraint_count
    FROM pg_constraint
    WHERE connamespace = 'tutor_project'::regnamespace;

    SELECT COUNT(*) INTO fk_count
    FROM pg_constraint
    WHERE connamespace = 'tutor_project'::regnamespace AND contype = 'f';

    SELECT COUNT(*) INTO identity_count
    FROM information_schema.columns
    WHERE table_schema = 'tutor_project'
      AND column_name = 'id'
      AND is_identity = 'YES';

    SELECT COUNT(*) INTO index_count
    FROM pg_indexes
    WHERE schemaname = 'tutor_project'
      AND indexname IN (
          'idx_tutor_project_questions_student_status_created',
          'idx_tutor_project_answers_question_created',
          'idx_tutor_project_qm_material'
      );

    IF table_count <> 6 OR view_count <> 4 OR constraint_count <> 36
       OR fk_count <> 5 OR identity_count <> 5 OR index_count <> 3 THEN
        RAISE EXCEPTION
            '완료 게이트 실패: tables %, views %, constraints %, FK %, identity %, indexes %.',
            table_count, view_count, constraint_count, fk_count, identity_count, index_count;
    END IF;

    IF (SELECT COUNT(*) FROM tutor_project.students) <> 4
       OR (SELECT COUNT(*) FROM tutor_project.tutors) <> 3
       OR (SELECT COUNT(*) FROM tutor_project.questions) <> 5
       OR (SELECT COUNT(*) FROM tutor_project.answers) <> 5
       OR (SELECT COUNT(*) FROM tutor_project.learning_materials) <> 6
       OR (SELECT COUNT(*) FROM tutor_project.question_materials) <> 7 THEN
        RAISE EXCEPTION '완료 게이트 실패: 기준 행 수가 다릅니다.';
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
        UNION ALL
        SELECT q.id::text
        FROM tutor_project.questions AS q
        LEFT JOIN tutor_project.answers AS a ON a.question_id = q.id
        WHERE q.status = 'answered'
        GROUP BY q.id
        HAVING COUNT(a.id) = 0
    ) AS anomalies;

    IF anomaly_count <> 0 THEN
        RAISE EXCEPTION '완료 게이트 실패: 업무·시간 이상이 %건 있습니다.', anomaly_count;
    END IF;

    IF (SELECT COUNT(*) FROM tutor_project.question_analysis_dataset) <> 5
       OR (SELECT COUNT(DISTINCT question_id) FROM tutor_project.question_analysis_dataset) <> 5
       OR (SELECT SUM(answer_count) FROM tutor_project.question_analysis_dataset) <> 5
       OR (SELECT SUM(material_count) FROM tutor_project.question_analysis_dataset) <> 7
       OR (SELECT COUNT(*) FROM tutor_project.student_question_summary) <> 4
       OR (SELECT COUNT(*) FROM tutor_project.student_question_summary WHERE question_count = 0) <> 1
       OR (SELECT COUNT(*) FROM tutor_project.tutor_answer_summary) <> 3
       OR (SELECT SUM(answer_count) FROM tutor_project.tutor_answer_summary) <> 5 THEN
        RAISE EXCEPTION '완료 게이트 실패: 분석 VIEW 기준값이 다릅니다.';
    END IF;

    IF (SELECT COUNT(*) FROM tutor_project.question_analysis_dataset WHERE status = 'answered') <> 3
       OR (SELECT COUNT(*) FROM tutor_project.question_analysis_dataset WHERE status = 'open') <> 1
       OR (SELECT COUNT(*) FROM tutor_project.question_analysis_dataset WHERE status = 'closed') <> 1
       OR (SELECT ROUND(AVG(first_response_hours) FILTER (WHERE has_answer), 2) FROM tutor_project.question_analysis_dataset) <> 2.00
       OR EXISTS (SELECT 1 FROM tutor_project.question_analysis_dataset WHERE first_response_hours < 0) THEN
        RAISE EXCEPTION '완료 게이트 실패: 상태 또는 첫 답변 시간 기준값이 다릅니다.';
    END IF;

    IF (
        SELECT COUNT(*)
        FROM (
            SELECT question_month, COUNT(*) AS cnt
            FROM tutor_project.question_analysis_dataset
            GROUP BY question_month
            HAVING COUNT(*) = 1
        ) AS monthly
    ) <> 5 THEN
        RAISE EXCEPTION '완료 게이트 실패: 2026년 1~5월 월별 질문은 각 1건이어야 합니다.';
    END IF;

    SELECT CASE WHEN is_called THEN last_value + 1 ELSE last_value END INTO students_next FROM tutor_project.students_id_seq;
    SELECT CASE WHEN is_called THEN last_value + 1 ELSE last_value END INTO tutors_next FROM tutor_project.tutors_id_seq;
    SELECT CASE WHEN is_called THEN last_value + 1 ELSE last_value END INTO questions_next FROM tutor_project.questions_id_seq;
    SELECT CASE WHEN is_called THEN last_value + 1 ELSE last_value END INTO answers_next FROM tutor_project.answers_id_seq;
    SELECT CASE WHEN is_called THEN last_value + 1 ELSE last_value END INTO materials_next FROM tutor_project.learning_materials_id_seq;

    IF students_next <= 104 OR tutors_next <= 203 OR questions_next <= 305
       OR answers_next <= 405 OR materials_next <= 506 THEN
        RAISE EXCEPTION '완료 게이트 실패: IDENTITY 다음 값이 최대 ID보다 크지 않습니다.';
    END IF;

    IF EXISTS (
        SELECT 1 FROM information_schema.referential_constraints
        WHERE constraint_schema = 'tutor_project' AND delete_rule = 'CASCADE'
    ) OR EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'tutor_project'
          AND lower(column_name) SIMILAR TO '%(password|secret|token|card|resident|ssn)%'
    ) OR EXISTS (
        SELECT 1 FROM tutor_project.students WHERE email NOT LIKE '%@example.test'
    ) OR EXISTS (
        SELECT 1 FROM tutor_project.tutors WHERE email NOT LIKE '%@example.test'
    ) THEN
        RAISE EXCEPTION '완료 게이트 실패: 삭제 정책 또는 가상 데이터 보안 기준 위반.';
    END IF;

    RAISE NOTICE 'Chapter 15 database completion gate passed';
END
$$;

ROLLBACK;

-- 이 통과는 DB 구조·데이터·SQL 검증을 의미합니다.
-- Python 실제 교차 검증, Role 시험, 백업·복원 시험과 문서 승인은 별도 증거로 기록합니다.
