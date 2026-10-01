# Chapter 08 확장 실습 답안

> **과제:** JOIN과 집계로 서비스 질문에 답하기  
> **제출 방법:** LMS에는 본인 GitHub 저장소의 `chapter08_answer.md` 파일 URL을 제출한다.

---

## 제출 전 주의

이 파일과 캡처 화면에는 실제 비밀번호, 전체 DB 접속 URL, API Key, 개인정보를 기록하지 않는다.

```text
GitHub 계정 또는 별칭: cyw0927
과제 작성일: 2026-09-17
사용한 AI 도구: ChatGPT, Claude
```

> 이 답안은 저장소의 Chapter 07 최종 데이터와 Chapter 08 검증 SQL을 기준으로 작성했다.  
> 모든 SQL은 로컬 PostgreSQL(`ai_database_book`)에 `psql`로 직접 접속하여 실행했고, 결과값이 예상과 모두 일치함을 확인했다(`00_check_course_project.sql`, `01_join_queries.sql`, `02_aggregation_queries.sql`, `03_join_aggregation_validation.sql` 전부 실행·검증 완료).  
> 다만 `step09_over_aggregation.png`, `step11_validation.png` 두 캡처는 DBeaver 화면으로 직접 남겨야 하는 증거이므로 로컬 DBeaver에서 실행 후 캡처하여 채워 넣는다.

---

# 1. Chapter 07 기준 상태 확인

다음을 실행한다.

```text
code/chapter08/00_check_course_project.sql
```

## 1-1. 사전 검사 결과

```text
검증 메시지: Chapter 08 prerequisite check passed (psql로 직접 실행하여 확인 완료)

students 행 수: 3
instructors 행 수: 2
courses 행 수: 3
enrollments 행 수: 5

전체 신청 건수: 5
전체 recorded_amount: 590000
활성 신청 건수: 3
활성 recorded_amount: 340000
취소 제외 신청 건수: 4
취소 제외 recorded_amount: 440000
```

기준값:

```text
students = 3
instructors = 2
courses = 3
enrollments = 5

전체 = 5 / 590000
활성 = 3 / 340000
취소 제외 = 4 / 440000
```

### 기준값이 다르면 그대로 진행하면 안 되는 이유

```text
이 장의 쿼리 결과는 7장에서 만든 데이터와 비교합니다. 시작할 때 데이터가 이미 다르면
쿼리가 틀린 건지 시작 데이터가 다른 건지 구분하기 어렵습니다. 그래서 먼저 7장 기준 숫자가
맞는지 확인한 다음 실습을 진행해야 한다고 이해했습니다.
```

### 증거 화면

권장 경로:

```text
assignments/chapter08/images/step01_prerequisite.png
```

---
![step01증거화면](images/step01_prerequisite.png)

# 2. 업무 질문을 SQL보다 먼저 정의하기

## 질문 A

```text
업무 질문: 수강신청 한 건마다 학생 이름과 강의 제목을 보여 주세요.
결과 한 행의 의미: 수강신청 한 건
포함 상태: 신청, 수강중, 완료, 취소 전체
제외 상태: 없음
JOIN할 테이블: enrollments, students, courses
JOIN 경로: enrollments.student_id = students.id, enrollments.course_id = courses.id
INNER JOIN / LEFT JOIN 선택: INNER JOIN
그 이유: 각 신청은 유효한 학생과 강의를 반드시 참조하는 구조이고, 신청 한 건을 기준으로 연결된 정보만 조회하면 되기 때문이다.
예상 행 수: 5행
```

## 질문 B

```text
업무 질문: 강의별 취소 제외 신청 수, 고유 학생 수, recorded_amount 합계를 보여 주세요.
결과 한 행의 의미: 강의 한 개
포함 상태: 신청, 수강중, 완료
제외 상태: 취소
JOIN할 테이블: courses, enrollments
JOIN 경로: courses.id = enrollments.course_id
집계 대상: COUNT(e.id), COUNT(DISTINCT e.student_id), SUM(e.recorded_amount)
예상 결과: 301 = 2건 / 2명 / 200000, 302 = 2건 / 2명 / 240000, 303 = 0건 / 0명 / 0
```

## 질문 C

