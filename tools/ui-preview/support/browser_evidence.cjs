/* Browser failure evidence for the checks to share. One collector per check run records console errors,
   uncaught page errors, transport failures (requestfailed) and HTTP error responses, each with the check's
   current step, the page and UTC/monotonic times. A caught render exception sent to console.error never
   reaches pageerror, so collecting pageerror alone misses it.

   `check(options, body)` is the entry a check script calls: it launches the installed Chrome and hands the
   body `newPage`, `step` and `expect`. Afterwards it fails the run on any unexpected browser error or any
   declared expected error that did not occur, and prints the pass line the body returns only once that is
   judged. On failure it writes `<name>.evidence.json` (versioned,
   bounded) and `<name>.evidence.txt` (a readable projection of the same data) beside the check's
   screenshots. A failure while writing evidence is reported after the original failure and never replaces
   it. Every context and the browser close however the body ends.

   PH_COMPOSER_BROWSER_TRACE=on-failure keeps a Playwright trace (actions, DOM snapshots, console, network)
   per page for failed runs; `always` keeps it for every run. Open one with
   `~/.cache/ph-composer-ui/node_modules/.bin/playwright show-trace <file>`.
   This is development evidence from a local Chrome run: it is neither HtmlDialog nor Chromium 88 proof.
   Lives outside the check glob, so `make ui-checks` does not run it as a check. */
const fs = require("node:fs");
const path = require("node:path");
const { performance } = require("node:perf_hooks");

const SCHEMA = 1;
const KIND = "ph-composer.browser-evidence";
// Every string in a report is clipped and every list is capped; a report over `reportBytes` drops its last
// events (after they were judged) until it fits, and a trace over `traceBytes` is deleted, each with a record.
const LIMITS = Object.freeze({ events: 200, message: 2000, url: 500, label: 200, stackLines: 12, steps: 50,
  reportBytes: 512 * 1024, traceBytes: 50 * 1024 * 1024 });
const TRACE_MODES = Object.freeze(["off", "on-failure", "always"]);

function clip(text, limit = LIMITS.message) {
  const value = String(text == null ? "" : text);
  return value.length <= limit ? value : `${value.slice(0, limit)}… [${value.length - limit} characters omitted]`;
}

function clipStack(stack) {
  if (!stack) return null;
  const lines = String(stack).split("\n");
  const kept = lines.slice(0, LIMITS.stackLines).map(line => clip(line, 400));
  if (lines.length > LIMITS.stackLines) kept.push(`… [${lines.length - LIMITS.stackLines} lines omitted]`);
  return kept.join("\n");
}

function urlOf(page) {
  try { return page.url(); } catch (_error) { return null; }
}

function fixtureOf(url) {
  let fixture = null;
  try { fixture = new URL(url).searchParams.get("fixture"); } catch (_error) { fixture = null; }
  return fixture == null ? null : clip(fixture, LIMITS.label);
}

function viewportOf(page) {
  try { return typeof page.viewportSize === "function" ? page.viewportSize() : null; } catch (_error) { return null; }
}

/* A RegExp without the global and sticky flags, whose `test` would otherwise keep a position between calls. */
function stateless(pattern) {
  return pattern instanceof RegExp ? new RegExp(pattern.source, pattern.flags.replace(/[gy]/g, "")) : pattern;
}

/* Whether an expectation names this event: same kind, and its pattern (a RegExp or a substring) matches
   the event's message or URL. */
function matches(expectation, event) {
  if (expectation.kind !== event.kind) return false;
  const haystack = `${event.message || ""}\n${event.url || ""}`;
  return expectation.pattern instanceof RegExp ? expectation.pattern.test(haystack)
    : haystack.includes(String(expectation.pattern));
}

/* The collector, free of Playwright: `attach` takes anything with `on(event, listener)` and `url()`, so the
   offline tests drive it with an emitter. `clock` is monotonic milliseconds, `now` the UTC Date. */
