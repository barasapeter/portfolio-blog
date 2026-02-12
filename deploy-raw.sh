#!/usr/bin/env bash
set -euo pipefail

# ====== EDIT THESE ======
APP_USER="ubuntu"
APP_DIR="/home/ubuntu/cardlabsv3.0"
DOMAIN="cardlabs-sandbox.duckdns.org"

DB_NAME="cardlabs"
DB_USER="cardlabs_user"
DB_PASS="change-this-strong-password"

SERVICE_NAME="fastapi"
APP_BIND="127.0.0.1:8000"
WORKERS="4"
# ========================

echo "==> Updating apt indexes (no full upgrade to save time)"
sudo apt-get update -y

echo "==> Installing OS dependencies"
sudo apt-get install -y --no-install-recommends \
  python3 python3-pip python3-venv python3-dev build-essential \
  libpq-dev \
  postgresql postgresql-contrib \
  nginx \
  certbot python3-certbot-nginx \
  libgl1 libglib2.0-0 libsm6 libxrender1 libxext6

echo "==> Creating app directory (if missing)"
sudo mkdir -p "$APP_DIR"
sudo chown -R "$APP_USER:$APP_USER" "$APP_DIR"

echo "==> Creating python venv (if missing)"
if [ ! -d "$APP_DIR/venv" ]; then
  sudo -u "$APP_USER" python3 -m venv "$APP_DIR/venv"
fi

echo "==> Upgrading pip tooling"
sudo -u "$APP_USER" "$APP_DIR/venv/bin/pip" install -U pip setuptools wheel

echo "==> Setting up Postgres role + db (idempotent)"
sudo -u postgres psql <<SQL
DO \$\$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = '${DB_USER}') THEN
    CREATE ROLE ${DB_USER} LOGIN PASSWORD '${DB_PASS}';
  END IF;
END
\$\$;

DO \$\$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_database WHERE datname = '${DB_NAME}') THEN
    CREATE DATABASE ${DB_NAME} OWNER ${DB_USER};
  END IF;
END
\$\$;
SQL

echo "==> Writing systemd service: /etc/systemd/system/${SERVICE_NAME}.service"
sudo tee "/etc/systemd/system/${SERVICE_NAME}.service" >/dev/null <<EOF
[Unit]
Description=FastAPI app (${SERVICE_NAME})
After=network.target

[Service]
User=${APP_USER}
WorkingDirectory=${APP_DIR}
EnvironmentFile=${APP_DIR}/.env
ExecStart=${APP_DIR}/venv/bin/gunicorn -w ${WORKERS} -k uvicorn.workers.UvicornWorker main:app --bind ${APP_BIND}
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

echo "==> Writing nginx site: /etc/nginx/sites-available/${SERVICE_NAME}"
sudo tee "/etc/nginx/sites-available/${SERVICE_NAME}" >/dev/null <<EOF
server {
    server_name ${DOMAIN} www.${DOMAIN};

    client_max_body_size 50M;

    location / {
        proxy_pass http://${APP_BIND};
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_read_timeout 120;
    }
}
EOF

echo "==> Enabling nginx site"
sudo ln -sf "/etc/nginx/sites-available/${SERVICE_NAME}" "/etc/nginx/sites-enabled/${SERVICE_NAME}"
sudo nginx -t
sudo systemctl restart nginx

echo "==> Enabling + starting app service"
sudo systemctl daemon-reload
sudo systemctl enable "${SERVICE_NAME}"
sudo systemctl restart "${SERVICE_NAME}"
sudo systemctl --no-pager status "${SERVICE_NAME}" || true

echo "==> HTTPS via certbot (will prompt if first time)"
# Only run if you want it now. If DNS isn't ready yet, comment this out.
sudo certbot --nginx -d "${DOMAIN}" -d "www.${DOMAIN}" || true

echo "==> Certbot timer status"
sudo systemctl --no-pager status certbot.timer || true

echo "✅ Bootstrap done."
echo "Next: create ${APP_DIR}/.env and run deploy.sh"