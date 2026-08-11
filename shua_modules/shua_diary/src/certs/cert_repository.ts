import Database from 'better-sqlite3';
import {
  CertEntry, CertResource, CertResourceProgress, CertInvestment,
  CertProgressSummary, InvestmentSummary, CertDashboardStats, CertStatus, InvestmentType,
} from '../diary/diary_types';
import { logger, HBP_LOG_TAG } from '../lib/governor_logger';

/**
 * CertRepository — SQLite interactions for the Certification Roadmap (TASK-017B).
 *
 * Four tables: cert_entries, cert_resources, cert_resource_progress, cert_investments.
 * All share the same shua_diary.db database connection.
 *
 * Time Complexity: O(1) PK lookups. O(log N) indexed queries by status/expiry/order.
 * Space Complexity: O(C + R + P + I) for certs, resources, progress rows, investments.
 */
export class CertRepository {
  private db: Database.Database;

  constructor(db: Database.Database) {
    this.db = db;
    this._ensureSchema();
    logger.info('cert_repository', 'Certification schema verified', {
      tags: HBP_LOG_TAG.LIFECYCLE | HBP_LOG_TAG.DATABASE,
    });
  }

  // ── Schema ─────────────────────────────────────────────────────────────────

  private _ensureSchema(): void {
    this.db.exec(`
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

      CREATE TABLE IF NOT EXISTS cert_resources (
        id                TEXT PRIMARY KEY,
        cert_id           TEXT NOT NULL REFERENCES cert_entries(id) ON DELETE CASCADE,
        title             TEXT NOT NULL,
        url               TEXT NOT NULL,
        type              TEXT NOT NULL DEFAULT 'course',
        platform          TEXT NOT NULL DEFAULT '',
        estimated_hours   REAL NOT NULL DEFAULT 0,
        is_free           INTEGER NOT NULL DEFAULT 0,
        cost              REAL NOT NULL DEFAULT 0,
        priority          INTEGER NOT NULL DEFAULT 2,
        sort_order        INTEGER NOT NULL DEFAULT 0,
        created_at        TEXT NOT NULL,
        updated_at        TEXT NOT NULL
      );

      CREATE INDEX IF NOT EXISTS idx_resources_cert
        ON cert_resources(cert_id, sort_order);

      CREATE TABLE IF NOT EXISTS cert_resource_progress (
        id                  TEXT PRIMARY KEY,
        resource_id         TEXT NOT NULL REFERENCES cert_resources(id) ON DELETE CASCADE,
        user_id             TEXT NOT NULL DEFAULT 'shua',
        completed_sections  INTEGER NOT NULL DEFAULT 0,
        total_sections      INTEGER NOT NULL DEFAULT 0,
        percent_complete    INTEGER NOT NULL DEFAULT 0,
        last_studied_at     TEXT,
        notes               TEXT NOT NULL DEFAULT '',
        updated_at          TEXT NOT NULL,
        UNIQUE(resource_id, user_id)
      );

      CREATE TABLE IF NOT EXISTS cert_investments (
        id                  TEXT PRIMARY KEY,
        cert_id             TEXT REFERENCES cert_entries(id) ON DELETE SET NULL,
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
    `);
  }

  // ── Prepared statements ──────────────────────────────────────────────────

  private _stmts: Record<string, Database.Statement> = {};
  private stmt(name: string, sql: string): Database.Statement {
    if (!this._stmts[name]) this._stmts[name] = this.db.prepare(sql);
    return this._stmts[name];
  }

  // ── CertEntry CRUD ────────────────────────────────────────────────────────

  /** List all certs for a user, optionally filtered by status. O(log N). */
  listAll(userId: string, status?: CertStatus): CertEntry[] {
    if (status) {
      return (this.stmt('listByStatus',
        `SELECT * FROM cert_entries WHERE user_id = ? AND status = ? ORDER BY roadmap_order ASC`
      ).all(userId, status) as any[]).map(r => this._mapCert(r));
    }
    return (this.stmt('listAll',
      `SELECT * FROM cert_entries WHERE user_id = ? ORDER BY roadmap_order ASC`
    ).all(userId) as any[]).map(r => this._mapCert(r));
  }

  /** Get full ordered roadmap. O(C log C). */
  getRoadmap(userId: string): CertEntry[] {
    return (this.stmt('getRoadmap',
      `SELECT * FROM cert_entries WHERE user_id = ? ORDER BY roadmap_order ASC`
    ).all(userId) as any[]).map(r => this._mapCert(r));
  }

