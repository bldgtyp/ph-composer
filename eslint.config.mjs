// The panel is plain script files loaded by an HtmlDialog, not ES modules, and the runtime floor is
// Chromium 88 (SketchUp 2023, the compatibility floor). `ecmaVersion: 2020` is that floor's syntax
// level. context/CODING_STANDARDS.md "JavaScript" owns the rules a linter cannot express.

// Every panel file is one `PhComposerUI.define` call (html/module.js); the registry is the only global.
const PANEL_GLOBALS = {
  PhComposerUI: "writable",
};

// What the HtmlDialog gives a panel file, and what the Ruby side installs on it.
const BROWSER_GLOBALS = {
  console: "readonly",
  document: "readonly",
  window: "readonly",
  navigator: "readonly",
  location: "readonly",
  setTimeout: "readonly",
  clearTimeout: "readonly",
  setInterval: "readonly",
  clearInterval: "readonly",
  requestAnimationFrame: "readonly",
  cancelAnimationFrame: "readonly",
  getComputedStyle: "readonly",
  performance: "readonly",
  Image: "readonly",
  Event: "readonly",
  CustomEvent: "readonly",
  ClipboardEvent: "readonly",
  DataTransfer: "readonly",
  MutationObserver: "readonly",
  ResizeObserver: "readonly",
  XMLHttpRequest: "readonly",
  fetch: "readonly",
  URL: "readonly",
  Blob: "readonly",
  FileReader: "readonly",
  sketchup: "readonly",
};

const NODE_GLOBALS = {
  require: "readonly",
  module: "writable",
  exports: "writable",
  __dirname: "readonly",
  __filename: "readonly",
  process: "readonly",
  console: "readonly",
  Buffer: "readonly",
  URL: "readonly",
  setTimeout: "readonly",
  clearTimeout: "readonly",
  setImmediate: "readonly",
  global: "writable",
};

// Runtime APIs that arrived after Chromium 88, the floor host's engine. Checked by the parser rather
// than by searching the text, so a name inside a comment or a string is not a finding. Adding a name
// is a floor decision. A post-88 global such as `structuredClone` needs no entry: it is not in the
// declared globals above, so `no-undef` already refuses it. Instance methods can only be matched by
// name, so `at`, `with` and `group` are left out: a selector cannot tell the receiver apart.
const AFTER_CHROMIUM_88_STATICS = [
  { object: "Object", property: "hasOwn", message: "Object.hasOwn arrived in Chromium 93, above the floor's 88." },
  { object: "Object", property: "groupBy", message: "Object.groupBy arrived in Chromium 117, above the floor's 88." },
  { object: "Array", property: "fromAsync", message: "Array.fromAsync arrived in Chromium 121, above the floor's 88." },
  { object: "crypto", property: "randomUUID", message: "crypto.randomUUID arrived in Chromium 92, above 88." },
  { object: "AbortSignal", property: "timeout", message: "AbortSignal.timeout arrived in Chromium 103, above 88." },
  {
    object: "Intl",
    property: "supportedValuesOf",
    message: "Intl.supportedValuesOf arrived in Chromium 99, above the floor host's 88.",
  },
];
const AFTER_CHROMIUM_88_METHODS = {
  selector: "CallExpression[callee.property.name=/^(findLast|findLastIndex|toSorted|toReversed|toSpliced)$/]",
  message: "This array method arrived in Chromium 97 or later, above the floor host's 88.",
};

const SHARED_RULES = {
  "no-undef": "error",
  "no-unused-vars": ["error", { args: "none", caughtErrors: "none" }],
  "max-len": ["error", { code: 120, ignoreUrls: true }],
};

export default [
  {
    ignores: ["src/ph_composer/vendor/**", "vendor/**", "node_modules/**", "_private/**"],
  },
  {
    // The shipped panel.
    files: ["src/ph_composer/html/**/*.js"],
    languageOptions: {
      ecmaVersion: 2020,
      sourceType: "script",
      globals: { ...BROWSER_GLOBALS, ...PANEL_GLOBALS },
    },
    rules: {
      ...SHARED_RULES,
      "no-restricted-properties": ["error", ...AFTER_CHROMIUM_88_STATICS],
      "no-restricted-syntax": ["error", AFTER_CHROMIUM_88_METHODS],
    },
  },
  {
    // The offline suite and the Node tools.
    files: ["tests/**/*.js", "tools/**/*.js"],
    languageOptions: {
      ecmaVersion: 2020,
      sourceType: "script",
      globals: { ...NODE_GLOBALS, ...PANEL_GLOBALS },
    },
    rules: SHARED_RULES,
  },
];
