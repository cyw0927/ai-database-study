# Chapter 13 확장 실습 답안 템플릿

> **과제:** AI와 실행 증거로 데이터베이스 설계 검증하기  
> **사용 방법:** 이 파일을 내려받아 본인의 GitHub 저장소에 `chapter13_answer.md`라는 이름으로 저장한 뒤 실습하면서 바로 작성합니다.  
> **제출 방법:** LMS에는 파일을 직접 업로드하지 않고, **본인 GitHub 저장소의 `chapter13_answer.md` 파일 URL**을 제출합니다.

---

## 제출 전 주의

이 파일과 AI 프롬프트·캡처 화면에는 실제 비밀번호, 전체 DB 접속 URL, API Key, 실제 개인정보, 운영 데이터 원문을 기록하지 않습니다.

```text
GitHub 계정 또는 별칭:
과제 작성일:
PostgreSQL 버전:
사용한 AI 도구:
```

> **핵심 원칙**  
> AI 결과는 정답이 아니라 **변경 후보**입니다.  
> 실행 성공만으로 승인하지 않고 요구사항 추적, 메타데이터, 정상·경계·실패 테스트, 업무 정합성, diff를 함께 확인합니다.

---

# 1. 시작 환경과 원본 보호 상태 확인

다음을 실행합니다.

```sql
SELECT version();
SELECT current_database();
SELECT current_user;
SELECT current_schema();
SHOW search_path;
SHOW transaction_read_only;
```

| 확인 항목 | 실제 결과 | 의미 |
| --- | --- | --- |
| PostgreSQL 버전 |  |  |
| `current_database()` |  |  |
| `current_user` |  |  |
| `current_schema()` |  |  |
| `search_path` |  |  |
| `transaction_read_only` |  |  |

Chapter 07·08 기준 상태도 확인합니다.

```text
students = 3
instructors = 2
courses = 3
enrollments = 5
전체 recorded_amount = 590000
활성 = 3건 / 340000
취소 제외 = 4건 / 440000
```

### `ai_review_lab` 같은 격리 스키마에서 먼저 검증해야 하는 이유

```text

```

### 증거 화면

권장 경로:

```text
assignments/chapter13/images/step01_environment.png
```

`여기에 실행 환경 또는 사전 검사 화면을 삽입하세요.`

---

# 2. AI에게 전달할 문맥 묶음 작성

AI에게 SQL부터 요청하지 않고 다음 문맥을 먼저 정리합니다.

## 2-1. 업무 목표

```text

```

## 2-2. 확인된 요구사항

| ID | 확인된 요구사항 | 근거 |
| --- | --- | --- |
| P13-R01 |  |  |
| P13-R02 |  |  |
| P13-R03 |  |  |
| P13-R04 |  |  |
| P13-R05 |  |  |

필요하면 행을 추가합니다.

## 2-3. 이번 버전의 결정·단순화

| ID | 결정 또는 단순화 | 이유 |
| --- | --- | --- |
| P13-D01 |  |  |
| P13-D02 |  |  |
| P13-D03 |  |  |

## 2-4. 아직 확정하면 안 되는 정책

```text
미확정 정책 1:
미확정 정책 2:
미확정 정책 3:
```

## 2-5. 수정 허용/금지 범위

```text
수정 허용:

수정 금지:

운영 데이터 직접 변경 금지 여부:
Role/권한 변경 금지 여부:
```

## 2-6. 검증 기준

```text
기대 테이블/관계:
기대 행 수:
확인할 제약조건:
실패해야 하는 입력:
0행이어야 하는 이상 조회:
최종 승인 조건:
```

---

# 3. AI 제안 분류

내가 AI에게 전달한 프롬프트 요약:

```text

```

AI 제안을 최소 5개 기록합니다.

| AI 제안 | 요구사항 근거 있음? | 분류 | 최종 판단 | 이유 |
| --- | --- | --- | --- | --- |
|  |  | 확정 요구사항 반영 / 합리적 후보 / 근거 없는 정책 / 위험 변경 | 수용 / 수정 / 보류 / 거절 |  |
|  |  |  |  |  |
|  |  |  |  |  |
|  |  |  |  |  |
|  |  |  |  |  |

