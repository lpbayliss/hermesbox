# hermesbox

Hermes agent + Claude Code + dev tooling on a Debian 13 LXC.

Per-service systemd units, SSH-accessible, one env file for all secrets.

---

## 1. Create the LXC (Proxmox host)

Run on your Proxmox node shell:

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/ct/debian.sh)"
```

Pick **Advanced** when prompted and bump resources — the script's defaults are too small for hermes:

| Resource     | Default | Recommended |
| ------------ | ------- | ----------- |
| OS           | Debian 13 | Debian 13 |
| CPU cores    | 1       | 2+          |
| RAM          | 512 MB  | 4096 MB+    |
| Disk         | 2 GB    | 16 GB+      |
| Unprivileged | yes     | yes         |
| Internet     | required | required    |

Default login: `root` / `debian`. Change it on first boot (`passwd`).

---

## 2. Install hermesbox (inside the LXC)

```bash
apt-get update && apt-get install -y git
git clone https://github.com/lpbayliss/hermesbox /opt/hermesbox
cd /opt/hermesbox
./install.sh
```

`install.sh` runs each `scripts/*.sh` in order. Idempotent — safe to re-run.

What you get:

- `hermes` user, password-SSH enabled, `NOPASSWD: ALL` sudo, member of `adm` and `systemd-journal` (so `journalctl` works without sudo).
- Tools: `git`, `gh`, `node 22`, `npm`, `lefthook`, `dotnet 8`, `godot 4.6.2 mono` (headless), `claude`, `obsidian-headless` (`ob`), `lazygit`, `delta`, `eza`, `starship`, `zoxide`, `direnv`, `fzf`, `ripgrep`, `fd`, `jq`, `tmux`.
- `hermes-agent` installed under `/home/hermes/.local/bin`.
- Two systemd units: `hermes-gw.service`, `obsidian-sync.service` (enabled, not started).
- `/etc/default/hermes` seeded from `etc/default/hermes.example` (mode 0640, root:hermes).

---

## 3. Configure secrets

Edit `/etc/default/hermes`. Required keys depend on which services you run:

- LLM: at least one of `OPENROUTER_API_KEY`, `ANTHROPIC_API_KEY`, etc.
- Gateway: any of `TELEGRAM_BOT_TOKEN`, `DISCORD_BOT_TOKEN`, `SLACK_BOT_TOKEN`/`SLACK_APP_TOKEN`, `EMAIL_*`.
- Obsidian sync: `OBSIDIAN_EMAIL`, `OBSIDIAN_PASSWORD`, `OBSIDIAN_VAULT`, `OBSIDIAN_VAULT_KEY`. Skip these and `obsidian-sync.service` will exit cleanly.

Then bring services up:

```bash
systemctl start hermes-gw obsidian-sync
systemctl status hermes-gw obsidian-sync
```

Hermes config itself (model selection, compression, etc.) lives at `/home/hermes/.hermes/config.yaml`. Run `hermes setup` as the `hermes` user once to create it; tweak via `hermes config set` after.

---

## 4. SSH in

The LXC has its own IP on your Proxmox bridge. Default sshd on port 22:

```bash
ssh hermes@<lxc-ip>
```

Drop a public key in `/home/hermes/.ssh/authorized_keys` to skip passwords.

GitHub auth: `gh auth login` as the `hermes` user, or set `GITHUB_TOKEN` in `/etc/default/hermes`.

---

## 5. Bind mounts (optional)

To back `/workspace` or `/vault` with host storage, add bind mounts after the LXC is up. Run on the **Proxmox host**:

```bash
mkdir -p /host/path
chown -R 101000:101000 /host/path     # unpriv: LXC uid 1000 (hermes) → host 101000
echo "mp0: /host/path,mp=/vault" >> /etc/pve/lxc/<vmid>.conf
pct restart <vmid>
```

UID mapping for unprivileged LXCs:
- LXC `root` (uid 0) → host uid 100000
- LXC `hermes` (uid 1000) → host uid 101000

Use `mp0`, `mp1`, etc. for multiple mounts.

---

## How to Update

```bash
cd /opt/hermesbox
git pull
./upgrade.sh
```

Re-runs every installer script (latest hermes, latest node 22.x, latest gh, latest binary releases of lazygit/delta/eza), reloads systemd, restarts enabled units.

---

## How to Uninstall

```bash
cd /opt/hermesbox
./uninstall.sh                # services + sources, keep user/data
./uninstall.sh --purge-user   # also remove hermes user + home
./uninstall.sh --purge-data   # also remove /workspace and /vault
./uninstall.sh --purge        # both
```

---

## Service management

All as `hermes` (sudo NOPASSWD) or root:

```bash
systemctl {start,stop,restart,status} hermes-gw
systemctl {start,stop,restart,status} obsidian-sync
journalctl -u hermes-gw -f
journalctl -u obsidian-sync -f
```

---

## Layout

```
install.sh                    orchestrator (root)
upgrade.sh                    re-run + restart units
uninstall.sh                  tear down
scripts/                      one .sh per tool/dep
systemd/                      unit files (installed to /etc/systemd/system/)
etc/default/hermes.example    env template
```

---

## Notes

- Targets Debian 13 (trixie) on amd64. Other distros/arches not supported.
- No config seeding — hermes config is yours to manage.
