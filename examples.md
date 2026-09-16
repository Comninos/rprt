# Examples

Same design. Different rows for different needs.
Ask an agent to reshape the *installed* script toward one of these (or your own). Delete code for fields you drop; it is not precious.

## 1. VM fleet (default)

Hop across VMs over SSH: where am I, virt or not, is the box healthy?

```
┌────────────────────────────────────────────────────┐
│                        RPRT                        │
├────────────┬───────────────────────────────────────┤
│ OS         │ Debian GNU/Linux 12                   │
│ HOSTNAME   │ trdnt-01                              │
│ MACHINE IP │ 203.0.113.40                          │
│ CLIENT IP  │ 198.51.100.17                         │
│ HYPERVISOR │ virtual                               │
│ MEMORY     │ ████████████░░░░░░  3.1/4.0G  77%     │
│ DISK       │ ██████░░░░░░░░░░░░  48/80G  60%       │
│ LOAD 1M    │ 1.82                                  │
│ LOAD 5M    │ 1.14                                  │
│ LOAD 15M   │ 0.73                                  │
│ UPTIME     │ 14d, 3h, 7m                           │
└────────────┴───────────────────────────────────────┘
```

## 2. Laptop

Battery, network, home disk; no hypervisor or client IP.

```
┌────────────────────────────────────────────────────┐
│                        RPRT                        │
├────────────┬───────────────────────────────────────┤
│ HOST       │ atlas                                 │
│ USER       │ dan                                   │
│ OS         │ Fedora Linux 44                       │
│ WIFI       │ home-net                              │
│ BATTERY    │ ████████████░░░░░░  72%  discharging  │
│ MEMORY     │ ██████████░░░░░░░░  12/16G  64%       │
│ DISK ~     │ ██████████████░░░░  340/500G  68%     │
│ LOAD 1M    │ 0.41                                  │
│ UPTIME     │ 2d, 4h, 12m                           │
└────────────┴───────────────────────────────────────┘
```

## 3. Minimal identity

Simple host card only.

```
┌────────────────────────────────────────────────────┐
│                        RPRT                        │
├────────────┬───────────────────────────────────────┤
│ HOST       │ trdnt-01                              │
│ OS         │ Debian GNU/Linux 12                   │
│ IP         │ 203.0.113.40                          │
│ UPTIME     │ 14d, 3h, 7m                           │
└────────────┴───────────────────────────────────────┘
```

## 4. Network

Can this box reach the world, and who connected?

```
┌────────────────────────────────────────────────────┐
│                     RPRT · NET                     │
├────────────┬───────────────────────────────────────┤
│ HOST       │ trdnt-01                              │
│ MACHINE IP │ 203.0.113.40                          │
│ CLIENT IP  │ 198.51.100.17                         │
│ GATEWAY    │ 203.0.113.1                           │
│ DNS        │ 1.1.1.1, 9.9.9.9                      │
│ IFACE eth0 │ RX 12.4G  TX 3.1G                     │
│ LISTEN     │ 14 tcp                                │
│ UPTIME     │ 14d, 3h, 7m                           │
└────────────┴───────────────────────────────────────┘
```

## 5. Hardware

What is this machine, physically?

```
┌────────────────────────────────────────────────────┐
│                   RPRT · HARDWARE                  │
├────────────┬───────────────────────────────────────┤
│ HOST       │ atlas                                 │
│ PRODUCT    │ ThinkPad T14 Gen 2                    │
│ BOARD      │ 20XKCTO1WW                            │
│ CPU        │ AMD Ryzen 7 PRO 4750U with Radeon     │
│ CORES      │ 16                                    │
│ GPU        │ AMD Renoir (DRM)                      │
│ MEMORY     │ ██████████░░░░░░░░  12/16G  64%       │
│ DISK nvme0 │ 512G                                  │
│ THERMAL    │ 48°C                                  │
│ ARCH       │ x86_64                                │
└────────────┴───────────────────────────────────────┘
```

## Field catalog

