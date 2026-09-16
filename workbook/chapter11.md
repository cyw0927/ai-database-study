# Chapter 11 독자 워크북

## 데이터베이스를 안전하게 지키고 복구하는 방법

> 이 워크북은 **PostgreSQL 16**의 `security_lab`을 기준으로 최소 권한, PUBLIC·membership·소유권, 비밀 정보 보호, 백업·복원 검증 결과를 기록하기 위한 자료입니다. Role 변경은 관리자 권한이 있는 테스트 환경에서, 복원 검증은 반드시 별도 DB에서 진행합니다.

---

## 1. 실습 파일과 순서

```text
01_security_lab_schema.sql
02_security_lab_seed.sql
03_role_permission_plan.sql
04_permission_checks.sql
05_permission_behavior_tests.sql
06_restore_validation.sql
BACKUP_RESTORE_RUNBOOK.md
reset_security_lab.sql
```

권장 순서:

```text
Chapter 07·08 기준 확인
→ 01 → 02
→ 03에서 필요한 역할·권한 문장만 검토·선택 실행
→ 04 PUBLIC·ACL·membership·RLS·유효 권한 확인
→ 05 허용·차단 동작 선택 실습
→ 터미널 custom archive 백업
→ 별도 DB 원자적 복원
→ 복원 DB에서 06 실행
→ 역할 재적용 후 04·05 재검증
→ RUNBOOK 기록
```

`05_restore_validation.sql`은 기존 링크 안내 파일이며 최종 복원 검증에는 `06_restore_validation.sql`을 사용합니다.

---

## 2. 실행 위치와 Chapter 07·08 기준 확인

```sql
SELECT current_database();
SELECT current_schema();
SHOW search_path;
```

| 확인 항목 | 기대 | 실제 | 통과 |
| --- | --- | --- | --- |
| 원본 실습 DB | `ai_database_book` |  |  |
| PostgreSQL major | 16 |  |  |
| students / instructors / courses / enrollments | 3 / 2 / 3 / 5 |  |  |
| 상태 | 신청2 / 수강중1 / 완료1 / 취소1 |  |  |
| `recorded_amount` 타입 | `NUMERIC(12,0)` |  |  |
| 전체 기록 금액 | 590000 |  |  |
| 활성 신청 | 3 / 340000 |  |  |
| 취소 제외 | 4 / 440000 |  |  |
| 1001 | 완료 / 100000 |  |  |
| 1004 | 취소 / 150000 |  |  |
| 1005 | 신청 / 120000 |  |  |
| 활성 신청 부분 고유 인덱스 | 존재 |  |  |
| `security_lab` 생성 전 | 미존재 |  |  |

| 스키마 | Chapter 11 처리 | 확인 |
| --- | --- | --- |
| `course_project` | 변경 금지 |  |
| `transaction_lab` | 존재하면 변경 금지 |  |
| `performance_lab` | 존재하면 변경 금지 |  |
| `public` | 변경 금지 |  |
| `security_lab` | 생성·실습·초기화 대상 |  |

운영 DB가 아닌 테스트 환경임을 확인한 근거:

```text
_______________________________________________________________
```

---

## 3. 보호 자산과 위험 목록

| 보호 자산 | 포함 데이터 | 주요 위험 | 통제 방법 |
| --- | --- | --- | --- |
| 개인정보 | 이름·이메일 |  |  |
| 접속 정보 | 호스트·계정·비밀 |  |  |
| 업무 데이터 | 상태·기록 금액 |  |  |
| 데이터 구조 | 테이블·제약조건 |  |  |
| 로그 | SQL·오류·접속 기록 |  |  |
| 백업 파일 | 전체 데이터 사본 |  |  |
| 복구 절차 | 계정·순서·판정 기준 |  |  |

가장 먼저 줄여야 할 위험과 이유:

```text
_______________________________________________________________
```

---

## 4. 인증·권한·소유권·감사 구분

| 개념 | 핵심 질문 | Chapter 11 예시 |
| --- | --- | --- |
| 인증 | 누가 접속했는가? |  |
| 권한 부여 | 무엇을 할 수 있는가? |  |
| 소유권 | 누가 객체를 관리하는가? |  |
| 역할 멤버십 | 어떤 권한 역할을 사용할 수 있는가? |  |
| 감사·기록 | 누가 무엇을 했는가? |  |

앱 로그인 역할을 객체 소유자로 두면 위험한 이유:

