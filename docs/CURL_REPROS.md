# 🌐 Curl Repros - API Testing Patterns

**Boring Builder Protocol - Principle 4: Reduce problems to curl repros**

Este documento contiene comandos curl mínimos para probar y depurar APIs comunes.

---

## Clawdbot API

### Status Check
```bash
# Check gateway status
clawdbot status

# Get token usage (parse from output)
clawdbot status | grep -E 'kimi-for-coding.*[0-9]+k/[0-9]+k'
```

---

## Moltbook API

### Authentication Test
```bash
API_KEY=$(grep '"api_key"' ~/.config/moltbook/credentials.json | head -1 | sed 's/.*: "//;s/".*//')

curl -s -H "Authorization: Bearer $API_KEY" \
  https://www.moltbook.com/api/v1/posts?limit=1 | jq '.success'
```

### Get Posts
```bash
API_KEY=$(grep '"api_key"' ~/.config/moltbook/credentials.json | head -1 | sed 's/.*: "//;s/".*//')

curl -s -H "Authorization: Bearer $API_KEY" \
  "https://www.moltbook.com/api/v1/posts?sort=hot&limit=5" | jq '.posts[].title'
```

### Create Post
```bash
API_KEY=$(grep '"api_key"' ~/.config/moltbook/credentials.json | head -1 | sed 's/.*: "//;s/".*//')

curl -s -X POST "https://www.moltbook.com/api/v1/posts" \
  -H "Authorization: Bearer $API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "submolt": "ponderings",
    "title": "Test post",
    "content": "This is a test"
  }' | jq '.'
```

### Get User Profile
```bash
API_KEY=$(grep '"api_key"' ~/.config/moltbook/credentials.json | head -1 | sed 's/.*: "//;s/".*//')

curl -s -H "Authorization: Bearer $API_KEY" \
  https://www.moltbook.com/api/v1/users/me | jq '.name'
```

---

## Shipyard API

### List Ships
```bash
API_KEY=$(grep '"api_key"' ~/.config/shipyard/credentials.json | head -1 | sed 's/.*: "//;s/".*//')

curl -s -H "Authorization: Bearer $API_KEY" \
  https://shipyard.bot/api/v1/ships | jq '.ships[].title'
```

### Create Ship
```bash
API_KEY=$(grep '"api_key"' ~/.config/shipyard/credentials.json | head -1 | sed 's/.*: "//;s/".*//')

curl -s -X POST "https://shipyard.bot/api/v1/ships" \
  -H "Authorization: Bearer $API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "title": "My Tool",
    "description": "Does something useful",
    "proof_url": "https://github.com/clawdColbot/my-tool"
  }' | jq '.'
```

---

## GitHub API

### Rate Limit Check
```bash
curl -s -H "Authorization: token $(gh auth token)" \
  https://api.github.com/rate_limit | jq '.rate.remaining'
```

### Get Repo Info
```bash
curl -s https://api.github.com/repos/clawdColbot/clawd | jq '.stargazers_count'
```

### List Commits
```bash
curl -s https://api.github.com/repos/clawdColbot/clawd/commits | jq '.[0].commit.message'
```

---

## Telegram Bot API

### Get Bot Info
```bash
TOKEN="YOUR_BOT_TOKEN"
curl -s "https://api.telegram.org/bot${TOKEN}/getMe" | jq '.result.username'
```

### Get Updates
```bash
TOKEN="YOUR_BOT_TOKEN"
curl -s "https://api.telegram.org/bot${TOKEN}/getUpdates?limit=5" | jq '.result[].message.text'
```

### Send Message
```bash
TOKEN="YOUR_BOT_TOKEN"
CHAT_ID="YOUR_CHAT_ID"
curl -s -X POST "https://api.telegram.org/bot${TOKEN}/sendMessage" \
  -d "chat_id=${CHAT_ID}" \
  -d "text=Hello from curl"
```

---

## File System Tests

### Check File Exists
```bash
test -f ~/clawd/MEMORY.md && echo "exists" || echo "missing"
```

### Check Directory
```bash
test -d ~/clawd/memory/life && echo "exists" || echo "missing"
```

### Check Permissions
```bash
stat -c "%a" ~/.clawdbot/.env
# Expected: 600
```

---

## JSON Parsing Tests

### Parse Token Usage
```bash
# From clawdbot status
clawdbot status | grep -E 'kimi-for-coding.*[0-9]+k/[0-9]+k' | grep -oE '\([0-9]+%\)' | grep -oE '[0-9]+'
```

### Parse State File
```bash
jq '.projects.propiedades-mvp.status' ~/clawd/memory/state.json
```

---

## Network Tests

### Test Connectivity
```bash
# Test general connectivity
ping -c 1 google.com > /dev/null && echo "online" || echo "offline"

# Test specific endpoint
curl -s --max-time 5 -o /dev/null -w "%{http_code}" https://api.github.com
```

### DNS Resolution
```bash
nslookup google.com > /dev/null && echo "DNS OK" || echo "DNS FAIL"
```

---

## Process Tests

### Check if Process Running
```bash
pgrep -x "clawdbot" > /dev/null && echo "running" || echo "stopped"
```

### Check Port
```bash
# Check if port is open
nc -z localhost 8080 && echo "open" || echo "closed"
```

---

## Error Handling Patterns

### Fail on Error
```bash
set -e
command_that_might_fail || { echo "Failed"; exit 1; }
```

### Timeout Pattern
```bash
timeout 30 curl -s https://api.example.com || { echo "Timeout"; exit 1; }
```

### Retry Pattern
```bash
for i in {1..3}; do
  curl -s https://api.example.com && break || sleep 2
done
```

---

## Debugging Tips

### Verbose Mode
```bash
# Add -v for verbose output
curl -v -s https://api.example.com
```

### Save Response
```bash
# Save full response for inspection
curl -s https://api.example.com -o /tmp/response.json
jq . /tmp/response.json
```

### Check Headers
```bash
# Check response headers
curl -s -I https://api.example.com
```

---

## Quick Reference

| Task | Command |
|------|---------|
| Test API | `curl -s --max-time 5 URL` |
| Parse JSON | `curl -s URL \| jq '.field'` |
| Check auth | `curl -s -H "Authorization: Bearer TOKEN" URL` |
| POST data | `curl -s -X POST -d '{"key":"value"}' URL` |
| Check file | `test -f PATH && echo OK` |
| Check process | `pgrep NAME > /dev/null` |

---

**Template version:** 1.0  
**Last updated:** 2026-02-01
