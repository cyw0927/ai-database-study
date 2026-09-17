# Chapter 10 실습 코드

## 실행 계획으로 인덱스 효과 검증하기

> **검증 기준 버전**
>
> 이 장의 자동 검증 기준은 **PostgreSQL 16**입니다. PostgreSQL 16의 다중 컬럼 B-tree에서는 선두 컬럼 제약이 없으면 후행 컬럼 조건만으로 탐색 범위를 줄이기 어렵습니다. **B-tree Skip Scan은 PostgreSQL 18에서 추가**되었으므로, PostgreSQL 18 이상에서는 동일 SQL의 계획이 달라질 수 있습니다. 실습 결과에는 서버 버전을 함께 기록합니다.

**Chapter 07·08 시작 기준**

`course_project`의 `students / instructors / courses / enrollments = 3 / 2 / 3 / 5`, 상태는 `신청 2 / 수강중 1 / 완료 1 / 취소 1`이어야 합니다.  
`course_project.enrollments.recorded_amount`는 `NUMERIC(12,0)`이며, 전체 기록 금액은 `590000`, 활성 신청은 `3건 / 340000`, 취소 제외 이력은 `4건 / 440000`입니다.  
기준 신청은 `1001 = 완료 / 100000`, `1004 = 취소 / 150000`, `1005 = 신청 / 120000`이고 `uq_course_enrollments_active`가 존재해야 합니다. 또한 Chapter 07의 **명명 제약조건 15개와 `NOT NULL` 열 20개**가 유지되어야 합니다. Chapter 10은 이 상태를 읽기만 하고 변경하지 않습니다.

이 폴더는 기존 프로젝트를 변경하지 않고 `performance_lab`에서 대량 데이터를 생성해 같은 SQL의 인덱스 전후 실행 계획을 비교하는 SQL 파일을 관리합니다.

---

## 실행 전 조건

Chapter 07의 `course_project.enrollments`가 기준 5행 상태여야 합니다. 명명 제약조건 15개와 `NOT NULL` 열 20개도 유지되어야 하며, `01_performance_lab_schema.sql`을 실행하는 역할에는 `ai_database_book`의 `CREATE` 권한이 필요합니다. Chapter 10은 `course_project`를 읽기만 하며 변경하지 않습니다.

```text
course_project: 변경하지 않음
transaction_lab: 변경하지 않음
performance_lab: Chapter 10 전용 실험 공간
```

모든 파일은 다음 위치 확인 형식을 사용합니다.

```sql
SELECT current_database();
SELECT current_schema();
SHOW search_path;
```

모든 실습 객체는 스키마 한정 이름으로 사용하므로 `current_schema()`가 `performance_lab`일 필요는 없습니다.

---

## 자동 검증 기준 상태

```text
01 완료: performance_lab 4개 테이블 / 0행 / 자동 인덱스 6개
02 완료: 10003 / 2 / 2003 / 100005, 후보 인덱스 0개
03: 후보 인덱스 없는 기준 실행 계획 8개 기록
04 완료: 자동 6 + 후보 3 = 전체 인덱스 9개
05: 03과 동일한 8개 SQL 재측정
06: 인덱스 정의·valid/ready·크기·사용 통계 검토
07: 결과 행·분포·금액·인덱스·Chapter 07·08 보존 자동 판정
```

`03_baseline_explain.sql`은 읽기 전용이므로 데이터베이스 상태만으로 사용자가 기준 계획을 실제 기록했는지 판정할 수 없습니다. 따라서 **학습자는 03 결과를 기록하고**, 저장소 자동 검증은 실제 실행 순서를 `03 → 04`로 고정합니다.

실행 시간은 캐시, JIT, 장비 부하의 영향을 받습니다. 한 번의 시간 숫자만으로 결론을 내리지 않고 **결과 행 동일성, 계획 노드, Index Cond, Buffers와 반복 측정**을 함께 봅니다. `enable_seqscan`, `enable_indexscan`, `enable_bitmapscan`은 모두 `on`으로 유지하며, 특정 계획을 강제한 결과를 최종 성능 증거로 사용하지 않습니다.

