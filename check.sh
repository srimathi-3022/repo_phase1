#!/bin/bash

# ============================================================
# Repo Health Checker — check.sh
# Runs validation checks on the repository.
# exit 0 = all checks passed | exit 1 = at least one check failed
# ============================================================

PASS=0
FAIL=1
overall=0

log_pass() { echo "✅ PASS: $1"; }
log_fail() { echo "❌ FAIL: $1"; overall=1; }
log_info() { echo "   ℹ️  $1"; }

echo ""
echo "========================================"
echo "  🔍 Repo Health Check"
echo "========================================"
echo ""

# -------------------------------------------------------
# CHECK 1: README.md exists and has more than 5 lines
# -------------------------------------------------------
echo "--- Check 1: README.md exists and has >5 lines ---"
if [ ! -f "README.md" ]; then
  log_fail "README.md is missing from the repo root."
else
  line_count=$(wc -l < "README.md")
  log_info "README.md has $line_count lines."
  if [ "$line_count" -gt 5 ]; then
    log_pass "README.md exists and has more than 5 lines."
  else
    log_fail "README.md exists but only has $line_count lines. Need more than 5."
  fi
fi

echo ""

# -------------------------------------------------------
# CHECK 2: .gitignore is present
# -------------------------------------------------------
echo "--- Check 2: .gitignore is present ---"
if [ -f ".gitignore" ]; then
  log_pass ".gitignore is present."
else
  log_fail ".gitignore is missing. Add one to prevent committing unwanted files."
fi

echo ""

# -------------------------------------------------------
# CHECK 3: No .env or secret files are committed
# -------------------------------------------------------
echo "--- Check 3: No .env or secret files committed ---"
secret_patterns=(".env" ".env.*" "*.pem" "*.key" "*.secret" "secrets.yml" "secrets.yaml" "credentials.json")
found_secrets=0

for pattern in "${secret_patterns[@]}"; do
  # Search tracked files only (not the working tree)
  matches=$(git ls-files "$pattern" 2>/dev/null)
  if [ -n "$matches" ]; then
    log_info "Potentially secret file found in git: $matches"
    found_secrets=1
  fi
done

if [ "$found_secrets" -eq 0 ]; then
  log_pass "No .env or secret files are tracked by git."
else
  log_fail "Secret or .env files are committed. Remove them and add to .gitignore."
fi

echo ""

# -------------------------------------------------------
# CHECK 4: All commit messages have more than 5 words
# -------------------------------------------------------
echo "--- Check 4: All commit messages have more than 5 words ---"

# Get the last 20 commits (or all if fewer)
bad_commits=0
commit_count=0

while IFS= read -r message; do
  [ -z "$message" ] && continue
  commit_count=$((commit_count + 1))
  word_count=$(echo "$message" | wc -w)
  if [ "$word_count" -le 5 ]; then
    log_info "Short commit message ($word_count words): \"$message\""
    bad_commits=$((bad_commits + 1))
  fi
done < <(git log --pretty=format:"%s" -n 20 2>/dev/null)

if [ "$commit_count" -eq 0 ]; then
  log_info "No commits found to check."
elif [ "$bad_commits" -eq 0 ]; then
  log_pass "All $commit_count recent commit messages have more than 5 words."
else
  log_fail "$bad_commits of $commit_count recent commit(s) have 5 or fewer words in their message."
fi

echo ""

# -------------------------------------------------------
# CHECK 5: GitHub Actions workflow file exists
# -------------------------------------------------------
echo "--- Check 5: CI workflow file exists ---"
if [ -f ".github/workflows/check.yml" ]; then
  log_pass ".github/workflows/check.yml is present."
else
  log_fail ".github/workflows/check.yml is missing. CI cannot run without it."
fi

echo ""

# -------------------------------------------------------
# CHECK 6: No large files over 5MB committed
# -------------------------------------------------------
echo "--- Check 6: No large files (>5MB) committed ---"
large_files=0

while IFS= read -r filepath; do
  size=$(git cat-file -s "HEAD:$filepath" 2>/dev/null || echo 0)
  if [ "$size" -gt 5242880 ]; then
    log_info "Large file detected: $filepath ($((size / 1024 / 1024))MB)"
    large_files=$((large_files + 1))
  fi
done < <(git ls-files 2>/dev/null)

if [ "$large_files" -eq 0 ]; then
  log_pass "No files over 5MB found in the repository."
else
  log_fail "$large_files large file(s) found. Consider using Git LFS or removing them."
fi

echo ""

# -------------------------------------------------------
# RESULTS SUMMARY
# -------------------------------------------------------
echo "========================================"
if [ "$overall" -eq 0 ]; then
  echo "  🎉 All checks passed! Repo is healthy."
else
  echo "  🚨 One or more checks failed. See above."
fi
echo "========================================"
echo ""

exit $overall