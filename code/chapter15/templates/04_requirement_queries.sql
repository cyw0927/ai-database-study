-- Chapter 15. 요구사항별 업무 조회와 정합성 검증
-- P15-V04: 확정 요구사항·경계 사례·시간 관계를 읽기 전용으로 검증합니다.

SELECT current_database();
SELECT current_schema();
SHOW search_path;

-- P15-R01: 학생과 질문 연결, 기대 5행
SELECT
    q.id AS question_id,
    q.question_code,
    s.id AS student_id,
    s.name AS student_name,
    s.email,
    q.title,
    q.status,
    q.created_at
FROM tutor_project.questions AS q
JOIN tutor_project.students AS s ON s.id = q.student_id
ORDER BY q.id;

-- P15-R05: 질문별 답변 수, 기대 5행
SELECT
    q.id AS question_id,
    q.question_code,
    q.title,
    q.status,
    COUNT(a.id) AS answer_count
FROM tutor_project.questions AS q
LEFT JOIN tutor_project.answers AS a ON a.question_id = q.id
GROUP BY q.id, q.question_code, q.title, q.status
ORDER BY q.id;

-- P15-R06: 답변과 튜터 연결, 기대 5행
SELECT
    a.id AS answer_id,
    q.question_code,
    t.id AS tutor_id,
    t.name AS tutor_name,
    t.specialty,
    a.answer_body,
    a.created_at
FROM tutor_project.answers AS a
JOIN tutor_project.questions AS q ON q.id = a.question_id
JOIN tutor_project.tutors AS t ON t.id = a.tutor_id
ORDER BY a.id;

-- P15-R07·P15-R10: 질문과 학습 자료 N:M 및 표시 순서, 기대 7행
SELECT
    q.question_code,
    m.material_code,
    m.title AS material_title,
    m.material_type,
    m.access_scope,
    m.is_active,
    qm.display_order,
    qm.note
FROM tutor_project.question_materials AS qm
JOIN tutor_project.questions AS q ON q.id = qm.question_id
JOIN tutor_project.learning_materials AS m ON m.id = qm.material_id
ORDER BY q.id, qm.display_order;

-- P15-R08: 질문이 없는 학생, 기대 1행
SELECT
    s.id,
    s.name,
    s.email,
    COUNT(q.id) AS question_count
FROM tutor_project.students AS s
LEFT JOIN tutor_project.questions AS q ON q.student_id = s.id
GROUP BY s.id, s.name, s.email
HAVING COUNT(q.id) = 0
ORDER BY s.id;

-- P15-R09: 연결되지 않은 자료, 기대 1행
SELECT
    m.id,
    m.material_code,
    m.title,
    m.is_active,
    COUNT(qm.question_id) AS linked_question_count
FROM tutor_project.learning_materials AS m
LEFT JOIN tutor_project.question_materials AS qm ON qm.material_id = m.id
GROUP BY m.id, m.material_code, m.title, m.is_active
HAVING COUNT(qm.question_id) = 0
ORDER BY m.id;

-- 경계 사례: open·답변 없음 1건, 답변 2개 질문 1건
SELECT
    COUNT(*) FILTER (WHERE answer_count = 0 AND status = 'open') AS open_without_answer_expected_1,
    COUNT(*) FILTER (WHERE answer_count = 2) AS two_answer_question_expected_1
FROM (
    SELECT q.id, q.status, COUNT(a.id) AS answer_count
    FROM tutor_project.questions AS q
    LEFT JOIN tutor_project.answers AS a ON a.question_id = q.id
    GROUP BY q.id, q.status
) AS counts;

-- 확정 정합성 이상: 모두 0행
SELECT q.*
FROM tutor_project.questions AS q
LEFT JOIN tutor_project.students AS s ON s.id = q.student_id
WHERE s.id IS NULL;

SELECT a.*
FROM tutor_project.answers AS a
LEFT JOIN tutor_project.questions AS q ON q.id = a.question_id
LEFT JOIN tutor_project.tutors AS t ON t.id = a.tutor_id
WHERE q.id IS NULL OR t.id IS NULL;

SELECT qm.*
FROM tutor_project.question_materials AS qm
LEFT JOIN tutor_project.questions AS q ON q.id = qm.question_id
LEFT JOIN tutor_project.learning_materials AS m ON m.id = qm.material_id
WHERE q.id IS NULL OR m.id IS NULL;

SELECT q.id, q.question_code
FROM tutor_project.questions AS q
LEFT JOIN tutor_project.answers AS a ON a.question_id = q.id
WHERE q.status = 'answered'
GROUP BY q.id, q.question_code
HAVING COUNT(a.id) = 0;

SELECT question_id, display_order, COUNT(*) AS duplicate_count
FROM tutor_project.question_materials
GROUP BY question_id, display_order
HAVING COUNT(*) > 1;

-- 시간 관계 이상: 모두 0행
SELECT q.id, s.joined_at, q.created_at
FROM tutor_project.questions AS q
JOIN tutor_project.students AS s ON s.id = q.student_id
WHERE (q.created_at AT TIME ZONE 'Asia/Seoul')::date < s.joined_at;

SELECT a.id, q.created_at AS question_created_at, a.created_at AS answer_created_at
FROM tutor_project.answers AS a
JOIN tutor_project.questions AS q ON q.id = a.question_id
WHERE a.created_at < q.created_at;

