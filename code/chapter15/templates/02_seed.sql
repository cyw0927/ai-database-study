-- Chapter 15. AI 튜터링 질문 관리 서비스 기준 데이터
-- P15-V02: 빈 전용 스키마에 명시적 ID와 고정 시각 데이터를 원자적으로 입력합니다.

SELECT current_database();
SELECT current_schema();
SHOW search_path;

DO $$
BEGIN
    IF current_database() <> 'ai_database_book' THEN
        RAISE EXCEPTION '실행 중단: 현재 데이터베이스는 %입니다.', current_database();
    END IF;

    IF to_regclass('tutor_project.students') IS NULL
       OR to_regclass('tutor_project.tutors') IS NULL
       OR to_regclass('tutor_project.questions') IS NULL
       OR to_regclass('tutor_project.answers') IS NULL
       OR to_regclass('tutor_project.learning_materials') IS NULL
       OR to_regclass('tutor_project.question_materials') IS NULL THEN
        RAISE EXCEPTION '실행 중단: 01_schema.sql의 핵심 테이블이 없습니다.';
    END IF;

    IF (SELECT COUNT(*) FROM tutor_project.students) <> 0
       OR (SELECT COUNT(*) FROM tutor_project.tutors) <> 0
       OR (SELECT COUNT(*) FROM tutor_project.questions) <> 0
       OR (SELECT COUNT(*) FROM tutor_project.answers) <> 0
       OR (SELECT COUNT(*) FROM tutor_project.learning_materials) <> 0
       OR (SELECT COUNT(*) FROM tutor_project.question_materials) <> 0 THEN
        RAISE EXCEPTION '실행 중단: Seed 대상 테이블은 모두 비어 있어야 합니다.';
    END IF;
END
$$;

BEGIN;

INSERT INTO tutor_project.students (id, name, email, joined_at, is_active)
VALUES
    (101, '학생A', 'student.a@example.test', DATE '2026-01-05', TRUE),
    (102, '학생B', 'student.b@example.test', DATE '2026-02-01', TRUE),
    (103, '학생C', 'student.c@example.test', DATE '2026-03-01', TRUE),
    (104, '질문없는학생', 'student.noquestion@example.test', DATE '2026-04-01', TRUE);

INSERT INTO tutor_project.tutors (id, name, email, specialty, is_active, created_at)
VALUES
    (201, '튜터SQL', 'tutor.sql@example.test', 'SQL', TRUE, TIMESTAMPTZ '2026-01-05 09:00:00+09'),
    (202, '튜터설계', 'tutor.design@example.test', 'Database Design', TRUE, TIMESTAMPTZ '2026-01-05 09:10:00+09'),
    (203, '튜터검증', 'tutor.review@example.test', 'Validation', TRUE, TIMESTAMPTZ '2026-01-05 09:20:00+09');

INSERT INTO tutor_project.questions (
    id, student_id, question_code, title, body, status, created_at, updated_at
)
VALUES
    (301, 101, 'Q-2026-001', 'JOIN과 GROUP BY 차이', 'JOIN과 GROUP BY를 언제 쓰는지 궁금합니다.', 'answered', TIMESTAMPTZ '2026-01-10 10:00:00+09', TIMESTAMPTZ '2026-01-10 11:00:00+09'),
    (302, 101, 'Q-2026-002', 'ERD 관계 질문', '질문과 학습 자료 관계를 어떻게 표현하나요?', 'answered', TIMESTAMPTZ '2026-02-15 10:00:00+09', TIMESTAMPTZ '2026-02-15 12:00:00+09'),
    (303, 102, 'Q-2026-003', '트랜잭션 오류 처리', '여러 INSERT 중 하나가 실패하면 어떻게 하나요?', 'open', TIMESTAMPTZ '2026-03-20 10:00:00+09', TIMESTAMPTZ '2026-03-20 10:00:00+09'),
    (304, 103, 'Q-2026-004', '인덱스 후보 검토', '질문 목록 조회에 어떤 인덱스를 고려해야 하나요?', 'answered', TIMESTAMPTZ '2026-04-10 10:00:00+09', TIMESTAMPTZ '2026-04-10 13:00:00+09'),
    (305, 103, 'Q-2026-005', '닫힌 질문 예시', '이미 해결된 질문입니다.', 'closed', TIMESTAMPTZ '2026-05-05 10:00:00+09', TIMESTAMPTZ '2026-05-05 14:00:00+09');

