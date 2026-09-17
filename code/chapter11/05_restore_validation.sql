-- Chapter 11. 복원 검증 파일 경로 변경 안내
-- 이 파일은 기존 링크 호환을 위해 유지합니다.
-- 최종 복원 검증은 다음 파일을 사용합니다.
--
-- code/chapter11/06_restore_validation.sql
--
-- 06 파일은 ai_database_book_restore가 아닌 데이터베이스에서 실행하면
-- 예외를 발생시켜 원본 DB를 복원 성공으로 잘못 판정하는 문제를 막습니다.
-- 또한 구조·데이터·제약조건·부분 고유 인덱스·IDENTITY·소유권을 자동 검증합니다.

SELECT current_user AS current_user_name;
SELECT current_database();
SELECT current_schema();
SHOW search_path;

SELECT
    'code/chapter11/06_restore_validation.sql을 실행하세요.'
        AS next_action;
