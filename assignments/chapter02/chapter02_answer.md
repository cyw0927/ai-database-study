# Chapter 02 확장 실습 답안

> **과제:** 데이터와 DBMS의 기본 개념  
> **GitHub 계정 또는 별칭:** cyw0927  
> **과제 작성일:** 2026-09-04  
> **사용한 AI 도구:** ChatGPT

> 실제 비밀번호, API Key, 전체 DB 접속 URL, 개인정보가 포함된 화면은 올리지 않습니다.

---

# 1. PostgreSQL에서 현재 위치 확인

## 1-1. 실행한 SQL

```sql
SELECT version();
SELECT current_database();
SELECT current_user;
SELECT current_schema();
SHOW search_path;
```

한 화면에서 보기 위해 다음 SQL도 실행했다.

```sql
SELECT
    version() AS version,
    current_database() AS current_database,
    current_user AS current_user,
    current_schema() AS current_schema,
    current_setting('search_path') AS search_path;
```

## 1-2. 실행 결과 기록

```text
PostgreSQL 버전: PostgreSQL 18.4 on x86_64-windows (64-bit)
현재 데이터베이스: postgres
현재 사용자: postgres
현재 스키마: public
search_path: public, "$user"
```

## 1-3. 구조를 내 말로 설명

```text
PostgreSQL은: 데이터를 저장하고 조회하며 관계와 제약조건을 관리하는 DBMS이다.

현재 접속한 데이터베이스는: PostgreSQL 서버가 관리하는 여러 데이터베이스 중 지금 내가 연결해서 사용하는 논리적 공간이다.

스키마는: 한 데이터베이스 안에서 테이블 같은 객체를 묶어서 구분하는 공간이다.

DBeaver 또는 psql 같은 도구는: PostgreSQL에 접속해서 SQL을 보내고 결과를 확인하는 클라이언트 도구이다.
```

### 확인 질문

```text
1. DBeaver를 종료하면 PostgreSQL 데이터가 사라지는가?
아니다. DBeaver는 접속 도구이고 실제 데이터는 PostgreSQL DBMS가 관리한다.

2. PostgreSQL과 현재 데이터베이스는 같은 것인가?
아니다. PostgreSQL은 DBMS이고 postgres는 현재 접속한 데이터베이스 이름이다.

3. public은 무엇인가?
public은 데이터베이스 이름이나 PostgreSQL 제품명이 아니라 스키마 이름이다.
```

## 1-4. 계층 구조 완성

```text
사용자
→ DBeaver / psql 같은 클라이언트
→ PostgreSQL DBMS
→ 데이터베이스
→ 스키마
→ 테이블
→ 행 / 열
```

## 1-5. 증거 화면

```markdown
![PostgreSQL 현재 위치 확인](./images/step01_environment.png)
```

> 현재 캡처 파일은 별도로 images 폴더에 추가할 예정이다.

---

# 2. 데이터베이스 안의 스키마와 테이블 관찰

## 2-1. 스키마 조회

```sql
SELECT schema_name
FROM information_schema.schemata
ORDER BY schema_name;
```

실행 후 확인할 대표 스키마 후보:

```text
1. information_schema
2. pg_catalog
3. public
```

### `public`은 무엇인가요?

```text
public은 현재 데이터베이스 안에 존재하는 스키마 중 하나이다.
테이블 이름 앞에 스키마를 생략했을 때 자주 사용되는 기본 스키마로 볼 수 있다.
```

### 데이터베이스와 스키마는 같은 것인가요?

```text
아니다. 하나의 데이터베이스 안에 여러 스키마가 있을 수 있다.
데이터베이스가 더 큰 논리적 공간이고 스키마는 그 안의 객체를 나누는 단위이다.
```

## 2-2. 현재 보이는 사용자 테이블 조회

```sql
SELECT table_schema, table_name
FROM information_schema.tables
WHERE table_type = 'BASE TABLE'
  AND table_schema NOT IN ('pg_catalog', 'information_schema')
ORDER BY table_schema, table_name;
```

