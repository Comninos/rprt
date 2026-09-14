# rprt

A simple bash machine report. Not a fetch program. No dependencies. Works over SSH.

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

Inspired by [USGC's machine report](https://github.com/usgraphics/usgc-machine-report).

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/Comninos/rprt/master/install.sh | bash
```

System-wide: `… | sudo bash -s -- --system`  
From clone: `./install.sh` (`--help` for options)

## Config

Edit the installed script to change the title or fields.

## License

[CC0 1.0](https://creativecommons.org/publicdomain/zero/1.0/) (public domain dedication)
