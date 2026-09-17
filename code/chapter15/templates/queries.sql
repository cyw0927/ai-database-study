-- Chapter 15 호환 안내: 검증 쿼리
-- 이 파일은 기존 링크 호환용 읽기 전용 상태 확인 파일입니다.
-- 실제 검증은 다음 순서로 실행합니다.
--
-- 03_metadata_validation.sql
-- 04_requirement_queries.sql
-- 05_transaction_checks.sql
-- 06_negative_tests.sql
-- 07_performance_checks.sql
-- 08_operations_checks.sql
-- 09_analysis_dataset.sql
-- 10_completion_gate.sql
-- Python 03_result_validation.py
-- 필요 시 복원 DB에서 11_restore_validation.sql

SELECT current_database();
SELECT current_schema();
SHOW search_path;

SELECT
    to_regnamespace('tutor_project') AS tutor_project_schema,
    to_regclass('tutor_project.question_analysis_dataset') AS question_view,
    to_regclass('tutor_project.student_question_summary') AS student_view,
    to_regclass('tutor_project.tutor_answer_summary') AS tutor_view;

-- 핵심 기준:
-- tables/views/sequences 6/4/5
-- constraints/FK/indexes 36/5/3
-- rows 4/3/5/5/6/7
-- tests 23/23, unexpected 0
-- 질문·학생·튜터 VIEW 5/4/3
-- 실제 SQL·pandas 요약 5종 일치
