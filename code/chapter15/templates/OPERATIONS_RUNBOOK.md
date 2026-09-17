# AI 튜터링 질문 관리 서비스 운영·복구 Runbook

## 1. 기본 정보와 목표

| 항목 | 기록 |
| --- | --- |
| 실행 환경 | 개발 / 테스트 / 운영 |
| 원본 DB | `ai_database_book` |
| 복원 DB | `tutor_project_restore` |
| 스키마 | `tutor_project` |
| 원본 PostgreSQL 버전 |  |
| 복원 PostgreSQL 버전 |  |
| `pg_dump` 버전 |  |
| `pg_restore` 버전 |  |
| `psql` 버전 |  |
| Python·pandas 버전 |  |
| 담당자·기록일 |  |
| RPO |  |
| RTO |  |

```bash
pg_dump --version
pg_restore --version
psql --version
```

```sql
SHOW server_version;
```

`pg_dump` 주요 버전이 원본 서버보다 오래되거나 복원 서버가 원본보다 오래된 주요 버전이면 호환성을 검토한 뒤 진행합니다.

---

## 2. 역할·권한 작업 행렬

| 역할 | CONNECT | schema USAGE | SELECT | INSERT | UPDATE | DELETE | schema CREATE |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `tutor_project_owner` NOLOGIN | 필요 | 필요 | 소유자 | 소유자 | 소유자 | 소유자 | 필요 |
| `tutor_project_app` NOLOGIN | 필요 | 필요 | 업무 범위 | 필요한 테이블 | 필요한 컬럼 | 원칙적 불허 | 불허 |
| `tutor_project_report` NOLOGIN | 필요 | 필요 | 분석 VIEW | 불허 | 불허 | 불허 | 불허 |
| `tutor_project_backup` NOLOGIN | 필요 | 필요 | 백업 대상 | 불허 | 불허 | 불허 | 불허 |

확인 항목:

```text
PUBLIC CONNECT·schema 권한
직접 GRANT와 역할 멤버십
객체 owner
IDENTITY 시퀀스 권한
최종 has_*_privilege 결과
실제 허용·차단 동작
```

`access_scope`는 자료의 업무 분류 값일 뿐 실제 접근 통제가 아닙니다. Role·VIEW·RLS 같은 별도 통제가 필요합니다.

---

## 3. 비밀·개인정보·파일 보호

| 점검 | 결과 |
| --- | --- |
| 실제 이름·이메일·전화번호 미사용 |  |
| 학생·튜터 이메일이 `example.test` |  |
| 자료 URL이 `example.test` 또는 NULL |  |
| 비밀번호·토큰·API 키 미포함 |  |
| 전체 접속 URL 미포함 |  |
| 실제 password file이 저장소 밖 |  |
| `.env`·백업·실제 CSV가 Git 제외 |  |
| 질문·답변 본문 로그 최소화 |  |
| 노출 자격 증명 회전 절차 |  |

Python은 `PGHOST`, `PGPORT`, `PGDATABASE`, `PGUSER`, `PGPASSFILE`을 사용하고 읽기 전용 트랜잭션으로 분석합니다.

---

## 4. 백업 계정과 외부 의존성

| 확인 | 결과 |
| --- | --- |
| DB CONNECT |  |
| schema USAGE |  |
| 대상 테이블·VIEW SELECT |  |
| 필요한 시퀀스 접근 |  |
| RLS 적용 여부 |  |
| 외부 스키마 FK |  |
| 사용자 정의 타입·함수·트리거 |  |
| 확장 기능·Large Object·외부 테이블 |  |

현재 교재 구조는 `tutor_project` 내부 FK만 사용합니다. 운영 변경 후에는 스키마 단독 덤프가 외부 의존성을 모두 포함한다고 가정하지 않습니다.

---

## 5. Custom-format 백업

```bash
pg_dump \
  -U <backup_user> \
  -d ai_database_book \
  -Fc \
  --schema=tutor_project \
  --no-owner \
  --no-privileges \
  -f <backup-dir>/tutor_project.backup
```

