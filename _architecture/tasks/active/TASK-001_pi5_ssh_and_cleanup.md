# TASK-001 — Pi5 SSH Setup + horAIzon 2.0 Cleanup

| Field | Value |
| :--- | :--- |
| **Status** | [ ] Not started |
| **Phase** | Phase 1 — Pre-coding prerequisite |
| **Type** | Manual (human) + AI-assisted |
| **Blocks** | TASK-007 (Governor deploy), all Pi5 work |
| **Prerequisites** | Tailscale must be running on MSI laptop and Pi5 |

---

## Context

Tailscale is live. The Pi5 (`horaizon-pi5`, `100.67.11.0`) is reachable on the mesh but SSH is not configured for passwordless remote coding. Until SSH is set up, no code can be deployed to or edited on the Pi5. Additionally, the old horAIzon 2.0 processes and binaries must be removed to prevent port conflicts when deploying 3.0.

---

## Part A — SSH Setup (Manual Steps on MSI Laptop)

### Step 1: Verify Tailscale connectivity

```powershell
# On MSI laptop (PowerShell)
ping 100.67.11.0
```

Expected: replies from Pi5. If no reply, open Tailscale tray → verify both devices are connected.

### Step 2: Generate SSH key (if you don't already have one)

```powershell
# Check for existing key first
Test-Path "$HOME\.ssh\id_ed25519"

# If False, generate one:
ssh-keygen -t ed25519 -C "msi-horaizon" -f "$HOME\.ssh\id_ed25519" -N ""
```

### Step 3: Copy public key to Pi5

```powershell
# Get your public key content
Get-Content "$HOME\.ssh\id_ed25519.pub"
```

SSH into Pi5 with password (one-time):
```powershell
ssh shua@100.67.11.0
# Enter password when prompted
```

On Pi5, paste the key:
```bash
mkdir -p ~/.ssh
chmod 700 ~/.ssh
echo "PASTE_YOUR_PUBLIC_KEY_HERE" >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
```

### Step 4: Disable password auth on Pi5

```bash
# On Pi5
sudo nano /etc/ssh/sshd_config
```

Set these values:
```
PasswordAuthentication no
PubkeyAuthentication yes
```

```bash
sudo systemctl restart ssh
```

### Step 5: Add SSH config on MSI for easy access

Create or append to `C:\Users\YOUR_USER\.ssh\config`:

```
Host horaizon-pi5
    HostName 100.67.11.0
    User shua
    IdentityFile ~/.ssh/id_ed25519
    ServerAliveInterval 60
    ServerAliveCountMax 3
```

### Step 6: Verify passwordless SSH

```powershell
ssh horaizon-pi5
# Should connect without password prompt
```

---

## Part B — horAIzon 2.0 Cleanup on Pi5 (AI-executable via SSH)

SSH into Pi5, then run the following. **Verify each step before proceeding.**

### Step 1: Stop all running 2.0 services

```bash
# Check what's running
sudo systemctl list-units --type=service | grep -E "shua|horaizon|governor"

# Stop and disable each one found, e.g.:
sudo systemctl stop shua-governor.service
sudo systemctl disable shua-governor.service

# Kill any orphan processes
pkill -f "shua_governor" || true
pkill -f "shua_diary" || true
pkill -f "shua_resume" || true
pkill -f "ollama" || true    # Will be restarted fresh
```

### Step 2: Check what ports are in use

```bash
ss -tlnp | grep -E "7700|8080|11434|3000|4000"
```

Note any processes still using these ports and kill them.

### Step 3: Remove 2.0 binaries and code (CONFIRM BEFORE RUNNING)

```bash
# First, list what exists
ls -la ~/horaizon/ 2>/dev/null || echo "No ~/horaizon dir"
ls -la /opt/horaizon/ 2>/dev/null || echo "No /opt/horaizon dir"

# Remove after confirming
sudo rm -rf /opt/horaizon     # if it exists
rm -rf ~/horaizon_2.0         # if it exists
rm -rf ~/horAIzon_2.0         # if it exists
```

### Step 4: Create fresh 3.0 directory structure

```bash
sudo mkdir -p /opt/horaizon
sudo mkdir -p /etc/horaizon/governor
sudo chown -R shua:shua /opt/horaizon
sudo chown -R shua:shua /etc/horaizon
```

### Step 5: Verify Ollama is installed

```bash
which ollama
ollama --version

# If not installed:
curl -fsSL https://ollama.com/install.sh | sh

# Pull the primary model
ollama pull qwen2.5:1.5b
ollama pull nomic-embed-text
```

### Step 6: Verify cgroups v2 is active

```bash
cat /sys/fs/cgroup/cgroup.controllers
# Expected output should include: cpuset cpu io memory hugetlb pids rdma misc
```

If empty or missing `memory`, cgroups v2 is not active. On Pi5 with bookworm this should be enabled by default.

### Step 7: Check port 7700 is free

```bash
ss -tlnp | grep 7700
# Expected: no output (port is free)
```

### Step 8: Verify ufw allows port 7700

```bash
sudo ufw status
sudo ufw allow 7700/tcp comment "HBP v2 WebSocket"
sudo ufw reload
```

---

## Acceptance Criteria

- [ ] `ssh horaizon-pi5` connects without password from MSI laptop
- [ ] `ssh horaizon-pi5` also works from within Tailscale network
- [ ] No horAIzon 2.0 processes running (`ps aux | grep shua` shows nothing relevant)
- [ ] `/opt/horaizon/` directory exists and is owned by `shua`
- [ ] `/etc/horaizon/governor/` directory exists
- [ ] `ollama pull qwen2.5:1.5b` completed successfully
- [ ] Port 7700 is free (`ss -tlnp | grep 7700` returns empty)
- [ ] cgroups v2 controllers are visible

---

## References

- `_architecture/specs/shua_governor/shua_governor_spec.md` — pre-deploy checklist
- `_architecture/implementation_plan.md` — Tailscale network map
