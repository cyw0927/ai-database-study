# Chapter 12 실습 코드

## 조회 패턴으로 RDBMS와 NoSQL 선택하기

이 폴더는 기존 프로젝트를 변경하지 않고 `nosql_lab`에서 PostgreSQL JSONB, Key-Value 캐시 개념과 저장 방식 선택 기준을 검증하는 파일을 관리합니다.

별도 MongoDB, Redis, Cassandra 계열이나 Graph DB 서버를 설치하지 않습니다. PostgreSQL 안에서 **원본·파생·캐시·문서·의사결정 기록의 경계**를 실습하고, 전용 NoSQL 제품 도입 전 검토 기준을 익힙니다.

---

## 보호 범위

```text
course_project: 변경하지 않음
transaction_lab: 변경하지 않음
performance_lab: 변경하지 않음
security_lab: 변경하지 않음
nosql_lab: Chapter 12 실습 대상
```

모든 SQL은 다음 위치 확인 형식을 사용합니다.

```sql
SELECT current_database();
SELECT current_schema();
SHOW search_path;
```

---

## 파일 목록

| 파일 | 설명 |
| --- | --- |
| `01_nosql_lab_schema.sql` | DB·Chapter 07 상태·15개 명명 제약조건·20개 NOT NULL·DB CREATE 권한을 검사하고 문서·캐시·의사결정 테이블을 한 트랜잭션에서 생성 |
| `02_nosql_lab_seed.sql` | Chapter 07 원본과 맞춘 문서 3건, 캐시 4건, 선택 사례 6건 입력·자동 검증 |
| `03_document_jsonb_queries.sql` | 안정 컬럼·JSONB 조회, 원본 대조, `document_version` 낙관적 잠금과 ROLLBACK |
| `04_key_value_cache_queries.sql` | Seed 기준 TTL과 실제 현재 상태, 정확 키·미스·무만료 키 시뮬레이션 |
| `05_storage_choice_review.sql` | 원본·일관성·동기화·복구·PoC·결정 상태 검토 |
| `06_jsonb_index_candidates.sql` | GIN과 `options.online` 표현식 인덱스 후보 생성·정의 확인 |
| `07_nosql_lab_validation.sql` | 원본 매핑·JSON 구조·TTL·결정 근거·인덱스를 최종 자동 판정 |
| `reset_nosql_lab.sql` | DB 보호 구문 안에서 `nosql_lab`만 초기화 |
| `nosql_jsonb_practice.sql` | 기존 링크 호환용 읽기 전용 안내·상태 확인 |

---

## 실행 순서

```text
01_nosql_lab_schema.sql
→ 02_nosql_lab_seed.sql
→ 03_document_jsonb_queries.sql
→ 04_key_value_cache_queries.sql
→ 05_storage_choice_review.sql
→ 06_jsonb_index_candidates.sql
→ 07_nosql_lab_validation.sql
```

처음부터 다시 실행할 때만 `reset_nosql_lab.sql`을 사용합니다.

---

## 기준 데이터

| 테이블 | 기대 행 수 |
| --- | ---: |
| `nosql_lab.course_documents` | 3 |
| `nosql_lab.key_value_cache_examples` | 4 |
| `nosql_lab.storage_choice_cases` | 6 |

Chapter 07·08 원본 기준:

```text
students 3
instructors 2
courses 3
enrollments 5
상태 = 신청 2 / 수강중 1 / 완료 1 / 취소 1
recorded_amount = NUMERIC(12,0)
전체 기록 금액 = 590000
활성 신청 = 3 / 340000
취소 제외 = 4 / 440000
1001 = 완료 / 100000
1004 = 취소 / 150000
1005 = 신청 / 120000
Chapter 07 명명 제약조건 = 15
Chapter 07 NOT NULL 열 = 20
```

`01_nosql_lab_schema.sql`은 `nosql_lab` DDL 전에 현재 역할이 `ai_database_book`에 `CREATE` 권한을 갖는지도 확인합니다.

`recorded_amount`는 신청 시점에 신청 행에 기록한 금액입니다. 결제 승인액·환불 반영 순액·회계 매출을 뜻하지 않으며 별도 결제·환불 원장은 현재 프로젝트 범위 밖입니다.

강의 문서 매핑:

| source_course_id | course_code | title |
| ---: | --- | --- |
| 301 | COURSE-301 | 데이터베이스 입문 |
| 302 | COURSE-302 | 정규화 실습 |
| 303 | COURSE-303 | 파이썬 데이터 분석 |

물리적 FK는 만들지 않지만 `07_nosql_lab_validation.sql`에서 원본 제목·난이도·강사 스냅샷을 대조합니다.

---

## 혼합 문서 설계

일반 컬럼:

```text
source_course_id
course_code
title
level
document_version
created_at
updated_at
```

JSONB:

```text
tags
options
instructor_snapshot
```

`level`은 모든 문서에서 중요하고 자주 검증·검색하므로 일반 컬럼에 둡니다. `instructor_snapshot`은 상세 화면 표시용 파생 복사본이며 최종 원본은 `course_project.instructors`입니다.

---

## JSONB 검증 책임

| 규칙 | DB 제약조건 | 애플리케이션·검증 SQL |
| --- | --- | --- |
| metadata가 객체 | 적용 | 재확인 |
| course_code·title 공백 금지 | 적용 | 보조 |
| level 허용값 | 일반 컬럼 CHECK | 보조 |
| tags가 배열 | 미적용 | 적용 |
| options가 객체 | 미적용 | 적용 |
| options.online boolean | 미적용 | 적용 |
| instructor_snapshot 원본 대조 | 미적용 | 적용 |
| 문서 버전 충돌 | 조건부 UPDATE | 재시도·충돌 처리 |

