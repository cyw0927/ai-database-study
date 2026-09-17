# Chapter 11 백업·복원 실행 기록

## 목적

PostgreSQL 16의 `security_lab` 또는 `ai_database_book` 논리 백업을 생성하고, 원본 DB가 아닌 별도 복원 DB에서 구조·데이터·제약조건·소유권과 권한을 검증합니다.

> 실제 비밀번호, 전체 접속 URL, libpq password file, 백업 파일과 복원 결과의 민감 데이터는 이 저장소에 기록하지 않습니다.

---

## 1. 실행 기준과 원본 상태

| 항목 | 기준 / 기록 |
| --- | --- |
| 교재 기준 PostgreSQL | 16 |
| 실행 날짜 |  |
| 담당자 |  |
| 원본 DB | `ai_database_book` |
| 복원 DB | `ai_database_book_restore` |
| 백업 범위 | `security_lab` / 전체 DB |
| 백업 형식 | custom / plain / directory |
| RPO 목표 |  |
| RTO 목표 |  |

원본 `security_lab` 기준:

```text
students / courses / enrollments = 3 / 3 / 3
JOIN = 3
상태 = 신청1 / 수강중1 / 완료1 / 취소0
recorded_amount = NUMERIC(12,0)
총 recorded_amount = 310000
활성 신청 = 2
활성 중복 = 0
recorded_amount와 course.price 불일치 = 0
```

확인 결과:

```text
_______________________________________________________________
```

---

## 2. 도구·서버 버전 호환성

| 항목 | 기록 |
| --- | --- |
| 원본 PostgreSQL 서버 버전 |  |
| 복원 PostgreSQL 서버 버전 |  |
| `pg_dump` 버전 |  |
| `pg_restore` 버전 |  |
| `psql` 버전 |  |

터미널:

```bash
pg_dump --version
pg_restore --version
psql --version
```

서버:

```sql
SHOW server_version;
```

판정:

```text
- pg_dump 주요 버전이 원본 서버보다 오래되면 실행을 중단하고 호환 도구를 준비한다.
- 복원 서버가 원본 서버보다 오래된 주요 버전이면 복원 호환성을 별도로 검토한다.
- 운영 복구에서는 extension과 외부 모듈 버전도 기록한다.
```

판정 결과:

```text
_______________________________________________________________
```

---

## 3. 저장 위치와 자격 증명 보호

| 항목 | 기록 |
| --- | --- |
| 백업 저장 위치 |  |
| 저장소 밖 경로인가 |  |
| 저장 암호화 |  |
| 전송 암호화 |  |
| 접근 가능 역할 |  |
| 보관 기간 |  |
| 삭제 절차 |  |
| 복원 임시 DB 삭제 시점 |  |
| password file 위치 |  |

```text
- 비밀번호를 명령줄 인자로 직접 기록하지 않는다.
- 저장소 예제에 PGPASSWORD 값을 넣지 않는다.
- 필요하면 저장소 밖의 libpq password file과 PGPASSFILE을 사용한다.

Unix 계열에서는 password file을 `chmod 0600` 수준으로 제한합니다. 권한이 느슨하면 libpq가 파일을 무시합니다. Windows는 별도 권한 검사를 하지 않으므로 접근이 제한된 보호 경로를 사용합니다.
- password file의 OS 접근 권한을 제한한다.
- 노출되면 파일 삭제보다 자격 증명 폐기·회전을 먼저 수행한다.
```

---

## 4. 백업 로그인 역할과 권한 역할

교재 역할:

```text
lab_role_backup_reader NOLOGIN
lab_backup_user LOGIN
```

PostgreSQL 16 membership 기대:

```text
lab_role_backup_reader → lab_backup_user
MEMBER = true
USAGE = true
inherit_option = true
set_option = true
admin_option = false 기대
```

| 확인 | 기대 | 실제 |
| --- | --- | --- |
| DB `CONNECT` | true |  |
| `security_lab` `USAGE` | true |  |
| students `SELECT` | true |  |
| courses `SELECT` | true |  |
| enrollments `SELECT` | true |  |
| students_id_seq `SELECT` | true |  |
| courses_id_seq `SELECT` | true |  |
| enrollments_id_seq `SELECT` | true |  |
| INSERT / UPDATE / DELETE | false |  |
| schema `CREATE` | false |  |