| 항목 | 기록 |
| --- | --- |
| 저장소 밖 경로 |  |
| 시작·완료 시각 |  |
| 종료 코드·경고 |  |
| 파일 크기 |  |
| SHA-256 |  |
| 접근 역할 |  |
| 보관 기간·삭제 절차 |  |

```bash
pg_restore --list <backup-dir>/tutor_project.backup
```

목록에서 6개 테이블, 5개 IDENTITY 시퀀스, 4개 VIEW, 제약조건과 업무 인덱스를 확인합니다. 해시는 파일 변경 여부의 근거이며 복원 가능성의 증거는 아닙니다.

---

## 6. 별도 DB 원자적 복원

기존 복원 DB를 자동 삭제하지 않습니다. 보존 필요 여부를 먼저 확인합니다.

```bash
createdb \
  -U <admin_user> \
  -O <restore_user> \
  -T template0 \
  tutor_project_restore
```

```bash
pg_restore \
  -U <restore_user> \
  -d tutor_project_restore \
  --single-transaction \
  --no-owner \
  --no-privileges \
  <backup-dir>/tutor_project.backup
```

작은 교재 실습은 전체 복원을 하나의 트랜잭션으로 처리합니다. 대규모 운영 복원에서는 긴 트랜잭션·잠금·자원 사용을 별도로 평가합니다.

Plain SQL 선택안:

```bash
psql \
  -X \
  -1 \
  -U <restore_user> \
  -d tutor_project_restore \
  -v ON_ERROR_STOP=1 \
  -f <backup-dir>/tutor_project.sql
```

---

## 7. 복원 검증

```bash
psql \
  -X \
  -U <restore_user> \
  -d tutor_project_restore \
  -v ON_ERROR_STOP=1 \
  -f 11_restore_validation.sql
```

| 검증 | 기대 | 실제 | 통과 |
| --- | ---: | ---: | --- |
| tables | 6 |  |  |
| views | 4 |  |  |
| sequences | 5 |  |  |
| students·tutors·questions | 4·3·5 |  |  |
| answers·materials·links | 5·6·7 |  |  |
| 제약조건·FK | 36·5 |  |  |
| 업무 인덱스 | 3 |  |  |
| 시간·관계 이상 | 0 |  |  |
| 질문 분석 VIEW | 5행 |  |  |
| 학생·튜터 요약 VIEW | 4·3행 |  |  |
| IDENTITY 다음 값 | 최대 ID보다 큼 |  |  |
| schema·table·sequence·view owner | `<restore_user>` |  |  |

`--no-privileges` 뒤에는 원본 ACL이 복원되지 않습니다. 필요한 역할·GRANT를 재적용한 뒤 `08_operations_checks.sql`과 실제 허용·차단 시험을 별도로 수행합니다.

---

## 8. 장애·복구와 분석 불일치

| 시나리오 | 탐지 | 대응 | 재검증 |
| --- | --- | --- | --- |
| 실수 DELETE |  |  |  |
| 스키마 변경 실패 |  |  |  |
| 백업 파일 손상 |  |  |  |
| 권한 오설정 |  |  |  |
| 분석 VIEW 정의 오류 |  |  |  |
| SQL·pandas 집계 불일치 |  |  |  |
| `.env`·password file 노출 |  |  |  |

SQL·Python 결과가 다르면 기대값을 바꾸기 전에 같은 읽기 전용 스냅샷, 분석 기간, VIEW 정의, 자료형과 집계 단위를 확인합니다.

---

## 9. 정기 점검과 최종 상태

| 항목 | 주기 | 담당 | 기준 |
| --- | --- | --- | --- |
| 백업 성공·해시 |  |  |  |
| 복원 시험 |  |  |  |
| 정합성·시간 관계 |  |  |  |
| PUBLIC·역할 권한 |  |  |  |
| 느린 쿼리·인덱스 |  |  |  |
| 분석 VIEW·SQL·pandas |  |  |  |
| 비밀·CSV·로그 저장 위치 |  |  |  |

다음 복원 시험 날짜: ____________________

```text
준비 완료 / 조건부 준비 / 보류 / 미준비
```

근거와 남은 조치:

```text
_______________________________________________________________
```