```text
_______________________________________________________________
```

---

## 5. 로그인 역할·권한 역할과 PostgreSQL 16 membership

| 역할 | LOGIN | 목적 | 실제 생성 여부 |
| --- | --- | --- | --- |
| `lab_role_security_owner` | NOLOGIN | 객체 소유 |  |
| `lab_role_report_reader` | NOLOGIN | 읽기 권한 묶음 |  |
| `lab_role_enrollment_app` | NOLOGIN | 앱 권한 묶음 |  |
| `lab_role_backup_reader` | NOLOGIN | 백업 권한 묶음 |  |
| `lab_readonly_user` | LOGIN | 보고 접속 |  |
| `lab_enrollment_user` | LOGIN | 앱 접속 |  |
| `lab_backup_user` | LOGIN | 백업 실행 |  |

로그인 역할과 권한 역할을 분리하는 장점:

```text
1.
2.
3.
```

### 멤버십과 권한 사용 가능성

| 멤버십 | MEMBER | USAGE | inherit_option | set_option | admin_option |
| --- | --- | --- | --- | --- | --- |
| report → readonly | true | true | true | true | false 기대 |
| app → enrollment | true | true | true | true | false 기대 |
| backup → backup_user | true | true | true | true | false 기대 |

`MEMBER`, `USAGE`, `INHERIT`, `SET`을 각각 확인해야 하는 이유:

```text
_______________________________________________________________
```

`rolinherit`만으로 membership별 설정을 모두 확인할 수 없는 이유:

```text
_______________________________________________________________
```

---

## 6. security_lab 구조·데이터·금액 의미

### 구조 검증

| 항목 | 기대 | 실제 | 통과 |
| --- | ---: | ---: | --- |
| 테이블 | 3 |  |  |
| 명시 제약조건 | 13 |  |  |
| NOT NULL 컬럼 | 14 |  |  |
| `recorded_amount` | `NUMERIC(12,0)` |  |  |
| 활성 부분 고유 인덱스 | valid / ready |  |  |
| 01 종료 시 행 수 | 0 / 0 / 0 |  |  |

### 샘플 데이터

| 테이블 | 기대 행 수 | 실제 행 수 | IDENTITY 다음 값 |
| --- | ---: | ---: | ---: |
| `security_lab.students` | 3 |  | 104 이상 |
| `security_lab.courses` | 3 |  | 204 이상 |
| `security_lab.enrollments` | 3 |  | 1004 이상 |
| JOIN 결과 | 3 |  | - |

| 상태 | 기대 건수 | 실제 |
| --- | ---: | ---: |
| 신청 | 1 |  |
| 수강중 | 1 |  |
| 완료 | 1 |  |
| 취소 | 0 |  |

```text
recorded_amount 합계 = 310000
활성 신청 = 2
활성 중복 = 0
recorded_amount와 course.price 불일치 = 0
```

`recorded_amount`의 의미를 한 문장으로 설명합니다.

```text
_______________________________________________________________
```

결제 승인액이나 회계 매출로 부르면 안 되는 이유:

```text
_______________________________________________________________
```

명시적 ID:

```text
students: 101, 102, 103
courses: 201, 202, 203
enrollments: 1001, 1002, 1003
```

### 무결성 규칙 찾기

| 규칙 | 구현 | 확인 |
| --- | --- | --- |
| 학생 이름 공백 금지 |  |  |
| 학생 이메일 공백 금지 |  |  |
| 정확 문자열 이메일 중복 금지 |  |  |
| 존재 학생·강의만 참조 |  |  |
| 음수 기록 금액 금지 |  |  |
| 상태 허용값 제한 |  |  |
| 활성 학생·강의 중복 금지 |  |  |

부분 고유 인덱스가 완료·취소 이력은 허용하면서 진행 중 중복만 차단하는 이유:

```text
_______________________________________________________________
```

---

## 7. 역할별 최소 권한 작업 행렬