```text
조회된 사용자 테이블 수 또는 눈에 띈 테이블: 실제 실행 결과 확인 예정

아직 테이블이 거의 없어도 괜찮은 이유:
PostgreSQL이 설치되었다고 수업용 테이블까지 자동으로 만들어지는 것은 아니기 때문이다.
```

## 2-3. 관찰 정리

```text
PostgreSQL 서버 안에는 여러 데이터베이스가 있을 수 있다.
한 데이터베이스 안에는 여러 스키마가 있을 수 있다.
스키마 안에는 테이블과 같은 객체가 존재한다.
```

---

# 3. TEMP TABLE로 테이블·행·열·키 직접 확인

## 3-1. 임시 테이블

실행할 SQL:

```sql
CREATE TEMP TABLE ch02_students (
    id INTEGER PRIMARY KEY,
    student_number TEXT UNIQUE NOT NULL,
    name TEXT NOT NULL,
    major TEXT
);

CREATE TEMP TABLE ch02_courses (
    id INTEGER PRIMARY KEY,
    course_code TEXT UNIQUE NOT NULL,
    title TEXT NOT NULL
);

CREATE TEMP TABLE ch02_enrollments (
    id INTEGER PRIMARY KEY,
    student_id INTEGER NOT NULL REFERENCES ch02_students(id),
    course_id INTEGER NOT NULL REFERENCES ch02_courses(id),
    status TEXT NOT NULL
);
```

- [ ] `ch02_students` 생성 확인
- [ ] `ch02_courses` 생성 확인
- [ ] `ch02_enrollments` 생성 확인

| 테이블 | 한 행의 의미 |
| --- | --- |
| `ch02_students` | 학생 한 명 |
| `ch02_courses` | 강의 한 개 |
| `ch02_enrollments` | 특정 학생이 특정 강의를 신청한 사건 한 건 |

## 3-2. 열의 의미 확인

### `ch02_students`

| 열 | 값의 의미 | 구분 |
| --- | --- | --- |
| `id` | DB 내부에서 학생 행을 구분하는 값 | 내부 식별자 / PK |
| `student_number` | 학교에서 사용하는 학번 | 업무 식별자 후보 |
| `name` | 학생 이름 | 일반 속성 |
| `major` | 학생 전공 | 일반 속성 |

### `ch02_enrollments`

| 열 | 값의 의미 | 구분 |
| --- | --- | --- |
| `id` | 수강신청 한 건을 구분하는 값 | PK |
| `student_id` | 어떤 학생의 신청인지 연결 | FK |
| `course_id` | 어떤 강의의 신청인지 연결 | FK |
| `status` | 신청, 수강중, 완료 등의 상태 | 일반 속성 |

## 3-3. 입력된 행 수

과제에서 주어진 데이터를 기준으로 예상되는 값:

```text
students 행 수: 3
courses 행 수: 2
enrollments 행 수: 3
```

## 3-4. 내부 식별자와 업무 식별자

```text
students.id가 필요한 이유:
DB 내부에서 학생 한 행을 안정적으로 구분하고 다른 테이블에서 참조하기 위해 필요하다.

student_number가 필요한 이유:
학교 업무에서는 학생을 학번으로 확인하는 경우가 많기 때문에 업무상 필요한 식별 정보이다.

둘을 항상 같은 값으로 사용하지 않아도 되는 이유:
학번 정책은 바뀔 수 있지만 내부 id는 DB 관계를 안정적으로 유지하는 용도로 사용할 수 있기 때문이다.
```

## 3-5. 숫자처럼 보이는 학번을 문자열로 저장한 이유

```text
학번은 더하거나 빼는 계산용 숫자가 아니다.
00123456처럼 앞의 0도 의미가 있으므로 숫자형으로 저장하면 앞자리 0이 사라질 수 있다.
그래서 문자열(TEXT)로 저장하는 것이 적절하다.
```

---

# 4. 테이블과 조회 결과는 다르다

## 4-1. 원본 테이블 행 수

```text
ch02_students 전체 행 수: 3
```

## 4-2. 일부 열만 조회

```sql
SELECT name, major
FROM ch02_students
ORDER BY id;
```

