# P2-16: D2-8 deferral evidence

DATE: 2026-10-01
STATUS: Deferred to Phase 5 under Ed's confirmed D2-8 rule, after native E15 passes.

Read-only production `GET https://api.ph-nav.com/api/v1/version` reports service ph-navigator,
environment production, deployed git SHA `6240e7001a9e158118d07a879b6379b210859134`.
Unauthenticated `GET /library` and `GET /library/materials` both return HTTP 404.
`/openapi.json` also returns 404; no private catalog or project was read.

The deployed source was read through authenticated GitHub at that exact SHA:
[desktop models](https://github.com/bldgtyp/ph-navigator/blob/6240e7001a9e158118d07a879b6379b210859134/backend/features/desktop/models.py)
and [desktop routes](https://github.com/bldgtyp/ph-navigator/blob/6240e7001a9e158118d07a879b6379b210859134/backend/features/desktop/routes.py).
It serves bearer-only `/api/v1/desktop/catalogs/materials`, `frame-types` and `glazing-types`.
Their strict response models contain kind, fixed library_id, server_time and rows, with
PH-Navigator catalog DTOs rather than PH-Composer's versioned neutral library envelope.
Current GitHub main `e6adc525ba13fc9bf395b29f6345c2e39177deb7` has the same contracts.

This establishes the accepted deferral condition without credentials, client data or endpoint
changes. P2-16 and roadmap item 2.5 move to Phase 5; their planned behavior stays unchanged.
Only relative document links are repaired during the move. Phase 2 exit excludes E16.
