# Chapter 11 확장 실습 답안

> **과제:** 데이터베이스를 안전하게 지키고 복구하는 방법
> **저장소:** cyw0927 / ai-database-study
> **작성일:** 2026-10-06
> **사용 도구:** Codex

## 먼저 적어 두기

이번 장에서 새로 알게 된 건 DB 접속과 테이블 권한이 같은 말은 아니라는 점이다. 백업도 파일을 만드는 것으로 끝나는 게 아니라, 다른 DB에 다시 넣어 봐야 확인이 된다고 한다.

아직 Chapter 11 SQL은 실행하지 않았다. 그래서 결과 표에는 실제로 확인한 값과 아직 안 해 본 값을 나눠 적었다. 실습을 마치면 DBeaver 결과와 캡처를 추가하면 된다.

Chapter 7 이후 개인 프로젝트는 하지 않았기 때문에 그 부분은 답안에 넣지 않았다.

---

# 1. 시작 환경과 Chapter 07·08 기준 상태 확인

Chapter 10 답안에 적어 둔 값을 옮겼다. Chapter 11에서 새로 접속해 확인한 값은 아니다.

| 확인 항목 | 기록 | 메모 |
| --- | --- | --- |
| PostgreSQL 서버 버전 | PostgreSQL 18.4 | Chapter 10 기록, 이번에 재확인 못함 |
| current_database() | ai_database_book | Chapter 10 기록 |
| current_user | postgres | Chapter 10 기록 |
| current_schema() | public | Chapter 10 기록 |
| search_path | "$user", public | Chapter 10 기록 |
| transaction_read_only | 미확인 | 이번에 확인 못함 |
| pg_dump / pg_restore / psql | PostgreSQL 18.4 | 컴퓨터의 명령 도구에서 확인 |

Chapter 10 답안에 기록된 Chapter 7·8 기준값입니다.

| 항목 | 앞서 확인한 값 |
| --- | ---: |
| students / instructors / courses / enrollments | 3 / 2 / 3 / 5 |
| 전체 recorded_amount | 590000 |
| 활성 신청 | 3건 / 340000 |
| 취소 제외 | 4건 / 440000 |
| id 1001 | 완료 / 100000 |
| id 1004 | 취소 / 150000 |
| id 1005 | 신청 / 120000 |

01 SQL도 이 값을 사전 검사합니다. 이번에는 실행하지 못했으므로 위 표는 Chapter 10 기록이고 이번 장 시작 직전에 다시 확인한 값은 아닙니다.

### 기존 course_project를 그대로 두고 security_lab을 쓰는 이유

처음에는 스키마를 하나 더 만드는 게 번거롭다고 생각했습니다. 그런데 권한 실습에서는 INSERT나 UPDATE를 일부러 시도할 수 있어서 원래 과제 데이터에서 하면 걱정됩니다. security_lab을 연습용으로 두고 course_project를 확인 기준으로 보존하면 실수해도 비교하기 쉽습니다.

> **중간 질문 — LLM에게 물어본 내용**
>
> “DB에 접속할 수 있는 계정이면 테이블도 다 수정할 수 있나요?”
>
> 접속 권한과 테이블 작업 권한은 별개라고 정리했습니다. 데이터베이스 CONNECT가 있어도 테이블별 SELECT, INSERT, UPDATE 권한은 제한할 수 있습니다.

---

# 2. 보호 대상과 위협 식별

개인 프로젝트 대신 수업에서 사용한 온라인 강의 DB를 기준으로 작성했습니다. 실제 사고가 있었다는 뜻은 아니고 생길 수 있는 실수를 적었습니다.

