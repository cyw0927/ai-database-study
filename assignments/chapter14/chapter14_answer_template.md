# Chapter 14 확장 실습 답안 템플릿

> **과제:** SQL 데이터 분석과 Python 확장  
> **사용 방법:** 이 파일을 내려받아 본인의 GitHub 저장소에 `chapter14_answer.md`라는 이름으로 저장한 뒤 실습하면서 바로 작성합니다.  
> **제출 방법:** LMS에는 파일을 직접 업로드하지 않고, **본인 GitHub 저장소의 `chapter14_answer.md` 파일 URL**을 제출합니다.

---

## 제출 전 주의

이 파일과 캡처 화면에는 실제 비밀번호, 전체 DB 접속 URL, API Key, password file 내용, 실제 개인정보를 기록하지 않습니다.

```text
GitHub 계정 또는 별칭:
과제 작성일:
PostgreSQL 버전:
Python 버전:
사용한 AI 도구:
데이터 읽기 방식: PostgreSQL 직접 연결 / CSV
```

> **핵심 원칙**  
> 그래프가 만들어졌다고 분석이 검증된 것은 아닙니다.  
> **질문 → 기간 → 한 행의 의미 → 지표 정의 → SQL 기준값 → pandas 결과 → 교차 검증**이 모두 일치해야 합니다.

---

# 1. 시작 환경 확인

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

Python도 확인합니다.

```bash
python --version
```

```text
Python 버전:
```

### 분석용 Python 연결을 읽기 전용으로 사용하는 이유

```text

```

---

# 2. 분석 질문 계약 작성

Chapter 14의 기준 질문은 다음과 같습니다.

```text
P14-Q01 상태별 수강신청 건수
P14-Q02 월별 신청 건수와 신청 시점 기록 금액
P14-Q03 강의별 신청 건수
P14-Q04 지역별 학생 수와 신청 건수
P14-Q05 완료된 신청의 완료 기간
```

그중 최소 2개를 골라 SQL보다 먼저 분석 계약을 작성합니다.

## 질문 A

```text
질문 ID:
업무 질문:
분석 기간:
날짜 기준:
한 행의 의미:
포함 상태:
제외 상태:
지표 이름:
지표의 업무 의미:
예상 검산 방법:
```

## 질문 B

```text
질문 ID:
업무 질문:
분석 기간:
날짜 기준:
한 행의 의미:
포함 상태:
제외 상태:
지표 이름:
지표의 업무 의미:
예상 검산 방법:
```

Chapter 14 기준 분석 기간:

```text
[2026-01-01, 2026-07-01)
```

### 반개방 구간 `[start, end)`을 사용하는 이유

```text

```

### `recorded_amount`의 정확한 업무 의미

```text

```

### 왜 `recorded_amount`를 실제 결제 매출 또는 회계 매출이라고 부르면 안 되나요?

```text

```

---

# 3. `analysis_lab` 생성과 Seed 기준 확인

다음 파일을 순서대로 실행합니다.

```text
code/chapter14/01_analysis_lab_schema.sql
code/chapter14/02_analysis_lab_seed.sql
```

기준 상태:

| 객체 | 기대값 | 실제값 | 일치? |
| --- | ---: | ---: | --- |
| `students` | 8 |  |  |
| `instructors` | 3 |  |  |
| `courses` | 5 |  |  |
| `enrollments` | 24 |  |  |

IDENTITY 다음 값도 확인한 경우 기록합니다.

```text
students 다음 값:
instructors 다음 값:
courses 다음 값:
enrollments 다음 값:
```

본문 기준:

```text
students = 109 이상
instructors = 204 이상
courses = 306 이상
enrollments = 1025 이상
```

### `analysis_lab`을 기존 `course_project`와 분리한 이유

```text

```

### 증거 화면

권장 경로:

```text
assignments/chapter14/images/step03_seed_baseline.png
```

`여기에 기준 행 수 또는 Seed 검증 화면을 삽입하세요.`

---

# 4. 집계 전에 데이터 품질 검사

다음을 실행합니다.

```text
code/chapter14/03_data_quality_checks.sql
```

정상 기준에서는 다음 이상 건수가 모두 0이어야 합니다.

