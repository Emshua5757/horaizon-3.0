# -*- coding: utf-8 -*-
import sys, io
# Force UTF-8 on Windows terminals that default to cp1252
if sys.stdout.encoding and sys.stdout.encoding.lower() != 'utf-8':
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', errors='replace')
    sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding='utf-8', errors='replace')

"""
shua_diary DB Debug CLI
-----------------------
Interactive REPL for inspecting, editing, and resetting shua_diary.db.

Usage:
    python db_debug.py

WARNING: Operates directly on the live SQLite file. Stop the Node.js 
orchestrator before running destructive commands (delete/reset) to avoid
WAL journal conflicts with better-sqlite3's exclusive write lock.
"""

import sqlite3
import os
import sys
import textwrap
from datetime import datetime, timezone

DB_PATH = os.path.join(os.path.dirname(__file__), 'data', 'shua_diary.db')

# ─── ANSI colour helpers ──────────────────────────────────────────────────────
RESET  = "\033[0m"
BOLD   = "\033[1m"
RED    = "\033[91m"
GREEN  = "\033[92m"
YELLOW = "\033[93m"
CYAN   = "\033[96m"
DIM    = "\033[2m"

def c(text, color): return f"{color}{text}{RESET}"
def header(text):   print(f"\n{BOLD}{CYAN}{'='*60}{RESET}\n{BOLD}{CYAN}  {text}{RESET}\n{BOLD}{CYAN}{'='*60}{RESET}")
def ok(msg):        print(f"{GREEN}[OK]{RESET} {msg}")
def warn(msg):      print(f"{YELLOW}[!!]{RESET} {msg}")
def err(msg):       print(f"{RED}[XX]{RESET} {msg}")


# ─── DB helpers ───────────────────────────────────────────────────────────────

def get_conn() -> sqlite3.Connection:
    """Returns a WAL-aware connection. Read-safe while Node.js is running."""
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    conn.execute("PRAGMA journal_mode=WAL")
    conn.execute("PRAGMA foreign_keys=ON")
    return conn


def now_iso() -> str:
    return datetime.now(timezone.utc).strftime('%Y-%m-%dT%H:%M:%SZ')


# ─── Commands ─────────────────────────────────────────────────────────────────

def cmd_list_entries(conn):
    """List all diary entries."""
    header("Diary Entries")
    rows = conn.execute(
        "SELECT id, user_id, title, logged_at, mood_score, is_globally_elevated, is_private "
        "FROM diary_entries ORDER BY lexo_rank ASC"
    ).fetchall()
    if not rows:
        warn("No entries found.")
        return
    for i, r in enumerate(rows):
        mood = f"{r['mood_score']:.2f}" if r['mood_score'] is not None else "null"
        flags = []
        if r['is_private']:         flags.append("PRIVATE")
        if r['is_globally_elevated']: flags.append("ELEVATED")
        flag_str = f"  {c('[' + ', '.join(flags) + ']', YELLOW)}" if flags else ""
        print(f"  {c(str(i+1), BOLD)}. {c(r['id'], DIM)}")
        print(f"     Title   : {c(r['title'], CYAN)}{flag_str}")
        print(f"     User    : {r['user_id']}   Logged: {r['logged_at']}   Mood: {mood}")
    print()


def cmd_list_blocks(conn, entry_id=None):
    """List all blocks for a given entry (or all blocks)."""
    header("Diary Blocks")
    if entry_id:
        rows = conn.execute(
            "SELECT id, entry_id, block_type, sort_order, lexo_rank, substr(content, 1, 60) as preview "
            "FROM diary_blocks WHERE entry_id=? ORDER BY lexo_rank ASC",
            (entry_id,)
        ).fetchall()
    else:
        rows = conn.execute(
            "SELECT id, entry_id, block_type, sort_order, lexo_rank, substr(content, 1, 60) as preview "
            "FROM diary_blocks ORDER BY entry_id, lexo_rank ASC"
        ).fetchall()

    if not rows:
        warn("No blocks found.")
        return
    for r in rows:
        print(f"  {c(r['id'], DIM)}")
        print(f"    Entry  : {r['entry_id']}")
        print(f"    Type   : {c(r['block_type'], YELLOW)}  Sort: {r['sort_order']}  Rank: {r['lexo_rank']}")
        print(f"    Content: {r['preview'] or c('(empty)', DIM)}")
    print()


