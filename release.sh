#!/usr/bin/env bash
set -e

# ==============================================================================
# HosteDay Flutter SDK & Template Release Automation Script
# Follows the standard HosteDay release engineering guidelines.
# Usage:
#   ./release.sh <version> [changelog_message]
# Example:
#   ./release.sh v2.2.1 "Template-ready example and configuration injection"
# ==============================================================================

RAW_VERSION="$1"
CHANGELOG="${2:-General updates, stability improvements, and template readiness}"

if [ -z "$RAW_VERSION" ]; then
    echo "❌ Error: Version is required."
    echo "Usage: ./release.sh <version> [changelog_message]"
    echo "Example: ./release.sh v2.2.1 \"Update example template and config\""
    exit 1
fi

# Normalize version numbers
VERSION="${RAW_VERSION#v}"
TAG="v${VERSION}"

# Validate semantic version format (X.Y.Z)
if [[ ! "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z0-9.]+)?$ ]]; then
    echo "❌ Error: Invalid semantic version format '$VERSION'. Expected X.Y.Z (e.g., 2.2.1 or v2.2.1)"
    exit 1
fi

echo "🚀 Starting HosteDay Flutter Release: $TAG (Package version: $VERSION)"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# 1. Update version in pubspec.yaml
if [ -f "pubspec.yaml" ]; then
    echo "📝 Updating pubspec.yaml to version: $VERSION..."
    sed -i -E "s/^version:[[:space:]]*[0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z0-9.]+)?/version: $VERSION/" pubspec.yaml
fi

# 2. Update CHANGELOG.md
if [ -f "CHANGELOG.md" ]; then
    echo "📝 Updating CHANGELOG.md..."
    DATE=$(date +"%Y-%m-%d")
    ENTRY="## $VERSION - $DATE\n\n- $CHANGELOG\n"
    TEMP_CHANGELOG=$(mktemp)
    echo -e "$ENTRY\n$(cat CHANGELOG.md)" > "$TEMP_CHANGELOG"
    mv "$TEMP_CHANGELOG" CHANGELOG.md
fi

# 3. Stage changes safely (prevent .env or credentials from being committed)
echo "🔍 Checking working tree and staging clean files..."
BLOCKED_PATTERNS=('(^|/)\.env($|\.)' '\.pem$' '\.key$' 'id_rsa' '\.p12$' '\.keystore$')
for pattern in "${BLOCKED_PATTERNS[@]}"; do
    if git status --porcelain | awk '{print $2}' | grep -E "$pattern" >/dev/null 2>&1; then
        echo "❌ Security Alert: Blocked sensitive file detected matching '$pattern'. Aborting release."
        exit 1
    fi
done

git add -A

# 4. Git Commit
COMMIT_MSG="chore(release): $TAG - $CHANGELOG"
echo "💾 Committing changes: $COMMIT_MSG"
if git diff --cached --quiet; then
    echo "ℹ️ No changes to commit. Proceeding to tagging."
else
    git commit -m "$COMMIT_MSG"
fi

# 5. Git Tag
if git rev-parse "$TAG" >/dev/null 2>&1; then
    echo "⚠️ Tag '$TAG' already exists. Recreating tag..."
    git tag -d "$TAG"
fi

echo "🏷️ Creating Git tag '$TAG'..."
git tag -a "$TAG" -m "$CHANGELOG"

# 6. Push to Remote
CURRENT_BRANCH=$(git branch --show-current)
echo "📤 Pushing branch '$CURRENT_BRANCH' and tag '$TAG' to origin..."
git push origin "$CURRENT_BRANCH"
git push origin "$TAG"

echo "=================================================================="
echo "🎉 Release $TAG published successfully to GitHub!"
echo "Repository: https://github.com/mustafa3max/hosteday-flutter"
echo "Tag: $TAG"
echo "=================================================================="
