# Review evidence

DATE: 2026-10-13
SOURCE BASELINE: `cfe01a6aad99a0e09d5ecf0de5659c606d7ba4f9` on `main`, initially clean.

These probes assert the reviewed baseline's **undesirable current behavior**. A passing probe
reproduces a finding; it does not mean the desired correction has passed. They live in planning,
not the production test suite, and will need adjustment/removal when a refactor fixes the behavior.
All records and file contents are synthetic. No native SketchUp automation was used.

| Check | Result | Evidence / command |
| --- | --- | --- |
| Full offline behavior suite | 1,490 Ruby tests / 18,315 assertions; 508 JS tests; 195 Python tests; all pass | `make test`; [captured output](offline-tests.log) |
| Enabled Ruby size metrics | 458 Ruby files inspected; zero offenses; includes the review probe present during scan | `bundle exec rubocop --only Metrics --format json`; [raw report](ruby-metrics.json) |
| Panel inventory | 78 modules, two page manifests current | `node tools/panel_manifest.js`; independently checked by frontend reviewer |
| Foundation probes | Six tests, 36 assertions, zero failures/errors/skips | [foundation_probes.rb](foundation_probes.rb) |
| Feature probes | Two tests, 29 assertions, zero failures/errors/skips | [ruby_feature_probes.rb](ruby_feature_probes.rb) |
| JavaScript probes | Four assertions/check scenarios reproduced | [javascript_probes.cjs](javascript_probes.cjs) |
| Frontend focused behavior checks | 327 tests passed in two non-overlapping groups; overlaps the later full suite | Exact groups/limits in [05](../sections/05-javascript.md#verification-and-limits) |

The configured enabled Metrics cops are MethodLength and ClassLength. CyclomaticComplexity is
disabled in the repository configuration; zero offenses here does not establish low cyclomatic
complexity. Physical module/file counts in the sections likewise measure size, not runtime cost.
No fresh coverage run was performed; historical thresholds are not presented as current results.

From the repository root, using the Makefile-selected installed Ruby:

```sh
"$(rbenv which ruby)" planning/code-review/evidence/foundation_probes.rb
"$(rbenv which ruby)" -Itests planning/code-review/evidence/ruby_feature_probes.rb
node planning/code-review/evidence/javascript_probes.cjs
```

The [diagram renderer](render_diagrams.py) uses the bundled workspace Python and Pillow to create
two PNG reading aids; it does not modify any application source or require external assets.

The main reviewer ran all retained probes successfully. The JS evidence reuses the existing test
fixture constructors in isolated Node VMs and directly exercises the real listeners/reducer. That
is synthetic DOM evidence, not browser/native input ordering proof. Ruby probes use the existing
SketchUp stub; native observer/operation/lifecycle claims remain with existing host evidence.

No required implementation gate was bypassed: this task creates review documents only. No
SketchUp 2023/Windows acceptance, large-model benchmark, licensed corpus test, vendor-manifest
refresh, full `make ci`, build/install or outside-provider native acceptance was performed.

Final document checks: all 124 local links resolved, all 64 source-line references were within the
referenced file, and Markdown heading anchors resolved. The two rendered images were visually
inspected. Probe syntax and `git diff --check` passed. The only tracked existing file changed is
`planning/STATUS.md`; the review packet is new. These checks do not prove every cited inference;
material findings were also checked against current source and their retained reproductions.
