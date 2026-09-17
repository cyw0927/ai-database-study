# Chapter 15 확장 실습 답안 템플릿

> **과제:** 데이터베이스 종합 프로젝트  
> **사용 방법:** 이 파일을 내려받아 본인의 GitHub 저장소에 `chapter15_answer.md`라는 이름으로 저장하고, 최종 프로젝트를 진행하면서 바로 작성합니다.  
> **제출 방법:** LMS에는 PDF나 ZIP을 직접 올리지 않고, **본인 GitHub 저장소의 `chapter15_answer.md` 파일 URL**을 제출합니다.

---

## 제출 전 주의

Public GitHub에는 다음 정보를 기록하지 않습니다.

```text
실제 DB 비밀번호
전체 DB 접속 URL
API Key / Token
password file 내용
실제 개인정보
민감한 서버 주소
백업 파일 자체 또는 공개 다운로드 링크
```

```text
GitHub 계정 또는 별칭:
과제 작성일:
PostgreSQL 버전:
Python 버전:
사용한 AI 도구:
프로젝트 이름:
프로젝트 한 줄 설명:
```

> **최종 프로젝트 핵심 원칙**  
> 기능 수가 많다고 완성된 프로젝트가 아닙니다.  
> **요구사항 → ERD → 실제 DB 구조 → 정상/실패 검증 → 트랜잭션 → 성능 → 운영/복구 → 분석 → AI 검토 → 재현 절차**가 서로 연결되어야 합니다.  
> **미실행 항목은 PASS가 아닙니다.**

---

# 1. 최종 제출 구조

본인 저장소에서 다음과 같이 정리하는 것을 권장합니다.

```text
assignments/chapter15/
├── chapter15_answer.md
├── project/
│   ├── README.md
│   ├── requirements.md
│   ├── erd.md
│   ├── 01_schema.sql
│   ├── 02_seed.sql
│   ├── 03_metadata_validation.sql
│   ├── 04_requirement_queries.sql
│   ├── 05_transaction_checks.sql
│   ├── 06_negative_tests.sql
│   ├── 07_performance_checks.sql
│   ├── 08_operations_checks.sql
│   ├── 09_analysis_dataset.sql
│   ├── 10_completion_gate.sql
│   ├── 11_restore_validation.sql
│   ├── python/
│   ├── OPERATIONS_RUNBOOK.md
│   ├── ai_review_report.md
│   ├── analysis_report.md
│   └── final_report.md
└── images/
```

프로젝트 상황에 따라 파일을 조정할 수 있지만 **실행 순서와 각 파일의 책임은 명확해야 합니다.**

### 실제 내 프로젝트 구조

```text

```

### 프로젝트 루트 URL

```text
https://github.com/<본인-ID>/<본인-저장소>/tree/main/assignments/chapter15/project
```

---

# 2. 프로젝트 문제와 범위 확정

Chapter 07부터 발전시킨 개인 프로젝트를 최종 범위로 정리합니다.

```text
서비스 이름:
해결하려는 문제:
주요 사용자:
핵심 업무 흐름:
```

## 2-1. 이번 최종 프로젝트에 포함하는 것

```text

```

## 2-2. 이번 프로젝트에서 제외하는 것

```text

```

## 2-3. 미확정 또는 후속 정책

최소 3개를 적습니다.

| ID | 미확정/후속 정책 | 왜 아직 확정하지 않았는가 | 다음 확인 방법 |
| --- | --- | --- | --- |
| D01 |  |  |  |
| D02 |  |  |  |
| D03 |  |  |  |

### 기능을 많이 넣는 것보다 범위를 명확히 하는 것이 중요한 이유

```text

```

---

# 3. 요구사항 추적표

핵심 요구사항을 **최소 8개 이상** 선정합니다.

| ID | 확정 요구사항 | ERD/테이블 | DDL/제약조건 | 정상 검증 | 실패/경계 검증 | 상태 |
| --- | --- | --- | --- | --- | --- | --- |
| R01 |  |  |  |  |  |  |
| R02 |  |  |  |  |  |  |
| R03 |  |  |  |  |  |  |
| R04 |  |  |  |  |  |  |
| R05 |  |  |  |  |  |  |
| R06 |  |  |  |  |  |  |
| R07 |  |  |  |  |  |  |
| R08 |  |  |  |  |  |  |