```text
업무 질문: 학생별 취소 제외 신청 수를 보여 주되 신청이 0건인 학생도 표시해 주세요.
결과 한 행의 의미: 학생 한 명
포함 상태: 신청, 수강중, 완료
제외 상태: 취소
0건인 부모도 보여야 하는가: 예. 모든 학생이 결과에 남아야 한다.
NULL을 어떻게 해석할 것인가: 오른쪽 enrollments가 NULL이면 해당 학생에게 취소 제외 신청이 없다는 뜻이다.
예상 결과: 김민지 2건, 이준호 2건, 박서연 0건
```

---

# 3. INNER JOIN과 다중 JOIN

## 3-1. 신청 한 건마다 학생 이름과 강의 제목 조회

실행 전 예상:

```text
결과 한 행 = 수강신청 한 건
예상 행 수 = 5행
JOIN 경로 = enrollments.student_id → students.id, enrollments.course_id → courses.id
```

내가 실행할 SQL:

```sql
SELECT
    e.id AS enrollment_id,
    s.name AS student_name,
    c.title AS course_title,
    e.status
FROM course_project.enrollments AS e
INNER JOIN course_project.students AS s
    ON e.student_id = s.id
INNER JOIN course_project.courses AS c
    ON e.course_id = c.id
ORDER BY e.id;
```

실제 결과:

```text
실제 행 수: 5행 (psql로 직접 실행하여 확인 완료)
예상과 일치 여부: 일치함
```

### 학생 이름이 여러 번 보이는 것이 중복 오류가 아닐 수 있는 이유

```text
이 결과에서는 한 줄이 학생 한 명이 아니라 신청 한 건을 뜻합니다. 한 학생이 여러 강의를
신청하면 이름이 여러 번 나오는 게 맞습니다. 이름이 반복된다고 바로 중복이라고 생각해서
DISTINCT를 넣으면 실제 신청 기록을 빼버릴 수 있습니다.
```

## 3-2. 학생·강의·강사까지 연결

```text
결과 한 행 = 수강신청 한 건
강사까지 가는 JOIN 경로 = enrollments.course_id → courses.id → courses.instructor_id → instructors.id
```

```sql
SELECT
    e.id AS enrollment_id,
    s.name AS student_name,
    c.title AS course_title,
    i.name AS instructor_name
FROM course_project.enrollments AS e
JOIN course_project.students AS s
    ON e.student_id = s.id
JOIN course_project.courses AS c
    ON e.course_id = c.id
JOIN course_project.instructors AS i
    ON c.instructor_id = i.id
ORDER BY e.id;
```

실제 행 수:

```text
5행 (psql로 직접 실행하여 확인 완료: 문길래가 301·302, 홍길동이 303 담당)
```

### 왜 PK/FK 경로를 따라 JOIN해야 하는가?

```text
이름은 같은 사람이 있을 수도 있어서 이름끼리 연결하면 엉뚱한 데이터가 붙을 수 있습니다.
그래서 학생 번호나 강의 번호처럼 테이블 관계를 나타내는 키를 따라 연결했습니다.
이번에는 신청에서 강의를 찾고, 강의에서 담당 강사를 찾았습니다.
```

### 증거 화면

권장 경로:

```text
assignments/chapter08/images/step03_inner_join.png
```

![step03증거](images/step03_inner_join.png)

---

# 4. LEFT JOIN과 0건 표현

## 4-1. 강의별 취소 제외 신청 수

신청이 없는 강의도 결과에 남도록 작성한다.

실행 전:

```text
결과 한 행 = 강의 한 개
강의 303의 예상 실제 신청 수 = 0
강의 303의 예상 고유 학생 수 = 0
강의 303의 예상 recorded_amount = 0
```

내 SQL:

```sql
SELECT
    c.id AS course_id,
    c.title AS course_title,
    COUNT(e.id) AS non_cancelled_count,
    COUNT(DISTINCT e.student_id) AS student_count,
    COALESCE(SUM(e.recorded_amount), 0) AS non_cancelled_recorded_amount
FROM course_project.courses AS c
LEFT JOIN course_project.enrollments AS e
    ON c.id = e.course_id
   AND e.status <> '취소'
GROUP BY c.id, c.title
ORDER BY c.id;
```

실제 결과:

