# xfa-flatten — Ponder XFA Form Flattener (Free / 3-page trial)

A cross-agent skill that flattens XFA dynamic forms and AcroForm PDFs into static PDFs — **entirely on your local machine, nothing is uploaded**. This is the free version: each document outputs the first 3 pages (no watermark).

## What's inside

```
xfaflatten/
├── xfa-flatten/                  <- the skill itself
│   ├── SKILL.md                  instructions + workflow
│   ├── references/troubleshooting.md
│   ├── scripts/
│   │   ├── install-xfaflatten.ps1
│   │   └── xfa-batch.ps1
│   └── bin/                      <- CLI bundled here: works offline, no download
│       ├── xfaflatten.exe
│       └── libSkiaSharp.dll
└── README.md
```

The CLI is bundled in `xfa-flatten/bin/`, so **cloning this repo is enough** — no network download, no installer running as admin. The installer script (`install-xfaflatten.ps1`) simply copies the bundled exe to `%LOCALAPPDATA%\xfaflatten` and smoke-tests it; it only downloads from the internet if `bin/` is missing.

## Install / use

### Claude Code / OpenCode / other `SKILL.md`-compatible agents

Copy or symlink the `xfa-flatten/` directory into your agent's skills folder, then restart the agent:

```powershell
# Personal skills (OpenCode / Claude Code style)
git clone https://github.com/Ponder-HenryJiang/xfaflatten.git
# then copy xfaflatten\xfa-flatten into ~/.agents/skills (or your agent's skills dir)
```

Alternative: set `XFAFLATTEN_EXE` to `<repo>\xfa-flatten\bin\xfaflatten.exe` and the skill will use it directly without running the install script.

### WorkBuddy

WorkBuddy skills are installed from its marketplace; if your WorkBuddy build supports importing a local skill folder, import `xfa-flatten/` directly. Otherwise this repo is mainly intended for the `SKILL.md`-compatible agents above.

## Try it

Once the skill is loaded, just ask your agent:

- "Flatten the XFA form D:\forms\imm1294.pdf"
- "Batch flatten all PDFs in D:\forms into D:\out"

Or run the CLI directly:

```powershell
& .\xfa-flatten\bin\xfaflatten.exe input.pdf output.pdf
& .\xfa-flatten\bin\xfaflatten.exe --license-info
```

## Free tier vs full version

- **Bundled here (free)**: no `license.json` -> first 3 pages per document, no watermark, exit code 0.
- **Full version**: place a paid `license.json` next to `xfaflatten.exe` (or pass `--license FILE`) to unlock all pages. To purchase, email **Ponder_Henry_Jiang@foxmail.com**.

## Feedback

If the **free version** produces any output-quality problems — missing glyphs, misalignment, pagination issues, or any other rendering defect — please email **Ponder_Henry_Jiang@foxmail.com** with a redacted sample input PDF, the output PDF, and the command-line output. The author will optimize promptly.

## Requirements

- Windows x64 (native exe); no admin rights needed.
- If SmartScreen blocks the first run: More info -> Run anyway.
- Security suites like 360 may flag "PowerShell downloads an exe" as a false positive — see `xfa-flatten/references/troubleshooting.md`.

## Branding

Product: **Ponder** / `xfaflatten`. Author: Henry.Jiang.