| 자산 | 예 | 위험 | 보호 방법 |
| --- | --- | --- | --- |
| 개인정보 | 학생 이름과 이메일 | 필요하지 않은 계정도 조회 | 조회 역할을 나누고 필요한 테이블에만 SELECT 허용 |
| 업무 데이터 | 신청 상태와 recorded_amount | 금액 변경 또는 행 삭제 | 필요한 INSERT와 제한된 상태 UPDATE만 허용 |
| DB 구조 | 테이블, 제약조건, 인덱스 | 실수로 변경·삭제 | 일반 계정의 ALTER, DROP, schema CREATE 차단 |
| 접속 비밀 | DB 비밀번호와 접속 정보 | GitHub나 캡처에 노출 | 저장소 밖 보관, 화면에서도 가림 |
| 로그 | 접속·오류 기록 | 접속 문자열이나 개인정보가 남음 | 로그 내용과 보관 범위 확인 |
| 백업 파일 | security_lab 데이터와 구조 | 파일 유출 또는 손상 | 저장소 밖 보관, 접근 제한, 해시와 복원 확인 |
| 복구 절차 | 별도 DB 생성과 복원 명령 | 원본에서 잘못 실행 | 대상 DB 이름 확인 후 별도 DB에서 검증 |

### 외부 공격 외에 운영 실수도 위험으로 보는 이유

처음에는 보안이라고 하면 외부 공격만 떠올렸습니다. DB 이름을 잘못 보고 원본에서 복원하거나 DELETE를 잘못 실행해도 데이터가 사라질 수 있습니다. 권한을 줄이고 원본과 실습 환경을 분리하는 것도 중요한 보안이라고 생각했습니다.

---

# 3. 최소 권한 작업 행렬

다음은 실제 계정을 만들었다는 뜻이 아니라 03 권한 계획을 읽고 정리한 내용입니다.

| 작업 | report reader | application user | backup user | owner/admin |
| --- | --- | --- | --- | --- |
| DB CONNECT | 허용 | 허용 | 허용 | 허용 |
| schema USAGE | 허용 | 허용 | 허용 | 허용 |
| SELECT | 허용 | 허용 | 허용 | 조건부 |
| INSERT | 차단 | 조건부 허용 | 차단 | 조건부 |
| UPDATE | 차단 | 조건부 허용 | 차단 | 조건부 |
| DELETE | 차단 | 차단 | 차단 | 조건부 |
| sequence USAGE | 차단 | 허용 | 차단 | 조건부 |
| sequence SELECT | 차단 | 차단 | 허용 | 조건부 |
| ALTER / DROP | 차단 | 차단 | 차단 | 조건부 |
| schema CREATE | 차단 | 차단 | 차단 | 조건부 |
| 권한 재부여 | 차단 | 차단 | 차단 | 조건부 |

앱 역할의 INSERT는 신청 행을 추가하는 경우입니다. UPDATE도 enrollments의 status 열만 바꾸도록 계획되어 있습니다. recorded_amount 수정, DELETE, 구조 변경은 허용하지 않습니다. 백업 역할은 데이터를 읽어도 운영 데이터를 수정할 이유는 없다고 보았습니다.

### 앱 로그인 계정을 객체 owner로 사용하면 위험한 이유

앱 계정이 테이블 주인이면 앱 오류가 구조 변경이나 삭제 권한을 가진 상태에서 실행될 수 있습니다. 앱에 필요한 일은 조회와 신청 상태 처리이므로 객체 관리 권한은 필요하지 않습니다. 로그인 역할과 객체 소유 역할을 분리하면 실수 범위를 줄일 수 있습니다.

### 앱 역할에 SUPERUSER, CREATEDB, CREATEROLE을 주지 않는 이유

신청 처리에 새 DB나 사용자를 만드는 권한은 필요하지 않습니다. SUPERUSER는 일반 권한 제한을 크게 우회하므로 앱 계정에 문제가 생기면 피해가 커질 수 있습니다. 기능에 필요한 권한만 주는 편이 맞습니다.

> **중간 질문 — LLM에게 물어본 내용**
>
> “앱이 INSERT를 해야 하니까 테이블 전체 권한을 줘도 될까요?”
>
> INSERT가 필요하다고 UPDATE, DELETE, ALTER까지 필요한 것은 아니라고 정리했습니다.

---

# 4. security_lab 생성과 기준 데이터 확인

실행 순서:

~~~text
code/chapter11/01_security_lab_schema.sql
code/chapter11/02_security_lab_seed.sql
~~~

아래 기대값은 SQL 파일에 적힌 기준이며 실제 실행값은 아닙니다.