```text
원본 테이블의 열 수와 조회 결과의 열 수가 다른 이유:
SELECT에서 name과 major 두 열만 선택했기 때문이다.
id와 student_number가 조회 화면에 안 보인다고 원본 테이블에서 삭제된 것은 아니다.
```

## 4-3. 조건을 적용한 조회

```sql
SELECT id, student_number, name, major
FROM ch02_students
WHERE major = '컴퓨터공학'
ORDER BY id;
```

```text
원본 테이블 행 수: 3
조회 결과 행 수: 2
원본 테이블의 데이터가 삭제된 것인가?: 아니다.
그렇게 판단한 이유: WHERE 조건에 맞는 행만 조회 화면에 보여 준 것이기 때문이다.
```

## 4-4. 정렬 결과 비교

```sql
SELECT id, name
FROM ch02_students
ORDER BY name ASC;

SELECT id, name
FROM ch02_students
ORDER BY name DESC;
```

```text
ASC 결과의 첫 학생: 김민지로 예상되며 실제 실행 결과로 확인한다.
DESC 결과의 첫 학생: 이준호로 예상되며 실제 실행 결과로 확인한다.

이 실험을 통해 ORDER BY에 대해 알게 된 점:
조회 화면에 우연히 보이는 순서를 데이터의 고정 순서라고 생각하면 안 된다.
업무적으로 순서가 중요하면 ORDER BY로 기준을 직접 지정해야 한다.
```

## 4-5. 증거 화면

```markdown
![조회 결과 비교](./images/step04_result_set.png)
```

---

# 5. PK와 FK를 실제로 관찰

## 5-1. 정상 데이터의 관계 읽기

```text
한 행이 의미하는 것:
수강신청 한 건과 그 신청을 한 학생, 강의, 현재 상태를 연결해서 보여 준 결과이다.

같은 student_id가 여러 enrollment 행에서 반복될 수 있는 이유:
학생 한 명이 여러 강의를 신청할 수 있기 때문이다.

같은 course_id가 여러 enrollment 행에서 반복될 수 있는 이유:
강의 한 개에 여러 학생이 신청할 수 있기 때문이다.
```

## 5-2. 기본키 중복 오류 관찰

```sql
INSERT INTO ch02_students (id, student_number, name, major)
VALUES (1, '20269999', '새학생', '경영학');
```

```text
실행 성공 / 실패: 실패가 정상
오류 메시지에서 확인할 핵심 단어: duplicate key / primary key / unique constraint
왜 실패하는가: id=1은 이미 기존 학생 행에서 사용 중인 PK이기 때문이다.
```

## 5-3. 존재하지 않는 학생을 참조하는 FK 오류 관찰

```sql
INSERT INTO ch02_enrollments (id, student_id, course_id, status)
VALUES (1004, 999, 10, '신청');
```

```text
실행 성공 / 실패: 실패가 정상
오류 메시지에서 확인할 핵심 단어: foreign key / student_id / 참조 대상 없음
왜 실패하는가: students 테이블에 id=999인 학생이 없기 때문이다.
```

## 5-4. PK와 FK의 차이 정리

```text
PK는 같은 테이블 안에서 각 행을 고유하게 구분하기 위한 키이다.

FK는 다른 테이블의 행을 참조해서 테이블 사이의 관계를 연결하기 위한 키이다.

FK 값이 여러 행에서 반복될 수 있는 이유는
1:N 관계에서는 여러 자식 행이 같은 부모 행을 참조할 수 있기 때문이다.
```

## 5-5. 증거 화면

```markdown
![PK FK 오류 확인](./images/step05_pk_fk.png)
```

---

# 6. 관계와 카디널리티를 자연어로 설명

```text
학생 한 명은 여러 수강신청을 가질 수 있는가?: 예
강의 한 개는 여러 수강신청을 가질 수 있는가?: 예
수강신청 한 건은 학생 몇 명을 참조하는가?: 한 명
수강신청 한 건은 강의 몇 개를 참조하는가?: 한 개
```

```text
students 1 ── N enrollments N ── 1 courses
```

### 학생과 강의가 N:M 관계라고 볼 수 있는 이유

```text
학생 한 명이 여러 강의를 신청할 수 있고,
강의 한 개에도 여러 학생이 신청할 수 있기 때문이다.
이 N:M 관계를 enrollments 연결 테이블이 두 개의 1:N 관계로 나누어 표현한다.
```