def cmd_pick_entry(conn) -> str | None:
    """Interactive entry picker. Returns entry_id or None."""
    rows = conn.execute("SELECT id, title FROM diary_entries ORDER BY lexo_rank ASC").fetchall()
    if not rows:
        warn("No entries available.")
        return None
    print()
    for i, r in enumerate(rows):
        print(f"  {c(str(i+1), BOLD)}. [{r['id'][:8]}...]  {r['title']}")
    choice = input("  Select entry # (or paste UUID): ").strip()
    if not choice:
        return None
    if choice.isdigit():
        idx = int(choice) - 1
        if 0 <= idx < len(rows):
            return rows[idx]['id']
        err("Index out of range.")
        return None
    # Treat as UUID
    match = conn.execute("SELECT id FROM diary_entries WHERE id=?", (choice,)).fetchone()
    return match['id'] if match else None


def cmd_edit_title(conn):
    """Rename the title of a diary entry."""
    header("Edit Entry Title")
    entry_id = cmd_pick_entry(conn)
    if not entry_id:
        return
    new_title = input("  New title: ").strip()
    if not new_title:
        warn("Aborted — empty title.")
        return
    conn.execute(
        "UPDATE diary_entries SET title=?, updated_at=? WHERE id=?",
        (new_title, now_iso(), entry_id)
    )
    conn.commit()
    ok(f"Title updated → \"{new_title}\"")


def cmd_edit_block_content(conn):
    """Edit the text content of a specific block."""
    header("Edit Block Content")
    entry_id = cmd_pick_entry(conn)
    if not entry_id:
        return
    blocks = conn.execute(
        "SELECT id, block_type, substr(content,1,80) as preview FROM diary_blocks WHERE entry_id=? ORDER BY lexo_rank ASC",
        (entry_id,)
    ).fetchall()
    if not blocks:
        warn("No blocks in this entry.")
        return
    for i, b in enumerate(blocks):
        print(f"  {c(str(i+1), BOLD)}. [{b['block_type']}]  {b['preview'] or c('(empty)', DIM)}")
    choice = input("  Select block #: ").strip()
    if not choice.isdigit() or not (1 <= int(choice) <= len(blocks)):
        warn("Invalid selection.")
        return
    block_id = blocks[int(choice) - 1]['id']
    print("  Enter new content (single line, Ctrl+Z to abort):")
    new_content = input("  > ").strip()
    conn.execute(
        "UPDATE diary_blocks SET content=?, updated_at=? WHERE id=?",
        (new_content, now_iso(), block_id)
    )
    # Refresh preview on parent entry
    conn.execute(
        "UPDATE diary_entries SET preview=substr(?,1,120), updated_at=? WHERE id=?",
        (new_content, now_iso(), entry_id)
    )
    conn.commit()
    ok(f"Block updated.")


def cmd_delete_entry(conn):
    """Delete a diary entry and all its blocks (CASCADE)."""
    header("Delete Entry")
    warn("This is DESTRUCTIVE. Blocks for this entry will also be deleted via CASCADE.")
    entry_id = cmd_pick_entry(conn)
    if not entry_id:
        return
    confirm = input(f"  Type YES to confirm deletion of {c(entry_id, RED)}: ").strip()
    if confirm != "YES":
        warn("Aborted.")
        return
    conn.execute("DELETE FROM diary_entries WHERE id=?", (entry_id,))
    conn.commit()
    ok(f"Entry {entry_id} deleted.")


def cmd_reset_all(conn):
    """Nuclear reset: wipes ALL entries and blocks."""
    header("RESET ALL DATA")
    warn("This will DELETE every diary entry and block. There is NO undo.")
    confirm = input("  Type RESET to confirm: ").strip()
    if confirm != "RESET":
        warn("Aborted.")
        return
    conn.execute("DELETE FROM diary_blocks")
    conn.execute("DELETE FROM diary_entries")
    conn.commit()
    ok("All diary data wiped.")


def cmd_add_entry(conn):
    """Insert a quick test entry directly into the DB."""
    header("Add Test Entry")
    title = input("  Entry title [Test Entry]: ").strip() or "Test Entry"
    user_id = input("  User ID [default]: ").strip() or "default"

    # Simple LexoRank: append after last
    last = conn.execute(
        "SELECT lexo_rank FROM diary_entries WHERE user_id=? ORDER BY lexo_rank DESC LIMIT 1",
        (user_id,)
    ).fetchone()
    rank = (last['lexo_rank'] + '0') if last else '0|hzzzzz:'

    import uuid
    entry_id = str(uuid.uuid4())
    ts = now_iso()
    conn.execute(
        "INSERT INTO diary_entries(id, user_id, title, lexo_rank, logged_at, created_at, updated_at) VALUES (?,?,?,?,?,?,?)",
        (entry_id, user_id, title, rank, ts, ts, ts)
    )
    conn.commit()
    ok(f"Entry created: {entry_id}")