```text
강의 301: 2건 / 2명 / 200000 (psql로 직접 실행하여 확인 완료)
강의 302: 2건 / 2명 / 240000 (psql로 직접 실행하여 확인 완료)
강의 303: 0건 / 0명 / 0 (psql로 직접 실행하여 확인 완료)
```

## 4-2. `COUNT(*)`와 `COUNT(e.id)` 비교

강의 303을 기준으로 작성한다.

```text
COUNT(*) 결과: 1
COUNT(e.id) 결과: 0
COUNT(DISTINCT e.student_id) 결과: 0
```

### 왜 `COUNT(*) = 1`인데 실제 신청 수는 0일 수 있나요?

```text
강의 303에는 신청이 없지만 LEFT JOIN은 강의 행을 결과에 남깁니다. 이때 신청 쪽 칸은 비어
있지만 결과 행 자체는 하나 있습니다. 그래서 COUNT(*)는 1이 되고, 실제 신청 번호를 세는
COUNT(e.id)는 0이 됩니다.
```

### 자식 사건 수를 셀 때 `COUNT(child.id)`가 더 적절한 이유

```text
COUNT(e.id)는 신청 번호가 비어 있는 행을 세지 않습니다. 그래서 신청이 실제로 있는 경우만
세고 싶을 때 이 방법을 쓰는 게 맞다고 이해했습니다.
```

---

# 5. `LEFT JOIN`에서 `ON`과 `WHERE` 조건 비교

취소 제외 신청만 연결한다고 가정한다.

## 5-1. 조건을 `ON`에 둔 경우

```sql
SELECT
    s.id,
    s.name,
    COUNT(e.id) AS non_cancelled_count
FROM course_project.students AS s
LEFT JOIN course_project.enrollments AS e
    ON s.id = e.student_id
   AND e.status <> '취소'
GROUP BY s.id, s.name
ORDER BY s.id;
```

```text
결과 학생 수: 3명
박서연 포함 여부: 포함됨. 취소 제외 신청 수 0건으로 남음.
```

## 5-2. 조건을 `WHERE`에 둔 경우

```sql
SELECT
    s.id,
    s.name,
    COUNT(e.id) AS non_cancelled_count
FROM course_project.students AS s
LEFT JOIN course_project.enrollments AS e
    ON s.id = e.student_id
WHERE e.status <> '취소'
GROUP BY s.id, s.name
ORDER BY s.id;
```

```text
결과 학생 수: 2명
박서연 포함 여부: 제외됨.
```

## 5-3. 차이 설명

```text
ON에 조건을 두면 취소 신청을 연결하지 않으면서도 학생은 모두 결과에 남습니다. 그래서
신청이 없는 박서연도 0건으로 볼 수 있었습니다.

WHERE에 조건을 두면 JOIN이 끝난 다음 취소가 아닌 신청만 남깁니다. 신청이 없는 박서연은
비교할 신청 상태가 없어서 결과에서 빠집니다. 그래서 ON을 쓴 결과는 3명, WHERE를 쓴 결과는
2명이었습니다.
```

---

# 6. 신청이 없는 학생 찾기 — 두 방법 비교

## 방법 1. `LEFT JOIN ... IS NULL`

```sql
SELECT
    s.id,
    s.name,
    s.email
FROM course_project.students AS s
LEFT JOIN course_project.enrollments AS e
    ON s.id = e.student_id
   AND e.status <> '취소'
WHERE e.id IS NULL;
```

## 방법 2. `NOT EXISTS`

```sql
SELECT
    s.id,
    s.name,
    s.email
FROM course_project.students AS s
WHERE NOT EXISTS (
    SELECT 1
    FROM course_project.enrollments AS e
    WHERE e.student_id = s.id
      AND e.status <> '취소'
);
```

```text
방법 1 결과: 박서연 1명 (psql로 직접 실행하여 확인 완료)
방법 2 결과: 박서연 1명 (psql로 직접 실행하여 확인 완료)
두 결과가 같은가: 같음. 직접 실행하여 최종 확인함.
찾아진 학생: 박서연
```

### 두 방식의 공통 의미를 자신의 말로 설명

```text
두 쿼리는 쓰는 문법은 다르지만, 둘 다 취소가 아닌 신청이 없는 학생을 찾습니다.
직접 실행한 결과에서 두 방법 모두 박서연 한 명이 나왔습니다.
```

