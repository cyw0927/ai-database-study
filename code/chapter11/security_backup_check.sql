-- Chapter 11. 데이터베이스를 안전하게 지키고 복구하는 방법
--
-- 이 파일은 기존 링크 호환용 읽기 전용 안내·상태 확인 진입점입니다.
-- 기존 프로젝트 테이블을 삭제하거나 다시 만들지 않습니다.
-- security_lab이 아직 생성되지 않은 상태에서도 안전하게 실행할 수 있습니다.
--
-- 실제 실습 순서:
-- 1. 01_security_lab_schema.sql
-- 2. 02_security_lab_seed.sql
-- 3. 03_role_permission_plan.sql에서 필요한 문장만 선택 실행
-- 4. 04_permission_checks.sql
-- 5. 05_permission_behavior_tests.sql 선택 실습
-- 6. 터미널에서 백업·별도 DB 복원
-- 7. 복원 DB에서 06_restore_validation.sql
-- 8. BACKUP_RESTORE_RUNBOOK.md 기록
--
-- 처음부터 다시 시작할 때만 reset_security_lab.sql을 사용합니다.

SELECT current_user AS current_user_name;
SELECT session_user AS session_user_name;
SELECT current_database();
SELECT current_schema();
SHOW search_path;
SELECT current_setting('server_version') AS postgresql_version;

-- 앞 장과 Chapter 11 객체 존재 여부
SELECT
    to_regclass('course_project.enrollments')
        AS project_enrollments_table,
    to_regclass('security_lab.students')
        AS security_students_table,
    to_regclass('security_lab.courses')
        AS security_courses_table,
    to_regclass('security_lab.enrollments')
        AS security_enrollments_table,
    to_regclass('security_lab.uq_security_enrollments_active')
        AS active_enrollment_index;

-- security_lab 테이블 목록
SELECT
    table_schema,
    table_name
FROM information_schema.tables
WHERE table_schema = 'security_lab'
ORDER BY table_name;

-- 기준 행 수 조회는 01·02 파일을 실행한 뒤 선택합니다.
-- SELECT COUNT(*) AS student_count FROM security_lab.students;
-- SELECT COUNT(*) AS course_count FROM security_lab.courses;
-- SELECT COUNT(*) AS enrollment_count FROM security_lab.enrollments;

-- 실습 Role 확인
SELECT
    rolname,
    rolcanlogin,
    rolsuper,
    rolcreatedb,
    rolcreaterole,
    rolinherit
FROM pg_roles
WHERE rolname LIKE 'lab_%'
ORDER BY rolname;

-- 실제 비밀번호·전체 접속 URL·백업 파일은 저장소에 기록하지 않습니다.
-- libpq password file 경로는 PGPASSFILE로 지정할 수 있으며 실제 파일은 저장소 밖에 둡니다.

-- Unix 계열 password file은 그룹·다른 사용자 접근을 막도록 chmod 0600 수준으로 제한합니다.
-- Windows는 별도 권한 검사를 하지 않으므로 접근이 제한된 사용자 경로를 사용합니다.
