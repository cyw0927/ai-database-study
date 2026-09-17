-- Chapter 15. 조회 패턴과 인덱스 후보·실행 계획 검토
-- P15-V05: 작은 기준 데이터에서는 인덱스 정의와 조회 패턴을 검토합니다.
-- Seq Scan이 선택되어도 자동 실패가 아니며 실제 효과는 통제된 대용량 데이터에서 측정합니다.

SELECT current_database();
SELECT current_schema();
SHOW search_path;

SELECT tablename, indexname, indexdef
FROM pg_indexes
WHERE schemaname = 'tutor_project'
  AND indexname IN (
      'idx_tutor_project_questions_student_status_created',
      'idx_tutor_project_answers_question_created',
      'idx_tutor_project_qm_material'
  )
ORDER BY indexname;

-- P15-Q01 관련: 학생별 상태별 질문 목록
EXPLAIN (COSTS, VERBOSE, FORMAT TEXT)
SELECT id, question_code, title, status, created_at
FROM tutor_project.questions
WHERE student_id = 101
  AND status = 'answered'
ORDER BY created_at DESC;

-- 질문별 답변 시간순 조회
EXPLAIN (COSTS, VERBOSE, FORMAT TEXT)
SELECT id, tutor_id, answer_body, created_at
FROM tutor_project.answers
WHERE question_id = 301
ORDER BY created_at;

-- 자료별 연결 질문 조회
EXPLAIN (COSTS, VERBOSE, FORMAT TEXT)
SELECT qm.question_id, q.question_code, q.title
FROM tutor_project.question_materials AS qm
JOIN tutor_project.questions AS q ON q.id = qm.question_id
WHERE qm.material_id = 501
ORDER BY qm.question_id;

DO $$
DECLARE
    valid_index_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO valid_index_count
    FROM pg_indexes
    WHERE schemaname = 'tutor_project'
      AND (
          (indexname = 'idx_tutor_project_questions_student_status_created'
           AND indexdef ILIKE '%USING btree (student_id, status, created_at DESC)%')
       OR (indexname = 'idx_tutor_project_answers_question_created'
           AND indexdef ILIKE '%USING btree (question_id, created_at)%')
       OR (indexname = 'idx_tutor_project_qm_material'
           AND indexdef ILIKE '%USING btree (material_id)%')
      );

    IF valid_index_count <> 3 THEN
        RAISE EXCEPTION 'P15-V05 실패: 업무 인덱스 정의는 정확히 3개여야 합니다.';
    END IF;

    RAISE NOTICE 'P15-V05 index candidate validation passed';
END
$$;

-- 실제 운영 판단 절차
-- 1. 운영과 유사한 데이터 크기·분포를 준비합니다.
-- 2. 같은 SQL의 인덱스 전·후 EXPLAIN (ANALYZE, BUFFERS)를 비교합니다.
-- 3. 실행 시간·버퍼와 INSERT·UPDATE·DELETE 비용을 함께 기록합니다.
-- 4. 중복·미사용 인덱스와 락·배포 방식을 검토한 뒤 유지 여부를 승인합니다.
