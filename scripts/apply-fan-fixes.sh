#!/usr/bin/env bash
# =============================================================================
# apply-fan-fixes.sh — Production fan control stack for Dell Inspiron 3030
# =============================================================================
#
# Consolidates the best of two independent plans (Claude + Codex audit) into
# one idempotent, migration-aware installer.
#
# What this deploys:
#   1. Moves Python controller to /usr/local/bin/ (out of home dir)
#   2. Externalizes config to /etc/default/quadro-fan-control
#   3. Sets log path to /var/log/quadro-fan-control/
#   4. Tunes fan curve — lower idle floor, earlier ramp
#   5. Applies thermald config with 58°C early trip point
#   6. Sets ACPI platform profile to "quiet" + persists via tmpfiles.d
#   7. Hardens systemd unit with restart limits, watchdog, thermal safety
#   8. Disables fancontrol.service (no config, just noise)
#   9. Masks i8kmon.service (crashes on desktop, cannot control this board)
#  10. Adds daily health check timer + logrotate config
#
# Usage:
#   sudo bash apply-fan-fixes.sh            # install / upgrade
#   sudo bash apply-fan-fixes.sh --check    # health check only (no changes)
#   sudo bash apply-fan-fixes.sh --uninstall
# =============================================================================

set -euo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; BOLD='\033[1m'; NC='\033[0m'
info()    { echo -e "${BLUE}[INFO]${NC}  $*"; }
ok()      { echo -e "${GREEN}[OK]${NC}    $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC}  $*"; }
err()     { echo -e "${RED}[ERROR]${NC} $*"; }
section() { echo -e "\n${BOLD}${BLUE}━━━ $* ━━━${NC}"; }

[[ $EUID -ne 0 ]] && { err "Run as root: sudo bash $0"; exit 1; }

# ---------------------------------------------------------------------------
# Paths (single source of truth)
# ---------------------------------------------------------------------------
CONTROLLER_SRC="/home/aaron/quadro_fan_control.py"
CONTROLLER_DST="/usr/local/bin/quadro-fan-control.py"
SERVICE_UNIT="/etc/systemd/system/quadro-fan.service"
ENV_FILE="/etc/default/quadro-fan-control"
LOG_DIR="/var/log/quadro-fan-control"
LOGROTATE_CONF="/etc/logrotate.d/quadro-fan-control"
THERMALD_CONF="/etc/thermald/thermal-conf.xml"
TMPFILES_CONF="/etc/tmpfiles.d/dell-thermal-quiet.conf"
HEALTH_SERVICE="/etc/systemd/system/quadro-fan-health.service"
HEALTH_TIMER="/etc/systemd/system/quadro-fan-health.timer"
HEALTH_SCRIPT="/usr/local/bin/quadro-fan-health.sh"

# ---------------------------------------------------------------------------
# Health-check-only mode
# ---------------------------------------------------------------------------
if [[ "${1:-}" == "--check" ]]; then
    bash "$HEALTH_SCRIPT" 2>/dev/null || {
        err "Health script not installed yet. Run without --check first."
        exit 1
    }
    exit 0
fi

# ---------------------------------------------------------------------------
# Uninstall
# ---------------------------------------------------------------------------
if [[ "${1:-}" == "--uninstall" ]]; then
    info "Uninstalling fan control stack..."
    for svc in quadro-fan-health.timer quadro-fan-health.service quadro-fan.service; do
        systemctl stop "$svc" 2>/dev/null || true
        systemctl disable "$svc" 2>/dev/null || true
    done
    rm -f "$CONTROLLER_DST" "$ENV_FILE" "$HEALTH_SCRIPT" "$HEALTH_SERVICE" "$HEALTH_TIMER"
    rm -f "$TMPFILES_CONF" "$LOGROTATE_CONF"
    [[ -f "${THERMALD_CONF}.bak-fanfix" ]] && mv "${THERMALD_CONF}.bak-fanfix" "$THERMALD_CONF"
    [[ -f "${CONTROLLER_SRC}.bak-fanfix" ]] && mv "${CONTROLLER_SRC}.bak-fanfix" "$CONTROLLER_SRC"
    systemctl unmask i8kmon.service fancontrol.service 2>/dev/null || true
    systemctl daemon-reload
    systemctl restart thermald 2>/dev/null || true
    ok "Uninstall complete. Reboot to restore BIOS defaults."
    exit 0
