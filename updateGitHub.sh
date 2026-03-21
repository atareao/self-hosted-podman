#!/bin/bash
# ================================================================
# Script: updateGitHub.sh
# Descripción: Commit y push automático a GitHub + Codeberg
#              Detecta automáticamente la rama actual.
# ================================================================
#!/bin/bash

set -e

BRANCH=$(git rev-parse --abbrev-ref HEAD)
KEY_PATH="$HOME/.ssh/idGitHub"
MSG=${1:-"Update: cambios automáticos"}

echo "🔐 Verificando clave SSH..."

if [ ! -f "$KEY_PATH" ]; then
  echo "❌ No se encontró la clave privada en $KEY_PATH"
  exit 1
fi

if [ -z "$SSH_AUTH_SOCK" ]; then
  echo "📡 Iniciando ssh-agent..."
  eval "$(ssh-agent -s)"
  trap "kill $SSH_AGENT_PID" EXIT
fi

if ! ssh-add -l | grep -q "$KEY_PATH"; then
  echo "🔑 Añadiendo clave SSH..."
  ssh-add "$KEY_PATH"
fi

echo "🌐 Verificando conexión con GitHub..."
if ! ssh -T git@github.com 2>&1 | grep -q "successfully authenticated"; then
  echo "❌ Error de autenticación SSH"
  exit 1
fi

echo "📌 Rama actual: $BRANCH"

git add .

if git diff --cached --quiet; then
  echo "⚠️ No hay cambios para commit"
else
  git commit -m "$MSG"
fi

REMOTE_URL=$(git remote get-url origin)

if [[ "$REMOTE_URL" == https://github.com/* ]]; then
  echo "🔄 Convirtiendo remote a SSH..."
  REPO_PATH=${REMOTE_URL#https://github.com/}
  git remote set-url origin "git@github.com:$REPO_PATH"
fi

for remote in origin codeberg; do
  if git remote get-url "$remote" &>/dev/null; then
    echo "🚀 Push a $remote..."
    git push -u "$remote" "$BRANCH"
  fi
done

echo "✅ Push completado (rama: $BRANCH)"