상태는 다음 중 하나만 사용합니다.

```text
PASS   실제 검증 완료
HOLD   추가 확인 필요
N/A    현재 범위 아님
```

### “구현했다”와 “검증했다”의 차이

```text

```

---

# 4. ERD와 한 행의 의미

ERD 파일 링크:

```text
./project/erd.md
```

각 핵심 테이블의 한 행 의미를 적습니다.

| 테이블 | 한 행의 의미 | PK | 주요 FK | 주요 업무 식별자/제약 |
| --- | --- | --- | --- | --- |
|  |  |  |  |  |
|  |  |  |  |  |
|  |  |  |  |  |
|  |  |  |  |  |

### N:M 관계가 있다면 어떻게 해소했나요?

```text

```

### 삭제 정책을 `CASCADE`, `RESTRICT/NO ACTION`, 별도 보관 중 무엇으로 판단했나요?

```text

```

### 증거 화면

권장 경로:

```text
assignments/chapter15/images/step04_erd.png
```

---

# 5. 깨끗한 상태에서 DB 재실행

가능하면 새 테스트 스키마 또는 초기화된 프로젝트 스키마에서 다음 순서로 다시 실행합니다.

```text
01_schema.sql
→ 02_seed.sql
→ 03_metadata_validation.sql
→ 04_requirement_queries.sql
```

## 5-1. 실행 환경

```sql
SELECT version();
SELECT current_database();
SELECT current_user;
SELECT current_schema();
SHOW search_path;
SHOW transaction_read_only;
```

```text
실제 DB:
실제 프로젝트 스키마:
```

## 5-2. 기준 Seed 상태

본인 프로젝트의 **예상 기준값을 실행 전에 먼저 작성**합니다.

| 항목 | 예상 | 실제 | PASS/HOLD |
| --- | ---: | ---: | --- |
| 핵심 테이블 1 행 수 |  |  |  |
| 핵심 테이블 2 행 수 |  |  |  |
| 핵심 테이블 3 행 수 |  |  |  |
| 핵심 관계 행 수 |  |  |  |
| 핵심 금액/수량 합계 |  |  |  |

### 수동으로 추가 작업하지 않고 다시 실행할 수 있었나요?

```text
예 / 아니오

수동 작업이 있었다면:
```

---

# 6. 메타데이터 검증

SQL 파일:

```text
./project/03_metadata_validation.sql
```

최소 다음을 PostgreSQL 실제 메타데이터에서 검증합니다.

| 검증 대상 | 기대 | 실제 | PASS/HOLD |
| --- | --- | --- | --- |
| 테이블 집합 |  |  |  |
| PK |  |  |  |
| FK |  |  |  |
| UNIQUE |  |  |  |
| CHECK |  |  |  |
| NOT NULL |  |  |  |
| 업무 인덱스 |  |  |  |
| IDENTITY/Sequence |  |  |  |

### SQL 파일에 제약조건이 적혀 있다는 것과 실제 DB 메타데이터를 확인하는 것은 왜 다른가요?

```text

```

---

# 7. 업무 질문과 정상 검증

프로젝트가 실제로 답해야 할 업무 질문을 최소 3개 작성합니다.

| 질문 ID | 업무 질문 | 결과 한 행의 의미 | 예상 결과 | 실제 결과 | 검산 방법 |
| --- | --- | --- | --- | --- | --- |
| Q01 |  |  |  |  |  |
| Q02 |  |  |  |  |  |
| Q03 |  |  |  |  |  |

### 업무 정합성 이상 조회

여러 테이블을 함께 봐야 발견할 수 있는 이상을 최소 2개 작성합니다.

```text
검증 1:
정상 기대 = 0행
실제 =

검증 2:
정상 기대 = 0행
실제 =
```

---

# 8. 실패 테스트와 정상 경계값

SQL 파일:

```text
./project/06_negative_tests.sql
```

최소 기준:

```text
실패해야 하는 테스트 6개 이상
성공해야 하는 정상 경계값 3개 이상
```

## 8-1. 실패 테스트