fi

echo ""
echo -e "${BOLD}${BLUE}╔══════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}${BLUE}║  Fan Control Stack — Dell Inspiron 3030 / i7-14700  ║${NC}"
echo -e "${BOLD}${BLUE}╚══════════════════════════════════════════════════╝${NC}"
echo ""

# ---------------------------------------------------------------------------
# STEP 1: Move Python controller to system path
# ---------------------------------------------------------------------------
section "Step 1/10 — Install controller to system path"

if [[ ! -f "$CONTROLLER_SRC" ]]; then
    err "Source script not found: $CONTROLLER_SRC"
    err "Ensure quadro_fan_control.py exists in /home/aaron/ first."
    exit 1
fi

# Backup source if not already done
[[ ! -f "${CONTROLLER_SRC}.bak-fanfix" ]] && \
    cp "$CONTROLLER_SRC" "${CONTROLLER_SRC}.bak-fanfix"

# Update the controller: tune curve, lower poll, fix log path, add env file support
python3 - << 'PYFIX'
import re, sys

src = "/home/aaron/quadro_fan_control.py"
dst = "/usr/local/bin/quadro-fan-control.py"

with open(src, "r") as f:
    content = f.read()

# 1. Lower-idle, earlier-ramp fan curve
old_curve_pat = r'FAN_CURVE\s*=\s*\[[\s\S]*?\]'
new_curve = '''FAN_CURVE = [
    (35,  22),   # near-silent idle
    (45,  35),   # light load
    (55,  50),   # moderate
    (62,  65),   # warm
    (70,  80),   # heavy
    (78,  92),   # near-critical ramp-up
    (84, 100),   # full cooling
]'''
content = re.sub(old_curve_pat, new_curve, content, count=1, flags=re.DOTALL)

# 2. Faster polling: 5s -> 3s
content = re.sub(r'POLL_INTERVAL\s*=\s*5', 'POLL_INTERVAL = int(os.environ.get("POLL_INTERVAL", "3"))', content)

# 3. EnvironmentFile support for key settings (read from env with fallbacks)
content = re.sub(r'LOG_INTERVAL\s*=\s*30', 'LOG_INTERVAL = int(os.environ.get("LOG_INTERVAL", "30"))', content)
content = re.sub(r'HYSTERESIS\s*=\s*3', 'HYSTERESIS = int(os.environ.get("HYSTERESIS", "3"))', content)
content = re.sub(r'ALERT_TEMP\s*=\s*85', 'ALERT_TEMP = int(os.environ.get("ALERT_TEMP", "85"))', content)

# 4. Move log to /var/log/quadro-fan-control/
content = re.sub(
    r'LOG_FILE\s*=\s*os\.environ\.get\(\s*\n?\s*"QUADRO_FAN_LOG".*?\)',
    'LOG_FILE = os.environ.get("QUADRO_FAN_LOG", "/var/log/quadro-fan-control/quadro-fan.csv")',
    content,
    count=1,
    flags=re.DOTALL
)

with open(dst, "w") as f:
    f.write(content)

import os, stat
os.chmod(dst, stat.S_IRWXU | stat.S_IRGRP | stat.S_IXGRP | stat.S_IROTH | stat.S_IXOTH)
print(f"Controller written to {dst}")
PYFIX

ok "Controller installed to $CONTROLLER_DST"

# ---------------------------------------------------------------------------
# STEP 2: Create log directory
# ---------------------------------------------------------------------------
section "Step 2/10 — Log directory"

mkdir -p "$LOG_DIR"
# Migrate existing CSV log if present
[[ -f "/home/aaron/quadro_fan_log.csv" ]] && {
    cp /home/aaron/quadro_fan_log.csv "${LOG_DIR}/quadro-fan.csv"
    ok "Migrated existing CSV log to $LOG_DIR/"
}
ok "Log directory ready: $LOG_DIR"

# ---------------------------------------------------------------------------
# STEP 3: Environment file
# ---------------------------------------------------------------------------
section "Step 3/10 — Config environment file"

# Only write if it doesn't exist (preserve user customizations)
if [[ ! -f "$ENV_FILE" ]]; then
    tee "$ENV_FILE" > /dev/null << 'ENVFILE'
# quadro-fan-control configuration
# Edit here — changes take effect after: systemctl restart quadro-fan.service