| 품질 검사 | 예상 | 실제 | 통과? |
| --- | ---: | ---: | --- |
| PK 또는 분석 VIEW 중복 | 0 |  |  |
| 고아 학생 FK | 0 |  |  |
| 고아 강의 FK | 0 |  |  |
| 고아 강사 FK | 0 |  |  |
| 완료인데 `completed_at` 없음 | 0 |  |  |
| 미완료인데 `completed_at` 존재 | 0 |  |  |
| 완료일 < 신청일 | 0 |  |  |
| 신청일 < 학생 가입일 | 0 |  |  |
| 신청일 < 강의 개설일 | 0 |  |  |
| 음수 `recorded_amount` | 0 |  |  |
| 취소 후 기록 금액이 0으로 덮인 행 | 0 |  |  |
| 분석 기간 밖 기준 데이터 | 0 |  |  |
| 활성 신청 중복 | 0 |  |  |

### 품질 검사를 집계보다 먼저 해야 하는 이유

```text

```

### SQL이 정상 실행돼도 원본 품질이 잘못되면 분석 결과를 신뢰할 수 없는 이유

```text

```

---

# 5. SQL 기준 결과 만들기

다음을 실행합니다.

```text
code/chapter14/04_summary_analysis.sql
code/chapter14/05_period_category_analysis.sql
```

## 5-1. 전체 기준

```text
전체 신청 행 수 기대 = 24
전체 recorded_amount 기대 = 3210000
```

```text
실제 신청 행 수:
실제 recorded_amount 합계:
일치 여부:
```

## 5-2. 상태별 기준

| 상태 | 기대 건수 | 실제 건수 | 일치? |
| --- | ---: | ---: | --- |
| 신청 | 4 |  |  |
| 수강중 | 5 |  |  |
| 완료 | 12 |  |  |
| 취소 | 3 |  |  |
| **합계** | **24** |  |  |

### 상태별 그룹 합을 전체 24건과 다시 비교해야 하는 이유

```text

```

## 5-3. 월별 기준

| 월 | 기대 신청 건수 | 실제 신청 건수 | 기대 기록 금액 | 실제 기록 금액 | 일치? |
| --- | ---: | ---: | ---: | ---: | --- |
| 2026-01 | 3 |  | 350000 |  |  |
| 2026-02 | 4 |  | 520000 |  |  |
| 2026-03 | 5 |  | 680000 |  |  |
| 2026-04 | 4 |  | 550000 |  |  |
| 2026-05 | 4 |  | 540000 |  |  |
| 2026-06 | 4 |  | 570000 |  |  |
| **합계** | **24** |  | **3210000** |  |  |

## 5-4. 완료 기간 기준

```text
완료 건수 기대 = 12
평균 완료 기간 기대 = 25일
최소 완료 기간 기대 = 18일
최대 완료 기간 기대 = 36일
```

```text
실제 완료 건수:
실제 평균 완료 기간:
실제 최소 완료 기간:
실제 최대 완료 기간:
```

### 완료 12건의 평균 25일을 전체 수강생의 평균 완료 기간이라고 일반화하면 안 되는 이유

```text

```

### 증거 화면

권장 경로:

```text
assignments/chapter14/images/step05_sql_metrics.png
```

`여기에 SQL 기준 결과가 보이는 핵심 화면을 삽입하세요.`

---

# 6. date spine과 데이터 없는 월

월별 분석에서 `generate_series` 기반 date spine을 사용하는 이유를 설명합니다.

```text
실제 데이터만 GROUP BY했을 때:

date spine을 먼저 만들고 LEFT JOIN했을 때:
```

### 데이터가 0건인 월을 결과에 남겨야 하는 이유

```text

```

### 중간 월이 빠진 상태에서 `LAG`를 쓰면 어떤 해석 오류가 생길 수 있나요?

```text

```

---

# 7. 분석 VIEW 검증

다음을 실행합니다.

```text
code/chapter14/06_analysis_dataset.sql
code/chapter14/07_analysis_validation.sql
```

대상 VIEW:

```text
analysis_lab.enrollment_analysis_dataset
```

한 행의 의미:

```text
수강신청 1건 = enrollment_id 1개
```

기준:

```text
정확한 컬럼 수 = 17
VIEW 행 수 = 24
고유 enrollment_id = 24
중복 enrollment_id = 0
recorded_amount 합계 = 3210000
완료 행 = 12
분석 기간 밖 행 = 0
```