---

# 7. 기본 집계 검산

저장소의 `00_check_course_project.sql`과 `03_join_aggregation_validation.sql`이 아래 값을 검증하도록 작성되어 있다. 로컬 실행 후 실제 결과가 같은지 최종 확인한다.

| 분석 범위 | 예상 건수 | 실제 건수 | 예상 금액 | 실제 금액 | 일치? |
| --- | ---: | ---: | ---: | ---: | --- |
| 전체 신청 | 5 | 5 | 590000 | 590000 | 일치 |
| 활성 신청 | 3 | 3 | 340000 | 340000 | 일치 |
| 취소 제외 | 4 | 4 | 440000 | 440000 | 일치 |
| 취소 | 1 | 1 | 150000 | 150000 | 일치 |

> 위 값은 `psql`로 `00_check_course_project.sql`, `02_aggregation_queries.sql`을 직접 실행하여 확인했다.

## 7-1. 전체 평균 `recorded_amount`

```text
예상 평균: 118000.00
실제 평균: 118000.00 (psql로 직접 실행하여 확인 완료)
```

## 7-2. 취소 제외 평균

```text
예상 평균: 110000.00
실제 평균: 110000.00 (psql로 직접 실행하여 확인 완료)
```

### `recorded_amount`를 실제 회계 매출이라고 부르면 안 되는 이유

```text
recorded_amount는 수강신청이 생성된 시점에 신청 행에 기록한 금액이다.
현재 데이터 모델에는 실제 결제 승인, 결제 실패, 환불 같은 회계 사건이 저장되어 있지 않다.
따라서 recorded_amount 합계를 실제 결제 성공액이나 회계 매출이라고 해석하면 안 된다.
```

---

# 8. `GROUP BY`, `HAVING`, `FILTER`

## 8-1. 상태별 신청 건수

```sql
SELECT
    status,
    COUNT(*) AS enrollment_count,
    SUM(recorded_amount) AS total_recorded_amount
FROM course_project.enrollments
GROUP BY status
ORDER BY CASE status
    WHEN '신청' THEN 1
    WHEN '수강중' THEN 2
    WHEN '완료' THEN 3
    WHEN '취소' THEN 4
    ELSE 99
END;
```

결과:

```text
신청: 2건
수강중: 1건
완료: 1건
취소: 1건
상태별 합계: 5건
```

### 상태별 건수 합이 전체 신청 5건과 맞는지 검산

```text
2 + 1 + 1 + 1 = 5이므로 전체 enrollments 5건과 일치한다.
psql로 직접 실행한 결과 화면에서도 신청 2 / 수강중 1 / 완료 1 / 취소 1로 동일하게 확인했다.
```

## 8-2. 강의별 취소 제외 신청 수와 금액

```sql
SELECT
    c.id AS course_id,
    c.title AS course_title,
    COUNT(e.id) AS non_cancelled_count,
    COUNT(DISTINCT e.student_id) AS student_count,
    COALESCE(SUM(e.recorded_amount), 0) AS non_cancelled_recorded_amount
FROM course_project.courses AS c
LEFT JOIN course_project.enrollments AS e
    ON c.id = e.course_id
   AND e.status <> '취소'
GROUP BY c.id, c.title
ORDER BY c.id;
```

```text
강의 301: 2건 / 2명 / 200000
강의 302: 2건 / 2명 / 240000
강의 303: 0건 / 0명 / 0
강의별 합계를 다시 더한 값: 440000
전체 취소 제외 기준 440000과 일치 여부: 일치
```

## 8-3. `HAVING` 사용

취소 제외 신청이 2건 이상인 강의를 조회한다.

```sql
SELECT
    c.id,
    c.title,
    COUNT(e.id) AS enrollment_count
FROM course_project.courses AS c
JOIN course_project.enrollments AS e
    ON c.id = e.course_id
WHERE e.status <> '취소'
GROUP BY c.id, c.title
HAVING COUNT(e.id) >= 2
ORDER BY c.id;
```

```text
예상 강의 수: 2개
실제 강의 수: 2개 (psql로 직접 실행하여 확인 완료: 강의 301, 302)
```

### `WHERE`와 `HAVING`의 차이

