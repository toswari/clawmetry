#!/bin/bash
# ClawMetry — Docker installer
# Usage: curl -fsSL https://raw.githubusercontent.com/toswari/clawmetry/main/install-docker.sh | bash
#
# This script pulls the latest ClawMetry Docker image and runs it.
set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

echo ""
echo -e "  ${BOLD}🦞 ClawMetry${NC}  ${DIM}AI Observability for OpenClaw${NC}"
echo -e "  ${DIM}Docker Installer${NC}"
echo -e "  $(printf '%.0s─' {1..50})"
echo ""

# ── Check Docker ────────────────────────────────────────────────────────────────

if ! command -v docker &>/dev/null; then
    echo -e "${RED}  ✗ Docker not found. Install Docker first: https://docs.docker.com/get-docker/${NC}"
    exit 1
fi

echo -e "  ${GREEN}✓${NC} Docker found: $(docker --version)"

# ── Pull Docker Image ──────────────────────────────────────────────────────────

echo ""
echo -e "  → Pulling latest ClawMetry Docker image..."

IMAGE_NAME="${CLAWMETRY_IMAGE:-toswari/clawmetry:latest}"

docker pull "$IMAGE_NAME" 2>&1 | tail -5

echo -e "  ${GREEN}✓${NC} Image pulled: $IMAGE_NAME"

# ── Create Data Volume ──────────────────────────────────────────────────────────

echo ""
echo -e "  → Creating data volume..."

docker volume create clawmetry-data >/dev/null 2>&1 || true

echo -e "  ${GREEN}✓${NC} Volume created: clawmetry-data"

# ── Stop Existing Container ─────────────────────────────────────────────────────

echo ""
echo -e "  → Checking for existing container..."

if docker ps -a --format '{{.Names}}' | grep -q "^clawmetry$"; then
    echo -e "  ${DIM}→ Stopping existing container...${NC}"
    docker stop clawmetry >/dev/null 2>&1 || true
    docker rm clawmetry >/dev/null 2>&1 || true
    echo -e "  ${GREEN}✓${NC} Removed old container"
fi

# ── Start Container ─────────────────────────────────────────────────────────────

echo ""
echo -e "  → Starting ClawMetry container..."

# Get host IP for OpenClaw integration
HOST_IP=$(ip route get 1.1.1.1 2>/dev/null | grep -oP 'src \K\S+' || echo "host.docker.internal")

docker run -d \
    --name clawmetry \
    --restart unless-stopped \
    -p 8900:8900 \
    -v clawmetry-data:/root/.clawmetry \
    -v /tmp/moltbot:/tmp/moltbot \
    -e CLAWMETRY_HOST="0.0.0.0" \
    -e CLAWMETRY_PORT="8900" \
    -e OPENCLAW_DIR="/openclaw" \
    --add-host=host.docker.internal:host-gateway \
    "$IMAGE_NAME"

sleep 3

# ── Health Check ────────────────────────────────────────────────────────────────

echo ""
echo -e "  → Waiting for startup..."

for i in {1..30}; do
    if curl -sf http://localhost:8900/api/health >/dev/null 2>&1; then
        echo -e "  ${GREEN}✓${NC} ClawMetry is healthy"
        break
    fi
    if [ $i -eq 30 ]; then
        echo -e "  ${YELLOW}⚠${NC} Container started but health check pending..."
    fi
    sleep 1
done

# ── Show Status ─────────────────────────────────────────────────────────────────

echo ""
echo -e "  $(printf '%.0s─' {1..50})"
echo ""
echo -e "  ${GREEN}${BOLD}✓ ClawMetry installed in Docker!${NC}"
echo ""
echo -e "  ${BOLD}Access the dashboard:${NC}"
echo -e "    ${BLUE}http://localhost:8900${NC}"
echo ""
echo -e "  ${BOLD}Useful commands:${NC}"
echo -e "    ${DIM}# View logs${NC}"
echo -e "    ${GREEN}docker logs -f clawmetry${NC}"
echo ""
echo -e "    ${DIM}# Stop container${NC}"
echo -e "    ${GREEN}docker stop clawmetry${NC}"
echo ""
echo -e "    ${DIM}# Start container${NC}"
echo -e "    ${GREEN}docker start clawmetry${NC}"
echo ""
echo -e "    ${DIM}# Remove container${NC}"
echo -e "    ${GREEN}docker rm -f clawmetry${NC}"
echo ""
echo -e "    ${DIM}# Update to latest version${NC}"
echo -e "    ${GREEN}bash install-docker.sh${NC}"
echo ""
echo -e "  ${BOLD}OpenClaw Integration:${NC}"
echo -e "    ${DIM}To monitor an OpenClaw instance, set the environment variable:${NC}"
echo -e "    ${GREEN}OPENCLAW_DIR=/path/to/.openclaw${NC}"
echo ""
echo -e "    ${DIM}Then restart with:${NC}"
echo -e "    ${GREEN}docker run -d --name clawmetry -p 8900:8900 \\${NC}"
echo -e "      ${GREEN}-v /path/to/.openclaw:/openclaw:ro \\${NC}"
echo -e "      ${GREEN}clawmetry:latest${NC}"
echo ""
echo -e "  $(printf '%.0s─' {1..50})"
echo ""