| 항목 | 기대값 | 실제값 | 일치? |
| --- | ---: | --- | --- |
| students / courses / enrollments | 3 / 3 / 3 | 미실행 | 확인 필요 |
| JOIN 결과 | 3 | 미실행 | 확인 필요 |
| 신청/수강중/완료/취소 | 1/1/1/0 | 미실행 | 확인 필요 |
| recorded_amount 합계 | 310000 | 미실행 | 확인 필요 |
| 활성 신청 / 활성 중복 | 2 / 0 | 미실행 | 확인 필요 |

security_lab은 권한과 복원 테스트용이고 course_project는 이전 장 데이터 확인용이라고 나누어 생각했습니다. 이름으로 구분하면 어느 쪽을 바꾸는지 알기 쉽습니다.

**증거 화면:** 아직 실행 화면을 캡처하지 않았습니다. 실제 결과를 assignments/chapter11/images/step03_security_lab.png로 추가해야 합니다. 임의로 만든 이미지를 증거처럼 넣지는 않았습니다.

---

# 5. Role과 권한 계획 검토

검토 파일은 code/chapter11/03_role_permission_plan.sql입니다.

| 역할 | LOGIN/NOLOGIN | 목적 | 과도하게 주면 안 되는 권한 |
| --- | --- | --- | --- |
| lab_role_security_owner | NOLOGIN | 실습 객체 소유와 관리 권한 묶음 | SUPERUSER, 불필요한 클러스터 권한 |
| lab_role_report_reader | NOLOGIN | 조회 권한 묶음 | 쓰기와 구조 변경 |
| lab_role_enrollment_app | NOLOGIN | 앱 신청 처리 권한 | 금액 변경, 삭제, 구조 변경 |
| lab_role_backup_reader | NOLOGIN | 백업용 읽기 권한 | INSERT, UPDATE, DELETE |
| lab_readonly_user | LOGIN | 실제 조회 접속 계정 | 조회 외 변경 권한 |
| lab_enrollment_user | LOGIN | 실제 앱 접속 계정 | 전체 테이블·구조 관리 권한 |
| lab_backup_user | LOGIN | 실제 백업 접속 계정 | 데이터 변경과 객체 소유 권한 |

Role 변경 문장은 주석 처리되어 있습니다. DB 접속도 안 돼서 실행하지 않았습니다. Role은 DB 하나에만 속하지 않고 PostgreSQL 클러스터 전체에 영향을 준다고 해서 기존 Role 확인 없이 만들면 안 된다고 판단했습니다.

### 로그인 역할과 권한 역할을 분리하는 이유

로그인 계정마다 권한을 직접 붙이면 설정을 반복합니다. 권한 묶음 역할을 로그인 계정에 연결하면 접속 주체와 할 수 있는 일을 나누어 볼 수 있습니다. 처음에는 역할이 많아져 복잡해질 것 같았는데, 사용자가 늘면 정리하기 쉬워 보입니다.

### PostgreSQL 16 membership의 INHERIT, SET, ADMIN

~~~text
INHERIT: 멤버 역할의 권한을 자동으로 사용할 수 있는지에 관한 옵션
SET: SET ROLE로 해당 역할을 활성 역할로 바꿀 수 있는지에 관한 옵션
ADMIN: 멤버십을 다른 역할에 부여하거나 관리할 수 있는 권한
~~~

---

# 6. 현재 권한과 실제 유효 권한 확인

실행 파일은 code/chapter11/04_permission_checks.sql입니다.

~~~text
security_lab owner: 미확인 — SQL 미실행
PUBLIC 권한: 미확인 — SQL 미실행
report role SELECT: 미확인 — SQL 미실행
app role INSERT 및 UPDATE 범위: 미확인 — SQL 미실행
backup role SELECT와 sequence SELECT: 미확인 — SQL 미실행
schema CREATE와 RLS: 미확인 — SQL 미실행
~~~

직접 GRANT만 보고 최종 접근을 판단하면 안 되는 이유는 PUBLIC이나 멤버 역할을 통해 권한을 받을 수 있기 때문입니다. 객체 owner는 관리 권한을 갖기도 합니다. 여러 경로를 확인하고 실제 로그인 역할 기준의 유효 권한을 봐야 합니다.