Rows you can add from bash plus `/proc`, `/sys`, `/etc`, and ordinary coreutils.
No packages, no network calls, no sudo, nothing slow.

### Identity
- OS name / version (`/etc/os-release`)
- Pretty hostname (`/etc/machine-info`, else `uname -n`)
- Kernel release / version (`uname -r`, `uname -v`)
- Architecture (`uname -m`)
- Machine id (`/etc/machine-id`)
- Boot id (`/proc/sys/kernel/random/boot_id`)
- User, UID, GID, groups (`id`)
- Home, shell (`$HOME`, `$SHELL`)
- Locale (`$LANG`)
- TTY / TERM (`tty`, `$TERM`)
- Who is logged in / session count (`who`)

### Network & SSH
- Machine IP (SSH_CONNECTION, else `/proc/net/fib_trie`)
- Client IP (SSH_CONNECTION)
- SSH port / connection endpoints (SSH_CONNECTION)
- Primary IPv4 / IPv6 per interface (`/proc/net/fib_trie`, `/proc/net/if_inet6`)
- Interface list + RX/TX bytes (`/proc/net/dev`)
- Default gateway (`/proc/net/route`)
- DNS servers (`/etc/resolv.conf`)
- Wi-Fi link quality (`/proc/net/wireless`; SSID only if `iw` is already on the box)
- Listening socket count (`/proc/net/tcp`, `/proc/net/tcp6`, udp)

### Virt & hardware
- Hypervisor / container (`/proc/cpuinfo` flags; `/.dockerenv`, `/run/.containerenv`, `/run/systemd/container`, `/proc/1/environ`, `/proc/1/cgroup`)
- DMI product / board / vendor / BIOS (`/sys/class/dmi/id/*`)
- Chassis type (`/sys/class/dmi/id/chassis_type`)
- CPU model, core count (`/proc/cpuinfo`; `nproc`)
- CPU MHz / governor (`/proc/cpuinfo`, `/sys/devices/system/cpu/*/cpufreq/`)
- Thermal zones (°C) (`/sys/class/thermal/`)
- Battery % + status (`/sys/class/power_supply/BAT*`)
- AC adapter online (`/sys/class/power_supply/A*` / `ADP*`)
- Backlight % (`/sys/class/backlight/`)
- Block devices + sizes (`/sys/block/`, `/proc/partitions`)
- GPU / display device (`/sys/class/drm/*/device/`; nicer name if `lspci` is already on the box)

### Memory & pressure
- Memory used / total / % (`/proc/meminfo` MemTotal, MemAvailable)
- MemFree, Buffers, Cached, Commit (`/proc/meminfo`)
- Swap used / total / % (`/proc/meminfo`)
- Dirty / writeback (`/proc/meminfo`)
- PSI memory / CPU / IO (`/proc/pressure/*` when present)
- Entropy avail (`/proc/sys/kernel/random/entropy_avail`)

### Disk & mounts
- Disk used / total / % for `/`, `$HOME`, or any mount (`df -P`)
- Inodes used / % (`df -iP`)
- Filesystem type (`/proc/mounts`)
- Mount count / read-only mounts (`/proc/mounts`)
- Separate rows per mount (`/`, `/home`, `/var`, `/data`, …)

### Load & time
- Load 1m / 5m / 15m (`/proc/loadavg`)
- Load per CPU (load / nproc)
- Runnable / total processes (`/proc/loadavg` fields 4–5)
- Process count (`/proc/[0-9]*`)
- Uptime (`/proc/uptime`)
- Local time / date (`date`)
- Timezone (`date +%Z`, `/etc/localtime` target)

### Security & misc
- SELinux mode (`/sys/fs/selinux/enforce` when present)
- AppArmor status (`/sys/module/apparmor/parameters/` or `/sys/kernel/security/apparmor/`)
- Capability bounding set hints (`/proc/self/status`)
- Umbrella "roles": title text only (e.g. `RPRT · LAPTOP`); not a data source