| ID | 입력/행동 | 기대 오류·제약 | 실제 결과 | 원본 상태 유지? | PASS/HOLD |
| --- | --- | --- | --- | --- | --- |
| N01 |  |  |  |  |  |
| N02 |  |  |  |  |  |
| N03 |  |  |  |  |  |
| N04 |  |  |  |  |  |
| N05 |  |  |  |  |  |
| N06 |  |  |  |  |  |

가능하면 다음을 기록합니다.

```text
expected SQLSTATE:
actual SQLSTATE:
expected constraint:
actual constraint:
```

## 8-2. 성공해야 하는 경계값

| ID | 경계값 | 왜 허용되어야 하는가 | 실제 결과 | PASS/HOLD |
| --- | --- | --- | --- | --- |
| B01 |  |  |  |  |
| B02 |  |  |  |  |
| B03 |  |  |  |  |

### 실패 테스트만 하고 정상 경계값을 확인하지 않으면 어떤 문제가 있나요?

```text

```

### 증거 화면

```text
assignments/chapter15/images/step08_negative_tests.png
```

---

# 9. 트랜잭션 검증

둘 이상의 변경이 함께 성공해야 하는 핵심 업무 하나를 선택합니다.

```text
업무 단위:
시작 전 상태:
잠금 또는 경쟁 가능 데이터:
변경 1:
변경 2:
추가 변경:
각 단계의 기대 영향 행 수:
COMMIT 조건:
ROLLBACK 조건:
```

## 정상 경로

```text
BEGIN 전:
트랜잭션 내부:
COMMIT 후:
```

## 실패/ROLLBACK 경로

```text
실패 조건:
ROLLBACK 후 상태:
부분 변경이 남았는가:
```

### “SQL 오류가 없었다”만으로 COMMIT하면 안 되는 이유

```text

```

---

# 10. 인덱스와 실행 계획 판단

반복될 가능성이 높은 조회 1~2개를 선택합니다.

| 조회 | 현재 계획 | 후보 인덱스 | 근거 | 데이터 규모 | 최종 판단 |
| --- | --- | --- | --- | --- | --- |
|  |  |  |  |  | 유지/보류/불필요 |
|  |  |  |  |  | 유지/보류/불필요 |

가능하면 다음을 비교합니다.

```text
EXPLAIN (ANALYZE, BUFFERS)
```

### 데이터가 작아서 Seq Scan이 나온다면 어떻게 판단했나요?

```text

```

### 인덱스를 만들지 않기로 한 판단도 설계 결정이 될 수 있나요?

```text

```

---

# 11. 보안·권한·비밀정보 점검

## 11-1. 최소 권한 계획

| 역할 | 필요한 작업 | 허용 권한 | 불필요/차단 권한 |
| --- | --- | --- | --- |
| 읽기/분석 |  |  |  |
| 서비스 쓰기 |  |  |  |
| 운영/관리 |  |  |  |

> 공유 PostgreSQL에서는 실제 Role 생성·삭제를 임의 수행하지 않습니다. 실제 Role 시험을 하지 못했다면 **미실행**으로 표시하고 PASS로 기록하지 않습니다.

## 11-2. 비밀정보 점검

- [ ] 실제 DB 비밀번호가 저장소에 없다.
- [ ] 실제 `.env`가 커밋되지 않았다.
- [ ] 실제 API Key/Token이 없다.
- [ ] 실제 개인정보가 Seed에 없다.
- [ ] 전체 DB 접속 URL이 문서에 없다.
- [ ] 백업 파일 자체가 Public GitHub에 없다.

### `access_scope` 같은 데이터 컬럼이 실제 DB 권한을 대신할 수 없는 이유

```text

```

---

# 12. 백업과 별도 DB 복원

운영 Runbook:

```text
./project/OPERATIONS_RUNBOOK.md
```

최소 흐름:

```text
pg_dump custom archive
→ archive 존재/목록/크기/해시 확인
→ 원본이 아닌 별도 DB 생성
→ pg_restore
→ 11_restore_validation.sql 실행
```

## 12-1. 백업 기록

```text
백업 범위:
pg_dump 버전:
백업 생성 성공 여부:
파일 크기:
SHA-256 확인 여부:
```

> 비밀번호, 백업 파일 자체, 공개 다운로드 URL은 답안에 넣지 않습니다.

## 12-2. 복원 검증