## 파일 목록

| 파일 | 설명 |
| --- | --- |
| `01_performance_lab_schema.sql` | 사전 조건을 검사하고 전용 스키마와 네 테이블을 하나의 트랜잭션에서 생성 |
| `02_performance_lab_seed.sql` | 일관된 대량 데이터 생성, IDENTITY 시작값 조정과 최초 `ANALYZE` |
| `03_baseline_explain.sql` | 세 실험 후보 인덱스가 없는 상태의 기준 실행 계획 |
| `04_create_candidate_indexes.sql` | 세 실험 후보 인덱스 생성, 통계는 다시 수집하지 않음 |
| `05_after_index_explain.sql` | 세 인덱스가 존재하는 상태에서 같은 SQL 재측정 |
| `06_index_review.sql` | 자동·수동 인덱스, 크기와 사용 통계 검토 |
| `07_result_validation.sql` | 결과 행 수, 데이터 상태, 프로젝트 보호와 인덱스 존재 자동 검증 |
| `reset_performance_lab.sql` | DB 보호 구문 안에서 `performance_lab`만 초기화 |
| `index_performance_practice.sql` | 기존 링크 호환용 안내·상태 확인 |

---

## 실행 순서

```text
01_performance_lab_schema.sql
→ 02_performance_lab_seed.sql
→ 03_baseline_explain.sql
→ 04_create_candidate_indexes.sql
→ 05_after_index_explain.sql
→ 06_index_review.sql
→ 07_result_validation.sql
```

`03`의 결과를 기록한 뒤 `04`, `05`를 실행해야 합니다.

```text
03 실행 전: 실험 후보 인덱스 0개
04 실행 전: 실험 후보 인덱스 0개
05·06·07 실행 전: 실험 후보 인덱스 3개
```

각 파일은 상태가 맞지 않으면 예외를 발생시켜 잘못된 전후 비교를 차단합니다.

---

## 기준 데이터

| 테이블 | 기대 행 수 |
| --- | ---: |
| `performance_lab.students` | 10003 |
| `performance_lab.instructors` | 2 |
| `performance_lab.courses` | 2003 |
| `performance_lab.enrollments` | 100005 |

대량 데이터의 주요 특징:

```text
성능 학생 ID: 1001~11000
성능 학생 이메일: performance{실제 ID}@example.com
성능 강의 ID: 1001~3000
학생별 신청: 10건
강의별 신청: 50건
동일 학생·강의 활성 신청 중복: 0건
```

주요 결과 행 수:

```text
performance5000@example.com → 1행, 학생 ID 5000
student_id = 5000           → 10행
course_id = 1500            → 50행
course_id=1500 + 수강중     → 15행
전체 수강중                 → 30001행
```

`enrollments` 100,005행 기준 대략적인 반환 비율:

```text
student_id = 5000                 ≈ 0.010%
course_id = 1500                  ≈ 0.050%
course_id = 1500 + 수강중         ≈ 0.015%
status = 수강중                   ≈ 30.0%
```

이 비율은 후보 판단의 단서이며 인덱스 사용을 보장하지 않습니다. 실제 실행 계획과 Buffers를 함께 확인합니다.

PC 성능이 낮아 생성 건수를 임의로 줄이면 이 기대값과 자동 검증을 함께 수정해야 합니다. 행 수가 너무 적으면 PostgreSQL이 합리적으로 `Seq Scan`을 선택해 차이가 작게 보일 수 있습니다.

---

## IDENTITY 시작값

명시적 ID 입력은 IDENTITY의 다음 값을 자동으로 변경하지 않습니다. `02` 파일은 다음 값으로 조정합니다.

```text
students.id      → 11001
instructors.id   → 203
courses.id       → 3001
enrollments.id   → 110001
```

---

## 전후 측정을 위한 실험 후보

```text
idx_performance_courses_title
idx_performance_enrollments_student_id
idx_performance_enrollments_course_status
```

이 세 인덱스는 측정을 위한 후보입니다. 실제 운영 적용 여부는 워크로드, 계획, Buffers, 시간, 저장 공간과 쓰기 비용을 비교한 뒤 결정합니다.

