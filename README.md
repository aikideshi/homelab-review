# Homelab — Host-Grouped Architecture

## Structure
- `ansible/` → Provisioning & config management
- `tofu/` → Proxmox LXC infrastructure
- `services/` → Per-host service stacks
  - `control/` → 100-105
  - `soyo/`    → 120-121
  - `ms01/`    → 160-163
- `secrets/` → SOPS-encrypted values

## ✅ Status: SOPS + Age Fully Operational

|Check|Result|
|---|---|
|Config location|✅ Correct ~/homelab/.sops.yaml|
|Encryption|✅ Round‑trip verified|
|Key path|✅ SOPS_AGE_KEY_FILE set|
|Repo layout|✅ Matches your spec exactly|

## ✅ Status: Service Migration

|#|	Service|	Depends On|
|---|---|---|
|102|	✅ cloudflared|	—|
|101|	authentik|	cloudflared (ingress)|
|103|	forgejo/semaphore/devops|	authentik (OIDC)|

### cloudflared Migration
- ✅ Archived source reviewed
- ✅ New service dir created
- ✅ Clean compose file — compose adapted and validated with no hardcoded secrets
- ✅ .env.example — interface contract
- ✅ cloudflared.yml — tunnel config
- ✅ Credentials JSON → SOPS encrypted → committed safely
- ✅ Plaintext deleted — no risk of accidental leak
- ✅ .sops.yaml extended for JSON
- ✅ Committed to new repo history
#### TOFU
|Stage|Status|
|---|---|
|Provider setup|✅ Stable|
|LXC resource definition|✅ Working|
|Network/IP config|✅ Live|
|SSH key injection|✅ Verified|
|SOPS + sops exec-env workflow|✅ Documented|
|State file|✅ Tracked locally (or push to remote if configured)|
#### 📊 Status Summary — Phase 01 Complete
|Component|Status|
|---|---|
|Debian Trixie LXC|✅ Bootstrapped|
|Docker Engine|✅ Installed (official trixie packages)|
|daemon.json config|✅ Applied|
|SOPS secrets workflow|✅ Decrypting & deploying|
|Cloudflared Tunnel|✅ LIVE — Connected via QUIC 🟢|
|control-edge service|✅ Running — accessible externally|

📝 README — Phase 01–02 Full Documentation
markdown

# Homelab — Control Infrastructure

## Overview
Self-hosted infrastructure split across dedicated LXC containers on Proxmox, managed via OpenTofu + Ansible, secured through Cloudflare Tunnel and Authentik SSO.

---

## Architecture

┌─────────────────────────────────────┐
Public Internet │ Cloudflare Zero Trust / Tunnel │
└──────────────┬──────────────────────┘
│
┌────────▼────────────┐
LXC 102-edge │ cloudflared only │
192.168.8.102 │ Tunnel ingress only │
└────────┬────────────┘
│ HTTP forward
┌────────▼────────────┐
LXC 100-core │ Caddy + Authentik │
192.168.8.100 │ TLS + Auth + Routing │
└────────┬────────────┘
│
┌────────▼────────────┐
Future LXCs │ DevOps / Media / Apps
(101, 104, ...) │ via Caddy + Authentik
└─────────────────────┘
plaintext


---

## LXC Inventory

| LXC Name | VM ID | IP Address | Role | Status |
|---|---|---|---|---|
| `control-edge` | 102 | `192.168.8.102` | Cloudflare Tunnel ingress | ✅ Online |
| `control-core` | 100 | `192.168.8.100` | Caddy reverse-proxy + Authentik SSO | ✅ Online |

---

## Phase 01 — Edge & Initial Core
**Completed:**
- Provisioned LXC 102-edge → Docker → cloudflared service
- Initial LXC 103 provisioning → Caddy + Authentik stack deployed
- Cloudflare Tunnel configured → pointed at core services
- Local DNS rewrites (AdGuard) → routed to Caddy
- Secrets management via SOPS established

