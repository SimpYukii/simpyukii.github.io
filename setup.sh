#!/usr/bin/env bash
# Shorts-Bot: Ein-Befehl-Einrichtung für einen frischen Ubuntu-Server.
#   curl -fsSL https://simpyukii.github.io/setup.sh | bash
# Enthält keine Geheimnisse. Erzeugt einen Deploy-Key, damit der Server das private Repo lesen darf.
set -euo pipefail
REPO_SSH="git@github.com:SimpYukii/SimpYukii.git"
APP_DIR=/opt/shortsbot
KEY=/root/.ssh/github_shortsbot

mkdir -p /root/.ssh && chmod 700 /root/.ssh
if [ ! -f "$KEY" ]; then
  ssh-keygen -t ed25519 -N "" -C "shortsbot-server" -f "$KEY" >/dev/null
fi
if ! grep -q "github_shortsbot" /root/.ssh/config 2>/dev/null; then
  printf 'Host github.com\n  IdentityFile %s\n  IdentitiesOnly yes\n' "$KEY" >> /root/.ssh/config
fi
ssh-keyscan -t ed25519 github.com >> /root/.ssh/known_hosts 2>/dev/null

until GIT_SSH_COMMAND="ssh -o BatchMode=yes" git ls-remote "$REPO_SSH" >/dev/null 2>&1; do
  echo
  echo "================================================================"
  echo " Schritt 1: Diesen Schlüssel bei GitHub als Deploy Key eintragen"
  echo "  github.com/SimpYukii/SimpYukii -> Settings -> Deploy keys -> Add deploy key"
  echo "  Title: hetzner-server   (\"Allow write access\" NICHT anhaken)"
  echo
  cat "$KEY.pub"
  echo
  echo " Danach hier Enter drücken."
  echo "================================================================"
  read -r _ < /dev/tty
done
echo "✓ GitHub-Zugriff klappt."

if ! command -v git >/dev/null; then apt-get update && apt-get install -y git; fi
[ -d "$APP_DIR/.git" ] || git clone "$REPO_SSH" "$APP_DIR"
bash "$APP_DIR/deploy/setup-server.sh" "$REPO_SSH"