function createCollector({ check, clock = () => performance.now(), now = () => new Date() } = {}) {
  const started = clock();
  const startedAt = now().toISOString();
  const events = [], expectations = [], pages = [], steps = [];
  let omitted = 0, omittedSteps = 0, currentStep = null;

  // The page's URL, fixture and viewport are read when the event happens: checks navigate and resize one page.
  function record(kind, pageId, page, fields) {
    if (events.length >= LIMITS.events) { omitted += 1; return; }
    const url = urlOf(page);
    events.push({ kind, page: pageId, step: currentStep, at: now().toISOString(), t_ms: Math.round(clock() - started),
      page_url: url == null ? null : clip(url, LIMITS.url), fixture: fixtureOf(url), viewport: viewportOf(page),
      ...fields });
  }

  function attach(page, { viewport = null } = {}) {
    const pageId = `page-${pages.length + 1}`;
    pages.push({ id: pageId, viewport, page });
    page.on("console", message => {
      if (message.type() !== "error") return;
      const location = typeof message.location === "function" ? message.location() : null;
      record("console", pageId, page, { message: clip(message.text()),
        source: location && location.url ? clip(`${location.url}:${location.lineNumber}`, LIMITS.url) : null });
    });
    page.on("pageerror", error => record("pageerror", pageId, page,
      { message: clip(error && error.message), stack: clipStack(error && error.stack) }));
    page.on("requestfailed", request => {
      const failure = typeof request.failure === "function" ? request.failure() : null;
      record("requestfailed", pageId, page, { method: request.method(), url: clip(request.url(), LIMITS.url),
        message: clip(failure && failure.errorText ? failure.errorText : "request failed") });
    });
    page.on("response", response => {
      const status = response.status();
      if (status < 400) return;
      const request = typeof response.request === "function" ? response.request() : null;
      record("http", pageId, page, { status, method: request ? request.method() : null,
        url: clip(response.url(), LIMITS.url), message: `HTTP ${status} ${clip(response.statusText(), 200)}`.trim() });
    });
    return pageId;
  }

  return {
    attach,
    /* Names the action under way; every later event carries it until the next step. */
    step(label) {
      currentStep = clip(label, LIMITS.label);
      if (steps.length < LIMITS.steps) steps.push({ label: currentStep, t_ms: Math.round(clock() - started) });
      else omittedSteps += 1;
    },
    /* Declares a browser error this case provokes on purpose. It must occur, and only matching events are
       exempt: an expected error is not a blanket console-error exemption. */
    expect(kind, pattern) {
      if (!["console", "pageerror", "requestfailed", "http"].includes(kind)) {
        throw new Error(`browser_evidence: unknown event kind ${kind}`);
      }
      expectations.push({ kind, pattern: stateless(pattern) });
    },
    /* The run's report: unexpected events, expectations that never matched, and the original failure. Events
       past the event bound were never kept, so they cannot be judged: the run fails rather than pass on them. */
    finish({ failure = null, browser = null, artifacts = {} } = {}) {
      const unexpected = events.filter(event => !expectations.some(expectation => matches(expectation, event)));
      const expected = expectations.map(expectation => ({ kind: expectation.kind, pattern: String(expectation.pattern),
        matched: events.filter(event => matches(expectation, event)).length }));
      const missing = expected.filter(expectation => expectation.matched === 0);
      const problems = [];
      if (unexpected.length) problems.push(`${unexpected.length} unexpected browser error(s)`);
      if (missing.length) problems.push(`${missing.length} expected browser error(s) did not occur`);
      if (omitted) {
        problems.push(`${omitted} later event(s) omitted at the ${LIMITS.events}-event bound and so not judged`);
      }
      const failed = Boolean(failure) || unexpected.length > 0 || missing.length > 0 || omitted > 0;
      const report = {
        schema: SCHEMA, kind: KIND, check: clip(check, LIMITS.label), status: failed ? "failed" : "passed",
        failure: failure ? { message: clip(failure.message), stack: clipStack(failure.stack) } : null,
        problems, started_at: startedAt, elapsed_ms: Math.round(clock() - started), browser,
        pages: pages.map(entry => ({ id: entry.id, viewport: entry.viewport, fixture: fixtureOf(urlOf(entry.page)) })),
        steps: steps.slice(), omitted_steps: omittedSteps, expected,
        unexpected_count: unexpected.length, events: events.slice(), omitted_events: omitted, trimmed_events: 0,
        limits: { ...LIMITS }, artifacts
      };
      return withinBudget(report);
    }
  };
}

/* Drops the report's last events, already judged, until its JSON fits LIMITS.reportBytes, and says so. */
function withinBudget(report) {
  const size = () => Buffer.byteLength(JSON.stringify(report));
  if (size() <= LIMITS.reportBytes) return report;
  while (report.events.length && size() > LIMITS.reportBytes) {
    report.events.pop();
    report.trimmed_events += 1;
  }
  report.problems.push(`${report.trimmed_events} judged event(s) left out to keep the report under ` +
    `${LIMITS.reportBytes} bytes`);
  return report;
}

