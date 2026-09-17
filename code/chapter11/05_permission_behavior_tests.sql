-- Chapter 11. 허용·차단 권한 동작 테스트
-- 관리자 권한이 있는 테스트 환경에서 역할과 GRANT를 적용한 뒤 사용합니다.
-- 모든 성공 테스트는 ROLLBACK으로 끝나므로 기준 데이터를 남기지 않습니다.
-- 실패해야 하는 문장은 기본 주석 상태이며 한 문장씩 선택 실행합니다.

SELECT current_user AS current_user_name;
SELECT current_database();
SELECT current_schema();
SHOW search_path;

DO $$
BEGIN
    IF current_database() <> 'ai_database_book' THEN
        RAISE EXCEPTION
            '실행 중단: 현재 데이터베이스는 %입니다.',
            current_database();
    END IF;

    IF to_regclass('security_lab.students') IS NULL
       OR to_regclass('security_lab.courses') IS NULL
       OR to_regclass('security_lab.enrollments') IS NULL THEN
        RAISE EXCEPTION
            '실행 중단: security_lab 핵심 테이블이 없습니다.';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'lab_readonly_user')
       OR NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'lab_enrollment_user') THEN
        RAISE EXCEPTION
            '실행 중단: 실습 로그인 역할이 없습니다. 03 파일의 역할 계획을 먼저 적용하세요.';
    END IF;

    IF (SELECT COUNT(*) FROM security_lab.students) <> 3
       OR (SELECT COUNT(*) FROM security_lab.courses) <> 3
       OR (SELECT COUNT(*) FROM security_lab.enrollments) <> 3
       OR (SELECT COALESCE(SUM(recorded_amount), 0) FROM security_lab.enrollments) <> 310000 THEN
        RAISE EXCEPTION '실행 중단: security_lab 기준 데이터가 아닙니다.';
    END IF;
END
$$;

-- ============================================================
-- 1. 읽기 계정의 허용 동작
-- 현재 세션 사용자가 대상 역할로 SET ROLE할 수 있어야 합니다.
-- ============================================================
BEGIN;
SET LOCAL ROLE lab_readonly_user;

SELECT id, name, email
FROM security_lab.students
ORDER BY id;

SELECT id, title, level, price
FROM security_lab.courses
ORDER BY id;

SELECT id, student_id, course_id, status, recorded_amount
FROM security_lab.enrollments
ORDER BY id;

ROLLBACK;

-- ============================================================
-- 2. 읽기 계정의 차단 동작
-- 아래 블록에서 실패 문장 하나만 주석 해제해 실행합니다.
-- 오류 후 ROLLBACK TO SAVEPOINT와 ROLLBACK을 실행합니다.
-- ============================================================
-- BEGIN;
-- SET LOCAL ROLE lab_readonly_user;
-- SAVEPOINT before_denied_action;
--
-- INSERT INTO security_lab.enrollments (
--     student_id, course_id, status, recorded_amount, enrolled_at
-- ) VALUES (
--     102, 201, '신청', 100000, CURRENT_DATE
-- ); -- permission denied가 발생해야 정상
--
-- ROLLBACK TO SAVEPOINT before_denied_action;
-- ROLLBACK;

-- UPDATE·DELETE도 같은 방식으로 한 문장씩 선택 테스트합니다.
-- UPDATE security_lab.enrollments SET status = '완료' WHERE id = 1001;
-- DELETE FROM security_lab.enrollments WHERE id = 1001;

-- ============================================================
-- 3. 앱 계정의 허용 동작
-- ID를 생략한 INSERT가 시퀀스 USAGE 권한으로 성공해야 합니다.
-- 변경 내용은 마지막 ROLLBACK으로 모두 취소합니다.
-- ============================================================
BEGIN;
SET LOCAL ROLE lab_enrollment_user;

SELECT id, name
FROM security_lab.students
ORDER BY id;

SELECT id, title, price
FROM security_lab.courses
ORDER BY id;

INSERT INTO security_lab.enrollments (
    student_id,
    course_id,
    status,
    recorded_amount,
    enrolled_at
)
VALUES (
    102,
    201,
    '신청',
    100000,
    CURRENT_DATE
)
RETURNING id, student_id, course_id, status, recorded_amount;

UPDATE security_lab.enrollments
SET status = '완료'
WHERE student_id = 102
  AND course_id = 201
  AND status = '신청'
RETURNING id, status;

ROLLBACK;

-- 주의: INSERT가 ROLLBACK되어도 IDENTITY 번호는 회수되지 않을 수 있습니다.
-- 권한 동작 시험 뒤 기준 시퀀스가 꼭 1004여야 하는 검증은 수행하지 않습니다.

-- ============================================================
-- 4. 앱 계정의 차단 동작
-- 실패 문장 하나만 주석 해제해 실행합니다.
-- ============================================================
-- BEGIN;
-- SET LOCAL ROLE lab_enrollment_user;
-- SAVEPOINT before_denied_action;
--
-- UPDATE security_lab.enrollments
-- SET recorded_amount = 0
-- WHERE id = 1001; -- recorded_amount UPDATE 권한 오류가 발생해야 정상
--
-- ROLLBACK TO SAVEPOINT before_denied_action;
-- ROLLBACK;

-- 다음 문장도 각각 별도 트랜잭션에서 실패해야 정상입니다.
-- DELETE FROM security_lab.enrollments WHERE id = 1001;
-- CREATE TABLE security_lab.denied_table (id INTEGER);

-- ============================================================
-- 5. 기준 데이터 보존 자동 확인
-- 시퀀스 번호는 증가했을 수 있지만 행 데이터는 3 / 3 / 3, 총액 310000이어야 합니다.
-- ============================================================
DO $$
DECLARE
    v_duplicate_active BIGINT;
BEGIN
    SELECT COUNT(*) INTO v_duplicate_active
    FROM (
        SELECT student_id, course_id
        FROM security_lab.enrollments
        WHERE status IN ('신청', '수강중')
        GROUP BY student_id, course_id
        HAVING COUNT(*) > 1
    ) AS duplicated;

    IF (SELECT COUNT(*) FROM security_lab.students) <> 3
       OR (SELECT COUNT(*) FROM security_lab.courses) <> 3
       OR (SELECT COUNT(*) FROM security_lab.enrollments) <> 3
       OR (SELECT COALESCE(SUM(recorded_amount), 0) FROM security_lab.enrollments) <> 310000
       OR v_duplicate_active <> 0 THEN
        RAISE EXCEPTION '권한 동작 테스트 후 기준 데이터가 변경되었습니다.';
    END IF;

    RAISE NOTICE 'Chapter 11 permission behavior baseline preserved';
END
$$;

SELECT COUNT(*) AS student_count FROM security_lab.students;
SELECT COUNT(*) AS course_count FROM security_lab.courses;
SELECT COUNT(*) AS enrollment_count FROM security_lab.enrollments;
SELECT SUM(recorded_amount) AS total_recorded_amount FROM security_lab.enrollments;

-- 권한 테스트 결과는 다음과 같이 기록합니다.
-- 읽기 계정: SELECT 성공, INSERT·UPDATE·DELETE 실패
-- 앱 계정: SELECT·INSERT·status UPDATE 성공,
--           recorded_amount UPDATE·DELETE·schema CREATE 실패
