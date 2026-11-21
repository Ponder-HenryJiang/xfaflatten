# xfaflatten Troubleshooting Guide

Referenced by the skill body (SKILL.md) when flattening fails, licensing is abnormal, or the result looks suspicious.

## 1. Exit-code reference

| Exit code | Meaning | Recommended action |
|---|---|---|
| 0 | Success (the 3-page truncation in free mode also counts as success; distinguish it via the `limited` field of `--json`) | Deliver normally |
| 1 | Argument/input error: file missing, output already exists, or a directory passed as the output path | Fix the invocation; add `--overwrite` when the output already exists |
| 2 | Flattening failed: corrupt / unsupported / not a PDF | First confirm the file opens normally; a truncated file (interrupted transfer) reports `Invalid/Unknown/Unsupported format` |
| 3 | Empty output | Check disk space and output-path permissions; rerun once with `-v` to collect diagnostics |
| 4 (helper scripts only) | Script cannot find xfaflatten.exe | Follow the download guidance in SKILL.md step 0 |
| 10 | License present but invalid (wrong machine / tampered / expired) | See section 2 |

## 2. License three states and licensing issues

| State | Behavior |
|---|---|
| No license.json | Free mode: only the first 3 pages of each document are output, no watermark, exit code 0 |
| License present but invalid | **Refuses to run**, exit code 10; never degrades to free mode |
| Valid License | Full output, exit code 0 |

Diagnostic commands:

```powershell
xfaflatten --license-info   # shows license path, machine code, and VALID / INVALID reason
xfaflatten --machine-code   # local machine code; only needed for machine-bound licenses
```

Common causes:

- `license.json` is not next to the exe and was not specified with `--license <path>`;
- Machine code mismatch (machine-bound licenses only; changing machines / reinstalling the OS / cloning a VM) — send the new `--machine-code` value to the vendor for re-issuance;
- The file was edited by an editor, invalidating the signature — use the vendor's original file again; do not reformat it manually;
- Expired — check the `expires` field in `--license-info`.

> The personal edition is not machine-bound by default and can be used on multiple computers; seeing `machine : (unbound)` is normal.

## 3. Font issues

Font families declared in the template map to fonts installed locally: `Myriad → Calibri`, Chinese → `SimSun`.

- Chinese renders as boxes: the target machine lacks SimSun (usually present on Windows; on Linux install Noto CJK / Source Han);
- Western layout differs: Calibri is missing; forms with embedded PDF fonts are unaffected;
- Do not suggest casually replacing system font files; identify the missing font first, then propose a solution.

## 4. SmartScreen and antivirus blocking

- Blocked by SmartScreen on first run: **More info → Run anyway** (a new signing certificate has a reputation-building period);
- Use `SHA256SUMS.txt` in the package to verify the hashes of the exe and `libSkiaSharp.dll`, ruling out a corrupted download;
- Defender / 360 false positives: file a false-positive report with the vendor; do not teach the user to disable antivirus permanently.

## 5. Common harmless output noise (do not treat as failures)

- `ReadDirectory: Warning, default.tiff: wrong data type UNDEFINED ...`: a warning from the native image decoder triggered by certain embedded PDF resources; does not affect the result or exit code;
- `pagination: N page(s) for M element(s)`: pagination diagnostic, not an error;
- The free-tier upgrade prompt and machine-code prompt: product information, not errors.

## 6. Performance and memory

- Single-file warm start is about 0.7–1.3 s; peak memory ranges from 40 MB to 800 MB depending on document complexity;
- Very large Chinese documents (hundreds of pages, many images, complex fonts) may use more memory: run a small batch first, then scale up;
- The batch script runs serially, which naturally limits load — do not add concurrency on your own.

## 7. Output-quality issues and feedback channel

If a flattened result has missing glyphs, misalignment, pagination, or font problems (not parameter/license errors), email the redacted input PDF, output PDF, and command-line output to **Ponder_Henry_Jiang@foxmail.com**; the author will optimize promptly. Include the version number from `version.txt` to help locate the issue.

Collect the following when reporting a problem:

1. The output PDF (may be redacted);
2. The full command line and stdout/stderr;
3. The `xfaflatten --license-info` output (license.json itself may be redacted);
4. The machine code (only needed for machine-bound licenses);
5. The contents of `version.txt` (version and build mode).

Do not upload original forms containing personal information on public channels.
