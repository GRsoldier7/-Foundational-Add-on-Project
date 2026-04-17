#!/usr/bin/env bash
# =============================================================================
# fix-fan-control.sh — Fix fan control on Dell Inspiron 3030 + Aquacomputer Quadro
# =============================================================================
#
# Problems solved:
#   1. Quadro fans running at fixed speed (no dynamic temp-based curve)
#   2. Dell BIOS fan using bang-bang (on/off) instead of smooth ramping
#   3. thermald config tuned for quieter, smoother thermal management
#
# What this script does:
#   - Creates a systemd service (quadro-fan-curve) that reads CPU package temp
#     and writes proportional PWM values to the Quadro's 4 fan channels
#   - Tunes thermald for smoother trip points on the i7-14700
#   - Disables the broken i8kmon service (crashes on desktops, can't control fans)
#   - Sets platform thermal profile to "quiet" for less aggressive BIOS fan behavior
#
# Usage:
#   sudo bash fix-fan-control.sh
#
# To uninstall:
#   sudo bash fix-fan-control.sh --uninstall
#
# =============================================================================

set -euo pipefail

# ---------------------------------------------------------------------------
# Color helpers
# ---------------------------------------------------------------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

info()  { echo -e "${BLUE}[INFO]${NC}  $*"; }
ok()    { echo -e "${GREEN}[OK]${NC}    $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC}  $*"; }
err()   { echo -e "${RED}[ERROR]${NC} $*"; }

# ---------------------------------------------------------------------------
# Pre-flight checks
# ---------------------------------------------------------------------------
if [[ $EUID -ne 0 ]]; then
    err "This script must be run as root (sudo)."
    exit 1
fi

# ---------------------------------------------------------------------------
# Configuration — Fan curve for Aquacomputer Quadro
# ---------------------------------------------------------------------------
# Format: "TEMP_C  PWM_DUTY" (PWM 0-255, temp in Celsius)
# Linear interpolation between points. Below min = min PWM. Above max = 255.
#
# This curve is tuned for the i7-14700 (idle ~37-40C, load up to ~85C):
#   35C -> 20% (51)   — near-silent idle
#   45C -> 30% (77)   — light load
#   55C -> 45% (115)  — moderate load
#   65C -> 60% (153)  — heavier work
#   75C -> 80% (204)  — sustained load
#   85C -> 100% (255) — full cooling
# ---------------------------------------------------------------------------
CURVE_TEMPS=(35 45 55 65 75 85)
CURVE_PWMS=(51 77 115 153 204 255)

# Quadro hwmon path (auto-detected at runtime by the service)
QUADRO_HWMON_NAME="quadro"
CPU_TEMP_HWMON_NAME="coretemp"

# Polling interval in seconds
POLL_INTERVAL=3

# Hysteresis: only change PWM if delta exceeds this (prevents jitter)
HYSTERESIS=5

# Which Quadro fan channels to control (1-4). Channels with no fan connected are harmless.
FAN_CHANNELS=(1 2 3 4)

# ---------------------------------------------------------------------------
# Uninstall mode
# ---------------------------------------------------------------------------
if [[ "${1:-}" == "--uninstall" ]]; then
    info "Uninstalling fan control fixes..."

    if systemctl is-active --quiet quadro-fan-curve.service 2>/dev/null; then
        systemctl stop quadro-fan-curve.service
    fi
    systemctl disable quadro-fan-curve.service 2>/dev/null || true
    rm -f /etc/systemd/system/quadro-fan-curve.service
    rm -f /usr/local/bin/quadro-fan-curve.sh

    # Restore thermald config backup if it exists
    if [[ -f /etc/thermald/thermal-conf.xml.bak-fan-fix ]]; then
        mv /etc/thermald/thermal-conf.xml.bak-fan-fix /etc/thermald/thermal-conf.xml
        systemctl restart thermald
        ok "Restored original thermald config"
    fi

    # Re-enable i8kmon if desired
    # systemctl enable i8kmon.service 2>/dev/null || true

    systemctl daemon-reload
    ok "Uninstall complete. Reboot recommended to restore BIOS defaults."
    exit 0
fi