  /** Get the next upcoming exam (nearest future exam_scheduled_at). O(log N). */
  getNextExam(userId: string): CertEntry | null {
    const now = new Date().toISOString();
    const row = this.stmt('getNextExam',
      `SELECT * FROM cert_entries
       WHERE user_id = ? AND exam_scheduled_at IS NOT NULL AND exam_scheduled_at > ?
       ORDER BY exam_scheduled_at ASC LIMIT 1`
    ).get(userId, now) as any | undefined;
    return row ? this._mapCert(row) : null;
  }

  /** Get certs expiring within N days. O(log N) via idx_cert_exam_date. */
  getExpiringSoon(userId: string, withinDays: number): CertEntry[] {
    const now = new Date();
    const cutoff = new Date(now.getTime() + withinDays * 86400_000).toISOString();
    return (this.stmt('getExpiringSoon',
      `SELECT * FROM cert_entries
       WHERE user_id = ? AND expires_at IS NOT NULL AND expires_at > ? AND expires_at <= ?
       AND status = 'passed'
       ORDER BY expires_at ASC`
    ).all(userId, now.toISOString(), cutoff) as any[]).map(r => this._mapCert(r));
  }

  /** Get a single cert by ID. O(1). */
  getById(id: string): CertEntry | null {
    const row = this.stmt('certById', `SELECT * FROM cert_entries WHERE id = ?`).get(id) as any | undefined;
    return row ? this._mapCert(row) : null;
  }

  /**
   * Upsert a cert record. If id is new, inserts. If existing, updates.
   * Assigns next roadmap_order on create.
   */
  save(cert: Partial<CertEntry> & { userId: string; name: string; issuer: string }): CertEntry {
    const now = new Date().toISOString();
    const isNew = !cert.id || !this.getById(cert.id);

    if (isNew) {
      const id = cert.id ?? crypto.randomUUID();
      const nextOrder = this._nextRoadmapOrder(cert.userId);

      this.stmt('insertCert', `
        INSERT INTO cert_entries(
          id, user_id, name, issuer, exam_code, credential_id, credential_url,
          vault_doc_hash, status, category, roadmap_order,
          exam_scheduled_at, exam_registration_url, exam_venue,
          study_started_at, issued_at, expires_at,
          passing_score, achieved_score, notes, created_at, updated_at
        ) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)
      `).run(
        id, cert.userId, cert.name, cert.issuer,
        cert.examCode ?? '', cert.credentialId ?? '', cert.credentialUrl ?? '',
        cert.vaultDocHash ?? null,
        cert.status ?? 'planned', cert.category ?? 'general',
        cert.roadmapOrder ?? nextOrder,
        cert.examScheduledAt ?? null, cert.examRegistrationUrl ?? '', cert.examVenue ?? 'online_proctored',
        cert.studyStartedAt ?? null, cert.issuedAt ?? null, cert.expiresAt ?? null,
        cert.passingScore ?? null, cert.achievedScore ?? null,
        cert.notes ?? '',
        now, now,
      );

      logger.info('cert_repository', `Cert created: ${id}`, { tags: HBP_LOG_TAG.DATABASE });
      return this.getById(id)!;
    }

    // Update existing
    this.stmt('updateCert', `
      UPDATE cert_entries SET
        name = ?, issuer = ?, exam_code = ?, credential_id = ?, credential_url = ?,
        vault_doc_hash = ?, status = ?, category = ?, roadmap_order = ?,
        exam_scheduled_at = ?, exam_registration_url = ?, exam_venue = ?,
        study_started_at = ?, issued_at = ?, expires_at = ?,
        passing_score = ?, achieved_score = ?, notes = ?,
        updated_at = ?
      WHERE id = ?
    `).run(
      cert.name, cert.issuer,
      cert.examCode ?? '', cert.credentialId ?? '', cert.credentialUrl ?? '',
      cert.vaultDocHash ?? null,
      cert.status ?? 'planned', cert.category ?? 'general',
      cert.roadmapOrder,
      cert.examScheduledAt ?? null, cert.examRegistrationUrl ?? '', cert.examVenue ?? 'online_proctored',
      cert.studyStartedAt ?? null, cert.issuedAt ?? null, cert.expiresAt ?? null,
      cert.passingScore ?? null, cert.achievedScore ?? null,
      cert.notes ?? '',
      now, cert.id,
    );

    logger.info('cert_repository', `Cert updated: ${cert.id}`, { tags: HBP_LOG_TAG.DATABASE });
    return this.getById(cert.id!)!;
  }

  /** Delete a cert (CASCADE deletes resources, progress, clears investment cert_id). */
  delete(id: string): void {
    this.stmt('deleteCert', `DELETE FROM cert_entries WHERE id = ?`).run(id);
    logger.info('cert_repository', `Cert deleted: ${id}`, { tags: HBP_LOG_TAG.DATABASE });
  }