| 항목 | 원본 | 복원 DB | 일치? |
| --- | --- | --- | --- |
| 핵심 테이블 수 |  |  |  |
| 핵심 행 수 |  |  |  |
| 제약조건 |  |  |  |
| 인덱스 |  |  |  |
| VIEW |  |  |  |
| IDENTITY/Sequence |  |  |  |

```text
복원 DB 이름:
11_restore_validation.sql 결과:
```

### 백업 성공과 복구 성공이 다른 이유

```text

```

### 증거 화면

```text
assignments/chapter15/images/step12_restore_validation.png
```

---

# 13. SQL 분석과 pandas 교차 검증

분석 파일:

```text
./project/09_analysis_dataset.sql
./project/python/
./project/analysis_report.md
```

분석 질문을 최소 2개 작성합니다.

| 질문 | 기간 | 한 행 의미 | 지표 의미 | SQL 기준 | pandas | 일치? |
| --- | --- | --- | --- | ---: | ---: | --- |
| A01 |  |  |  |  |  |  |
| A02 |  |  |  |  |  |  |

최소 한 질문은 SQL과 pandas에서 직접 같은 값을 계산합니다.

### 같은 스냅샷에서 비교했나요?

```text
예 / 아니오

근거:
```

### 값이 다르다면 확인한 순서

```text
1.
2.
3.
```

### 그래프가 SQL↔pandas 검산을 대신할 수 없는 이유

```text

```

---

# 14. AI 최종 리뷰와 diff 검토

AI에게 프로젝트를 리뷰시킨 뒤 **채택 1개 이상 + 거절 1개 이상**을 반드시 기록합니다.

| AI 제안 | 채택/수정/보류/거절 | 근거 | 다시 실행한 검증 |
| --- | --- | --- | --- |
|  |  |  |  |
|  |  |  |  |

## diff 검토

- [ ] 요청하지 않은 파일이 수정되지 않았다.
- [ ] `DROP`, 광범위한 `DELETE`, `CASCADE`가 근거 없이 추가되지 않았다.
- [ ] 제약조건을 통과시키려고 기대값을 실제값으로 바꾸지 않았다.
- [ ] 미확정 정책을 AI가 임의 확정하지 않았다.
- [ ] 비밀번호·토큰·개인정보가 diff에 없다.
- [ ] AI가 “테스트 완료”라고 쓴 항목을 실제 실행 로그와 대조했다.

### 채택한 제안

```text
제안:
왜 채택했는가:
재검증 결과:
```

### 거절한 제안

```text
제안:
왜 거절했는가:
```

---

# 15. DB 완료 게이트

SQL 파일:

```text
./project/10_completion_gate.sql
```

```text
실행 결과:
```

DB 완료 게이트는 다음을 의미합니다.

```text
DB 구조
Seed
메타데이터
업무 검증
트랜잭션 기준 상태
실패/경계 테스트
성능/운영 점검
분석 VIEW
```

### DB 완료 게이트 통과만으로 전체 프로젝트 PASS가 아닌 이유

```text

```

---

# 16. 전체 프로젝트 최종 완료 게이트

각 항목은 실제 증거가 있을 때만 PASS로 표시합니다.

| 영역 | 상태 | 증거 파일/결과 |
| --- | --- | --- |
| 요구사항·범위 | PASS/HOLD/N/A |  |
| ERD·한 행 의미 | PASS/HOLD/N/A |  |
| 스키마·Seed 재실행 | PASS/HOLD/N/A |  |
| 메타데이터 검증 | PASS/HOLD/N/A |  |
| 업무 정합성 | PASS/HOLD/N/A |  |
| 실패·경계 테스트 | PASS/HOLD/N/A |  |
| 트랜잭션 | PASS/HOLD/N/A |  |
| 인덱스 검토 | PASS/HOLD/N/A |  |
| 권한·비밀정보 | PASS/HOLD/N/A |  |
| DB completion gate | PASS/HOLD/N/A |  |
| SQL 분석 | PASS/HOLD/N/A |  |
| pandas 교차 검증 | PASS/HOLD/N/A |  |
| 백업 생성 | PASS/HOLD/N/A |  |
| 별도 DB 복원 | PASS/HOLD/N/A |  |
| AI diff 검토 | PASS/HOLD/N/A |  |
| README 재현 절차 | PASS/HOLD/N/A |  |

### 최종 판정

다음 중 하나만 선택합니다.

