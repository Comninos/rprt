# rprt

A no-deps bash machine report following the **Single-End** software philosophy. Works over SSH. Not a fetch program.

RPRT has no settings and no flags. It only reports what you need. For configuration, agents can directly edit the installed script (`~/.local/bin/rprt`, or `/usr/local/bin/rprt` if system-wide), or edit it yourself (see Philosophy section below). 

See [examples.md](examples.md) for more variations and a field catalog.

Inspired by [USGC's machine report](https://github.com/usgraphics/usgc-machine-report).

VM fleet (default):

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

Laptop:

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

## The Single-End Philosophy

**Software that serves a single end;** only what *you* require, and little else. This philosophy is intended for very small programs in a world of token abundance.

- Settings are bloat. Just change the code.
- Different user, different code. Ends are bespoke.
- Few lines of code keep the program pliable, cheap in tokens, and gratifying.

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/Comninos/rprt/master/install.sh | bash
```

System-wide: `… | sudo bash -s -- --system`  
From clone: `./install.sh` (`--help` for options)

## For Agents

- Drop unused field code when removing rows.
- Maintain the basic shape: one file, no config, no flags, few deps.

## License

[CC0 1.0](https://creativecommons.org/publicdomain/zero/1.0/) (public domain dedication)
