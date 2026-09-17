# Chapter 11 실습 코드

## 데이터베이스를 안전하게 지키고 복구하는 방법

기준 환경은 **PostgreSQL 16**입니다. 이 폴더는 기존 프로젝트를 변경하지 않고 `security_lab`에서 최소 권한을 설계하고, custom archive를 별도 데이터베이스에 복원해 구조·데이터·소유권과 권한을 검증합니다.

---

## 보호 범위

```text
course_project: 변경하지 않음
transaction_lab: 존재하면 변경하지 않음
performance_lab: 존재하면 변경하지 않음
public: 변경하지 않음
security_lab: Chapter 11 실습 대상
Role: 클러스터 전역 객체이므로 자동 생성·삭제하지 않음
```

Chapter 11의 필수 시작 기준은 Chapter 07·08의 `course_project`입니다.

```text
3 / 2 / 3 / 5
상태 = 신청2 / 수강중1 / 완료1 / 취소1
recorded_amount NUMERIC(12,0)
전체 590000
활성 3 / 340000
취소 제외 4 / 440000
1001 완료 / 100000
1004 취소 / 150000
1005 신청 / 120000
uq_course_enrollments_active 존재
Chapter 07 명명 제약조건 15개 / NOT NULL 열 20개 유지
현재 역할의 ai_database_book CREATE 권한 확인
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
| `01_security_lab_schema.sql` | Chapter 07·08 전체 기준·구조 계약·DB CREATE 권한을 검사하고 스키마·테이블·부분 고유 인덱스를 한 트랜잭션에서 생성·검증 |
| `02_security_lab_seed.sql` | 3/3/3 샘플, 상태 분포, 총 310000, IDENTITY와 무결성 자동 검증 |
| `03_role_permission_plan.sql` | PostgreSQL 16 membership, Role·GRANT·REVOKE·Default Privileges·백업 역할·소유권·정리 계획 |
| `04_permission_checks.sql` | PUBLIC·ACL·membership 옵션·RLS·시퀀스·유효 권한 확인 |
| `05_permission_behavior_tests.sql` | 읽기·앱 계정 허용 동작과 기준 보존, 차단 동작 선택 실습 |
| `05_restore_validation.sql` | 기존 링크 호환용 안내 |
| `06_restore_validation.sql` | 별도 복원 DB의 구조·데이터·금액·제약조건·IDENTITY·소유권 자동 검증 |
| `BACKUP_RESTORE_RUNBOOK.md` | 버전·권한·RLS·의존성·archive·원자적 복원·2단계 검증 실행 기록 |
| `reset_security_lab.sql` | CASCADE 없이 transaction으로 `security_lab`만 초기화, 예상 밖 객체가 있으면 전체 ROLLBACK |
| `security_backup_check.sql` | 읽기 전용 안내·상태 확인 진입점 |

---

## 실행 순서

```text
01_security_lab_schema.sql
→ 02_security_lab_seed.sql
→ 03_role_permission_plan.sql에서 필요한 문장만 선택 실행
→ 04_permission_checks.sql
→ 05_permission_behavior_tests.sql 선택 실습
→ 터미널에서 custom archive 백업
→ 별도 DB 생성·원자적 복원
→ 복원 DB에서 06_restore_validation.sql
→ 역할 재적용 후 04·05 권한 재검증
→ BACKUP_RESTORE_RUNBOOK.md 기록
```

Role 생성과 권한 변경은 관리자 권한이 있는 테스트 환경에서만 수행합니다.

---

## security_lab 기준 상태

```text
students = 3
courses = 3
enrollments = 3
JOIN = 3
상태 = 신청1 / 수강중1 / 완료1 / 취소0
recorded_amount 합계 = 310000
활성 신청 = 2
활성 중복 = 0
recorded_amount와 course.price 불일치 = 0
```

| 테이블 | 명시적 ID | IDENTITY 다음 값 |
| --- | --- | ---: |
| `security_lab.students` | 101~103 | 104 이상 |
| `security_lab.courses` | 201~203 | 204 이상 |
| `security_lab.enrollments` | 1001~1003 | 1004 이상 |

`recorded_amount`는 **신청 시점에 신청 행에 기록한 금액**이며 `NUMERIC(12,0)`입니다. 실제 결제 승인액·환불 반영 순매출·회계 매출을 의미하지 않습니다.

Chapter 07의 활성 신청 정책을 유지합니다.

```sql
CREATE UNIQUE INDEX uq_security_enrollments_active
ON security_lab.enrollments (student_id, course_id)
WHERE status IN ('신청', '수강중');
```

완료·취소 이력은 여러 건 허용하지만 진행 중 신청은 학생·강의 조합당 한 건입니다.

학생 이메일은 `NOT NULL`, 정확히 같은 문자열에 대한 `UNIQUE`, 공백 문자열 방지 `CHECK`를 사용합니다. 대소문자 정규화는 이 장의 범위가 아닙니다.

---

## 역할 예시

```text
lab_role_security_owner NOLOGIN
lab_role_report_reader NOLOGIN
lab_role_enrollment_app NOLOGIN
lab_role_backup_reader NOLOGIN
lab_readonly_user LOGIN
lab_enrollment_user LOGIN
lab_backup_user LOGIN
```

실제 비밀번호나 password file은 SQL과 저장소에 기록하지 않습니다.

### PostgreSQL 16 membership

교재의 의도:

```text
report_reader → readonly_user   : INHERIT TRUE / SET TRUE
app_role      → enrollment_user : INHERIT TRUE / SET TRUE
backup_reader → backup_user     : INHERIT TRUE / SET TRUE
ADMIN OPTION  : 기본 불필요
```

다음을 함께 확인합니다.

```text
pg_has_role(..., 'MEMBER')
pg_has_role(..., 'USAGE')
pg_auth_members.inherit_option
pg_auth_members.set_option
pg_auth_members.admin_option
```

---

## 최소 권한 기준

### 보고 역할

```text
DB CONNECT
security_lab USAGE
students·courses·enrollments SELECT
INSERT·UPDATE·DELETE·schema CREATE 불허
```

### 수강신청 앱 역할

```text
DB CONNECT
security_lab USAGE
students·courses·enrollments SELECT
enrollments INSERT
enrollments.status 컬럼 UPDATE
enrollments_id_seq USAGE
recorded_amount UPDATE·DELETE·TRUNCATE·schema CREATE 불허
```

`nextval()` 사용에는 시퀀스 `USAGE`면 충분합니다. 시퀀스 상태를 직접 조회할 업무 요구가 없다면 앱 역할에 `SELECT`는 부여하지 않습니다.

### 백업 역할

```text
DB CONNECT
security_lab USAGE
students·courses·enrollments SELECT
students_id_seq·courses_id_seq·enrollments_id_seq SELECT
INSERT·UPDATE·DELETE·schema CREATE 불허
```

백업 역할의 시퀀스 `SELECT`는 IDENTITY 상태를 포함한 논리 백업 검증을 위한 권한입니다.

---

## 비밀번호와 password file

루트 `.env.example`에는 실제 비밀번호를 두지 않고 `PGPASSFILE` 경로만 설정합니다.

```text
PGHOST=
PGPORT=
PGDATABASE=
PGUSER=
PGPASSFILE=
```

`PGPASSWORD`를 저장소나 장기 실행 환경에 보관하지 않습니다. 실제 password file은 저장소 밖에 둡니다.

Unix 계열에서는 password file을 그룹·다른 사용자가 읽지 못하도록 **`chmod 0600` 수준**으로 제한합니다. 권한이 더 느슨하면 libpq가 파일을 무시할 수 있습니다. Windows는 별도의 password file 권한 검사를 하지 않으므로 사용자 프로필 또는 접근이 제한된 보호 경로를 사용합니다.

---

## 백업·복원 핵심 원칙

```text
백업 전 서버·pg_dump·pg_restore·psql 버전 기록
백업 Role과 최소 권한 확인
RLS 적용 여부 확인
스키마 외부 의존성 확인
custom archive 생성
pg_restore --list로 archive 내용 확인
SHA-256 기록
원본이 아닌 별도 DB에 복원
구조·데이터·소유권 검증
Role·GRANT 재적용 후 실제 허용·차단 동작 검증
```

custom archive 생성 예:

```bash
pg_dump \
  -U <backup_user> \
  -d ai_database_book \
  -Fc \
  --schema=security_lab \
  -f <backup-dir>/security_lab.backup
