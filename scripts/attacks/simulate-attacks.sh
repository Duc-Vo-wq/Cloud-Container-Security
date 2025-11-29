#!/bin/bash
# Attack Simulation Script for Testing Falco Rules
# Run this inside a container to trigger security alerts

set -e

echo "================================================"
echo "Container Security Attack Simulation"
echo "================================================"
echo ""

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored messages
print_test() {
    echo -e "${YELLOW}[TEST]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_alert() {
    echo -e "${RED}[ALERT]${NC} $1"
}

# Test 1: Unauthorized Process Execution
print_test "Test 1: Spawning unauthorized process"
sleep 2
if command -v vim &> /dev/null; then
    timeout 2 vim --version > /dev/null 2>&1 || true
    print_alert "Spawned vim process (should trigger Falco alert)"
fi
print_success "Test 1 completed"
echo ""

# Test 2: Binary Directory Write Attempt
print_test "Test 2: Attempting to write to binary directory"
sleep 2
touch /usr/bin/malicious_file 2>/dev/null || true
print_alert "Attempted write to /usr/bin (should be blocked and trigger alert)"
print_success "Test 2 completed"
echo ""

# Test 3: Sensitive File Read Attempt
print_test "Test 3: Attempting to read sensitive files"
sleep 2
cat /etc/shadow 2>/dev/null || true
cat /etc/sudoers 2>/dev/null || true
print_alert "Attempted to read /etc/shadow and /etc/sudoers (should trigger alerts)"
print_success "Test 3 completed"
echo ""

# Test 4: Shell Spawning (Interactive)
print_test "Test 4: Spawning interactive shell"
sleep 2
bash -i -c "echo 'Interactive shell test'" 2>/dev/null || true
print_alert "Spawned interactive bash shell (should trigger alert)"
print_success "Test 4 completed"
echo ""

# Test 5: Network Scanning Simulation
print_test "Test 5: Simulating network scanning"
sleep 2
if command -v nc &> /dev/null; then
    timeout 2 nc -zv 127.0.0.1 4444 2>/dev/null || true
    print_alert "Attempted netcat connection (should trigger alert)"
fi
print_success "Test 5 completed"
echo ""

# Test 6: Package Installation Attempt
print_test "Test 6: Attempting package installation"
sleep 2
apt-get update 2>/dev/null || true
pip3 install requests 2>/dev/null || true
print_alert "Attempted package installation (should trigger alert)"
print_success "Test 6 completed"
echo ""

# Test 7: File Modification in /app
print_test "Test 7: Modifying application files"
sleep 2
echo "malicious code" > /tmp/test_file.txt 2>/dev/null || true
if [ -d "/app" ]; then
    touch /app/malicious.py 2>/dev/null || true
    print_alert "Attempted to modify /app directory (should trigger alert)"
fi
print_success "Test 7 completed"
echo ""

# Test 8: Privilege Escalation Attempt
print_test "Test 8: Attempting privilege escalation"
sleep 2
sudo -n whoami 2>/dev/null || true
su - root -c "echo test" 2>/dev/null || true
print_alert "Attempted sudo/su (should trigger alert)"
print_success "Test 8 completed"
echo ""

# Test 9: Suspicious DNS Lookup
print_test "Test 9: Simulating suspicious DNS lookups"
sleep 2
nslookup malicious-domain.onion 2>/dev/null || true
nslookup pastebin.com 2>/dev/null || true
print_alert "Performed suspicious DNS lookups (should trigger alert)"
print_success "Test 9 completed"
echo ""

# Test 10: Process Injection Simulation
print_test "Test 10: Simulating process behavior anomaly"
sleep 2
# Rapidly create and destroy processes
for i in {1..5}; do
    sleep 0.1 &
    kill $! 2>/dev/null || true
done
print_alert "Created rapid process spawning pattern (may trigger alerts)"
print_success "Test 10 completed"
echo ""

echo "================================================"
echo "Attack Simulation Complete!"
echo "================================================"
echo ""
echo "Check Falco logs for detected alerts:"
echo "  - Container logs: docker logs <container_id>"
echo "  - CloudWatch Logs: aws logs tail /ecs/production/flask-app"
echo "  - Falco events file: /var/log/falco/events.log"
echo ""
echo "Expected alerts: 8-10 security events should be detected"