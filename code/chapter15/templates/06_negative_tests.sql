-- Chapter 15. 자동 반례·정상 경계값 테스트
-- P15-T03~T25: SQLSTATE와 실제 제약조건 이름을 함께 기록합니다.
-- 모든 성공 테스트는 정리 SQL을 실행해 기준 데이터를 유지합니다.

SELECT current_database();
SELECT current_schema();
SHOW search_path;

DROP TABLE IF EXISTS pg_temp.project_test_results;
CREATE TEMP TABLE project_test_results (
    test_order INTEGER PRIMARY KEY,
    test_name TEXT NOT NULL,
    expected_sqlstate TEXT,
    actual_sqlstate TEXT,
    expected_constraint TEXT,
    actual_constraint TEXT,
    actual_table TEXT,
    actual_column TEXT,
    actual_result TEXT NOT NULL,
    detail TEXT
);

CREATE OR REPLACE FUNCTION pg_temp.run_project_test(
    p_order INTEGER,
    p_name TEXT,
    p_expected_sqlstate TEXT,
    p_expected_constraint TEXT,
    p_statement TEXT,
    p_cleanup TEXT DEFAULT NULL
) RETURNS VOID
LANGUAGE plpgsql
AS $$
DECLARE
    v_sqlstate TEXT;
    v_constraint TEXT;
    v_table TEXT;
    v_column TEXT;
    v_message TEXT;
BEGIN
    BEGIN
        EXECUTE p_statement;
        IF p_cleanup IS NOT NULL THEN
            EXECUTE p_cleanup;
        END IF;

        INSERT INTO pg_temp.project_test_results VALUES (
            p_order,
            p_name,
            p_expected_sqlstate,
            NULL,
            p_expected_constraint,
            NULL,
            NULL,
            NULL,
            CASE WHEN p_expected_sqlstate IS NULL
                 THEN 'expected_success'
                 ELSE 'unexpected_success'
            END,
            NULL
        );
    EXCEPTION WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS
            v_sqlstate = RETURNED_SQLSTATE,
            v_constraint = CONSTRAINT_NAME,
            v_table = TABLE_NAME,
            v_column = COLUMN_NAME,
            v_message = MESSAGE_TEXT;

        INSERT INTO pg_temp.project_test_results VALUES (
            p_order,
            p_name,
            p_expected_sqlstate,
            v_sqlstate,
            p_expected_constraint,
            NULLIF(v_constraint, ''),
            NULLIF(v_table, ''),
            NULLIF(v_column, ''),
            CASE
                WHEN p_expected_sqlstate IS NOT NULL
                 AND v_sqlstate = p_expected_sqlstate
                 AND (p_expected_constraint IS NULL OR v_constraint = p_expected_constraint)
                    THEN 'expected_failure'
                ELSE 'unexpected_error'
            END,
            v_message
        );
    END;
END
$$;

-- 실패 반례 18개
SELECT pg_temp.run_project_test(1, 'P15-T03 duplicate_student_email', '23505', 'uq_tutor_project_students_email',
    $sql$INSERT INTO tutor_project.students(id,name,email,joined_at) VALUES(9101,'중복학생','student.a@example.test',DATE '2026-05-01')$sql$);
SELECT pg_temp.run_project_test(2, 'P15-T04 duplicate_tutor_email', '23505', 'uq_tutor_project_tutors_email',
    $sql$INSERT INTO tutor_project.tutors(id,name,email,specialty) VALUES(9201,'중복튜터','tutor.sql@example.test','SQL')$sql$);
SELECT pg_temp.run_project_test(3, 'P15-T05 missing_student_fk', '23503', 'fk_tutor_project_questions_student',
    $sql$INSERT INTO tutor_project.questions(id,student_id,question_code,title,body,status) VALUES(9301,999999,'NEG-Q-01','없는 학생','FK 오류','open')$sql$);
SELECT pg_temp.run_project_test(4, 'P15-T06 invalid_question_status', '23514', 'chk_tutor_project_questions_status',
    $sql$INSERT INTO tutor_project.questions(id,student_id,question_code,title,body,status) VALUES(9302,101,'NEG-Q-02','잘못된 상태','CHECK 오류','waiting')$sql$);
