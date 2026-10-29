#!/bin/bash
# Installation de Nginx avec une page de test - TP4
set -e

if [ "$EUID" -ne 0 ]; then
    echo "Erreur : lancer ce script avec sudo"
    exit 1
fi

apt-get update -q
apt-get install -y nginx

cat > /var/www/html/index.html <<EOF
<!DOCTYPE html>
<html>
<head><meta charset="utf-8"><title>Test</title></head>
<body>
<h1>Serveur $(hostname)</h1>
<p>Page deployee par script Bash le $(date '+%d/%m/%Y a %H:%M')</p>
</body>
</html>
EOF

systemctl enable --now nginx
systemctl is-active nginx
