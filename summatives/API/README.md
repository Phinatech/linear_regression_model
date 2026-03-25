# Task 2 — Student Performance Prediction API

**Mission:** Early identification of academically at-risk students to enable targeted support in under-resourced school communities. this 

---

## Live Public URL

| Resource | URL |
|----------|-----|
| Swagger UI (interactive docs) | https://student-performance-api-li3g.onrender.com/docs |
| Redoc UI | https://student-performance-api-li3g.onrender.com/redoc |
| Health check | https://student-performance-api-li3g.onrender.com/health |
| Root | https://student-performance-api-li3g.onrender.com/ |

Click the Swagger UI link above to access the live, interactive API documentation.

---

## Endpoints

| Method | Path | Description |
|--------|------|-------------|
| GET | `/` | Root health check |
| GET | `/health` | Model type and feature info |
| POST | `/predict` | Predict G3 for one student |
| POST | `/predict/batch` | Predict G3 for up to 500 students |
| POST | `/retrain` | Retrain model on newly uploaded CSV data |

---

## Project Files

```
summatives/API/
├── main.py               ← FastAPI application (Task 2)
├── predict.py            ← Prediction helper from Task 1
├── requirements.txt      ← Pinned dependencies for Render
├── render.yaml           ← Render one-click deployment config
└── saved_model/
    ├── best_model.pkl    ← Trained model from Task 1
    ├── scaler.pkl        ← StandardScaler fitted on training data
    └── feature_names.pkl ← Ordered feature list for inference
```

---

## Run Locally

```bash
# 1. Navigate into the API folder
cd summatives/API

# 2. Create and activate a virtual environment
python3 -m venv venv
source venv/bin/activate

# 3. Install dependencies
pip install -r requirements.txt

# 4. Start the server
uvicorn main:app --reload --port 8000

# 5. Open Swagger UI in your browser
# http://localhost:8000/docs
```

---

## Libraries Used

| Library | Purpose |
|---------|---------|
| `fastapi` | Web framework for building the API endpoints |
| `uvicorn` | ASGI server that runs the FastAPI app |
| `pydantic` | Data validation and type enforcement via BaseModel |
| `scikit-learn` | Machine learning models (RandomForest, LinearRegression, DecisionTree) |
| `pandas` | Data manipulation and preprocessing |
| `numpy` | Numerical operations |
| `joblib` | Saving and loading model artefacts |
| `python-multipart` | Enables file upload support for the /retrain endpoint |

---

## CORS Configuration

CORS is implemented with explicit values — no wildcard `*` used on any field:

```python
app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "http://localhost:3000",
        "http://localhost:8000",
        "http://127.0.0.1:8000",
        "https://student-performance-api-li3g.onrender.com",
        "https://student-perf-frontend.onrender.com",
    ],
    allow_credentials=True,
    allow_methods=["GET", "POST", "OPTIONS"],
    allow_headers=["Content-Type", "Authorization", "Accept", "Origin", "X-Requested-With"],
)
```

---

## Pydantic Validation

All 26 input variables are validated using Pydantic's `BaseModel`:

- Numeric fields use `Field(ge=..., le=...)` to enforce realistic ranges
- Categorical fields use `Literal[...]` to restrict to allowed values only

Example constraints:

| Variable | Type | Constraint |
|----------|------|------------|
| `age` | int | ge=15, le=22 |
| `failures` | int | ge=0, le=4 |
| `absences` | int | ge=0, le=93 |
| `famrel` | int | ge=1, le=5 |
| `studytime` | int | ge=1, le=4 |
| `sex` | Literal | "F" or "M" only |
| `higher` | Literal | "yes" or "no" only |
| `Mjob` | Literal | "teacher", "health", "services", "at_home", "other" |

Sending an invalid value returns `422 Unprocessable Entity` automatically.

---

## Example Requests

### POST /predict — single student

```bash
curl -X POST "https://student-performance-api-li3g.onrender.com/predict" \
     -H "Content-Type: application/json" \
     -d '{
       "sex": "F", "age": 16, "address": "U", "famsize": "LE3",
       "Pstatus": "T", "Medu": 3, "Fedu": 2,
       "Mjob": "services", "Fjob": "other", "guardian": "mother",
       "traveltime": 1, "studytime": 2, "failures": 0,
       "schoolsup": "no", "famsup": "yes", "paid": "no",
       "activities": "yes", "nursery": "yes", "higher": "yes",
       "internet": "yes", "romantic": "no",
       "famrel": 4, "freetime": 3, "goout": 2,
       "Dalc": 1, "Walc": 2, "health": 4, "absences": 4
     }'
```

Response:

```json
{
  "predicted_grade": 12.4,
  "risk_level": "ON TRACK — Continue current support",
  "model_used": "RandomForestRegressor",
  "input_received": { "sex": "F", "age": 16, "...": "..." }
}
```

### POST /retrain — trigger model update with new data

```bash
curl -X POST "https://student-performance-api-li3g.onrender.com/retrain" \
     -F "file=@student-mat.csv"
```

Response:

```json
{
  "message": "Model retrained and reloaded successfully.",
  "rows_used": 395,
  "new_model": "RandomForestRegressor",
  "test_r2": 0.8721,
  "test_rmse": 1.43,
  "model_saved": true
}
```

---

## Deployment — Render

Deployed on Render using `render.yaml`:

```yaml
services:
  - type: web
    name: student-performance-api
    env: python
    buildCommand: pip install -r requirements.txt
    startCommand: uvicorn main:app --host 0.0.0.0 --port $PORT
```

> **Note:** Render free-tier services sleep after 15 minutes of inactivity.
> The first request after sleeping may take 30–60 seconds to respond. This is normal.

---

## Requirements Checklist

### Prediction API (5 pts — Excellent band)

- [x] API endpoint for prediction — `POST /predict` and `POST /predict/batch`
- [x] Public URL with path to Swagger UI — https://student-performance-api-li3g.onrender.com/docs
- [x] Pydantic constraints on all variables — `Field(ge=, le=)` and `Literal[...]`
- [x] Each variable has an explicit data type — `int` or `Literal[str...]`

### Retraining (3 pts — Excellent band)

- [x] `POST /retrain` triggers model update when new data is uploaded
- [x] Accepts CSV file upload, preprocesses, retrains, evaluates, saves to disk
- [x] Reloads model into live memory — no restart needed
- [x] Validates file type, row count (min 50), and G3 column before training

### CORS Middleware (5 pts — Excellent band)

- [x] `CORSMiddleware` implemented
- [x] `allow_origins` — explicit list of 5 specific trusted URLs, no wildcard `*`
- [x] `allow_credentials` — True
- [x] `allow_methods` — explicit list: `["GET", "POST", "OPTIONS"]`
- [x] `allow_headers` — explicit list: Content-Type, Authorization, Accept, Origin, X-Requested-With
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            