SELECT pg_temp.run_project_test(5, 'P15-T07 blank_question_title', '23514', 'chk_tutor_project_questions_title',
    $sql$INSERT INTO tutor_project.questions(id,student_id,question_code,title,body,status) VALUES(9303,101,'NEG-Q-03','   ','빈 제목 오류','open')$sql$);
SELECT pg_temp.run_project_test(6, 'P15-T08 missing_question_fk', '23503', 'fk_tutor_project_answers_question',
    $sql$INSERT INTO tutor_project.answers(id,question_id,tutor_id,answer_body) VALUES(9401,999999,201,'없는 질문 답변')$sql$);
SELECT pg_temp.run_project_test(7, 'P15-T09 missing_tutor_fk', '23503', 'fk_tutor_project_answers_tutor',
    $sql$INSERT INTO tutor_project.answers(id,question_id,tutor_id,answer_body) VALUES(9402,303,999999,'없는 튜터 답변')$sql$);
SELECT pg_temp.run_project_test(8, 'P15-T10 blank_answer_body', '23514', 'chk_tutor_project_answers_body',
    $sql$INSERT INTO tutor_project.answers(id,question_id,tutor_id,answer_body) VALUES(9403,303,201,'   ')$sql$);
SELECT pg_temp.run_project_test(9, 'P15-T11 invalid_material_type', '23514', 'chk_tutor_project_materials_type',
    $sql$INSERT INTO tutor_project.learning_materials(id,material_code,title,material_type,content_summary,access_scope,source_version,content_hash) VALUES(9501,'NEG-M-01','잘못된 자료','audio','유형 오류','public','v1','demo-neg-01')$sql$);
SELECT pg_temp.run_project_test(10, 'P15-T12 invalid_access_scope', '23514', 'chk_tutor_project_materials_scope',
    $sql$INSERT INTO tutor_project.learning_materials(id,material_code,title,material_type,content_summary,access_scope,source_version,content_hash) VALUES(9502,'NEG-M-02','잘못된 범위','document','범위 오류','secret','v1','demo-neg-02')$sql$);
SELECT pg_temp.run_project_test(11, 'P15-T13 missing_material_fk', '23503', 'fk_tutor_project_qm_material',
    $sql$INSERT INTO tutor_project.question_materials(question_id,material_id,display_order) VALUES(303,999999,2)$sql$);
SELECT pg_temp.run_project_test(12, 'P15-T14 invalid_display_order', '23514', 'chk_tutor_project_qm_display_order',
    $sql$INSERT INTO tutor_project.question_materials(question_id,material_id,display_order) VALUES(303,505,0)$sql$);
SELECT pg_temp.run_project_test(13, 'P15-T15 duplicate_question_material', '23505', 'pk_tutor_project_question_materials',
    $sql$INSERT INTO tutor_project.question_materials(question_id,material_id,display_order) VALUES(301,501,3)$sql$);
SELECT pg_temp.run_project_test(14, 'P15-T16 duplicate_display_order', '23505', 'uq_tutor_project_qm_display_order',
    $sql$INSERT INTO tutor_project.question_materials(question_id,material_id,display_order) VALUES(301,503,1)$sql$);
SELECT pg_temp.run_project_test(15, 'P15-T17 blank_student_email', '23514', 'chk_tutor_project_students_email',
    $sql$INSERT INTO tutor_project.students(id,name,email,joined_at) VALUES(9102,'이메일공백','   ',DATE '2026-05-01')$sql$);
SELECT pg_temp.run_project_test(16, 'P15-T18 blank_question_code', '23514', 'chk_tutor_project_questions_code',
    $sql$INSERT INTO tutor_project.questions(id,student_id,question_code,title,body,status) VALUES(9304,101,'   ','코드 공백','코드 오류','open')$sql$);
SELECT pg_temp.run_project_test(17, 'P15-T19 invalid_question_timestamps', '23514', 'chk_tutor_project_questions_timestamps',
    $sql$INSERT INTO tutor_project.questions(id,student_id,question_code,title,body,status,created_at,updated_at) VALUES(9305,101,'NEG-Q-05','시간 오류','시간 오류','open',TIMESTAMPTZ '2026-05-02 10:00:00+09',TIMESTAMPTZ '2026-05-02 09:00:00+09')$sql$);
