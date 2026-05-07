@"
# Repo Health Checker

![CI](https://github.com/srimathi-3022/repo_phase1/actions/workflows/check.yml/badge.svg)

This project automatically validates repository health on every push using GitHub Actions.

## What It Checks

- README.md exists and has more than 5 lines
- .gitignore is present in the repo root
- No secret or .env files are accidentally committed
- All commit messages have more than 5 words
- CI workflow file exists at .github/workflows/check.yml
- No files over 5MB are committed

## How to Run Locally

Open Git Bash and run these commands:
chmod +x check.sh
./check.sh

## Result

All checks pass = Green CI badge
Any check fails = Red CI badge

## Project Structure

check.sh is the main validation script
.github/workflows/check.yml is the GitHub Actions workflow
README.md is this documentation file
.gitignore prevents committing unwanted files
"@ | Out-File -FilePath README.md -Encoding utf8 -NoNewline