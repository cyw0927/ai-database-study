-- Chapter 15. tutor_project 초기화
-- tutor_project 스키마만 삭제하며 앞 장 스키마·public·Role은 변경하지 않습니다.

SELECT current_user;
SELECT current_database();
SELECT current_schema();
SHOW search_path;

DO $$
BEGIN
    IF current_database() <> 'ai_database_book' THEN
        RAISE EXCEPTION
            '초기화 중단: 현재 데이터베이스는 %입니다. ai_database_book에서만 실행하세요.',
            current_database();
    END IF;

    DROP VIEW IF EXISTS tutor_project.tutor_answer_summary;
    DROP VIEW IF EXISTS tutor_project.student_question_summary;
    DROP VIEW IF EXISTS tutor_project.question_analysis_dataset;
    DROP VIEW IF EXISTS tutor_project.analysis_parameters;
    DROP TABLE IF EXISTS tutor_project.question_materials;
    DROP TABLE IF EXISTS tutor_project.answers;
    DROP TABLE IF EXISTS tutor_project.learning_materials;
    DROP TABLE IF EXISTS tutor_project.questions;
    DROP TABLE IF EXISTS tutor_project.tutors;
    DROP TABLE IF EXISTS tutor_project.students;
    DROP SCHEMA IF EXISTS tutor_project;
END
$$;

-- 삭제 후 실행 순서
-- 01_schema.sql → 02_seed.sql → 03_metadata_validation.sql
-- → 04_requirement_queries.sql → 05_transaction_checks.sql
-- → 06_negative_tests.sql → 07_performance_checks.sql
-- → 08_operations_checks.sql → 09_analysis_dataset.sql
-- → 10_completion_gate.sql → Python 교차 검증
