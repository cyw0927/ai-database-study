"""Shared read-only PostgreSQL and DataFrame validation for Chapter 15."""

from __future__ import annotations

import os
from contextlib import contextmanager
from typing import Iterator

import pandas as pd
from dotenv import load_dotenv
from sqlalchemy import URL, Connection, Engine, create_engine, text

EXPECTED_DATABASE = "ai_database_book"
EXPECTED_ROWS = 5
EXPECTED_COLUMNS = [
    "question_id",
    "question_code",
    "question_created_at",
    "question_month",
    "student_id",
    "student_name",
    "status",
    "answer_count",
    "first_answer_at",
    "first_response_hours",
    "material_count",
    "has_answer",
    "has_material",
]
ALLOWED_STATUSES = {"open", "answered", "closed"}

QUESTION_DATASET_SQL = """
SELECT *
FROM tutor_project.question_analysis_dataset
ORDER BY question_id
"""

STUDENTS_SQL = """
SELECT id AS student_id, name AS student_name
FROM tutor_project.students
ORDER BY id
"""

QUESTIONS_SQL = """
SELECT id AS question_id, student_id, status, created_at AS question_created_at
FROM tutor_project.questions
CROSS JOIN tutor_project.analysis_parameters AS p
WHERE created_at >= p.start_at
  AND created_at < p.end_at_exclusive
ORDER BY id
"""

TUTORS_SQL = """
SELECT id AS tutor_id, name AS tutor_name
FROM tutor_project.tutors
ORDER BY id
"""

ANSWERS_SQL = """
SELECT id AS answer_id, question_id, tutor_id, created_at AS answer_created_at
FROM tutor_project.answers
CROSS JOIN tutor_project.analysis_parameters AS p
WHERE created_at >= p.start_at
  AND created_at < p.end_at_exclusive
ORDER BY id
"""

PARAMETERS_SQL = """
SELECT start_at, end_at_exclusive
FROM tutor_project.analysis_parameters
"""

STATUS_SUMMARY_SQL = """
SELECT status, COUNT(*)::bigint AS question_count
FROM tutor_project.question_analysis_dataset
GROUP BY status
ORDER BY status
"""

MONTHLY_SUMMARY_SQL = """
WITH params AS (
    SELECT start_at, end_at_exclusive
    FROM tutor_project.analysis_parameters
), months AS (
    SELECT generate_series(
        DATE_TRUNC('month', start_at AT TIME ZONE 'Asia/Seoul')::date,
        (DATE_TRUNC('month', end_at_exclusive AT TIME ZONE 'Asia/Seoul') - INTERVAL '1 month')::date,
        INTERVAL '1 month'
    )::date AS question_month
    FROM params
), monthly AS (
    SELECT
        question_month,
        COUNT(*)::bigint AS question_count,
        SUM(answer_count)::bigint AS answer_count,
        SUM(material_count)::bigint AS material_count
    FROM tutor_project.question_analysis_dataset
    GROUP BY question_month
)
SELECT
    m.question_month,
    COALESCE(a.question_count, 0)::bigint AS question_count,
    COALESCE(a.answer_count, 0)::bigint AS answer_count,
    COALESCE(a.material_count, 0)::bigint AS material_count
FROM months AS m
LEFT JOIN monthly AS a ON a.question_month = m.question_month
ORDER BY m.question_month
"""

STUDENT_SUMMARY_SQL = """
SELECT student_id, student_name, question_count::bigint AS question_count
FROM tutor_project.student_question_summary
ORDER BY student_id
"""

TUTOR_SUMMARY_SQL = """
SELECT tutor_id, tutor_name, answer_count::bigint AS answer_count
FROM tutor_project.tutor_answer_summary
ORDER BY tutor_id
"""

RESPONSE_SUMMARY_SQL = """
SELECT
    COUNT(*) FILTER (WHERE has_answer)::bigint AS answered_questions,
    ROUND(AVG(first_response_hours) FILTER (WHERE has_answer), 2) AS avg_first_response_hours,
    MIN(first_response_hours) FILTER (WHERE has_answer) AS min_first_response_hours,
    MAX(first_response_hours) FILTER (WHERE has_answer) AS max_first_response_hours
FROM tutor_project.question_analysis_dataset
"""


def _required_env(name: str) -> str:
    value = os.getenv(name, "").strip()
    if not value:
        raise RuntimeError(f"{name} 환경변수가 없습니다. .env.example을 확인하세요.")
    return value


def create_read_only_engine() -> Engine:
    """Create a password-free SQLAlchemy URL; libpq reads PGPASSFILE externally."""
    load_dotenv()
    host = _required_env("PGHOST")
    port_text = _required_env("PGPORT")
    database = _required_env("PGDATABASE")
    user = _required_env("PGUSER")
    _required_env("PGPASSFILE")

    if database != EXPECTED_DATABASE:
        raise RuntimeError(
            f"PGDATABASE는 {EXPECTED_DATABASE}여야 하지만 현재 값은 {database}입니다."
        )

    try:
        port = int(port_text)
    except ValueError as exc:
        raise RuntimeError("PGPORT는 정수여야 합니다.") from exc

    url = URL.create(
        "postgresql+psycopg",
        username=user,
        host=host,
        port=port,
        database=database,
    )
    return create_engine(url, pool_pre_ping=True)