---

# 7. AI가 만든 테이블 구조 직접 검토

## 7-1. AI에게 묻기 전에 내가 먼저 찾은 문제

```sql
CREATE TABLE student_courses (
    student_name VARCHAR(50),
    student_email VARCHAR(100),
    course_title VARCHAR(100),
    instructor_name VARCHAR(50)
);
```

```text
문제 1. 각 행을 확실하게 구분할 PK가 없다.
문제 2. 학생을 이름이나 이메일 문자열만으로 연결하면 변경이나 중복에 취약하다.
문제 3. 강의와 강사도 별도 식별자 없이 이름 문자열로만 저장하고 있다.
문제 4. 학생 정보, 강의 정보, 강사 정보, 수강 사건 정보가 한 테이블에 섞여 있다.
문제 5. 필수값, 중복 허용 여부, 참조 규칙 같은 제약조건을 알 수 없다.
```

## 7-2. AI 검토 요청 프롬프트

```text
나는 PostgreSQL과 데이터베이스를 처음 배우는 학생입니다.
다음 student_courses 테이블에서 한 행의 의미, PK 후보, 내부 식별자와 업무 식별자,
FK 관계 후보, 중복 저장 위험, 아직 결정할 수 없는 정책을 중심으로 검토해 주세요.
완성 설계를 대신 만들거나 요구사항이 없는 정책을 임의로 확정하지 마세요.
```

## 7-3. AI 제안과 나의 판단

| AI의 지적 또는 제안 | 동의 / 수정 / 보류 | 나의 근거 |
| --- | --- | --- |
| 행을 구분할 PK가 필요하다 | 동의 | 현재 구조에는 고유 식별자가 없다 |
| 학생과 강의를 별도 식별자로 구분할 필요가 있다 | 동의 | 이름은 바뀌거나 중복될 수 있다 |
| 수강 관계는 FK 후보로 표현할 수 있다 | 동의 | 학생과 강의 사이의 관계를 연결해야 한다 |
| 이메일은 무조건 PK로 사용한다 | 보류 | 이메일 변경 가능성과 고유 정책을 확인해야 한다 |
| 같은 학생의 같은 강의 재수강을 막는다 | 보류 | 업무 정책이 아직 정해지지 않았다 |

## 7-4. 본문과 대조한 항목

```text
AI가 설명한 내용: FK는 관계를 연결하는 값이며 여러 행에서 같은 값이 반복될 수 있다.

본문에서 확인한 내용: 1:N 관계에서는 여러 자식 행이 같은 부모의 PK를 FK로 참조할 수 있다.

일치 / 부분 일치 / 수정 필요: 일치

내가 최종적으로 이해한 내용:
PK는 자신의 행을 고유하게 구분하지만 FK는 다른 행과의 관계를 표현하므로 자동으로 UNIQUE일 필요가 없다.
```

## 7-5. 증거 화면

```markdown
![AI 구조 검토](./images/step07_ai_review.png)
```

---

# 8. Chapter 01의 개인 서비스 아이디어를 DB 용어로 다시 표현

## 8-1. 서비스 기본 정보

```text
서비스 이름: 개인 자산·지출 관리 서비스
서비스 목적: 사용자가 직접 수입과 지출을 기록하고 월별 수입, 지출, 예산 사용 현황을 확인하는 가계부형 서비스
```

## 8-2. PostgreSQL 구조 후보

```text
데이터베이스 이름 후보: ai_database_study
스키마 이름 후보: personal_finance
```

## 8-3. 테이블 후보와 한 행 의미

| 테이블 후보 | 한 행의 의미 | 내부 ID 후보 | 업무 식별자 후보 |
| --- | --- | --- | --- |
| `users` | 사용자 한 명 | `users.id` | 이메일 후보, 고유 여부는 확인 필요 |
| `expenses` | 지출 한 건 | `expenses.id` | 없음 또는 확인 필요 |
| `expense_categories` | 지출 카테고리 한 종류 | `expense_categories.id` | 카테고리명 후보, 중복 정책 확인 필요 |
| `incomes` | 수입 한 건 | `incomes.id` | 없음 또는 확인 필요 |
| `budgets` | 일정 기간의 예산 한 건 | `budgets.id` | 사용자+기간 조합 후보, 정책 확인 필요 |

