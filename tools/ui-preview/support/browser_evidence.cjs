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
// Expectations are judged against each field as observed, up to `matchChars`, never against the clipped copy.
const LIMITS = Object.freeze({ events: 200, message: 2000, url: 500, label: 200, stackLines: 12, steps: 50,
  pages: 50, expectations: 100, cleanupErrors: 20, matchChars: 64 * 1024, reportBytes: 512 * 1024,
  traceBytes: 50 * 1024 * 1024 });
const KINDS = Object.freeze(["console", "pageerror", "requestfailed", "http"]);
// A check name becomes a file name in the evidence directory, so it is one plain path segment.
const NAME = /^[A-Za-z0-9_][A-Za-z0-9_.-]{0,99}$/;
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
  try { return sizeOf(typeof page.viewportSize === "function" ? page.viewportSize() : null); } catch (_error) {
    return null;
  }
}

/* Only the two numbers of a viewport, whatever object the caller or the page supplied. */
function sizeOf(viewport) {
  if (!viewport || typeof viewport !== "object") return null;
  const width = Number(viewport.width), height = Number(viewport.height);
  return Number.isFinite(width) && Number.isFinite(height) ? { width, height } : null;
}

/* A RegExp without the global and sticky flags, whose `test` would otherwise keep a position between calls. */
function stateless(pattern) {
  return pattern instanceof RegExp ? new RegExp(pattern.source, pattern.flags.replace(/[gy]/g, "")) : pattern;
}

/* Whether an expectation names this observation: same kind, and its pattern (a RegExp or a substring)
   matches the observed message or the observed URL, each tested on its own. */
function matches(expectation, observed) {
  if (expectation.kind !== observed.kind) return false;
  return [observed.message, observed.url].some(field => field != null && (expectation.pattern instanceof RegExp
    ? expectation.pattern.test(field) : field.includes(String(expectation.pattern))));
}

/* Reads a property that may throw (an Error's stack getter can), so formatting never replaces a failure. */
function read(object, key) {
  try { return object == null ? null : object[key]; } catch (_error) { return null; }
}

/* The collector, free of Playwright: `attach` takes anything with `on(event, listener)` and `url()`, so the
   offline tests drive it with an emitter. `clock` is monotonic milliseconds, `now` the UTC Date. */
function createCollector({ check, clock = () => performance.now(), now = () => new Date() } = {}) {
  const started = clock();
  const startedAt = now().toISOString();
  const events = [], observed = [], expectations = [], pages = [], steps = [];
  let omitted = 0, omittedSteps = 0, omittedPages = 0, currentStep = null, closing = false;

  // The page's URL, fixture and viewport are read when the event happens: checks navigate and resize one page.
  function record(kind, pageId, page, fields, raw) {
    if (closing) return;
    if (events.length >= LIMITS.events) { omitted += 1; return; }
    const url = urlOf(page);
    const field = value => (value == null ? null : String(value).slice(0, LIMITS.matchChars));
    observed.push({ kind, message: field(raw.message), url: field(raw.url) });
    events.push({ kind, page: pageId, step: currentStep, at: now().toISOString(), t_ms: Math.round(clock() - started),
      page_url: url == null ? null : clip(url, LIMITS.url), fixture: fixtureOf(url), viewport: viewportOf(page),
      ...fields });
  }

  /* A listener that cannot read its event still records one of that kind, so the run cannot pass on it. */
  function listen(page, pageId, name, kind, handler) {
    page.on(name, payload => {
      try { handler(payload); } catch (error) {
        const text = `the collector could not read this ${kind} event: ${clip(read(error, "message"), LIMITS.label)}`;
        record(kind, pageId, page, { message: text }, { message: text });
      }
    });
  }

  function attach(page, { viewport = null } = {}) {
    const pageId = `page-${pages.length + omittedPages + 1}`;
    if (pages.length < LIMITS.pages) pages.push({ id: pageId, viewport: sizeOf(viewport), page });
    else omittedPages += 1;
    listen(page, pageId, "console", "console", message => {
      if (message.type() !== "error") return;
      const location = typeof message.location === "function" ? message.location() : null;
      const text = message.text();
      record("console", pageId, page, { message: clip(text),
        source: location && location.url ? clip(`${location.url}:${location.lineNumber}`, LIMITS.url) : null },
      { message: text });
    });
    listen(page, pageId, "pageerror", "pageerror", error => record("pageerror", pageId, page,
      { message: clip(read(error, "message")), stack: clipStack(read(error, "stack")) }, { message: read(error, "message") }));
    listen(page, pageId, "requestfailed", "requestfailed", request => {
      const failure = typeof request.failure === "function" ? request.failure() : null;
      const text = failure && failure.errorText ? failure.errorText : "request failed";
      record("requestfailed", pageId, page, { method: request.method(), url: clip(request.url(), LIMITS.url),
        message: clip(text) }, { message: text, url: request.url() });
    });
    listen(page, pageId, "response", "http", response => {
      const status = response.status();
      if (status < 400) return;
      const request = typeof response.request === "function" ? response.request() : null;
      const text = `HTTP ${status} ${response.statusText()}`.trim();
      record("http", pageId, page, { status, method: request ? request.method() : null,
        url: clip(response.url(), LIMITS.url), message: clip(text, LIMITS.label) }, { message: text, url: response.url() });
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
      if (!KINDS.includes(kind)) throw new Error(`browser_evidence: unknown event kind ${String(kind).slice(0, 40)}`);
      if (!(pattern instanceof RegExp) && !(typeof pattern === "string" && pattern.length > 0)) {
        throw new Error("browser_evidence: an expectation needs a RegExp or a non-empty string");
      }
      if (expectations.length >= LIMITS.expectations) {
        throw new Error(`browser_evidence: a check declares at most ${LIMITS.expectations} expectations`);
      }
      expectations.push({ kind, pattern: stateless(pattern) });
    },
    /* Stops recording: events that arrive while contexts close (aborted requests) are not judged. */
    close() {
      closing = true;
    },
    /* The run's report: unexpected events, expectations that never matched, and the original failure. Events
       past the event bound were never kept, so they cannot be judged: the run fails rather than pass on them. */
    finish({ failure = null, browser = null, artifacts = {} } = {}) {
      const surprising = observed.map(entry => !expectations.some(expectation => matches(expectation, entry)));
      const unexpected = observed.filter((_entry, index) => surprising[index]);
      const expected = expectations.map(expectation => ({ kind: expectation.kind,
        pattern: clip(String(expectation.pattern), LIMITS.label),
        matched: observed.filter(entry => matches(expectation, entry)).length }));
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
        failure: failure ? { message: clip(read(failure, "message")), stack: clipStack(read(failure, "stack")) } : null,
        problems, started_at: startedAt, elapsed_ms: Math.round(clock() - started), browser,
        pages: pages.map(entry => ({ id: entry.id, viewport: entry.viewport, fixture: fixtureOf(urlOf(entry.page)) })),
        omitted_pages: omittedPages, steps: steps.slice(), omitted_steps: omittedSteps, expected,
        unexpected_count: unexpected.length,
        events: events.map((event, index) => ({ ...event, unexpected: surprising[index] })),
        omitted_events: omitted, trimmed_events: 0,
        limits: { ...LIMITS }, artifacts
      };
      return withinBudget(report);
    }
  };
}

