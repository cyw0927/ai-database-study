# Chapter 14 실습 코드

## SQL 데이터 분석과 Python 확장

이 폴더는 `analysis_lab`에서 분석 질문의 기간과 행 단위를 SQL로 확정하고, 분석 VIEW를 CSV 또는 읽기 전용 PostgreSQL 연결로 pandas에 전달한 뒤 **실제 SQL 집계와 Python 집계**를 교차 검증하는 파일을 관리합니다.

---

## 핵심 범위

```text
course_project: 변경하지 않음
transaction_lab: 변경하지 않음
performance_lab: 변경하지 않음
security_lab: 변경하지 않음
nosql_lab: 변경하지 않음
ai_review_lab: 변경하지 않음
analysis_lab: Chapter 14 실습 대상
```

모든 SQL은 다음 위치를 확인합니다.

```sql
SELECT current_database();
SELECT current_schema();
SHOW search_path;
```

생성·Seed·초기화 파일은 `ai_database_book`인지 실제로 검사합니다.

---

## 분석 기준

```text
P14-Q01 상태별 수강신청 건수
P14-Q02 월별 신청 수와 신청 시점 기록 금액
P14-Q03 강의별 신청 건수
P14-Q04 지역별 학생·신청 건수
P14-Q05 완료된 신청의 완료 기간
```

분석 기간은 한 곳에서 관리합니다.

```text
analysis_lab.analysis_parameters
start_date = 2026-01-01
end_date_exclusive = 2026-07-01
기간 표현 = [2026-01-01, 2026-07-01)
```

`recorded_amount`는 물리 컬럼 이름이지만 의미는 **신청 시점 기록 금액**입니다. 결제 성공·환불·회계 매출을 의미하지 않습니다. 분석 VIEW에서는 `recorded_amount`로 제공합니다.

---

## 파일 목록

| 파일 | 설명 |
| --- | --- |
| `01_analysis_lab_schema.sql` | DB·기존 스키마를 검사하고 네 테이블·분석 기간 VIEW·활성 신청 인덱스를 한 트랜잭션에서 생성 |
| `02_analysis_lab_seed.sql` | 빈 상태 검사 후 8·3·5·24행 입력, IDENTITY 조정과 COMMIT 전 자동 판정 |
| `03_data_quality_checks.sql` | 중복·고아 FK·상태·금액·가입일·개설일·기간·활성 신청 점검 |
| `04_summary_analysis.sql` | 고정 기간의 상태·강의·강사·지역 집계 |
| `05_period_category_analysis.sql` | date spine 월별 분석, LAG, 범주별 현재 완료 상태 비중과 완료 기간 |
| `06_analysis_dataset.sql` | 수강신청 1건 단위, 기간 제한 분석 VIEW 생성 |
| `07_analysis_validation.sql` | 상태·월·금액·기간·품질 상세 증거 조회 |
| `08_analysis_lab_validation.sql` | 구조·기간·행 수·품질·기준값·IDENTITY 최종 예외 기반 게이트 |
| `reset_analysis_lab.sql` | 올바른 DB에서 VIEW와 자식 테이블부터 `analysis_lab`만 초기화 |
| `python/validation_utils.py` | 공통 컬럼·자료형·기간·연결·manifest 검증 |
| `python/01_load_csv.py` | CSV 구조 검증과 선택적 manifest 확인 |
| `python/02_load_postgresql.py` | 읽기 전용 DB 연결, CSV와 SHA-256 manifest 생성 |
| `python/03_pandas_analysis.py` | 상태·월·강의·피벗·완료 기간과 헤드리스 그래프 생성 |
| `python/04_result_validation.py` | 실제 SQL 결과와 pandas 결과 직접 비교 |
| `python/reference_metrics.json` | CSV 경로에서 사용하는 버전 관리 SQL 기준값 |
| `python/analysis_manifest.example.json` | CSV 출처·기간·시점·해시 manifest 형식 |
| `python/.env.example` | libpq 방식 연결 변수 이름 |
| `python/requirements.txt` | Python 패키지 범위 |

---

## SQL 실행 순서

```text
01_analysis_lab_schema.sql
→ 02_analysis_lab_seed.sql
→ 03_data_quality_checks.sql
→ 04_summary_analysis.sql
→ 05_period_category_analysis.sql
→ 06_analysis_dataset.sql
→ 07_analysis_validation.sql
→ 08_analysis_lab_validation.sql
```

