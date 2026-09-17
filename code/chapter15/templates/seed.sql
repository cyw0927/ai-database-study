-- Chapter 15 호환 안내: 기준 데이터 입력
-- 이 파일은 기존 링크 호환용 읽기 전용 상태 확인 파일입니다.
-- 실제 입력은 빈 상태 검사·트랜잭션·IDENTITY 조정이 포함된 02_seed.sql을 실행합니다.

SELECT current_database();
SELECT current_schema();
SHOW search_path;

SELECT
    to_regnamespace('tutor_project') AS tutor_project_schema,
    to_regclass('tutor_project.students') AS students_table,
    to_regclass('tutor_project.questions') AS questions_table;

-- 02_seed.sql 기준:
-- rows 4 / 3 / 5 / 5 / 6 / 7
-- identity next 105 / 204 / 306 / 406 / 507 이상
-- 질문 없는 학생 1 / 연결되지 않은 자료 1 / 시간 관계 이상 0
