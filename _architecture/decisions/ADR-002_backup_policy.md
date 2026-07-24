# ADR-002: Disaster Recovery & Automated Snapshot Backup Policy

| Field | Value |
| :--- | :--- |
| **Status** | Approved |
| **Date** | 2026-07-24 |
| **Deciders** | Joshua B. Ygot, horAIzon Core Team |
| **Replaces** | None (New ADR) |

---

## Context and Problem Statement

horAIzon 3.0 runs as an always-on personal AI operating system on a Raspberry Pi 5. Key persistent state includes:
1. `shua_diary.db` (Personal journal entries, LexoRank block data, FTS5 index)
2. `/var/lib/horaizon/media/` (Content-addressable deduplicated photo/video vault)
3. `activity.db` (Centralized telemetry logs and audit trails)
4. `shua_resume.db` (Resume matrix records and past compilation history)
5. `shua_crypto.db` (Encrypted secret key vault)

SD cards and SSD storage on always-on single-board computers carry a non-zero failure rate. Losing diary memories or cryptographic vault records due to hardware failure is unacceptable.

---

## Decision Drivers

- Zero data loss for personal diary entries, media files, and secret vaults.
- Automated, hands-free operation integrated into the existing `shua_governor` Dream Loop scheduler.
- Minimal bandwidth and CPU overhead on Pi 5.
- Atomic SQLite snapshot creation without stopping active microservices.

---

## Considered Options

1. **Manual File Copies**: Copying files manually via SCP when remembered (High risk of human error).
2. **Real-time Master/Replica Database Replication**: Litestream / rqlite streaming (High memory and network complexity).
3. **Automated Nightly Snapshot & Encrypted Archive Sync (Chosen)**: Live `VACUUM INTO` snapshots + compressed Zstd archive synced via Tailscale to MSI laptop / cloud object store.

---

## Decision Outcome

Option 3 is chosen: **Automated Nightly Snapshot & Encrypted Archive Sync**.

### Backup Execution Flow (`shua_governor` Dream Loop Job 5)

Every night at **03:00 AM Asia/Manila**:

```
[ Dream Loop Scheduler ]
           │
           ▼
1. Live SQLite Snapshots
   - shua_diary.db  ──► VACUUM INTO '/tmp/backups/diary_snapshot.db'
   - activity.db    ──► VACUUM INTO '/tmp/backups/activity_snapshot.db'
   - shua_resume.db ──► VACUUM INTO '/tmp/backups/resume_snapshot.db'
           │
           ▼
2. Archive Compression & Encryption
   - Tar & Zstd compress '/tmp/backups/' + '/var/lib/horaizon/media/'
   - Encrypt archive: 'horaizon_backup_YYYYMMDD.tar.zst.enc'
           │
           ▼
3. Multi-Target Backup Sync
   - Primary: Synced over Tailscale to MSI Laptop dev directory
   - Secondary (Optional): Synced to Cloud Restic / S3 bucket
           │
           ▼
4. Maintenance Purge
   - Retain last 14 daily backup archives on Pi 5 / Laptop
   - Remove temporary files from '/tmp/backups/'
```

---

## Consequences

### Positive
- **Guaranteed Disaster Recovery**: If Pi 5 storage fails, all entries, media, and keys can be restored in <5 minutes.
- **Zero Downtime**: `VACUUM INTO` creates atomic, consistent SQLite snapshots without locking or stopping running microservices.
- **Zero Extra Daemon Tax**: Managed entirely by `shua_governor`'s existing Tokio scheduler.

### Negative
- Requires transient disk space on Pi 5 (`/tmp/backups/`) during archive creation (~200–500MB).
