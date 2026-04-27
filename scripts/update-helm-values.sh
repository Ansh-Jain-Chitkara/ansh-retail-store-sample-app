#!/usr/bin/env bash
# update-helm-values.sh — Update .image.repository and .image.tag in a service's
# Helm chart values.yaml to point at a private AWS ECR repository.
#
# Usage:
#   update-helm-values.sh <SERVICE> <SHORT_SHA> <AWS_ACCOUNT_ID> <AWS_REGION>
#
# Arguments:
#   SERVICE         — microservice name (e.g. ui, cart, catalog, checkout, orders)
#   SHORT_SHA       — 7-character Git SHA used as the image tag
#   AWS_ACCOUNT_ID  — 12-digit AWS account ID
#   AWS_REGION      — AWS region (e.g. us-east-1)
#
# The script targets ONLY the top-level .image path, leaving nested image blocks
# (e.g. .dynamodb.image, .mysql.image) completely untouched.
#
# Exit codes:
#   0 — success
#   1 — missing arguments, yq not installed, or target file not found

set -euo pipefail

# ---------------------------------------------------------------------------
# Argument validation
# ---------------------------------------------------------------------------
if [[ $# -ne 4 ]]; then
  echo "Error: expected 4 arguments, got $#" >&2
  echo "Usage: $(basename "$0") <SERVICE> <SHORT_SHA> <AWS_ACCOUNT_ID> <AWS_REGION>" >&2
  exit 1
fi

SERVICE="$1"
SHORT_SHA="$2"
AWS_ACCOUNT_ID="$3"
AWS_REGION="$4"

# ---------------------------------------------------------------------------
# Dependency check
# ---------------------------------------------------------------------------
if ! command -v yq &>/dev/null; then
  echo "Error: 'yq' is not installed or not in PATH" >&2
  echo "Install it from: https://github.com/mikefarah/yq/releases" >&2
  exit 1
fi

# ---------------------------------------------------------------------------
# Target file check
# ---------------------------------------------------------------------------
TARGET_FILE="src/${SERVICE}/chart/values.yaml"

if [[ ! -f "${TARGET_FILE}" ]]; then
  echo "Error: target file not found: ${TARGET_FILE}" >&2
  exit 1
fi

# ---------------------------------------------------------------------------
# Update .image.repository and .image.tag (top-level .image only)
# ---------------------------------------------------------------------------
REPOSITORY="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/retail-store-${SERVICE}"

yq -i '
  .image.repository = "'"${REPOSITORY}"'" |
  .image.tag = "'"${SHORT_SHA}"'"
' "${TARGET_FILE}"

# ---------------------------------------------------------------------------
# Observability
# ---------------------------------------------------------------------------
echo "Updated ${TARGET_FILE}: repository=${REPOSITORY} tag=${SHORT_SHA}"

# chmod +x scripts/update-helm-values.sh  # run once after creating this file
exit 0