  /** Bulk update roadmap_order by ordered certId array. O(C) updates. */
  reorder(userId: string, certIds: string[]): void {
    const update = this.db.prepare(`UPDATE cert_entries SET roadmap_order = ? WHERE id = ? AND user_id = ?`);
    const tx = this.db.transaction(() => {
      certIds.forEach((id, idx) => update.run(idx, id, userId));
    });
    tx();
    logger.info('cert_repository', `Roadmap reordered for user ${userId}`, {
      tags: HBP_LOG_TAG.DATABASE, telemetry: { count: certIds.length },
    });
  }

  // ── Dashboard Stats ───────────────────────────────────────────────────────

  getDashboardStats(userId: string): CertDashboardStats {
    const all = this.listAll(userId);
    const byStatus = {} as Record<CertStatus, number>;
    const statuses: CertStatus[] = ['planned', 'studying', 'exam_scheduled', 'passed', 'failed', 'expired'];
    for (const s of statuses) byStatus[s] = 0;
    for (const c of all) byStatus[c.status] = (byStatus[c.status] ?? 0) + 1;

    const nextExamCert = this.getNextExam(userId);
    const nextExam = nextExamCert
      ? {
          cert: nextExamCert,
          daysUntil: Math.ceil(
            (new Date(nextExamCert.examScheduledAt!).getTime() - Date.now()) / 86400_000
          ),
        }
      : null;

    const totalInvestedPhp = this._sumInvestments(userId);

    return {
      totalCerts: all.length,
      byStatus,
      nextExam,
      totalInvestedPhp,
      roadmap: all,
    };
  }

  private _sumInvestments(userId: string): number {
    const row = this.stmt('sumInvestments',
      `SELECT COALESCE(SUM(amount_php), 0) as total FROM cert_investments WHERE user_id = ?`
    ).get(userId) as { total: number };
    return row.total;
  }

  // ── CertResource CRUD ─────────────────────────────────────────────────────

  listResources(certId: string): CertResource[] {
    return (this.stmt('listResources',
      `SELECT * FROM cert_resources WHERE cert_id = ? ORDER BY sort_order ASC`
    ).all(certId) as any[]).map(r => this._mapResource(r));
  }

  saveResource(resource: Partial<CertResource> & { certId: string; title: string; url: string }): CertResource {
    const now = new Date().toISOString();
    const isNew = !resource.id || !(this.stmt('getResourceById',
      `SELECT id FROM cert_resources WHERE id = ?`
    ).get(resource.id));

    const id = resource.id ?? crypto.randomUUID();

    if (isNew) {
      const nextOrder = (this.stmt('maxResourceOrder',
        `SELECT COALESCE(MAX(sort_order), -1) as m FROM cert_resources WHERE cert_id = ?`
      ).get(resource.certId) as { m: number }).m + 1;

      this.stmt('insertResource', `
        INSERT INTO cert_resources(id, cert_id, title, url, type, platform, estimated_hours, is_free, cost, priority, sort_order, created_at, updated_at)
        VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?)
      `).run(
        id, resource.certId, resource.title, resource.url,
        resource.type ?? 'course', resource.platform ?? '',
        resource.estimatedHours ?? 0, resource.isFree ? 1 : 0, resource.cost ?? 0,
        resource.priority ?? 2, resource.sortOrder ?? nextOrder, now, now,
      );
    } else {
      this.stmt('updateResource', `
        UPDATE cert_resources SET title=?, url=?, type=?, platform=?, estimated_hours=?,
          is_free=?, cost=?, priority=?, sort_order=?, updated_at=?
        WHERE id=?
      `).run(
        resource.title, resource.url, resource.type ?? 'course', resource.platform ?? '',
        resource.estimatedHours ?? 0, resource.isFree ? 1 : 0, resource.cost ?? 0,
        resource.priority ?? 2, resource.sortOrder ?? 0, now, id,
      );
    }

    return this._mapResource(this.stmt('getResource', `SELECT * FROM cert_resources WHERE id = ?`).get(id) as any);
  }

  deleteResource(resourceId: string): void {
    this.stmt('deleteResource', `DELETE FROM cert_resources WHERE id = ?`).run(resourceId);
  }

  reorderResources(certId: string, resourceIds: string[]): void {
    const update = this.db.prepare(`UPDATE cert_resources SET sort_order = ? WHERE id = ? AND cert_id = ?`);
    const tx = this.db.transaction(() => {
      resourceIds.forEach((id, idx) => update.run(idx, id, certId));
    });
    tx();
  }