**Discovered:**
- Backup restore from prior instance incomplete → fresh Authentik setup required
- `sops_filter.py` was misclassified → removed; using `community.sops.sops` collection directly
- Redundant directory nesting simplified → flatter paths adopted

---

## Phase 02 — Rebase to 100 + Cleanup
**Completed:**
- **Rebase:** Destroyed LXC 103 → recreated as LXC 100 (`192.168.8.100`)
- **IP Updated:** Cloudflare Tunnel + AdGuard DNS rewrites → `auth.h-and-i.com → 192.168.8.100`
- **Secrets Simplified:** `secrets/per-service/*` → collapsed to `secrets/*`
- **Paths Flattened:** Removed `service_group` layer → `/var/services/100-core`, `/var/services/102-edge`
- **Debian 13 Trixie Verified:** Docker CE packages work natively (Oct 2026)
- **Playbook Fixed:** Removed overly strict `creates:` guard on Docker repo task → consistent provisioning
- **Authentik Refined:**
  - Postgres renamed `authentik-db` (abstracted from implementation)
  - Orphaned containers purged
  - Caddyfile syntax error fixed → stable TLS issuance via Cloudflare DNS-01
- **Network Scheme:**
  - `core_proxy` — shared proxy plane; Caddy listens here
  - `core_internal` — isolated DB/Redis; no external exposure

---

## How to Deploy

### Prerequisites
- SOPS configured for `secrets/*.sops.env` files
- SSH access to `root@192.168.8.102` and `root@192.168.8.100`

