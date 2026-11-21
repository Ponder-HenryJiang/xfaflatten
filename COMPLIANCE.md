# Compliance & Licensing Notes / 合规与协议说明

This document records the licensing posture of the Ponder / xfaflatten project. It is a **developer-facing reference**, not legal advice. For binding terms, see the actual license texts and contracts.

---

## 1. Ownership & branding

- Product name: **Ponder**; `xfaflatten` is a Ponder product.
- Author / copyright holder: **Henry.Jiang** (`Ponder_Henry_Jiang@foxmail.com`).
- External materials (download page, purchase page, QUICKSTART, skill detail page) consistently use the Ponder brand.

**Note**: the main source repository currently has **no top-level LICENSE file**. That means, by default, all rights are reserved — the source is **not** openly licensed. This is consistent with a commercial product, but it should be stated explicitly. Two separate distributions have their own terms (see below).

---

## 2. Component license inventory

### 2.1 First-party code (proprietary / all rights reserved)
- `Xfa.Engine/` — XFA layout / script / render engine
- `Ponder.Pdf/` — self-developed PDF engine (kernel, parsing, rendering, crypto)
- `tools/aot/Xfa.License*`, `tools/aot/Xfa.Aot.Cli` — license verification + CLI
- These are the commercial core. No open-source license is granted.

### 2.2 Third-party dependencies in the **commercial build**

The shipped CLI (`Xfa.Aot.Cli` → `Xfa.Engine` → `Ponder.Pdf`) depends only on:

| Component | License | Commercial use | Notes |
|---|---|---|---|
| SkiaSharp 1.68.0 | MIT | ✅ | Includes Skia (BSD), HarfBuzz (Old MIT), ANGLE (BSD), libpng (libpng), FreeType (FTL/GPLv2 dual — FTL taken), ICU (ICU/Unicode), DNG SDK (Adobe), expat (MIT), etc. Full notices shipped in `THIRD-PARTY-NOTICES.txt` and `SkiaSharp-1.68.0-THIRD-PARTY-NOTICES.txt`. |
| .NET Runtime 10 | MIT | ✅ | NativeAOT-linked into the exe. |
| System.Buffers / Memory / Unsafe / Text.Encoding.CodePages | MIT | ✅ | Microsoft core libs. |

**No AGPL / GPL component is linked into the commercial binary.** The FreeType license used is the FTL (BSD-style with credit requirement), not GPLv2 — attribution is required and is shipped in the notices.

The bundled `THIRD-PARTY-NOTICES.txt` files are copied into every release package (`dist/.../`), satisfying MIT/BSD "include copyright notice" obligations.

### 2.3 Components **NOT** in the commercial build
- **iText 9.8.0** (AGPL / commercial dual license) — referenced only by `Xfa.ItextCompare` and `Xfa.Engine.Itext` (comparison / legacy adapter projects). **These are not part of `Xfa.Aot.Cli` and are not shipped.** If you ever distribute anything referencing iText, you must comply with AGPL or buy a commercial iText license.
- **BouncyCastle** — vendored under `Ponder.Pdf/Utilities/CommonModules/BouncyCastle` (MIT-style). No copyleft.

### 2.4 Fonts (important)
- The package ships **no** commercial fonts. Calibri / SimSun / Arial / Times are **not** distributed.
- At runtime the tool maps template font families to fonts installed on the target machine (`Myriad → Calibri`, CJK → SimSun). Customers must hold their own font licenses.
- **Do not** copy Windows font files into any package or container image. This is documented in `THIRD-PARTY-NOTICES.txt` and `AOT_MONETIZATION.md` §4.3.
- PDF output embeds font subsets; source font `fsType` embedding permissions are read but not strictly enforced before embedding — audit before commercial release (open item).

---

## 3. Distribution-specific terms

### 3.1 WorkBuddy skill package (`workbuddyskill/`)
- The skill package is **text only** (SKILL.md + scripts + references). It contains no binary.
- It is distributed through the WorkBuddy marketplace under its own paid-skill terms.
- The CLI is downloaded/installed separately by `install-xfaflatten.ps1` from the official direct URL; a `license.json` unlocks full output.

