"""
main.py — Task 2: Student Performance Prediction API
=====================================================
Mission: Early identification of academically at-risk students
         to enable targeted support in under-resourced communities.
 
Endpoints:
  GET  /              — health check
  GET  /health        — model info
  POST /predict       — predict final grade for one student
  POST /predict/batch — predict grades for up to 500 students
  POST /retrain       — retrain model on newly uploaded CSV data
 
Swagger UI : http://localhost:8000/docs
Redoc UI   : http://localhost:8000/redoc
 
Run locally:
    uvicorn main:app --reload --port 8000
"""
 
# ==============================================================
# IMPORTS
# ==============================================================
import io
import os
import logging
from typing import List, Literal
 
import joblib
import numpy as np
import pandas as pd
 
from fastapi import FastAPI, HTTPException, UploadFile, File, status
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field
from sklearn.ensemble        import RandomForestRegressor
from sklearn.model_selection import train_test_split
from sklearn.preprocessing   import StandardScaler
from sklearn.metrics         import mean_squared_error, r2_score
 
# ==============================================================
# LOGGING
# ==============================================================
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)
 
# ==============================================================
# FASTAPI APP INSTANCE
# ==============================================================
app = FastAPI(
    title="Student Performance Prediction API",
    description="""
## Student Grade Prediction — Early Intervention Tool
 
Predicts a student's final exam grade (**G3**, 0–20 scale) from enrolment-time
features — before any mid-term results exist. Built to flag at-risk students early
so educators can deploy targeted support in under-resourced school communities.
 
### Available Endpoints
| Method | Path | Description |
|--------|------|-------------|
| GET  | `/` | Root health check |
| GET  | `/health` | Model and feature info |
| POST | `/predict` | Predict grade for one student |
| POST | `/predict/batch` | Predict grades for up to 500 students |
| POST | `/retrain` | Retrain model on newly uploaded CSV |
 
### Live API
Once deployed, Swagger UI is available at **`/docs`** (this page).
 
**Summative Assignment — Task 2 — African Leadership University**
    """,
    version="1.0.0",
    contact={"name": "Chinmerem", "email": "student@alueducation.com"},
)
 
# ==============================================================
# CORS MIDDLEWARE
#
# Explicitly configured — does NOT use wildcard "*" on any field.
#
# allow_origins    : Only specific trusted domains are whitelisted.
#                   Prevents arbitrary websites from calling the API.
# allow_credentials: True — required to forward cookies and
#                   Authorization headers with cross-origin requests.
# allow_methods    : Only the HTTP verbs this API actually exposes.
#                   OPTIONS is included for browser CORS preflight.
# allow_headers    : Only the headers a browser client genuinely needs.
#                   Restricting this prevents header-injection attacks.
# ==============================================================
app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "http://localhost:3000",                         # React / Next.js local dev server
        "http://localhost:8000",                         # FastAPI local (Swagger UI self-calls)
        "http://127.0.0.1:8000",                         # same host, numeric loopback form
        "https://student-performance-api.onrender.com",  # production Render back-end URL
        "https://student-perf-frontend.onrender.com",    # front-end app if separately hosted
    ],
    allow_credentials=True,
    allow_methods=[
        "GET",      # used by /  and /health
        "POST",     # used by /predict, /predict/batch, /retrain
        "OPTIONS",  # required for CORS preflight requests sent by browsers
    ],
    allow_headers=[
        "Content-Type",      # tells the server the request body is JSON
        "Authorization",     # needed for Bearer token / API key authentication
        "Accept",            # browser content-type negotiation
        "Origin",            # browsers attach this on every cross-origin request
        "X-Requested-With",  # sent by Axios and XMLHttpRequest-based clients
    ],
)
 
# ==============================================================
# LOAD MODEL ARTEFACTS FROM TASK 1
# ==============================================================
MODEL_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "saved_model")
 
 
def load_artefacts():
    """Load the best model, scaler, and feature list from disk."""
    mdl   = joblib.load(os.path.join(MODEL_DIR, "best_model.pkl"))
    sc    = joblib.load(os.path.join(MODEL_DIR, "scaler.pkl"))
    feats = joblib.load(os.path.join(MODEL_DIR, "feature_names.pkl"))
    logger.info("Model loaded: %s | Features: %d", type(mdl).__name__, len(feats))
    return mdl, sc, feats
 
 
