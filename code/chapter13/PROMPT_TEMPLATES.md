# Chapter 13 AI 검토 프롬프트 템플릿

## 1. ERD·DDL 검토 요청

```text
다음 PostgreSQL 데이터베이스 설계를 요구사항 추적 방식으로 검토해 주세요.

업무 목표:
[저장할 데이터와 답해야 할 질문]

확인된 요구사항:
- [P13-R01]
- [P13-R02]
- [P13-R03]

결정·단순화·미확정 정책:
- [P13-D01]
- [P13-D02]
- [AI가 임의로 변경하면 안 되는 항목]

현재 구조:
- 데이터베이스:
- 스키마:
- 테이블:
- 제약조건·인덱스:
- 대표 행 수:
- IDENTITY 다음 값:

수정 범위:
- [대상 파일·스키마]

수정 금지:
- 다른 Chapter와 기존 프로젝트 스키마
- 실제 개인정보·비밀번호·토큰·접속 URL·카드번호
- 근거 없는 전체 UNIQUE·NOT NULL·CASCADE
- 승인되지 않은 DROP·ALTER·Role 변경

검토 결과:
1. P13 요구사항별 반영 위치
2. 결정과 충돌·누락·임의 가정
3. ERD 관계·카디널리티·선택성
4. 전체 UNIQUE와 부분 고유 인덱스 구분
5. 타입·PK·FK·UNIQUE·CHECK·NULL
6. IDENTITY·명시적 ID·RESTART
7. 결제·환불 시각과 부분 환불 범위
8. LEFT JOIN NULL 검증
9. 보안·권한·성능·복구 위험
10. 최소 수정안
11. 정상·경계값·반례·메타데이터·업무 검증
12. 추가 결정 항목
```

---

## 2. Codex 저장소 수정 요청

```text
현재 저장소의 code/chapter13 파일만 수정해 주세요.

목표:
- [재현된 문제]
- [기대 결과]

현재 기준:
- DB ai_database_book
- ai_review_lab 전용
- Chapter 07 enrollments 5행 유지
- Chapter 07 명명 제약조건 15개 / NOT NULL 열 20개 유지
- 01 생성 단계에서 현재 역할의 DB CREATE 권한 확인
- bad_enrollments 3행
- students 3행
- instructors 2행
- courses 3행
- enrollments 4행
- payments 4행
- 정상 JOIN 4행
- 정확한 FK 4개
- 좋은 설계 제약조건 29개
- IDENTITY id 6개
- 활성 신청 부분 고유 인덱스 존재
- 반례·경계값 30개 통과

수정 허용:
- [구체적인 파일 목록]

수정 금지:
- course_project
- transaction_lab
- performance_lab
- security_lab
- nosql_lab
- 다른 Chapter
- Role·권한
- 관련 없는 포맷 변경

검증:
1. current_database·current_schema·SHOW search_path
2. 실제 PostgreSQL 메타데이터와 정확한 객체 이름
3. 기준 행 수·JOIN·IDENTITY 다음 값
4. SQLSTATE와 constraint name
5. 정상 경계값 6개
6. 반례 24개
7. 업무 이상 조회 0행
8. 08 최종 자동 검증
9. 파일별 diff

완료 보고:
- 변경 파일
- 변경 이유
- commit
- 실제 실행 결과
- 미실행 항목
- 남은 가정
```

---

## 3. SQL 오류 분석 요청

```text
다음 PostgreSQL 오류를 분석해 주세요.

환경:
- 테스트 DB: ai_database_book
- 스키마: ai_review_lab
- 실행 파일:
- 실행 순서:
- 실행 전 행 수:

재현 SQL:
[최소 재현 SQL]

오류 증거:
- SQLSTATE:
- constraint name:
- table name:
- column name:
- 비밀과 개인정보를 제거한 오류 메시지:

기대 결과:
[행 수·오류 유형·제약조건·메타데이터]

조건:
- 오류와 직접 관련 없는 파일을 수정하지 않는다.
- P13-R01~P13-R09와 P13-D01~P13-D08을 유지한다.
- 파괴적 SQL을 추가하지 않는다.
- 수정 전 원인과 수정 후 검증 SQL을 제시한다.
- LEFT JOIN NULL 비교가 있으면 IS DISTINCT FROM 필요 여부를 확인한다.
```

