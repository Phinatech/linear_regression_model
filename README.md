# Student Performance Prediction — Summative Assignment

## Mission

In under-resourced school communities across Sub-Saharan Africa, students who are academically at risk often go unidentified until it is too late for meaningful support. This project uses machine learning to predict a student's final exam grade (**G3, 0–20**) from enrolment-time demographic, socioeconomic, and behavioural features — flagging at-risk students early so educators can deploy targeted interventions before any exam results exist.

---

## Live API — Swagger UI

Click the link below to access the interactive API documentation and test predictions:

**https://student-performance-api-li3g.onrender.com/docs**

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/` | GET | Health check |
| `/health` | GET | Model and feature info |
| `/predict` | POST | Predict final grade for one student |
| `/predict/batch` | POST | Predict for up to 500 students |
| `/retrain` | POST | Retrain model on newly uploaded CSV |

> **Note:** The API is hosted on Render's free tier. The first request after inactivity may take 30–60 seconds to wake up. Refresh if needed.

---

## Video Demo

[Watch on YouTube — add your link here](#)

The 7-minute video covers:

- Flutter mobile app making a live prediction
- Flutter API call code walkthrough (`api_service.dart`)
- Swagger UI testing — predictions, data type validation, range constraints
- Jupyter notebook — model creation and performance comparison
- Model loss, hyperparameters, retraining strategy, and CORS explanation

---

## Project Structure

```
summatives/
├── API/
│   ├── main.py               ← FastAPI application (Task 2)
│   ├── predict.py            ← Prediction helper (Task 1)
│   ├── requirements.txt      ← Dependencies
│   ├── render.yaml           ← Render deployment config
│   └── saved_model/
│       ├── best_model.pkl
│       ├── scaler.pkl
│       └── feature_names.pkl
│
├── linear_regression/
│   └── multivariate.ipynb    ← Task 1 notebook (full ML pipeline)
│
└── FlutterApp/
    └── student_grade_predictor/
        ├── pubspec.yaml
        └── lib/
            ├── main.dart
            ├── prediction_page.dart
            ├── api_service.dart
            ├── result_display.dart
            └── widgets/
                └── form_widgets.dart
```

---

## How to Run the Mobile App

### Prerequisites

- Flutter SDK installed (`brew install --cask flutter` on Mac)
- VS Code with the Flutter and Dart extensions installed
- A device or simulator (iOS Simulator, Android Emulator, or Chrome)

### Steps

**1. Clone the repository**
```bash
git clone https://github.com/YOUR-USERNAME/linear_regression_model.git
cd linear_regression_model/summatives/FlutterApp/student_grade_predictor
```

**2. Install dependencies**
```bash
flutter pub get
```

**3. Run the app**
```bash
flutter run
```

When prompted, select your target device:

- **Chrome** — quickest option, no simulator setup needed
- **iPhone Simulator** — recommended for iOS testing
- **Android Emulator** — requires Android Studio

**4. Use the app**

1. Fill in all 26 student profile fields
2. Tap the **Predict** button
3. The predicted G3 grade and risk level appear in the display area below

> The app calls `https://student-performance-api-li3g.onrender.com/predict` directly. No local server needed.

---

## How to Run the API Locally

```bash
cd summatives/API
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
uvicorn main:app --reload --port 8000
# Open http://localhost:8000/docs
```

---

## Model Performance Summary

| Model | Test R² | Test RMSE | Test MAE |
|-------|---------|-----------|----------|
| Linear Regression | ~0.25 | ~3.8 | ~2.9 |
| Decision Tree | ~0.55 | ~2.9 | ~2.1 |
| **Random Forest** | **~0.87** | **~1.4** | **~1.0** |
| SGD (Gradient Descent) | ~0.24 | ~3.8 | ~2.9 |

**Best model: Random Forest** — selected because it handles the mixed categorical and numeric feature set best, achieves the lowest RMSE, and generalises well without significant overfitting.

---

## Dataset

**Student Performance Dataset (Math course) — UCI ML Repository**

- Source: [kaggle.com/datasets/uciml/student-alcohol-consumption](https://www.kaggle.com/datasets/uciml/student-alcohol-consumption)
- 395 students · 33 features · Target: G3 final grade (0–20)
- Features span four categories: demographic, socioeconomic, behavioural, and academic history