## 8-4. FK 후보

```text
1. expenses.user_id → users.id
   이유: 어떤 사용자의 지출인지 연결하기 위해서

2. expenses.category_id → expense_categories.id
   이유: 지출 한 건이 어떤 카테고리에 속하는지 연결하기 위해서

3. incomes.user_id → users.id
   이유: 어떤 사용자의 수입인지 연결하기 위해서

4. budgets.user_id → users.id
   이유: 어떤 사용자가 설정한 예산인지 연결하기 위해서
```

## 8-5. 자연어 관계 문장

```text
1. 한 사용자는 여러 개의 지출 내역을 가질 수 있다.
2. 한 사용자는 여러 개의 수입 내역을 가질 수 있다.
3. 하나의 지출 카테고리는 여러 지출 내역에서 사용될 수 있다.
4. 한 사용자는 기간별로 여러 예산 기록을 가질 수 있다.
```

## 8-6. 아직 확정하지 않을 정책

```text
Q1. 사용자가 매달 예산 상한을 설정하고 초과 시 알림을 받을 것인가?
Q2. 지출 카테고리를 고정할 것인가, 사용자가 직접 추가·수정할 수 있게 할 것인가?
Q3. 삭제하거나 수정한 수입·지출 내역의 이전 기록을 보존할 것인가?
Q4. 이메일을 반드시 고유한 업무 식별자로 사용할 것인가?
```

---

# 9. AI를 개인 구조의 검토자로 사용

## 9-1. 사용한 프롬프트

```text
나는 데이터베이스 초보자이고 개인 자산·지출 관리 서비스를 만들고 있다.
테이블 후보는 users, expenses, expense_categories, incomes, budgets이다.
정답 설계를 대신 만들지 말고 각 테이블의 한 행 의미, 내부 ID와 업무 식별자,
PK/FK 역할, 빠진 관계, 아직 확인해야 하는 업무 정책을 질문 형태로 검토해 주세요.
근거 없이 정책을 확정하지 마세요.
```

## 9-2. AI가 질문한 내용 중 유용했던 것

```text
1. users가 반드시 필요한 다중 사용자 서비스인지, 개인 단독 사용 서비스인지 확인할 필요가 있다.
2. budgets는 월 전체 예산만 관리할지 카테고리별 예산도 관리할지 정해야 한다.
3. 삭제한 거래 기록을 완전히 삭제할지 이력을 남길지 정해야 한다.
```

## 9-3. AI가 너무 빨리 결정한 내용 또는 내가 보류한 내용

```text
1. 이메일을 무조건 UNIQUE 업무 식별자로 사용한다는 제안은 보류했다.
2. 카테고리별 예산까지 처음부터 구현하자는 제안은 프로젝트 범위를 고려해 보류했다.
```

## 9-4. 검토 후 수정한 구조

| 수정 전 | 수정 후 | 수정 이유 |
| --- | --- | --- |
| 사용자와 지출 관계만 자연어로 작성 | `expenses.user_id → users.id` FK 후보 추가 | 실제 DB 관계를 더 분명히 표현하기 위해 |
| 지출 카테고리만 데이터 후보로 작성 | `expenses.category_id → expense_categories.id` 추가 | 지출과 카테고리의 연결을 표현하기 위해 |
| 예산을 단순 숫자로 생각 | 기간별 예산 한 건으로 정의 | 한 행의 의미를 분명히 하기 위해 |

---

# 10. 최종 개념 정리