---

# 7. 허용/차단 행동 검증

계획 파일은 code/chapter11/05_permission_behavior_tests.sql입니다. 아래는 예상 결과이며 실행값은 아닙니다.

| 역할 | 작업 | 예상 | 실제 | 이유 |
| --- | --- | --- | --- | --- |
| lab_readonly_user | 세 테이블 SELECT | 허용 | 미실행 | 조회 권한 계획 |
| lab_enrollment_user | INSERT 후 status UPDATE | 허용 | 미실행 | 신청 추가와 상태 변경 계획 |
| lab_readonly_user | enrollments INSERT | 차단 | 미실행 | 읽기 역할은 쓰기 불가 |
| lab_enrollment_user | recorded_amount UPDATE | 차단 | 미실행 | 앱은 금액을 수정하지 못함 |

성공 테스트는 ROLLBACK하도록 되어 있지만 IDENTITY 번호는 롤백 뒤에도 증가할 수 있다고 주석에 적혀 있습니다. 행 수와 금액이 기준으로 돌아와도 시퀀스 번호까지 원래 값이어야 한다고 검사하면 안 됩니다.

권한 표뿐 아니라 실제 테스트도 필요한 이유는 다른 경로로 권한을 받을 수 있고 필요한 권한이 빠졌을 수도 있기 때문입니다. 실패 테스트는 문장 하나씩 실행해야 해서 전체 스크립트를 한 번에 실행하면 안 됩니다. 실제 결과 화면은 아직 없어 step06_permission_test.png도 추가 전입니다.

---

# 8. 비밀정보와 저장소 점검

이번 답안에는 실제 비밀번호, 전체 접속 URL, API Key, password file 내용, 백업 파일을 넣지 않았습니다. 저장소 전체에 대한 비밀정보 검색은 하지 않았으므로 전체 점검 완료라고 쓰지는 않겠습니다.

### .env.example에는 무엇을 남기고 무엇을 남기지 않아야 하나요?

PGHOST, PGPORT, PGDATABASE, PGUSER, PGPASSFILE처럼 변수 이름과 가짜 예시만 둡니다. 실제 비밀번호는 넣지 않습니다. 실제 값을 넣는 .env 파일은 저장소에 커밋되지 않게 해야 합니다.

### PGPASSWORD 대신 보호된 password file을 검토하는 이유

비밀번호를 명령이나 문서에 적으면 터미널 기록이나 Git 기록에 남을 수 있습니다. password file을 저장소 밖의 접근 제한된 위치에 두면 노출 범위를 줄일 수 있습니다. 파일 위치와 OS 권한도 확인해야 합니다.

---

# 9. 백업 전 준비 확인

참고 문서는 code/chapter11/BACKUP_RESTORE_RUNBOOK.md입니다.

| 항목 | 기록 |
| --- | --- |
| 서버 버전 | PostgreSQL 18.4 — Chapter 10 기록, 이번에는 재확인 못함 |
| pg_dump / pg_restore / psql | PostgreSQL 18.4 |
| 백업 DB / 스키마 | ai_database_book / security_lab 계획 |
| 백업 형식 / 역할 | custom archive (-Fc) / lab_backup_user 계획 |
| RLS | 코드와 Runbook은 미사용이라고 설명. 실제 상태 미확인 |
| 외부 의존성 | 제공 DDL은 security_lab 내부 테이블 중심. 실제 카탈로그 확인 미실행 |

특정 스키마만 백업해도 외부 의존성이 자동으로 포함되는 것은 아닙니다. 다른 스키마의 타입·함수·extension, 외부 FK, 트리거 의존성을 확인해야 합니다. 제공 SQL은 security_lab 내부 테이블을 만들지만 실제 카탈로그는 확인하지 않았습니다.

---

# 10. custom archive 백업 생성

미실행입니다. DB 접속이 안 되어 백업 파일도 만들지 않았습니다.

~~~text
성공 여부 / 생성 시각 / 파일 크기: 미실행 / 해당 없음 / 해당 없음
경고·오류: 명령 미실행
archive 목록: 미확인
SHA-256: 백업 파일 미생성
~~~