앱 역할의 sequence `USAGE`와 달리 백업 역할은 IDENTITY 시퀀스의 현재 상태 보존이 업무 목적이므로 sequence `SELECT`를 별도 허용합니다.

---

## 5. RLS 확인

교재의 `security_lab` 기대:

```text
students.relrowsecurity = false
courses.relrowsecurity = false
enrollments.relrowsecurity = false
```

운영 테이블에 RLS가 있다면 다음을 구분합니다.

```text
일반 전체 백업
→ pg_dump는 row_security를 끄고 모든 행을 읽으려 한다.
→ 백업 역할이 이를 우회할 수 없으면 오류로 중단될 수 있다.

--enable-row-security
→ 백업 역할에게 보이는 행만 의도적으로 덤프하는 선택이다.
→ 전체 백업과 같은 의미로 사용하지 않는다.
```

| 테이블 | RLS | FORCE RLS | 처리 결정 |
| --- | --- | --- | --- |
|  |  |  |  |

---

## 6. 특정 스키마 백업의 외부 의존성 확인

`--schema=security_lab`은 선택 스키마 외부의 모든 의존 객체를 자동으로 포함한다고 보장하지 않습니다.

| 의존성 | 존재 여부 | 처리 계획 |
| --- | --- | --- |
| 다른 스키마를 참조하는 FK |  |  |
| 사용자 정의 타입 |  |  |
| 함수·트리거 |  |  |
| 확장 기능 |  |  |
| Large Object |  |  |
| 외부 테이블 |  |  |

현재 교재의 `security_lab`은 외부 스키마 FK·사용자 정의 타입·트리거 의존성 없이 단독 복원할 수 있도록 설계했습니다.

---

## 7. security_lab custom archive 생성

```bash
pg_dump \
  -U <backup_user> \
  -d ai_database_book \
  -Fc \
  --schema=security_lab \
  -f <backup-dir>/security_lab.backup
```

중요:

```text
custom archive에는 원본 owner·ACL 메타데이터가 들어 있을 수 있다.
archive 형식에서 pg_dump --no-owner로 owner 메타데이터를 없앤다고 설명하지 않는다.
검증 복원에서 원본 owner 적용을 생략하려면 pg_restore --no-owner를 사용한다.
원본 ACL 적용을 생략하려면 pg_restore --no-privileges를 사용한다.
```

| 항목 | 기록 |
| --- | --- |
| 실행 로그인 역할 |  |
| 적용 권한 역할 |  |
| 종료 코드 |  |
| 표준 오류·경고 |  |
| 파일 크기 |  |
| 생성 시각 |  |
| 수행 시간 |  |

---

## 8. 전체 데이터베이스 백업 선택안

전체 DB 복구가 목적이라면 범위가 달라집니다.

```bash
pg_dump \
  -U <backup_user> \
  -d ai_database_book \
  -Fc \
  -f <backup-dir>/ai_database_book.backup
```

전체 DB를 선택한 이유:

```text
_______________________________________________________________
```

---

## 9. 전역 객체 백업 선택안

개별 데이터베이스 dump에는 Role과 Tablespace 같은 클러스터 전역 객체가 포함되지 않습니다.

역할 암호 정보를 제외하는 선택안:

```bash
pg_dumpall \
  --globals-only \
  --no-role-passwords \
  -U <admin_user> \
  -f <secure-backup-dir>/globals.sql
```

```text
- 같은 클러스터에서는 기존 Role·Tablespace와 충돌할 수 있다.
- 내용을 검토한 뒤 테스트 환경에서 적용한다.
- Role 파일은 일반 데이터 dump보다 더 엄격하게 보호한다.
```

전역 객체 백업 여부와 이유:

```text
_______________________________________________________________
```

---

## 10. archive 목록과 파일 해시

```bash
pg_restore --list <backup-dir>/security_lab.backup
```

| 확인 항목 | 결과 |
| --- | --- |
| `security_lab` 스키마 |  |
| students / courses / enrollments |  |
| IDENTITY 시퀀스 3개 |  |
| sequence set 3개 |  |
| PK·FK·UNIQUE·CHECK |  |
| `uq_security_enrollments_active` |  |
| ACL 항목 |  |
| 예상하지 않은 외부 객체 |  |