/* The readable account: a projection of the report, never extra data. */
function summarize(report) {
  const lines = [`${report.check}: ${report.status.toUpperCase()} in ${report.elapsed_ms} ms (started ${report.started_at})`];
  if (report.browser) {
    lines.push(`browser: ${report.browser.engine} ${report.browser.version || "unknown"} (${report.browser.channel}); a ` +
      "local Chrome run, not HtmlDialog or Chromium 88 evidence");
  }
  for (const page of report.pages) {
    lines.push(`${page.id}: viewport ${page.viewport ? `${page.viewport.width} x ${page.viewport.height}` : "default"}` +
      `${page.fixture ? `, fixture ${page.fixture}` : ""}`);
  }
  if (report.failure) lines.push("", "failure:", report.failure.stack || report.failure.message);
  for (const problem of report.problems) lines.push(`problem: ${problem}`);
  if (report.expected.length) {
    lines.push("", "expected errors:");
    for (const entry of report.expected) lines.push(`  ${entry.kind} ${entry.pattern}: ${entry.matched} matched`);
  }
  if (report.events.length) {
    lines.push("", "browser events:");
    for (const event of report.events) {
      const where = [event.fixture && `fixture ${event.fixture}`,
        event.viewport && `${event.viewport.width} x ${event.viewport.height}`].filter(Boolean).join(", ");
      lines.push(`  +${event.t_ms} ms ${event.page}${where ? ` [${where}]` : ""} ${event.kind}` +
        `${event.step ? ` during "${event.step}"` : ""}: ` +
        `${event.message}${event.url ? ` (${event.method || ""} ${event.url})`.replace("( ", "(") : ""}`);
    }
  }
  if (report.omitted_events) lines.push(`  … ${report.omitted_events} more omitted`);
  if (report.trimmed_events) lines.push(`  … ${report.trimmed_events} more left out of the report`);
  if (report.omitted_steps) lines.push(`steps: ${report.omitted_steps} after the first ${report.steps.length} omitted`);
  const files = Object.entries(report.artifacts).filter(([, value]) => value && (!Array.isArray(value) || value.length));
  if (files.length) {
    lines.push("", "artifacts:");
    for (const [name, value] of files) lines.push(`  ${name}: ${Array.isArray(value) ? value.join(", ") : value}`);
  }
  return `${lines.join("\n")}\n`;
}

/* Writes the JSON and text beside the screenshots. Returns the paths written and the write errors; it never
   throws, so a full disk cannot replace the failure being reported. */
function writeEvidence(report, directory, { fileSystem = fs } = {}) {
  const written = [], errors = [];
  const base = path.join(directory, report.check);
  const json = `${base}.evidence.json`, text = `${base}.evidence.txt`;
  const finalReport = { ...report, artifacts: { ...report.artifacts, evidence_json: json, evidence_txt: text } };
  for (const [file, content] of [[json, `${JSON.stringify(finalReport, null, 2)}\n`], [text, summarize(finalReport)]]) {
    try {
      fileSystem.mkdirSync(directory, { recursive: true });
      fileSystem.writeFileSync(file, content);
      written.push(file);
    } catch (error) {
      errors.push(`${file}: ${error && error.message}`);
    }
  }
  return { written, errors, report: finalReport };
}

function traceMode(value = process.env.PH_COMPOSER_BROWSER_TRACE) {
  const mode = value || "off";
  if (!TRACE_MODES.includes(mode)) {
    throw new Error(`PH_COMPOSER_BROWSER_TRACE must be one of ${TRACE_MODES.join(", ")}; got ${mode}`);
  }
  return mode;
}

/* A thrown or rejected value as an Error, so `throw null` or `Promise.reject("")` still fails the run. */
function asError(value) {
  if (value instanceof Error) return value;
  let text;
  try { text = JSON.stringify(value); } catch (_error) { text = String(value); }
  return Object.assign(new Error(`the check threw a non-Error value: ${text === undefined ? String(value) : text}`),
    { thrown: value });
}

