/* Views of one host table, contributed by any feature (context/EXTENSIBILITY.md, "Zone views"). A screen
   declares itself a host; a view registers under the host's id with what it reads and draws. The host
   lists the views whose snapshot sections are published, so a build without a feature shows none of its
   views. This module names no host and no view. */
PhComposerUI.define("table_views", ["snapshot"], function (snapshot) {
  "use strict";
  var hosts = Object.create(null), views = Object.create(null);

  function entries(hostId) { return views[hostId] || (views[hostId] = []); }

  /* A view is checked as it registers: it needs an id and a label, and its id is its own under one host. */
  function register(hostId, view) {
    if (!hostId) throw new Error("A table view needs a host id.");
    if (!view || !view.id || !view.label) throw new Error("A table view needs an id and a label.");
    var list = entries(hostId);
    if (list.some(function (entry) { return entry.id === view.id; })) {
      throw new Error("Duplicate table view " + view.id + " under " + hostId + ".");
    }
    list.push(view);
    return function () {
      var index = list.indexOf(view);
      if (index >= 0) list.splice(index, 1);
    };
  }

  /* The host's own handle: the views listed for one snapshot, in order, each only while every section it
     names is published. */
  function host(hostId) {
    if (!hostId) throw new Error("A table view host needs an id.");
    hosts[hostId] = true;
    return {
      views: function (state) {
        return entries(hostId).filter(function (view) {
          return (view.sections || []).every(function (name) { return snapshot.section(state, name) !== null; });
        }).slice().sort(function (a, b) { return (a.order || 0) - (b.order || 0); });
      }
    };
  }

  /* Views registered under an id no screen declared, to report once the panel has loaded every module. */
  function unhosted() {
    return Object.keys(views).filter(function (hostId) { return !hosts[hostId] && views[hostId].length; })
      .reduce(function (all, hostId) {
        return all.concat(views[hostId].map(function (view) { return view.id + " (host " + hostId + ")"; }));
      }, []);
  }

  return { register: register, host: host, unhosted: unhosted };
});
