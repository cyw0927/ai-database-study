-- Chapter 15. 답변 등록과 질문 상태 변경 트랜잭션 검증
-- P15-T01~T02: 정상 원자성과 실패 시 무변경을 검증하고 모두 ROLLBACK합니다.

SELECT current_database();
SELECT current_schema();
SHOW search_path;

DO $$
BEGIN
    IF current_database() <> 'ai_database_book' THEN
        RAISE EXCEPTION '실행 중단: 현재 데이터베이스는 %입니다.', current_database();
    END IF;
    IF (SELECT COUNT(*) FROM tutor_project.answers) <> 5
       OR (SELECT status FROM tutor_project.questions WHERE id = 303) IS DISTINCT FROM 'open' THEN
        RAISE EXCEPTION '실행 중단: answers 5행·질문 303 open 기준 상태가 필요합니다.';
    END IF;
END
$$;

-- P15-T01 정상 경로: INSERT와 조건부 UPDATE가 모두 한 번씩 성공해야 합니다.
BEGIN;

INSERT INTO tutor_project.answers (
    id, question_id, tutor_id, answer_body, created_at
)
VALUES (
    9901, 303, 201, '트랜잭션 테스트 답변입니다.',
    TIMESTAMPTZ '2026-05-20 15:00:00+09'
);

UPDATE tutor_project.questions
SET
    status = 'answered',
    updated_at = TIMESTAMPTZ '2026-05-20 15:00:00+09'
WHERE id = 303
  AND status = 'open'
RETURNING id, status;

DO $$
BEGIN
    IF (SELECT COUNT(*) FROM tutor_project.answers) <> 6
       OR (SELECT status FROM tutor_project.questions WHERE id = 303) IS DISTINCT FROM 'answered'
       OR (SELECT COUNT(*) FROM tutor_project.answers WHERE id = 9901) <> 1 THEN
        RAISE EXCEPTION 'P15-T01 실패: 정상 트랜잭션 내부 상태가 기대와 다릅니다.';
    END IF;
END
$$;

ROLLBACK;

-- 정상 경로 ROLLBACK 확인
DO $$
BEGIN
    IF (SELECT COUNT(*) FROM tutor_project.answers) <> 5
       OR (SELECT status FROM tutor_project.questions WHERE id = 303) IS DISTINCT FROM 'open'
       OR EXISTS (SELECT 1 FROM tutor_project.answers WHERE id = 9901) THEN
        RAISE EXCEPTION 'P15-T01 실패: ROLLBACK 후 기준 상태가 복구되지 않았습니다.';
    END IF;
END
$$;

-- P15-T02 실패 경로: 답변 INSERT가 실패하면 상태 UPDATE도 실행되지 않아야 합니다.
BEGIN;

DO $$
BEGIN
    BEGIN
        INSERT INTO tutor_project.answers (
            id, question_id, tutor_id, answer_body, created_at
        )
        VALUES (
            9902, 303, 999999, '실패 경로 테스트 답변입니다.',
            TIMESTAMPTZ '2026-05-20 15:10:00+09'
        );

        UPDATE tutor_project.questions
        SET status = 'answered', updated_at = TIMESTAMPTZ '2026-05-20 15:10:00+09'
        WHERE id = 303 AND status = 'open';

        RAISE EXCEPTION 'P15-T02 실패: 잘못된 튜터 답변이 성공했습니다.';
    EXCEPTION
        WHEN foreign_key_violation THEN
            NULL;
    END;

    IF EXISTS (SELECT 1 FROM tutor_project.answers WHERE id = 9902)
       OR (SELECT status FROM tutor_project.questions WHERE id = 303) IS DISTINCT FROM 'open' THEN
        RAISE EXCEPTION 'P15-T02 실패: 실패 경로에서 일부 변경이 남았습니다.';
    END IF;
END
$$;

ROLLBACK;

SELECT
    (SELECT COUNT(*) FROM tutor_project.answers) AS answers_after_expected_5,
    (SELECT status FROM tutor_project.questions WHERE id = 303) AS question_303_expected_open,
    (SELECT COUNT(*) FROM tutor_project.answers WHERE id IN (9901, 9902)) AS temporary_answers_expected_0;

SELECT 'P15-T01~T02 transaction validation passed' AS result;