# Temperature polling interval in seconds (lower = more responsive, more CPU)
POLL_INTERVAL=3

# How often to write a CSV log entry (seconds)
LOG_INTERVAL=30

# Fan speed change threshold to suppress jitter (percent)
HYSTERESIS=3

# Desktop alert threshold (degrees C)
ALERT_TEMP=85

# CSV log path
QUADRO_FAN_LOG=/var/log/quadro-fan-control/quadro-fan.csv
ENVFILE
    ok "Environment file created: $ENV_FILE"
else
    ok "Environment file already exists — preserving user settings: $ENV_FILE"
fi

# ---------------------------------------------------------------------------
# STEP 4: thermald config (4-point curve from 58°C)
# ---------------------------------------------------------------------------
section "Step 4/10 — Thermald config"

[[ -f "$THERMALD_CONF" && ! -f "${THERMALD_CONF}.bak-fanfix" ]] && \
    cp "$THERMALD_CONF" "${THERMALD_CONF}.bak-fanfix" && \
    ok "Backed up original thermald config"

mkdir -p /etc/thermald
tee "$THERMALD_CONF" > /dev/null << 'THERMALD'
<?xml version="1.0"?>
<!--
  Dell Inspiron 3030 / i7-14700 — Tuned thermald config
  4-point RAPL curve. Starts at 58°C to catch power spikes before
  they hit the 85-88°C range seen in production CSV logs.
  Cooling method: RAPL power capping (no direct fan control path exists).
-->
<ThermalConfiguration>
  <Platform>
    <Name>Dell Inspiron 3030</Name>
    <ProductName>*</ProductName>
    <Preference>QUIET</Preference>
    <ThermalZones>
      <ThermalZone>
        <Type>x86_pkg_temp</Type>
        <TripPoints>
          <!-- 58°C: early soft catch — 15% influence, relaxed sample -->
          <TripPoint>
            <SensorType>x86_pkg_temp</SensorType>
            <Temperature>58000</Temperature>
            <type>passive</type>
            <ControlType>SEQUENTIAL</ControlType>
            <CoolingDevice>
              <index>1</index>
              <type>rapl_controller</type>
              <influence>15</influence>
              <SamplingPeriod>10</SamplingPeriod>
            </CoolingDevice>
          </TripPoint>
          <!-- 65°C: moderate throttle -->
          <TripPoint>
            <SensorType>x86_pkg_temp</SensorType>
            <Temperature>65000</Temperature>
            <type>passive</type>
            <ControlType>SEQUENTIAL</ControlType>
            <CoolingDevice>
              <index>2</index>
              <type>rapl_controller</type>
              <influence>35</influence>
              <SamplingPeriod>7</SamplingPeriod>
            </CoolingDevice>
          </TripPoint>
          <!-- 72°C: stronger throttle -->
          <TripPoint>
            <SensorType>x86_pkg_temp</SensorType>
            <Temperature>72000</Temperature>
            <type>passive</type>
            <ControlType>SEQUENTIAL</ControlType>
            <CoolingDevice>
              <index>3</index>
              <type>rapl_controller</type>
              <influence>60</influence>
              <SamplingPeriod>5</SamplingPeriod>
            </CoolingDevice>
          </TripPoint>
          <!-- 80°C: aggressive — fast sample, high influence, before critical -->
          <TripPoint>
            <SensorType>x86_pkg_temp</SensorType>
            <Temperature>80000</Temperature>
            <type>passive</type>
            <ControlType>SEQUENTIAL</ControlType>
            <CoolingDevice>
              <index>4</index>
              <type>rapl_controller</type>
              <influence>85</influence>
              <SamplingPeriod>3</SamplingPeriod>
            </CoolingDevice>
          </TripPoint>
        </TripPoints>
      </ThermalZone>
    </ThermalZones>
  </Platform>
</ThermalConfiguration>
THERMALD

ok "thermald config written (58→65→72→80°C trip points)"

# ---------------------------------------------------------------------------
# STEP 5: Platform profile — quiet + boot persistence
# ---------------------------------------------------------------------------
section "Step 5/10 — ACPI platform profile"

PROFILE_PATH="/sys/firmware/acpi/platform_profile"
if [[ -f "$PROFILE_PATH" ]]; then
    echo "quiet" > "$PROFILE_PATH"
    ok "Live platform profile set to: $(cat $PROFILE_PATH)"
