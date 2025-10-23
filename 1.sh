#!/bin/bash
# Upstream Linux from v5.4.275 to v5.4.325

# Exit on errors
set -e

START=275
END=289

# Check for clean working directory
if [[ -n $(git status --porcelain) ]]; then
    echo "❌ Working directory is not clean. Please commit or stash your changes first."
    exit 1
fi

# Set upstream URL
UPSTREAM_URL="https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git/"
REMOTE_NAME="temp-upstream"

# Add temporary remote if not exists
if ! git remote | grep -q "$REMOTE_NAME"; then
    git remote add "$REMOTE_NAME" "$UPSTREAM_URL"
fi

for VERSION_NUM in $(seq $START $END); do
    VERSION="v5.4.$VERSION_NUM"
    echo -e "\n============================"
    echo "📥 Fetching $VERSION from Linux stable..."

    if ! git fetch "$REMOTE_NAME" "$VERSION"; then
        echo "❌ Failed to fetch $VERSION. Aborting."
        git remote remove "$REMOTE_NAME"
        exit 1
    fi

    echo "🔀 Merging $VERSION into current branch..."
    set +e
    git merge FETCH_HEAD --allow-unrelated-histories --strategy-option=theirs --no-edit
    MERGE_RESULT=$?
    set -e

    if [ $MERGE_RESULT -eq 0 ]; then
        echo "✅ Merge of $VERSION completed successfully."
    else
        echo "⚠️ Merge had conflicts. Attempting to resolve..."
        for file in $(git diff --name-only --diff-filter=U); do
            git checkout --theirs "$file"
            git add "$file"
        done
        git commit -m "Auto-merged with upstream $VERSION using 'theirs' strategy"
        echo "✅ Conflicts resolved and merge committed for $VERSION."
    fi
done

git remote remove "$REMOTE_NAME"

echo -e "\n🎉 Finished upstreaming from v5.4.$START to v5.4.$END."