```text
WHERE는 묶기 전에 각 행을 고르는 조건이고, HAVING은 묶은 다음 센 결과를 고르는 조건입니다.
이 쿼리는 취소 신청을 먼저 빼고 강의별로 센 뒤, 신청이 2건 이상인 강의만 표시했습니다.
```

---

# 9. 과대 집계 오류 직접 관찰

강사 201의 강의 가격 합계를 구한다고 가정한다.

## 9-1. 신청까지 JOIN해서 잘못 집계한 결과

```sql
SELECT
    i.id AS instructor_id,
    i.name AS instructor_name,
    SUM(c.price) AS wrong_course_price_sum
FROM course_project.instructors AS i
JOIN course_project.courses AS c
    ON i.id = c.instructor_id
JOIN course_project.enrollments AS e
    ON c.id = e.course_id
WHERE i.id = 201
GROUP BY i.id, i.name;
```

```text
강사 201 잘못된 가격 합계: 440000
```

## 9-2. 강의 수준에서 올바르게 집계

```sql
SELECT
    i.id AS instructor_id,
    i.name AS instructor_name,
    COALESCE(SUM(c.price), 0) AS course_price_sum
FROM course_project.instructors AS i
LEFT JOIN course_project.courses AS c
    ON i.id = c.instructor_id
WHERE i.id = 201
GROUP BY i.id, i.name;
```

```text
강사 201 올바른 가격 합계: 220000
```

## 9-3. 왜 두 결과가 달라졌나요?

```text
JOIN 전 강의 행 수: 강사 201의 강의는 301, 302 두 개이므로 2행
JOIN 후 강의가 반복된 이유: 강의 301에 신청 2건, 강의 302에 신청 2건이 연결되어 각 강의 행이 신청 수만큼 반복됨
SUM이 무엇을 반복해서 더했는가: 301의 가격 100000을 2번, 302의 가격 120000을 2번 더해서 440000이 됨
```

### `SUM(DISTINCT c.price)`를 일반적인 해결책으로 사용하면 안 되는 이유

```text
SUM(DISTINCT c.price)를 쓰면 강의가 아니라 가격이 같은지를 보고 하나를 빼버립니다.
서로 다른 강의의 가격이 우연히 같으면 한 강의 가격이 잘못 빠질 수 있습니다.
이번 질문은 강의 가격을 더하는 것이므로 신청 테이블을 연결하지 않고 강의만 더하는 편이 맞았습니다.
```

### 증거 화면

강사 201 기준으로 잘못된 합계(440,000)와 올바른 합계(220,000)를 각각 캡처했다.

```text
assignments/chapter08/images/step09a_wrong_aggregation.png
assignments/chapter08/images/step09b_correct_aggregation.png
```

![step09a증거화면 - 잘못된 합계 440000](images/step09a_wrong_aggregation.png)
![step09b증거화면 - 올바른 합계 220000](images/step09b_correct_aggregation.png)

---

# 10. 상세 결과 ↔ 집계 결과 교차 검산

강의 301을 선택한다.

```text
선택한 course_id: 301
강의 제목: 데이터베이스 입문
```

## 10-1. 상세 신청 행 조회

```sql
SELECT
    id,
    student_id,
    status,
    recorded_amount
FROM course_project.enrollments
WHERE course_id = 301
ORDER BY id;
```

```text
상세 행 수: 2행
상세 recorded_amount를 직접 더한 값: 100000 + 100000 = 200000
```

## 10-2. 집계 SQL

```sql
SELECT
    COUNT(*) AS enrollment_count,
    SUM(recorded_amount) AS total_recorded_amount
FROM course_project.enrollments
WHERE course_id = 301;
```

```text
집계 건수: 2
집계 금액: 200000
```

## 10-3. 비교

```text
상세 행 수와 COUNT 결과 일치 여부: 일치함. 2 = 2
상세 금액 합과 SUM 결과 일치 여부: 일치함. 200000 = 200000
다르다면 원인: JOIN 경로, 상태 조건, COUNT 대상, 중복 행, GROUP BY 수준을 다시 확인한다.
```

> 위 값은 psql로 직접 실행하여 최종 확인했다.

---

# 11. 자동 완료 게이트

다음을 실행한다.