# ---------------------------------------------------------------------------
# Step 1: Validate hardware is present
# ---------------------------------------------------------------------------
info "Checking hardware..."

QUADRO_HWMON=""
CPU_TEMP_HWMON=""

for hw in /sys/class/hwmon/hwmon*/name; do
    name=$(cat "$hw" 2>/dev/null)
    dir=$(dirname "$hw")
    case "$name" in
        "$QUADRO_HWMON_NAME") QUADRO_HWMON="$dir" ;;
        "$CPU_TEMP_HWMON_NAME") CPU_TEMP_HWMON="$dir" ;;
    esac
done

if [[ -z "$QUADRO_HWMON" ]]; then
    err "Aquacomputer Quadro not found in /sys/class/hwmon/. Is it connected?"
    exit 1
fi
ok "Quadro found at $QUADRO_HWMON"

if [[ -z "$CPU_TEMP_HWMON" ]]; then
    err "coretemp not found. Is lm-sensors installed?"
    exit 1
fi
ok "CPU temp sensor found at $CPU_TEMP_HWMON"

# Verify PWM is writable
if [[ ! -w "${QUADRO_HWMON}/pwm1" ]]; then
    err "Cannot write to ${QUADRO_HWMON}/pwm1. Check kernel driver (aquacomputer_d5next)."
    exit 1
fi
ok "Quadro PWM is writable"

# ---------------------------------------------------------------------------
# Step 2: Create the fan curve daemon script
# ---------------------------------------------------------------------------
info "Installing fan curve daemon to /usr/local/bin/quadro-fan-curve.sh..."

cat > /usr/local/bin/quadro-fan-curve.sh << 'DAEMON_SCRIPT'
#!/usr/bin/env bash
# quadro-fan-curve.sh — Dynamic fan curve for Aquacomputer Quadro
# Reads CPU package temp, interpolates fan curve, writes PWM to Quadro channels.
# Designed to run as a systemd service.

set -euo pipefail

# --- Configuration (injected by installer) ---
QUADRO_HWMON_NAME="quadro"
CPU_TEMP_HWMON_NAME="coretemp"
POLL_INTERVAL=__POLL_INTERVAL__
HYSTERESIS=__HYSTERESIS__

# Fan curve: parallel arrays
CURVE_TEMPS=(__CURVE_TEMPS__)
CURVE_PWMS=(__CURVE_PWMS__)
FAN_CHANNELS=(__FAN_CHANNELS__)

# --- Runtime state ---
LAST_PWM=-1

# --- Find hwmon paths (they can change across reboots) ---
find_hwmon() {
    local target_name="$1"
    for hw in /sys/class/hwmon/hwmon*/name; do
        if [[ "$(cat "$hw" 2>/dev/null)" == "$target_name" ]]; then
            dirname "$hw"
            return 0
        fi
    done
    return 1
}

