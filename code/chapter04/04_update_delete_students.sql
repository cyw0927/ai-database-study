-- Chapter 04. 04 안전한 UPDATE와 DELETE
-- 시작 상태: ai_database_book의 샘플 학생 6명, 이준호 grade 3, 박서연 존재
-- 완료 상태: 학생 5명, 이준호 grade 4, 박서연 삭제
-- 실행 방법: 각 단계의 SELECT와 변경 SQL을 순서대로 확인합니다.

SELECT current_database();
SELECT current_user;
SELECT current_schema();
SHOW search_path;

DO $$
DECLARE
    v_count bigint;
    v_junho_grade integer;
    v_seoyeon_count bigint;
BEGIN
    IF current_database() <> 'ai_database_book' THEN
        RAISE EXCEPTION
            '변경 중단: 현재 데이터베이스는 %입니다. ai_database_book 연결을 선택하세요.',
            current_database();
    END IF;

    IF to_regnamespace('public') IS NULL THEN
        RAISE EXCEPTION
            '변경 중단: public 스키마가 존재하지 않습니다.';
    END IF;

    IF current_setting('transaction_read_only')::boolean THEN
        RAISE EXCEPTION
            '변경 중단: 현재 연결이 읽기 전용입니다.';
    END IF;

    IF to_regclass('public.students') IS NULL THEN
        RAISE EXCEPTION
            '변경 중단: public.students가 없습니다.';
    END IF;

    IF NOT has_table_privilege(current_user, 'public.students', 'SELECT') THEN
        RAISE EXCEPTION
            '변경 중단: 사용자 %에게 public.students SELECT 권한이 없습니다.',
            current_user;
    END IF;

    IF NOT has_table_privilege(current_user, 'public.students', 'UPDATE') THEN
        RAISE EXCEPTION
            '변경 중단: 사용자 %에게 public.students UPDATE 권한이 없습니다.',
            current_user;
    END IF;

    IF NOT has_table_privilege(current_user, 'public.students', 'DELETE') THEN
        RAISE EXCEPTION
            '변경 중단: 사용자 %에게 public.students DELETE 권한이 없습니다.',
            current_user;
    END IF;

    SELECT COUNT(*) INTO v_count
    FROM public.students;

    SELECT grade INTO v_junho_grade
    FROM public.students
    WHERE email = 'junho@example.com';

    SELECT COUNT(*) INTO v_seoyeon_count
    FROM public.students
    WHERE email = 'seoyeon@example.com';

    IF v_count <> 6
       OR v_junho_grade IS DISTINCT FROM 3
       OR v_seoyeon_count <> 1 THEN
        RAISE EXCEPTION
            '변경 중단: 초기 데이터 상태가 아닙니다. 학생 수=%, 이준호 학년=%, 박서연 행 수=%',
            v_count, v_junho_grade, v_seoyeon_count;
    END IF;
END
$$;

-- ============================================================
-- UPDATE: 이준호 학년을 3에서 4로 변경
-- ============================================================

-- 1. 대상 확인
SELECT id, name, email, grade
FROM public.students
WHERE email = 'junho@example.com';

-- 2. 수정과 반환값 확인
UPDATE public.students
SET grade = 4
WHERE email = 'junho@example.com'
RETURNING id, name, grade;

-- 3. 수정 결과 확인
SELECT id, name, email, grade
FROM public.students
WHERE email = 'junho@example.com';

-- ============================================================
-- DELETE: 박서연 학생 삭제
-- ============================================================

-- 1. 대상 확인
SELECT id, name, email, major
FROM public.students
WHERE email = 'seoyeon@example.com';

-- 2. 삭제와 반환값 확인
DELETE FROM public.students
WHERE email = 'seoyeon@example.com'
RETURNING id, name, email;

-- 3. 삭제 결과 확인: 기대 결과 0행
SELECT id, name, email
FROM public.students
WHERE email = 'seoyeon@example.com';

-- 최종 상태를 자동 판정합니다.
DO $$
DECLARE
    v_count bigint;
    v_junho_grade integer;
    v_seoyeon_count bigint;
BEGIN
    SELECT COUNT(*) INTO v_count
    FROM public.students;

    SELECT grade INTO v_junho_grade
    FROM public.students
    WHERE email = 'junho@example.com';

    SELECT COUNT(*) INTO v_seoyeon_count
    FROM public.students
    WHERE email = 'seoyeon@example.com';

    IF v_count <> 5
       OR v_junho_grade IS DISTINCT FROM 4
       OR v_seoyeon_count <> 0 THEN
        RAISE EXCEPTION
            '최종 상태 오류: 학생 수=%, 이준호 학년=%, 박서연 행 수=%',
            v_count, v_junho_grade, v_seoyeon_count;
    END IF;
END
$$;

SELECT COUNT(*) AS remaining_student_count
FROM public.students;

SELECT id, name, email, major, grade
FROM public.students
ORDER BY id ASC;

-- ------------------------------------------------------------
-- 실행하지 않는 위험 SQL 예시
-- ------------------------------------------------------------

-- WHERE가 없으므로 모든 행을 수정합니다.
-- UPDATE public.students
-- SET grade = 1;

-- WHERE가 없으므로 모든 행을 삭제합니다.
-- DELETE FROM public.students;

-- 여러 열 수정 예시입니다. 기본 실습에서는 실행하지 않습니다.
-- UPDATE public.students
-- SET major = '소프트웨어공학',
--     grade = 3
-- WHERE email = 'minji@example.com'
-- RETURNING id, name, major, grade;
