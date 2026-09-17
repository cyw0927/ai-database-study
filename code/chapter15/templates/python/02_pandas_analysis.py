"""Build reproducible pandas summaries from one read-only Chapter 15 snapshot."""

from __future__ import annotations

import pandas as pd

from validation_utils import load_snapshot_frames, read_only_snapshot

ANALYSIS_TIMEZONE = "Asia/Seoul"


def _to_analysis_timezone(value: object) -> pd.Timestamp:
    """Return a timezone-aware timestamp interpreted in the Chapter 15 business timezone."""
    timestamp = pd.Timestamp(pd.to_datetime(value, errors="raise"))
    if timestamp.tzinfo is None:
        return timestamp.tz_localize(ANALYSIS_TIMEZONE)
    return timestamp.tz_convert(ANALYSIS_TIMEZONE)


def _month_start(timestamp: pd.Timestamp) -> pd.Timestamp:
    """Return a timezone-naive first day used by the SQL DATE question_month column."""
    return pd.Timestamp(year=timestamp.year, month=timestamp.month, day=1)


def build_summaries(frames: dict[str, pd.DataFrame]) -> dict[str, pd.DataFrame]:
    """Build status, month, student, tutor and response summaries."""
    dataset = frames["dataset"].copy()
    students = frames["students"].copy()
    questions = frames["questions"].copy()
    tutors = frames["tutors"].copy()
    answers = frames["answers"].copy()
    parameters = frames["parameters"].copy()

    status_summary = (
        dataset.groupby("status", as_index=False, dropna=False)
        .agg(question_count=("question_id", "count"))
        .sort_values("status")
        .reset_index(drop=True)
    )

    monthly_actual = (
        dataset.groupby("question_month", as_index=False)
        .agg(
            question_count=("question_id", "count"),
            answer_count=("answer_count", "sum"),
            material_count=("material_count", "sum"),
        )
    )

    # PostgreSQL의 timestamptz는 드라이버에서 UTC로 전달될 수 있습니다.
    # 월 경계를 UTC에서 먼저 제거하면 2026-01-01 00:00+09가
    # 2025-12-31 15:00+00로 보이면서 12월이 잘못 생성될 수 있습니다.
    # SQL과 같은 업무 시간대(Asia/Seoul)로 먼저 변환한 뒤 월 시작일을 만듭니다.
    start_at = _to_analysis_timezone(parameters.loc[0, "start_at"])
    end_at = _to_analysis_timezone(parameters.loc[0, "end_at_exclusive"])
    start_month = _month_start(start_at)
    end_month_exclusive = _month_start(end_at)

    if end_at <= start_at:
        raise ValueError("분석 종료 시각은 시작 시각보다 뒤여야 합니다.")
    if end_month_exclusive <= start_month:
        raise ValueError("분석 기간에는 최소 한 개의 월이 포함되어야 합니다.")

    months = pd.DataFrame(
        {
            "question_month": pd.date_range(
                start=start_month,
                end=end_month_exclusive - pd.offsets.MonthBegin(1),
                freq="MS",
            )
        }
    )
    monthly_summary = (
        months.merge(monthly_actual, on="question_month", how="left")
        .fillna({"question_count": 0, "answer_count": 0, "material_count": 0})
        .sort_values("question_month")
        .reset_index(drop=True)
    )

    student_counts = (
        questions.groupby("student_id", as_index=False)
        .agg(question_count=("question_id", "count"))
    )
    student_summary = (
        students.merge(student_counts, on="student_id", how="left")
        .fillna({"question_count": 0})
        .sort_values("student_id")
        .reset_index(drop=True)
    )

    tutor_counts = (
        answers.groupby("tutor_id", as_index=False)
        .agg(answer_count=("answer_id", "count"))
    )
    tutor_summary = (
        tutors.merge(tutor_counts, on="tutor_id", how="left")
        .fillna({"answer_count": 0})
        .sort_values("tutor_id")
        .reset_index(drop=True)
    )

    response_values = dataset.loc[dataset["has_answer"], "first_response_hours"]
    response_summary = pd.DataFrame(
        [
            {
                "answered_questions": int(dataset["has_answer"].sum()),
                "avg_first_response_hours": round(float(response_values.mean()), 2),
                "min_first_response_hours": float(response_values.min()),
                "max_first_response_hours": float(response_values.max()),
            }
        ]
    )

    for frame, columns in [
        (status_summary, ["question_count"]),
        (monthly_summary, ["question_count", "answer_count", "material_count"]),
        (student_summary, ["question_count"]),
        (tutor_summary, ["answer_count"]),
    ]:
        for column in columns:
            frame[column] = pd.to_numeric(frame[column], errors="raise").astype("int64")

    return {
        "status": status_summary,
        "monthly": monthly_summary,
        "student": student_summary,
        "tutor": tutor_summary,
        "response": response_summary,
    }


if __name__ == "__main__":
    with read_only_snapshot() as connection:
        snapshot_frames = load_snapshot_frames(connection)
    summaries = build_summaries(snapshot_frames)
    for name, summary in summaries.items():
        print(f"\n[{name}]")
        print(summary.to_string(index=False))
