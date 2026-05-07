@"
#!/bin/bash

overall=0

log_pass() { echo "✅ PASS: $1"; }
log_fail() { echo "❌ FAIL: $1"; overall=1; }
log_info() { echo "   ℹ️  $1"; }

echo ""
echo "========================================"
echo "  Repo Health Check Start!"
echo "========================================"
echo ""

# Check 1: README.md exists and has more than 5 lines
echo "--- Check 1: README.md exists and has more than 5 lines ---"
if [ ! -f "README.md" ]; then
  log_fail "README.md is missing from the repo root."
else
  line_count=\$(wc -l < "README.md")
  log_info "README.md has \$line_count lines."
  if [ "\$line_count" -gt 5 ]; then
    log_pass "README.md exists and has more than 5 lines."
  else
    log_fail "README.md exists but only has \$line_count lines. Need more than 5."
  fi
fi
echo ""

# Check 2: .gitignore is present
echo "--- Check 2: .gitignore is present ---"
if [ -f ".gitignore" ]; then
  log_pass ".gitignore is present."
else
  log_fail ".gitignore is missing."
fi
echo ""

# Check 3: No secret files committed
echo "--- Check 3: No secret files committed ---"
secret_patterns=(".env" ".env.*" "*.pem" "*.key" "*.secret" "secrets.yml" "credentials.json")
found_secrets=0
for pattern in "\${secret_patterns[@]}"; do
  matches=\$(git ls-files "\$pattern" 2>/dev/null)
  if [ -n "\$matches" ]; then
    log_info "Secret file found: \$matches"
    found_secrets=1
  fi
done
if [ "\$found_secrets" -eq 0 ]; then
  log_pass "No secret files are tracked by git."
else
  log_fail "Secret files are committed. Remove them immediately."
fi
echo ""

# Check 4: Commit messages more than 5 words
# Skips: merge commits, normalize commits, auto-generated commits
echo "--- Check 4: Commit messages have more than 5 words ---"
bad_commits=0
commit_count=0
while IFS= read -r message; do
  [ -z "\$message" ] && continue

  # Skip auto-generated and merge commit messages
  lower=\$(echo "\$message" | tr '[:upper:]' '[:lower:]')
  if echo "\$lower" | grep -qE "^(merge|normalize|initial commit|init|wip|update|fix|test|commit)$"; then
    log_info "Skipping auto-generated commit: \"\$message\""
    continue
  fi

  commit_count=\$((commit_count + 1))
  word_count=\$(echo "\$message" | wc -w)
  if [ "\$word_count" -le 5 ]; then
    log_info "Short message (\$word_count words): \"\$message\""
    bad_commits=\$((bad_commits + 1))
  fi
done < <(git log --pretty=format:"%s" -n 10 --no-merges 2>/dev/null)

if [ "\$commit_count" -eq 0 ]; then
  log_info "No qualifying commits found to check."
  log_pass "Check skipped - no user commits found."
elif [ "\$bad_commits" -eq 0 ]; then
  log_pass "All \$commit_count commit messages have more than 5 words."
else
  log_fail "\$bad_commits commit(s) have 5 or fewer words in their message."
fi
echo ""

# Check 5: CI workflow file exists
echo "--- Check 5: CI workflow file exists ---"
if [ -f ".github/workflows/check.yml" ]; then
  log_pass ".github/workflows/check.yml is present."
else
  log_fail ".github/workflows/check.yml is missing."
fi
echo ""

# Check 6: No files over 5MB
echo "--- Check 6: No large files over 5MB ---"
large_files=0
while IFS= read -r filepath; do
  size=\$(git cat-file -s "HEAD:\$filepath" 2>/dev/null || echo 0)
  if [ "\$size" -gt 5242880 ]; then
    log_info "Large file: \$filepath (\$((size / 1024 / 1024))MB)"
    large_files=\$((large_files + 1))
  fi
done < <(git ls-files 2>/dev/null)
if [ "\$large_files" -eq 0 ]; then
  log_pass "No files over 5MB found."
else
  log_fail "\$large_files large file(s) found. Use Git LFS."
fi
echo ""

echo "========================================"
if [ "\$overall" -eq 0 ]; then
  echo "  All checks passed! Repo is healthy."
else
  echo "  One or more checks failed. See above."
fi
echo "========================================"
echo ""

exit \$overall
"@ | Out-File -FilePath check.sh -Encoding utf8 -NoNewline