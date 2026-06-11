#!/bin/bash
# Start all services locally

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SERVICES_DIR="$(dirname "$SCRIPT_DIR")"
cd "${SERVICES_DIR}"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}   Run Microservices Locally            ${NC}"
echo -e "${BLUE}========================================${NC}"
echo -e ""

# Check if docker-compose.yml exists
if [ ! -f "docker-compose.yml" ]; then
    echo -e "${RED}❌ docker-compose.yml not found!${NC}"
    exit 1
fi

# Check Docker
if ! docker info > /dev/null 2>&1; then
    echo -e "${RED}❌ Docker is not running. Start Docker first.${NC}"
    exit 1
fi

echo -e "${YELLOW}🚀 Starting infrastructure (Postgres + LocalStack)...${NC}"
docker compose up -d postgres localstack

echo -e "${YELLOW}⏳ Waiting for Postgres...${NC}"
until docker compose exec -T postgres pg_isready -U postgres > /dev/null 2>&1; do
    echo -n "."
    sleep 2
done
echo -e ""
echo -e "${GREEN}✅ Postgres is ready${NC}"

echo -e "${YELLOW}⏳ Waiting for LocalStack (15 seconds)...${NC}"
sleep 15
echo -e "${GREEN}✅ LocalStack should be ready${NC}"

echo -e ""
echo -e "${YELLOW}🚀 Building and starting microservices...${NC}"
docker compose up -d --build

echo -e ""
echo -e "${GREEN}✅ All services are running!${NC}"
echo -e ""
echo -e "${BLUE}📍 Service URLs:${NC}"
echo -e "  Product Service:  ${GREEN}http://localhost:8001${NC}"
echo -e "  Cart Service:     ${GREEN}http://localhost:8002${NC}"
echo -e "  User Service:     ${GREEN}http://localhost:8003${NC}"
echo -e "  Order Service:    ${GREEN}http://localhost:8004${NC}"
echo -e "  Shipping Service: ${GREEN}http://localhost:8005${NC}"
echo -e ""
echo -e "${YELLOW}📋 Quick checks:${NC}"
echo -e "  curl http://localhost:8001/health"
echo -e "  curl http://localhost:8005/health"
echo -e ""
echo -e "${YELLOW}🛑 To stop:${NC}"
echo -e "  cd ${SERVICES_DIR} && docker compose down"