model, scaler, feature_names = load_artefacts()
 
# ==============================================================
# ENCODING MAPS (must match Task 1 training pipeline exactly)
# ==============================================================
BINARY_MAP = {
    "sex":        {"F": 0, "M": 1},
    "address":    {"R": 0, "U": 1},
    "famsize":    {"GT3": 0, "LE3": 1},
    "Pstatus":    {"A": 0, "T": 1},
    "schoolsup":  {"no": 0, "yes": 1},
    "famsup":     {"no": 0, "yes": 1},
    "paid":       {"no": 0, "yes": 1},
    "activities": {"no": 0, "yes": 1},
    "nursery":    {"no": 0, "yes": 1},
    "higher":     {"no": 0, "yes": 1},
    "internet":   {"no": 0, "yes": 1},
    "romantic":   {"no": 0, "yes": 1},
}
MULTI_COLS = ["Mjob", "Fjob", "guardian"]
 
# ==============================================================
# PYDANTIC INPUT SCHEMA
#
# StudentInput enforces:
#   1. A data type on every single field  (int or Literal[str])
#   2. Range constraints on all numeric fields  via Field(ge=, le=)
#   3. Allowed-value constraints on all string fields via Literal[...]
#   4. A clear description on every field (rendered in Swagger UI)
# ==============================================================
class StudentInput(BaseModel):
    """
    Student enrolment profile — 26 features used to predict final grade (G3).
    Mid-term grades G1 and G2 are excluded to prevent data leakage.
    """
 
    # ── Demographic ──────────────────────────────────────────────
    sex: Literal["F", "M"] = Field(
        ..., description="Student sex — 'F' = female, 'M' = male"
    )
    age: int = Field(
        ..., ge=15, le=22,
        description="Age in years. Accepted range: 15 to 22."
    )
    address: Literal["U", "R"] = Field(
        ..., description="Home address type — 'U' = urban, 'R' = rural"
    )
    famsize: Literal["LE3", "GT3"] = Field(
        ..., description="Family size — 'LE3' = 3 or fewer members, 'GT3' = more than 3 members"
    )
    Pstatus: Literal["T", "A"] = Field(
        ..., description="Parent cohabitation — 'T' = living together, 'A' = apart"
    )
 
    # ── Parental background ──────────────────────────────────────
    Medu: int = Field(
        ..., ge=0, le=4,
        description="Mother's education. 0=none, 1=primary (up to 4th grade), 2=5th–9th grade, 3=secondary, 4=higher education"
    )
    Fedu: int = Field(
        ..., ge=0, le=4,
        description="Father's education. 0=none, 1=primary (up to 4th grade), 2=5th–9th grade, 3=secondary, 4=higher education"
    )
    Mjob: Literal["teacher", "health", "services", "at_home", "other"] = Field(
        ..., description="Mother's occupation"
    )
    Fjob: Literal["teacher", "health", "services", "at_home", "other"] = Field(
        ..., description="Father's occupation"
    )
    guardian: Literal["mother", "father", "other"] = Field(
        ..., description="Student's primary guardian"
    )
 
    # ── School behaviour ─────────────────────────────────────────
    traveltime: int = Field(
        ..., ge=1, le=4,
        description="Travel time to school. 1=under 15 min, 2=15–30 min, 3=30 min–1 h, 4=over 1 h"
    )
    studytime: int = Field(
        ..., ge=1, le=4,
        description="Weekly study time. 1=under 2 h, 2=2–5 h, 3=5–10 h, 4=over 10 h"
    )
    failures: int = Field(
        ..., ge=0, le=4,
        description="Number of past class failures. 0 = none, 4 = four or more."
    )
    schoolsup: Literal["yes", "no"] = Field(
        ..., description="Extra educational support from the school"
    )
    famsup: Literal["yes", "no"] = Field(
        ..., description="Family educational support at home"
    )
    paid: Literal["yes", "no"] = Field(
        ..., description="Enrolled in extra paid tutoring classes"
    )
    activities: Literal["yes", "no"] = Field(
        ..., description="Participates in extra-curricular activities"
    )
    nursery: Literal["yes", "no"] = Field(
        ..., description="Attended nursery school as a young child"
    )
    higher: Literal["yes", "no"] = Field(
        ..., description="Aspires to pursue higher (university-level) education"
    )
    internet: Literal["yes", "no"] = Field(
        ..., description="Has internet access at home"
    )
    romantic: Literal["yes", "no"] = Field(
        ..., description="Currently in a romantic relationship"
    )
 
    # ── Social & health ──────────────────────────────────────────
    famrel: int = Field(
        ..., ge=1, le=5,
        description="Quality of family relationships. 1 = very bad, 5 = excellent"
    )
    freetime: int = Field(
        ..., ge=1, le=5,
        description="Free time after school. 1 = very low, 5 = very high"
    )
    goout: int = Field(
        ..., ge=1, le=5,
        description="Frequency of going out with friends. 1 = very low, 5 = very high"
    )
    Dalc: int = Field(
        ..., ge=1, le=5,
        description="Workday alcohol consumption. 1 = very low, 5 = very high"
    )
    Walc: int = Field(
        ..., ge=1, le=5,
        description="Weekend alcohol consumption. 1 = very low, 5 = very high"
    )
    health: int = Field(
        ..., ge=1, le=5,
        description="Current health status. 1 = very bad, 5 = very good"
    )
    absences: int = Field(
        ..., ge=0, le=93,
        description="Number of school absences. Accepted range: 0 to 93."
    )
 
    model_config = {
        "json_schema_extra": {
            "example": {
                "sex": "F", "age": 16, "address": "U", "famsize": "LE3",
                "Pstatus": "T", "Medu": 3, "Fedu": 2,
                "Mjob": "services", "Fjob": "other", "guardian": "mother",
                "traveltime": 1, "studytime": 2, "failures": 0,
                "schoolsup": "no", "famsup": "yes", "paid": "no",
                "activities": "yes", "nursery": "yes", "higher": "yes",
                "internet": "yes", "romantic": "no",
                "famrel": 4, "freetime": 3, "goout": 2,
                "Dalc": 1, "Walc": 2, "health": 4, "absences": 4,
            }
        }
    }
 
 
