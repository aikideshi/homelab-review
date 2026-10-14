# Phase 04 Watch Scaffold

## Sizing (why 2c / 2GB / 16GB is enough)
- uptime-kuma: ~200MB RAM, 0.1 CPU idle. SQLite data ~ 50MB even with 100 monitors
- beszel-hub: ~80MB RAM Go binary, almost no CPU. Data = metrics history (default 1m resolution 30d ~ 200MB)
- dozzle: ~40MB RAM, reads docker socket only
- wud: ~30MB RAM
Total: <400MB RAM steady, bursts to ~800MB on compose pull. So 2048MB gives 4x headroom.
Disk: 16GB local-lvm, actual volumes <1GB. Keep 16GB for docker image layers.
CPU: 2 cores, N150 has 4c4t - leaving 2c for future dl-qbt LXC.

## IP scheme
soyo host = 192.168.8.12
watch LXC = 192.168.8.120 (first in 120-139 range)
AdGuard rewrites -> all *.h-and-i.com -> 192.168.8.100 (Caddy), Caddy reverse_proxy to .120

## Authentik - What each needs
All 4 use **forward_single** proxy provider (your import authentik_forward_auth pattern).
No OAuth needed, just forward_auth. Steps:

1. For each app, terraform creates authentik_provider_proxy + authentik_application
2. Group binding: authentik Admins can access
3. Outpost: Add the 4 new providers to your embedded outpost (UI or terraform)
4. Caddy fragment does `import authentik_forward_auth` which does:
   forward_auth authentik:9000 { uri /outpost.goauthentik.io/auth/caddy ... }
   So Caddy will 302 to auth.h-and-i.com if no session.

Beszel extra: Beszel hub itself is behind Authentik, but agents talk via TOKEN (BESZEL_HUB_TOKEN). So agents bypass browser auth via token. Set BESZEL_HUB_TOKEN in watch.sops.env.

Dozzle/WUD Swarm:
- Central dozzle on 120 in server mode
- On each other docker host (100,101,16), deploy dozzle agent:
  docker run -v /var/run/docker.sock:/var/run/docker.sock amir20/dozzle --agent --addr :7007
  Then in central dozzle UI: Settings -> Agents -> add 192.168.8.100:7007 etc.
  For now scaffold runs single-host. Add agents later in base role.

## Tofu order
cd tofu
tofu init
tofu plan -target=proxmox_virtual_environment_container.soyo
tofu apply

## Ansible order
# Add to ansible/inventory/hosts.yml the soyo-watch group
ansible-playbook playbooks/soyo-watch.yml -i inventory/hosts.yml

## SOPS secrets needed
secrets/watch.sops.env:
UPTIME_KUMA_VERSION=1
BESZEL_VERSION=latest
DOZZLE_VERSION=latest
WUD_VERSION=latest
BESZEL_HUB_TOKEN=your-random-32-char

secrets/global.sops.env should have TIMEZONE etc.

## Caddy SAFE RELOAD
We kept delegate_to: control-core + caddy reload --config pattern, never compose restart.
