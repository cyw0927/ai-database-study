# AI Database Book — Student Lab Repository

이 저장소는 『AI와 함께 배우는 데이터베이스 입문』의 **학생용 실습 자료**를 관리합니다.

출판 원고, 발표 자료, 블로그 자료, 출판용 HTML/PDF 생성 스크립트와 제작 과정 문서는 별도의 publishing 저장소에서 관리합니다. 이 저장소에서는 수업과 자기주도 학습에 필요한 실습 코드와 워크북에 집중합니다.

## 시작하기

1. 이 저장소를 Clone합니다.
2. PostgreSQL과 DBeaver를 준비합니다.
3. 학습 중인 Chapter의 `code/chapterXX/` 폴더를 확인합니다.
4. README가 있는 경우 먼저 읽고 권장 순서대로 SQL 또는 Python 파일을 실행합니다.
5. `workbook/chapterXX.md`를 이용해 실습 결과를 확인하고 복습합니다.
6. Chapter 15에서 앞 Chapter의 내용을 종합한 프로젝트를 진행합니다.

## 폴더 구조

```text
ai-database-book/
├── README.md
├── .gitignore
├── .env.example
├── code/
│   ├── chapter01/
│   ├── chapter02/
│   ├── chapter03/
│   └── ...
└── workbook/
    ├── chapter01.md
    ├── chapter02.md
    ├── chapter03.md
    └── ...
```

## `code/`

Chapter별로 직접 실행할 SQL, Python, 프로젝트 실습 파일을 제공합니다.

- SQL 실습은 PostgreSQL을 기준으로 합니다.
- 각 Chapter의 `README.md`가 있다면 먼저 확인하세요.
- 번호가 붙은 파일은 특별한 안내가 없는 한 번호 순서대로 실행하는 것을 권장합니다.
- `reset_*.sql`, `verify_*.sql`, `*_validation.sql` 등은 실습 초기화와 결과 검증에 사용합니다.
- Chapter 14에는 PostgreSQL과 Python/pandas를 연결하는 분석 실습이 포함됩니다.
- Chapter 15에는 종합 프로젝트용 SQL, Python, 보고서 템플릿이 포함됩니다.

## `workbook/`

책의 각 Chapter를 읽은 뒤 직접 생각하고 확인하고 기록하는 **학생용 학습 활동 자료**입니다.

각 워크북에는 다음과 같은 활동이 포함될 수 있습니다.

- 핵심 활동: 해당 Chapter에서 반드시 확인할 내용
- 선택 활동: 필요에 따라 추가로 적용해 보는 내용
- 심화 활동: 개념을 실제 서비스와 운영 관점까지 확장하는 내용

처음 학습할 때는 핵심 활동을 우선 진행하고, 선택·심화 활동은 학습 속도에 맞게 추가하면 됩니다.

## 권장 학습 흐름

```text
책 본문 읽기
→ code/chapterXX 실습 실행
→ 실행 결과 확인
→ workbook/chapterXX.md 작성·복습
→ 다음 Chapter 진행
```

## 실습할 때 주의할 점

- SQL을 실행하기 전에 **현재 연결된 데이터베이스와 스키마**를 확인하세요.
- `UPDATE`, `DELETE`, `DROP`과 같은 변경 명령은 대상 테이블과 조건을 먼저 확인하세요.
- `.env.example`은 로컬 환경 변수 작성 예시입니다. 필요한 경우 `.env` 파일을 별도로 만들어 사용하세요.
- 실제 비밀번호, API Key, 개인정보와 같은 민감한 값은 Git에 커밋하지 마세요.
- 실습 결과가 예상과 다르면 바로 다음 단계로 넘어가지 말고 Chapter의 검증 SQL과 README를 먼저 확인하세요.

## Chapter 15 종합 프로젝트

Chapter 15는 앞에서 배운 데이터 모델링, SQL, 무결성, 트랜잭션, 성능, 보안·복구, AI 검증과 데이터 분석 내용을 하나의 프로젝트로 연결하는 단계입니다.

`code/chapter15/templates/`의 자료를 복사해 프로젝트 요구사항에 맞게 수정하면서 진행하는 것을 권장합니다.

---

이 저장소의 목표는 완성된 답을 제공하는 것이 아니라, **직접 실행하고 검증하면서 데이터베이스를 이해할 수 있도록 돕는 것**입니다.