/* A kept trace larger than LIMITS.traceBytes is deleted and recorded as omitted, not retained. */
function keepTrace(file, traces, omittedTraces, problems) {
  let bytes = 0;
  try { bytes = fs.statSync(file).size; } catch (error) {
    problems.push(`trace ${file}: ${error && error.message}`);
    return;
  }
  if (bytes <= LIMITS.traceBytes) { traces.push(file); return; }
  try { fs.unlinkSync(file); } catch (error) { problems.push(`trace ${file}: ${error && error.message}`); }
  omittedTraces.push({ file, bytes, limit: LIMITS.traceBytes });
}

/* Runs one check and returns `{ ok, report, error, evidence }` without touching the process. `browserType`
   defaults to Playwright's chromium; the offline tests pass a double. */
async function runCheck(options, body) {
  const { name, output, browserType = require("playwright").chromium, trace = traceMode(),
    launchOptions = { headless: true, channel: "chrome" } } = options;
  if (!name || !output) throw new Error("browser_evidence: a check needs a name and an output directory");
  const collector = createCollector({ check: name, ...options.clocks });
  const contexts = [];
  let browser = null, browserInfo = null, failure = null, summary = null, threw = false;
  try {
    browser = await browserType.launch(launchOptions);
    browserInfo = { engine: "chromium", channel: launchOptions.channel || "bundled",
      version: typeof browser.version === "function" ? browser.version() : null };
    const newPage = async (pageOptions = {}) => {
      const context = await browser.newContext(pageOptions);
      contexts.push(context);
      if (trace !== "off") await context.tracing.start({ screenshots: true, snapshots: true, sources: false });
      const page = await context.newPage();
      collector.attach(page, { viewport: pageOptions.viewport || null });
      return page;
    };
    summary = await body({ browser, newPage, step: collector.step, expect: collector.expect });
  } catch (error) {
    threw = true;
    failure = asError(error);
  }
  const preliminary = collector.finish({ failure, browser: browserInfo });
  const failed = threw || preliminary.status === "failed";
  const cleanupErrors = [], traces = [], omittedTraces = [];
  for (const [index, context] of contexts.entries()) {
    if (trace === "always" || (trace === "on-failure" && failed)) {
      const file = path.join(output, `${name}.trace-${index + 1}.zip`);
      try { await context.tracing.stop({ path: file }); keepTrace(file, traces, omittedTraces, cleanupErrors); }
      catch (error) { cleanupErrors.push(`trace ${file}: ${error && error.message}`); }
    } else if (trace !== "off") {
      try { await context.tracing.stop(); } catch (_error) { /* the context is closing anyway */ }
    }
    try { await context.close(); } catch (error) { cleanupErrors.push(`close context: ${error && error.message}`); }
  }
  if (browser) {
    try { await browser.close(); } catch (error) { cleanupErrors.push(`close browser: ${error && error.message}`); }
  }
  const report = collector.finish({ failure, browser: browserInfo,
    artifacts: { screenshot_dir: output, traces, omitted_traces: omittedTraces, cleanup_errors: cleanupErrors } });
  if (report.status === "passed") return { ok: true, report, error: null, evidence: null, summary };
  const evidence = writeEvidence(report, output, options);
  return { ok: false, report: evidence.report, error: failure, evidence, summary: null };
}

/* The entry a check script calls. A passing run prints the line the body returns, so nothing claims a pass
   before the browser errors are judged, then any trace or cleanup problem as a warning. A failing run prints the original failure first, then the evidence
   account and any evidence-write error, and sets a failing exit status. */
function check(options, body) {
  return runCheck(options, body).then(result => {
    if (result.ok) {
      if (result.summary) console.log(result.summary);
      for (const problem of result.report.artifacts.cleanup_errors) console.error(`browser_evidence: warning: ${problem}`);
      for (const omitted of result.report.artifacts.omitted_traces) {
        console.error(`browser_evidence: warning: trace ${omitted.file} (${omitted.bytes} bytes) deleted over the ` +
          `${omitted.limit}-byte limit`);
      }
      return result;
    }
    process.exitCode = 1;
    if (result.error) console.error(result.error.thrown === undefined ? result.error : result.error.message);
    console.error(summarize(result.report));
    for (const error of result.evidence.errors) console.error(`browser_evidence: could not write ${error}`);
    if (result.evidence.written.length) console.error(`browser evidence: ${result.evidence.written.join(", ")}`);
    return result;
  }, error => {
    process.exitCode = 1;
    console.error(error);
  });
}

module.exports = { SCHEMA, KIND, LIMITS, createCollector, summarize, writeEvidence, traceMode, runCheck, check };
