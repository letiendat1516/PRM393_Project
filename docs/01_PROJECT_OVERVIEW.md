# JobHub Project Overview

## 1. Project Introduction

**JobHub** is an AI-powered recruitment platform designed to connect job seekers with employers through intelligent resume analysis and job recommendation.

Unlike traditional recruitment websites that rely only on keyword matching, JobHub integrates Artificial Intelligence to understand a candidate's professional profile and recommend the most suitable job opportunities based on their skills, experience, education, and career objectives.

The primary goal of the project is to simplify the recruitment process for both candidates and employers while improving matching accuracy and reducing manual screening time.

---

# 2. Business Objectives

JobHub aims to solve several common problems in online recruitment.

For Job Seekers:

- Difficult to find suitable jobs among thousands of postings.
- Resume information is often underutilized.
- Lack of personalized job recommendations.
- Time-consuming application process.

For Employers:

- Large number of unqualified applications.
- Manual resume screening is expensive and time-consuming.
- Difficulty identifying the best candidates quickly.

JobHub uses AI-assisted resume analysis and intelligent job matching to improve recruitment efficiency.

---

# 3. Target Users

The system supports three primary user roles.

## Job Seeker

A candidate looking for suitable employment opportunities.

Main responsibilities:

- Register account
- Login
- Manage personal profile
- Upload Resume (PDF)
- Receive AI resume analysis
- Search jobs
- Receive AI job recommendations
- Apply for jobs
- Track application status

---

## Employer

A company or recruiter searching for qualified candidates.

Main responsibilities:

- Register company account
- Manage company profile
- Create job postings
- Update job postings
- View applicants
- Review applications
- Approve or reject candidates

---

## Administrator

Responsible for system administration.

Main responsibilities:

- Manage user accounts
- Manage employer accounts
- Manage job postings
- Monitor system activities
- View reports and statistics

---

# 4. Project Scope

The current project includes:

- Authentication
- User management
- Employer management
- Resume management
- AI Resume Analysis
- Job management
- Job search
- AI Job Recommendation
- Job application
- Company management
- Administration dashboard

The project focuses on building a scalable web application following Layered Architecture and MVC.

---

# 5. Core Features

## Authentication

- Register
- Login
- JWT Authentication
- Password Encryption
- Forgot Password
- Change Password

---

## Resume Management

- Upload Resume (PDF)
- Update Resume
- Delete Resume
- Store Resume

---

## AI Resume Analysis

After uploading a resume, the system sends the document to an AI model.

The AI extracts structured information including:

- Technical Skills
- Soft Skills
- Education
- Work Experience
- Certifications
- Languages
- Career Objective

The extracted information is stored inside the database for future job matching.

---

## Job Management

Employers can:

- Create Jobs
- Edit Jobs
- Delete Jobs
- Close Jobs
- View Applicants

---

## Job Search

Job Seekers can search jobs using filters:

- Keyword
- Company
- Salary
- Location
- Experience
- Job Category
- Remote / Hybrid / Onsite
- Employment Type

---

## AI Job Recommendation

The recommendation process consists of two phases.

### Phase 1

Rule-based filtering.

The system filters candidate jobs based on predefined conditions such as location, salary, work type, required skills, and experience.

### Phase 2

AI Matching.

The filtered job list is analyzed by AI together with the candidate profile.

The AI evaluates:

- Skill Matching
- Experience Matching
- Education Matching
- Semantic Similarity
- Overall Suitability

Finally, the AI returns:

- Matching Score
- Recommendation Reason
- Missing Skills
- Strengths
- Suggested Improvements

---

## Job Application

Candidates can:

- Apply for jobs
- Select resume
- Submit application
- Track application status

---

## Administration

Administrators can:

- Manage users
- Manage employers
- Manage jobs
- Monitor activities
- View statistics

---

# 6. Technology Stack

## Frontend

- ReactJS
- Vite
- React Router
- TailwindCSS
- Axios
- Framer Motion

---

## Backend

- NodeJS
- ExpressJS

---

## Database

Supabase PostgreSQL

Supabase is used only as the relational database.

Authentication is implemented manually using JWT.

---

## AI

DeepSeek API

The AI is responsible for:

- Resume Information Extraction
- Intelligent Job Recommendation

Business logic always remains inside the backend.

The AI acts only as an intelligent analysis service.

---

# 7. Software Architecture

The project follows MVC combined with Layered Architecture.

Presentation Layer

↓

Controller Layer

↓

Service Layer

↓

Repository Layer

↓

Supabase PostgreSQL

Each layer has a single responsibility.

Business logic is isolated inside the Service Layer.

Database access is isolated inside the Repository Layer.

---

# 8. Development Principles

The project follows the following engineering principles.

- SOLID
- Separation of Concerns
- Clean Code
- Layered Architecture
- MVC Pattern
- Repository Pattern
- Reusable Components
- Modular Design

---

# 9. Future Enhancements

The architecture is designed for future scalability.

Potential future features include:

- AI Interview Assistant
- Resume Optimization
- AI Career Advisor
- Company Recommendation
- Interview Scheduling
- Notification System
- Email Service
- Real-time Chat
- Mobile Application

---

# 10. Development Goal

The objective is not only to develop a working recruitment platform but also to establish a maintainable, scalable, production-ready architecture suitable for enterprise software development.

Every feature should be built following software engineering best practices, emphasizing maintainability, extensibility, and code quality.