`updated_at`은 자동으로 바뀌지 않습니다. 변경 SQL이나 애플리케이션이 값을 갱신해야 합니다.

---

## 낙관적 잠금

```sql
UPDATE nosql_lab.course_documents
SET
    metadata = jsonb_set(...),
    document_version = document_version + 1,
    updated_at = CURRENT_TIMESTAMP
WHERE course_code = 'COURSE-301'
  AND document_version = 1
  AND jsonb_typeof(metadata -> 'options') = 'object';
```

영향 행 수가 0이면 다음을 확인합니다.

```text
다른 사용자가 먼저 문서를 수정했는가?
읽은 document_version이 오래되었는가?
jsonb_set의 중간 경로가 존재하는가?
```

실습은 결과를 확인한 뒤 `ROLLBACK`해 `certificate=true`, `document_version=1` 기준을 유지합니다.

---

## 재현 가능한 캐시 기준

Seed 기준은 현재 시각이 아니라 각 행의 `created_at`과 `expired_at`을 비교합니다.

```text
전체 4
Seed 시점 유효 3
Seed 시점 만료 1
```

```sql
expired_at IS NULL OR expired_at > created_at
```

실제 현재 유효 캐시는 시간이 지나면 달라질 수 있으므로 고정 정답으로 사용하지 않습니다.

```sql
expired_at IS NULL OR expired_at > CURRENT_TIMESTAMP
```

`expired_at IS NULL`은 만료 정책이 없는 키입니다. PostgreSQL 테이블은 자동 TTL 삭제를 구현하지 않습니다. 실제 Key-Value 제품에서도 TTL 기반 expiration과 메모리 압박에 따른 eviction은 구분해서 확인합니다. 예를 들어 Redis에서는 `EXPIRE`로 만료 시간을 지정하는 동작과 메모리 한도에서 eviction policy가 키를 제거하는 동작이 별개입니다.

---

## Key-Value 시뮬레이션 한계

```text
메모리 저장
자동 TTL 삭제
eviction
복제
샤딩
고성능 네트워크 조회
실제 장애 동작
```

`cache_value`는 편의를 위해 JSONB로 저장하지만 JSON 객체만 강제하지 않습니다. 실제 Key-Value 제품은 문자열·숫자·배열·바이너리 등 다양한 값을 지원할 수 있습니다.

---

## 저장 방식 선택 기록

각 사례에는 다음 근거를 함께 저장합니다.

```text
system_role
primary_query
candidate_storage
source_of_truth
consistency_requirement
synchronization_strategy
recovery_strategy
poc_success_criteria
decision_status
reason
```

결정 상태:

```text
candidate
poc_planned
hold
adopted
rejected
```

후보 저장소가 있다고 채택된 것은 아닙니다. 현재 데이터에서는 PostgreSQL 원본만 `adopted`이며 나머지는 후보·PoC·보류 상태입니다.

---

## JSONB 인덱스 후보

```text
metadata @> ...
→ 기본 jsonb_ops GIN 후보

metadata #>> '{options,online}' = 'true'
→ 표현식 B-tree 후보
```

`CREATE INDEX IF NOT EXISTS`는 같은 이름의 기존 인덱스 정의가 올바른지 보장하지 않으므로 사용하지 않습니다. `06` 파일은 인덱스 미존재를 검사한 뒤 생성하고 정의를 조회합니다.

기본 `jsonb_ops`는 `?`, `?|`, `?&`, `@>`, `@?`, `@@` 등 다양한 연산을 지원합니다. `jsonb_path_ops`는 `@>`, `@?`, `@@`를 지원하지만 `?`, `?|`, `?&`는 지원하지 않으므로 실제 질의에 맞게 선택합니다.

표본이 3행뿐이므로 인덱스가 있어도 `Seq Scan`이 합리적일 수 있습니다.

---

## Column-Family 용어 범위

이 장의 partition key와 clustering key 설명은 Cassandra 계열을 중심으로 한 개념 예시입니다. 제품마다 키 구조, 정렬, 보조 인덱스와 트랜잭션 범위가 다르므로 공식 문서와 PoC로 확인합니다.

---

## 최종 검증 기준

`07_nosql_lab_validation.sql`은 다음을 판정합니다.

```text
Chapter 07 기준 3/2/3/5 + 명명 제약조건 15 + NOT NULL 20 유지
Chapter 12 기준 3/4/6
강의 301~303 원본 매핑
강사 instructor_snapshot 원본 대조
JSONB 핵심 구조·버전·시각
COURSE-301 ROLLBACK 기준 유지
Seed 캐시 4/3/1
인기 강의 cache course_ids 301~303
시스템 역할 6종
선택 근거 공백 0건
adopted 사례 1건
GIN·표현식 인덱스 정의
```

통과 메시지:

```text
Chapter 12 nosql_lab validation passed
```

---

## 안전 원칙

```text
- 생성·초기화·Seed 파일은 현재 DB와 상태를 실제 검사합니다.
- 모든 객체에 nosql_lab 스키마를 명시합니다.
- 기준 문서 수정은 버전 조건과 ROLLBACK을 사용합니다.
- JSONB를 전용 Document DB와 동일하게 설명하지 않습니다.
- 캐시 테이블을 실제 Key-Value DB로 과장하지 않습니다.
- 제품별 트랜잭션·일관성·확장성을 추측하지 않습니다.
- 원본과 파생 저장소의 동기화·재시도·멱등성·복구를 기록합니다.
- 후보 저장소와 최종 채택 결정을 구분합니다.
```
