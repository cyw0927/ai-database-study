-- Chapter 12. 조회 패턴으로 RDBMS와 NoSQL 선택하기
--
-- 이 파일은 기존 링크 호환용 읽기 전용 안내·상태 확인 진입점입니다.
-- 기존 프로젝트 테이블을 삭제하거나 다시 만들지 않습니다.
-- nosql_lab이 아직 생성되지 않은 상태에서도 안전하게 실행할 수 있습니다.
--
-- 실제 실습 순서:
-- 1. 01_nosql_lab_schema.sql
-- 2. 02_nosql_lab_seed.sql
-- 3. 03_document_jsonb_queries.sql
-- 4. 04_key_value_cache_queries.sql
-- 5. 05_storage_choice_review.sql
-- 6. 06_jsonb_index_candidates.sql
-- 7. 07_nosql_lab_validation.sql
--
-- 처음부터 다시 시작할 때만 reset_nosql_lab.sql을 사용합니다.

SELECT current_user AS current_user_name;
SELECT current_database();
SELECT current_schema();
SHOW search_path;

-- 앞 장과 Chapter 12 객체 존재 여부 확인
SELECT
    to_regnamespace('course_project') AS course_project_schema,
    to_regnamespace('transaction_lab') AS transaction_lab_schema,
    to_regnamespace('performance_lab') AS performance_lab_schema,
    to_regnamespace('security_lab') AS security_lab_schema,
    to_regnamespace('nosql_lab') AS nosql_lab_schema,
    to_regclass('nosql_lab.course_documents') AS course_documents_table,
    to_regclass('nosql_lab.key_value_cache_examples') AS cache_examples_table,
    to_regclass('nosql_lab.storage_choice_cases') AS storage_choice_table,
    to_regclass('nosql_lab.idx_nosql_course_documents_metadata_gin')
        AS metadata_gin_index,
    to_regclass('nosql_lab.idx_nosql_course_documents_online')
        AS online_expression_index;

-- Chapter 07·08 canonical source state
-- recorded_amount는 신청 시점에 신청 행에 기록한 금액이며
-- 결제 승인액·환불 반영 순액·회계 매출을 뜻하지 않습니다.
SELECT
    COUNT(*) AS enrollment_count,
    COUNT(*) FILTER (WHERE status = '신청') AS requested_count,
    COUNT(*) FILTER (WHERE status = '수강중') AS learning_count,
    COUNT(*) FILTER (WHERE status = '완료') AS completed_count,
    COUNT(*) FILTER (WHERE status = '취소') AS cancelled_count,
    COALESCE(SUM(recorded_amount), 0) AS total_recorded_amount,
    COUNT(*) FILTER (WHERE status IN ('신청', '수강중')) AS active_count,
    COALESCE(SUM(recorded_amount) FILTER (WHERE status IN ('신청', '수강중')), 0)
        AS active_recorded_amount,
    COUNT(*) FILTER (WHERE status <> '취소') AS non_cancelled_count,
    COALESCE(SUM(recorded_amount) FILTER (WHERE status <> '취소'), 0)
        AS non_cancelled_recorded_amount
FROM course_project.enrollments;

-- canonical 기대값:
-- rows=5 / status=2·1·1·1 / total=590000 / active=3·340000 / non-cancelled=4·440000
-- course_project.enrollments.recorded_amount = NUMERIC(12,0)

-- nosql_lab 테이블 목록
SELECT
    table_schema,
    table_name
FROM information_schema.tables
WHERE table_schema = 'nosql_lab'
ORDER BY table_name;

-- 기준 행 수 조회는 01·02 파일 실행 후 사용합니다.
-- SELECT COUNT(*) FROM nosql_lab.course_documents;         -- 3
-- SELECT COUNT(*) FROM nosql_lab.key_value_cache_examples; -- 4
-- SELECT COUNT(*) FROM nosql_lab.storage_choice_cases;     -- 6

-- 캐시 4/3/1은 현재 시각이 아니라 Seed 기준(created_at과 expired_at 비교)입니다.
-- 실제 현재 유효 캐시 수는 시간이 지나면 달라질 수 있습니다.
--
-- 이 장은 별도 NoSQL 서버의 성능·분산·TTL·트랜잭션을 구현하지 않습니다.
-- PostgreSQL JSONB와 일반 테이블로 개념과 선택 기준만 검증합니다.
