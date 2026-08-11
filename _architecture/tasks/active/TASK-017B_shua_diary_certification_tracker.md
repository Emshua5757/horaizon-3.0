# TASK-017B — `shua_diary` Certification Roadmap Schema & API

| Field | Value |
| :--- | :--- |
| **Status** | [ ] Not started |
| **Phase** | Phase 3 |
| **Type** | AI-executable |
| **Language** | TypeScript (Node.js — extension of TASK-017) |
| **Target** | `shua_modules/shua_diary/src/certs/` |
| **Blocks** | TASK-019B (Flutter Certification Roadmap Screen) |
| **Prerequisites** | TASK-017 (`shua_diary` base backend running), ADR-001 |
| **References** | `_architecture/decisions/ADR-001_native_over_sdui.md`, `_architecture/contracts/hbp/hbp_v2_spec.md` |

---

## Why This Task Exists

The user is actively investing in AWS and DevOps certifications — funded by data annotation income. This is not just a record-keeper: it's a **personal exam investment & learning roadmap engine**.

The system must answer these questions at a glance:

1. **Where am I on the roadmap?** — Timeline of planned → in-progress → earned certs
2. **When is my next exam?** — Scheduled exam date, registration link, countdown
3. **What do I need to grind?** — Curated study resource links with progress tracking
4. **How much have I invested?** — Exam fees + course costs vs. total spent
5. **Am I on track?** — Daily study progress toward the exam date

This requires **four relational tables**: `cert_entries`, `cert_resources`, `cert_resource_progress`, and `cert_investments`.

---

## Full Data Model

### 1. `CertEntry` — The Certification Record

```typescript
export interface CertEntry {
  id: string;               // UUID PK
  userId: string;           // 'shua'
  name: string;             // "AWS Solutions Architect — Associate (SAA-C03)"
  issuer: string;           // "Amazon Web Services"
  examCode: string;         // "SAA-C03"
  credentialId: string;     // Issued credential ID (empty until passed)
  credentialUrl: string;    // Credly / verify URL (empty until passed)
  vaultDocHash: string | null; // SHA256 of certificate PDF in governor vault

  status: CertStatus;       // 'planned' | 'studying' | 'exam_scheduled' | 'passed' | 'failed' | 'expired'
  category: string;         // 'aws' | 'devops' | 'security' | 'ai_ml' | 'general'
  roadmapOrder: number;     // Integer sort order in the timeline (1 = first to earn)

  // Exam scheduling
  examScheduledAt: string | null;  // ISO 8601 datetime of booked exam
  examRegistrationUrl: string;     // Pearson VUE / PSI / etc. registration link
  examVenue: string;               // 'online_proctored' | 'test_center'

  // Dates
  studyStartedAt: string | null;   // When user started studying
  issuedAt: string | null;         // Date cert was earned (null until passed)
  expiresAt: string | null;        // Expiry date (null = never expires)

  // Scoring (filled in after exam)
  passingScore: number | null;     // Required passing score (e.g. 720/1000)
  achievedScore: number | null;    // Score user got

  notes: string;            // Free-form notes: exam tips, lessons learned

  createdAt: string;
  updatedAt: string;
}

export type CertStatus =
  | 'planned'          // Want to get this cert — not studying yet
  | 'studying'         // Actively grinding for this cert
  | 'exam_scheduled'   // Exam is booked — crunch time
  | 'passed'           // Earned
  | 'failed'           // Failed — can reschedule
  | 'expired';         // Was earned, has now expired
```

---

### 2. `CertResource` — Study Resources to Grind

One cert has many resources (courses, practice tests, docs, YouTube playlists, cheat sheets).

```typescript
export interface CertResource {
  id: string;             // UUID PK
  certId: string;         // FK → cert_entries.id ON DELETE CASCADE
  title: string;          // "Stephane Maarek AWS SAA Course"
  url: string;            // Link to grind
  type: ResourceType;     // 'course' | 'practice_exam' | 'documentation' | 'video' | 'cheatsheet' | 'book'
  platform: string;       // "Udemy" | "Tutorials Dojo" | "AWS Docs" | "YouTube" | "A Cloud Guru" | etc.
  estimatedHours: number; // Estimated study time to complete
  isFree: boolean;        // Free resource or paid
  cost: number;           // Cost in PHP (0 if free)
  priority: number;       // 1 = must-do, 2 = recommended, 3 = optional
  sortOrder: number;      // Manual sort within cert resources
  createdAt: string;
  updatedAt: string;
}

export type ResourceType = 'course' | 'practice_exam' | 'documentation' | 'video' | 'cheatsheet' | 'book';
```

