# Chapter 06 실습 코드

## 정규화와 데이터 무결성으로 좋은 테이블 만들기

이 폴더는 정규화 전후 구조를 비교하고, 기존 데이터가 새 업무 규칙을 만족하는지 확인한 뒤 PostgreSQL 제약조건을 추가·검증하는 SQL 파일을 관리합니다.

---

## 권장 번호형 파일

| 파일 | 시작 상태 | 완료 상태 | 반복 실행 |
| --- | --- | --- | --- |
| `01_normalization_schema.sql` | 실습 테이블 없음 | 제약조건 전 빈 기본 구조 4개 | 한 번 |
| `02_normalization_seed.sql` | 네 테이블이 비어 있음 | raw 3·회원 2·도서 2·대여 3 | 한 번 |
| `03_normalization_compare.sql` | 정상 샘플 존재 | 정규화 전후·관계·날짜 자동 검증 | 가능 |
| `04_add_integrity_rules.sql` | 업무 규칙 미적용 | C-01~C-08 적용·메타데이터 확인 | 한 번 |
| `05_integrity_tests.sql` | 규칙 적용 완료 | 경계·오류 테스트·기준 상태 재확인 | 한 테스트씩 |
| `reset_normalization.sql` | 어떤 실습 상태 | Chapter 06 실습 객체 삭제 | 필요할 때만 |

## 기존 파일명

다음 파일은 기존 링크와 자료 호환을 위해 유지합니다.

| 기존 파일 | 대응 번호 파일 |
| --- | --- |
| `normalization_schema.sql` | `01_normalization_schema.sql` |
| `normalization_seed.sql` | `02_normalization_seed.sql` |
| `normalization_practice.sql` | `03_normalization_compare.sql` |
| `integrity_tests.sql` | `05_integrity_tests.sql` |

기존 파일과 번호 파일은 같은 역할이므로 둘 중 하나만 실행합니다. 무결성 규칙 추가는 공통으로 `04_add_integrity_rules.sql`을 사용합니다.

---

## 권장 실행 순서

```text
현재 연결 확인
→ 01_normalization_schema.sql
→ 02_normalization_seed.sql
→ 03_normalization_compare.sql
→ 04_add_integrity_rules.sql
→ 05_integrity_tests.sql에서 한 테스트씩 실행
```

처음부터 다시 시작할 때는 다음 순서를 사용합니다.

```text
reset_normalization.sql
→ 01_normalization_schema.sql
→ 02_normalization_seed.sql
→ 03_normalization_compare.sql
→ 04_add_integrity_rules.sql
```

---

## 공통 실행 원칙

```text
1. ai_database_book 연결인지 확인한다.
2. 현재 사용자와 search_path를 확인한다.
3. Auto-commit 상태를 확인한다.
4. public.table_name처럼 스키마를 명시한다.
5. 각 파일의 시작 상태를 확인한다.
6. 번호 파일과 호환 파일을 중복 실행하지 않는다.
7. 오류 테스트는 한 번에 하나씩 실행한다.
8. 오류 후 기준 데이터가 유지되는지 확인한다.
9. 01에서 테이블을 생성한 사용자와 같은 PostgreSQL 역할로 02~05를 실행한다.
```

현재 스키마는 환경에 따라 `public`이 아닐 수 있습니다. 주요 객체는 `public.members_nf`처럼 스키마를 명시하므로 `current_schema() = public`을 실행 조건으로 강제하지 않습니다.

---

## 실습 테이블과 한 행 의미

| 테이블 | 한 행의 의미 |
| --- | --- |
| `library_records_raw` | 대여 사건과 회원·도서 현재 사실이 섞인 한 건 |
| `members_nf` | 회원 한 명 |
| `books_nf` | 이 장에서 대여 대상으로 취급하는 간소화된 도서 항목 한 건 |
| `loans_nf` | 특정 회원이 특정 도서를 대여한 사건 한 건 |

`books_nf`는 제목·판본·실제 복본을 완전히 분리한 운영 모델이 아닙니다. 동일 ISBN 복본과 여러 저자는 이번 장의 범위 밖입니다.

---

## 01 생성 단계의 원자성

`01_normalization_schema.sql`과 호환 `normalization_schema.sql`은 다음 흐름을 사용합니다.

```text
DB·public·쓰기 가능 여부 확인
→ 네 테이블 미존재 확인
→ BEGIN
→ raw / members_nf / books_nf / loans_nf 생성
→ 네 테이블 존재·0행 확인
→ COMMIT
```

생성 중 오류가 발생하면 트랜잭션 전체가 실패하므로 일부 테이블만 생성된 상태를 완료 상태로 남기지 않습니다.

---

## 02 샘플 입력의 원자성

`02_normalization_seed.sql`과 호환 `normalization_seed.sql`은 다음을 하나의 트랜잭션으로 처리합니다.

```text
네 테이블 존재·0행 확인
→ BEGIN
→ raw 3행
→ members_nf 2행
→ books_nf 2행
→ loans_nf 3행
→ IDENTITY 다음 값 조정
→ 기준 상태 검증
→ COMMIT
```

커밋 전 기준:

```text
raw = 3
members = 2
books = 2
loans = 3
미반납 = 2
회원 101 대여 = 2
도서 201 대여 = 2
```

명시적 ID 다음 값:

