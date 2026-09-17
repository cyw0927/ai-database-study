"""Load and strictly validate the Chapter 15 question-level analysis view."""

from __future__ import annotations

import pandas as pd

from validation_utils import QUESTION_DATASET_SQL, normalize_question_dataset, read_dataframe, read_only_snapshot


def load_dataset() -> pd.DataFrame:
    """Return the validated question-level DataFrame from one read-only snapshot."""
    with read_only_snapshot() as connection:
        dataframe = read_dataframe(connection, QUESTION_DATASET_SQL)
    return normalize_question_dataset(dataframe)


if __name__ == "__main__":
    df = load_dataset()
    print(df.to_string(index=False))
    print("\n[dtypes]")
    print(df.dtypes)
    print(f"\n행 수: {len(df)}")
