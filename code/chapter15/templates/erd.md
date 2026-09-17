# Chapter 15 ERD·분석 구조 설명

## 1. 스키마와 관계

```text
tutor_project.students 1 → 0..N questions
tutor_project.questions 1 → 0..N answers
tutor_project.tutors 1 → 0..N answers
tutor_project.questions 1 → 0..N question_materials
tutor_project.learning_materials 1 → 0..N question_materials
```

질문과 학습 자료의 N:M 관계는 `question_materials`로 해소합니다. 모든 FK는 현재 `RESTRICT`이며 요구사항 없이 CASCADE를 사용하지 않습니다.

## 2. 테이블별 역할

| 테이블 | 역할 | 주요 제약 |
| --- | --- | --- |
| `students` | 질문 등록 학생 | IDENTITY PK, email 공백 CHECK·UNIQUE |
| `tutors` | 답변 작성 튜터 | IDENTITY PK, email 공백 CHECK·UNIQUE |
| `questions` | 질문·상태·시각 | student FK, code UNIQUE, 상태·시간 CHECK |
| `answers` | 질문별 튜터 답변 | question·tutor FK, 본문 CHECK |
| `learning_materials` | 학습 자료 메타데이터 | code UNIQUE, 유형·범위·문자열 CHECK |
| `question_materials` | 질문·자료 연결 | 복합 PK, 표시 순서 UNIQUE·CHECK |

### 외래키 5개

| 제약조건 | 자식 컬럼 | 부모 컬럼 | 삭제 규칙 |
| --- | --- | --- | --- |
| `fk_tutor_project_questions_student` | questions.student_id | students.id | RESTRICT |
| `fk_tutor_project_answers_question` | answers.question_id | questions.id | RESTRICT |
| `fk_tutor_project_answers_tutor` | answers.tutor_id | tutors.id | RESTRICT |
| `fk_tutor_project_qm_question` | question_materials.question_id | questions.id | RESTRICT |
| `fk_tutor_project_qm_material` | question_materials.material_id | learning_materials.id | RESTRICT |

## 3. 시간 규칙

```text
questions.updated_at >= questions.created_at
질문 작성일 >= 학생 가입일                 검증 SQL
답변 작성 시각 >= 질문 작성 시각           검증 SQL
답변 작성 시각 >= 튜터 생성 시각           검증 SQL
자료 연결 시각 >= 질문 작성 시각           검증 SQL
```

테이블 내부 규칙은 CHECK로, 여러 테이블을 함께 보는 규칙은 `04_requirement_queries.sql`과 완료 게이트에서 검증합니다.

## 4. 업무 인덱스

| 인덱스 | 조회 패턴 |
| --- | --- |
| `questions(student_id, status, created_at DESC)` | 학생별 상태별 질문 |
| `answers(question_id, created_at)` | 질문별 답변 시간순 조회 |
| `question_materials(material_id)` | 자료별 연결 질문 |

작은 Seed에서는 Seq Scan이 정상일 수 있습니다. 인덱스 효과는 운영과 유사한 데이터로 전·후 실행 계획과 쓰기 비용을 함께 측정합니다.

## 5. 분석 구조

```text
analysis_parameters
→ 고정 기간 [2026-01-01 00:00+09, 2026-06-01 00:00+09)

question_analysis_dataset
→ 한 행 = 질문 1건

student_question_summary
→ 한 행 = 학생 1명, 질문 0건 포함

tutor_answer_summary
→ 한 행 = 튜터 1명, 답변 0건 포함
```

`answers`와 `question_materials`를 질문에 동시에 직접 JOIN하면 답변 수×자료 수로 행이 늘어날 수 있습니다. 두 자식 집합을 각각 질문별로 먼저 집계한 뒤 연결합니다.

검증 기준:

```text
질문 VIEW 5행·question_id 중복 0
answer_count 합계 5·material_count 합계 7
학생 VIEW 4행·질문 0건 학생 1명
튜터 VIEW 3행·답변 합계 5
첫 답변 4건·평균 2시간·음수 0
```

## 6. 미확정 정책

```text
P15-D02 같은 튜터의 복수 답변
P15-D03 상태 자동 변경 방식
P15-D04 closed 질문 추가 답변
P15-D05 비활성 학생·튜터의 신규 작업
P15-D07 삭제·보관 정책의 다음 버전
P15-D08 access_scope를 실제 접근 통제로 연결하는 방식
```

## 7. 설계 메모

```text
- 명시적 ID 입력 후 IDENTITY 다음 값을 조정한다.
- updated_at은 자동 갱신되지 않으므로 작성 경로가 책임진다.
- access_scope는 데이터 값이며 권한 통제가 아니다.
- content_hash의 demo-sha256-*는 실제 해시가 아닌 가상 예시다.
- 실제 구조는 PostgreSQL 카탈로그와 10_completion_gate.sql로 검증한다.
- Python은 같은 읽기 전용 스냅샷의 SQL 결과와 pandas 결과를 비교한다.
```