```

custom archive에는 원본 owner·ACL 메타데이터가 포함될 수 있습니다. 테스트 복원에서는 적용 여부를 복원 단계에서 제어합니다.

```bash
pg_restore \
  -U <restore_user> \
  -d ai_database_book_restore \
  --single-transaction \
  --no-owner \
  --no-privileges \
  <backup-dir>/security_lab.backup
```

`--no-owner`는 archive의 원본 소유권 설정을 적용하지 않고, `--no-privileges`는 GRANT·REVOKE 복원을 생략합니다. 이 옵션을 사용했다고 권한 검증이 끝난 것은 아니므로 복원 DB의 실제 owner·ACL을 확인합니다.

---

## RLS 주의

이 실습의 `security_lab`은 RLS를 사용하지 않습니다.

일반적인 전체 논리 백업에서는 `pg_dump`가 row security를 끄고 전체 데이터를 읽으려 합니다. 백업 역할이 정책을 우회할 수 없으면 실패할 수 있습니다. `--enable-row-security`는 **역할에게 보이는 행만 의도적으로 백업**하려는 경우에만 별도로 검토하며 운영 전체 백업과 같은 의미로 사용하지 않습니다.

---

## 복원 검증 기준

`06_restore_validation.sql`의 핵심 기준:

```text
복원 DB = ai_database_book_restore
students / courses / enrollments = 3 / 3 / 3
JOIN = 3
상태 = 신청1 / 수강중1 / 완료1 / 취소0
총 recorded_amount = 310000
recorded_amount = NUMERIC(12,0)
고아 FK = 0
활성 중복 = 0
NOT NULL = 14
명시 제약조건 = 13
부분 고유 인덱스 valid / ready
IDENTITY 시퀀스 = 3
다음 자동 ID > 기존 최대 ID
schema·table·sequence owner = 복원 역할
```

원본 ACL을 생략한 테스트 복원 뒤에는 역할·권한 정책을 다시 적용하고 `04_permission_checks.sql`과 실제 허용·차단 테스트를 수행합니다.

---

## 초기화

`reset_security_lab.sql`은 `security_lab`만 제거합니다. 예상하지 않은 객체가 있으면 자동 삭제하지 않고 중단하며, `CASCADE`를 기본으로 사용하지 않습니다.

Role은 클러스터 전역 객체이므로 reset 파일에서 자동 삭제하지 않습니다.