| 객체·작업 | 보고 역할 | 앱 역할 | 백업 역할 | 근거 |
| --- | --- | --- | --- | --- |
| DB `CONNECT` | 허용 | 허용 | 허용 |  |
| schema `USAGE` | 허용 | 허용 | 허용 |  |
| students `SELECT` | 허용 | 허용 | 허용 |  |
| courses `SELECT` | 허용 | 허용 | 허용 |  |
| enrollments `SELECT` | 허용 | 허용 | 허용 |  |
| enrollments `INSERT` | 불허 | 허용 | 불허 |  |
| enrollments status `UPDATE` | 불허 | 허용 | 불허 |  |
| `recorded_amount UPDATE` | 불허 | 불허 | 불허 |  |
| enrollments `DELETE` | 불허 | 불허 | 불허 |  |
| schema `CREATE` | 불허 | 불허 | 불허 |  |
| enrollment sequence `USAGE` | 불허 | 허용 | 불필요 |  |
| 세 sequence `SELECT` | 불허 | 불허 | 허용 |  |

앱은 sequence `USAGE`만, 백업 역할은 sequence `SELECT`를 사용하는 이유:

```text
_______________________________________________________________
```

---

## 8. 유효 권한과 권한 경로

### 유효 권한 함수

| 역할·권한 | 기대 | 실제 | 통과 |
| --- | --- | --- | --- |
| 읽기 계정 DB CONNECT | true |  |  |
| 읽기 계정 schema USAGE | true |  |  |
| 읽기 계정 SELECT | true |  |  |
| 읽기 계정 INSERT | false |  |  |
| 앱 계정 INSERT | true |  |  |
| 앱 계정 전체 UPDATE | false |  |  |
| 앱 계정 status UPDATE | true |  |  |
| 앱 계정 recorded_amount UPDATE | false |  |  |
| 앱 계정 DELETE | false |  |  |
| 앱 계정 sequence USAGE | true |  |  |
| 앱 계정 sequence SELECT | false |  |  |
| 백업 계정 테이블 SELECT | true |  |  |
| 백업 계정 세 sequence SELECT | true |  |  |
| 백업 계정 INSERT | false |  |  |

### 권한 경로

| 경로 | 확인 대상 | 실제 상태 |
| --- | --- | --- |
| 직접 테이블 GRANT | `role_table_grants` |  |
| 직접 컬럼 GRANT | `role_column_grants` |  |
| PUBLIC 테이블 권한 | `table_privileges` |  |
| PUBLIC 컬럼 권한 | `column_privileges` |  |
| DB ACL | `pg_database.datacl` |  |
| 스키마 ACL | `pg_namespace.nspacl` |  |
| membership | `pg_auth_members` / `pg_has_role` |  |
| 객체 소유권 | `pg_class.relowner` |  |

`has_database_privilege(..., 'CONNECT') = true`만으로 직접 GRANT라고 단정할 수 없는 이유:

```text
_______________________________________________________________
```

PUBLIC 권한을 `role_table_grants`만으로 확인하면 안 되는 이유:

```text
_______________________________________________________________
```

---

## 9. RLS 상태 확인

| 테이블 | relrowsecurity 기대 | relforcerowsecurity 기대 | 실제 |
| --- | --- | --- | --- |
| students | false | false |  |
| courses | false | false |  |
| enrollments | false | false |  |

일반적인 전체 백업에서 RLS가 중요한 이유:

```text
_______________________________________________________________
```

`--enable-row-security`를 전체 백업과 같은 의미로 사용하면 안 되는 이유:

```text
_______________________________________________________________
```

---

## 10. 허용·차단 동작 테스트

`05_permission_behavior_tests.sql`의 결과를 기록합니다.

### 읽기 계정

| 작업 | 기대 | 실제 | 통과 |
| --- | --- | --- | --- |
| students SELECT | 성공 |  |  |
| courses SELECT | 성공 |  |  |
| enrollments SELECT | 성공 |  |  |
| enrollments INSERT | 실패 |  |  |
| status UPDATE | 실패 |  |  |
| DELETE | 실패 |  |  |

### 앱 계정

| 작업 | 기대 | 실제 | 통과 |
| --- | --- | --- | --- |
| SELECT | 성공 |  |  |
| ID 생략 INSERT | 성공 |  |  |
| status UPDATE | 성공 |  |  |
| recorded_amount UPDATE | 실패 |  |  |
| DELETE | 실패 |  |  |
| schema CREATE | 실패 |  |  |

허용 테스트 종료 후:

```text
students / courses / enrollments = 3 / 3 / 3
총 recorded_amount = 310000
활성 중복 = 0
```

테스트 데이터를 마지막에 `ROLLBACK`하는 이유:

```text
_______________________________________________________________
```

ROLLBACK 후에도 IDENTITY 번호 공백이 생길 수 있는 이유:

