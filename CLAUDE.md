# PJ3 — Expense Tracker

Spring Boot 3.3 / Java 21 backend (`backend/`) + Flutter / Riverpod frontend (`frontend/`).

## Common Commands
- Backend verify (Spotless, Checkstyle, JUnit, JaCoCo): `mvn -f backend/pom.xml -B verify jacoco:report` *(requires JDK 21)*
- Backend format apply: `mvn -f backend/pom.xml spotless:apply`
- Flutter analyze: `cd frontend && flutter analyze`
- Flutter tests: `cd frontend && flutter test`
