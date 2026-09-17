-- Chapter 13. AI와 실행 증거로 데이터베이스 설계 검증하기
--
-- 이 파일은 기존 링크 호환용 읽기 전용 안내·상태 확인 진입점입니다.
-- 기존 프로젝트 테이블을 삭제하거나 다시 만들지 않습니다.
-- ai_review_lab이 아직 생성되지 않은 상태에서도 안전하게 실행할 수 있습니다.
--
-- 실제 실습 순서:
-- 1. 01_ai_review_lab_schema.sql
-- 2. 02_bad_design_seed.sql
-- 3. 03_good_design_schema.sql
-- 4. 04_good_design_seed.sql
-- 5. 05_metadata_validation.sql
-- 6. 06_business_validation.sql
-- 7. 07_negative_tests.sql
-- 8. 08_ai_review_lab_validation.sql
-- 9. AI_REVIEW_REPORT_TEMPLATE.md 기록
--
-- 처음부터 다시 시작할 때만 reset_ai_review_lab.sql을 사용합니다.

SELECT current_user AS current_user_name;
SELECT current_database();
SELECT current_schema();
SHOW search_path;

-- 앞 장과 Chapter 13 객체 존재 여부 확인
SELECT
    to_regnamespace('course_project') AS course_project_schema,
    to_regnamespace('transaction_lab') AS transaction_lab_schema,
    to_regnamespace('performance_lab') AS performance_lab_schema,
    to_regnamespace('security_lab') AS security_lab_schema,
    to_regnamespace('nosql_lab') AS nosql_lab_schema,
    to_regnamespace('ai_review_lab') AS ai_review_lab_schema,
    to_regclass('ai_review_lab.bad_enrollments') AS bad_table,
    to_regclass('ai_review_lab.students') AS students_table,
    to_regclass('ai_review_lab.instructors') AS instructors_table,
    to_regclass('ai_review_lab.courses') AS courses_table,
    to_regclass('ai_review_lab.enrollments') AS enrollments_table,
    to_regclass('ai_review_lab.payments') AS payments_table,
    to_regclass('ai_review_lab.uq_ai_review_enrollments_active')
        AS active_enrollment_index;

SELECT
    table_schema,
    table_name
FROM information_schema.tables
WHERE table_schema = 'ai_review_lab'
ORDER BY table_name;

-- 기준 행 수 조회는 01→04 파일을 실행한 뒤 사용합니다.
-- SELECT COUNT(*) FROM ai_review_lab.bad_enrollments; -- 3
-- SELECT COUNT(*) FROM ai_review_lab.students;        -- 3
-- SELECT COUNT(*) FROM ai_review_lab.instructors;     -- 2
-- SELECT COUNT(*) FROM ai_review_lab.courses;         -- 3
-- SELECT COUNT(*) FROM ai_review_lab.enrollments;     -- 4
-- SELECT COUNT(*) FROM ai_review_lab.payments;        -- 4

-- 핵심 추적 ID:
-- P13-R01~P13-R09  확인된 요구사항
-- P13-D01~P13-D08  결정·범위
-- P13-T01~P13-T27  반례·경계값 테스트
-- P13-V01~P13-V08  실행·검증 단계

-- AI 결과는 자동 승인하지 않습니다.
-- 요구사항 추적, 실제 메타데이터, 정상·반례·업무 정합성 결과,
-- IDENTITY 상태와 파일별 diff를 확인한 뒤
-- 승인·조건부 승인·보류·거절을 기록합니다.
