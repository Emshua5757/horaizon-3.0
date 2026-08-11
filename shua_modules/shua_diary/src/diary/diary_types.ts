/**
 * shua_diary v3.0 — TypeScript DTOs
 *
 * Pure data shapes — zero business logic, zero SDUI references.
 * Maps directly to SQLite table columns and HBP v2 wire payloads.
 *
 * Naming convention: camelCase in TypeScript, snake_case in SQLite/wire.
 */

// ── diary_entries table ────────────────────────────────────────────────────

export interface DiaryEntry {
  id:                  string;        // UUID primary key
  userId:              string;        // 'shua'
  title:               string;        // display title
  isPrivate:           boolean;       // lock overlay if true
  aiProvider:          string;        // 'ollama' | 'gemini' | 'hybrid'
  lexoRank:            string;        // LexoRank ordering string
  preview:             string;        // first ~120 chars of body content
  moodScore:           number | null; // 1–10 float; null until AI analyzes
  energyScore:         number | null; // 1–10 float; null until AI analyzes
  isGloballyElevated:  boolean;       // pinned to top of entry list
  loggedAt:            string;        // ISO 8601 — when the entry "happened"
  createdAt:           string;        // ISO 8601
  updatedAt:           string;        // ISO 8601
}

// ── diary_blocks table ─────────────────────────────────────────────────────

/**
 * BlockType — string identifier for diary block types.
 * Stored in diary_blocks.block_type. Flutter renders the corresponding
 * DiaryBlockWidget subclass. No SDUI primitive mapping needed.
 *
 * See TASK-019 block type table for the full list of 36 block types.
 */
export type BlockType =
  | 'markdown'    | 'code'         | 'button'      | 'checkbox'
  | 'chip'        | 'container'    | 'grid'        | 'list_editor'
  | 'list_view'   | 'ordinal_slider' | 'slider'    | 'progress'
  | 'radio'       | 'shimmer'      | 'table'       | 'text_input'
  | 'toggle'      | 'heatmap'      | 'map'         | 'drawing'
  | 'audio'       | 'video'        | 'image'       | 'stl'
  | 'chart'       | 'gauge'        | 'timeline'    | 'document'
  | 'carousel'    | 'html'         | 'date_picker' | 'time_picker'
  | 'divider'     | 'spacer'       | 'expansion'   | 'wrap'
  | 'certification'; // embeds a CertEntry reference inline

export interface DiaryBlock {
  id:        string;           // UUID primary key
  entryId:   string;           // FK → diary_entries.id
  blockType: BlockType;        // content type — drives Flutter widget selection
  content:   string;           // JSON string; schema owned by Flutter block widget
  lexoRank:  string;           // sort order within the entry
  version:   number;           // optimistic lock — increment on every update
  createdAt: string;
  updatedAt: string;
}

/** Conflict response when optimistic lock version mismatches. */
export interface BlockConflictError {
  error:  'conflict';
  latest: DiaryBlock; // Server's current version for the client to refresh from
}

// ── Certification Roadmap (TASK-017B) ─────────────────────────────────────

export type CertStatus =
  | 'planned'        // Want to get this cert — not studying yet
  | 'studying'       // Actively grinding
  | 'exam_scheduled' // Exam is booked — crunch time
  | 'passed'         // Earned
  | 'failed'         // Failed — can reschedule
  | 'expired';       // Was earned, has now expired

export type ResourceType =
  | 'course'
  | 'practice_exam'
  | 'documentation'
  | 'video'
  | 'cheatsheet'
  | 'book';

export type InvestmentType =
  | 'exam_fee'
  | 'course'
  | 'book'
  | 'equipment'
  | 'other';

export interface CertEntry {
  id:                  string;
  userId:              string;
  name:                string;        // "AWS Solutions Architect — Associate (SAA-C03)"
  issuer:              string;        // "Amazon Web Services"
  examCode:            string;        // "SAA-C03"
  credentialId:        string;        // Issued credential ID (empty until passed)
  credentialUrl:       string;        // Credly / verify URL
  vaultDocHash:        string | null; // SHA256 of certificate PDF in governor vault

  status:              CertStatus;
  category:            string;        // 'aws' | 'devops' | 'security' | 'ai_ml' | 'general'
  roadmapOrder:        number;        // integer sort in timeline (1 = first to earn)

  // Exam scheduling
  examScheduledAt:     string | null; // ISO 8601 datetime of booked exam
  examRegistrationUrl: string;        // Pearson VUE / PSI link
  examVenue:           string;        // 'online_proctored' | 'test_center'

  // Dates
  studyStartedAt:      string | null; // When user started studying
  issuedAt:            string | null; // When cert was earned (null until passed)
  expiresAt:           string | null; // Expiry date (null = never expires)

  // Post-exam scoring
  passingScore:        number | null; // Required passing score (e.g. 720)
  achievedScore:       number | null; // Score user got

  notes:               string;
  createdAt:           string;
  updatedAt:           string;
}

export interface CertResource {
  id:             string;
  certId:         string;         // FK → cert_entries.id
  title:          string;         // "Stephane Maarek AWS SAA Course"
  url:            string;         // Link to grind
  type:           ResourceType;
  platform:       string;         // "Udemy" | "Tutorials Dojo" | "AWS Docs" etc.
  estimatedHours: number;         // Estimated hours to complete
  isFree:         boolean;
  cost:           number;         // Cost in PHP (0 if free)
  priority:       number;         // 1 = must-do, 2 = recommended, 3 = optional
  sortOrder:      number;         // Manual sort within cert resources
  createdAt:      string;
  updatedAt:      string;
}

export interface CertResourceProgress {
  id:                string;
  resourceId:        string;      // FK → cert_resources.id
  userId:            string;
  completedSections: number;      // Sections/chapters/questions done
  totalSections:     number;      // Total in the resource
  percentComplete:   number;      // 0–100 integer
  lastStudiedAt:     string | null;
  notes:             string;
  updatedAt:         string;
}

export interface CertInvestment {
  id:               string;
  certId:           string | null; // FK → cert_entries.id (null = general)
  userId:           string;
  description:      string;        // "SAA-C03 Exam Fee" | "Udemy Course" etc.
  type:             InvestmentType;
  amountPhp:        number;        // Amount in Philippine Peso
  paidAt:           string;        // ISO 8601 date
  receiptVaultHash: string | null; // SHA256 of receipt/invoice in governor vault
  notes:            string;
  createdAt:        string;
}

// ── Aggregated/computed shapes ─────────────────────────────────────────────

export interface CertProgressSummary {
  certId:               string;
  totalResources:       number;
  completedResources:   number;       // Resources at 100%
  avgProgressPercent:   number;       // Weighted average across all resources
  totalEstimatedHours:  number;       // Sum of all resource estimated_hours
  daysUntilExam:        number | null; // null if exam not scheduled
}

export interface InvestmentSummary {
  totalSpentPhp: number;
  byType:        Record<InvestmentType, number>;
  byCert:        Array<{ certId: string; certName: string; totalPhp: number }>;
}

export interface CertDashboardStats {
  totalCerts:             number;
  byStatus:               Record<CertStatus, number>;
  nextExam:               { cert: CertEntry; daysUntil: number } | null;
  totalInvestedPhp:       number;
  roadmap:                CertEntry[]; // Full ordered roadmap
}