자동 인덱스:

```text
PRIMARY KEY
UNIQUE email
```

PostgreSQL은 외래키 자식 컬럼에 인덱스를 자동 생성하지 않습니다. FK 자식 인덱스는 무결성 정확성을 위한 필수 구조는 아니지만 JOIN과 부모 삭제·키 변경 시 자식 검색에 도움이 될 수 있습니다.

---

## 비교할 SQL

```text
학생 이메일 정확 일치
강의 제목 정확 일치
학생별 신청 JOIN
course_id 단독 조건
course_id + status 조건
status 단독 조건
ORDER BY title
ORDER BY title LIMIT 20
```

같은 SQL, 같은 데이터, 같은 테이블 통계를 인덱스 전후에 사용합니다. `02`에서 `ANALYZE`한 뒤 `04`에서는 다시 실행하지 않아 새로운 통계 표본의 영향을 섞지 않습니다.

---

## 실행 계획 기록 항목

```text
주요 계획 노드
cost
rows / actual rows
actual time
loops
Buffers hit/read
Filter
Index Cond
Sort
Planning Time
Execution Time
```

`cost`는 실행 시간이 아닙니다. 계획과 시간은 PostgreSQL 버전, 장비, 캐시와 설정에 따라 달라질 수 있습니다.

`EXPLAIN ANALYZE`는 일반 결과 행 대신 실행 계획을 출력하므로, 결과 동일성은 `07_result_validation.sql`의 별도 `COUNT`와 자동 판정으로 확인합니다.

---

## 복합 인덱스와 PostgreSQL 18+ Skip Scan

`(course_id, status)`에서는 선두 컬럼인 `course_id` 조건이 있을 때 일반적으로 활용하기 쉽습니다.

```text
course_id 단독
course_id + status
→ 활용 가능성 높음

status 단독
→ 일반적으로 제한적
→ 데이터 분포와 비용에 따라 PostgreSQL 18+에서의 Skip Scan 가능성 존재
```

실제 사용 여부는 `Index Cond`와 계획 노드로 확인합니다.

---

## 운영 환경의 인덱스 생성

이 실습은 격리된 스키마이므로 일반 `CREATE INDEX`를 사용합니다.

운영 테이블에서는 다음을 먼저 검토합니다.

```text
쓰기 잠금 영향
인덱스 생성 시간과 디스크 공간
CREATE INDEX CONCURRENTLY 필요 여부
실패 후 INVALID 인덱스 존재 여부
```

`CREATE INDEX CONCURRENTLY`는 트랜잭션 블록 안에서 실행할 수 없으며 일반 생성보다 오래 걸릴 수 있습니다.

---

## idx_scan 해석

```text
- idx_scan = 0만으로 삭제하지 않습니다.
- 통계 초기화 시점과 관찰 기간을 확인합니다.
- PK·UNIQUE 인덱스는 제약조건 유지에 직접 사용됩니다.
- FK 자식 인덱스는 성능 목적이며 업무 패턴을 확인합니다.
- idx_scan을 사용자 SQL 실행 횟수와 항상 같은 값으로 해석하지 않습니다.
```

---

## 안전 원칙

```text
- public, course_project, transaction_lab 객체를 삭제하지 않습니다.
- 생성 파일에서 자동 DROP을 실행하지 않습니다.
- reset 파일은 ai_database_book에서만 삭제를 허용합니다.
- EXPLAIN (ANALYZE, BUFFERS)는 SELECT에만 사용합니다.
- 실행 시간 한 번만 보고 판단하지 않습니다.
- 계획, 행 수, Buffers와 결과 동일성을 함께 확인합니다.
- 기준과 사후 측정 사이에 데이터와 통계를 바꾸지 않습니다.
```

---

## 초기화

처음부터 다시 시작할 때만 다음 파일을 사용합니다.

```text
reset_performance_lab.sql
```

이 파일은 현재 데이터베이스를 검증한 뒤 `performance_lab`의 네 테이블과 스키마만 삭제합니다.