  // ── CertResourceProgress ──────────────────────────────────────────────────

  getProgress(resourceId: string, userId: string): CertResourceProgress | null {
    const row = this.stmt('getProgress',
      `SELECT * FROM cert_resource_progress WHERE resource_id = ? AND user_id = ?`
    ).get(resourceId, userId) as any | undefined;
    return row ? this._mapProgress(row) : null;
  }

  saveProgress(progress: Partial<CertResourceProgress> & { resourceId: string; userId: string }): CertResourceProgress {
    const now = new Date().toISOString();
    const id = progress.id ?? crypto.randomUUID();

    this.stmt('upsertProgress', `
      INSERT INTO cert_resource_progress(id, resource_id, user_id, completed_sections, total_sections, percent_complete, last_studied_at, notes, updated_at)
      VALUES (?,?,?,?,?,?,?,?,?)
      ON CONFLICT(resource_id, user_id) DO UPDATE SET
        completed_sections = excluded.completed_sections,
        total_sections = excluded.total_sections,
        percent_complete = excluded.percent_complete,
        last_studied_at = excluded.last_studied_at,
        notes = excluded.notes,
        updated_at = excluded.updated_at
    `).run(
      id, progress.resourceId, progress.userId,
      progress.completedSections ?? 0, progress.totalSections ?? 0,
      progress.percentComplete ?? 0,
      progress.lastStudiedAt ?? now, progress.notes ?? '', now,
    );

    logger.info('cert_repository', `Progress updated: resource ${progress.resourceId}`, {
      tags: HBP_LOG_TAG.DATABASE,
      telemetry: { percent: progress.percentComplete },
    });

    return this.getProgress(progress.resourceId, progress.userId)!;
  }

  /** Compute aggregated cert progress across all resources. */
  getCertTotalProgress(certId: string, userId: string): CertProgressSummary {
    const resources = this.listResources(certId);
    const cert = this.getById(certId);

    if (resources.length === 0) {
      return {
        certId, totalResources: 0, completedResources: 0,
        avgProgressPercent: 0, totalEstimatedHours: 0, daysUntilExam: null,
      };
    }

    let totalHours = 0;
    let weightedSum = 0;
    let completedCount = 0;

    for (const r of resources) {
      const prog = this.getProgress(r.id, userId);
      const pct = prog?.percentComplete ?? 0;
      totalHours += r.estimatedHours;
      weightedSum += pct * r.estimatedHours; // weight by estimated hours
      if (pct >= 100) completedCount++;
    }

    const avgPct = totalHours > 0 ? Math.round(weightedSum / totalHours) : 0;

    let daysUntilExam: number | null = null;
    if (cert?.examScheduledAt) {
      daysUntilExam = Math.ceil((new Date(cert.examScheduledAt).getTime() - Date.now()) / 86400_000);
    }

    return {
      certId,
      totalResources: resources.length,
      completedResources: completedCount,
      avgProgressPercent: avgPct,
      totalEstimatedHours: totalHours,
      daysUntilExam,
    };
  }

  // ── CertInvestment CRUD ───────────────────────────────────────────────────

  listInvestments(userId: string, certId?: string): CertInvestment[] {
    if (certId) {
      return (this.stmt('investmentsByCert',
        `SELECT * FROM cert_investments WHERE user_id = ? AND cert_id = ? ORDER BY paid_at DESC`
      ).all(userId, certId) as any[]).map(r => this._mapInvestment(r));
    }
    return (this.stmt('allInvestments',
      `SELECT * FROM cert_investments WHERE user_id = ? ORDER BY paid_at DESC`
    ).all(userId) as any[]).map(r => this._mapInvestment(r));
  }