해시는 파일이 달라지지 않았는지 확인하는 데 도움이 됩니다. 하지만 PostgreSQL이 파일을 복원할 수 있는지는 별도 문제입니다. 별도 DB에 복원한 다음 구조와 데이터를 확인해야 합니다.

실제 백업 화면은 없습니다. 실행 뒤 민감한 경로와 데이터를 가리고 파일 크기, 목록, SHA-256만 보이도록 step09_backup.png를 추가해야 합니다.

---

# 11. 별도 복원 DB 준비

복원 대상 예시는 ai_database_book_restore입니다. 이번에는 서버 접속이 안 되어 같은 이름의 DB가 있는지 확인하지 않았고 새 DB도 만들지 않았습니다. 기존 DB를 확인 없이 지우지도 않았습니다.

원본에 바로 복원하면 대상이나 옵션을 잘못 썼을 때 원본에 영향을 줄 수 있습니다. 별도 DB에서 시험하면 원본을 그대로 두고 비교할 수 있습니다.

---

# 12. custom archive 원자적 복원

복원 DB와 백업 파일이 없어 미실행입니다.

~~~text
--single-transaction: 복원을 하나의 트랜잭션으로 묶어 중간 오류 때 일부 객체만 남을 위험을 줄임
--no-owner: archive의 예전 소유자를 적용하지 않음. 복원 뒤 owner 확인 필요
--no-privileges: archive의 GRANT/REVOKE를 적용하지 않음. 권한 정책을 따로 적용하고 확인해야 함

실제 복원 결과: 미실행
~~~

no-owner와 no-privileges는 원래 소유자와 ACL을 그대로 적용하지 않도록 합니다. 복원 뒤 owner와 필요한 GRANT를 따로 확인해야 하므로 옵션만으로 권한 검증이 끝나지는 않습니다.

---

# 13. 복원 DB 구조·데이터·소유권 검증

다음 파일은 원본이 아닌 별도 복원 DB에서 실행합니다.

~~~text
code/chapter11/06_restore_validation.sql
~~~

| 검증 항목 | 기대값 | 실제값 |
| --- | ---: | --- |
| students / courses / enrollments | 3 / 3 / 3 | 미실행 |
| JOIN | 3 | 미실행 |
| 신청/수강중/완료/취소 | 1/1/1/0 | 미실행 |
| recorded_amount 합계 | 310000 | 미실행 |
| 고아 student/course FK | 0 / 0 | 미실행 |
| 활성 중복 | 0 | 미실행 |
| NOT NULL / 명시 제약조건 | 14 / 13 | 미실행 |
| IDENTITY 시퀀스 | 3 | 미실행 |
| NUMERIC(12,0), 다음 ID, owner | 기준에 맞음 | 미확인 |
| 최종 검증 메시지 | 통과 | 미실행 |

백업 파일이 생겼다는 것만으로는 다시 사용할 수 있는지 알 수 없습니다. 별도 DB에서 행 수, 관계, 제약조건, 시퀀스, 소유자를 확인해야 필요한 데이터가 돌아왔는지 알 수 있습니다. 이 단계는 실행하지 않았습니다. 실제 통과 후 DB 이름과 검증 메시지가 보이도록 step12_restore_validation.png를 추가해야 합니다.

---

# 14. 복원 후 권한 2단계 검증

~~~text
구조·데이터 검증: 미실행
권한 정책 재적용: 미실행
허용 동작 검증: 미실행
차단 동작 검증: 미실행
~~~

테이블과 데이터가 복원되어도 사용자가 할 수 있는 작업은 별도 문제입니다. no-privileges를 쓰면 권한 설정을 생략하므로 먼저 데이터 복원을 확인하고 그다음 권한을 적용해 테스트하는 순서가 이해하기 쉽다고 생각했습니다.

---

# 17. AI를 보안·복구 리뷰어로 활용