---

### 3. `CertResourceProgress` — Per-Resource Study Progress

```typescript
export interface CertResourceProgress {
  id: string;             // UUID PK
  resourceId: string;     // FK → cert_resources.id ON DELETE CASCADE
  userId: string;
  completedSections: number;  // Number of sections/chapters/questions done
  totalSections: number;      // Total sections/chapters/questions in the resource
  percentComplete: number;    // 0–100 integer (computed or manually entered)
  lastStudiedAt: string;      // ISO 8601 datetime of last study session
  notes: string;              // Notes on this resource (e.g. "section 4 is dense, review again")
  updatedAt: string;
}
```

---

### 4. `CertInvestment` — Financial Tracking

```typescript
export interface CertInvestment {
  id: string;             // UUID PK
  certId: string | null;  // FK → cert_entries.id (null = general investment, e.g. laptop)
  userId: string;
  description: string;    // "SAA-C03 Exam Fee" | "Udemy Course — Stephane Maarek" | etc.
  type: InvestmentType;   // 'exam_fee' | 'course' | 'book' | 'equipment' | 'other'
  amountPhp: number;      // Amount in Philippine Peso (your working currency)
  paidAt: string;         // ISO 8601 date
  receiptVaultHash: string | null; // SHA256 of receipt/invoice in governor vault (optional)
  notes: string;
  createdAt: string;
}

export type InvestmentType = 'exam_fee' | 'course' | 'book' | 'equipment' | 'other';

// Summary computed by repo
export interface InvestmentSummary {
  totalSpentPhp: number;
  byType: Record<InvestmentType, number>;
  byCert: Array<{ certId: string; certName: string; totalPhp: number }>;
}
```

---

## SQLite Schema (`shua_diary.db` — added to `DiaryRepository._ensureSchema`)

```sql
-- Core certification records
CREATE TABLE IF NOT EXISTS cert_entries (
  id                    TEXT PRIMARY KEY,
  user_id               TEXT NOT NULL DEFAULT 'shua',
  name                  TEXT NOT NULL,
  issuer                TEXT NOT NULL,
  exam_code             TEXT NOT NULL DEFAULT '',
  credential_id         TEXT NOT NULL DEFAULT '',
  credential_url        TEXT NOT NULL DEFAULT '',
  vault_doc_hash        TEXT,
  status                TEXT NOT NULL DEFAULT 'planned',
  category              TEXT NOT NULL DEFAULT 'general',
  roadmap_order         INTEGER NOT NULL DEFAULT 0,
  exam_scheduled_at     TEXT,
  exam_registration_url TEXT NOT NULL DEFAULT '',
  exam_venue            TEXT NOT NULL DEFAULT 'online_proctored',
  study_started_at      TEXT,
  issued_at             TEXT,
  expires_at            TEXT,
  passing_score         REAL,
  achieved_score        REAL,
  notes                 TEXT NOT NULL DEFAULT '',
  created_at            TEXT NOT NULL,
  updated_at            TEXT NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_cert_user_order
  ON cert_entries(user_id, roadmap_order);
CREATE INDEX IF NOT EXISTS idx_cert_status
  ON cert_entries(user_id, status);
CREATE INDEX IF NOT EXISTS idx_cert_exam_date
  ON cert_entries(exam_scheduled_at);

-- Study resources per cert
CREATE TABLE IF NOT EXISTS cert_resources (
  id                TEXT PRIMARY KEY,
  cert_id           TEXT NOT NULL REFERENCES cert_entries(id) ON DELETE CASCADE,
  title             TEXT NOT NULL,
  url               TEXT NOT NULL,
  type              TEXT NOT NULL DEFAULT 'course',
  platform          TEXT NOT NULL DEFAULT '',
  estimated_hours   REAL NOT NULL DEFAULT 0,
  is_free           INTEGER NOT NULL DEFAULT 0,
  cost              REAL NOT NULL DEFAULT 0,    -- PHP
  priority          INTEGER NOT NULL DEFAULT 2,  -- 1=must 2=recommended 3=optional
  sort_order        INTEGER NOT NULL DEFAULT 0,
  created_at        TEXT NOT NULL,
  updated_at        TEXT NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_resources_cert
  ON cert_resources(cert_id, sort_order);

-- Study progress per resource
CREATE TABLE IF NOT EXISTS cert_resource_progress (
  id                  TEXT PRIMARY KEY,
  resource_id         TEXT NOT NULL REFERENCES cert_resources(id) ON DELETE CASCADE,
  user_id             TEXT NOT NULL DEFAULT 'shua',
  completed_sections  INTEGER NOT NULL DEFAULT 0,
  total_sections      INTEGER NOT NULL DEFAULT 0,
  percent_complete    INTEGER NOT NULL DEFAULT 0,   -- 0–100
  last_studied_at     TEXT,
  notes               TEXT NOT NULL DEFAULT '',
  updated_at          TEXT NOT NULL,
  UNIQUE(resource_id, user_id)
);

-- Financial investment tracking
CREATE TABLE IF NOT EXISTS cert_investments (
  id                  TEXT PRIMARY KEY,
  cert_id             TEXT REFERENCES cert_entries(id) ON DELETE SET NULL,  -- nullable
  user_id             TEXT NOT NULL DEFAULT 'shua',
  description         TEXT NOT NULL,
  type                TEXT NOT NULL DEFAULT 'exam_fee',
  amount_php          REAL NOT NULL,
  paid_at             TEXT NOT NULL,
  receipt_vault_hash  TEXT,
  notes               TEXT NOT NULL DEFAULT '',
  created_at          TEXT NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_investments_user
  ON cert_investments(user_id, paid_at DESC);
CREATE INDEX IF NOT EXISTS idx_investments_cert
  ON cert_investments(cert_id);
```

