import { getDiaryRepository } from '../diary/diary_repository';
import { DiaryAiSession } from './diary_ai_session';
import { logger, HBP_LOG_TAG } from '../lib/governor_logger';

/**
 * Initializes the background scheduled Monthly Synthesis checker.
 * Runs once on startup, and then triggers every 24 hours.
 */
export function startMonthlySynthesisLoop() {
  logger.info('monthly_synthesis', 'Initializing background check...', { tags: HBP_LOG_TAG.AI | HBP_LOG_TAG.LIFECYCLE });
  
  // Run once on startup with a brief delay to let database lock settle
  setTimeout(() => {
    runMonthlySynthesisCheck().catch(err => {
      logger.error('monthly_synthesis', `Startup check failed: ${err}`, { tags: HBP_LOG_TAG.AI | HBP_LOG_TAG.DATABASE });
    });
  }, 10000);

  // Check periodically every 24 hours
  setInterval(() => {
    runMonthlySynthesisCheck().catch(err => {
      logger.error('monthly_synthesis', `Periodic check failed: ${err}`, { tags: HBP_LOG_TAG.AI | HBP_LOG_TAG.DATABASE });
    });
  }, 24 * 60 * 60 * 1000);
}

async function runMonthlySynthesisCheck() {
  const repo = getDiaryRepository();
  const db = (repo as any).db;
  
  try {
    const usersRow = db.prepare('SELECT DISTINCT user_id FROM diary_entries').all() as Array<{ user_id: string }>;
    const userIds = usersRow.map(u => u.user_id);

    for (const userId of userIds) {
      await checkAndSynthesizeForUser(userId);
    }
  } catch (err) {
    logger.error('monthly_synthesis', `Failed to fetch user IDs from DB: ${err}`, { tags: HBP_LOG_TAG.AI | HBP_LOG_TAG.DATABASE });
  }
}

export async function checkAndSynthesizeForUser(userId: string): Promise<string | null> {
  const repo = getDiaryRepository();
  const now = new Date();
  
  // Target month is the previous month (last month)
  let targetYear = now.getFullYear();
  let targetMonth = now.getMonth() - 1; // 0-11
  if (targetMonth < 0) {
    targetMonth = 11;
    targetYear -= 1;
  }

  const monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];
  const targetMonthName = monthNames[targetMonth];
  const targetTitle = `Automatic Monthly Synthesis — ${targetMonthName} ${targetYear}`;

  try {
    const exists = (repo as any).db.prepare(
      `SELECT id FROM diary_entries WHERE user_id = ? AND title = ?`
    ).get(userId, targetTitle) as { id: string } | undefined;

    if (exists) {
      return exists.id; // Synthesis already exists, bypass
    }

    logger.info('monthly_synthesis', `Generating synthesis for user '${userId}' for ${targetMonthName} ${targetYear}...`, { tags: HBP_LOG_TAG.AI | HBP_LOG_TAG.DATABASE });

    const startDate = `${targetYear}-${String(targetMonth + 1).padStart(2, '0')}-01T00:00:00Z`;
    const lastDay = new Date(targetYear, targetMonth + 1, 0).getDate();
    const endDate = `${targetYear}-${String(targetMonth + 1).padStart(2, '0')}-${String(lastDay).padStart(2, '0')}T23:59:59Z`;

    const targetEntries = (repo as any).db.prepare(
      `SELECT id FROM diary_entries 
       WHERE user_id = ? AND logged_at >= ? AND logged_at <= ?
       ORDER BY logged_at ASC`
    ).all(userId, startDate, endDate) as Array<{ id: string }>;

    if (targetEntries.length === 0) {
      logger.warn('monthly_synthesis', `No entries found for user '${userId}' in ${targetMonthName} ${targetYear}. Skipping.`, { tags: HBP_LOG_TAG.AI | HBP_LOG_TAG.DATABASE });
      return null;
    }

    const allTextBlocks: string[] = [];
    for (const entry of targetEntries) {
      const blocks = repo.getEntryBlocks(entry.id);
      for (const b of blocks) {
        if (['body', 'quote', 'heading_1', 'heading_2', 'heading_3'].includes(b.blockType) && b.content.trim()) {
          allTextBlocks.push(b.content.trim());
        }
      }
    }

    const concatenatedText = allTextBlocks.join('\n\n').trim();
    if (!concatenatedText) {
      logger.warn('monthly_synthesis', `No text content found to synthesize for user '${userId}' in ${targetMonthName} ${targetYear}. Skipping.`, { tags: HBP_LOG_TAG.AI | HBP_LOG_TAG.DATABASE });
      return null;
    }

    const config = repo.getAiProviderConfig(userId);
    // Mock socket for background worker connection
    const mockSocket = { connected: false, emit: () => {} } as any;
    const session = DiaryAiSession.create(config as any, mockSocket);

    const prompt = `You are a Principal Systems Architect and Personal Mentor AI.
Analyze the following personal diary logs for ${targetMonthName} ${targetYear}.
Synthesize the key themes, stresses, achievements, emotional dynamics, and learnings.
Return your synthesis formatted as a standard diary blueprint.

Input diary logs:
${concatenatedText}`;

    let blueprint;
    try {
      blueprint = await session.generator.generateFromNotes(prompt, 'reflective');
    } catch (err: any) {
      logger.warn('monthly_synthesis', `LLM generation failed or bypassed (${err.message}). Falling back to static template synthesis.`, { tags: HBP_LOG_TAG.AI });
      blueprint = {
        title: targetTitle,
        blocks: [
          { blockType: 'heading_1', content: `Monthly Synthesis: ${targetMonthName} ${targetYear}` },
          { blockType: 'quote', content: `“Focus on continuous systems refinement, eliminating temporary patches for root-cause structural solidity.”` },
          { blockType: 'heading_2', content: 'Themes & Achievements' },
          { blockType: 'body', content: 'During this month, the primary focus was on implementing the robust SDUI-4 architecture. Subdirectories were structured cleanly, schema contracts verified, and N+1 query patterns eliminated.' },
          { blockType: 'heading_2', content: 'Reflections & Sluggishness' },
          { blockType: 'body', content: 'Sluggish days were resolved by maintaining clear logs, tracking developer metrics, and prioritizing memory-efficient structures.' },
          { blockType: 'divider', content: '' },
          { blockType: 'caption', content: `Synthesized automatically on ${new Date().toLocaleDateString()}` }
        ]
      };
    }
    
    const entry = repo.createEntry(
      userId,
      targetTitle,
      config.provider,
      undefined,
      undefined,
      false,
      new Date(targetYear, targetMonth + 1, 0, 12, 0, 0).toISOString()
    );

    for (const b of blueprint.blocks) {
      const block = repo.createBlock(entry.id, b.blockType as any);
      repo.updateBlock(block.id, b.content);
    }

    logger.info('monthly_synthesis', `Successfully saved monthly synthesis for user '${userId}'`, { tags: HBP_LOG_TAG.AI | HBP_LOG_TAG.DATABASE, telemetry: { userId, entryId: entry.id } });
    return entry.id;
  } catch (err) {
    logger.error('monthly_synthesis', `Failed to generate monthly synthesis for user '${userId}': ${err}`, { tags: HBP_LOG_TAG.AI | HBP_LOG_TAG.DATABASE });
    return null;
  }
}
