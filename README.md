# Biddyan

**Biddyan - Academic, Admission & Job Preparation Platform**

Biddyan is a Bengali-first preparation platform for academic, admission, BCS,
bank, and government job examinations. It includes a Flutter client, a
TypeScript/Express API, PostgreSQL persistence, and Redis-powered leaderboards.

## Features

- OTP and social-login demo flows
- Exam categories and study sections
- Full-page exam experience with all questions shown vertically
- MCQ answer selection with negative marking
- Result analytics with score, rank, correct/wrong counts, and marks
- Read-only answer review with colored correct and incorrect options
- Hierarchical topic management
- Admin question creation
- PostgreSQL-backed exam and question APIs
- Redis-backed real-time leaderboards

## Project structure

```text
backend/   Express + TypeScript API
devops/    Docker Compose, database schema, and Nginx configuration
frontend/  Flutter Web, Android, and iOS client
```

## Run the Flutter client

```powershell
cd frontend
flutter pub get
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:5000/api
```

If the backend is unavailable, the frontend uses local demo data. For the
offline OTP flow, use:

```text
123456
```

## Run the backend

```powershell
cd backend
npm install
npm run build
npm start
```

The API listens on port `5000` by default. The Flutter client connects to
`http://localhost:5000/api` during local development. For a deployed API, pass
a different value with
`--dart-define=API_BASE_URL=https://your-domain/api`.

## Run the full stack with Docker

```powershell
docker compose -f devops/docker-compose.yml up --build
```

Configure database, Redis, and JWT values through environment variables in your
deployment environment. Never commit credentials or `.env` files.

## Validation

```powershell
cd frontend
flutter analyze
flutter test
```

## License

This project is currently maintained as a private application project.