다음 제안이 있었다면 별도로 검토합니다.

```text
UNIQUE
NOT NULL
CASCADE
TRIGGER
RLS
DROP
DELETE
ALTER
Role/GRANT/REVOKE
```

### AI가 미확정 정책을 임의로 확정하면 위험한 이유

```text

```

---

# 4. `ai_review_lab` 생성과 나쁜 설계 관찰

다음을 실행합니다.

```text
code/chapter13/01_ai_review_lab_schema.sql
code/chapter13/02_bad_design_seed.sql
```

## 4-1. 나쁜 설계에서 발견한 문제

최소 4개를 기록합니다.

| 문제 | 왜 위험한가 | 어떤 요구사항/원칙과 충돌하는가 |
| --- | --- | --- |
|  |  |  |
|  |  |  |
|  |  |  |
|  |  |  |

## 4-2. 기준 행 수

```text
bad_enrollments 기대 = 3
실제 =
```

### SQL이 실행된다는 사실과 설계가 올바르다는 사실이 다른 이유

```text

```

---

# 5. 좋은 설계 생성과 Seed 확인

다음을 실행합니다.

```text
code/chapter13/03_good_design_schema.sql
code/chapter13/04_good_design_seed.sql
```

## 5-1. 기준 행 수

| 테이블 | 기대 | 실제 | 일치? |
| --- | ---: | ---: | --- |
| `bad_enrollments` | 3 |  |  |
| `students` | 3 |  |  |
| `instructors` | 2 |  |  |
| `courses` | 3 |  |  |
| `enrollments` | 4 |  |  |
| `payments` | 4 |  |  |

## 5-2. 금액·상태 기준

```text
enrollments.recorded_amount 합계 기대 = 470000
실제 =

payments.amount 합계 기대 = 470000
실제 =

수강 상태 기대 = 완료 2 / 신청 1 / 취소 1 / 수강중 0
실제 =

결제 상태 기대 = 결제완료 2 / 결제대기 1 / 환불 1 / 결제실패 0
실제 =
```

### `courses.price`와 `enrollments.recorded_amount`가 달라도 오류가 아닐 수 있는 이유

```text

```

---

# 6. 요구사항 추적표

최소 P13-R01~P13-R09를 기준으로 작성합니다.

| 요구사항 ID | 설계 반영 위치 | 검증 SQL/테스트 | 실행 증거 | 상태 |
| --- | --- | --- | --- | --- |
| P13-R01 |  |  |  | PASS / REVIEW |
| P13-R02 |  |  |  |  |
| P13-R03 |  |  |  |  |
| P13-R04 |  |  |  |  |
| P13-R05 |  |  |  |  |
| P13-R06 |  |  |  |  |
| P13-R07 |  |  |  |  |
| P13-R08 |  |  |  |  |
| P13-R09 |  |  |  |  |

### 요구사항 ID가 있으면 AI 결과 검토가 쉬워지는 이유

```text

```

---

# 7. PostgreSQL 메타데이터 검증

다음을 실행합니다.

```text
code/chapter13/05_metadata_validation.sql
```

본문 기준:

```text
정확한 테이블 집합 = 6개
좋은 설계 제약조건 = 29개
FK = 4개
IDENTITY id 컬럼 = 6개
금액 컬럼 3개 = NUMERIC(12,0) NOT NULL
활성 신청 부분 고유 인덱스 존재
원시 카드정보/비밀 전용 컬럼 이름 = 0개
```

| 검증 항목 | 기대 | 실제 | 일치? |
| --- | ---: | ---: | --- |
| 테이블 집합 | 6 |  |  |
| 제약조건 | 29 |  |  |
| FK | 4 |  |  |
| IDENTITY | 6 |  |  |
| 활성 신청 부분 고유 인덱스 | 존재 |  |  |

### DDL 파일만 읽는 것과 실제 메타데이터를 조회하는 것의 차이

```text

```

### 증거 화면

권장 경로:

```text
assignments/chapter13/images/step07_metadata.png
```

`여기에 메타데이터 검증 통과 화면을 삽입하세요.`

---

# 8. 업무 정합성 0행 검증

다음을 실행합니다.

```text
code/chapter13/06_business_validation.sql
```