SELECT pg_temp.run_project_test(18, 'P15-T20 blank_material_url', '23514', 'chk_tutor_project_materials_url',
    $sql$INSERT INTO tutor_project.learning_materials(id,material_code,title,material_type,content_summary,source_url,access_scope,source_version,content_hash) VALUES(9503,'NEG-M-03','URL 공백','article','URL 오류','   ','public','v1','demo-neg-03')$sql$);

-- 정상 경계값 5개
SELECT pg_temp.run_project_test(19, 'P15-T21 one_character_student_name', NULL, NULL,
    $sql$INSERT INTO tutor_project.students(id,name,email,joined_at) VALUES(9601,'가','one.char@example.test',DATE '2026-05-01')$sql$,
    $sql$DELETE FROM tutor_project.students WHERE id=9601$sql$);
SELECT pg_temp.run_project_test(20, 'P15-T22 nullable_source_url', NULL, NULL,
    $sql$INSERT INTO tutor_project.learning_materials(id,material_code,title,material_type,content_summary,source_url,access_scope,source_version,content_hash) VALUES(9602,'OK-M-01','URL 없음','article','정상 경계값',NULL,'public','v1','demo-ok-01')$sql$,
    $sql$DELETE FROM tutor_project.learning_materials WHERE id=9602$sql$);
SELECT pg_temp.run_project_test(21, 'P15-T23 nullable_note_and_order_two', NULL, NULL,
    $sql$INSERT INTO tutor_project.question_materials(question_id,material_id,display_order,note) VALUES(303,506,2,NULL)$sql$,
    $sql$DELETE FROM tutor_project.question_materials WHERE question_id=303 AND material_id=506$sql$);
SELECT pg_temp.run_project_test(22, 'P15-T24 multiple_answers_same_question', NULL, NULL,
    $sql$INSERT INTO tutor_project.answers(id,question_id,tutor_id,answer_body,created_at) VALUES(9603,301,202,'추가 답변 허용 경계값',TIMESTAMPTZ '2026-05-10 10:00:00+09')$sql$,
    $sql$DELETE FROM tutor_project.answers WHERE id=9603$sql$);
SELECT pg_temp.run_project_test(23, 'P15-T25 same_tutor_multiple_answers_policy_open', NULL, NULL,
    $sql$INSERT INTO tutor_project.answers(id,question_id,tutor_id,answer_body,created_at) VALUES(9604,301,201,'같은 튜터 복수 답변 정책 미확정 예시',TIMESTAMPTZ '2026-05-10 10:10:00+09')$sql$,
    $sql$DELETE FROM tutor_project.answers WHERE id=9604$sql$);

SELECT *
FROM pg_temp.project_test_results
ORDER BY test_order;

DO $$
DECLARE
    total_count INTEGER;
    passed_count INTEGER;
    unexpected_count INTEGER;
BEGIN
    SELECT
        COUNT(*),
        COUNT(*) FILTER (WHERE actual_result IN ('expected_failure', 'expected_success')),
        COUNT(*) FILTER (WHERE actual_result LIKE 'unexpected%')
    INTO total_count, passed_count, unexpected_count
    FROM pg_temp.project_test_results;

    IF total_count <> 23 OR passed_count <> 23 OR unexpected_count <> 0 THEN
        RAISE EXCEPTION
            'P15-T03~T25 실패: total %, passed %, unexpected %.',
            total_count, passed_count, unexpected_count;
    END IF;

    IF (SELECT COUNT(*) FROM tutor_project.students) <> 4
       OR (SELECT COUNT(*) FROM tutor_project.tutors) <> 3
       OR (SELECT COUNT(*) FROM tutor_project.questions) <> 5
       OR (SELECT COUNT(*) FROM tutor_project.answers) <> 5
       OR (SELECT COUNT(*) FROM tutor_project.learning_materials) <> 6
       OR (SELECT COUNT(*) FROM tutor_project.question_materials) <> 7 THEN
        RAISE EXCEPTION 'P15-T03~T25 실패: 테스트 후 기준 데이터가 변경되었습니다.';
    END IF;

    RAISE NOTICE 'P15-T03~T25 negative and boundary validation passed';
END
$$;