### 3.2 GitHub public repo (`github.com/Ponder-HenryJiang/xfaflatten`)
- `LICENSE`: **MIT** — applies to the skill source materials only (`SKILL.md`, `references/`, `scripts/`, README).
- **Exception**: the bundled binaries in `xfa-flatten/bin/` (`xfaflatten.exe`, `libSkiaSharp.dll`) are **proprietary**, not MIT-licensed. They are a free trial build limited to the first 3 pages per document. Full functionality requires a paid license. `LICENSE` states this exception explicitly.
- `.gitignore` excludes `license.json` and `*.flat.pdf` so no license or customer artifacts leak into the repo.

### 3.3 CLI release package (`dist/...slim.zip`, hosted on COS / Gitee / GitHub Release)
- Proprietary binary, free tier 3 pages, full output via paid `license.json`.
- Ships `THIRD-PARTY-NOTICES.txt` + `SkiaSharp-1.68.0-THIRD-PARTY-NOTICES.txt` + `SHA256SUMS.txt`.
- Code signing is **optional / not yet applied** (`sign-win.ps1` available). Unsigned exe triggers SmartScreen reputation warnings.

---

## 4. License mechanism (commercial enforcement)

- Algorithm: RSA-3072 + SHA-256 + PKCS#1 v1.5; private key offline, only the public key is embedded in the exe.
- Personal edition: `machine` empty = unbound, usable on multiple machines of the buyer; relies on low price + updates to absorb sharing.
- Business edition: bound to `--machine-code`, expiry, and `maxMajorVersion`.
- Fail-closed: no / invalid license → exit code 10 or free 3-page truncation, never "silently unlimited".
- **Not DRM**: native compilation raises the bar but does not make it uncrackable. External messaging must not promise "uncrackable" (documented in `AOT_MONETIZATION.md`).

---

## 5. Data privacy / personal information

- All processing is local; no upload, no network calls from the CLI. This is the core selling point for immigration / insurance / finance forms.
- Skill docs instruct agents and users not to upload personal forms to online tools, and to redact bugs reports.
- `license.json` must not be uploaded or forwarded; it is a signed file.

---

## 6. Compliance gaps / action items

| # | Item | Status | Action |
|---|---|---|---|
| 1 | Main repo has no LICENSE | ⚠️ Open | Decide: keep all-rights-reserved (add a `LICENSE` stating proprietary), or open-source the engine under a chosen license. Do not leave ambiguous. |
| 2 | Top-level `license.json` in repo | ⚠️ Dev artifact | Ensure it is gitignored (it is) and never shipped in customer packages. |
| 3 | Font `fsType` embedding | ⚠️ Open | Audit embedded font subsets against source `fsType` before commercial release. |
| 4 | Code signing | ⚠️ Not applied | Sign exe with EV/OV certificate before public launch to reduce SmartScreen/AV false positives. |
| 5 | 360 / AV false positives | ⚠️ Known | "PowerShell downloads then runs exe" is flagged as false positive. Documented; long-term: signing + whitelist submission. |
| 6 | Personal seller, no company | ⚠️ Known | Enterprise invoices/contracts not possible as an individual; do not collect large corporate payments personally without tax declaration (see `AOT_MONETIZATION.md` §6.5). International personal collection via Creem/Gumroad/Lemon Squeezy; domestic via 爱发电/面包多. |
| 7 | iText AGPL contamination | ✅ OK | iText only in comparison/test projects, not in the shipped binary. Keep it that way. |
| 8 | Third-party notices in every package | ✅ OK | Shipped in all `dist/` packages. |
| 9 | GitHub repo MIT exception | ✅ OK | `LICENSE` explicitly excludes `bin/`. |
| 10 | Branding consistency | ✅ OK | Ponder brand used across all outward-facing docs; old third-party attributions removed. |

---

## 7. Summary

- The **commercial binary is clean** from a copyleft perspective (only MIT/BSD-style deps; iText AGPL excluded).
- The **main source repo's license is unspecified** — needs an explicit decision.
- The **GitHub skill repo** is MIT for text, proprietary for the bundled exe (documented).
- **Fonts, code signing, and individual-seller tax/invoice** are the main remaining compliance topics.