class BatchInput(BaseModel):
    """Request body for batch prediction."""
    students: List[StudentInput] = Field(
        ..., min_length=1, max_length=500,
        description="List of 1 to 500 student records"
    )
 
 
# ==============================================================
# RESPONSE SCHEMAS
# ==============================================================
class PredictionResponse(BaseModel):
    predicted_grade: float = Field(..., description="Predicted final grade G3 (0–20)")
    risk_level:      str   = Field(..., description="Risk intervention classification")
    model_used:      str   = Field(..., description="Model class that produced the prediction")
    input_received:  dict  = Field(..., description="Echo of your input for verification")
 
 
class BatchPredictionResponse(BaseModel):
    predictions:    List[dict] = Field(..., description="Prediction result for each student")
    total_students: int        = Field(..., description="Total students processed")
 
 
class RetrainResponse(BaseModel):
    message:     str   = Field(..., description="Status message")
    rows_used:   int   = Field(..., description="Training rows in uploaded file")
    new_model:   str   = Field(..., description="Model class retrained")
    test_r2:     float = Field(..., description="R² on held-out 20% test split")
    test_rmse:   float = Field(..., description="RMSE on held-out 20% test split")
    model_saved: bool  = Field(..., description="True if new model was saved to disk")
 
 
# ==============================================================
# HELPERS
# ==============================================================
def encode_student(raw: dict) -> pd.DataFrame:
    """Encode a raw student dict into the feature matrix the model expects."""
    df = pd.DataFrame([raw])
    for col, mapping in BINARY_MAP.items():
        if col in df.columns:
            df[col] = df[col].map(mapping)
    df = pd.get_dummies(
        df, columns=[c for c in MULTI_COLS if c in df.columns], drop_first=True
    )
    for col in feature_names:
        if col not in df.columns:
            df[col] = 0
    return df[feature_names]
 
 
