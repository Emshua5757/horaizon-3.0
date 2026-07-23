# TASK-014 — C# ASP.NET Core Interview Prep Portal (shua_portal)

| Field | Value |
| :--- | :--- |
| **Status** | [ ] Not started |
| **Phase** | Phase 3 — Learning & Integration |
| **Type** | AI-executable + C# Practice |
| **Language** | C# (.NET 9) |
| **Target** | `shua_portal/` |
| **Blocks** | None |
| **Prerequisites** | .NET 9 SDK installed |

---

## Context

To master **ASP.NET Core** and C# concepts frequently asked in enterprise engineering interviews (e.g., Accenture), we are introducing a new backend service module: **`shua_portal`**. 

This module functions as an interactive **Interview Prep Simulator** integrated directly into the horAIzon 3.0 ecosystem. It allows you to practice coding ASP.NET Core patterns (Middleware, Dependency Injection, EF Core) by building them, while exposing an API that integrates with local Ollama to ask, record, and grade your technical answers.

---

## Technical Specifications

### 1. Architecture
* **Framework:** ASP.NET Core 9.0 Web API (Minimal APIs & Controller patterns)
* **Database:** SQLite via Entity Framework Core (EF Core) code-first migrations
* **Service Integrations:** Calls local Ollama API (`http://localhost:11434/api/generate`) to analyze answers

### 2. Core API Endpoints
* `GET /api/interview/questions` — Returns a list of mock interview questions covering ASP.NET Core concepts (e.g., Lifecycle, DI scope, Middleware pipeline).
* `POST /api/interview/submit` — Takes user's text answer, uses EF Core to persist the response, calls local Ollama with a grading prompt, and returns a detailed evaluation.
* `GET /api/interview/stats` — Aggregates progress metrics (average score, concepts mastered).

### 3. Key Concepts to Implement & Learn
* **Dependency Injection (DI):** Registering transient, scoped, and singleton services (`IInterviewService`, `IOllamaClient`, etc.).
* **Custom Middleware:** Write a custom logging middleware to log request latency to the console.
* **EF Core DbContext:** Configure SQLite db models, database seed data (preset questions), and migrations.

---

## Implementation Steps

### Step 1: Project Scaffolding
Scaffold the Web API project inside `shua_portal/`:
```powershell
dotnet new webapi -o shua_portal --use-program-main
```

### Step 2: EF Core & Database Setup
1. Add NuGet packages:
   * `Microsoft.EntityFrameworkCore.Sqlite`
   * `Microsoft.EntityFrameworkCore.Design`
2. Define `InterviewQuestion` and `UserResponse` db entities.
3. Configure `AppDbContext` and seed it with standard Accenture interview questions.
4. Run migrations to create the SQLite file.

### Step 3: Implement Services
1. Build `OllamaClient` to communicate with the local Ollama instance.
2. Build `InterviewService` to handle grading logic using an 8b model prompt template.
3. Register services in `Program.cs` utilizing correct lifetime scopes.

### Step 4: Controllers & Middleware
1. Build `InterviewController` exposing the required REST endpoints.
2. Implement a custom C# middleware class `RequestLoggingMiddleware` to inspect the ASP.NET request pipeline.

---

## Acceptance Criteria

- [ ] `dotnet build` succeeds in the `shua_portal` directory with zero errors
- [ ] Running the project launches a local server on port `5000` / `5001` (or dynamic port)
- [ ] Database automatically creates `shua_portal.db` SQLite file and runs seed migrations
- [ ] Calling `GET /api/interview/questions` returns seeded ASP.NET interview questions
- [ ] Calling `POST /api/interview/submit` with an answer queries Ollama and returns a score + critique
- [ ] Custom request latency middleware prints logs to terminal on each API request