실제 결과:

```text
컬럼 수:
VIEW 행 수:
고유 enrollment_id:
중복 enrollment_id:
recorded_amount 합계:
완료 행:
분석 기간 밖 행:
```

### VIEW의 행 단위가 깨진 상태로 Python 분석을 진행하면 어떤 문제가 생기나요?

```text

```

---

# 8. SQL 최종 완료 게이트

다음을 실행합니다.

```text
code/chapter14/08_analysis_lab_validation.sql
```

기대 메시지:

```text
Chapter 14 analysis_lab validation passed: rows 8/3/5/24/24, amount 3210000
```

실제 메시지:

```text

```

### 이 게이트가 실패했을 때 기대값을 현재 데이터에 맞게 수정하면 안 되는 이유

```text

```

---

# 9. Python 환경 준비

기존 가상환경이 없다면 생성합니다.

```bash
python -m venv .venv
```

Windows PowerShell:

```powershell
.\.venv\Scripts\Activate.ps1
python -m pip install -r code/chapter14/python/requirements.txt
```

설치 확인:

```bash
python -c "import pandas, sqlalchemy, psycopg, matplotlib; print('OK')"
```

```text
설치 확인 결과:
```

### 실제 DB 비밀번호나 전체 연결 URL을 Python 파일 또는 GitHub에 직접 저장하면 안 되는 이유

```text

```

---

# 10. 데이터 읽기 방식 선택

아래 둘 중 하나를 선택합니다.

```text
A. 읽기 전용 PostgreSQL 직접 연결
B. CSV + manifest + SQL reference metrics
```

내 선택:

```text
선택 방식:
선택 이유:
```

## A를 선택한 경우

권장 명령:

```bash
python code/chapter14/python/02_load_postgresql.py --export-csv code/chapter14/data/enrollment_analysis_dataset.csv
python code/chapter14/python/03_pandas_analysis.py --source postgresql
python code/chapter14/python/04_result_validation.py --source postgresql
```

확인 사항:

```text
현재 DB:
transaction_read_only:
읽은 VIEW:
행 수:
```

### 같은 `REPEATABLE READ` 읽기 전용 스냅샷에서 SQL과 pandas를 비교하는 장점

```text

```

## B를 선택한 경우

권장 명령:

```bash
python code/chapter14/python/01_load_csv.py --require-manifest
python code/chapter14/python/03_pandas_analysis.py
python code/chapter14/python/04_result_validation.py --source csv
```

확인 사항:

```text
CSV 파일:
manifest 파일:
원본 DB:
원본 VIEW:
분석 기간:
CSV 행 수:
SHA-256 확인 여부:
```

### CSV만 있고 출처·기간·해시 정보가 없다면 재현성이 약해지는 이유

```text

```

---

# 11. DataFrame 구조와 엄격한 자료형 검증

DataFrame을 읽은 뒤 기록합니다.

```text
shape:
컬럼 수:
날짜 컬럼 dtype:
recorded_amount dtype:
completion_days dtype:
is_completed dtype:
```

공통 검증 기준:

```text
정확한 17개 컬럼
24행
enrollment_id 고유
날짜 strict 변환
recorded_amount strict 숫자 변환
completion_days strict 숫자 변환
is_completed boolean
status와 is_completed 일치
완료 상태와 완료일·완료 기간 일치
분석 기간 [2026-01-01, 2026-07-01)
```

### `errors='coerce'`, 무조건적인 `dropna()`, `drop_duplicates()`가 위험할 수 있는 이유

```text

```

### 오류 행을 조용히 삭제하지 않고 원인을 먼저 확인해야 하는 이유

```text

```

---

# 12. pandas 분석 결과

다음을 실행합니다.

```text
code/chapter14/python/03_pandas_analysis.py
```

PostgreSQL 직접 경로라면 `--source postgresql`을 사용합니다.

## 12-1. pandas 상태별 건수

| 상태 | SQL 기준 | pandas | 일치? |
| --- | ---: | ---: | --- |
| 신청 | 4 |  |  |
| 수강중 | 5 |  |  |
| 완료 | 12 |  |  |
| 취소 | 3 |  |  |

## 12-2. pandas 월별 건수·금액