def preprocess_for_retrain(df_raw: pd.DataFrame):
    """Full preprocessing for a retrain dataframe. Returns (X_encoded, y)."""
    df = df_raw.copy()
    df.drop(
        columns=[c for c in ["G1", "G2", "school", "reason"] if c in df.columns],
        inplace=True,
    )
    X = df.drop(columns=["G3"])
    y = df["G3"]
    for col, mapping in BINARY_MAP.items():
        if col in X.columns:
            X[col] = X[col].map(mapping)
    X = pd.get_dummies(
        X, columns=[c for c in MULTI_COLS if c in X.columns], drop_first=True
    )
    return X, y
 
 
def get_risk_label(grade: float) -> str:
    if grade < 7:
        return "HIGH RISK — Urgent support recommended"
    elif grade < 11:
        return "MODERATE — Monitor and provide extra resources"
    return "ON TRACK — Continue current support"
 
 
def run_prediction(student_dict: dict) -> float:
    df_enc    = encode_student(student_dict)
    df_scaled = scaler.transform(df_enc)
    return float(np.clip(model.predict(df_scaled)[0], 0, 20))
 
 
# ==============================================================
# ENDPOINTS
# ==============================================================
 
@app.get("/", tags=["Health"], summary="Root health check")
def root():
    """Confirms the API is live and lists all endpoints."""
    return {
        "status":     "running",
        "message":    "Student Performance Prediction API is live.",
        "swagger_ui": "/docs",
        "redoc":      "/redoc",
        "endpoints": {
            "health":        "GET  /health",
            "predict":       "POST /predict",
            "predict_batch": "POST /predict/batch",
            "retrain":       "POST /retrain",
        },
    }
 
 
@app.get("/health", tags=["Health"], summary="Model and API status")
def health():
    """Returns current model type and feature count."""
    return {
        "status":        "healthy",
        "model_type":    type(model).__name__,
        "feature_count": len(feature_names),
        "features":      feature_names,
    }
 
 
@app.post(
    "/predict",
    response_model=PredictionResponse,
    status_code=status.HTTP_200_OK,
    tags=["Prediction"],
    summary="Predict final grade for one student",
    description=(
        "Submit one student's enrolment profile. "
        "Returns predicted G3 grade (0–20), a risk classification label, "
        "and the model used."
    ),
)
def predict(student: StudentInput):
    """
    ### POST /predict
 
    All 26 fields are required (see schema). Returns:
    - **predicted_grade** — G3 score 0–20
    - **risk_level** — ON TRACK / MODERATE / HIGH RISK
    - **model_used** — model class name
    - **input_received** — echo of input for transparency
    """
    try:
        d     = student.model_dump()
        grade = run_prediction(d)
        return PredictionResponse(
            predicted_grade=round(grade, 2),
            risk_level=get_risk_label(grade),
            model_used=type(model).__name__,
            input_received=d,
        )
    except Exception as exc:
        logger.error("Prediction error: %s", exc)
        raise HTTPException(status.HTTP_500_INTERNAL_SERVER_ERROR, detail=str(exc))
 
 
@app.post(
    "/predict/batch",
    response_model=BatchPredictionResponse,
    status_code=status.HTTP_200_OK,
    tags=["Prediction"],
    summary="Predict final grades for multiple students",
)
def predict_batch(batch: BatchInput):
    """
    ### POST /predict/batch
 
    Send a JSON body: `{ "students": [ {...}, {...} ] }` with 1–500 records.
    Returns a predicted grade and risk label for every student.
    """
    try:
        out = []
        for i, s in enumerate(batch.students):
            grade = run_prediction(s.model_dump())
            out.append({
                "index":           i,
                "predicted_grade": round(grade, 2),
                "risk_level":      get_risk_label(grade),
            })
        return BatchPredictionResponse(predictions=out, total_students=len(out))
    except Exception as exc:
        logger.error("Batch error: %s", exc)
        raise HTTPException(status.HTTP_500_INTERNAL_SERVER_ERROR, detail=str(exc))
 
 