최종 통과 메시지:

```text
Chapter 14 analysis_lab validation passed: rows 8/3/5/24/24, amount 3210000
```

실패하면 기대값을 바꾸지 않고 DB·기간·Seed·JOIN·품질 검사를 확인합니다.

---

> `analysis_lab`은 분석 학습용 합성 데이터입니다. `course_project`를 복제·확장한 운영 데이터가 아니며, `recorded_amount NUMERIC(12,0)`는 앞 장과 동일하게 신청 시점 기록 금액입니다. 취소 후에도 이 역사값을 0으로 덮어쓰지 않습니다.

## 기준 데이터

| 항목 | 기대값 |
| --- | ---: |
| students | 8 |
| instructors | 3 |
| courses | 5 |
| enrollments | 24 |
| enrollment_analysis_dataset | 24 |
| 데이터셋 enrollment_id 중복 | 0 |
| 신청 시점 기록 금액 합계 | 3,210,000 |

상태별 기준:

| status | 건수 |
| --- | ---: |
| 신청 | 4 |
| 수강중 | 5 |
| 완료 | 12 |
| 취소 | 3 |

월별 기준:

| 월 | 신청 건수 | 기록 금액 |
| --- | ---: | ---: |
| 2026-01 | 3 | 350000 |
| 2026-02 | 4 | 520000 |
| 2026-03 | 5 | 680000 |
| 2026-04 | 4 | 550000 |
| 2026-05 | 4 | 540000 |
| 2026-06 | 4 | 570000 |

완료된 신청 기준:

```text
완료 건수 12
평균 완료 기간 25일
최소 18일
최대 36일
```

이 통계는 완료된 행만 대상으로 하므로 전체 수강생의 평균 소요 기간으로 일반화하지 않습니다.

---

## 스키마와 업무 규칙

```text
students 1 → N enrollments
instructors 1 → N courses
courses 1 → N enrollments
```

Chapter 07의 활성 신청 규칙을 유지합니다.

```sql
CREATE UNIQUE INDEX uq_analysis_enrollments_active
ON analysis_lab.enrollments (student_id, course_id)
WHERE status IN ('신청', '수강중');
```

같은 날짜의 동일 원천 행 중복은 별도 `UNIQUE(student_id, course_id, enrolled_at)`로 차단합니다. 두 제약은 목적이 다릅니다.

---

## 분석 데이터셋

VIEW:

```text
analysis_lab.enrollment_analysis_dataset
```

행 단위:

```text
수강신청 1건 = enrollment_id 1개
```

정확한 컬럼:

```text
enrollment_id
student_id
student_name
region
course_id
course_title
category
level
instructor_id
instructor_name
enrolled_at
enrollment_month
status
recorded_amount
completed_at
completion_days
is_completed
```

VIEW는 분석 기간을 실제로 적용하므로 기간 밖 행이 추가되어도 Chapter 14의 분석 범위는 변하지 않습니다.

---

## 데이터 품질 기준

```text
PK·분석 VIEW 중복 0
고아 학생·강의·강사 0
완료 상태와 completed_at 조합 이상 0
완료일 < 신청일 0
신청일 < 학생 가입일 0
신청일 < 강의 개설일 0
음수 기록 금액 0
취소 후 기록 금액이 0으로 덮어써진 행 0
분석 기간 밖 기준 데이터 0
활성 신청 중복 0
```

---

## date spine과 지표 명칭

월별 분석은 `generate_series`로 1~6월 기준표를 먼저 만듭니다. 데이터가 없는 월도 0건으로 유지되므로 `LAG`의 이전 달 의미와 그래프 간격이 보존됩니다.

```text
completed_share_pct
→ 전체 신청 중 현재 완료 상태의 비중

completion_rate
→ 관찰 기간·코호트·취소 포함 여부를 정의한 별도 지표
```

이 장에서는 첫 번째만 계산합니다.

---

## Python 환경

```bash
python -m venv .venv
```

Windows PowerShell:

```powershell
.\.venv\Scripts\Activate.ps1
pip install -r code/chapter14/python/requirements.txt
```

macOS·Linux:

```bash
source .venv/bin/activate
pip install -r code/chapter14/python/requirements.txt
```

설치 확인:

```bash
python -c "import pandas, sqlalchemy, psycopg, matplotlib; print('OK')"
```