```text
code/chapter08/03_join_aggregation_validation.sql
```

```text
최종 검증 메시지: Chapter 08 join and aggregation validation passed (psql로 직접 실행하여 확인 완료)
```

기대 메시지:

```text
Chapter 08 join and aggregation validation passed
```

### 자동 검증이 통과했어도 사람이 SQL 의미를 설명해야 하는 이유

```text
자동 검사는 준비된 데이터에서 정해 둔 숫자와 맞는지 확인해 줍니다. 하지만 질문을 잘못
이해했거나 금액을 잘못 더한 것까지 전부 알아서 알려 주지는 않습니다. 지금 데이터에서 맞아
보이는 쿼리도 다른 데이터에서는 틀릴 수 있습니다. 그래서 통과 메시지만 보지 말고 한 줄이
무엇을 뜻하는지와 어떤 행을 더했는지 직접 살펴봐야겠다고 생각했습니다.
```

### 증거 화면

권장 경로:

```text
assignments/chapter08/images/step11_validation.png
```

![step11증거화면](images/step11_validation.png)

---

# 12. 개인 프로젝트 업무 질문 3개 만들기

Chapter 07에서 작성한 개인 프로젝트를 사용한다.

| 질문 ID | 업무 질문 | 결과 한 행 | 포함/제외 범위 | JOIN 경로 | 집계 대상 | 검산 방법 |
| --- | --- | --- | --- | --- | --- | --- |
| P08-Q01 |  |  |  |  |  |  |
| P08-Q02 |  |  |  |  |  |  |
| P08-Q03 |  |  |  |  |  |  |

## 12-1. 질문 1 SQL

```sql

```

```text
예상 결과:
실제 결과:
검산 결과:
```

## 12-2. 질문 2 SQL

```sql

```

```text
예상 결과:
실제 결과:
검산 결과:
```

## 12-3. 질문 3 SQL

```sql

```

```text
예상 결과:
실제 결과:
검산 결과:
```

---

# 13. AI를 JOIN·집계 리뷰어로 활용

## 13-1. 내가 AI에게 전달한 질문

```text
제가 만든 SQL은 강의마다 취소를 뺀 신청 수와 금액 합계를 보여주려고 합니다.
신청이 하나도 없는 강의도 결과에 남아야 합니다.
테이블을 제대로 연결했는지, 신청이 없는 경우 숫자가 어떻게 나오는지 봐 주세요.
강의 가격이 여러 번 더해질 위험도 있는지 쉬운 말로 설명해 주세요.
SQL이 실행됐다는 이유만으로 맞다고 하지 말고, 결과가 제 질문에 맞는지도 봐 주세요.
```

## 13-2. 내 SQL과 AI SQL 비교

| 검토 항목 | 내 판단/SQL | AI 제안 | 최종 선택 | 이유 |
| --- | --- | --- | --- | --- |
| 검토할 내용 | 내가 생각한 것 | AI가 말한 것 | 판단 | 이유 |
| --- | --- | --- | --- | --- |
| 한 줄이 뜻하는 것 | 강의 하나 | 강의 하나로 표시 | 수용 | 강의별 결과를 보고 싶기 때문 |
| 어떤 신청을 셀지 | 취소는 빼기 | 취소 상태 제외 | 수용 | 취소되지 않은 신청만 세고 싶음 |
| 테이블 연결 | 강의 번호와 신청의 강의 번호를 연결 | 같은 방법 사용 | 수용 | 번호를 따라 연결해야 맞는 강의 신청을 찾을 수 있음 |
| 신청이 없는 강의 | 강의 303도 보여야 함 | LEFT JOIN 사용 | 수용 | 신청이 없어도 강의는 목록에 남겨야 함 |
| 신청 수 세기 | `COUNT(e.id)` | 같은 방법 사용 | 수용 | 신청이 없는 경우를 1건으로 세지 않기 위해 |
| 금액 중복 | 신청 행과 강의 가격을 구분 | 바로 JOIN해 더하면 가격이 반복될 수 있음 | 수용 | 직접 실행해 합계가 달라지는 것을 확인함 |
| 결과 확인 | 신청 목록과 합계 비교 | 301·302·303 각각 확인 | 수용 | 목록을 보고 직접 센 값과 비교할 수 있음 |