def cmd_set_mood(conn):
    """Manually set mood_score on an entry (useful for heatmap testing)."""
    header("Set Mood Score")
    entry_id = cmd_pick_entry(conn)
    if not entry_id:
        return
    raw = input("  Mood score (-1.0 to 1.0): ").strip()
    try:
        score = float(raw)
        assert -1.0 <= score <= 1.0
    except (ValueError, AssertionError):
        err("Invalid score. Must be a float in [-1.0, 1.0].")
        return
    conn.execute(
        "UPDATE diary_entries SET mood_score=?, updated_at=? WHERE id=?",
        (score, now_iso(), entry_id)
    )
    conn.commit()
    ok(f"Mood score set to {score}")


def cmd_schema(conn):
    """Print schema for both diary tables."""
    header("Schema")
    for table in ['diary_entries', 'diary_blocks']:
        print(c(f"\n  TABLE: {table}", BOLD))
        rows = conn.execute(f"PRAGMA table_info({table})").fetchall()
        for r in rows:
            nullable = "NULL" if not r['notnull'] else "NOT NULL"
            default  = f"  DEFAULT {r['dflt_value']}" if r['dflt_value'] else ""
            pk       = c("  [PK]", GREEN) if r['pk'] else ""
            print(f"    {c(r['name'], CYAN)}  {DIM}{r['type']} {nullable}{default}{RESET}{pk}")
    print()


def cmd_raw_sql(conn):
    """Execute raw SQL (SELECT only for safety)."""
    header("Raw SQL (SELECT only)")
    print(c("  Type your SELECT query. Empty line to cancel.", DIM))
    sql = input("  SQL> ").strip()
    if not sql:
        return
    if not sql.upper().startswith("SELECT"):
        warn("Only SELECT statements allowed in this mode. Use specific commands for writes.")
        return
    try:
        rows = conn.execute(sql).fetchall()
        if not rows:
            warn("No rows returned.")
            return
        keys = rows[0].keys()
        print(f"\n  {' | '.join(c(k, BOLD) for k in keys)}")
        print(f"  {'─' * 60}")
        for r in rows:
            print(f"  {' | '.join(str(r[k]) for k in keys)}")
        print(f"\n  {c(str(len(rows)) + ' row(s)', DIM)}")
    except Exception as e:
        err(str(e))


# ─── REPL ─────────────────────────────────────────────────────────────────────

MENU = [
    ("1",  "List entries",              cmd_list_entries),
    ("2",  "List blocks (all)",         lambda conn: cmd_list_blocks(conn)),
    ("3",  "List blocks for entry",     lambda conn: cmd_list_blocks(conn, cmd_pick_entry(conn))),
    ("4",  "Edit entry title",          cmd_edit_title),
    ("5",  "Edit block content",        cmd_edit_block_content),
    ("6",  "Set mood score on entry",   cmd_set_mood),
    ("7",  "Add test entry",            cmd_add_entry),
    ("8",  "Delete entry (destructive)",cmd_delete_entry),
    ("9",  "RESET ALL DATA",            cmd_reset_all),
    ("s",  "Show DB schema",            cmd_schema),
    ("r",  "Raw SELECT SQL",            cmd_raw_sql),
    ("q",  "Quit",                      None),
]


def repl():
    if not os.path.exists(DB_PATH):
        err(f"DB not found at: {DB_PATH}")
        sys.exit(1)

    SEP = '=' * 50
    print(f"\n{BOLD}{CYAN}{SEP}{RESET}")
    print(f"{BOLD}{CYAN}   shua_diary.db  Debug Console{RESET}")
    print(f"{BOLD}{CYAN}{SEP}{RESET}")
    print(f"  DB Path : {c(DB_PATH, DIM)}")
    print(f"  {c('Tip: Stop the Node.js orchestrator before deleting/resetting.', YELLOW)}")

    conn = get_conn()

    while True:
        print(f"\n{BOLD}  Commands:{RESET}")
        for key, label, _ in MENU:
            color = RED if "RESET" in label or "destructive" in label else CYAN
            print(f"    {c(key, color)}  {label}")

        choice = input(f"\n{BOLD}  > {RESET}").strip().lower()
        if choice == "q":
            ok("Bye.")
            conn.close()
            break

        matched = next((fn for k, _, fn in MENU if k == choice and fn is not None), None)
        if matched:
            try:
                matched(conn)
            except KeyboardInterrupt:
                print()
                warn("Cancelled.")
            except Exception as e:
                err(f"Error: {e}")
        else:
            warn("Unknown command.")


if __name__ == "__main__":
    repl()