| 월 | SQL 건수 | pandas 건수 | SQL 금액 | pandas 금액 | 일치? |
| --- | ---: | ---: | ---: | ---: | --- |
| 2026-01 | 3 |  | 350000 |  |  |
| 2026-02 | 4 |  | 520000 |  |  |
| 2026-03 | 5 |  | 680000 |  |  |
| 2026-04 | 4 |  | 550000 |  |  |
| 2026-05 | 4 |  | 540000 |  |  |
| 2026-06 | 4 |  | 570000 |  |  |

## 12-3. pandas 완료 기간

```text
완료 건수:
평균 완료 기간:
최소 완료 기간:
최대 완료 기간:
```

## 12-4. 피벗 또는 범주 분석

```text
선택한 피벗/범주:
행 기준:
열 기준:
값:
전체 합계가 원본과 일치하는가:
```

---

# 13. SQL ↔ pandas 최종 교차 검증

다음을 실행합니다.

```text
code/chapter14/python/04_result_validation.py
```

## 핵심 비교표

| 지표 | SQL | pandas | 일치? |
| --- | ---: | ---: | --- |
| 전체 행 수 | 24 |  |  |
| 고유 enrollment_id | 24 |  |  |
| `recorded_amount` 합계 | 3210000 |  |  |
| 신청 | 4 |  |  |
| 수강중 | 5 |  |  |
| 완료 | 12 |  |  |
| 취소 | 3 |  |  |
| 완료 건수 | 12 |  |  |
| 평균 완료 기간 | 25 |  |  |
| 최소 완료 기간 | 18 |  |  |
| 최대 완료 기간 | 36 |  |  |

### 최종 Python 검증 결과

```text

```

### SQL과 pandas 결과가 다를 때 확인할 순서를 자신의 말로 작성

```text
1.
2.
3.
4.
5.
6.
```

### 증거 화면

권장 경로:

```text
assignments/chapter14/images/step13_cross_validation.png
```

`여기에 SQL↔pandas 검증 성공 또는 핵심 비교 화면을 삽입하세요.`

---

# 14. 시각화 검증

생성한 그래프 하나를 선택합니다.

```text
그래프 제목:
X축 의미:
Y축 의미:
사용한 데이터:
```

검토:

```text
월 순서가 올바른가:
Y축이 0부터 시작하는가:
표와 그래프의 값이 같은가:
누락된 월이 없는가:
단위를 오해할 표현이 없는가:
```

### 그래프가 SQL↔pandas 숫자 검증을 대신할 수 없는 이유

```text

```

### 증거 화면

권장 경로:

```text
assignments/chapter14/images/step14_chart.png
```

`여기에 최종 그래프를 삽입하세요.`

---

# 15. 통제된 불일치 원인 분석

원본 DB를 변경하지 않고, pandas 분석 코드의 **복사본 또는 임시 코드**에서 분석 범위를 하나만 의도적으로 다르게 만들어 봅니다.

예:

```text
취소 상태를 임시로 제외한다.
분석 시작 월을 한 달 늦춘다.
월별 date spine을 제거한다.
```

> 실습이 끝나면 원래 기준으로 되돌립니다. 제공된 기준 파일을 수정해 억지로 통과시키지 않습니다.

```text
변경한 한 가지 조건:
SQL 기준 결과:
변경된 pandas 결과:
발생한 차이:
차이가 생긴 원인:
원래 기준으로 복구했는가:
```

### 이 실습에서 배운 가장 중요한 검산 원칙

```text

```

---

# 16. 개인 프로젝트 분석 질문 2개

Chapter 07부터 발전시킨 개인 프로젝트를 사용합니다.

| 질문 ID | 분석 질문 | 기간 | 한 행 | 지표 | SQL 기준 | pandas 검산 | 시각화 필요? |
| --- | --- | --- | --- | --- | --- | --- | --- |
| P14-P01 |  |  |  |  |  |  |  |
| P14-P02 |  |  |  |  |  |  |  |

최소 한 질문은 SQL과 pandas 양쪽에서 같은 결과를 만드는 검증 계획을 작성합니다.

## P14-P01 상세

```text
Source of Truth:
분석 VIEW 또는 추출 SQL:
예상 행 단위:
SQL 검산값:
pandas 검산값:
불일치 시 확인 순서:
```

개인 프로젝트 DB가 아직 실행 가능한 상태가 아니라면 다음을 명시합니다.

