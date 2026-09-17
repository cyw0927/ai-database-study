-- Chapter 05 호환 파일: 02_library_seed.sql과 같은 역할
-- 기존 링크와 강의 자료 호환을 위해 유지합니다.
-- 번호 파일과 이 파일을 모두 실행하지 마세요.
-- 전체 입력과 IDENTITY 조정은 하나의 트랜잭션으로 묶어 부분 입력을 방지합니다.

SELECT current_database();
SELECT current_user;
SELECT current_schema();
SHOW search_path;

BEGIN;

DO $$
DECLARE
    v_member_count bigint;
    v_book_count bigint;
    v_loan_count bigint;
BEGIN
    IF current_database() <> 'ai_database_book' THEN
        RAISE EXCEPTION
            '입력 중단: 현재 데이터베이스는 %입니다. ai_database_book에 연결하세요.',
            current_database();
    END IF;

    IF current_setting('transaction_read_only')::boolean THEN
        RAISE EXCEPTION
            '입력 중단: 현재 연결이 읽기 전용입니다.';
    END IF;

    IF to_regclass('public.members') IS NULL
       OR to_regclass('public.books') IS NULL
       OR to_regclass('public.loans') IS NULL THEN
        RAISE EXCEPTION
            '입력 중단: Chapter 05 테이블이 모두 존재하지 않습니다. 01_library_schema.sql 또는 library_schema.sql을 먼저 실행하세요.';
    END IF;

    SELECT COUNT(*) INTO v_member_count FROM public.members;
    SELECT COUNT(*) INTO v_book_count FROM public.books;
    SELECT COUNT(*) INTO v_loan_count FROM public.loans;

    IF v_member_count <> 0 OR v_book_count <> 0 OR v_loan_count <> 0 THEN
        RAISE EXCEPTION
            '입력 중단: 테이블이 비어 있지 않습니다. members=%, books=%, loans=%',
            v_member_count, v_book_count, v_loan_count;
    END IF;
END
$$;

INSERT INTO public.members (id, name, email, joined_at)
VALUES
    (101, '김민지', 'minji@example.com', DATE '2026-03-01'),
    (102, '이준호', 'junho@example.com', DATE '2026-03-05'),
    (103, '박서연', 'seoyeon@example.com', DATE '2026-03-10');

INSERT INTO public.books (id, title, author, published_year, isbn)
VALUES
    (201, '데이터베이스 입문', '문길래', 2026, 'ISBN-001'),
    (202, 'SQL 기초', '홍길동', 2025, 'ISBN-002'),
    (203, 'ERD 설계 연습', '이몽룡', 2024, 'ISBN-003');

INSERT INTO public.loans (
    id,
    member_id,
    book_id,
    borrowed_at,
    due_at,
    returned_at
)
VALUES
    (1001, 101, 201, DATE '2026-04-01', DATE '2026-04-15', DATE '2026-04-02'),
    (1002, 101, 202, DATE '2026-04-02', DATE '2026-04-16', NULL),
    (1003, 102, 201, DATE '2026-04-03', DATE '2026-04-17', NULL),
    (1004, 103, 203, DATE '2026-04-05', DATE '2026-04-19', NULL);

ALTER TABLE public.members
    ALTER COLUMN id RESTART WITH 104;

ALTER TABLE public.books
    ALTER COLUMN id RESTART WITH 204;

ALTER TABLE public.loans
    ALTER COLUMN id RESTART WITH 1005;

DO $$
DECLARE
    v_member_count bigint;
    v_book_count bigint;
    v_loan_count bigint;
    v_open_loan_count bigint;
    v_member_101_count bigint;
    v_book_201_count bigint;
BEGIN
    SELECT COUNT(*) INTO v_member_count FROM public.members;
    SELECT COUNT(*) INTO v_book_count FROM public.books;
    SELECT COUNT(*) INTO v_loan_count FROM public.loans;
    SELECT COUNT(*) INTO v_open_loan_count FROM public.loans WHERE returned_at IS NULL;
    SELECT COUNT(*) INTO v_member_101_count FROM public.loans WHERE member_id = 101;
    SELECT COUNT(*) INTO v_book_201_count FROM public.loans WHERE book_id = 201;

    IF v_member_count <> 3
       OR v_book_count <> 3
       OR v_loan_count <> 4
       OR v_open_loan_count <> 3
       OR v_member_101_count <> 2
       OR v_book_201_count <> 2 THEN
        RAISE EXCEPTION
            '입력 검증 실패: members=%, books=%, loans=%, open=%, member101=%, book201=%',
            v_member_count,
            v_book_count,
            v_loan_count,
            v_open_loan_count,
            v_member_101_count,
            v_book_201_count;
    END IF;
END
$$;

COMMIT;

SELECT
    (SELECT COUNT(*) FROM public.members) AS member_count,
    (SELECT COUNT(*) FROM public.books) AS book_count,
    (SELECT COUNT(*) FROM public.loans) AS loan_count,
    (SELECT COUNT(*) FROM public.loans WHERE returned_at IS NULL) AS open_loan_count;
