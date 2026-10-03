# Host gate UI findings, host check, 2026-10-02

The host look owed by [host-gate-ui-findings](../../features/unscheduled/host-gate-ui-findings/PLAN.md),
issue #37, PR #40. Ledger case `HGUI`.

## Conditions

- SketchUp 26.1.188, Ruby 3.2.2, macOS. Development bridge for setup and readback; the panel driven
  through native window control; the native pickers and Save sheets operated by Ed, who reported each
  prompt with a screenshot.
- Build A: `dist/ph_composer.rbz` from branch `feat/host-gate-ui-findings` at `ce6a7a7`, SHA256
  `0722e368…9e5c`. Build B: the same branch after the item 3 revision below, SHA256 `ca62e207…0be1`.
  For each build, the package comparison against the installed Plugins folder matches with no extra
  files, and SketchUp was launched fresh on the fixture.
- Fixtures (gitignored `_private/host/hgui/`): `hgui.skp`, a copy of R11's `r11.skp`
  (`166a5556…d225`): one Frame on all four sides of one element of R11 type. `hgui-export.skp`, a copy
  of Phase 2's `p214-integrated.skp` (`8d23fc20…2aeb`), whose export preflight has no blocking finding.
- The stored library setup read `W10=` (empty) before the run and again after it.

## Results

| # | Check | Build | Result | Observation |
| --- | --- | --- | --- | --- |
| 1 | Disabled primary in the Libraries dialog | A | pass | With an unreadable setup (fault written by development eval), "Add library file…" and "Add library folder…" are both greyed; a click on the primary opens no picker. Reset gave "No libraries configured." with the primary teal again. |
| 2 | Export library form wording | A | pass | "Frame: 1", "Glazing: 1", "Material: 0", "Psi-Install Type: 1", then "Frame: source attribution is not exported" (likewise Glazing and Psi-Install Type) and "Window Type: not a library record; it stays in this Model". No codes. |
| 4 | Menu add notice | A | pass | Extensions → PH-Composer → Libraries → Add Library Folder…, `r11` chosen in the native picker: the panel showed "Added library r11." Readback: one provider `r11`; later removed through the public `remove` setup command. |
| 5 | Frame uses bubble | A | pass | Trigger "1"; heading "Used by 1 element"; one row "R11 type / Element" with "Bottom, left, right, top". Open type opened R11 type ("Showing 1 of 1 elements"). |
| 3a | Library export over an existing file | A | pass | One prompt, the macOS sheet's "already exists. Do you want to replace it?"; no second question. The file now holds a new "Model library" export (1 Frame, 1 Glazing, 1 Psi-Install Type). Model unmodified. |
| 3b | HBJSON over an existing pair | A | pass | One prompt, the macOS sheet's; no SketchUp question. `pair.hbjson` and `pair-export-report.html` replaced (49 KB, 65 KB). |
| 3c | HBJSON over a lone Export report | A | fail, revised | SketchUp asked "Replace the existing Export report beside this HBJSON?"; Yes started the runtime, then the export refused: "Only one destination artifact exists…". The pair has refused half a prior pair since P0-F, so the question could only lead to a refusal. Nothing written. |
| 3d | Name typed without `.hbjson` over an existing pair | A | fail, revised | `UI.savepanel` returned `…/hb/noext` with no extension (read through a development logging wrapper), so the sheet never checked `noext.hbjson`. SketchUp asked the report question; the export would refuse ("must end in .hbjson"). Nothing overwritten. |
| 3c | Lone Export report, after revision | B | pass | No question, no runtime; the panel showed "Only one destination artifact exists. Move or rename it before replacing the coordinated pair." The 6-byte report is unchanged. |
| 3d | Name without `.hbjson`, after revision | B | pass | No question; the panel showed "The export destination must end in .hbjson." `noext.hbjson` and its report are unchanged. |

## Revision made during the check

Ed agreed at the host: the HBJSON export now refuses a destination its artifact pair would refuse,
right after the Save sheet and before any question (`Export::ArtifactPair.destination_problem`).
`NativeApproval.confirm_replace` lost its companion branch. 3b was not repeated on build B; the
revision leaves that route's macOS path unchanged (the sheet's consent, no question), and
`tests/panel_test.rb` covers the replace question elsewhere.

## Observations, not failures

- The sides in the uses bubble follow stored order ("Bottom, left, right, top"), not top, right,
  bottom, left.
- The HBJSON export result lists internal text: "segment material id must be non-empty text" and
  Material ids such as `mat_tqhkQczrArTp`. Not part of this packet; a follow-up.
- `screencapture -l` was refused for SketchUp's windows in this session; captures came from the native
  window controller and Ed's screenshots.

## Restoration

The library setup is back to `W10=`. The savepanel logging wrapper (development eval) was cleared by
the fresh launch for build B. The fixtures are scratch copies; nothing was saved over a source fixture.
Raw captures are in `_private/host/hgui/`.
