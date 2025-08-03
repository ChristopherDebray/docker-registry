#!/bin/bash
set -euo pipefail

if [ $# -lt 2 ]; then
  echo "Usage: $0 <repo> <keep>"
  exit 1
fi

REPO=$1
KEEP=$2

REGISTRY="REGISTRY_DOMAIN"
USER="REGISTRY_USER"
PASS="PASSWORD"

# Récupère tous les tags sauf "latest"
TAGS=$(curl -s -u $USER:$PASS https://$REGISTRY/v2/$REPO/tags/list \
  | jq -r '.tags[]' \
  | grep -v '^latest$' \
  | sort)

COUNT=$(echo "$TAGS" | wc -l)
DELETE_COUNT=$((COUNT - KEEP))

if [ "$DELETE_COUNT" -le 0 ]; then
  echo "Nothing to delete for $REPO (only $COUNT tags beside latest)."
  exit 0
fi

echo "$COUNT tags found for $REPO (beside latest), deleting $DELETE_COUNT oldest…"

# Deletes the oldest tags while ignoring "latest"
echo "$TAGS" | head -n $DELETE_COUNT | while read TAG; do
  DIGEST=$(curl -s -I -u $USER:$PASS \
    -H "Accept: application/vnd.docker.distribution.manifest.v2+json" \
    https://$REGISTRY/v2/$REPO/manifests/$TAG \
    | grep Docker-Content-Digest | awk '{print $2}' | tr -d $'\r')

  if [ -n "$DIGEST" ]; then
    echo "Deleting $REPO:$TAG ($DIGEST)"
    curl -s -u $USER:$PASS -X DELETE https://$REGISTRY/v2/$REPO/manifests/$DIGEST
  fi
done

echo "Cleanup done for $REPO. Kept $KEEP recent tags + latest."
