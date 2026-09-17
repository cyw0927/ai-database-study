# Chapter 03 실습 코드

## PostgreSQL과 DBeaver 실습 환경 확인

이 폴더는 Chapter 03의 환경 조회와 로컬 필수 경로 자동 검증 SQL을 관리합니다.

---

## 파일 목록

| 파일 | 역할 |
| --- | --- |
| `setup_check.sql` | 서버·DB·스키마·검색 경로·사용자·읽기 전용 상태·시간대를 사람이 확인하는 조회 파일 |
| `setup_validate_local.sql` | Chapter 04 이후 실습에 필요한 로컬 조건을 예외 기반으로 판정하는 완료 게이트 |

두 파일 모두 테이블과 데이터를 생성·수정·삭제하지 않습니다.

---

## 실행 전 확인

DBeaver에서 다음 대상을 선택합니다.

```text
대상 데이터베이스: ai_database_book
실습 대상 스키마: public
```

`current_schema()`가 항상 `public`이어야 하는 것은 아닙니다. 현재 스키마와 `search_path`는 `setup_check.sql`에서 확인하고, `public`의 존재와 `USAGE`·`CREATE` 권한은 검증 파일에서 별도로 판정합니다.

---

## 권장 실행 순서

```text
1. DBeaver에서 ai_database_book 연결 선택
2. SQL Editor 열기
3. setup_check.sql 실행
4. 한 행 요약 결과 확인
5. setup_validate_local.sql 실행
6. 통과 메시지 확인
```

통과 메시지:

```text
Chapter 03 recommended local environment validation passed
```

---

## `setup_check.sql` 결과

| 확인 항목 | 필수 판정 또는 참고 내용 |
| --- | --- |
| PostgreSQL 버전 | 버전 문자열 확인 |
| `current_database()` | `ai_database_book`이어야 함 |
| `current_schema()` | 환경에 따라 `public`이 아닐 수 있음 |
| `SHOW search_path` | 검색 순서를 읽고 설명할 수 있어야 함 |
| `current_user` | 예상한 접속 사용자 |
| `transaction_read_only` | 로컬 필수 경로는 `off` |
| `TimeZone` | 현재 세션 시간대 확인 |
| `CURRENT_TIMESTAMP` | 날짜·시간 값 반환 확인 |
| `1 + 1` | `2` |
| 요약 결과 | DB·public·USAGE·CREATE·읽기 전용 상태를 한 행으로 확인 |

---

## `setup_validate_local.sql` 판정 기준

```text
PostgreSQL 15 이상
current_database() = ai_database_book
현재 사용자의 CONNECT 권한
public 스키마 존재
현재 사용자의 public USAGE 권한
현재 사용자의 public CREATE 권한
transaction_read_only = off
SQL 계산 결과 정상
```

이 파일은 로컬 필수 경로 전용입니다. 관리형 PostgreSQL, 읽기 전용 복제본 또는 Supabase 선택 경로는 데이터베이스 이름과 권한 정책이 다를 수 있으므로 이 완료 게이트를 그대로 사용하지 않습니다.

---

## 재실행 가능성

두 파일은 다음 데이터 변경 명령을 포함하지 않습니다.

```text
CREATE TABLE
INSERT
UPDATE
DELETE
DROP
```

따라서 연결 상태를 다시 확인할 때 반복 실행할 수 있습니다. 테이블 생성과 CRUD는 Chapter 04, 제약조건 오류는 Chapter 06에서 다룹니다.

---

## 보안 주의

```text
- 비밀번호를 SQL 파일에 작성하지 않습니다.
- 전체 클라우드 접속 URL을 저장하지 않습니다.
- 실제 .env와 password file을 커밋하지 않습니다.
- 화면 캡처와 AI 질문에도 비밀정보를 포함하지 않습니다.
```

후속 장의 접속 정보는 다음 libpq 변수 체계를 사용합니다.

```text
PGHOST
PGPORT
PGDATABASE
PGUSER
PGPASSFILE
```