```text
PostgreSQL은 데이터를 저장하고 관계와 제약조건을 관리하며 SQL을 실행하는 DBMS이다.

DBeaver 또는 psql은 PostgreSQL에 접속해서 SQL을 보내고 결과를 확인하는 클라이언트 도구이다.

데이터베이스와 스키마의 차이는 데이터베이스가 더 큰 논리적 공간이고 스키마는 그 안의 객체를 나누는 단위라는 점이다.

테이블 한 행은 그 테이블에서 정의한 대상 또는 사건 한 건을 의미한다.

조회 결과가 원본 테이블과 다른 이유는 SELECT가 필요한 열, 행, 순서만 골라서 결과 집합을 만들기 때문이다.

내부 식별자와 업무 식별자의 차이는 내부 식별자는 DB 관계를 안정적으로 유지하기 위한 값이고 업무 식별자는 실제 업무에서 사용하는 번호나 코드라는 점이다.

PK는 같은 테이블 안에서 한 행을 고유하게 구분하는 키이다.

FK는 다른 테이블의 PK 등을 참조해서 테이블 사이의 관계를 연결하는 키이다.
```

---

# 11. 이번 Chapter에서 새롭게 알게 된 점

```text
1. PostgreSQL, 데이터베이스, 스키마, 테이블은 서로 같은 개념이 아니라 계층적으로 나뉜다는 것을 알게 되었다.
2. PK와 FK는 둘 다 키지만 PK는 자기 행을 구분하고 FK는 다른 행과 관계를 연결한다는 차이를 알게 되었다.
3. SELECT 결과는 원본 테이블 자체가 아니며 WHERE나 열 선택에 따라 일부만 보일 수 있다는 것을 알게 되었다.
4. 학번처럼 숫자로 보이는 값도 계산 목적이 아니고 앞자리 0을 보존해야 하면 문자열이 더 적절할 수 있다는 것을 알게 되었다.
```

## 아직 헷갈리는 내용

```text
1. 실제 서비스에서 자연키와 별도 내부 id 중 어떤 방식을 선택하는 것이 더 좋은지 아직 더 공부가 필요하다.
2. 삭제 정책이나 UNIQUE 제약조건을 실제 요구사항에서 어떤 기준으로 정해야 하는지 아직 헷갈린다.
```

## AI에게 다시 질문하고 싶은 내용

```text
실제 서비스에서 FK와 삭제 정책을 설계할 때 어떤 요구사항을 먼저 확인해야 하는가?
```

---

# 12. 제출 전 자기 점검

- [x] PostgreSQL에서 현재 database / schema / search_path를 확인했다.
- [x] DBMS, database, schema, table을 구분해서 설명할 수 있다.
- [ ] TEMP TABLE 3개를 생성하고 직접 데이터를 조회했다.
- [x] 각 테이블의 한 행 의미를 작성했다.
- [ ] 테이블과 조회 결과가 다르다는 것을 실제 SQL로 확인했다.
- [x] `ORDER BY`를 사용하지 않으면 업무 순서를 가정하면 안 된다는 점을 이해했다.
- [x] 내부 식별자와 업무 식별자의 차이를 설명할 수 있다.
- [ ] PK 중복 입력 실패를 직접 확인했다.
- [ ] 존재하지 않는 FK 참조 실패를 직접 확인했다.
- [x] FK 값이 반복될 수 있는 이유를 설명할 수 있다.
- [x] AI가 만든 테이블을 내가 먼저 검토했다.
- [x] AI 설명 중 최소 하나를 본문과 대조했다.
- [x] 개인 서비스의 테이블 후보를 3개 이상 작성했다.
- [x] 개인 서비스의 FK 후보와 미확정 정책을 기록했다.
- [x] 실제 비밀번호·API Key·민감한 접속 정보가 포함되지 않았는지 확인했다.
- [ ] 이미지 링크가 GitHub에서 정상적으로 보이는지 확인했다.

---

# 13. GitHub 제출 정보

```text
답안 파일:
assignments/chapter02/chapter02_answer.md

이미지 폴더:
assignments/chapter02/images/
```

내 LMS 제출 URL:

```text
https://github.com/cyw0927/ai-database-study/blob/main/assignments/chapter02/chapter02_answer.md
```

## 최종 확인

- [ ] 위 URL을 로그아웃 상태 또는 다른 브라우저에서 열어도 확인 가능하다.
- [x] Markdown 기본 구조를 작성했다.
- [ ] 이미지가 깨지지 않는다.
- [ ] LMS에 교수자 템플릿 URL이 아니라 내 답안 파일 URL을 제출했다.
