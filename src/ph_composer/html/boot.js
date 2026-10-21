/* Starts the kit and the page's entry module, named on <body data-phc-entry>. The one script a page runs
   outside the generated module list, so that no page needs an inline script, which its
   Content-Security-Policy forbids. */
(function () {
  "use strict";
  var entry = document.body.getAttribute("data-phc-entry");
  PhComposerUI.start()[entry].ready();
}());