@contextmanager
def read_only_snapshot() -> Iterator[Connection]:
    """Yield one REPEATABLE READ, READ ONLY snapshot and verify location."""
    engine = create_read_only_engine()
    try:
        with engine.connect() as connection:
            transaction = connection.begin()
            try:
                connection.execute(
                    text("SET TRANSACTION ISOLATION LEVEL REPEATABLE READ, READ ONLY")
                )
                state = connection.execute(
                    text(
                        """
                        SELECT
                            current_database() AS database_name,
                            current_user AS user_name,
                            current_setting('transaction_read_only') AS read_only,
                            to_regclass('tutor_project.question_analysis_dataset') IS NOT NULL
                                AS analysis_view_exists
                        """
                    )
                ).mappings().one()

                if state["database_name"] != EXPECTED_DATABASE:
                    raise RuntimeError(
                        f"잘못된 DB 연결: {state['database_name']}"
                    )
                if state["read_only"] != "on":
                    raise RuntimeError("분석 트랜잭션이 읽기 전용이 아닙니다.")
                if not state["analysis_view_exists"]:
                    raise RuntimeError(
                        "tutor_project.question_analysis_dataset VIEW가 없습니다."
                    )

                yield connection
            finally:
                transaction.rollback()
    finally:
        engine.dispose()


def read_dataframe(connection: Connection, sql: str) -> pd.DataFrame:
    return pd.read_sql_query(text(sql), connection)


def normalize_question_dataset(dataframe: pd.DataFrame) -> pd.DataFrame:
    """Validate exact columns, types, row unit, status and derived fields."""
    actual_columns = list(dataframe.columns)
    if actual_columns != EXPECTED_COLUMNS:
        raise ValueError(
            "분석 VIEW 컬럼이 기대와 다릅니다. "
            f"expected={EXPECTED_COLUMNS}, actual={actual_columns}"
        )

    frame = dataframe.copy()
    frame["question_created_at"] = pd.to_datetime(
        frame["question_created_at"], errors="raise", utc=True
    )
    frame["question_month"] = pd.to_datetime(
        frame["question_month"], errors="raise"
    ).dt.normalize()
    frame["first_answer_at"] = pd.to_datetime(
        frame["first_answer_at"], errors="raise", utc=True
    )

    for column in ["question_id", "student_id", "answer_count", "material_count"]:
        frame[column] = pd.to_numeric(frame[column], errors="raise")

    frame["first_response_hours"] = pd.to_numeric(
        frame["first_response_hours"], errors="raise"
    )

    for column in ["has_answer", "has_material"]:
        if not pd.api.types.is_bool_dtype(frame[column]):
            values = set(frame[column].dropna().unique().tolist())
            if not values.issubset({True, False}):
                raise ValueError(f"{column}은 boolean이어야 합니다: {values}")
            frame[column] = frame[column].astype("boolean")
        if frame[column].isna().any():
            raise ValueError(f"{column}에 NULL이 있습니다.")
        frame[column] = frame[column].astype(bool)

    if len(frame) != EXPECTED_ROWS:
        raise ValueError(f"기대 행 수 {EXPECTED_ROWS}, 실제 {len(frame)}")
    if frame["question_id"].duplicated().any():
        duplicated = frame.loc[
            frame["question_id"].duplicated(keep=False), "question_id"
        ].tolist()
        raise ValueError(f"중복 question_id가 있습니다: {duplicated}")
    if not set(frame["status"]).issubset(ALLOWED_STATUSES):
        raise ValueError(f"허용되지 않은 상태가 있습니다: {set(frame['status'])}")
    if (frame[["answer_count", "material_count"]] < 0).any().any():
        raise ValueError("answer_count 또는 material_count가 음수입니다.")
    if not (frame["has_answer"] == (frame["answer_count"] > 0)).all():
        raise ValueError("has_answer와 answer_count가 일치하지 않습니다.")
    if not (frame["has_material"] == (frame["material_count"] > 0)).all():
        raise ValueError("has_material과 material_count가 일치하지 않습니다.")

    no_answer = ~frame["has_answer"]
    if frame.loc[no_answer, ["first_answer_at", "first_response_hours"]].notna().any().any():
        raise ValueError("답변 없는 질문에 첫 답변 시각 또는 시간이 있습니다.")
    if frame.loc[frame["has_answer"], "first_answer_at"].isna().any():
        raise ValueError("답변 있는 질문에 첫 답변 시각이 없습니다.")
    if (frame.loc[frame["has_answer"], "first_response_hours"] < 0).any():
        raise ValueError("첫 답변 시간이 음수입니다.")

    return frame.sort_values("question_id").reset_index(drop=True)


def load_snapshot_frames(connection: Connection) -> dict[str, pd.DataFrame]:
    """Load source tables and analysis views from the same snapshot."""
    dataset = normalize_question_dataset(read_dataframe(connection, QUESTION_DATASET_SQL))
    return {
        "dataset": dataset,
        "students": read_dataframe(connection, STUDENTS_SQL),
        "questions": read_dataframe(connection, QUESTIONS_SQL),
        "tutors": read_dataframe(connection, TUTORS_SQL),
        "answers": read_dataframe(connection, ANSWERS_SQL),
        "parameters": read_dataframe(connection, PARAMETERS_SQL),
    }


def load_sql_summaries(connection: Connection) -> dict[str, pd.DataFrame]:
    """Load actual SQL aggregation results for direct pandas comparison."""
    return {
        "status": read_dataframe(connection, STATUS_SUMMARY_SQL),
        "monthly": read_dataframe(connection, MONTHLY_SUMMARY_SQL),
        "student": read_dataframe(connection, STUDENT_SUMMARY_SQL),
        "tutor": read_dataframe(connection, TUTOR_SUMMARY_SQL),
        "response": read_dataframe(connection, RESPONSE_SUMMARY_SQL),
    }
