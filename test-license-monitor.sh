#!/bin/bash

# Color definitions
red="\e[38;5;196m"
green="\e[38;5;82m"
yellow="\e[38;5;226m"
blue="\e[38;5;39m"
neutral="\e[0m"
gray="\e[38;5;245m"

echo -e "${blue}=== Test Alrescha79 VPN License Monitor ===${neutral}"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo -e "${red}Error: Script ini harus dijalankan sebagai root${neutral}"
    exit 1
fi

echo -e "${yellow}Testing License Monitor Installation...${neutral}"
echo ""

# Test 1: Check if main script exists
echo -e "${blue}1. Checking main script...${neutral}"
if [ -f "/usr/bin/check-license" ] && [ -x "/usr/bin/check-license" ]; then
    echo -e "${green}   ✓ check-license script exists and executable${neutral}"
else
    echo -e "${red}   ✗ check-license script not found or not executable${neutral}"
    exit 1
fi

# Test 2: Check systemd files
echo -e "${blue}2. Checking systemd files...${neutral}"
if [ -f "/etc/systemd/system/license-monitor.service" ]; then
    echo -e "${green}   ✓ license-monitor.service exists${neutral}"
else
    echo -e "${red}   ✗ license-monitor.service not found${neutral}"
fi

if [ -f "/etc/systemd/system/license-monitor.timer" ]; then
    echo -e "${green}   ✓ license-monitor.timer exists${neutral}"
else
    echo -e "${red}   ✗ license-monitor.timer not found${neutral}"
fi

# Test 3: Check timer status
echo -e "${blue}3. Checking timer status...${neutral}"
if systemctl is-enabled license-monitor.timer >/dev/null 2>&1; then
    echo -e "${green}   ✓ Timer is enabled${neutral}"
else
    echo -e "${red}   ✗ Timer is not enabled${neutral}"
fi

if systemctl is-active license-monitor.timer >/dev/null 2>&1; then
    echo -e "${green}   ✓ Timer is active${neutral}"
else
    echo -e "${red}   ✗ Timer is not active${neutral}"
fi

# Test 4: Check log directory
echo -e "${blue}4. Checking log directory...${neutral}"
if [ -d "/var/log/setup" ]; then
    echo -e "${green}   ✓ Log directory exists${neutral}"
else
    echo -e "${red}   ✗ Log directory not found${neutral}"
    mkdir -p /var/log/setup
    echo -e "${yellow}   → Created log directory${neutral}"
fi

# Test 5: Test script execution
echo -e "${blue}5. Testing script execution...${neutral}"
echo -e "${gray}   Running: check-license --help${neutral}"
if /usr/bin/check-license >/dev/null 2>&1; then
    echo -e "${green}   ✓ Script executes without errors${neutral}"
else
    echo -e "${red}   ✗ Script execution failed${neutral}"
fi

# Test 6: Check current status
echo -e "${blue}6. Checking current license status...${neutral}"
if [ -f "/var/log/setup/license_status" ]; then
    license_status=$(cat /var/log/setup/license_status)
    echo -e "${green}   ✓ License status file exists: ${license_status}${neutral}"
else
    echo -e "${yellow}   ⚠ License status file not found (normal for fresh install)${neutral}"
fi

if [ -f "/var/log/setup/services_status" ]; then
    services_status=$(cat /var/log/setup/services_status)
    echo -e "${green}   ✓ Services status file exists: ${services_status}${neutral}"
else
    echo -e "${yellow}   ⚠ Services status file not found (normal for fresh install)${neutral}"
fi

# Test 7: Check next timer run
echo -e "${blue}7. Checking timer schedule...${neutral}"
next_run=$(systemctl list-timers license-monitor.timer --no-pager 2>/dev/null | grep license-monitor | awk '{print $1" "$2}')
if [ -n "$next_run" ]; then
    echo -e "${green}   ✓ Next run scheduled: ${next_run}${neutral}"
else
    echo -e "${yellow}   ⚠ Could not determine next run time${neutral}"
fi

# Test 8: Manual test (optional)
echo ""
echo -e "${blue}8. Manual test (optional):${neutral}"
read -p "   Do you want to run a manual license check? (y/n): " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${yellow}   Running manual license check...${neutral}"
    /usr/bin/check-license --check
fi

echo ""
echo -e "${green}=== Test Summary ===${neutral}"

# Count tests
total_tests=7
passed_tests=0

# Recheck all tests for summary
[ -f "/usr/bin/check-license" ] && [ -x "/usr/bin/check-license" ] && ((passed_tests++))
[ -f "/etc/systemd/system/license-monitor.service" ] && ((passed_tests++))
[ -f "/etc/systemd/system/license-monitor.timer" ] && ((passed_tests++))
systemctl is-enabled license-monitor.timer >/dev/null 2>&1 && ((passed_tests++))
systemctl is-active license-monitor.timer >/dev/null 2>&1 && ((passed_tests++))
[ -d "/var/log/setup" ] && ((passed_tests++))
/usr/bin/check-license >/dev/null 2>&1 && ((passed_tests++))

if [ $passed_tests -eq $total_tests ]; then
    echo -e "${green}✅ All tests passed ($passed_tests/$total_tests)${neutral}"
    echo -e "${green}License Monitor is properly installed and configured!${neutral}"
else
    echo -e "${yellow}⚠️  Some tests failed ($passed_tests/$total_tests passed)${neutral}"
    echo -e "${yellow}License Monitor may need attention.${neutral}"
fi

echo ""
echo -e "${blue}Useful commands:${neutral}"
echo -e "  check-license --status         : Check current status"
echo -e "  check-license --check          : Manual license check"
echo -e "  systemctl status license-monitor.timer : Check timer status"
echo -e "  journalctl -u license-monitor.service  : View logs"