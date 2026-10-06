# Managed Zone options interaction study

Development only. Synthetic data lives in memory and resets on reload. No host or public operation
is called. Shared menu/dialog components come from the shipping UI kit; no shared styles are changed.

Serve the repository root with `make ui-preview`, then open
`http://127.0.0.1:8765/tools/spikes/zone-field-options/`.

Use either column menu to manage its options. Save commits the in-memory draft; Cancel/Escape discard
it. Merge/Delete requires a replacement for a used Segment or default, and offers Not set for Levels.
This study supports the packet's interaction decision. It does not prove Model migration, Undo,
recovery, revision guards, accessibility across all states, native colour selection or export.