**Time Complexity**: All primary lookups O(1) by PK. Roadmap timeline query O(C log C) sorted by `roadmap_order`. Investment summary O(I) where I = investment count.
**Space Complexity**: O(C + R + P + I) where C = certs, R = resources, P = progress rows, I = investments.

---

## `cert_repository.ts` — Full API

```typescript
export class CertRepository {
  // --- CertEntry CRUD ---
  listAll(userId: string): CertEntry[];
  listByStatus(userId: string, status: CertStatus): CertEntry[];
  getRoadmap(userId: string): CertEntry[];            // Ordered by roadmap_order ASC
  getNextExam(userId: string): CertEntry | null;      // Nearest exam_scheduled_at in future
  getById(id: string): CertEntry | undefined;
  save(cert: Partial<CertEntry>): CertEntry;          // Upsert by id
  delete(id: string): void;
  reorder(userId: string, certIds: string[]): void;   // Bulk update roadmap_order

  // --- CertResource CRUD ---
  listResources(certId: string): CertResource[];
  saveResource(resource: Partial<CertResource>): CertResource;
  deleteResource(resourceId: string): void;
  reorderResources(resourceIds: string[]): void;

  // --- CertResourceProgress ---
  getProgress(resourceId: string, userId: string): CertResourceProgress | null;
  saveProgress(progress: Partial<CertResourceProgress>): CertResourceProgress;
  getCertTotalProgress(certId: string, userId: string): CertProgressSummary;

  // --- CertInvestment CRUD ---
  listInvestments(userId: string): CertInvestment[];
  listInvestmentsByCert(certId: string): CertInvestment[];
  saveInvestment(inv: Partial<CertInvestment>): CertInvestment;
  deleteInvestment(investmentId: string): void;
  getInvestmentSummary(userId: string): InvestmentSummary;

  // --- Dashboard/Stats ---
  getDashboardStats(userId: string): CertDashboardStats;
  getExpiringSoon(userId: string, withinDays: number): CertEntry[];
}

export interface CertProgressSummary {
  certId: string;
  totalResources: number;
  completedResources: number;        // Resources at 100%
  avgProgressPercent: number;        // Weighted average across all resources
  totalEstimatedHours: number;       // Sum of all resource estimated_hours
  totalStudiedHours: number;         // Computed from progress × estimated_hours
  daysUntilExam: number | null;      // null if exam not scheduled
}

export interface CertDashboardStats {
  totalCerts: number;
  byStatus: Record<CertStatus, number>;
  nextExam: { cert: CertEntry; daysUntil: number } | null;
  totalInvestedPhp: number;
  activeStudyHoursThisWeek: number;  // From last_studied_at logs this week
  roadmap: CertEntry[];              // Full ordered roadmap
}
```