```text
_______________________________________________________________
```

---

## 11. 현재 객체와 미래 객체 권한

| 구분 | 적용 대상 | 객체 생성 역할 영향 | 기록 |
| --- | --- | --- | --- |
| `GRANT ON TABLE` | 현재 객체 |  |  |
| `ALTER DEFAULT PRIVILEGES` | 미래 객체 | 큼 |  |

Default Privileges에서 `FOR ROLE`이 중요한 이유:

```text
_______________________________________________________________
```

`pg_restore --no-privileges` 후에도 복원 역할의 Default Privileges를 확인해야 하는 이유:

```text
_______________________________________________________________
```

---

## 12. PUBLIC과 소유권

| 점검 항목 | 실제 상태 | 변경 필요 | 근거 |
| --- | --- | --- | --- |
| DB CONNECT to PUBLIC |  |  |  |
| security_lab USAGE to PUBLIC |  |  |  |
| security_lab CREATE to PUBLIC |  |  |  |
| 테이블 PUBLIC 권한 |  |  |  |
| schema owner |  |  |  |
| table·sequence owner |  |  |  |

무조건적인 `REVOKE ALL FROM PUBLIC`이 위험할 수 있는 이유:

```text
_______________________________________________________________
```

소유 역할을 삭제하기 전 필요한 절차:

```text
_______________________________________________________________
```

---

## 13. 비밀 정보와 저장소 보호

| 점검 항목 | 확인 |
| --- | --- |
| 실제 `.env`가 저장소에 없는가 |  |
| `.env.example`에 실제 값이 없는가 |  |
| `PGPASSWORD` 대신 `PGPASSFILE` 이름을 사용하는가 |  |
| 실제 password file이 저장소 밖에 있는가 |  |
| 실제 비밀번호·토큰이 SQL에 없는가 |  |
| 백업 파일이 프로젝트 밖에 있는가 |  |
| `.backup`, `.dump`, 압축 SQL이 ignore 대상인가 |  |
| 로그에 접속 URL·비밀번호가 없는가 |  |
| 노출 시 자격 증명 회전 절차가 있는가 |  |

노출이 발생했을 때 첫 조치:

```text
_______________________________________________________________
```

---

## 14. SQL Injection 방어

| 입력 종류 | 안전한 처리 | 이유 |
| --- | --- | --- |
| email 값 | 파라미터 바인딩 |  |
| 숫자 ID 값 | 파라미터 바인딩 |  |
| 정렬 컬럼 | 허용 목록 |  |
| 정렬 방향 | 허용 목록 |  |
| 테이블명 | 허용 목록 또는 서버 코드 고정 |  |

파라미터 바인딩과 허용 목록의 차이:

```text
_______________________________________________________________
```

최소 권한 계정이 Injection 피해 범위를 줄이는 이유:

```text
_______________________________________________________________
```

---

## 15. 백업 도구와 서버 버전

| 항목 | 값 | 판정 |
| --- | --- | --- |
| 원본 서버 버전 |  |  |
| 복원 서버 버전 |  |  |
| `pg_dump --version` |  |  |
| `pg_restore --version` |  |  |
| `psql --version` |  |  |

교재 자동 검증 기준:

```text
PostgreSQL 16
```

중단하거나 별도 호환성 검토가 필요한 조건:

```text
_______________________________________________________________
```

---

## 16. 백업 계정 최소 권한과 의존성

### 백업 계정

| 확인 항목 | 필요 | 실제 | 통과 |
| --- | --- | --- | --- |
| DB CONNECT | 필요 |  |  |
| security_lab USAGE | 필요 |  |  |
| 대상 테이블 SELECT | 필요 |  |  |
| 세 IDENTITY 시퀀스 SELECT | 이 실습에서 필요 |  |  |
| RLS 적용 여부 | 확인 |  |  |
| 백업 후 권한 처리 | 정책 |  |  |

### 스키마 외부 의존성

| 의존성 | 존재 여부 | 처리 계획 |
| --- | --- | --- |
| 다른 스키마 FK |  |  |
| 사용자 정의 타입 |  |  |
| 함수·트리거 |  |  |
| 확장 기능 |  |  |
| Large Object |  |  |
| 외부 테이블 |  |  |

현재 `security_lab`이 단독 복원 가능한 근거:

```text
_______________________________________________________________
```

---

## 17. custom archive 백업

실행 명령:

```bash
pg_dump \
  -U <backup_user> \
  -d ai_database_book \
  -Fc \
  --schema=security_lab \
  -f <backup-dir>/security_lab.backup
```

| 기록 | 값 |
| --- | --- |
| 실행 역할 |  |
| 종료 코드 |  |
| 경고·오류 |  |
| 파일 크기 |  |
| 생성 시각 |  |

custom archive에서 `pg_dump --no-owner`를 사용해 owner 메타데이터가 제거된다고 설명하면 안 되는 이유:

```text
_______________________________________________________________
```

archive에 owner·ACL 메타데이터를 보존하고 검증 복원에서 적용 여부를 결정하는 장점:

```text
_______________________________________________________________
```

---

## 18. archive 목록과 해시

```bash
pg_restore --list <backup-dir>/security_lab.backup
```

| 확인 항목 | 결과 |
| --- | --- |
| security_lab 스키마 |  |
| students |  |
| courses |  |
| enrollments |  |
| IDENTITY 시퀀스 3개 |  |
| sequence set |  |
| 제약조건 |  |
| 부분 고유 인덱스 |  |
| ACL 항목 |  |
| 예상하지 않은 객체 |  |

해시:

```text
알고리즘 = SHA-256
값 = __________________________________________________________
```

해시가 복원 성공을 증명하지 못하는 이유:

```text
_______________________________________________________________
```

---

## 19. 별도 복원 DB와 원자적 복원

복원 DB 생성:

```bash
createdb \
  -U <admin_user> \
  -O <restore_user> \
  -T template0 \
  ai_database_book_restore
```

custom archive 복원:

```bash
pg_restore \
  -U <restore_user> \
  -d ai_database_book_restore \
  --single-transaction \
  --no-owner \
  --no-privileges \
  <backup-dir>/security_lab.backup
```

| 옵션 | 의미 | 확인 |
| --- | --- | --- |
| `--single-transaction` | 작은 실습의 부분 복원 방지 |  |
| `--no-owner` | 원본 owner 적용 생략 |  |
| `--no-privileges` | 원본 ACL 적용 생략 |  |

복원 DB owner와 restore user를 맞추는 이유:

```text
_______________________________________________________________
```

`template0`를 사용하는 이유:

```text
_______________________________________________________________
```

대규모 운영 복원에서 single transaction을 그대로 적용하기 전에 검토할 사항:

```text
_______________________________________________________________
```

---

## 20. 복원 검증 1단계

`ai_database_book_restore`에서 `06_restore_validation.sql`을 실행합니다.

| 검증 | 기대 | 실제 | 통과 |
| --- | ---: | ---: | --- |
| 현재 DB | `ai_database_book_restore` |  |  |
| students | 3 |  |  |
| courses | 3 |  |  |
| enrollments | 3 |  |  |
| JOIN | 3 |  |  |
| 신청 / 수강중 / 완료 / 취소 | 1 / 1 / 1 / 0 |  |  |
| 총 recorded_amount | 310000 |  |  |
| recorded_amount 타입 | NUMERIC(12,0) |  |  |
| amount-course.price 불일치 | 0 |  |  |
| 고아 student FK | 0 |  |  |
| 고아 course FK | 0 |  |  |
| 활성 신청 중복 | 0 |  |  |
| NOT NULL | 14 |  |  |
| 명시 제약조건 | 13 |  |  |
| 부분 고유 인덱스 | valid / ready |  |  |
| IDENTITY 시퀀스 | 3 |  |  |
| 다음 자동값 | 현재 최대 ID보다 큼 |  |  |
| schema·table·sequence owner | restore user |  |  |

자동 성공 메시지:

```text
Chapter 11 restore structure and data validation passed
```

---

## 21. 복원 검증 2단계

역할·권한을 재적용한 뒤 기록합니다.

```text
03 역할 계획
→ 04 PUBLIC·ACL·membership·유효 권한
→ 05 실제 허용·차단 동작
```

| 역할 | SELECT | INSERT | status UPDATE | recorded_amount UPDATE | DELETE | schema CREATE |
| --- | --- | --- | --- | --- | --- | --- |
| readonly | 성공 | 실패 | 실패 | 실패 | 실패 | 실패 |
| enrollment app | 성공 | 성공 | 성공 | 실패 | 실패 | 실패 |
| backup | 성공 | 실패 | 실패 | 실패 | 실패 | 실패 |