# --- Interpolate fan curve ---
interpolate_pwm() {
    local temp=$1
    local num_points=${#CURVE_TEMPS[@]}

    # Below minimum temp
    if (( temp <= CURVE_TEMPS[0] )); then
        echo "${CURVE_PWMS[0]}"
        return
    fi

    # Above maximum temp
    if (( temp >= CURVE_TEMPS[num_points-1] )); then
        echo "${CURVE_PWMS[num_points-1]}"
        return
    fi

    # Find the two points to interpolate between
    local i
    for (( i=0; i < num_points-1; i++ )); do
        local t_low=${CURVE_TEMPS[i]}
        local t_high=${CURVE_TEMPS[i+1]}
        if (( temp >= t_low && temp <= t_high )); then
            local p_low=${CURVE_PWMS[i]}
            local p_high=${CURVE_PWMS[i+1]}
            local t_range=$(( t_high - t_low ))
            local p_range=$(( p_high - p_low ))
            local t_offset=$(( temp - t_low ))
            # Integer linear interpolation
            echo $(( p_low + (t_offset * p_range) / t_range ))
            return
        fi
    done

    # Fallback: max
    echo "255"
}

# --- Read CPU package temperature (millidegrees -> degrees) ---
read_cpu_temp() {
    local hwmon="$1"
    # Package temp is temp1 for coretemp
    local raw
    raw=$(cat "${hwmon}/temp1_input" 2>/dev/null) || return 1
    echo $(( raw / 1000 ))
}

# --- Main loop ---
main() {
    echo "quadro-fan-curve starting..."

    local quadro_path cpu_path
    quadro_path=$(find_hwmon "$QUADRO_HWMON_NAME") || { echo "ERROR: Quadro not found"; exit 1; }
    cpu_path=$(find_hwmon "$CPU_TEMP_HWMON_NAME") || { echo "ERROR: coretemp not found"; exit 1; }

    echo "Quadro: $quadro_path"
    echo "CPU temp: $cpu_path"
    echo "Curve: temps=(${CURVE_TEMPS[*]}) pwms=(${CURVE_PWMS[*]})"
    echo "Channels: ${FAN_CHANNELS[*]}"
    echo "Poll: ${POLL_INTERVAL}s, Hysteresis: ${HYSTERESIS} PWM units"

    # Trap EXIT to restore fans to a safe speed
    trap 'echo "Stopping — setting fans to 100%"; for ch in ${FAN_CHANNELS[*]}; do echo 255 > "${quadro_path}/pwm${ch}" 2>/dev/null; done; exit 0' EXIT TERM INT

    while true; do
        local cpu_temp
        cpu_temp=$(read_cpu_temp "$cpu_path") || { echo "WARN: can't read temp"; sleep "$POLL_INTERVAL"; continue; }

        local target_pwm
        target_pwm=$(interpolate_pwm "$cpu_temp")

        # Apply hysteresis: only change if delta is significant
        if (( LAST_PWM >= 0 )); then
            local delta=$(( target_pwm - LAST_PWM ))
            # Make delta absolute
            if (( delta < 0 )); then delta=$(( -delta )); fi
            # Skip if change is within hysteresis (unless ramping up for safety)
            if (( delta < HYSTERESIS && target_pwm <= LAST_PWM )); then
                sleep "$POLL_INTERVAL"
                continue
            fi
        fi

        # Write PWM to all configured channels
        for ch in "${FAN_CHANNELS[@]}"; do
            echo "$target_pwm" > "${quadro_path}/pwm${ch}" 2>/dev/null || true
        done

        echo "$(date '+%H:%M:%S') CPU=${cpu_temp}C -> PWM=${target_pwm}/255 ($(( target_pwm * 100 / 255 ))%)"
        LAST_PWM=$target_pwm

        sleep "$POLL_INTERVAL"
    done
}

main "$@"
DAEMON_SCRIPT

# Inject configuration values
sed -i "s/__POLL_INTERVAL__/${POLL_INTERVAL}/" /usr/local/bin/quadro-fan-curve.sh
sed -i "s/__HYSTERESIS__/${HYSTERESIS}/" /usr/local/bin/quadro-fan-curve.sh
sed -i "s/__CURVE_TEMPS__/${CURVE_TEMPS[*]}/" /usr/local/bin/quadro-fan-curve.sh
sed -i "s/__CURVE_PWMS__/${CURVE_PWMS[*]}/" /usr/local/bin/quadro-fan-curve.sh
sed -i "s/__FAN_CHANNELS__/${FAN_CHANNELS[*]}/" /usr/local/bin/quadro-fan-curve.sh

chmod +x /usr/local/bin/quadro-fan-curve.sh
ok "Fan curve daemon installed"

# ---------------------------------------------------------------------------
# Step 3: Create systemd service
# ---------------------------------------------------------------------------
info "Creating systemd service: quadro-fan-curve.service..."

cat > /etc/systemd/system/quadro-fan-curve.service << 'SERVICE_UNIT'
[Unit]
Description=Aquacomputer Quadro dynamic fan curve (CPU temp based)
After=multi-user.target
Wants=lm-sensors.service

[Service]
Type=simple
ExecStart=/usr/local/bin/quadro-fan-curve.sh
Restart=on-failure
RestartSec=10
# Safety: if service crashes, fans go to 100% via trap
# Additional safety: systemd sets fans to max on stop
ExecStopPost=/bin/bash -c 'for hw in /sys/class/hwmon/hwmon*/name; do if [ "$(cat "$hw")" = "quadro" ]; then d=$(dirname "$hw"); for i in 1 2 3 4; do echo 255 > "$d/pwm$i" 2>/dev/null; done; fi; done'

# Hardening
NoNewPrivileges=false
ProtectSystem=false

[Install]
WantedBy=multi-user.target
SERVICE_UNIT

systemctl daemon-reload
ok "Systemd service created"

# ---------------------------------------------------------------------------
# Step 4: Tune thermald for smoother thermal management
# ---------------------------------------------------------------------------
info "Tuning thermald configuration..."

THERMALD_CONF="/etc/thermald/thermal-conf.xml"
if [[ -f "$THERMALD_CONF" ]]; then
    cp "$THERMALD_CONF" "${THERMALD_CONF}.bak-fan-fix"
    ok "Backed up existing thermald config to ${THERMALD_CONF}.bak-fan-fix"
fi

cat > "$THERMALD_CONF" << 'THERMALD_XML'
<?xml version="1.0"?>
<!--
  Tuned thermald config for Dell Inspiron 3030 / i7-14700
  More granular trip points for smoother thermal transitions.
  Uses RAPL power limiting (no direct fan control on this board).
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
          <!-- Gentle throttle at 60C — barely noticeable -->
          <TripPoint>
            <SensorType>x86_pkg_temp</SensorType>
            <Temperature>60000</Temperature>
            <type>passive</type>
            <ControlType>SEQUENTIAL</ControlType>
            <CoolingDevice>
              <index>1</index>
              <type>rapl_controller</type>
              <influence>20</influence>
              <SamplingPeriod>8</SamplingPeriod>
            </CoolingDevice>
          </TripPoint>
          <!-- Moderate throttle at 68C -->
          <TripPoint>
            <SensorType>x86_pkg_temp</SensorType>
            <Temperature>68000</Temperature>
            <type>passive</type>
            <ControlType>SEQUENTIAL</ControlType>
            <CoolingDevice>
              <index>2</index>
              <type>rapl_controller</type>
              <influence>40</influence>
              <SamplingPeriod>6</SamplingPeriod>
            </CoolingDevice>
          </TripPoint>
          <!-- Stronger throttle at 75C -->
          <TripPoint>
            <SensorType>x86_pkg_temp</SensorType>
            <Temperature>75000</Temperature>
            <type>passive</type>
            <ControlType>SEQUENTIAL</ControlType>
            <CoolingDevice>
              <index>3</index>
              <type>rapl_controller</type>
              <influence>60</influence>
              <SamplingPeriod>5</SamplingPeriod>
            </CoolingDevice>
          </TripPoint>
          <!-- Aggressive throttle at 82C — protect the chip -->
          <TripPoint>
            <SensorType>x86_pkg_temp</SensorType>
            <Temperature>82000</Temperature>
            <type>passive</type>
            <ControlType>SEQUENTIAL</ControlType>
            <CoolingDevice>
              <index>4</index>
              <type>rapl_controller</type>
              <influence>80</influence>
              <SamplingPeriod>3</SamplingPeriod>
            </CoolingDevice>
          </TripPoint>
        </TripPoints>
      </ThermalZone>
    </ThermalZones>
  </Platform>
</ThermalConfiguration>
THERMALD_XML

ok "Thermald config tuned (4 graduated trip points: 60/68/75/82C)"

# ---------------------------------------------------------------------------
# Step 5: Disable broken i8kmon
# ---------------------------------------------------------------------------
info "Disabling broken i8kmon service (crashes on desktop — no battery)..."
systemctl stop i8kmon.service 2>/dev/null || true
systemctl disable i8kmon.service 2>/dev/null || true
systemctl mask i8kmon.service 2>/dev/null || true
ok "i8kmon disabled and masked"

# ---------------------------------------------------------------------------
# Step 6: Set platform thermal profile to quiet
# ---------------------------------------------------------------------------
PROFILE_PATH="/sys/firmware/acpi/platform_profile"
if [[ -f "$PROFILE_PATH" ]]; then
    CURRENT=$(cat "$PROFILE_PATH")
    info "Current thermal profile: $CURRENT"
    echo "quiet" > "$PROFILE_PATH"
    ok "Set platform thermal profile to 'quiet' (less aggressive BIOS fan)"

    # Make it persistent via udev rule
    cat > /etc/udev/rules.d/99-dell-thermal-quiet.rules << 'UDEV_RULE'
# Set Dell platform thermal profile to quiet on boot
ACTION=="add", SUBSYSTEM=="firmware", ATTR{acpi/platform_profile}="quiet"
UDEV_RULE

    # Also via tmpfiles.d for reliability
    cat > /etc/tmpfiles.d/dell-thermal-quiet.conf << 'TMPFILES'
# Set Dell thermal profile to quiet
w /sys/firmware/acpi/platform_profile - - - - quiet
TMPFILES

    ok "Thermal profile persistence configured (udev + tmpfiles.d)"
fi

# ---------------------------------------------------------------------------
# Step 7: Enable and start services
# ---------------------------------------------------------------------------
info "Restarting thermald with new config..."
systemctl restart thermald
ok "thermald restarted"

info "Enabling and starting quadro-fan-curve service..."
systemctl enable quadro-fan-curve.service
systemctl start quadro-fan-curve.service
ok "quadro-fan-curve service started"

# ---------------------------------------------------------------------------
# Step 8: Verification
# ---------------------------------------------------------------------------
echo ""
echo -e "${GREEN}============================================${NC}"
echo -e "${GREEN}  Fan Control Fix — Installation Complete   ${NC}"
echo -e "${GREEN}============================================${NC}"
echo ""

info "Verifying services..."
echo ""

# Check quadro-fan-curve
if systemctl is-active --quiet quadro-fan-curve.service; then
    ok "quadro-fan-curve.service is RUNNING"
    echo "   Latest output:"
    journalctl -u quadro-fan-curve.service --no-pager -n 3 2>/dev/null | sed 's/^/   /'
else
    err "quadro-fan-curve.service failed to start"
    journalctl -u quadro-fan-curve.service --no-pager -n 10 2>/dev/null | sed 's/^/   /'
fi
echo ""

# Check thermald
if systemctl is-active --quiet thermald.service; then
    ok "thermald.service is RUNNING"
else
    err "thermald.service is not running"
fi
echo ""

# Show current state
info "Current readings:"
CPU_TEMP_FILE=$(find /sys/class/hwmon/ -name "name" -exec sh -c 'cat "$1" | grep -q coretemp && dirname "$1"' _ {} \; 2>/dev/null | head -1)
if [[ -n "$CPU_TEMP_FILE" ]]; then
    TEMP=$(( $(cat "${CPU_TEMP_FILE}/temp1_input") / 1000 ))
    echo "   CPU Package: ${TEMP}C"
fi

QUADRO_PATH=$(find /sys/class/hwmon/ -name "name" -exec sh -c 'cat "$1" | grep -q quadro && dirname "$1"' _ {} \; 2>/dev/null | head -1)
if [[ -n "$QUADRO_PATH" ]]; then
    for ch in 1 2 3 4; do
        pwm=$(cat "${QUADRO_PATH}/pwm${ch}" 2>/dev/null || echo "?")
        rpm=$(cat "${QUADRO_PATH}/fan${ch}_input" 2>/dev/null || echo "?")
        pct="?"
        if [[ "$pwm" =~ ^[0-9]+$ ]]; then pct=$(( pwm * 100 / 255 )); fi
        echo "   Quadro Fan ${ch}: PWM=${pwm} (${pct}%), ${rpm} RPM"
    done
fi

echo "   Platform profile: $(cat /sys/firmware/acpi/platform_profile 2>/dev/null || echo 'N/A')"
echo "   i8kmon: $(systemctl is-active i8kmon.service 2>/dev/null || echo 'masked/disabled')"
echo ""

info "Fan curve: 35C=20% | 45C=30% | 55C=45% | 65C=60% | 75C=80% | 85C=100%"
info "To monitor live: journalctl -u quadro-fan-curve.service -f"
info "To uninstall:    sudo bash $0 --uninstall"
echo ""