---

## HBP v2 RPC Operations (`diary.cert.*` namespace)

| Operation | Direction | Payload | Response |
| :--- | :--- | :--- | :--- |
| `diary.cert.list` | C → S | `{ user_id, status? }` | `CertEntry[]` |
| `diary.cert.get` | C → S | `{ cert_id }` | `{ cert: CertEntry, resources: CertResource[], progress: CertProgressSummary }` |
| `diary.cert.save` | C → S | `CertEntry` (partial) | `CertEntry` |
| `diary.cert.delete` | C → S | `{ cert_id }` | `{ ok: true }` |
| `diary.cert.reorder` | C → S | `{ cert_ids: string[] }` | `{ ok: true }` |
| `diary.cert.roadmap` | C → S | `{ user_id }` | `CertEntry[]` (ordered) |
| `diary.cert.dashboard` | C → S | `{ user_id }` | `CertDashboardStats` |
| `diary.cert.expiring_soon` | C → S | `{ user_id, within_days }` | `CertEntry[]` |
| `diary.cert.resource.list` | C → S | `{ cert_id }` | `CertResource[]` |
| `diary.cert.resource.save` | C → S | `CertResource` (partial) | `CertResource` |
| `diary.cert.resource.delete` | C → S | `{ resource_id }` | `{ ok: true }` |
| `diary.cert.progress.save` | C → S | `CertResourceProgress` (partial) | `CertResourceProgress` |
| `diary.cert.progress.get` | C → S | `{ cert_id, user_id }` | `CertProgressSummary` |
| `diary.cert.investment.list` | C → S | `{ user_id }` | `CertInvestment[]` |
| `diary.cert.investment.save` | C → S | `CertInvestment` (partial) | `CertInvestment` |
| `diary.cert.investment.delete` | C → S | `{ investment_id }` | `{ ok: true }` |
| `diary.cert.investment.summary` | C → S | `{ user_id }` | `InvestmentSummary` |

---

## `certification` Block Type (Diary Integration)

A diary entry can embed a cert reference as a `certification` block type.

**`content` JSON schema** (stored in `diary_blocks.content`):

```json
{
  "cert_id": "uuid",
  "display_mode": "card" | "badge" | "progress_card"
}
```

- `card` — Full card: name, status chip, exam date countdown, progress bar
- `badge` — Compact: icon + name + status only
- `progress_card` — Shows study progress breakdown (resources %, days until exam)

**Example use cases**:
- "Passed SAA-C03!" diary entry → embeds cert in `badge` mode
- "Study session log" diary entry → embeds cert in `progress_card` mode to log today's progress
- Weekly review entry → embeds roadmap cert in `card` mode showing exam countdown

---

## Dream Loop Hooks

Add to `shua_diary` server startup to register nightly jobs with governor:

```typescript
await governorLogger.registerDreamLoopJob({
  jobId: 'cert_expiry_check',
  schedule: 'nightly',
  op: 'diary.cert.expiring_soon',
  params: { user_id: 'shua', within_days: 30 }
});

await governorLogger.registerDreamLoopJob({
  jobId: 'cert_exam_countdown',
  schedule: 'nightly',
  op: 'diary.cert.dashboard',
  params: { user_id: 'shua' }
  // Governor logs a warn! if nextExam.daysUntil <= 7
});
```

---

## Acceptance Criteria

- [ ] All 4 tables (`cert_entries`, `cert_resources`, `cert_resource_progress`, `cert_investments`) exist with correct schema
- [ ] All indexes exist for efficient roadmap + exam date + investment queries
- [ ] `CertRepository` implements all methods with zero compiler warnings
- [ ] All 17 `diary.cert.*` RPC operations respond with correct MessagePack payloads
- [ ] `diary.cert.roadmap` returns certs in `roadmap_order` ASC — user's visual timeline order
- [ ] `diary.cert.dashboard` returns correct `nextExam` (nearest future `exam_scheduled_at`)
- [ ] `diary.cert.progress.get` computes `avgProgressPercent` as weighted average across resources
- [ ] `diary.cert.investment.summary` sums correctly by cert and by type
- [ ] `certification` block type registered in TASK-017 `diary_types.ts`
- [ ] Telemetry logs emitted for all state changes
- [ ] `0` TypeScript compiler errors or warnings
