-- Chapter 04. 03 SELECT와 조건 조회
-- 시작 상태: 샘플 학생 6명
-- 완료 상태: 데이터 변경 없음
-- 반복 실행: 조회문만 포함하므로 반복 실행할 수 있습니다.

-- 전체 열과 필요한 열
SELECT *
FROM public.students;

SELECT id, name, email, major
FROM public.students
ORDER BY id ASC;

SELECT
    name AS student_name,
    major AS student_major
FROM public.students
ORDER BY id ASC;

-- WHERE와 비교 연산자
SELECT id, name, major
FROM public.students
WHERE major = '컴퓨터공학'
ORDER BY id ASC;

SELECT id, name, grade
FROM public.students
WHERE grade >= 3
ORDER BY grade DESC, id ASC;

-- AND, OR, IN
SELECT id, name, major, grade
FROM public.students
WHERE major = '컴퓨터공학'
  AND grade >= 3
ORDER BY id ASC;

SELECT id, name, major
FROM public.students
WHERE major = '컴퓨터공학'
   OR major = '데이터사이언스'
ORDER BY id ASC;

SELECT id, name, major
FROM public.students
WHERE major IN ('컴퓨터공학', '데이터사이언스')
ORDER BY id ASC;

SELECT id, name, major, grade
FROM public.students
WHERE major = '컴퓨터공학'
  AND (grade = 2 OR grade = 3)
ORDER BY id ASC;

-- LIKE 문자열 검색
SELECT id, name
FROM public.students
WHERE name LIKE '김%'
ORDER BY id ASC;

SELECT id, name
FROM public.students
WHERE name LIKE '%민%'
ORDER BY id ASC;

SELECT id, name
FROM public.students
WHERE name LIKE '%우'
ORDER BY id ASC;

SELECT id, name
FROM public.students
WHERE name LIKE '김__'
ORDER BY id ASC;

-- NULL 확인
SELECT id, name, major, grade
FROM public.students
WHERE major IS NULL
ORDER BY id ASC;

SELECT id, name, major, grade
FROM public.students
WHERE major IS NOT NULL
ORDER BY id ASC;

-- major가 NULL인 행은 포함되지 않습니다.
SELECT id, name, major
FROM public.students
WHERE major <> '경영학'
ORDER BY id ASC;

-- NULL도 포함하는 조건
SELECT id, name, major
FROM public.students
WHERE major <> '경영학'
   OR major IS NULL
ORDER BY id ASC;

-- DISTINCT
SELECT DISTINCT major
FROM public.students
WHERE major IS NOT NULL
ORDER BY major ASC;

-- ORDER BY와 LIMIT
SELECT id, name, grade
FROM public.students
ORDER BY grade ASC, id ASC;

SELECT id, name, created_at
FROM public.students
ORDER BY created_at DESC, id DESC
LIMIT 3;

-- ------------------------------------------------------------
-- 선택 학습: PostgreSQL 문법
-- ------------------------------------------------------------

-- 대소문자를 구분하지 않는 패턴 검색
SELECT id, name, email
FROM public.students
WHERE email ILIKE '%EXAMPLE.COM'
ORDER BY id ASC;

-- NULL을 마지막에 표시
SELECT id, name, grade
FROM public.students
ORDER BY grade DESC NULLS LAST, id ASC;

-- NULL 안전 비교
SELECT id, name, major
FROM public.students
WHERE major IS DISTINCT FROM '경영학'
ORDER BY id ASC;

-- 형 변환
SELECT CAST('3' AS INTEGER) AS cast_result;
SELECT '3'::INTEGER AS shorthand_result;
