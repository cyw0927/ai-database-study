-- Chapter 15 호환 안내: 스키마 생성
-- 이 파일은 기존 링크 호환용 읽기 전용 상태 확인 파일입니다.
-- 실제 생성은 보호 구문과 트랜잭션이 포함된 01_schema.sql을 실행합니다.

SELECT current_user AS current_user_name;
SELECT current_database();
SELECT current_schema();
SHOW search_path;

SELECT
    to_regnamespace('tutor_project') AS tutor_project_schema,
    to_regclass('tutor_project.students') AS students_table,
    to_regclass('tutor_project.tutors') AS tutors_table,
    to_regclass('tutor_project.questions') AS questions_table,
    to_regclass('tutor_project.answers') AS answers_table,
    to_regclass('tutor_project.learning_materials') AS materials_table,
    to_regclass('tutor_project.question_materials') AS question_materials_table,
    to_regclass('tutor_project.analysis_parameters') AS analysis_parameters_view;

-- 실행 순서:
-- 01_schema.sql → 02_seed.sql → 03_metadata_validation.sql
-- 처음부터 다시 시작할 때만 reset_tutor_project.sql을 검토합니다.
