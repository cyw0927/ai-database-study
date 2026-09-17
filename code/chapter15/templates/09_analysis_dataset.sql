-- Chapter 15. 분석 데이터셋과 SQL 기준 결과
-- P15-V07: 고정 반개방 기간 안에서 질문·학생·튜터 분석 단위를 분리합니다.

SELECT current_database();
SELECT current_schema();
SHOW search_path;

-- P15-R12: 한 행은 질문 1건
CREATE OR REPLACE VIEW tutor_project.question_analysis_dataset AS
WITH params AS (
    SELECT start_at, end_at_exclusive
    FROM tutor_project.analysis_parameters
),
answer_summary AS (
    SELECT
        a.question_id,
        COUNT(*) AS answer_count,
        MIN(a.created_at) AS first_answer_at
    FROM tutor_project.answers AS a
    CROSS JOIN params AS p
    WHERE a.created_at >= p.start_at
      AND a.created_at < p.end_at_exclusive
    GROUP BY a.question_id
),
material_summary AS (
    SELECT question_id, COUNT(*) AS material_count
    FROM tutor_project.question_materials
    GROUP BY question_id
)
SELECT
    q.id AS question_id,
    q.question_code,
    q.created_at AS question_created_at,
    DATE_TRUNC('month', q.created_at AT TIME ZONE 'Asia/Seoul')::date AS question_month,
    s.id AS student_id,
    s.name AS student_name,
    q.status,
    COALESCE(a.answer_count, 0) AS answer_count,
    a.first_answer_at,
    CASE
        WHEN a.first_answer_at IS NULL THEN NULL
        ELSE ROUND(EXTRACT(EPOCH FROM (a.first_answer_at - q.created_at)) / 3600.0, 2)
    END AS first_response_hours,
    COALESCE(m.material_count, 0) AS material_count,
    COALESCE(a.answer_count, 0) > 0 AS has_answer,
    COALESCE(m.material_count, 0) > 0 AS has_material
FROM tutor_project.questions AS q
JOIN tutor_project.students AS s ON s.id = q.student_id
LEFT JOIN answer_summary AS a ON a.question_id = q.id
LEFT JOIN material_summary AS m ON m.question_id = q.id
CROSS JOIN params AS p
WHERE q.created_at >= p.start_at
  AND q.created_at < p.end_at_exclusive;

-- P15-Q02: 질문이 없는 학생도 포함하는 학생 단위 VIEW
CREATE OR REPLACE VIEW tutor_project.student_question_summary AS
WITH params AS (
    SELECT start_at, end_at_exclusive
    FROM tutor_project.analysis_parameters
)
SELECT
    s.id AS student_id,
    s.name AS student_name,
    COUNT(q.id) AS question_count
FROM tutor_project.students AS s
CROSS JOIN params AS p
LEFT JOIN tutor_project.questions AS q
  ON q.student_id = s.id
 AND q.created_at >= p.start_at
 AND q.created_at < p.end_at_exclusive
GROUP BY s.id, s.name;

-- P15-Q03: 답변이 없는 튜터도 포함하는 튜터 단위 VIEW
CREATE OR REPLACE VIEW tutor_project.tutor_answer_summary AS
WITH params AS (
    SELECT start_at, end_at_exclusive
    FROM tutor_project.analysis_parameters
)
SELECT
    t.id AS tutor_id,
    t.name AS tutor_name,
    COUNT(a.id) AS answer_count
FROM tutor_project.tutors AS t
CROSS JOIN params AS p
LEFT JOIN tutor_project.answers AS a
  ON a.tutor_id = t.id
 AND a.created_at >= p.start_at
 AND a.created_at < p.end_at_exclusive
GROUP BY t.id, t.name;

-- 질문 단위 기본 검증
SELECT *
FROM tutor_project.question_analysis_dataset
ORDER BY question_id;

SELECT
    COUNT(*) AS dataset_rows_expected_5,
    COUNT(DISTINCT question_id) AS distinct_questions_expected_5,
    SUM(answer_count) AS answer_count_sum_expected_5,
    SUM(material_count) AS material_count_sum_expected_7,
    COUNT(*) FILTER (WHERE has_answer = FALSE) AS no_answer_questions_expected_1
FROM tutor_project.question_analysis_dataset;

-- P15-Q01 상태별 질문 수
SELECT status, COUNT(*) AS question_count
FROM tutor_project.question_analysis_dataset
GROUP BY status
ORDER BY status;

-- P15-Q02 학생별 질문 수: 4명, 질문 없는 학생 0건 포함
SELECT *
FROM tutor_project.student_question_summary
ORDER BY student_id;

-- P15-Q03 튜터별 답변 수: 2·1·2
SELECT *
FROM tutor_project.tutor_answer_summary
ORDER BY tutor_id;

-- P15-Q04 월별 질문 수: 데이터가 없는 월도 0건으로 유지
WITH params AS (
    SELECT start_at, end_at_exclusive
    FROM tutor_project.analysis_parameters
), months AS (
    SELECT generate_series(
        DATE_TRUNC('month', start_at AT TIME ZONE 'Asia/Seoul')::date,
        (DATE_TRUNC('month', end_at_exclusive AT TIME ZONE 'Asia/Seoul') - INTERVAL '1 month')::date,
        INTERVAL '1 month'
    )::date AS question_month
    FROM params
), monthly AS (
    SELECT
        question_month,
        COUNT(*) AS question_count,
        SUM(answer_count) AS answer_count,
        SUM(material_count) AS material_count
    FROM tutor_project.question_analysis_dataset
    GROUP BY question_month
)
SELECT
    m.question_month,
    COALESCE(a.question_count, 0) AS question_count,
    COALESCE(a.answer_count, 0) AS answer_count,
    COALESCE(a.material_count, 0) AS material_count
FROM months AS m
LEFT JOIN monthly AS a ON a.question_month = m.question_month
ORDER BY m.question_month;

-- P15-Q05 질문별 답변·자료 수
SELECT question_id, question_code, answer_count, material_count
FROM tutor_project.question_analysis_dataset
ORDER BY question_id;

-- P15-Q06 첫 답변 시간: 답변 있는 4건, 평균 2시간
SELECT
    COUNT(*) FILTER (WHERE has_answer) AS answered_questions_expected_4,
    ROUND(AVG(first_response_hours) FILTER (WHERE has_answer), 2) AS avg_first_response_hours_expected_2,
    MIN(first_response_hours) FILTER (WHERE has_answer) AS min_first_response_hours_expected_0_50,
    MAX(first_response_hours) FILTER (WHERE has_answer) AS max_first_response_hours_expected_3_50
FROM tutor_project.question_analysis_dataset;

DO $$
BEGIN
    IF (SELECT COUNT(*) FROM tutor_project.question_analysis_dataset) <> 5
       OR (SELECT COUNT(*) FROM tutor_project.student_question_summary) <> 4
       OR (SELECT COUNT(*) FROM tutor_project.tutor_answer_summary) <> 3
       OR (SELECT COUNT(*) FROM tutor_project.question_analysis_dataset WHERE first_response_hours < 0) <> 0 THEN
        RAISE EXCEPTION 'P15-V07 실패: 분석 VIEW 행 수 또는 시간 정합성이 다릅니다.';
    END IF;

    RAISE NOTICE 'P15-V07 analysis dataset validation passed';
END
$$;
