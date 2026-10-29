#!/bin/bash
# Script de sauvegarde quotidienne de /srv/data vers /backup
# Auteur : Nihad - TP1

set -euo pipefail                 # arrête le script à la moindre erreur

SOURCE="srv/data"                 # dossier à sauvegarder (relatif à /)
DEST="/backup"                    # dossier des sauvegardes
DATE=$(date +%Y-%m-%d_%H-%M)      # date du jour, ex : 2026-10-26_02-00
ARCHIVE="$DEST/data_$DATE.tar.gz"
LOG="/var/log/backup_data.log"

mkdir -p "$DEST"
chmod 700 "$DEST"                 # seul root peut lire les sauvegardes

# Création de l'archive compressée, en conservant les ACL
tar --acls -czf "$ARCHIVE" -C / "$SOURCE"

# Rotation : suppression des sauvegardes de plus de 7 jours
find "$DEST" -name 'data_*.tar.gz' -mtime +7 -delete

echo "$(date '+%F %T') - Sauvegarde OK : $ARCHIVE" >> "$LOG"