정상 상태에서 다음 이상 조회는 모두 0행이어야 합니다.

```text
학생·강사 이메일 중복
필수 문자열 공백
신청 금액과 결제 금액 불일치
결제·환불 시각 조합 위반
고아 참조
활성 신청 중복
수강 상태와 결제 상태 조합 위반
```

## 내가 확인한 이상 조회

| 검증 항목 | 기대 | 실제 | 판단 |
| --- | ---: | ---: | --- |
|  | 0 |  |  |
|  | 0 |  |  |
|  | 0 |  |  |
|  | 0 |  |  |

### 제약조건만으로 모든 업무 정합성을 검증할 수 없는 이유

```text

```

### `LEFT JOIN`에서 NULL을 안전하게 비교해야 하는 이유

```text

```

---

# 9. 의도적 실패 + 정상 경계 테스트

> **중요:** `07_negative_tests.sql`과 다음 STEP의 `08_ai_review_lab_validation.sql`은 **같은 PostgreSQL 세션에서 연속 실행**합니다.

다음을 실행합니다.

```text
code/chapter13/07_negative_tests.sql
```

본문 기준:

```text
expected_failure = 24
expected_success = 6
전체 = 30
통과 = 30
unexpected = 0
```

## 9-1. 실패 테스트 최소 4개 상세 기록

| test_id | 실패 목적 | 예상 SQLSTATE | 실제 SQLSTATE | 예상 constraint | 실제 constraint | 통과? |
| --- | --- | --- | --- | --- | --- | --- |
|  |  |  |  |  |  |  |
|  |  |  |  |  |  |  |
|  |  |  |  |  |  |  |
|  |  |  |  |  |  |  |

## 9-2. 정상 경계값 최소 3개 기록

| test_id | 허용되어야 하는 경계 | 실제 결과 | 왜 허용되어야 하는가 |
| --- | --- | --- | --- |
|  |  |  |  |
|  |  |  |  |
|  |  |  |  |

### 실패 테스트만 하고 정상 경계값을 테스트하지 않으면 생기는 문제

```text

```

### 증거 화면

권장 경로:

```text
assignments/chapter13/images/step09_negative_tests.png
```

`여기에 30/30 또는 대표 실패 테스트 화면을 삽입하세요.`

---

# 10. 최종 자동 완료 게이트

**07과 같은 PostgreSQL 세션에서** 다음을 바로 실행합니다.

```text
code/chapter13/08_ai_review_lab_validation.sql
```

기대 메시지:

```text
Chapter 13 AI review lab validation passed: tests 30/30
```

```text
실제 메시지:
```

최종 검증 핵심:

```text
Chapter 07·08 canonical state 유지
Chapter 13 기준 행 수 = 3/3/2/3/4/4
recorded_amount 합계 = 470000
payment amount 합계 = 470000
정상 JOIN = 4
제약조건 29 / FK 4 / IDENTITY 6
업무 이상 = 0
가격 차이 정보용 행 = 1002 한 행
negative/boundary tests = 30/30
unexpected = 0
```

### 자동 완료 게이트가 통과해도 사람이 최종 승인해야 하는 이유

```text

```

---

# 11. AI 변경 diff 검토

Git 또는 수정 전/후 비교를 사용합니다.

```text
검토한 파일:
비교 방법: git diff / GitHub diff / 수동 비교
```

| 검토 항목 | 결과 | 발견 내용 |
| --- | --- | --- |
| 요청하지 않은 파일 수정 | 없음 / 있음 |  |
| `DROP` 추가 | 없음 / 있음 |  |
| 광범위한 `DELETE/UPDATE` | 없음 / 있음 |  |
| 근거 없는 `CASCADE` | 없음 / 있음 |  |
| Role/권한 변경 | 없음 / 있음 |  |
| 비밀정보/개인정보 포함 | 없음 / 있음 |  |
| 기대값을 실제값에 맞춰 변경 | 없음 / 있음 |  |
| 미확정 정책 임의 구현 | 없음 / 있음 |  |

### diff를 실행 결과와 별도로 확인해야 하는 이유

```text

```

### 증거 화면

권장 경로:

```text
assignments/chapter13/images/step11_diff.png
```

