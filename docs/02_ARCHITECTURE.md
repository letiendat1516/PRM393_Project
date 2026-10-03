# JobHub Software Architecture

## 1. Architecture Overview

JobHub is designed following **MVC (Model-View-Controller)** combined with **Layered Architecture**.

The primary objective of this architecture is to separate responsibilities clearly, reduce coupling, improve maintainability, and support future scalability.

Every layer has a single responsibility and communicates only with the layer immediately below it.

The architecture follows the principle of **Separation of Concerns (SoC)**.

---

# 2. Layered Architecture

The application consists of five logical layers.

```
Presentation Layer

↓

Controller Layer

↓

Service Layer

↓

Repository Layer

↓

Database Layer
```

Dependency flows only from top to bottom.

Lower layers must never depend on upper layers.

---

# 3. Layer Responsibilities

---

## 3.1 Presentation Layer

The Presentation Layer is responsible for interacting with end users.

Technology

- ReactJS
- React Router
- TailwindCSS

Responsibilities

- Display user interface
- Handle user interaction
- Validate simple client-side inputs
- Send HTTP requests to backend
- Display server responses
- Manage page navigation
- Manage local UI state

Presentation Layer MUST NOT

- Execute business logic
- Connect directly to the database
- Call AI services directly
- Handle authentication logic
- Perform data processing

The Presentation Layer communicates only through REST APIs.

---

## 3.2 Controller Layer

Controllers act as the entry point of every HTTP request.

Responsibilities

- Receive HTTP Request
- Validate Request
- Call appropriate Service
- Return HTTP Response
- Handle status codes
- Convert data between HTTP and application objects

Controllers MUST NOT

- Write SQL
- Access Database
- Implement business logic
- Call Repository directly
- Process AI logic

Example

```
Client

↓

JobController

↓

JobService
```

Controllers should remain lightweight.

---

## 3.3 Service Layer

The Service Layer contains the application's business logic.

This is the heart of the system.

Responsibilities

- Implement business rules
- Execute use cases
- Coordinate workflows
- Call Repository
- Call AI services
- Process application logic
- Validate business conditions
- Transform data

Service Layer communicates with

- Repository Layer
- External AI Service
- Utility Services

Services MUST NOT

- Execute SQL
- Receive HTTP Requests
- Return HTTP Responses
- Know UI implementation

Service modules

- AuthService
- JobSeekerService
- EmployerService
- ResumeService
- JobService
- ApplicationService
- RecommendationService

---

## 3.4 Repository Layer

The Repository Layer is responsible for all database operations.

Responsibilities

- CRUD
- Database Query
- Transaction
- Mapping data

Repository communicates only with

Supabase PostgreSQL

Repositories MUST NOT

- Process business logic
- Validate business rules
- Call another Service
- Call Controller

Repositories are the only layer allowed to access the database.

Repository modules

- AuthRepository
- JobSeekerRepository
- EmployerRepository
- ResumeRepository
- JobRepository
- ApplicationRepository
- RecommendationRepository

---

## 3.5 Database Layer

Technology

Supabase PostgreSQL

Responsibilities

- Store application data
- Execute SQL
- Maintain relationships
- Ensure data integrity

Supabase Authentication is NOT used.

Authentication is implemented inside the backend using JWT.

---

# 4. External Services

JobHub integrates external services.

Current external services

- DeepSeek API
- Email Service (future)

These services are treated as Infrastructure.

Business logic must always remain inside the Service Layer.

The AI is responsible only for intelligent analysis.

The backend always controls:

- Workflow
- Validation
- Data persistence
- Business decisions

---

# 5. AI Workflow

Resume Analysis

```
Upload Resume

↓

ResumeController

↓

ResumeService

↓

DeepSeek API

↓

Structured Resume

↓

ResumeRepository

↓

Database
```

Job Recommendation

```
Candidate Request

↓

RecommendationController

↓

RecommendationService

↓

Repository

↓

Candidate Profile

↓

Filtered Jobs

↓

DeepSeek API

↓

Matching Result

↓

RecommendationService

↓

Response
```

AI never communicates directly with the database.

AI never receives raw SQL.

---

# 6. Dependency Rules

Allowed

```
Presentation

↓

Controller

↓

Service

↓

Repository

↓

Database
```

Forbidden

```
Controller

↓

Database
```

```
Presentation

↓

Repository
```

```
Service

↓

Controller
```

```
Repository

↓

Service
```

```
Repository

↓

Presentation
```

```
Controller

↓

AI
```

All dependencies must flow downward.

---

# 7. Package Responsibilities

Controllers

```
controllers/

AuthController

JobController

EmployerController

ResumeController

ApplicationController

RecommendationController
```

Responsibilities

- HTTP only

---

Services

```
services/

AuthService

JobService

ResumeService

RecommendationService
...
```

Responsibilities

- Business Logic

---

Repositories

```
repositories/

AuthRepository

ResumeRepository

JobRepository
...
```

Responsibilities

- Database Access

---

# 8. Design Principles

The project follows

- MVC Pattern
- Layered Architecture
- Repository Pattern
- SOLID Principles
- DRY
- KISS
- Separation of Concerns
- Single Responsibility Principle
- Dependency Inversion Principle

---

# 9. Communication Rules

Every request must follow this flow.

```
Client

↓

REST API

↓

Controller

↓

Service

↓

Repository

↓

Supabase

↓

Repository

↓

Service

↓

Controller

↓

Client
```

No shortcut is allowed.

---

# 10. Coding Rules

Controllers

✔ Validate Request

✔ Call Service

✔ Return Response

❌ No Business Logic

❌ No Database Query

---

Services

✔ Business Logic

✔ AI Workflow

✔ Validation

✔ Workflow

❌ No SQL

❌ No HTTP Response

---

Repositories

✔ CRUD

✔ Query

✔ Transaction

❌ No Business Logic

---

# 11. Scalability

The architecture must support future modules without changing existing modules.

Future extensions

- Notification Service
- AI Interview
- Resume Optimization
- AI Career Advisor
- Payment
- Subscription
- Chat
- Mobile Application

New modules must follow the same layered architecture.

---

# 12. Architecture Goals

The architecture is designed to achieve the following goals.

- Maintainability
- Scalability
- Low Coupling
- High Cohesion
- Testability
- Reusability
- Readability
- Production Readiness

Every new feature added to JobHub must comply with this architecture document.

Violation of the architecture is not allowed.