백업 역할의 세 IDENTITY 시퀀스 SELECT:

```text
students_id_seq   = __________
courses_id_seq    = __________
enrollments_id_seq= __________
```

---

## 22. reset 원자성 확인

정상 reset:

```text
security_lab 삭제
course_project 5행 유지
Role은 삭제하지 않음
```

예상하지 못한 객체를 만든 뒤 reset을 실행하는 시험:

```sql
CREATE TABLE security_lab.keep_me (id INTEGER);
```

기대 결과:

```text
DROP SCHEMA 실패
앞에서 삭제하려던 students/courses/enrollments도 ROLLBACK
keep_me도 유지
CASCADE로 예상 밖 객체를 지우지 않음
```

실제 결과:

```text
_______________________________________________________________
```

---

## 23. RPO·RTO와 Runbook

| 기준 | 목표 | 실제 | 충족 | 개선안 |
| --- | --- | --- | --- | --- |
| RPO |  |  |  |  |
| RTO |  |  |  |  |

Runbook에 반드시 기록한 항목:

```text
[ ] 원본·복원 서버 버전
[ ] pg_dump·pg_restore·psql 버전
[ ] 백업 로그인·권한 역할
[ ] membership 옵션
[ ] RLS 상태
[ ] 외부 의존성
[ ] 백업 범위
[ ] archive 목록
[ ] SHA-256
[ ] 복원 DB owner/template
[ ] restore 옵션
[ ] 06 자동 검증 결과
[ ] 권한 재검증 결과
[ ] 오류·해결
[ ] RPO·RTO
[ ] 다음 복원 시험 날짜
```

---

## 24. AI 검토 활동

AI가 만든 보안·백업 명령에서 확인합니다.

| 항목 | 확인 |
| --- | --- |
| SUPERUSER·ALL PRIVILEGES를 관성적으로 쓰지 않는가 |  |
| 로그인 역할과 권한 역할을 분리하는가 |  |
| PostgreSQL 16 membership 옵션을 이해하는가 |  |
| recorded_amount 의미·권한이 맞는가 |  |
| 앱 sequence USAGE와 backup sequence SELECT를 구분하는가 |  |
| PUBLIC·ACL·소유권 경로를 확인하는가 |  |
| RLS 전체 백업과 visible-row dump를 구분하는가 |  |
| 스키마 외부 의존성을 확인하는가 |  |
| custom archive의 owner 메타데이터를 잘못 설명하지 않는가 |  |
| 원본 DB에 복원하지 않는가 |  |
| `pg_restore --no-owner --no-privileges`를 복원 단계에 두는가 |  |
| 실제 복원 검증을 포함하는가 |  |

가장 위험했던 AI 제안과 수정 내용:

```text
_______________________________________________________________
```

---

## 25. 최종 자기 점검

```text
[ ] Chapter 07·08 기준 상태를 확인했다.
[ ] security_lab은 3/3/3, 총 recorded_amount 310000이다.
[ ] recorded_amount는 NUMERIC(12,0)이며 결제 매출로 해석하지 않는다.
[ ] 13개 명시 제약조건과 NOT NULL 14개를 확인했다.
[ ] PostgreSQL 16 membership의 MEMBER·USAGE·INHERIT·SET을 구분했다.
[ ] readonly/app/backup 로그인 역할과 NOLOGIN 권한 역할을 분리했다.
[ ] 읽기·앱 계정의 허용·차단 동작을 확인했다.
[ ] 백업 역할의 table/sequence 읽기 권한을 확인했다.
[ ] RLS 상태를 확인했다.
[ ] 실제 비밀번호·백업 파일을 저장소에 두지 않았다.
[ ] custom archive의 owner·ACL 메타데이터와 restore 적용 옵션을 구분했다.
[ ] archive 목록과 SHA-256을 기록했다.
[ ] 별도 DB에 원자적으로 복원했다.
[ ] 06 자동 검증을 통과했다.
[ ] 역할·권한을 2단계에서 재검증했다.
[ ] reset의 정상 경로와 예상 객체 차단 원자성을 확인했다.
[ ] RPO·RTO와 다음 복원 시험 날짜를 기록했다.
```


## 최종 출판 보안 확인

```text
Unix password file 권한을 chmod 0600 수준으로 제한한 이유:
________________________________________________________________________

PGPASSWORD 대신 PGPASSFILE을 사용하는 이유:
________________________________________________________________________
```