else
    warn "Platform profile sysfs not found (will still persist for next boot)"
fi

tee "$TMPFILES_CONF" > /dev/null << 'TMPFILES'
# Set Dell Inspiron 3030 BIOS thermal profile to "quiet" at boot.
# "quiet" reduces Intel HWP boost aggressiveness, lowering peak PL2.
# Available choices: quiet balanced
w /sys/firmware/acpi/platform_profile - - - - quiet
TMPFILES

systemd-tmpfiles --create "$TMPFILES_CONF" 2>/dev/null && ok "tmpfiles.d rule applied" || \
    warn "tmpfiles.d warnings (will activate on next boot)"

# ---------------------------------------------------------------------------
# STEP 6: Harden quadro-fan.service
# ---------------------------------------------------------------------------
section "Step 6/10 — Harden systemd service unit"

tee "$SERVICE_UNIT" > /dev/null << 'SERVICE'
[Unit]
Description=Aquacomputer Quadro Fan Controller
Documentation=file:///usr/local/bin/quadro-fan-control.py
After=multi-user.target
# Restart up to 5 times in 2 minutes, then give up (avoids crash loops)
StartLimitIntervalSec=120
StartLimitBurst=5

[Service]
Type=simple
EnvironmentFile=/etc/default/quadro-fan-control
ExecStart=/usr/bin/python3 /usr/local/bin/quadro-fan-control.py
Restart=on-failure
RestartSec=5
# Watchdog: restart if service hangs and stops logging for 90s
WatchdogSec=90
# THERMAL SAFETY: if service stops for ANY reason, blast all Quadro fans to 100%
# This prevents a crashed daemon leaving fans at low speed during heavy load
ExecStopPost=/bin/bash -c '\
  for hw in /sys/class/hwmon/hwmon*/name; do \
    [ "$(cat "$hw" 2>/dev/null)" = "quadro" ] || continue; \
    d=$(dirname "$hw"); \
    for i in 1 2 3 4; do echo 255 > "$d/pwm$i" 2>/dev/null || true; done; \
  done'

[Install]
WantedBy=multi-user.target
SERVICE

ok "Service unit hardened (env file, restart limits, watchdog, thermal safety)"

# ---------------------------------------------------------------------------
# STEP 7: Disable noisy dead services
# ---------------------------------------------------------------------------
section "Step 7/10 — Silence dead services"

# i8kmon: crashes at boot (no battery on desktop), cannot control this board's fans
systemctl mask i8kmon.service 2>/dev/null && ok "i8kmon masked" || warn "i8kmon mask had warnings"
systemctl stop i8kmon.service 2>/dev/null || true

# fancontrol: enabled but /etc/fancontrol doesn't exist, causing failed starts
systemctl disable fancontrol.service 2>/dev/null && ok "fancontrol disabled" || warn "fancontrol disable had warnings"
systemctl stop fancontrol.service 2>/dev/null || true

# ---------------------------------------------------------------------------
# STEP 8: Daily health check timer
# ---------------------------------------------------------------------------
section "Step 8/10 — Health monitoring"

tee "$HEALTH_SCRIPT" > /dev/null << 'HEALTHSCRIPT'
#!/usr/bin/env bash
# quadro-fan-health.sh — Daily health check for fan control stack
# Run by systemd timer. Logs to /var/log/quadro-fan-control/health.log
# Fails loudly (journal + log file) if anything is wrong.

LOG="/var/log/quadro-fan-control/health.log"
CSV="/var/log/quadro-fan-control/quadro-fan.csv"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
FAILURES=0

mkdir -p /var/log/quadro-fan-control

log_ok()   { echo "[$TIMESTAMP] OK    $*" | tee -a "$LOG"; }
log_warn() { echo "[$TIMESTAMP] WARN  $*" | tee -a "$LOG"; logger -t quadro-fan-health -p daemon.warning "$*"; (( FAILURES++ )); }
log_fail() { echo "[$TIMESTAMP] FAIL  $*" | tee -a "$LOG"; logger -t quadro-fan-health -p daemon.err "$*"; (( FAILURES++ )); }

echo "[$TIMESTAMP] === Health check start ===" >> "$LOG"

# 1. Check required services active
for svc in quadro-fan.service thermald.service; do
    if systemctl is-active --quiet "$svc"; then
        log_ok "$svc is active"
    else
        log_fail "$svc is NOT active ($(systemctl is-active $svc))"
    fi