답안을 정리하면서 AI에게 계획 SQL과 Runbook을 같이 읽어 달라고 했다. 내가 궁금했던 건 원본 DB를 건드릴 위험이 있는지와 백업이 정말 복구되는지 확인하려면 뭘 더 해야 하는지였다. 아래 내용은 파일을 읽고 나눈 검토이고, DB에서 직접 시험한 결과는 아니다.

~~~text
내 질문:
Role과 복원 명령을 그대로 실행해도 될까? 실수할 수 있는 부분을 쉬운 말로 알려줘.
~~~

| 확인한 점 | 내가 내린 판단 | 이유 |
| --- | --- | --- |
| 기존 데이터와 실습 데이터를 나누기 | 수용 | course_project는 그대로 두고 security_lab에서 연습하는 게 안전해 보인다. |
| Role SQL 실행 | 보류 | Role은 DB 하나가 아니라 서버 전체에 생긴다고 해서, 먼저 기존 Role부터 확인해야 한다. |
| 백업 파일만 보고 복구 완료라고 하기 | 거절 | 파일 목록을 봐도 복원이 되는지는 모른다. 다른 DB에 복원해 봐야 한다. |
| 원본 DB에 바로 복원하기 | 거절 | 복원할 DB 이름을 잘못 쓰면 원본에 영향을 줄 수 있다. |
| 복원 뒤 권한 다시 확인하기 | 수용 | 권한을 빼고 복원했다면 필요한 권한을 다시 설정해야 한다. |

### AI가 위험한 명령을 제안하면

바로 실행하지 않고 어느 DB와 Role에 적용되는지 먼저 확인해야 한다. 특히 SUPERUSER나 DROP 같은 말이 있으면 왜 필요한지 더 살펴봐야겠다. 이번에는 DB 접속이 안 돼서 Role이나 복원 명령을 실제로 실행하지 않았다.

---
# 18. 최종 성찰

~~~text
1. 인증은 누가 접속했는지 확인하는 것이고, 권한 부여는 그 사람이 뭘 할 수 있는지 정하는 것이다.

2. 최소 권한은 필요한 일을 할 수 있을 만큼만 권한을 주는 것이다.

3. 백업 파일이 있어도 다른 DB에서 열리고 값이 맞는지 확인해야 복구 준비가 됐다고 할 수 있다.

4. 원본 말고 별도 DB에 복원하면 원래 데이터를 지키면서 시험할 수 있다.

5. AI가 준 명령도 어느 DB에 적용되는지와 데이터가 바뀌는지를 내가 확인해야 한다.
~~~

이번 답안은 계획을 읽고 쓴 부분이 많다. 실제로 SQL을 실행하고 결과를 보면 이 답을 더 고칠 수 있을 것 같다.

---
# 19. 제출 체크리스트

- [x] 답안 초안을 저장소에 만들었다.
- [ ] Chapter 11 연결에서 버전과 DB를 다시 확인했다.
- [x] 보호 자산과 위협을 작성했다.
- [x] 최소 권한 행렬을 작성했다.
- [ ] security_lab 기준 행 수와 합계를 실제 확인했다.
- [x] Role/권한 계획을 검토했다.
- [x] Role 변경을 실행하지 않았다.
- [ ] ACL/PUBLIC/membership/유효 권한을 확인했다.
- [ ] 허용·차단 행동을 실행했다.
- [x] 이 답안에 비밀번호·API Key·백업 파일을 넣지 않았다.
- [ ] custom archive와 SHA-256을 확인했다.
- [ ] 원본이 아닌 별도 DB에 복원했다.
- [ ] 복원 검증 SQL을 실행했다.
- [ ] 복원 후 권한을 별도로 검증했다.
- [x] 개인 프로젝트 작성 구간을 제외했다.
- [x] AI 제안에 대한 판단을 기록했다.
- [ ] 실제 증거 화면을 추가했다.
- [ ] GitHub에서 Markdown과 이미지를 확인했다.

---

# LMS 제출 URL

~~~text
https://github.com/cyw0927/ai-database-study/blob/main/assignments/chapter11/chapter11_answer.md
~~~

현재 파일은 실행 결과와 캡처가 빠진 초안이므로, 미완료 항목을 실제 DBeaver 결과로 채운 뒤 제출해야 합니다.