### AI가 만든 SQL에서 발견한 위험 또는 확인한 점

```text
AI 답을 읽다가 WHERE에 취소 제외 조건을 두면 신청이 없는 강의가 결과에서 빠질 수 있다는 점을
확인했습니다. COUNT(*)는 신청이 없어도 강의 행을 1건으로 셀 수 있었습니다. 그래서 이번에는
조건을 ON에 두고 COUNT(e.id)로 실제 신청만 셌습니다. COALESCE는 값이 비어 있을 때 0으로
보이게 해 주는 기능이지, 중복 계산을 고쳐 주는 기능은 아니라고 이해했습니다.
```

### AI SQL이 실행 성공했다고 바로 정답이라고 할 수 없는 이유

```text
SQL이 오류 없이 실행돼도 원하는 질문에 답하지 않을 수 있습니다. 신청 수를 세려던 건데
강의 정보를 반복해서 더할 수도 있습니다. 그래서 결과 숫자만 믿지 않고 원래 신청 목록과 비교해
계산이 맞는지 다시 확인해야 합니다.
```

---

# 14. 최종 성찰

```text
1. JOIN을 하기 전에 먼저 생각할 것은
   결과의 한 줄이 신청 한 건인지, 학생 한 명인지 정하는 것이다.

2. LEFT JOIN에서 COUNT(*) 대신 COUNT(child.id)를 쓰기도 하는 이유는
   신청이 없어도 강의가 한 줄 남을 수 있기 때문이다. COUNT(*)는 그 줄을 신청 1건으로 셀 수 있다.

3. ON과 WHERE의 위치가 중요한 이유는
   조건을 어디에 두느냐에 따라 신청이 없는 학생이나 강의가 결과에 남을 수도 있고 빠질 수도 있기 때문이다.

4. JOIN을 많이 한 다음 바로 SUM하면 조심해야 하는 이유는
   같은 강의가 신청 수만큼 반복되어 가격을 여러 번 더할 수 있기 때문이다.

5. 집계 숫자가 맞는지 확인하는 방법은
   상세 신청 목록도 조회해서 직접 센 숫자와 합계를 비교하는 것이다.
```

---

# 15. 제출 체크리스트

- [x] `chapter08_answer.md`를 본인 저장소에 만들었다.
- [x] `00_check_course_project.sql`이 통과했다. — psql로 직접 실행하여 확인 완료
- [x] 업무 질문마다 결과 한 행을 먼저 정의했다.
- [x] INNER JOIN과 다중 JOIN을 실행했다. — psql로 직접 실행하여 확인 완료
- [x] LEFT JOIN에서 0건 부모를 확인했다. — psql로 직접 실행하여 확인 완료
- [x] `COUNT(*)`와 `COUNT(child.id)` 차이를 설명했다.
- [x] ON과 WHERE 조건 위치 차이를 직접 실행해 비교했다.
- [x] `LEFT JOIN ... IS NULL`과 `NOT EXISTS`를 직접 실행해 비교했다.
- [x] 전체/활성/취소 제외 기준값을 직접 실행해 검산했다.
- [x] `GROUP BY`, `HAVING` SQL을 작성했다.
- [x] 과대 집계 오류와 수정 결과를 직접 실행해 비교했다.
- [x] 상세 결과와 집계 결과를 직접 실행해 교차 검산했다.
- [x] `03_join_aggregation_validation.sql`이 통과했다.
- [ ] 개인 프로젝트 업무 질문 3개를 작성했다. — 아직 미작성
- [x] AI SQL을 실행 성공 여부가 아니라 의미와 검산 관점에서 평가했다.
- [ ] 핵심 캡처는 3~4장 정도만 사용했다. — step09/step11 캡처 추가 필요
- [x] 비밀번호·개인정보·비밀정보가 없다.
- [ ] GitHub 웹에서 Markdown과 이미지가 정상적으로 보이는지 최종 확인했다.
- [ ] 최종 답안을 commit/push했다.

---

# 16. LMS 제출 URL

```text
https://github.com/cyw0927/ai-database-study/blob/main/assignments/chapter08/chapter08_answer.md
```

내 제출 URL:

```text
https://github.com/cyw0927/ai-database-study/blob/main/assignments/chapter08/chapter08_answer.md
```