done

# 2. Check nuisance services are off
for svc in i8kmon.service fancontrol.service; do
    state=$(systemctl is-active "$svc" 2>/dev/null || echo "inactive")
    if [[ "$state" != "active" ]]; then
        log_ok "$svc is not running ($state)"
    else
        log_warn "$svc is unexpectedly active — check if it was re-enabled"
    fi
done

# 3. Platform profile
if [[ -f /sys/firmware/acpi/platform_profile ]]; then
    profile=$(cat /sys/firmware/acpi/platform_profile)
    if [[ "$profile" == "quiet" ]]; then
        log_ok "Platform profile: $profile"
    else
        log_warn "Platform profile is '$profile' (expected 'quiet') — may allow aggressive turbo"
    fi
fi

# 4. CSV log freshness (should be written every 30s, warn if >10min stale)
if [[ -f "$CSV" ]]; then
    age=$(( $(date +%s) - $(stat -c %Y "$CSV") ))
    if (( age < 600 )); then
        log_ok "CSV log is fresh (${age}s old)"
    else
        log_warn "CSV log is stale (${age}s old) — fan controller may not be writing"
    fi
else
    log_warn "CSV log does not exist yet at $CSV"
fi

# 5. Check for repeated high-temp warnings in last 24h
if [[ -f "$CSV" ]]; then
    # Count entries in last 24h above 84°C
    cutoff=$(date -d "24 hours ago" '+%Y-%m-%d %H:%M:%S')
    hot_count=$(awk -F, -v cutoff="$cutoff" 'NR>1 && $1 >= cutoff && $4+0 >= 84 {count++} END {print count+0}' "$CSV")
    if (( hot_count > 5 )); then
        log_warn "High temp events (>=84°C) in last 24h: $hot_count — consider checking cooling"
    else
        log_ok "High temp events in last 24h: $hot_count (threshold: >5)"
    fi
fi

# 6. Current temp snapshot
for hw in /sys/class/hwmon/hwmon*/name; do
    [[ "$(cat "$hw" 2>/dev/null)" == "coretemp" ]] || continue
    d=$(dirname "$hw")
    temp=$(( $(cat "${d}/temp1_input" 2>/dev/null || echo 0) / 1000 ))
    log_ok "Current CPU package temp: ${temp}°C"
done

echo "[$TIMESTAMP] === Health check end: $FAILURES failure(s) ===" >> "$LOG"

if (( FAILURES > 0 )); then
    echo "HEALTH CHECK FAILED: $FAILURES issue(s). See $LOG"
    exit 1
fi
HEALTHSCRIPT

chmod +x "$HEALTH_SCRIPT"

tee "$HEALTH_SERVICE" > /dev/null << 'HSVC'
[Unit]
Description=Quadro Fan Control Health Check
After=multi-user.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/quadro-fan-health.sh
StandardOutput=journal
StandardError=journal
HSVC

tee "$HEALTH_TIMER" > /dev/null << 'HTIMER'
[Unit]
Description=Daily Quadro Fan Control Health Check
Requires=quadro-fan-health.service

[Timer]
OnBootSec=5min
OnUnitActiveSec=24h
Unit=quadro-fan-health.service

[Install]
WantedBy=timers.target
HTIMER

ok "Health check script installed: $HEALTH_SCRIPT"
ok "Health timer unit created (runs 5min after boot, then daily)"

# ---------------------------------------------------------------------------
# STEP 9: Log rotation
# ---------------------------------------------------------------------------
section "Step 9/10 — Log rotation"

