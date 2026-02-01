#!/bin/bash
#
# test_reproducibility.sh - Quick reproducibility test

PASS=0
FAIL=0

check() {
    if eval "$2" > /dev/null 2>&1; then
        echo "✅ $1"
        ((PASS++))
    else
        echo "❌ $1"
        ((FAIL++))
    fi
}

echo "🧪 Reproducibility Test - ClawdColombia"
echo "======================================="
echo ""

echo "📋 Checking critical files..."
check "TACIT.md" "test -f ~/clawd/TACIT.md"
check "SOUL.md" "test -f ~/clawd/SOUL.md"
check "MEMORY.md" "test -f ~/clawd/MEMORY.md"
check "AGENTS.md" "test -f ~/clawd/AGENTS.md"
check "HEARTBEAT.md" "test -f ~/clawd/HEARTBEAT.md"
check "WORKFLOWS.md" "test -f ~/clawd/WORKFLOWS.md"

echo ""
echo "📁 Checking directories..."
check "docs/" "test -d ~/clawd/docs"
check "tools/" "test -d ~/clawd/tools"
check "memory/" "test -d ~/clawd/memory"
check "templates/" "test -d ~/clawd/templates"

echo ""
echo "🔒 Checking BBP compliance..."
check "Strict mode in scripts" "grep -q 'set -euo pipefail' ~/clawd/tools/health_check.sh"
check "BBP documentation" "test -f ~/clawd/docs/BORING_BUILDER_PROTOCOL.md"
check "Curl repros" "test -f ~/clawd/docs/CURL_REPROS.md"
check "Fix security script" "test -f ~/clawd/tools/fix_security.sh"

echo ""
echo "🛠️  Checking tools..."
check "health_check.sh" "test -f ~/clawd/tools/health_check.sh"
check "token_monitor.sh" "test -f ~/clawd/tools/token_monitor.sh"
check "recovery_check.sh" "test -f ~/clawd/tools/recovery_check.sh"
check "checkpoint-manager.sh" "test -f ~/clawd/tools/checkpoint-manager.sh"

echo ""
echo "======================================="
echo "Results: $PASS passed, $FAIL failed"

if [[ $FAIL -eq 0 ]]; then
    echo "✅ REPRODUCIBILITY CHECK PASSED"
    exit 0
else
    echo "❌ Some checks failed"
    exit 1
fi