SELECT a.id, t.created_at AS tutor_created_at, a.created_at AS answer_created_at
FROM tutor_project.answers AS a
JOIN tutor_project.tutors AS t ON t.id = a.tutor_id
WHERE a.created_at < t.created_at;

SELECT qm.question_id, qm.material_id, q.created_at AS question_created_at, qm.created_at AS linked_at
FROM tutor_project.question_materials AS qm
JOIN tutor_project.questions AS q ON q.id = qm.question_id
WHERE qm.created_at < q.created_at;

-- P15-D02~D05: 다음은 현재 샘플 관찰이며 아직 일반 제약조건이 아닙니다.
SELECT
    q.status,
    COUNT(a.id) AS answer_count,
    COUNT(*) AS question_rows
FROM tutor_project.questions AS q
LEFT JOIN tutor_project.answers AS a ON a.question_id = q.id
GROUP BY q.id, q.status
ORDER BY q.id;

SELECT
    (SELECT COUNT(*) FROM tutor_project.students WHERE is_active = FALSE) AS inactive_students,
    (SELECT COUNT(*) FROM tutor_project.tutors WHERE is_active = FALSE) AS inactive_tutors;

DO $$
DECLARE
    anomaly_count BIGINT;
BEGIN
    IF (SELECT COUNT(*) FROM tutor_project.students) <> 4
       OR (SELECT COUNT(*) FROM tutor_project.tutors) <> 3
       OR (SELECT COUNT(*) FROM tutor_project.questions) <> 5
       OR (SELECT COUNT(*) FROM tutor_project.answers) <> 5
       OR (SELECT COUNT(*) FROM tutor_project.learning_materials) <> 6
       OR (SELECT COUNT(*) FROM tutor_project.question_materials) <> 7 THEN
        RAISE EXCEPTION 'P15-V04 실패: 기준 행 수가 다릅니다.';
    END IF;

    SELECT COUNT(*) INTO anomaly_count
    FROM (
        SELECT q.id::text AS anomaly_id
        FROM tutor_project.questions AS q
        LEFT JOIN tutor_project.students AS s ON s.id = q.student_id
        WHERE s.id IS NULL
        UNION ALL
        SELECT a.id::text
        FROM tutor_project.answers AS a
        LEFT JOIN tutor_project.questions AS q ON q.id = a.question_id
        LEFT JOIN tutor_project.tutors AS t ON t.id = a.tutor_id
        WHERE q.id IS NULL OR t.id IS NULL
        UNION ALL
        SELECT (qm.question_id::text || ':' || qm.material_id::text)
        FROM tutor_project.question_materials AS qm
        LEFT JOIN tutor_project.questions AS q ON q.id = qm.question_id
        LEFT JOIN tutor_project.learning_materials AS m ON m.id = qm.material_id
        WHERE q.id IS NULL OR m.id IS NULL
        UNION ALL
        SELECT q.id::text
        FROM tutor_project.questions AS q
        LEFT JOIN tutor_project.answers AS a ON a.question_id = q.id
        WHERE q.status = 'answered'
        GROUP BY q.id
        HAVING COUNT(a.id) = 0
        UNION ALL
        SELECT q.id::text
        FROM tutor_project.questions AS q
        JOIN tutor_project.students AS s ON s.id = q.student_id
        WHERE (q.created_at AT TIME ZONE 'Asia/Seoul')::date < s.joined_at
        UNION ALL
        SELECT a.id::text
        FROM tutor_project.answers AS a
        JOIN tutor_project.questions AS q ON q.id = a.question_id
        JOIN tutor_project.tutors AS t ON t.id = a.tutor_id
        WHERE a.created_at < q.created_at OR a.created_at < t.created_at
        UNION ALL
        SELECT (qm.question_id::text || ':' || qm.material_id::text)
        FROM tutor_project.question_materials AS qm
        JOIN tutor_project.questions AS q ON q.id = qm.question_id
        WHERE qm.created_at < q.created_at
    ) AS anomalies;

    IF anomaly_count <> 0 THEN
        RAISE EXCEPTION 'P15-V04 실패: 업무·시간 정합성 이상이 %건 있습니다.', anomaly_count;
    END IF;

    IF (
        SELECT COUNT(*)
        FROM (
            SELECT s.id
            FROM tutor_project.students AS s
            LEFT JOIN tutor_project.questions AS q ON q.student_id = s.id
            GROUP BY s.id
            HAVING COUNT(q.id) = 0
        ) AS no_question_students
    ) <> 1 THEN
        RAISE EXCEPTION 'P15-V04 실패: 질문 없는 학생은 1명이어야 합니다.';
    END IF;

    IF (
        SELECT COUNT(*)
        FROM (
            SELECT m.id
            FROM tutor_project.learning_materials AS m
            LEFT JOIN tutor_project.question_materials AS qm ON qm.material_id = m.id
            GROUP BY m.id
            HAVING COUNT(qm.question_id) = 0
        ) AS unlinked_materials
    ) <> 1 THEN
        RAISE EXCEPTION 'P15-V04 실패: 연결되지 않은 자료는 1건이어야 합니다.';
    END IF;

    RAISE NOTICE 'P15-V04 requirement validation passed';
END
$$;