function serialize(report) {
  return `${JSON.stringify(report, null, 2)}\n`;
}

const TRIMMED = "judged event(s) left out to keep the report under";

/* Drops judged events until the file the report is written as fits LIMITS.reportBytes, and says so: expected
   events go first, latest first, so the unexpected ones that failed the run stay. Measured on the written
   form, so it is applied again once the evidence paths are added. A report still over budget with no events
   left becomes its essentials alone. */
function withinBudget(report) {
  const problems = report.problems.filter(problem => !problem.includes(TRIMMED));
  const note = () => `${report.trimmed_events} ${TRIMMED} ${LIMITS.reportBytes} bytes`;
  const size = () => Buffer.byteLength(serialize({ ...report, problems: problems.concat(note()) }));
  if (Buffer.byteLength(serialize(report)) <= LIMITS.reportBytes) return report;
  while (report.events.length && size() > LIMITS.reportBytes) {
    const expected = report.events.map(event => !event.unexpected).lastIndexOf(true);
    report.events.splice(expected >= 0 ? expected : report.events.length - 1, 1);
    report.trimmed_events += 1;
  }
  report.problems = problems.concat(note());
  return size() <= LIMITS.reportBytes ? report : essentials(report);
}

/* What a report keeps when even its other fields overflow the budget: identity, outcome, failure, counts. */
function essentials(report) {
  return { schema: report.schema, kind: report.kind, check: report.check, status: report.status,
    failure: report.failure, started_at: report.started_at, elapsed_ms: report.elapsed_ms,
    problems: report.problems.slice(0, 10).map(problem => clip(problem, LIMITS.label))
      .concat("the report's other fields exceeded the byte budget and were left out"),
    pages: [], steps: [], expected: [], events: [], unexpected_count: report.unexpected_count,
    omitted_events: report.omitted_events, trimmed_events: report.trimmed_events, omitted_steps: 0,
    limits: report.limits, artifacts: {} };
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
  let finalReport = report;
  try {
    finalReport = withinBudget({ ...report, events: report.events.slice(), problems: report.problems.slice(),
      artifacts: { ...report.artifacts, evidence_json: json, evidence_txt: text } });
  } catch (error) {
    errors.push(`budget: ${clip(read(error, "message"), LIMITS.label)}`);
  }
  for (const [file, render] of [[json, serialize], [text, summarize]]) {
    try {
      const content = render(finalReport);
      fileSystem.mkdirSync(directory, { recursive: true });
      fileSystem.writeFileSync(file, content);
      written.push(file);
    } catch (error) {
      errors.push(`${file}: ${clip(read(error, "message"), LIMITS.label)}`);
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
  try { text = JSON.stringify(value); } catch (_error) { text = undefined; }
  if (text === undefined) {
    try { text = String(value); } catch (_error) { text = Object.prototype.toString.call(value); }
  }
  return Object.assign(new Error(`the check threw a non-Error value: ${clip(text, LIMITS.label)}`), { thrown: value });
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
  if (!NAME.test(String(name || "")) || !output) {
    throw new Error("browser_evidence: a check needs a plain name (letters, digits, _ . -) and an output directory");
  }
  const collector = createCollector({ check: name, ...options.clocks });
  const contexts = [];
  let browser = null, browserInfo = null, failure = null, summary = null, threw = false;
  try {
    browser = await browserType.launch(launchOptions);
    browserInfo = { engine: "chromium", channel: clip(launchOptions.channel || "bundled", LIMITS.label),
      version: typeof browser.version === "function" ? clip(browser.version(), LIMITS.label) : null };
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
  // Judged once, before anything closes: events that closing provokes (aborted requests) are not the check's,
  // and the same verdict decides which traces to keep. A failure to judge counts as failed and skips nothing.
  collector.close();
  const cleanupErrors = [], traces = [], omittedTraces = [];
  const problem = text => {
    if (cleanupErrors.length < LIMITS.cleanupErrors) cleanupErrors.push(clip(text));
  };
  let failed = threw;
  try { failed = failed || collector.finish({ failure, browser: browserInfo }).status === "failed"; }
  catch (error) { failed = true; problem(`judge run: ${read(error, "message")}`); }
  for (const [index, context] of contexts.entries()) {
    if (trace === "always" || (trace === "on-failure" && failed)) {
      const file = path.join(output, `${name}.trace-${index + 1}.zip`);
      try {
        await context.tracing.stop({ path: file });
        const kept = [];
        keepTrace(file, traces, omittedTraces, kept);
        kept.forEach(problem);
      } catch (error) { problem(`trace ${file}: ${read(error, "message")}`); }
    } else if (trace !== "off") {
      try { await context.tracing.stop(); } catch (_error) { /* the context is closing anyway */ }
    }
    try { await context.close(); } catch (error) { problem(`close context: ${read(error, "message")}`); }
  }
  if (browser) {
    try { await browser.close(); } catch (error) { problem(`close browser: ${read(error, "message")}`); }
  }
  const artifacts = { screenshot_dir: clip(output, LIMITS.url), traces: traces.map(file => clip(file, LIMITS.url)),
    omitted_traces: omittedTraces.map(entry => ({ ...entry, file: clip(entry.file, LIMITS.url) })),
    cleanup_errors: cleanupErrors };
  let report;
  try {
    report = collector.finish({ failure, browser: browserInfo, artifacts });
  } catch (error) {
    // The original failure, if any, stays the run's error; the formatting failure is reported beside it.
    const fallback = failure || new Error("browser_evidence: the run could not be judged");
    report = essentials({ schema: SCHEMA, kind: KIND, check: name, status: "failed",
      failure: { message: clip(read(fallback, "message")), stack: null }, started_at: null, elapsed_ms: null,
      problems: [`judge run: ${clip(read(error, "message"), LIMITS.label)}`], unexpected_count: null,
      omitted_events: null, trimmed_events: 0, limits: { ...LIMITS } });
    return { ok: false, report, error: fallback, evidence: writeEvidence(report, output, options), summary: null };
  }
  if (!failed && report.status === "passed") return { ok: true, report, error: null, evidence: null, summary };
  const evidence = writeEvidence(report, output, options);
  return { ok: false, report: evidence.report, error: failure, evidence, summary: null };
}

/* The entry a check script calls. A passing run prints the line the body returns, so nothing claims a pass
   before the browser errors are judged, then any trace or cleanup problem as a warning. A failing run prints
   the original failure first, then the evidence account and any evidence-write error, and sets a failing exit
   status. Printing itself cannot turn a failure into a pass. */
function check(options, body) {
  return runCheck(options, body).then(result => {
    try { report(result); } catch (error) {
      if (!result.ok) process.exitCode = 1;
      console.error(`browser_evidence: could not print the result: ${read(error, "message")}`);
    }
    return result;
  }, error => {
    process.exitCode = 1;
    console.error(error);
  });
}

function report(result) {
  const artifacts = result.report.artifacts || {};
  if (result.ok) {
    if (result.summary) console.log(result.summary);
    for (const problem of artifacts.cleanup_errors || []) console.error(`browser_evidence: warning: ${problem}`);
    for (const omitted of artifacts.omitted_traces || []) {
      console.error(`browser_evidence: warning: trace ${omitted.file} (${omitted.bytes} bytes) deleted over the ` +
        `${omitted.limit}-byte limit`);
    }
    return;
  }
  process.exitCode = 1;
  if (result.error) console.error(result.error.thrown === undefined ? result.error : result.error.message);
  console.error(summarize(result.report));
  for (const error of result.evidence.errors) console.error(`browser_evidence: could not write ${error}`);
  if (result.evidence.written.length) console.error(`browser evidence: ${result.evidence.written.join(", ")}`);
}

module.exports = { SCHEMA, KIND, LIMITS, createCollector, summarize, writeEvidence, traceMode, runCheck, check };
