"""
predict.py
──────────
Uses the best-performing saved model to predict a student's
final grade (G3) from their demographic and behavioural profile.
 
This script is the bridge to Task 2. It exposes:
  - predict_single(student_dict) → float  (one-student prediction)
  - predict_batch(df)            → array  (batch predictions)
 
Usage:
    python predict.py
    or import and call predict_single() from another script.
"""
 
import joblib
import numpy as np
import pandas as pd
import os
 
# ── Load saved artefacts ──────────────────────────────────────
MODEL_DIR = "saved_model"
 
model         = joblib.load(os.path.join(MODEL_DIR, "best_model.pkl"))
scaler        = joblib.load(os.path.join(MODEL_DIR, "scaler.pkl"))
feature_names = joblib.load(os.path.join(MODEL_DIR, "feature_names.pkl"))
 
print("✅ Model loaded:", type(model).__name__)
print(f"   Expects {len(feature_names)} features after encoding.\n")
 
 
# ── Helper: build a DataFrame row from raw student input ──────
def encode_student(raw: dict) -> pd.DataFrame:
    """
    Convert a human-readable student profile dict into the
    encoded, one-hot-expanded format expected by the model.
 
    Parameters
    ----------
    raw : dict with keys matching the RAW dataset columns
          (before encoding). See EXAMPLE_STUDENT below.
 
    Returns
    -------
    df_encoded : pd.DataFrame, shape (1, n_features)
    """
    df = pd.DataFrame([raw])
 
    # ── Binary columns (same mapping used in training) ──
    binary_map = {
        "sex":       {"F": 0, "M": 1},
        "address":   {"R": 0, "U": 1},
        "famsize":   {"GT3": 0, "LE3": 1},
        "Pstatus":   {"A": 0, "T": 1},
        "schoolsup": {"no": 0, "yes": 1},
        "famsup":    {"no": 0, "yes": 1},
        "paid":      {"no": 0, "yes": 1},
        "activities":{"no": 0, "yes": 1},
        "nursery":   {"no": 0, "yes": 1},
        "higher":    {"no": 0, "yes": 1},
        "internet":  {"no": 0, "yes": 1},
        "romantic":  {"no": 0, "yes": 1},
    }
    for col, mapping in binary_map.items():
        if col in df.columns:
            df[col] = df[col].map(mapping)
 
    # ── Multi-class columns → One-Hot (drop_first=True like training) ──
    multi_cols = ["Mjob", "Fjob", "guardian"]
    df = pd.get_dummies(df, columns=[c for c in multi_cols if c in df.columns],
                        drop_first=True)
 
    # ── Align to training feature set ──
    #    Add any missing OHE columns as 0; drop any extras
    for col in feature_names:
        if col not in df.columns:
            df[col] = 0
    df = df[feature_names]   # enforce exact column order
 
    return df
 
 
# ── Core prediction function ───────────────────────────────────
def predict_single(student_dict: dict) -> float:
    """
    Predict the final grade (G3) for a single student.
 
    Parameters
    ----------
    student_dict : dict
        Raw student features. See EXAMPLE_STUDENT below.
 
    Returns
    -------
    predicted_grade : float   (clipped to [0, 20])
    """
    df_encoded = encode_student(student_dict)
    df_scaled  = scaler.transform(df_encoded)
    pred       = model.predict(df_scaled)[0]
    return float(np.clip(pred, 0, 20))
 
 
def predict_batch(df_raw: pd.DataFrame) -> np.ndarray:
    """
    Predict final grades for multiple students at once.
 
    Parameters
    ----------
    df_raw : pd.DataFrame of raw student records
 
    Returns
    -------
    predictions : np.ndarray of floats, shape (n_students,)
    """
    records = df_raw.to_dict(orient="records")
    return np.array([predict_single(r) for r in records])
 
 
def risk_label(grade: float) -> str:
    """Translate numeric grade into an intervention risk level."""
    if grade < 7:
        return "🔴 HIGH RISK   — Urgent support recommended"
    elif grade < 11:
        return "🟡 MODERATE    — Monitor & provide extra resources"
    else:
        return "🟢 ON TRACK    — Continue current support"
 
 
# ── Demo: predict for three example students ───────────────────
if __name__ == "__main__":
 
    EXAMPLE_STUDENTS = [
        {
            # Student A — socioeconomically challenged, high absences
            "sex": "M", "age": 17, "address": "R", "famsize": "GT3",
            "Pstatus": "A", "Medu": 1, "Fedu": 1,
            "Mjob": "other",  "Fjob": "other", "guardian": "mother",
            "studytime": 1, "failures": 2, "schoolsup": "yes",
            "famsup": "no", "paid": "no", "activities": "no",
            "nursery": "yes", "higher": "no", "internet": "no",
            "romantic": "yes", "famrel": 2, "freetime": 4,
            "goout": 4, "Dalc": 3, "Walc": 4, "health": 2, "absences": 18,
        },
        {
            # Student B — average, moderate engagement
            "sex": "F", "age": 16, "address": "U", "famsize": "LE3",
            "Pstatus": "T", "Medu": 3, "Fedu": 2,
            "Mjob": "services", "Fjob": "other", "guardian": "mother",
            "studytime": 2, "failures": 0, "schoolsup": "no",
            "famsup": "yes", "paid": "no", "activities": "yes",
            "nursery": "yes", "higher": "yes", "internet": "yes",
            "romantic": "no", "famrel": 4, "freetime": 3,
            "goout": 2, "Dalc": 1, "Walc": 2, "health": 4, "absences": 4,
        },
        {
            # Student C — strong background, high engagement
            "sex": "F", "age": 15, "address": "U", "famsize": "LE3",
            "Pstatus": "T", "Medu": 4, "Fedu": 4,
            "Mjob": "teacher", "Fjob": "health", "guardian": "mother",
            "studytime": 4, "failures": 0, "schoolsup": "no",
            "famsup": "yes", "paid": "yes", "activities": "yes",
            "nursery": "yes", "higher": "yes", "internet": "yes",
            "romantic": "no", "famrel": 5, "freetime": 2,
            "goout": 1, "Dalc": 1, "Walc": 1, "health": 5, "absences": 0,
        },
    ]
 
    print("=" * 60)
    print("  STUDENT PERFORMANCE PREDICTOR — Early Intervention Tool")
    print("=" * 60)
 
    for i, student in enumerate(EXAMPLE_STUDENTS, 1):
        grade = predict_single(student)
        label = risk_label(grade)
        print(f"\n Student {i}")
        print(f"   Predicted Final Grade (G3): {grade:.1f} / 20")
        print(f"   Risk Assessment           : {label}")
 
    print("\n" + "=" * 60)
    print("  BATCH PREDICTION DEMO")
    print("=" * 60)
    df_batch = pd.DataFrame(EXAMPLE_STUDENTS)
    grades   = predict_batch(df_batch)
    for i, g in enumerate(grades, 1):
        print(f"  Student {i}: G3 = {g:.1f}  →  {risk_label(g)}")
 
    print("\n Prediction script ready for Task 2 integration.")
    print("   Import with: from predict import predict_single, predict_batch")
 