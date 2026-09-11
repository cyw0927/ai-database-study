-- Chapter 04. 02 샘플 학생 데이터 입력
-- 시작 상태: ai_database_book의 public.students 테이블이 존재하고 0행
-- 완료 상태: 샘플 학생 6명
-- 반복 실행: 시작 상태가 아니면 중단합니다.
-- 안전성: 세 INSERT를 한 트랜잭션으로 묶어 중간 실패 시 부분 입력을 남기지 않습니다.
-- 시간 주의: CURRENT_TIMESTAMP는 트랜잭션 시작 시각이므로 이 파일에서 입력한 6명의 created_at은 같을 수 있습니다.

SELECT current_database();
SELECT current_user;
SELECT current_schema();
SHOW search_path;

BEGIN;

DO $$
DECLARE
    v_count bigint;
BEGIN
    IF current_database() <> 'ai_database_book' THEN
        RAISE EXCEPTION
            '입력 중단: 현재 데이터베이스는 %입니다. ai_database_book 연결을 선택하세요.',
            current_database();
    END IF;

    IF to_regnamespace('public') IS NULL THEN
        RAISE EXCEPTION
            '입력 중단: public 스키마가 존재하지 않습니다.';
    END IF;

    IF current_setting('transaction_read_only')::boolean THEN
        RAISE EXCEPTION
            '입력 중단: 현재 연결이 읽기 전용입니다.';
    END IF;

    IF to_regclass('public.students') IS NULL THEN
        RAISE EXCEPTION
            '입력 중단: public.students가 없습니다. 01_create_students.sql을 먼저 실행하세요.';
    END IF;

    IF NOT has_table_privilege(current_user, 'public.students', 'SELECT') THEN
        RAISE EXCEPTION
            '입력 중단: 사용자 %에게 public.students SELECT 권한이 없습니다.',
            current_user;
    END IF;

    IF NOT has_table_privilege(current_user, 'public.students', 'INSERT') THEN
        RAISE EXCEPTION
            '입력 중단: 사용자 %에게 public.students INSERT 권한이 없습니다.',
            current_user;
    END IF;

    SELECT COUNT(*) INTO v_count
    FROM public.students;

    IF v_count <> 0 THEN
        RAISE EXCEPTION
            '입력 중단: public.students에 이미 %행이 있습니다. 현재 상태를 확인하세요.',
            v_count;
    END IF;
END
$$;

-- 단일 행 입력과 자동값 확인
INSERT INTO public.students (name, email, major, grade)
VALUES ('김민지', 'minji@example.com', '컴퓨터공학', 2)
RETURNING id, name, created_at;

-- 여러 행 입력
INSERT INTO public.students (name, email, major, grade)
VALUES
    ('이준호', 'junho@example.com', '데이터사이언스', 3),
    ('박서연', 'seoyeon@example.com', '경영학', 1),
    ('최현우', 'hyunwoo@example.com', '컴퓨터공학', 4),
    ('정하늘', 'haneul@example.com', 'AI데이터공학', 2)
RETURNING id, name, major, grade;

-- 선택값을 생략해 NULL 확인
INSERT INTO public.students (name, email)
VALUES ('윤서진', 'seojin@example.com')
RETURNING id, name, major, grade, created_at;

-- COMMIT 전에 기준 상태를 판정합니다.
DO $$
DECLARE
    v_count bigint;
    v_junho_grade integer;
    v_seoyeon_count bigint;
    v_null_student_count bigint;
BEGIN
    SELECT COUNT(*) INTO v_count
    FROM public.students;

    SELECT grade INTO v_junho_grade
    FROM public.students
    WHERE email = 'junho@example.com';

    SELECT COUNT(*) INTO v_seoyeon_count
    FROM public.students
    WHERE email = 'seoyeon@example.com';

    SELECT COUNT(*) INTO v_null_student_count
    FROM public.students
    WHERE email = 'seojin@example.com'
      AND major IS NULL
      AND grade IS NULL;

    IF v_count <> 6
       OR v_junho_grade IS DISTINCT FROM 3
       OR v_seoyeon_count <> 1
       OR v_null_student_count <> 1 THEN
        RAISE EXCEPTION
            '입력 중단: 예상한 초기 데이터 상태와 다릅니다. 학생 수=%, 이준호 학년=%, 박서연 행 수=%, 윤서진 NULL 상태 행 수=%',
            v_count, v_junho_grade, v_seoyeon_count, v_null_student_count;
    END IF;
END
$$;

COMMIT;

-- 초기 데이터 상태 확인
SELECT COUNT(*) AS student_count
FROM public.students;

SELECT id, name, email, major, grade, created_at
FROM public.students
ORDER BY id ASC;
