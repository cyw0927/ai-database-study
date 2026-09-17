# Chapter 15 코드 자료

## 데이터베이스 종합 프로젝트

`code/chapter15/templates/`는 `tutor_project`에서 요구사항·구조·Seed·트랜잭션·반례·인덱스·권한·복구와 실제 SQL·pandas 분석을 검증하는 최종 프로젝트 패키지입니다.

## 보호 범위

```text
course_project·transaction_lab·performance_lab
security_lab·nosql_lab·ai_review_lab·analysis_lab·public
→ 변경하지 않음

tutor_project
→ Chapter 15 생성·검증·분석·초기화 대상
```

## 폴더 구조

```text
code/chapter15/templates/
├── README.md
├── requirements.md
├── erd.md
├── 01_schema.sql
├── 02_seed.sql
├── 03_metadata_validation.sql
├── 04_requirement_queries.sql
├── 05_transaction_checks.sql
├── 06_negative_tests.sql
├── 07_performance_checks.sql
├── 08_operations_checks.sql
├── 09_analysis_dataset.sql
├── 10_completion_gate.sql
├── 11_restore_validation.sql
├── python/
│   ├── requirements.txt
│   ├── .env.example
│   ├── validation_utils.py
│   ├── 01_load_postgresql.py
│   ├── 02_pandas_analysis.py
│   └── 03_result_validation.py
├── OPERATIONS_RUNBOOK.md
├── ai_review_report.md
├── analysis_report.md
├── final_report.md
├── reset_tutor_project.sql
├── schema.sql
├── seed.sql
└── queries.sql
```

마지막 세 SQL은 기존 링크 호환용 안내 파일입니다.

## 실행 순서

```text
01 → 02 → 03 → 04 → 05 → 06 → 07 → 08 → 09 → 10
→ Python 01 → 02 → 03
→ 백업·별도 DB 복원 → 복원 DB에서 11
→ 보고서·AI diff·최종 판단
```

처음부터 다시 시작할 때만 보호 구문이 포함된 `reset_tutor_project.sql`을 사용합니다.

## 기준 결과

| 항목 | 기대 |
| --- | ---: |
| base tables / views / sequences | 6 / 4 / 5 |
| constraints / FK / business indexes | 36 / 5 / 3 |
| students·tutors·questions | 4·3·5 |
| answers·materials·links | 5·6·7 |
| IDENTITY 다음 값 | 105·204·306·406·507 이상 |
| 업무·시간 정합성 이상 | 0 |
| 반례·경계값 | 23/23, unexpected 0 |
| 질문·학생·튜터 VIEW | 5·4·3행 |
| answer_count·material_count | 5·7 |
| 첫 답변 | 4건·평균 2시간·음수 0 |
| DB 완료 게이트 | passed Notice |
| 실제 SQL·pandas 요약 | 5종 일치 |
| 별도 DB 복원 검증 | passed Notice |

## Python 보안·검증

```text
PGHOST·PGPORT·PGDATABASE·PGUSER·PGPASSFILE
REPEATABLE READ, READ ONLY
정확한 컬럼·자료형·행 단위 검증
실제 SQL 결과와 pandas 결과 직접 비교
```

`DATABASE_URL`에 비밀번호를 기록하지 않으며 실제 password file은 저장소 밖에서 보호합니다.

## 완료 기준 구분

```text
10 통과
→ DB 구조·데이터·SQL 검증 완료

Python 03 통과
→ 같은 스냅샷의 SQL·pandas 결과 일치

11 통과
→ 백업의 별도 DB 복구 가능성 확인

실제 Role 시험·문서·AI diff 승인
→ 전체 프로젝트 최종 판단 근거
```

미실행 항목은 통과로 기록하지 않습니다. `access_scope`는 업무 분류이며 실제 접근 권한이 아닙니다.