`여기에 핵심 diff 또는 수정 전/후 비교 화면을 삽입하세요.`

---

# 12. 개인 프로젝트에 AI Review 적용

Chapter 07부터 발전시킨 개인 프로젝트에서 실제 파일 하나 이상을 선택합니다.

```text
선택한 파일:
선택 이유:
```

예:

```text
requirements.md
ERD
schema.sql
seed.sql
validation.sql
analysis.sql
```

## 12-1. 개인 프로젝트 검토 계약

```text
확정 요구사항:
미확정 정책:
수정 허용 범위:
수정 금지 범위:
검증 기준:
```

## 12-2. AI 제안 최소 4개 분류

| AI 제안 | 수용 / 수정 / 보류 / 거절 | 이유 | 실행 검증 |
| --- | --- | --- | --- |
|  |  |  |  |
|  |  |  |  |
|  |  |  |  |
|  |  |  |  |

> **반드시 `수용/수정` 사례 1개 이상과 `보류/거절` 사례 1개 이상을 포함합니다.**

### AI 제안을 거절하는 것도 올바른 AI 활용인 이유

```text

```

---

# 13. 최종 승인 판단

다음 중 하나를 선택합니다.

```text
PASS   = 승인
REVIEW = 조건부 승인
HOLD   = 보류
REJECT = 거절
```

```text
최종 판정:

판정 근거:
1.
2.
3.

확인된 요구사항:

실행한 검증:

남은 가정/미확정 정책:

추가로 필요한 검증:
```

---

# 14. 최종 회고

### 14-1. AI가 가장 쉽게 임의 확정하려 한 정책은 무엇이었나요?

```text

```

### 14-2. SQL 실행 성공만으로는 찾기 어려웠던 문제는 무엇인가요?

```text

```

### 14-3. 메타데이터 검증과 실패 테스트는 각각 어떤 증거를 제공했나요?

```text

```

### 14-4. 앞으로 AI가 만든 DB 코드를 검토할 때 가장 먼저 확인할 것은 무엇인가요?

```text

```

---

# 15. 제출 전 자기 점검

- [ ] AI 답을 정답으로 취급하지 않았다.
- [ ] 확정 요구사항과 미확정 정책을 분리했다.
- [ ] 원본 프로젝트가 아닌 격리된 `ai_review_lab`에서 먼저 실행했다.
- [ ] 기준 행 수와 금액을 확인했다.
- [ ] 메타데이터 검증을 실행했다.
- [ ] 업무 정합성 이상 조회가 0행인지 확인했다.
- [ ] 의도적 실패 테스트를 실행했다.
- [ ] 정상 경계값도 확인했다.
- [ ] `07`과 `08`을 같은 PostgreSQL 세션에서 실행했다.
- [ ] 최종 `30/30` 자동 게이트를 확인했다.
- [ ] diff에서 파괴적·범위 외 변경을 검토했다.
- [ ] 비밀번호/API Key/실제 개인정보를 포함하지 않았다.
- [ ] 개인 프로젝트 AI 제안 중 수용/수정과 보류/거절을 모두 기록했다.
- [ ] 최종 승인 상태와 남은 위험을 기록했다.
- [ ] 핵심 이미지 2~4장이 GitHub에서 정상 표시된다.

---

# 16. GitHub 제출 정보

권장 구조:

```text
assignments/
└── chapter13/
    ├── chapter13_answer.md
    └── images/
        ├── step01_environment.png
        ├── step07_metadata.png
        ├── step09_negative_tests.png
        └── step11_diff.png
```

GitHub에 commit/push한 뒤 브라우저에서 **본인의 `chapter13_answer.md` 파일을 직접 열어** Markdown과 이미지를 확인합니다.

LMS 제출 URL 형식:

```text
https://github.com/<본인-GitHub-ID>/<본인-저장소>/blob/main/assignments/chapter13/chapter13_answer.md
```

### 제출하면 안 되는 것

```text
교수자 answer_template URL
저장소 홈 URL만 제출
로컬 C:\... 경로
ChatGPT 대화 URL
이미지 파일 URL만 제출
비밀번호나 접속 정보가 포함된 URL
```

### LMS에 제출할 최종 URL

```text

```
