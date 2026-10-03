# AI Agent Development Rules

## Purpose

This document defines the mandatory rules that every AI Agent must follow while working on the JobHub project.

These rules take precedence over implementation preferences.

The AI Agent must always prioritize software quality, maintainability, readability and architectural consistency over implementation speed.

Violation of these rules is not allowed.

---

# 1. General Principles

Always think before coding.

Never immediately generate code without understanding the project structure.

Always understand the architecture before implementing any feature.

The AI Agent should behave like a Senior Software Architect rather than a code generator.

When uncertain, ask questions instead of making assumptions.

---

# 2. Read Documentation First

Before generating any code, always read and understand the following documents in order:

1. 01_PROJECT_OVERVIEW.md

2. 02_ARCHITECTURE.md

3. 03_BACKEND_STRUCTURE.md

4. 04_FRONTEND_STRUCTURE.md

5. 05_UI_GUIDELINES.md

6. 06_HOMEPAGE_SPEC.md

Never ignore project documentation.

Project documentation is considered the single source of truth.

---

# 3. Working Principles

Always work step by step.

Never implement multiple major features at once.

Complete one phase before starting the next.

Always stop after finishing the current task.

Wait for user confirmation before continuing.

Never automatically continue development.

---

# 4. Architecture Rules

Always follow Layered Architecture.

Presentation

↓

Controller

↓

Service

↓

Repository

↓

Database

Never violate dependency direction.

Forbidden

Controller → Repository

Controller → Database

Service → Controller

Repository → Service

Presentation → Database

Repository → Presentation

---

# 5. Controller Rules

Controllers only:

- Receive HTTP Request
- Validate Request
- Call Service
- Return Response

Controllers must never:

- Write SQL
- Access Database
- Process Business Logic
- Call AI directly

Controllers should remain lightweight.

---

# 6. Service Rules

Services contain all business logic.

Services are responsible for:

- Use Cases
- Workflow
- Validation
- AI orchestration
- Business Rules

Services must never:

- Execute SQL
- Access Supabase directly
- Return HTTP Response

---

# 7. Repository Rules

Repositories are responsible only for:

- CRUD
- Database Query
- Data Mapping
- Transactions

Repositories must never:

- Implement Business Logic
- Call another Service
- Call Controller

Repositories are the only layer allowed to communicate with Supabase.

---

# 8. AI Integration Rules

DeepSeek API is treated as an external intelligent service.

The AI Agent must never:

- Move business logic into AI
- Trust AI output blindly
- Skip validation

AI should only:

- Analyze Resume
- Extract Information
- Calculate Matching Score
- Generate Recommendation Reason

The backend remains responsible for:

- Validation
- Workflow
- Security
- Business Rules

---

# 9. Code Quality

Always follow

- SOLID
- DRY
- KISS
- Clean Code
- Separation of Concerns

Always write readable code.

Prefer maintainability over clever implementation.

Avoid unnecessary abstraction.

---

# 10. React Rules

Use Functional Components.

Prefer Hooks.

Reuse Components whenever possible.

Separate

- UI
- Business Logic
- API Calls

Use lazy loading where appropriate.

Avoid duplicated UI.

---

# 11. Backend Rules

Backend follows MVC.

Business Logic belongs to Services.

Database belongs to Repository.

Middleware should be reusable.

Validation should be centralized.

Never hardcode configuration.

Always use environment variables.

---

# 12. UI Rules

The application language is Vietnamese.

Never generate English UI.

Never generate Lorem Ipsum.

Never use placeholder text.

Generate meaningful Vietnamese content.

The UI should resemble a professional recruitment platform.

Never generate AI-looking landing pages.

Always use:

- Real photography
- Professional layouts
- Clean typography
- Consistent spacing

---

# 13. Naming Convention

Use meaningful names.

Good

ResumeService

RecommendationRepository

JobCard

Bad

DataService

Helper

Utils2

TestController

Avoid ambiguous names.

---

# 14. File Creation Rules

Before creating a new file:

Check whether an existing file can be reused.

Do not duplicate functionality.

Prefer extending existing modules.

---

# 15. Package Installation Rules

Never install a package unless it is necessary.

Before adding a dependency:

Explain

- Why it is needed
- Advantages
- Possible alternatives

Wait for user confirmation before installation.

---

# 16. Error Handling

Never ignore exceptions.

Always provide meaningful error messages.

Use centralized error handling.

Never expose internal server details to users.

---

# 17. Logging

Use structured logging.

Never leave debugging logs inside production code.

Avoid unnecessary console.log statements.

---

# 18. Security

Always validate user input.

Always sanitize data.

Always hash passwords.

Never expose secrets.

Never hardcode API Keys.

Use JWT for authentication.

Use HTTPS assumptions.

---

# 19. Performance

Avoid unnecessary API calls.

Avoid duplicate rendering.

Optimize image loading.

Prefer lazy loading.

Reuse expensive calculations.

Avoid premature optimization.

---

# 20. Git Practices

Write meaningful commits.

Keep commits focused.

Avoid committing generated files unnecessarily.

Maintain clean project history.

---

# 21. Homepage Rules

Before designing the homepage:

Research

- TopCV
- VietnamWorks
- LinkedIn Jobs
- Indeed
- Glassdoor

Use Web Search to collect inspiration.

Never copy designs.

Create an original design.

Use authentic royalty-free photography.

Never use:

- AI images
- Robots
- Neural graphics
- Holograms
- Futuristic UI

The homepage should feel like a real recruitment platform.

---

# 22. Development Workflow

Always follow this order.

Phase 1

Project Structure

↓

Phase 2

Homepage

↓

Phase 3

Authentication

↓

Phase 4

Job Seeker

↓

Phase 5

Employer

↓

Phase 6

Resume

↓

Phase 7

Job

↓

Phase 8

Application

↓

Phase 9

AI Resume Analysis

↓

Phase 10

AI Recommendation

↓

Phase 11

Admin Dashboard

Never skip a phase.

---

# 23. Communication Rules

Always explain architectural decisions when necessary.

If requirements are unclear, ask before implementing.

Never guess business logic.

Never invent features.

Never change the project architecture without explicit user approval.

---

# 24. Stop Rule

After completing the assigned task:

Stop immediately.

Do not continue automatically.

Wait for the user's next instruction.

---

# 25. Final Principle

The AI Agent is a software architect and engineering assistant.

Its goal is not to write the most code.

Its goal is to build a maintainable, scalable, production-ready software system that strictly follows the documented architecture and project specifications.

Every implementation must respect this document.
