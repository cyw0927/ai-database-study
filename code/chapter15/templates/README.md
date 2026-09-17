# AI 튜터링 질문 관리 서비스

## 프로젝트 목표

`tutor_project` 전용 스키마에서 학생 질문·튜터 답변·학습 자료를 관리하고, 설계·데이터·트랜잭션·반례·분석·운영·복구 결과를 다른 사람이 같은 순서로 재현하도록 구성합니다.

```text
P15 요구사항·정책
→ ERD·DDL
→ 기준 데이터·IDENTITY 조정
→ 정확한 메타데이터·업무·시간 검증
→ 트랜잭션·23개 반례/경계값
→ 인덱스 후보·PUBLIC·운영 점검
→ 고정 기간 분석 VIEW
→ 예외 기반 DB 완료 게이트
→ 같은 스냅샷의 실제 SQL·pandas 교차 검증
→ 별도 DB 복원 검증·최종 보고서
```

## 파일 구조

```text
01_schema.sql
02_seed.sql
03_metadata_validation.sql
04_requirement_queries.sql
05_transaction_checks.sql
06_negative_tests.sql
07_performance_checks.sql
08_operations_checks.sql
09_analysis_dataset.sql
10_completion_gate.sql
11_restore_validation.sql
python/
├── requirements.txt
├── .env.example
├── validation_utils.py
├── 01_load_postgresql.py
├── 02_pandas_analysis.py
└── 03_result_validation.py
OPERATIONS_RUNBOOK.md
ai_review_report.md
analysis_report.md
final_report.md
reset_tutor_project.sql
```

## 실행 순서

```text
01 → 02 → 03 → 04 → 05 → 06 → 07 → 08 → 09 → 10
→ Python 01 → 02 → 03
→ 필요 시 백업·별도 DB 복원 → 복원 DB에서 11
→ 보고서와 최종 판단
```

각 SQL은 `psql -X -v ON_ERROR_STOP=1` 또는 오류 시 중단되는 DBeaver 설정으로 실행합니다.

```bash
psql -X -U <user> -d ai_database_book -v ON_ERROR_STOP=1 -f 01_schema.sql
```

운영 DB가 아닌 개발·테스트 환경에서 실행합니다. 처음부터 다시 시작할 때만 `reset_tutor_project.sql`을 검토합니다.

## 기준 결과

| 항목 | 기대 |
| --- | ---: |
| base tables / analysis views / sequences | 6 / 4 / 5 |
| constraints / FK / business indexes | 36 / 5 / 3 |
| students·tutors·questions | 4·3·5 |
| answers·materials·links | 5·6·7 |
| IDENTITY 다음 값 | 105·204·306·406·507 이상 |
| 질문 없는 학생·연결 없는 자료 | 1·1 |
| 업무·시간 정합성 이상 | 0 |
| 반례·경계값 | 23/23, unexpected 0 |
| 질문·학생·튜터 VIEW | 5·4·3행 |
| answer_count·material_count 합계 | 5·7 |
| 첫 답변 | 4건·평균 2시간·음수 0 |
| DB 완료 게이트 | 통과 Notice |
| 실제 SQL·pandas 요약 5종 | 모두 일치 |

## 분석 범위와 행 단위

```text
기간: [2026-01-01 00:00+09, 2026-06-01 00:00+09)
question_analysis_dataset: 질문 1건
student_question_summary: 학생 1명, 질문 0건 포함
tutor_answer_summary: 튜터 1명, 답변 0건 포함
```

월별 집계는 date spine을 사용해 데이터가 없는 월도 0건으로 유지합니다.

## Python 연결

`.env.example`은 변수 이름만 제공합니다.

```text
PGHOST
PGPORT
PGDATABASE=ai_database_book
PGUSER
PGPASSFILE
```

실제 password file은 저장소 밖에 둡니다. Python은 하나의 `REPEATABLE READ, READ ONLY` 스냅샷에서 원본 테이블·VIEW·SQL 집계를 읽고 pandas 결과와 `assert_frame_equal()`로 비교합니다.

```bash
python -m pip install -r python/requirements.txt
python python/01_load_postgresql.py
python python/02_pandas_analysis.py
python python/03_result_validation.py
```

## 백업·복원

Runbook은 다음 기준을 사용합니다.

```text
도구·서버 버전
백업 계정 권한·RLS·외부 의존성
custom format + --no-owner --no-privileges
createdb -O <restore_user> -T template0
pg_restore --single-transaction
복원 DB tutor_project_restore에서 11_restore_validation.sql
```

## 완료 상태 구분

```text
10_completion_gate.sql 통과
→ DB 구조·데이터·SQL 검증 완료

Python 교차 검증 통과
→ 실제 SQL·pandas 결과 일치

11_restore_validation.sql 통과
→ 백업 파일의 별도 DB 복구 가능성 확인

Role 허용·차단 시험·문서·AI diff 승인
→ 전체 프로젝트 최종 판단 근거
```

미실행 항목은 통과로 기록하지 않습니다. `access_scope`는 데이터 분류 값이며 실제 접근 권한을 자동으로 차단하지 않습니다.
