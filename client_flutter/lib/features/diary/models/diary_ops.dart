library;

/// HBP v2 operation name constants for shua.diary module.
/// Auto-synced from _architecture/contracts/hbp/schema/hbp_diary.toml
/// DO NOT edit manually — update the TOML and re-run sync_contracts.

// ── Diary Entry ──────────────────────────────────────────────────────────────
const kDiaryEntryList   = 'shua.diary.entry.list';
const kDiaryEntryGet    = 'shua.diary.entry.get';
const kDiaryEntryCreate = 'shua.diary.entry.create';
const kDiaryEntrySave   = 'shua.diary.entry.save';
const kDiaryEntryDelete = 'shua.diary.entry.delete';

// ── Diary Block ───────────────────────────────────────────────────────────────
const kDiaryBlockSave    = 'shua.diary.block.save';
const kDiaryBlockReorder = 'shua.diary.block.reorder';
const kDiaryBlockDelete  = 'shua.diary.block.delete';

// ── Search & Utilities ────────────────────────────────────────────────────────
const kDiarySearch        = 'shua.diary.search';
const kDiaryMemoryElevate = 'shua.diary.memory.elevate';

// ── Events (server-pushed) ────────────────────────────────────────────────────
const kDiaryEntryUpdated = 'shua.diary.entry.updated';
const kDiarySentiment    = 'shua.diary.sentiment.score';

// ── Certification Roadmap (TASK-017B) ─────────────────────────────────────────
const kCertList     = 'shua.diary.cert.list';
const kCertGet      = 'shua.diary.cert.get';
const kCertSave     = 'shua.diary.cert.save';
const kCertDelete   = 'shua.diary.cert.delete';
const kCertReorder  = 'shua.diary.cert.reorder';
const kCertRoadmap  = 'shua.diary.cert.roadmap';
const kCertDashboard = 'shua.diary.cert.dashboard';
const kCertExpiringSoon = 'shua.diary.cert.expiring_soon';

const kCertResourceList   = 'shua.diary.cert.resource.list';
const kCertResourceSave   = 'shua.diary.cert.resource.save';
const kCertResourceDelete = 'shua.diary.cert.resource.delete';

const kCertProgressSave = 'shua.diary.cert.progress.save';
const kCertProgressGet  = 'shua.diary.cert.progress.get';

const kCertInvestmentList    = 'shua.diary.cert.investment.list';
const kCertInvestmentSave    = 'shua.diary.cert.investment.save';
const kCertInvestmentDelete  = 'shua.diary.cert.investment.delete';
const kCertInvestmentSummary = 'shua.diary.cert.investment.summary';