```text
현재 상태: 설계만 완료 / 미실행
실행 가능해졌을 때 검증할 기준:
```

---

# 17. AI를 분석 리뷰어로 활용

## 17-1. 사용한 프롬프트

```text

```

권장 방향:

```text
그래프 모양을 먼저 평가하지 말고
1. 분석 질문
2. 기간
3. 한 행 단위
4. 지표 의미
5. JOIN 중복
6. NULL·취소 처리
7. SQL 기준값
8. pandas 결과
9. 자료형 변환
10. 출처·스냅샷
을 먼저 검토해 주세요.
불일치가 있으면 기대값을 수정하지 말고 원인 후보와 검증 순서를 제시해 주세요.
```

## 17-2. AI 제안 검토

| AI 제안 | 수용 / 수정 / 보류 / 거절 | 실제 확인 | 최종 이유 |
| --- | --- | --- | --- |
|  |  |  |  |
|  |  |  |  |
|  |  |  |  |

### AI가 `dropna()`, `drop_duplicates()`, `errors='coerce'`를 제안했다면 어떻게 판단했나요?

```text

```

### AI가 만든 그래프가 보기 좋더라도 숫자 기준 검증을 먼저 해야 하는 이유

```text

```

---

# 18. 최종 해석

## 18-1. 관찰한 사실

```text

```

## 18-2. 나의 해석

```text

```

## 18-3. 이 분석의 한계

```text

```

### 관찰·해석·한계를 분리해서 기록해야 하는 이유

```text

```

---

# 19. 제출 전 체크리스트

- [ ] `ai_database_book`에서 실습했다.
- [ ] 분석 질문·기간·한 행 의미를 SQL보다 먼저 작성했다.
- [ ] 분석 기간을 `[2026-01-01, 2026-07-01)`로 확인했다.
- [ ] `recorded_amount`를 신청 시점 기록 금액으로 해석했다.
- [ ] `students/instructors/courses/enrollments = 8/3/5/24`를 확인했다.
- [ ] 데이터 품질 이상이 0건임을 확인했다.
- [ ] SQL 상태별·월별 기준을 기록했다.
- [ ] 분석 VIEW가 24행이며 enrollment_id가 고유함을 확인했다.
- [ ] SQL 최종 게이트를 통과했다.
- [ ] Python DataFrame의 17개 컬럼·24행·자료형을 확인했다.
- [ ] SQL과 pandas 결과를 직접 교차 검증했다.
- [ ] 그래프를 숫자 검증의 대체물로 사용하지 않았다.
- [ ] 비밀번호·전체 접속 URL·password file을 저장소에 올리지 않았다.
- [ ] CSV를 사용했다면 출처 manifest와 해시를 확인했다.
- [ ] 개인 프로젝트 분석 질문 2개를 작성했다.
- [ ] AI 제안을 실제 결과로 검토했다.
- [ ] 핵심 이미지 2~4장만 제출했다.
- [ ] GitHub 웹에서 Markdown과 이미지가 정상적으로 보이는지 확인했다.

---

# 20. 최종 회고

## Q1. SQL과 pandas를 함께 사용했을 때 각각 가장 적합했던 역할은 무엇이었나요?

```text

```

## Q2. SQL과 pandas 결과가 다르다면 가장 먼저 무엇을 확인해야 하나요?

```text

```

## Q3. 데이터 품질 검사가 분석보다 먼저 필요한 이유는 무엇인가요?

```text

```

## Q4. 시각화가 검증 증거를 대신할 수 없는 이유는 무엇인가요?

```text

```

## Q5. 이번 장에서 AI를 가장 유용하게 사용한 지점과, AI 제안을 거절하거나 수정한 지점은 무엇인가요?

```text

```

---

# 21. LMS 제출 URL

LMS에는 아래 형식의 **본인 GitHub 파일 URL**을 제출합니다.

```text
https://github.com/<본인-GitHub-ID>/<본인-저장소>/blob/main/assignments/chapter14/chapter14_answer.md
```

실제 제출 URL:

```text

```

> 교수자 템플릿 URL, 저장소 루트 URL, 이미지 URL을 제출하지 않습니다. 반드시 본인이 작성한 `chapter14_answer.md`의 정확한 URL을 제출합니다.