Windows PowerShell:

```powershell
Get-FileHash <backup-dir>\security_lab.backup -Algorithm SHA256
```

Linux·macOS:

```bash
sha256sum <backup-dir>/security_lab.backup
```

| 항목 | 기록 |
| --- | --- |
| 해시 알고리즘 | SHA-256 |
| 해시 값 |  |
| 측정 시각 |  |
| 재전송 후 해시 일치 |  |

해시는 파일 변경 여부를 확인하는 근거이며 실제 복원 가능성의 증거는 아닙니다.

---

## 11. 별도 복원 DB 생성

기존 `ai_database_book_restore`가 있다면 보존 필요 여부를 먼저 확인합니다. 자동으로 삭제하지 않습니다.

복원 역할을 DB owner로 지정하고 `template0`에서 깨끗한 DB를 만듭니다.

```bash
createdb \
  -U <admin_user> \
  -O <restore_user> \
  -T template0 \
  ai_database_book_restore
```

| 항목 | 기록 |
| --- | --- |
| 기존 DB 충돌 확인 |  |
| 생성 성공 |  |
| DB owner |  |
| 인코딩 |  |
| template | `template0` |

---

## 12. custom archive 원자적 복원

```bash
pg_restore \
  -U <restore_user> \
  -d ai_database_book_restore \
  --single-transaction \
  --no-owner \
  --no-privileges \
  <backup-dir>/security_lab.backup
```

```text
--single-transaction
→ 작은 실습에서 전체 복원을 한 트랜잭션으로 묶어 부분 객체 잔존 위험을 줄인다.

--no-owner
→ archive의 원본 owner 적용을 생략하고 복원 실행 역할이 객체를 생성·소유한다.

--no-privileges
→ archive의 GRANT·REVOKE ACL 적용을 생략한다.
```

| 항목 | 기록 |
| --- | --- |
| 시작 시각 |  |
| 완료 시각 |  |
| 종료 코드 |  |
| 경고·오류 |  |
| 부분 객체 잔존 여부 |  |
| 원본 owner 미적용 |  |
| 원본 ACL 미적용 |  |

대규모 운영 복원에서는 긴 트랜잭션, 잠금, WAL, 디스크 공간과 자원 사용을 별도로 검토합니다.

---

## 13. Plain SQL 원자적 복원 선택안

```bash
psql \
  -X \
  -1 \
  -U <restore_user> \
  -d ai_database_book_restore \
  -v ON_ERROR_STOP=1 \
  -f <backup-dir>/security_lab.sql
```

```text
-X               → 사용자의 psqlrc 설정을 읽지 않음
-1               → 파일 전체를 하나의 트랜잭션으로 실행
ON_ERROR_STOP=1  → 첫 오류에서 중단
```

덤프 출처를 신뢰할 수 있는지도 확인합니다. 복원은 대상 서버에서 SQL과 객체 정의를 실행하는 작업입니다.

---

## 14. 복원 검증 1단계: 구조·데이터·소유권

```bash
psql \
  -X \
  -U <restore_user> \
  -d ai_database_book_restore \
  -v ON_ERROR_STOP=1 \
  -f code/chapter11/06_restore_validation.sql
```

`06_restore_validation.sql`은 원본 DB에서 실행하면 예외를 발생시킵니다.

| 검증 항목 | 기대 | 실제 | 통과 |
| --- | ---: | ---: | --- |
| students | 3 |  |  |
| courses | 3 |  |  |
| enrollments | 3 |  |  |
| JOIN | 3 |  |  |
| 신청 / 수강중 / 완료 / 취소 | 1 / 1 / 1 / 0 |  |  |
| 총 recorded_amount | 310000 |  |  |
| recorded_amount 타입 | NUMERIC(12,0) |  |  |
| recorded_amount-course.price 불일치 | 0 |  |  |
| 고아 student FK | 0 |  |  |
| 고아 course FK | 0 |  |  |
| 활성 신청 중복 | 0 |  |  |
| NOT NULL | 14 |  |  |
| 명시 제약조건 | 13 |  |  |
| 활성 신청 부분 고유 인덱스 | valid / ready |  |  |
| IDENTITY 시퀀스 | 3 |  |  |
| 다음 자동값 | 현재 최대 ID보다 큼 |  |  |
| schema·table·sequence owner | `<restore_user>` |  |  |