```text
PASS     전체 필수 증거 확인 완료
REVIEW   핵심은 완료했지만 조건부 확인 필요
HOLD     필수 검증 또는 증거 미완료
```

```text
최종 판정:

판정 근거:

남은 위험/미실행 항목:
```

> **미실행 = PASS가 아닙니다.**

---

# 17. 재현성 시험

처음 보는 사람이 README만 보고 실행한다고 가정합니다.

README 최소 포함 항목:

- [ ] 프로젝트 목적과 사용자
- [ ] 필요 환경과 PostgreSQL/Python 버전
- [ ] DB/스키마 이름
- [ ] 실행 파일 순서
- [ ] Seed 기준 상태
- [ ] 각 검증 단계의 기대 결과
- [ ] 초기화 방법
- [ ] 파괴적 작업 주의
- [ ] 비밀정보 처리
- [ ] Python 실행 방법
- [ ] 백업/복원 방법
- [ ] 알려진 한계·미확정 정책

### README만 보고 처음부터 다시 실행해 보았나요?

```text
예 / 아니오
```

### 재실행 중 README에 빠져 있던 내용

```text

```

### 재실행 후 수정한 내용

```text

```

---

# 18. 기준 예제 `tutor_project`와 비교

Public 기준 예제:

<https://github.com/GilbertMoon/ai-database-book/tree/main/code/chapter15/templates>

기준 예제의 핵심 완료 값:

```text
base tables / views / sequences = 6 / 4 / 5
constraints / FK / business indexes = 36 / 5 / 3
students / tutors / questions = 4 / 3 / 5
answers / materials / links = 5 / 6 / 7
negative + boundary tests = 23 / 23, unexpected 0
question / student / tutor views = 5 / 4 / 3
answer_count / material_count = 5 / 7
first answer = 4건 / 평균 2시간 / 음수 0
```

### 내 프로젝트와 기준 예제에서 공통으로 적용한 검증 원칙

```text

```

### 기준 예제를 그대로 복사하지 않고 내 도메인에 맞게 바꾼 부분

```text

```

---

# 19. 최종 회고

## 가장 중요했던 설계 결정

```text

```

## 가장 위험했던 오류 또는 가정

```text

```

## 실패 테스트가 발견한 것

```text

```

## SQL↔pandas 검산이 확인한 것

```text

```

## 백업·복원 시험에서 배운 것

```text

```

## AI 제안을 거절한 경험에서 배운 것

```text

```

## 이 프로젝트를 다음 버전으로 발전시킨다면 가장 먼저 할 일

```text

```

---

# 20. 최종 제출 체크리스트

- [ ] `chapter15_answer.md` 작성 완료
- [ ] 프로젝트 요구사항/범위 문서 링크 확인
- [ ] ERD 링크 확인
- [ ] 실행 가능한 DDL/Seed 확인
- [ ] 메타데이터·업무 검증 SQL 확인
- [ ] 실패 6개 이상 + 정상 경계 3개 이상 확인
- [ ] 트랜잭션 COMMIT/ROLLBACK 증거 확인
- [ ] 인덱스 판단 근거 확인
- [ ] 비밀정보가 Public 저장소에 없는지 확인
- [ ] DB 완료 게이트 결과 확인
- [ ] SQL↔pandas 교차 검증 확인
- [ ] 백업 + 별도 DB 복원 검증 확인
- [ ] AI 제안 채택 1개 + 거절 1개 확인
- [ ] README 재현 절차 확인
- [ ] final_report 링크 확인
- [ ] GitHub 웹에서 Markdown과 이미지가 정상 표시되는지 확인

핵심 캡처는 **증거에 필요한 최소 수**만 사용합니다. 권장 예시는 다음과 같습니다.

```text
step04_erd.png
step05_clean_run.png
step08_negative_tests.png
step09_transaction.png
step12_restore_validation.png
step13_sql_pandas_validation.png
step16_final_gate.png
```

---

# 21. LMS 제출 URL

LMS에는 교수자 템플릿 URL이 아니라 **본인 저장소에서 작성 완료한 파일 URL**을 제출합니다.

```text
https://github.com/<본인-GitHub-ID>/<본인-저장소>/blob/main/assignments/chapter15/chapter15_answer.md
```

### 실제 제출 URL

```text

```