---

## 4. 파괴적 마이그레이션 검토 요청

```text
다음 PostgreSQL 마이그레이션을 실행 전에 검토해 주세요.

변경:
[ALTER·DROP·UNIQUE·NOT NULL·타입 변경]

대상 환경:
[개발 / 테스트 / 운영]

현재 데이터:
- 행 수:
- NULL·중복·범위 위반 현황:
- 활성 상태 중복 현황:
- 의존 객체:
- 현재 인덱스:

검토:
1. 전체 UNIQUE와 부분 고유 인덱스 중 어떤 정책인가
2. 데이터 손실 가능성
3. 테이블 잠금과 서비스 중단 가능성
4. 기존 데이터 사전 검증 SQL
5. 단계적 적용 방법
6. 백업·롤백·복구 절차
7. 변경 후 메타데이터·업무 검증
8. 실행 중단 기준

금지:
- 원본 DB에 즉시 실행하는 지시
- 근거 없는 CASCADE
- 백업·복구 없는 파괴적 변경
- 미확정 정책을 DB 제약으로 고정
```

---

## 5. 결제·환불 모델 검토 요청

```text
다음 결제 모델을 검토해 주세요.

현재 단순화:
- enrollment 1 : 0..1 payment
- payment는 현재 상태 한 건
- paid_at은 결제 완료 시각
- refunded_at은 환불 완료 시각
- 샘플은 전액 결제·전액 환불
- 부분 결제·부분 환불 원장은 범위 밖
- 신청 상태는 결제 없이 존재 가능

검토:
1. 상태별 paid_at·refunded_at 규칙
2. 완료·취소 신청의 필수 결제 누락 검증
3. LEFT JOIN NULL 처리
4. 금액 의미와 부분 환불 한계
5. 결제 시도 이력 N건으로 확장할 때 변경점
6. 현재 모델에서 AI가 임의로 추가한 가정
7. 정상 경계값과 반례
```

---

## 6. AI 생성 인덱스 검토 요청

```text
다음 PostgreSQL 쿼리에 대한 인덱스 제안을 검토해 주세요.

테이블 행 수:
[행 수]

반복 쿼리:
[실제 SQL]

업무 규칙:
- 신청·수강중 활성 신청은 학생·강의당 한 건
- 완료·취소 이력은 보존

현재 인덱스:
[pg_indexes 결과]

전후 실행 계획:
[EXPLAIN (ANALYZE, BUFFERS)]

검토:
1. 기존 PK·UNIQUE와 중복 여부
2. 전체 UNIQUE와 부분 고유 인덱스의 업무 차이
3. 복합 인덱스 컬럼 순서 근거
4. 읽기 이점
5. INSERT·UPDATE·DELETE 비용
6. 동일 SQL 전후 비교
7. 적용·보류·제거 기준
```

---

## 7. 최종 승인 검토 요청

```text
다음 변경의 최종 승인 가능 여부를 검토해 주세요.

P13 요구사항 추적표:
[표]

P13 결정·미확정 정책:
[표]

변경 diff 요약:
[파일별 내용]

실행 증거:
- DB·스키마 보호:
- 기준 행·IDENTITY:
- 메타데이터 05:
- 업무 정합성 06:
- 반례·경계값 07:
- 최종 자동 검증 08:
- 보안·민감정보:
- 권한·성능·복구:

미실행 항목:
[항목]

다음 중 하나로 판단하고 근거를 작성하세요.
- 승인
- 조건부 승인
- 보류
- 거절

검증하지 않은 항목은 통과로 간주하지 마세요.
```
