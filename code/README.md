# code/

이 폴더는 Chapter별 실습 코드를 관리합니다.

권장 구조:

```text
code/
├── chapter01/
├── chapter02/
├── chapter03/
└── ...
```

각 Chapter의 실습 코드는 해당 Chapter 번호 폴더에 저장합니다.

예시:

```text
code/chapter04/basic_crud.sql
code/chapter07/schema.sql
code/chapter07/seed.sql
code/chapter15/app/
```

원칙:

```text
- 본문 원고와 코드가 불일치하지 않도록 Chapter별로 함께 검토한다.
- SQL은 PostgreSQL 기준으로 작성한다.
- 웹 실습 코드는 초급자가 실행 가능한 최소 구조로 유지한다.
- 민감한 접속 정보는 코드에 직접 포함하지 않는다.
```
