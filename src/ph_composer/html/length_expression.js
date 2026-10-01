/* The length expression reader: "4' 6\"", "1200mm + 25", "3 1/2 in". It scans the text into tokens and
   evaluates them in one pass, so a malformed expression names what it could not read. */
PhComposerUI.define("length_expression", ["unit_numbers", "unit_tables"], function (numbers, tables) {
  "use strict";
  var LENGTH_UNITS = tables.LENGTH_UNITS, DIMENSION_BY_ID = tables.DIMENSION_BY_ID,
    METRES_PER_INCH = tables.METRES_PER_INCH;
  var classifyUnit = tables.classifyUnit;
  var parseRegionalNumber = numbers.parseRegionalNumber, isSpaceGroup = numbers.isSpaceGroup;

  function normalizeLengthQuotes(text, format) {
    var normalized = text.replace(/[′‘´\x60]/g, "'").replace(/[″“”]/g, "\"");
    return format.group === "’" ? normalized : normalized.replace(/’/g, "'");
  }

  function scanNumber(text, start, format) {
    var end = start;
    var scannedEnd;
    var candidate;
    var parsed;
    var actualEnd;
    var remainder;
    var bestFailure = null;
    var char;
    while (end < text.length) {
      char = text.charAt(end);
      if (!/[0-9.,eE+\- ’'  ]/.test(char)) break;
      if ((char === "+" || char === "-") && end > start && !/[eE]/.test(text.charAt(end - 1))) break;
      end += 1;
    }
    scannedEnd = end;
    // The longest prefix that reads as a number is the token; the failures of longer prefixes decide the error.
    while (end > start) {
      candidate = text.slice(start, end).trim();
      if (candidate) {
        parsed = parseRegionalNumber(candidate, format);
        if (parsed.ok) {
          actualEnd = start + text.slice(start, end).replace(/\s+$/, "").length;
          remainder = text.slice(actualEnd, scannedEnd);
          // A space followed by a fraction starts a mixed number (2 1/2), not a malformed group.
          if (bestFailure === "number_format" && (/^[.,]/.test(remainder) ||
              (isSpaceGroup(format.group) && /^[   ]+\d/.test(remainder) &&
                !/^[   ]+\d+\s*\//.test(text.slice(actualEnd))))) return { error: "number_format" };
          if (bestFailure === "nonfinite" && /^[0-9eE]/.test(remainder)) return { error: "nonfinite" };
          return { token: { type: "number", value: parsed.value, start: start, end: actualEnd }, next: actualEnd };
        }
        if (!bestFailure || parsed.code === "number_format") bestFailure = parsed.code;
      }
      end -= 1;
    }
    return { error: bestFailure || "malformed" };
  }

  function tokenizeLength(text, format) {
    var tokens = [];
    var position = 0;
    var scanned;
    var start;
    var char;
    while (position < text.length) {
      char = text.charAt(position);
      start = position;
      if (/\s/.test(char)) { position += 1; continue; }
      if (/\d/.test(char) || char === format.decimal) {
        scanned = scanNumber(text, position, format);
        if (scanned.error) return { error: scanned.error };
        tokens.push(scanned.token); position = scanned.next; continue;
      }
      if (/[+\-*/()]/.test(char)) {
        tokens.push({ type: char, start: position, end: position + 1 });
        position += 1;
        continue;
      }
      if (char === "'" || char === "’" || char === "\"") {
        tokens.push({ type: "unit", text: char === "’" ? "'" : char, start: position, end: position + 1 });
        position += 1;
        continue;
      }
      if (/[A-Za-z°²³μ]/.test(char)) {
        while (position < text.length && /[A-Za-z°²³μ]/.test(text.charAt(position))) position += 1;
        tokens.push({ type: "unit", text: text.slice(start, position), start: start, end: position }); continue;
      }
      return { error: "malformed" };
    }
    return { tokens: tokens };
  }

  function defaultLengthUnit(context) {
    var value = context.defaultUnit || "mm";
    return DIMENSION_BY_ID[value] && DIMENSION_BY_ID[value].architectural ? "in" : (LENGTH_UNITS[value] ? value : "mm");
  }

  /* Evaluates a length expression to metres, or returns { error, data }. */
  function parseLengthExpression(text, context) {
    var tokenized = tokenizeLength(normalizeLengthQuotes(text, context.numberFormat), context.numberFormat);
    var defaultMetres = LENGTH_UNITS[defaultLengthUnit(context)].metres;
    var list;
    var position = 0;
    var failure = null;
    var result;
    if (tokenized.error) return { error: tokenized.error };
    list = tokenized.tokens;

    function fail(code, data) {
      if (!failure) failure = { error: code, data: data };
      return { number: NaN, dimension: "scalar" };
    }
    function peek(offset) { return list[position + (offset || 0)]; }
    function asLength(value) {
      return value.dimension === "length" ? value : { number: value.number * defaultMetres, dimension: "length" };
    }
    function joined(left, right) { return left && right && left.end === right.start; }

    /* A proper integer fraction starting at the token offset, or null. */
    function fractionAt(offset) {
      var numerator = peek(offset);
      var slash = peek(offset + 1);
      var denominator = peek(offset + 2);
      if (!numerator || numerator.type !== "number" || !slash || slash.type !== "/" || !denominator ||
        denominator.type !== "number") return null;
      if (numerator.value % 1 || denominator.value % 1 ||
        !(denominator.value > 1 && numerator.value < denominator.value)) return null;
      return numerator.value / denominator.value;
    }

    function literal() {
      var whole = peek();
      var next = peek(1);
      var fraction;
      if (!whole || whole.type !== "number") return null;
      // Mixed numbers: a joined hyphen (2-1/2) or whitespace (2 1/2) before a proper fraction.
      if (next && next.type === "-" && joined(whole, next) && joined(next, peek(2)) &&
        (fraction = fractionAt(2)) !== null) {
        position += 5;
        return whole.value + fraction;
      }
      if (next && next.type === "number" && whole.end < next.start && (fraction = fractionAt(1)) !== null) {
        position += 4;
        return whole.value + fraction;
      }
      // A bare proper fraction binds as one literal only when a unit follows it (1/2 in).
      if ((fraction = fractionAt(0)) !== null && peek(3) && peek(3).type === "unit") { position += 3; return fraction; }
      position += 1;
      return whole.value;
    }

    function applyUnit(number, token) {
      var info = classifyUnit(token.text, "length");
      if (!info.unit) return fail(info.wrongLabel ? "wrong_quantity" : "unsupported_unit", token.text);
      return { number: number * LENGTH_UNITS[info.unit].metres, dimension: "length", unit: info.unit };
    }

    function factor() {
      var token = peek();
      var value;
      var number;
      var unitToken;
      var mark;
      var hyphen;
      var inches;
      if (token && token.type === "(") {
        position += 1;
        value = sum(false);
        if (failure) return value;
        if (!peek() || peek().type !== ")") return fail("malformed");
        position += 1;
        unitToken = peek();
        if (!unitToken || unitToken.type !== "unit") return value;
        position += 1;
        return value.dimension === "length" ? fail("double_unit") : applyUnit(value.number, unitToken);
      }
      number = literal();
      if (number === null) return fail("malformed");
      unitToken = peek();
      if (!unitToken || unitToken.type !== "unit") return { number: number, dimension: "scalar" };
      position += 1;
      value = applyUnit(number, unitToken);
      if (failure) return value;
      if (value.unit === "ft") {
        // Feet followed by inches form one compound (1' 2", 1'-2"); a spaced hyphen is subtraction.
        mark = position;
        hyphen = peek();
        if (hyphen && hyphen.type === "-") {
          if (!joined(unitToken, hyphen) || !joined(hyphen, peek(1))) return value;
          position += 1;
        }
        inches = literal();
        if (inches !== null && peek() && peek().type === "unit" && classifyUnit(peek().text, "length").unit === "in") {
          position += 1;
          return { number: value.number + inches * METRES_PER_INCH, dimension: "length" };
        }
        if (hyphen && hyphen.type === "-") return fail("malformed");
        position = mark;
      }
      return peek() && peek().type === "unit" ? fail("double_unit") : value;
    }

    function product() {
      var left = factor();
      var operator;
      var right;
      while (!failure && peek() && (peek().type === "*" || peek().type === "/")) {
        operator = peek().type; position += 1; right = factor();
        if (failure) return left;
        if (operator === "/" && right.number === 0) return fail("division_by_zero");
        if (right.dimension === "length" &&
          (operator === "/" || left.dimension === "length")) return fail("non_length_result");
        left = {
          number: operator === "*" ? left.number * right.number : left.number / right.number,
          dimension: left.dimension === "length" || right.dimension === "length" ? "length" : "scalar"
        };
        if (!isFinite(left.number)) return fail("nonfinite");
      }
      return left;
    }

    function sum(allowSign) {
      var negative = allowSign && peek() && peek().type === "-";
      var left;
      var operator;
      var right;
      if (negative) position += 1;
      left = product();
      // A leading sign belongs to the first term only: -1 ft + 2 in is -254 mm.
      if (negative) left = { number: -left.number, dimension: left.dimension };
      while (!failure && peek() && (peek().type === "+" || peek().type === "-")) {
        operator = peek().type; position += 1; right = product();
        if (failure) return left;
        // Bare additive terms take the field's starting unit once any term is a length.
        if (left.dimension === "length" || right.dimension === "length") {
          left = asLength(left);
          right = asLength(right);
        }
        left = { number: operator === "+" ? left.number + right.number : left.number - right.number,
          dimension: left.dimension };
        if (!isFinite(left.number)) return fail("nonfinite");
      }
      return left;
    }

    result = sum(true);
    if (!failure && position !== list.length) fail("malformed");
    return failure || { metres: asLength(result).number };
  }

  return { parseLengthExpression: parseLengthExpression, tokenizeLength: tokenizeLength,
    defaultLengthUnit: defaultLengthUnit };
});
