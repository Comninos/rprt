#!/bin/bash
# rprt — SSH login report. No config, flags, or themes — edit this file.
# Examples + field catalog: https://raw.githubusercontent.com/Comninos/rprt/master/examples.md

# clip() uses ${#s}; in C/POSIX locale that counts bytes, not characters (breaks █░).
for _rprt_loc in C.UTF-8 C.utf8 en_US.UTF-8 en_US.utf8; do
    if LC_ALL="$_rprt_loc" LC_CTYPE="$_rprt_loc" locale >/dev/null 2>&1; then
        export LC_ALL="$_rprt_loc"
        break
    fi
done
unset _rprt_loc

TITLE="RPRT"
LABEL_WIDTH=10
DATA_WIDTH=37
BAR_WIDTH=18

# Pad/truncate by character count (printf %-Ns is byte-based; █░ break that).
clip() {
    local w="$1" s="$2" var="$3" len i padded
    len=${#s}
    if (( len > w )); then
        padded="${s:0:$((w - 3))}..."
    else
        padded="$s"
        for (( i = len; i < w; i++ )); do padded+=" "; done
    fi
    printf -v "$var" '%s' "$padded"
}

bar() {
    local used="$1" total="$2" filled i graph=""
    if awk -v t="$total" 'BEGIN { exit !(t > 0) }'; then
        filled=$(awk -v u="$used" -v t="$total" -v w="$BAR_WIDTH" \
            'BEGIN { n = int((u / t) * w + 0.5); if (n > w) n = w; if (n < 0) n = 0; print n }')
    else
        filled=0
    fi
    for (( i = 0; i < filled; i++ )); do graph+="█"; done
    for (( i = filled; i < BAR_WIDTH; i++ )); do graph+="░"; done
    printf '%s' "$graph"
}

INNER_WIDTH=$((LABEL_WIDTH + DATA_WIDTH + 5))

row() {
    local label data
    clip "$LABEL_WIDTH" "$1" label
    clip "$DATA_WIDTH" "$2" data
    printf '│ %s │ %s │\n' "$label" "$data"
}

title_row() {
    local text="$1" len pad_l pad_r i
    len=${#text}
    if (( len > INNER_WIDTH )); then
        text="${text:0:$((INNER_WIDTH - 3))}..."
        len=${#text}
    fi
    pad_l=$(( (INNER_WIDTH - len) / 2 ))
    pad_r=$(( INNER_WIDTH - len - pad_l ))
    printf '│'
    for (( i = 0; i < pad_l; i++ )); do printf ' '; done
    printf '%s' "$text"
    for (( i = 0; i < pad_r; i++ )); do printf ' '; done
    printf '│\n'
}

hrule_span() {
    local left right i
    case "$1" in
        top) left="┌"; right="┐" ;;
        bot) left="└"; right="┘" ;;
    esac
    printf '%s' "$left"
    for (( i = 0; i < INNER_WIDTH; i++ )); do printf '─'; done
    printf '%s\n' "$right"
}

hrule() {
    local left mid right i
    case "$1" in
        bot) left="└"; mid="┴"; right="┘" ;;
        *)   left="├"; mid="┼"; right="┤" ;;
    esac
    printf '%s' "$left"
    for (( i = 0; i < LABEL_WIDTH + 2; i++ )); do printf '─'; done
    printf '%s' "$mid"
    for (( i = 0; i < DATA_WIDTH + 2; i++ )); do printf '─'; done
    printf '%s\n' "$right"
}

hrule_title_to_cols() {
    local i
    printf '├'
    for (( i = 0; i < LABEL_WIDTH + 2; i++ )); do printf '─'; done
    printf '┬'
    for (( i = 0; i < DATA_WIDTH + 2; i++ )); do printf '─'; done
    printf '┤\n'
}

os_line=""
if [ -r /etc/os-release ]; then
    # shellcheck source=/dev/null
    . /etc/os-release
    if [ -n "${NAME-}" ] && [ -n "${VERSION_ID-}" ]; then
        os_line="${NAME} ${VERSION_ID}"
    elif [ -n "${PRETTY_NAME-}" ]; then
        os_line="$PRETTY_NAME"
    elif [ -n "${NAME-}" ]; then
        os_line="$NAME"
    fi
fi

host_line="$(uname -n 2>/dev/null || true)"

machine_ip=""
client_ip=""
if [ -n "${SSH_CONNECTION-}" ]; then
    client_ip=$(printf '%s' "$SSH_CONNECTION" | awk '{print $1}')
    machine_ip=$(printf '%s' "$SSH_CONNECTION" | awk '{print $3}')