  saveInvestment(inv: Partial<CertInvestment> & { userId: string; description: string; amountPhp: number; paidAt: string }): CertInvestment {
    const now = new Date().toISOString();
    const id = inv.id ?? crypto.randomUUID();

    const exists = inv.id && (this.stmt('getInvestById',
      `SELECT id FROM cert_investments WHERE id = ?`
    ).get(inv.id));

    if (!exists) {
      this.stmt('insertInvestment', `
        INSERT INTO cert_investments(id, cert_id, user_id, description, type, amount_php, paid_at, receipt_vault_hash, notes, created_at)
        VALUES (?,?,?,?,?,?,?,?,?,?)
      `).run(
        id, inv.certId ?? null, inv.userId, inv.description,
        inv.type ?? 'exam_fee', inv.amountPhp, inv.paidAt,
        inv.receiptVaultHash ?? null, inv.notes ?? '', now,
      );
    } else {
      this.stmt('updateInvestment', `
        UPDATE cert_investments SET cert_id=?, description=?, type=?, amount_php=?, paid_at=?, receipt_vault_hash=?, notes=?
        WHERE id=?
      `).run(inv.certId ?? null, inv.description, inv.type ?? 'exam_fee', inv.amountPhp, inv.paidAt, inv.receiptVaultHash ?? null, inv.notes ?? '', id);
    }

    logger.info('cert_repository', `Investment saved: ₱${inv.amountPhp} — ${inv.description}`, {
      tags: HBP_LOG_TAG.DATABASE,
      telemetry: { amount_php: inv.amountPhp, type: inv.type },
    });

    return this._mapInvestment(
      this.stmt('getInvestmentById', `SELECT * FROM cert_investments WHERE id = ?`).get(id) as any
    );
  }

  deleteInvestment(id: string): void {
    this.stmt('deleteInvestment', `DELETE FROM cert_investments WHERE id = ?`).run(id);
  }

  getInvestmentSummary(userId: string): InvestmentSummary {
    const all = this.listInvestments(userId);

    const byType = {} as Record<InvestmentType, number>;
    const typeKeys: InvestmentType[] = ['exam_fee', 'course', 'book', 'equipment', 'other'];
    for (const t of typeKeys) byType[t] = 0;

    const byCertMap = new Map<string, { certName: string; total: number }>();
    let total = 0;

    for (const inv of all) {
      total += inv.amountPhp;
      byType[inv.type] = (byType[inv.type] ?? 0) + inv.amountPhp;

      if (inv.certId) {
        if (!byCertMap.has(inv.certId)) {
          const cert = this.getById(inv.certId);
          byCertMap.set(inv.certId, { certName: cert?.name ?? 'Unknown', total: 0 });
        }
        byCertMap.get(inv.certId)!.total += inv.amountPhp;
      }
    }

    return {
      totalSpentPhp: total,
      byType,
      byCert: Array.from(byCertMap.entries()).map(([certId, v]) => ({
        certId, certName: v.certName, totalPhp: v.total,
      })),
    };
  }

  // ── Private mappers ───────────────────────────────────────────────────────

  private _mapCert(r: any): CertEntry {
    return {
      id: r.id, userId: r.user_id, name: r.name, issuer: r.issuer,
      examCode: r.exam_code, credentialId: r.credential_id, credentialUrl: r.credential_url,
      vaultDocHash: r.vault_doc_hash ?? null,
      status: r.status as CertStatus, category: r.category, roadmapOrder: r.roadmap_order,
      examScheduledAt: r.exam_scheduled_at ?? null, examRegistrationUrl: r.exam_registration_url,
      examVenue: r.exam_venue, studyStartedAt: r.study_started_at ?? null,
      issuedAt: r.issued_at ?? null, expiresAt: r.expires_at ?? null,
      passingScore: r.passing_score ?? null, achievedScore: r.achieved_score ?? null,
      notes: r.notes, createdAt: r.created_at, updatedAt: r.updated_at,
    };
  }

  private _mapResource(r: any): CertResource {
    return {
      id: r.id, certId: r.cert_id, title: r.title, url: r.url,
      type: r.type, platform: r.platform, estimatedHours: Number(r.estimated_hours),
      isFree: r.is_free === 1, cost: Number(r.cost), priority: r.priority,
      sortOrder: r.sort_order, createdAt: r.created_at, updatedAt: r.updated_at,
    };
  }

  private _mapProgress(r: any): CertResourceProgress {
    return {
      id: r.id, resourceId: r.resource_id, userId: r.user_id,
      completedSections: r.completed_sections, totalSections: r.total_sections,
      percentComplete: r.percent_complete, lastStudiedAt: r.last_studied_at ?? null,
      notes: r.notes, updatedAt: r.updated_at,
    };
  }

  private _mapInvestment(r: any): CertInvestment {
    return {
      id: r.id, certId: r.cert_id ?? null, userId: r.user_id,
      description: r.description, type: r.type as InvestmentType,
      amountPhp: Number(r.amount_php), paidAt: r.paid_at,
      receiptVaultHash: r.receipt_vault_hash ?? null,
      notes: r.notes, createdAt: r.created_at,
    };
  }

  private _nextRoadmapOrder(userId: string): number {
    const row = this.stmt('maxRoadmapOrder',
      `SELECT COALESCE(MAX(roadmap_order), -1) as m FROM cert_entries WHERE user_id = ?`
    ).get(userId) as { m: number };
    return row.m + 1;
  }
}