INSERT INTO tutor_project.answers (id, question_id, tutor_id, answer_body, created_at)
VALUES
    (401, 301, 201, 'JOIN은 테이블을 연결하고 GROUP BY는 집계 단위를 만듭니다.', TIMESTAMPTZ '2026-01-10 10:30:00+09'),
    (402, 301, 203, '실제 요구사항을 쿼리로 검증하면서 두 개념을 비교해 보세요.', TIMESTAMPTZ '2026-01-10 10:50:00+09'),
    (403, 302, 202, '질문과 자료는 N:M이므로 연결 테이블을 둡니다.', TIMESTAMPTZ '2026-02-15 11:30:00+09'),
    (404, 304, 201, 'WHERE, JOIN, ORDER BY 패턴과 실행 계획을 기준으로 인덱스를 검토합니다.', TIMESTAMPTZ '2026-04-10 12:30:00+09'),
    (405, 305, 203, '닫힌 질문의 추가 답변 허용 여부는 별도 정책이 필요합니다.', TIMESTAMPTZ '2026-05-05 13:30:00+09');

INSERT INTO tutor_project.learning_materials (
    id, material_code, title, material_type, content_summary,
    source_url, access_scope, source_version, content_hash, is_active, updated_at
)
VALUES
    (501, 'MAT-JOIN-01', 'JOIN 기본 문서', 'article', 'JOIN의 목적과 INNER JOIN, LEFT JOIN의 기본 사용법을 설명합니다.', 'https://example.test/join', 'public', 'v1', 'demo-sha256-join-v1', TRUE, TIMESTAMPTZ '2026-01-02 09:00:00+09'),
    (502, 'MAT-GROUP-01', 'GROUP BY 실습', 'document', 'GROUP BY와 집계 함수, HAVING을 사용하는 실습 자료입니다.', 'https://example.test/group-by', 'public', 'v1', 'demo-sha256-group-v1', TRUE, TIMESTAMPTZ '2026-01-03 09:00:00+09'),
    (503, 'MAT-ERD-01', 'ERD 관계 설명', 'article', '1:N과 N:M 관계를 연결 테이블로 표현하는 방법을 설명합니다.', 'https://example.test/erd', 'public', 'v1', 'demo-sha256-erd-v1', TRUE, TIMESTAMPTZ '2026-02-02 09:00:00+09'),
    (504, 'MAT-TX-01', '트랜잭션 영상', 'video', 'COMMIT, ROLLBACK과 원자성을 설명하는 내부 교육 영상입니다.', 'https://example.test/transaction', 'internal', 'v1', 'demo-sha256-tx-v1', TRUE, TIMESTAMPTZ '2026-03-02 09:00:00+09'),
    (505, 'MAT-IDX-01', '인덱스 체크리스트', 'document', '반복 쿼리와 실행 계획을 기준으로 인덱스 후보를 평가합니다.', 'https://example.test/index', 'public', 'v1', 'demo-sha256-index-v1', TRUE, TIMESTAMPTZ '2026-04-02 09:00:00+09'),
    (506, 'MAT-OLD-01', '연결되지 않은 과거 자료', 'quiz', '현재 프로젝트와 연결되지 않은 비활성 예제 자료입니다.', 'https://example.test/orphan', 'public', 'v1', 'demo-sha256-old-v1', FALSE, TIMESTAMPTZ '2025-12-01 09:00:00+09');