자동 성공 메시지:

```text
Chapter 11 restore structure and data validation passed
```

`--no-privileges`를 사용했더라도 복원 역할의 Default Privileges가 새 객체 생성 시 적용될 수 있으므로 실제 ACL을 조회합니다.

---

## 15. 복원 검증 2단계: 역할·권한 재적용

```text
1. 03_role_permission_plan.sql 검토
2. 필요한 Role·GRANT를 복원 테스트 환경에 적용
3. PostgreSQL 16 membership 옵션 확인
4. 04_permission_checks.sql 실행
5. 05_permission_behavior_tests.sql 실행
6. 허용·차단 결과 기록
```

| 역할 | SELECT | INSERT | status UPDATE | recorded_amount UPDATE | DELETE | schema CREATE |
| --- | --- | --- | --- | --- | --- | --- |
| `lab_readonly_user` | 성공 | 실패 | 실패 | 실패 | 실패 | 실패 |
| `lab_enrollment_user` | 성공 | 성공 | 성공 | 실패 | 실패 | 실패 |
| `lab_backup_user` | 성공 | 실패 | 실패 | 실패 | 실패 | 실패 |

백업 역할:

```text
students_id_seq SELECT = 성공
courses_id_seq SELECT = 성공
enrollments_id_seq SELECT = 성공
```

PUBLIC·직접 GRANT·membership·소유권을 포함한 권한 경로를 함께 확인합니다.

---

## 16. reset 원자성 시험

정상 reset:

```text
security_lab만 삭제
course_project 유지
Role 유지
CASCADE 사용 안 함
```

예상하지 못한 객체를 추가한 경계 시험:

```sql
CREATE TABLE security_lab.keep_me (id INTEGER);
```

`reset_security_lab.sql` 실행 기대:

```text
DROP SCHEMA 실패
앞선 known table DROP도 ROLLBACK
students / courses / enrollments / keep_me 모두 유지
```

시험 후 `keep_me`를 명시적으로 제거하고 reset을 다시 실행합니다.

| 항목 | 결과 |
| --- | --- |
| 예상 객체에서 reset 실패 |  |
| known tables 롤백 유지 |  |
| keep_me 유지 |  |
| keep_me 제거 후 reset 성공 |  |
| course_project 불변 |  |

---

## 17. 오류와 해결 기록

| 단계 | 오류 | 원인 | 해결 | 재검증 |
| --- | --- | --- | --- | --- |
| 버전 확인 |  |  |  |  |
| membership |  |  |  |  |
| 백업 권한 |  |  |  |  |
| RLS |  |  |  |  |
| 스키마 의존성 |  |  |  |  |
| 백업 |  |  |  |  |
| 목록·해시 |  |  |  |  |
| 복원 |  |  |  |  |
| 구조·데이터 검증 |  |  |  |  |
| 권한 검증 |  |  |  |  |
| reset 원자성 |  |  |  |  |

---

## 18. RPO·RTO와 최종 판정

| 기준 | 목표 | 실제 | 충족 | 개선안 |
| --- | --- | --- | --- | --- |
| RPO |  |  |  |  |
| RTO |  |  |  |  |

RPO는 허용 가능한 데이터 손실 시점이고, RTO는 서비스 재개까지 허용되는 시간입니다. 백업 주기와 실제 복원 시간이 두 목표를 모두 충족해야 합니다.

정리:

| 항목 | 기록 |
| --- | --- |
| 복원 DB 정리 승인 |  |
| 임시 파일 삭제 |  |
| 보존 백업 이동 |  |
| 접근 권한 재확인 |  |
| 백업 역할 권한 회수·유지 |  |
| 다음 복원 시험 날짜 |  |
| 담당자 인수인계 |  |

최종 판정:

```text
백업 성공
/ archive 목록·해시 확인
/ 별도 DB 복원 성공
/ 구조·데이터·소유권 검증 성공
/ 역할·권한 검증 성공
/ reset 격리 검증 성공
```
