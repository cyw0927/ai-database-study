"""Compare actual SQL aggregates and pandas aggregates from one DB snapshot."""

from __future__ import annotations

from importlib.util import module_from_spec, spec_from_file_location
from pathlib import Path

import pandas as pd

from validation_utils import load_snapshot_frames, load_sql_summaries, read_only_snapshot

MODULE_PATH = Path(__file__).with_name("02_pandas_analysis.py")
_spec = spec_from_file_location("chapter15_pandas_analysis", MODULE_PATH)
if _spec is None or _spec.loader is None:
    raise RuntimeError(f"분석 모듈을 읽을 수 없습니다: {MODULE_PATH}")
_analysis = module_from_spec(_spec)
_spec.loader.exec_module(_analysis)
build_summaries = _analysis.build_summaries


def _normalize(name: str, dataframe: pd.DataFrame) -> pd.DataFrame:
    frame = dataframe.copy()
    if name == "monthly":
        frame["question_month"] = pd.to_datetime(
            frame["question_month"], errors="raise"
        ).dt.normalize()
    if name in {"status", "monthly", "student", "tutor"}:
        for column in frame.columns:
            if column.endswith("_count"):
                frame[column] = pd.to_numeric(frame[column], errors="raise").astype(
                    "int64"
                )
    if name == "response":
        for column in frame.columns:
            frame[column] = pd.to_numeric(frame[column], errors="raise")
        frame["answered_questions"] = frame["answered_questions"].astype("int64")
    return frame.reset_index(drop=True)


def validate() -> None:
    with read_only_snapshot() as connection:
        snapshot_frames = load_snapshot_frames(connection)
        sql_summaries = load_sql_summaries(connection)
        pandas_summaries = build_summaries(snapshot_frames)

    for name in ["status", "monthly", "student", "tutor", "response"]:
        sql_frame = _normalize(name, sql_summaries[name])
        pandas_frame = _normalize(name, pandas_summaries[name])
        pd.testing.assert_frame_equal(
            sql_frame,
            pandas_frame,
            check_dtype=False,
            check_exact=False,
            rtol=0,
            atol=1e-9,
        )
        print(f"{name}: PASS")

    dataset = snapshot_frames["dataset"]
    checks = {
        "dataset_rows": len(dataset) == 5,
        "unique_question_id": not dataset["question_id"].duplicated().any(),
        "answer_count_sum": int(dataset["answer_count"].sum()) == 5,
        "material_count_sum": int(dataset["material_count"].sum()) == 7,
        "no_answer_questions": int((~dataset["has_answer"]).sum()) == 1,
    }
    failed = [name for name, passed in checks.items() if not passed]
    for name, passed in checks.items():
        print(f"{name}: {'PASS' if passed else 'FAIL'}")
    if failed:
        raise AssertionError(f"데이터셋 검증 실패: {failed}")

    print("Chapter 15 SQL and pandas cross-validation passed")


if __name__ == "__main__":
    validate()
