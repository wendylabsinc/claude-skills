---
name: wendy
description: 'Build and deploy apps to robots and edge devices with Wendy (wendy.dev): WendyOS on NVIDIA Jetson, Raspberry Pi and x86, the Wendy Agent on Linux and Mac, Wendy Lite on ESP32, and local robot simulators. Use when developers mention Wendy or WendyOS, wendy CLI commands, wendy.json or entitlements, or deploying apps to Jetson, Raspberry Pi, robots or simulators.'
references:
  - wendy.json.md
---

# Wendy

Wendy ([wendy.dev](https://wendy.dev)) builds apps into containers and deploys
them to WendyOS devices (NVIDIA Jetson on JetPack 7.2 or later, Raspberry Pi
4/5, x86), to existing Linux computers and Macs (beta) running the Wendy Agent,
to local simulators (`vm:<name>`), and to the local Docker provider (`docker`).
ESP32 boards run Wendy Lite (beta). Documentation:
[docs.wendy.dev](https://docs.wendy.dev/latest/); `wendy docs <topic>` prints
the same pages in the terminal.

For complete workflows (onboarding, device install and debugging, robots and
ROS 2, Wendy Data), install the official Wendy plugin and MCP server:

```bash
claude plugin marketplace add wendylabsinc/wendy-agentic-coding
claude plugin install wendy-agentic-coding@wendy-agentic-coding
wendy mcp setup
```

## Install the CLI

```bash
curl -fsSL https://install.wendy.dev/cli.sh | bash   # macOS or Linux
brew install wendylabsinc/tap/wendy                  # Homebrew
winget install WendyLabs.Wendy                       # Windows
```

## CLI commands

Pass `--device <selector>` to every command. Without a terminal the CLI prints
JSON on stdout and progress on stderr. `--yes` accepts prompts and creates a
minimal `wendy.json` when the project has none.

```bash
wendy discover --json
wendy --json run --device <selector> --detach --wait-ready --yes
wendy --json device apps list --device <selector>
wendy --json device logs --app <app-id> --tail 50 --no-follow --device <selector>
wendy json validate
wendy --json vm list
```

Run `--help` for any other command. `wendy init` creates a new project;
`wendy os install` writes WendyOS to a drive or board.

A deploy result shows that the app started and, with `--wait-ready`, that its
port accepts connections. Then check the behavior the user asked for once, such
as one HTTP request to the result's `url`, and report what you checked.

## Languages

Wendy runs apps in any language that builds into a container. Swift packages
and Python projects build without a Dockerfile; other projects use a
Dockerfile, a Stagefile (`build.stagefile.yaml`) or Docker Compose. Templates
for many languages are at
[github.com/wendylabsinc/templates](https://github.com/wendylabsinc/templates).

## Entitlements

Apps are sandboxed. `wendy.json` declares what an app may access (network,
GPU, camera, audio, Bluetooth, USB, serial and more). Add one with, for
example, `wendy project entitlements add gpu`, and check the file with
`wendy json validate`. A web server needs the `network` entitlement with
`"mode": "host"`. See `references/wendy.json.md` for the file format and
common entitlements, and https://docs.wendy.dev/latest/device/entitlements/
for the full list.

## No device available

A simulator runs WendyOS with the same agent, containerd and entitlements as
hardware, including robot profiles (`go2`, `g1`, `rosmaster-r2`). Use an
existing simulator from `wendy --json vm list`. Ask the user before creating
one with `wendy vm create`: it downloads an image of a few hundred MB. Report
results as verified on the simulator, not the user's hardware. Cameras,
microphones, GPU, GPIO, USB and serial peripherals, and real motion still need
hardware.

## Troubleshooting

| Problem | Next step |
|---------|-----------|
| Device not found | Check the USB or LAN connection, then run `wendy discover --json` |
| Network access denied | Add the `network` entitlement with `"mode": "host"` |
| GPU, camera or audio missing | Add the matching entitlement, then redeploy |
| App started but misbehaves | Read `wendy --json device logs --app <app-id> --tail 50 --no-follow` |

## Further reading

- Docs: https://docs.wendy.dev/latest/
- Docs index for agents: https://docs.wendy.dev/llms.txt
- Website: https://wendy.dev
