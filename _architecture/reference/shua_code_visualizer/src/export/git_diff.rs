use std::path::{Path, PathBuf};
use git2::{Repository, Status, Commit};

pub fn get_modified_files(repo_root: &Path) -> Vec<PathBuf> {
    let repo = match Repository::open(repo_root) {
        Ok(r) => r,
        Err(_) => return Vec::new(),
    };

    let mut modified = Vec::new();
    let statuses = match repo.statuses(None) {
        Ok(s) => s,
        Err(_) => return Vec::new(),
    };

    for entry in statuses.iter() {
        let status = entry.status();
        if status.intersects(Status::INDEX_MODIFIED | Status::WT_MODIFIED | Status::WT_NEW | Status::INDEX_NEW) {
            if let Some(path_str) = entry.path() {
                let abs_path = repo_root.join(path_str);
                modified.push(abs_path);
            }
        }
    }

    modified
}

pub fn churn_score(file: &Path, repo: &Repository, days: u32) -> f32 {
    let mut walk = match repo.revwalk() {
        Ok(w) => w,
        Err(_) => return 0.0,
    };

    if walk.push_head().is_err() {
        return 0.0;
    }

    let now = std::time::SystemTime::now()
        .duration_since(std::time::UNIX_EPOCH)
        .unwrap()
        .as_secs() as i64;
    let limit_secs = (days as i64) * 24 * 3600;

    let mut commit_count = 0;
    let mut total_commits_checked = 0;

    let rel_path = match file.strip_prefix(repo.workdir().unwrap_or(Path::new(""))) {
        Ok(p) => p,
        Err(_) => file,
    };

    for oid_result in walk {
        let oid = match oid_result {
            Ok(o) => o,
            Err(_) => continue,
        };

        let commit = match repo.find_commit(oid) {
            Ok(c) => c,
            Err(_) => continue,
        };

        let commit_time = commit.time().seconds();
        if now - commit_time > limit_secs {
            break;
        }

        total_commits_checked += 1;

        if commit_touches_file(repo, &commit, rel_path) {
            commit_count += 1;
        }
    }

    if total_commits_checked == 0 {
        return 0.0;
    }

    (commit_count as f32) / (total_commits_checked as f32)
}

fn commit_touches_file(repo: &Repository, commit: &Commit, file: &Path) -> bool {
    let tree = match commit.tree() {
        Ok(t) => t,
        Err(_) => return false,
    };

    let mut parent_tree = None;
    if let Ok(parent) = commit.parent(0) {
        if let Ok(pt) = parent.tree() {
            parent_tree = Some(pt);
        }
    }

    let mut diff_options = git2::DiffOptions::new();
    diff_options.pathspec(file);

    let diff = repo.diff_tree_to_tree(parent_tree.as_ref(), Some(&tree), Some(&mut diff_options));
    if let Ok(d) = diff {
        d.deltas().len() > 0
    } else {
        false
    }
}