tee "$LOGROTATE_CONF" > /dev/null << 'LOGROTATE'
/var/log/quadro-fan-control/*.csv
/var/log/quadro-fan-control/health.log
{
    daily
    rotate 30
    compress
    delaycompress
    missingok
    notifempty
    create 0644 root root
}
LOGROTATE

ok "logrotate config installed (30-day rolling, daily rotation)"

# ---------------------------------------------------------------------------
# STEP 10: Reload, enable, start everything
# ---------------------------------------------------------------------------
section "Step 10/10 — Reload and start services"

systemctl daemon-reload
systemctl enable quadro-fan.service
systemctl restart thermald
sleep 1
systemctl restart quadro-fan.service
sleep 2
systemctl enable quadro-fan-health.timer
systemctl start quadro-fan-health.timer

ok "All services reloaded and started"

# ---------------------------------------------------------------------------
# VERIFICATION
# ---------------------------------------------------------------------------
section "Verification"

PASS=0; FAIL=0

check() {
    local label="$1" cmd="$2" expect="$3"
    local result; result=$(eval "$cmd" 2>/dev/null || true)
    if echo "$result" | grep -qE "$expect"; then
        ok "$label"
        (( PASS++ ))
    else
        err "$label — got: '$result'"
        (( FAIL++ ))
    fi
}

check "quadro-fan.service active"      "systemctl is-active quadro-fan.service"    "^active$"
check "thermald.service active"        "systemctl is-active thermald.service"       "^active$"
check "quadro-fan-health.timer active" "systemctl is-active quadro-fan-health.timer" "^active$"
check "i8kmon masked/inactive"         "systemctl is-active i8kmon.service"         "inactive|masked|failed"
check "fancontrol disabled/inactive"   "systemctl is-active fancontrol.service"     "inactive|masked|failed"
check "Platform profile quiet"         "cat /sys/firmware/acpi/platform_profile"    "quiet"
check "tmpfiles.d rule exists"         "ls $TMPFILES_CONF"                          "dell-thermal"
check "logrotate config exists"        "ls $LOGROTATE_CONF"                         "quadro-fan"
check "Controller at system path"      "ls $CONTROLLER_DST"                         "quadro-fan-control"
check "Env file exists"                "ls $ENV_FILE"                               "quadro-fan"
check "Log directory exists"           "ls -d $LOG_DIR"                             "quadro-fan-control"

echo ""
info "Recent fan controller log:"
journalctl -u quadro-fan.service --no-pager -n 5 2>/dev/null | sed 's/^/   /'

echo ""
info "Current readings:"
for hw in /sys/class/hwmon/hwmon*/name; do
    name=$(cat "$hw" 2>/dev/null); d=$(dirname "$hw")
    case "$name" in
        coretemp)
            temp=$(( $(cat "${d}/temp1_input" 2>/dev/null || echo 0) / 1000 ))
            echo "   CPU Package:      ${temp}°C"
            ;;
        quadro)
            for i in 1 2 3 4; do
                pwm=$(cat "${d}/pwm${i}" 2>/dev/null || echo "?")
                rpm=$(cat "${d}/fan${i}_input" 2>/dev/null || echo "?")
                pct="?"; [[ "$pwm" =~ ^[0-9]+$ ]] && pct=$(( pwm * 100 / 255 ))
                echo "   Quadro Fan ${i}:     PWM=${pwm} (${pct}%), ${rpm} RPM"
            done
            ;;
        dell_ddv)
            rpm=$(cat "${d}/fan1_input" 2>/dev/null || echo "?")
            echo "   Dell CPU Fan:     ${rpm} RPM (BIOS-controlled)"
            ;;
    esac
done
echo "   Platform profile: $(cat /sys/firmware/acpi/platform_profile 2>/dev/null)"

echo ""
if (( FAIL == 0 )); then
    echo -e "${GREEN}${BOLD}✓ All ${PASS} checks passed.${NC}"
    echo ""
    echo "  Expected behavior:"
    echo "    Idle 35–45°C    →  Quadro fans ~22–35%   (near-silent)"
    echo "    Light 55–62°C   →  Fans ~50–65%,  thermald inactive"
    echo "    Sustained 65–72°C → Fans ~65–80%, thermald gently caps PL2"
    echo "    Heavy 75–80°C   →  Fans ~80–92%, thermald actively limits power"
    echo "    No more 85–88°C repeating spikes — caught at 58°C by thermald"
    echo ""
    echo "  Commands:"
    echo "    Monitor live:      journalctl -u quadro-fan.service -f"
    echo "    Temperature watch: watch -n2 sensors"
    echo "    CSV tail:          tail -f $LOG_DIR/quadro-fan.csv"
    echo "    Health check:      sudo bash $HEALTH_SCRIPT"
    echo "    Tune settings:     sudo nano $ENV_FILE && sudo systemctl restart quadro-fan.service"
    echo "    Uninstall:         sudo bash $0 --uninstall"
else
    echo -e "${RED}${BOLD}✗ ${FAIL} check(s) failed — review output above.${NC}"
    echo "  Run: journalctl -u quadro-fan.service -n 20 --no-pager"
    exit 1
fi