INSERT INTO tutor_project.question_materials (
    question_id, material_id, display_order, note, created_at
)
VALUES
    (301, 501, 1, 'JOIN 복습', TIMESTAMPTZ '2026-01-10 11:00:00+09'),
    (301, 502, 2, '집계 실습', TIMESTAMPTZ '2026-01-10 11:00:00+09'),
    (302, 503, 1, '관계 설명', TIMESTAMPTZ '2026-02-15 12:00:00+09'),
    (303, 504, 1, '트랜잭션 개념', TIMESTAMPTZ '2026-03-20 10:30:00+09'),
    (304, 505, 1, '성능 후보', TIMESTAMPTZ '2026-04-10 13:00:00+09'),
    (305, 501, 1, '복습 자료', TIMESTAMPTZ '2026-05-05 14:00:00+09'),
    (305, 503, 2, '추가 자료', TIMESTAMPTZ '2026-05-05 14:00:00+09');

-- 명시적 ID 입력은 IDENTITY의 다음 값을 자동으로 이동시키지 않습니다.
ALTER TABLE tutor_project.students ALTER COLUMN id RESTART WITH 105;
ALTER TABLE tutor_project.tutors ALTER COLUMN id RESTART WITH 204;
ALTER TABLE tutor_project.questions ALTER COLUMN id RESTART WITH 306;
ALTER TABLE tutor_project.answers ALTER COLUMN id RESTART WITH 406;
ALTER TABLE tutor_project.learning_materials ALTER COLUMN id RESTART WITH 507;

DO $$
DECLARE
    temporal_anomaly_count BIGINT;
BEGIN
    IF (SELECT COUNT(*) FROM tutor_project.students) <> 4
       OR (SELECT COUNT(*) FROM tutor_project.tutors) <> 3
       OR (SELECT COUNT(*) FROM tutor_project.questions) <> 5
       OR (SELECT COUNT(*) FROM tutor_project.answers) <> 5
       OR (SELECT COUNT(*) FROM tutor_project.learning_materials) <> 6
       OR (SELECT COUNT(*) FROM tutor_project.question_materials) <> 7 THEN
        RAISE EXCEPTION 'Seed 검증 실패: 기준 행 수가 일치하지 않습니다.';
    END IF;

    SELECT COUNT(*) INTO temporal_anomaly_count
    FROM (
        SELECT q.id
        FROM tutor_project.questions AS q
        JOIN tutor_project.students AS s ON s.id = q.student_id
        WHERE (q.created_at AT TIME ZONE 'Asia/Seoul')::date < s.joined_at
        UNION ALL
        SELECT a.id
        FROM tutor_project.answers AS a
        JOIN tutor_project.questions AS q ON q.id = a.question_id
        JOIN tutor_project.tutors AS t ON t.id = a.tutor_id
        WHERE a.created_at < q.created_at OR a.created_at < t.created_at
        UNION ALL
        SELECT qm.question_id
        FROM tutor_project.question_materials AS qm
        JOIN tutor_project.questions AS q ON q.id = qm.question_id
        WHERE qm.created_at < q.created_at
    ) AS anomalies;

    IF temporal_anomaly_count <> 0 THEN
        RAISE EXCEPTION 'Seed 검증 실패: 시간 관계 이상이 %건 있습니다.', temporal_anomaly_count;
    END IF;

    IF (
        SELECT COUNT(*)
        FROM tutor_project.students AS s
        LEFT JOIN tutor_project.questions AS q ON q.student_id = s.id
        GROUP BY s.id
        HAVING COUNT(q.id) = 0
    ) <> 1 THEN
        RAISE EXCEPTION 'Seed 검증 실패: 질문 없는 학생은 1명이어야 합니다.';
    END IF;
END
$$;

COMMIT;

SELECT
    (SELECT COUNT(*) FROM tutor_project.students) AS students_expected_4,
    (SELECT COUNT(*) FROM tutor_project.tutors) AS tutors_expected_3,
    (SELECT COUNT(*) FROM tutor_project.questions) AS questions_expected_5,
    (SELECT COUNT(*) FROM tutor_project.answers) AS answers_expected_5,
    (SELECT COUNT(*) FROM tutor_project.learning_materials) AS materials_expected_6,
    (SELECT COUNT(*) FROM tutor_project.question_materials) AS links_expected_7;