---

## PostgreSQL 연결

`python/.env.example`을 복사해 `python/.env`를 만들고 실제 값은 저장소에 커밋하지 않습니다.

```text
PGHOST=localhost
PGPORT=5432
PGDATABASE=ai_database_book
PGUSER=
PGPASSFILE=
```

실제 password file은 저장소 밖의 보호된 경로에 둡니다. Python은 다음을 확인합니다.

```text
현재 DB = ai_database_book
분석 VIEW 존재
transaction_read_only = on
분석 계정은 실제 환경에서 CONNECT·USAGE·SELECT 중심 최소권한
정확한 컬럼과 24행
```

---

## 권장 Python 실행 경로

### PostgreSQL 직접 경로

같은 읽기 전용 DB에서 CSV와 manifest 생성:

```bash
python code/chapter14/python/02_load_postgresql.py \
  --export-csv code/chapter14/data/enrollment_analysis_dataset.csv
```

pandas 분석:

```bash
python code/chapter14/python/03_pandas_analysis.py --source postgresql
```

실제 SQL과 pandas를 같은 `REPEATABLE READ`, 읽기 전용 스냅샷에서 직접 비교:

```bash
python code/chapter14/python/04_result_validation.py --source postgresql
```

### CSV 경로

기본 구조 확인:

```bash
python code/chapter14/python/01_load_csv.py
```

manifest까지 엄격히 확인:

```bash
python code/chapter14/python/01_load_csv.py --require-manifest
```

pandas 분석과 기준값 비교:

```bash
python code/chapter14/python/03_pandas_analysis.py
python code/chapter14/python/04_result_validation.py --source csv
```

CSV 최종 검증은 다음 세 증거를 함께 사용합니다.

```text
CSV 데이터셋
CSV manifest: DB·VIEW·기간·생성 시점·행 수·기대 기록 금액·금액 의미·SHA-256
reference_metrics.json: SQL 기준값
```

DBeaver에서 직접 CSV를 내보냈다면 `analysis_manifest.example.json`을 참고해 manifest를 작성하고 SHA-256을 계산해야 최종 검증 경로를 사용할 수 있습니다.

---

## Python 공통 검증

`validation_utils.py`가 모든 로더에 같은 기준을 적용합니다.

```text
정확한 17개 컬럼
24행과 enrollment_id 고유성
날짜 컬럼 strict 변환
recorded_amount strict 숫자 변환
completion_days strict 숫자 변환
is_completed boolean
status와 is_completed 일치
완료 상태와 완료일·완료 기간 일치
분석 기간 [2026-01-01, 2026-07-01)
```

잘못된 문자열을 NULL로 숨기지 않도록 숫자 변환은 `errors="raise"`를 사용합니다.

---

## 시각화

Python 시각화는 GUI가 없는 환경에서도 실행되도록 `Agg` 백엔드를 사용합니다. 설치된 한글 글꼴을 탐색하고 찾지 못하면 경고를 출력합니다. Y축은 0부터 시작합니다.

```text
그래프는 검증 결과를 대신하지 않는다.
SQL·pandas 표와 합계를 먼저 확인한 뒤 해석을 돕는 용도로 사용한다.
```

생성된 그래프는 `code/chapter14/output/`에 저장되며 Git에서 제외됩니다.

---

## 안전 원칙

```text
- 생성·Seed·reset 파일은 현재 DB를 실제 검사한다.
- 분석 기간은 SQL·VIEW·Python에서 같은 반개방 구간을 사용한다.
- 원본 테이블 변경 SQL을 Python에서 실행하지 않는다.
- PostgreSQL 연결은 읽기 전용으로 설정하고 실제 환경에서는 최소권한 분석 계정과 함께 사용한다.
- Python 월 date spine은 공통 분석 기간 상수에서 생성한다.
- 비밀번호·전체 접속 URL·password file을 코드에 기록하지 않는다.
- CSV와 그래프는 저장소에서 제외한다.
- Python에서 dropna·drop_duplicates·errors='coerce'로 오류를 숨기지 않는다.
- PostgreSQL 경로는 실제 SQL과 pandas를 같은 스냅샷에서 비교한다.
- CSV 경로는 출처 manifest와 별도 SQL 기준값을 사용한다.
- 불일치 시 기대값을 실제값으로 바꾸지 않는다.
```