### Provision
```bash
# From homelab root
cd tofu/ansible

# Edge (tunnel)
ansible-playbook playbooks/01-provision-control-edge.yml

# Core (Caddy + Authentik)
ansible-playbook playbooks/02-provision-control-core.yml

Post-Setup

    Visit https://auth.h-and-i.com → set admin password
    Authentik → Outposts → create outpost → copy token
    Update secrets/100-core.sops.env → AUTHENTIK_PROXY_TOKEN=<token> → re-encrypt
    Re-run playbook → token deployed → proxy healthy

Pending / To-Do
High Availability

    Proxmox HA — enable auto-restart of LXC 100-core on surviving node if host fails
    Caddy Resiliency — split Caddy from Authentik → dedicated LXC(s) that can run independently
    Dual-stack Proxy — standby Caddy instance; Cloudflare LB or Keepalived VIP
    Authentik State — Postgres read-replica + Redis sentinel for multi-node auth

Networking Standardization

    Define shared Docker network pattern (core_proxy external join)
    Document service-to-service communication: LAN IP vs Docker network vs Tailscale
    Tailscale ACLs for inter-LXC management traffic

Phase 03 — DevOps Stack (Next)
See detailed plan below.
plaintext


---

## 🚀 Phase 03 — DevOps Stack: Full Plan

### 📦 Proposed Services — LXC `devops` (VM ID: `101`)

| Service | Purpose | Why Selected |
|---|---|---|
| **Forgejo** | Git forge / self-hosted GitHub alternative | Restore from GitHub; lightweight, AGPL, Gitea upstream ✅ |
| **Code-Server** | VS Code in browser — direct edit of repo files | Web-based dev environment; works seamlessly with Forgejo ✅ |
| **Semaphore** | CI/CD pipeline runner | Self-hosted alternative to GitHub Actions; simple, fast ✅ |
| **Termix** | Web-based terminal / shell access | Browser-based console; quick troubleshooting ✅ |
| **Woodpecker CI** *(recommended)* | Optional — lighter alternative/companion to Semaphore | Extremely lightweight, Docker-native, great for small homelabs |
| **Registry** *(optional)* | Private OCI/Docker image registry | Store built images from Semaphore before deployment |
| **Gitea Actions Runner** *(if using Forgejo)* | Built-in CI — lighter than separate Semaphore | If you want minimalism |

### Recommended Final Set
> **Forgejo + Code-Server + Semaphore** = core minimum. Add Termix for convenience. Woodpecker as alternative CI if Semaphore feels heavy.

---

## 🔗 Network Integration Pattern

### Cross-LXC Connectivity

LXC 100-core (Caddy)
↳ core_proxy network ← LXC 101-devops joins as external
↳ auth.h-and-i.com/* → routes to devops containers via forward_auth
LXC 101-devops
├── forgejo.h-and-i.com → Caddy → Authentik → Forgejo
├── code.h-and-i.com → Caddy → Authentik → Code-Server
├── ci.h-and-i.com → Caddy → Authentik → Semaphore
└── term.h-and-i.com → Caddy → Authentik → Termix
plaintext


### Key Principles
1. **Caddy handles all ingress** — no ports exposed directly on devops LXC
2. **Authentik forward-auth** — every devops route protected centrally
3. **Isolated internal network** for CI runners, secrets, etc.
4. **Service isolation** — each service can move to its own LXC later without rework

### Directory Structure

homelab/
├── secrets/
│ ├── 102-edge.sops.env
│ ├── 100-core.sops.env
│ └── 101-devops.sops.env ← new
└── tofu/
├── ansible/
│ └── playbooks/
│ └── 03-provision-devops.yml ← new
└── services/control/
├── 102-edge/
├── 100-core/
└── 101-devops/
├── compose.yml
├── Caddyfile
└── .env.example


📋 FULL CONTEXT — PHASE 3+ FOUNDATION
I. WHERE WE ARE — CURRENT STATE
Infrastructure Map
plaintext

                    Cloudflare Tunnel
                         │
              ┌──────────▼──────────┐
  LXC 102     │  cloudflared        │  — pure ingress only
  .102        │  no services        │
              └──────────┬───────────┘
                         │
              ┌──────────▼──────────────────────────────┐
  LXC 100     │  Caddy + Authentik                      │
  .100        │  core_proxy ← CREATES the shared network │
              │  ├─ caddy:80/443                        │
              │  ├─ authentik-server:9000               │
              │  ├─ authentik-worker                    │
              │  ├─ authentik-db (Postgres)             │
              │  └─ authentik-redis                      │
              │  core_internal ← DB/Redis ONLY, isolated │
              └─────────────────────────────────────────┘
                         │
         ┌───────────────┼───────────────┐
         ▼               ▼               ▼
    LXC 101          LXC SOYO         LXC MS-01
   devops           storage/media     media
   .101              (rebuild)        (clean)
   Forgejo          qBittorrent       Plex/Jellyfin
   Code-Server      apt-cacher-ng     Library
   Semaphore        Docker Registry
   Termix           Backup Target

LXC Inventory
Table
Name	VM ID	IP	Role	Status
control-edge	102	192.168.8.102	Cloudflare Tunnel — ingress only	✅ Online
control-core	100	192.168.8.100	Caddy + Authentik + Postgres + Redis	✅ Online
devops	101	192.168.8.101	Forgejo, Code-Server, Semaphore, Termix	⬜ Next
soyo	(TBD)	(TBD)	qBittorrent, apt-cacher-ng, Registry, Backup	⬜ Planned
ms-01	(TBD)	(TBD)	Plex/Jellyfin — clean media library	⬜ Planned
Synology DS1517+	—	Existing	Download/seeding storage + backup target	⬜ Integrate
Secrets & Path Pattern

    Secrets: secrets/<vmid>-<role>.sops.env (collapsed from per-service/)
    Services: tofu/services/<role>/<vmid>/compose.yml
    LXC root: /var/services/<vmid>-<role>/ (flat, no control/ nesting)
    OS: Debian 13 Trixie — Docker CE works natively ✅
    IaC: OpenTofu (LXC create) → Ansible (provision/deploy)

II. NETWORKING — THE CORE PATTERN (Answering Your Questions)
Why core_proxy? What Is It?
It is THE shared ingress plane — one network, one Caddy, all services join it.
plaintext

core_proxy = "the network where Caddy lives"
Every service that wants to be reachable via Caddy JOINS this network
→ Caddy says "reverse_proxy forgejo:3000"
→ Docker DNS resolves "forgejo" to the right container
→ NO IP changes, NO rework, just names forever

Bridge Type — What It Means

    Bridge = virtual Ethernet switch inside Docker
    Containers on the same bridge can talk directly using container names
    Like plugging all servers into the same physical switch
    bridge = isolated within single host/LXC; traffic never leaves that machine
    Unlike macvlan/ipvlan = containers get real LAN IPs; bridge is simpler, cleaner, more secure

Venn Diagram — Network Scope
plaintext

┌─────────────────────────────────────────────────────────┐
│              LXC 100 (192.168.8.100)                    │
│  ┌──────────────────────────────────────────────────┐  │
│  │             core_proxy (BRIDGE)                   │  │
│  │  ┌─────────┐  ┌──────────────┐  ┌─────────────┐  │  │
│  │  │  Caddy  │  │ Authentik-   │  │  (reserved  │  │  │
│  │  │ :80/443 │  │ Server :9000 │  │   for future│  │  │
│  │  └────┬────┘  └──────┬───────┘  └─────────────┘  │  │
│  └───────┼──────────────┼─────────────────────────────┘ │
│          │              │                               │
│  ┌───────▼──────────────▼────────────────────────────┐  │
│  │         core_internal (BRIDGE, INTERNAL=true)      │  │
│  │    Authentik-DB        Authentik-Redis            │  │
│  │    :5432                :6379                      │  │
│  │  └───────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────┘
          │
          │  cross-LXC join (same named network)
          ▼
┌─────────────────────────────────────────────────────────┐
│              LXC 101 (192.168.8.101)                    │
│  ┌──────────────────────────────────────────────────┐  │
│  │        core_proxy (EXTERNAL — joined, not created) │
│  │  ┌─────────┐  ┌──────────┐  ┌─────────┐          │  │
│  │  │ Forgejo │  │ Code-    │  │ Semaphore│          │  │
│  │  │ :3000   │  │ Server   │  │ :4000   │          │  │
│  │  └─────────┘  └──────────┘  └─────────┘          │  │
│  │                                                    │  │
│  │  devops_internal (BRIDGE, INTERNAL=true)          │  │
│  │  ├─ DBs for Forgejo/Semaphore (never exposed)     │  │
│  │  └─ CI runners                                    │  │
│  └──────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────┘

Mutual Access — How It Actually Works
You do NOT create devops_proxy — that's the key insight:
Table
Question	Answer
Does devops need its own proxy network?	No — only ONE core_proxy exists, created by LXC 100
How does devops connect to core?	core_proxy: external: true → joins existing network
How does core connect to devops?	Same network → bidirectional automatically ✅
Mutual?	Yes — once joined, caddy ↔ forgejo see each other by name
Can everyone access everything?	No — only what's on core_proxy. Internal DB networks stay isolated
The Rule — In Ansible Terms
LXC 100 (creator):
yaml

networks:
  core_proxy:
    name: core_proxy
    driver: bridge
    # external: false ← CREATES it
  core_internal:
    internal: true

ANY OTHER LXC (joiner):
yaml

networks:
  core_proxy:
    external: true   # ← "use the one that already exists"
    name: core_proxy
  devops_internal:   # ← EACH LXC has its OWN isolated internal net
    internal: true

Ansible ensures it exists first — playbook task:
yaml

- name: Ensure shared core_proxy network exists
  community.docker.docker_network:
    name: core_proxy
    state: present
    driver: bridge

Run this in the core playbook before starting services — other LXCs just join.
III. BACKUP STRATEGY — NO MORE DATA LOSS
Your Sizing (From Actual Dump)
plaintext

Authentik SQL dump:     ~10.3 MB
Compressed .tar.gz:      ~47 MB
→ Tiny. Daily backups = negligible storage/bandwidth

3-Layer Defense — Built Into Ansible
Table
Layer	Method	Ansible?	Purpose
1 — Logical DB Dump	pg_dumpall → cron daily @ 0300	✅ Yes	Point-in-time, fastest restore
2 — Restic Off-Site Sync	Dumps → NAS/Synology/soyo	✅ Yes	Encrypted, deduplicated history
3 — Proxmox PBS	LXC-level snapshots	Manual/Proxmox UI	"oops I deleted the whole container" recovery
Ansible-Deployed Components

    Backup script → /usr/local/bin/db-backup.sh
    Cron schedule → daily 0300 UTC+11
    Retention → keep 14 days locally
    Restic config → repo on Synology or soyo
    All vars in SOPS → RESTIC_REPOSITORY, RESTIC_PASSWORD

Restore = 5 Minutes
bash

# Get latest dump from restic or local
docker compose exec -T authentik-db psql -U authentik < dump.sql

IV. STORAGE & EXPANSION — NEW ASSETS
Synology DS1517+

    Role: Download seeding storage + backup target
    Integration: Mount via NFS/SMB to relevant LXCs
    Path: /mnt/synology/downloads, /mnt/synology/backups
    Media: qBittorrent writes here; ms-01 library stays clean

SOYO (Blank Proxmox LXC/VM)

    Role: Download/seed + caching + registry + backup destination
    Services: qBittorrent, apt-cacher-ng, Docker Registry, Restic repo
    Purpose: Offload download churn from ms-01; faster LAN caching

MS-01 (Clean Media Library)

    Role: Plex/Jellyfin primary — clean, no download clutter
    Storage: Media library only — seeds/downloads live on soyo/Synology
    Network: Joins core_proxy → Caddy routes media.h-and-i.com

Future Path → k3s

    Stateless apps (Forgejo, Semaphore, Code-Server) will migrate to k3s
    core_proxy pattern becomes Ingress network
    Stateful (DBs, media) stay on LXC/NAS for simplicity
    Current setup = proving ground for patterns that survive k8s transition

V. PHASE ORDER — YOUR CALL
Table
Option	Path	Pros
A — DevOps First	Forgejo → Code → Semaphore → then backup	Git history preserved immediately; work from clean slate
B — Backup First	Restore Authentik → build backup system → then DevOps	Data safety established before anything else
Recommendation: A — DevOps First

    You're essentially rebuilding anyway
    Forgejo becomes your source of truth for everything including Ansible playbooks
    Once code lives in Forgejo → backup strategy protects it from there
    Authentik admin + outpost token set → auth already functional

VI. PHASE 3 — DEVOPS: DELIVERABLES
Table
#	Item	Status
1	OpenTofu: LXC 101-devops defined	⬜
2	hosts.yml: devops entry → 192.168.8.101	⬜
3	101-devops.sops.env: created from template	⬜
4	03-provision-devops.yml: playbook parallel to core/edge	⬜
5	core_proxy: join as external network	⬜
6	compose.yml: Forgejo + Code-Server + Semaphore + Termix	⬜
7	Caddyfile: 3+ domains → forward_auth → Authentik	⬜
8	Forgejo: mirror from GitHub verified	⬜
9	README: Phase 3 updated	⬜


Updated TOFU to use SOPS secrets for LXC credentials
✅ _secrets.tf defines the SOPS data sources
✅ _providers.tf uses the SOPS data for passwords/tokens
✅ _control.tf uses the SOPS data for LXC credentials
✅ _authentik.tf uses the SOPS data for Google OAuth
✅ variables.tf only contains non-sensitive config (populated by terraform.tfvars)
✅ tofu init -upgrade has downloaded all providers

STATUS
- Forgejo Authentik integration completed
- Created new user and uploaded homelab repo into git.h-and-i.com
- Semaphore, Termix, Code Server pending
- Migrated ms-01 samba server to 192.168.8.178