fi
if [ -z "$machine_ip" ] && [ -r /proc/net/fib_trie ]; then
    machine_ip=$(awk '/32 host/ { print f } /([0-9]+\.){3}[0-9]+/ { f=$2 }' \
        /proc/net/fib_trie | awk '$1 != "127.0.0.1" { print; exit }')
fi

# LXC/Docker share the host kernel — no CPU hypervisor flag. Check containers first.
hv_line="bare metal"
if [ -f /.dockerenv ]; then
    hv_line="docker"
elif [ -f /run/.containerenv ]; then
    hv_line="podman"
elif [ -r /run/systemd/container ]; then
    hv_line=$(tr -d '\n' </run/systemd/container)
elif [ -r /proc/1/environ ] &&
    tr '\0' '\n' </proc/1/environ | grep -q '^container='; then
    hv_line=$(tr '\0' '\n' </proc/1/environ |
        awk -F= '/^container=/ { print $2; exit }')
elif [ -r /proc/1/cgroup ] &&
    grep -Eq '(docker|lxc|kubepods|containerd)' /proc/1/cgroup; then
    hv_line="container"
elif [ -r /proc/cpuinfo ] && grep -q '^flags.* hypervisor' /proc/cpuinfo; then
    hv_line="virtual"
fi

mem_line=""
if [ -r /proc/meminfo ]; then
    mem_total_k=$(awk '/^MemTotal:/ {print $2}' /proc/meminfo)
    mem_avail_k=$(awk '/^MemAvailable:/ {print $2}' /proc/meminfo)
    mem_used_k=$((mem_total_k - mem_avail_k))
    mem_pct=$(awk -v u="$mem_used_k" -v t="$mem_total_k" \
        'BEGIN { printf "%d", (u / t) * 100 }')
    mem_used_g=$(awk -v k="$mem_used_k" 'BEGIN { printf "%.1f", k / 1024 / 1024 }')
    mem_total_g=$(awk -v k="$mem_total_k" 'BEGIN { printf "%.0f", k / 1024 / 1024 }')
    mem_line="$(bar "$mem_used_k" "$mem_total_k")  ${mem_used_g}/${mem_total_g}G  ${mem_pct}%"
fi

disk_line=""
if df_out=$(df -P / 2>/dev/null | awk 'NR==2 {print $2, $3, $5}'); then
    disk_total_k=$(printf '%s' "$df_out" | awk '{print $1}')
    disk_used_k=$(printf '%s' "$df_out" | awk '{print $2}')
    disk_pct=$(printf '%s' "$df_out" | awk '{gsub(/%/,""); print $3}')
    disk_used_g=$(awk -v k="$disk_used_k" 'BEGIN { printf "%.0f", k / 1024 / 1024 }')
    disk_total_g=$(awk -v k="$disk_total_k" 'BEGIN { printf "%.0f", k / 1024 / 1024 }')
    disk_line="$(bar "$disk_used_k" "$disk_total_k")  ${disk_used_g}/${disk_total_g}G  ${disk_pct}%"
fi

load1_line=""
load5_line=""
load15_line=""
if [ -r /proc/loadavg ]; then
    read -r load1 load5 load15 _ </proc/loadavg
    load1_line="$load1"
    load5_line="$load5"
    load15_line="$load15"
fi

up_line=""
if [ -r /proc/uptime ]; then
    secs=$(cut -d. -f1 /proc/uptime)
    days=$((secs / 86400))
    hours=$(((secs % 86400) / 3600))
    mins=$(((secs % 3600) / 60))
    parts=()
    (( days > 0 )) && parts+=("${days}d")
    (( hours > 0 || days > 0 )) && parts+=("${hours}h")
    parts+=("${mins}m")
    up_line=$(IFS=,; echo "${parts[*]}" | sed 's/,/, /g')
fi

hrule_span top
title_row "$TITLE"
hrule_title_to_cols
row "OS"         "$os_line"
row "HOSTNAME"   "$host_line"
row "MACHINE IP" "$machine_ip"
row "CLIENT IP"  "$client_ip"
row "HYPERVISOR" "$hv_line"
row "MEMORY"     "$mem_line"
row "DISK"       "$disk_line"
row "LOAD 1M"    "$load1_line"
row "LOAD 5M"    "$load5_line"
row "LOAD 15M"   "$load15_line"
row "UPTIME"     "$up_line"
hrule bot