```text
library_records_raw.loan_id = 1004부터
members_nf.id = 103부터
books_nf.id = 203부터
loans_nf.id = 1004부터
```

---

## 03 정규화 전후 비교

`03_normalization_compare.sql`은 데이터를 변경하지 않고 다음을 자동 판정합니다.

```text
raw = 3
members = 2
books = 2
loans = 3
미반납 = 2
회원 101 대여 = 2
도서 201 대여 = 2
회원 고아 참조 = 0
도서 고아 참조 = 0
날짜 순서 오류 = 0
도서 201 재대여 시간 순서 오류 = 0
활성 대여 중복 = 0
```

통과 메시지:

```text
Chapter 06 normalization comparison passed
```

JOIN은 정규화 후에도 원래 업무 결과를 재구성할 수 있는지 확인하는 최소 용도로만 사용합니다. 상세 JOIN은 Chapter 08에서 다룹니다.

---

## 확정 규칙 C-01~C-08

| ID | 규칙 | 구현 |
| --- | --- | --- |
| C-01 | 정확히 같은 이메일 문자열 중복 금지 | `UNIQUE (email)` |
| C-02 | ISBN 필수·같은 문자열 중복 금지 | `NOT NULL` + `UNIQUE (isbn)` |
| C-03 | 공백 이름·제목 금지 | `CHECK` |
| C-04 | 반납예정일은 대여일 이상 | `CHECK` |
| C-05 | 실제반납일은 `NULL` 또는 대여일 이상 | `CHECK` |
| C-06 | 존재하는 회원·도서만 참조 | `FOREIGN KEY` |
| C-07 | 참조 중인 부모 삭제 금지 | `ON DELETE RESTRICT` |
| C-08 | 도서당 미반납 대여 최대 한 건 | 부분 고유 인덱스 |

이메일 대소문자·별칭 정규화, 동일 ISBN 복본, 여러 저자, 과거 기간 전체 중첩은 이 장에서 다루지 않습니다.

---

## 04 기존 데이터 검사 후 규칙 추가

`04_add_integrity_rules.sql`은 하나의 트랜잭션 안에서 다음 순서로 동작합니다.

```text
현재 DB·쓰기 가능 여부 확인
→ Chapter 05에서 확정된 필수값과 Chapter 06의 새 정책을 기존 데이터에서 검사
→ 정확한 대상 테이블의 기존 규칙 존재 여부 확인
→ NULL·중복·공백·날짜·고아 참조·활성 중복 검사
→ ALTER COLUMN SET NOT NULL
→ UNIQUE·CHECK·FOREIGN KEY 추가
→ 부분 고유 인덱스 생성
→ 적용 메타데이터 검증
→ COMMIT
```

커밋 전 자동 확인:

```text
명명된 제약조건 = 8개
NOT NULL 적용 열 = 10개
uq_loans_nf_active_book 존재
```

같은 제약조건 이름이 다른 테이블이나 스키마에 존재하더라도 Chapter 06 대상 테이블의 규칙만 판정하도록 `conrelid`까지 확인합니다.

---

## 05 정상·경계·오류 테스트

파일 시작 시 다음 상태를 확인합니다.

```text
Chapter 06 네 테이블 존재
명명된 제약조건 8개 존재
부분 고유 인덱스 존재
```

### 허용되어야 하는 경계값

```text
due_at = borrowed_at
returned_at = borrowed_at
returned_at = NULL
published_year = NULL
공백이 아닌 한 글자 이름
```

### 실패해야 하는 오류값

```text
NOT NULL 위반
ISBN NULL 위반
이메일·ISBN UNIQUE 위반
공백 이름·제목 CHECK 위반
존재하지 않는 회원 FOREIGN KEY 위반
존재하지 않는 도서 FOREIGN KEY 위반
날짜 순서 CHECK 위반
두 번째 미반납 대여 부분 고유 인덱스 위반
참조 중 부모 삭제 RESTRICT/FK 위반
```

각 오류 예제에는 기대 제약조건 또는 인덱스 이름을 주석으로 표시했습니다. 실패해야 하는 SQL은 한 번에 하나만 실행합니다.

테스트 후 자동 기준 상태 확인:

```text
raw 3 / members 2 / books 2 / loans 3 / 미반납 2
회원 101 = 2 / 도서 201 = 2
고아 참조 = 0 / 활성 중복 = 0
```

통과 메시지:

```text
Chapter 06 integrity test baseline preserved
```

수동 커밋 상태에서 다음 메시지가 나타나면:

```text
current transaction is aborted
```

실패한 트랜잭션을 종료합니다.

```sql
ROLLBACK;
```

---

## 초기화

`reset_normalization.sql`은 다음을 확인한 뒤 Chapter 06 대상만 삭제합니다.

```text
현재 DB = ai_database_book
public 스키마 존재
읽기 전용 연결 아님
```

삭제 순서:

```text
public.loans_nf
→ public.books_nf
→ public.members_nf
→ public.library_records_raw
```

부분 인덱스와 테이블 소속 제약조건은 테이블 삭제 시 함께 제거됩니다.

---

## 범위 안내

```text
JOIN 상세는 Chapter 08
트랜잭션과 오류 복구는 Chapter 09
인덱스와 성능은 Chapter 10
JSONB 구조는 Chapter 12
운영 데이터 정제·무중단 마이그레이션은 심화 범위
```