@app.post(
    "/retrain",
    response_model=RetrainResponse,
    status_code=status.HTTP_200_OK,
    tags=["Retraining"],
    summary="Retrain model on newly uploaded data",
    description=(
        "Upload a CSV file with the same columns as the original dataset plus a `G3` "
        "target column. The API preprocesses the data, retrains a Random Forest, "
        "evaluates performance, saves the new model to disk, and reloads it into memory. "
        "All subsequent `/predict` calls immediately use the newly trained model."
    ),
)
async def retrain(
    file: UploadFile = File(
        ...,
        description="CSV file containing student data with a G3 column. Minimum 50 rows.",
    )
):
    """
    ### POST /retrain — Model update when new data is available
 
    **This is the endpoint that triggers a model update when new data is seen.**
 
    Upload a `.csv` file that contains at least 50 student rows and a `G3` column.
 
    Pipeline:
    1. Validate file type, row count, and column presence
    2. Apply the same preprocessing used in Task 1
    3. Train / test split (80% / 20%)
    4. Train a new `RandomForestRegressor`
    5. Evaluate: compute R² and RMSE on the test split
    6. Save updated model, scaler, and feature names to `saved_model/`
    7. Reload artefacts — next prediction call uses the new model immediately
    """
    global model, scaler, feature_names
 
    if not file.filename.endswith(".csv"):
        raise HTTPException(
            status.HTTP_400_BAD_REQUEST,
            detail="Only .csv files are accepted.",
        )
 
    try:
        contents = await file.read()
        df_new   = pd.read_csv(io.StringIO(contents.decode("utf-8")))
    except Exception as exc:
        raise HTTPException(
            status.HTTP_400_BAD_REQUEST,
            detail=f"Could not parse CSV: {exc}",
        )
 
    if "G3" not in df_new.columns:
        raise HTTPException(
            status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="CSV must contain a 'G3' column (the target variable).",
        )
 
    if len(df_new) < 50:
        raise HTTPException(
            status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail=f"Only {len(df_new)} rows found. Minimum 50 required.",
        )
 
    try:
        X, y = preprocess_for_retrain(df_new)
 
        X_train, X_test, y_train, y_test = train_test_split(
            X, y, test_size=0.2, random_state=42
        )
 
        new_scaler = StandardScaler()
        Xtr = new_scaler.fit_transform(X_train)
        Xte = new_scaler.transform(X_test)
 
        new_model = RandomForestRegressor(
            n_estimators=200, max_depth=10,
            min_samples_leaf=2, random_state=42, n_jobs=-1,
        )
        new_model.fit(Xtr, y_train)
 
        preds    = new_model.predict(Xte)
        new_r2   = float(r2_score(y_test, preds))
        new_rmse = float(np.sqrt(mean_squared_error(y_test, preds)))
 
        os.makedirs(MODEL_DIR, exist_ok=True)
        joblib.dump(new_model,        os.path.join(MODEL_DIR, "best_model.pkl"))
        joblib.dump(new_scaler,       os.path.join(MODEL_DIR, "scaler.pkl"))
        joblib.dump(list(X.columns),  os.path.join(MODEL_DIR, "feature_names.pkl"))
 
        model, scaler, feature_names = load_artefacts()
 
        logger.info("Retrain done — rows: %d | R²: %.4f | RMSE: %.4f",
                    len(df_new), new_r2, new_rmse)
 
        return RetrainResponse(
            message="Model retrained and reloaded successfully. All future /predict calls use the new model.",
            rows_used=len(df_new),
            new_model=type(new_model).__name__,
            test_r2=round(new_r2, 4),
            test_rmse=round(new_rmse, 4),
            model_saved=True,
        )
 
    except HTTPException:
        raise
    except Exception as exc:
        logger.error("Retrain failed: %s", exc)
        raise HTTPException(
            status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Retraining failed: {exc}",
        )
 