#!/usr/bin/env bash
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color
PASS=0
FAIL=0

check() {
    local name="$1"
    local cmd="$2"
    echo -n "=== $name ... "
    if eval "$cmd" > /tmp/ansible-test-$$.log 2>&1; then
        echo -e "${GREEN}PASS${NC}"
        PASS=$((PASS + 1))
    else
        echo -e "${RED}FAIL${NC}"
        cat /tmp/ansible-test-$$.log
        FAIL=$((FAIL + 1))
    fi
}

echo "============================================"
echo " Ansible Infrastructure Layer Tests"
echo "============================================"
echo ""

check "Syntax check (01-infra.yml)" \
    "ansible-playbook --syntax-check playbooks/01-infra.yml"

check "Syntax check (02-k3s.yml)" \
    "ansible-playbook --syntax-check playbooks/02-k3s.yml"

check "Syntax check (02.5-kubeconfig.yml)" \
    "ansible-playbook --syntax-check playbooks/02.5-kubeconfig.yml"

check "Syntax check (03-traefik.yml)" \
    "ansible-playbook --syntax-check playbooks/03-traefik.yml"

check "Syntax check (04-metallb.yml)" \
    "ansible-playbook --syntax-check playbooks/04-metallb.yml"

check "Syntax check (05-longhorn.yml)" \
    "ansible-playbook --syntax-check playbooks/05-longhorn.yml"

check "Syntax check (06-prometheus.yml)" \
    "ansible-playbook --syntax-check playbooks/06-prometheus.yml"

check "Syntax check (07-loki.yml)" \
    "ansible-playbook --syntax-check playbooks/07-loki.yml"

check "Syntax check (08-argocd.yml)" \
    "ansible-playbook --syntax-check playbooks/08-argocd.yml"

check "Syntax check (09-external-db.yml)" \
    "ansible-playbook --syntax-check playbooks/09-external-db.yml"

check "Syntax check (10-fission.yml)" \
    "ansible-playbook --syntax-check playbooks/10-fission.yml"

check "Ansible-lint" \
    "ansible-lint --version && ansible-lint ."

echo ""
echo "============================================"
echo -e "Results: ${GREEN}${PASS} passed${NC}, ${RED}${FAIL} failed${NC}"
echo "============================================"

# Cleanup
rm -f /tmp/ansible-test-$$.log

exit $FAIL
