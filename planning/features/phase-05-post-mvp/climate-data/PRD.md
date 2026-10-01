# Climate data

DATE: 2026-09-18
STATUS: Requested. Post-MVP draft; D7 and D9 confirmed, remaining questions not interviewed.
AUTHOR: Ed May, BLDGTYP, with Claude
ISSUE: none (no remote)

## Problem

METr needs a climate. If the export carries none, the consultant sets it in METr after every
export. If the export carries one, a variant study needs no manual step. The climate also feeds
two later views, the sun path and the window radiation overlay.

## Product boundary

D7 confirms the narrow boundary. PH-Composer ships and distributes no climate datasets. A user
may import or link a climate dataset they are entitled to use, manually enter or paste values, or
select a local EPW obtained from a public source such as the Ladybug EPW Map. PH-Composer keeps
a self-contained model snapshot after import. It does not host a climate map, mirror EPW files or
ship a catalog.

## Port disposition

| Part | Disposition | Note |
| --- | --- | --- |
| Predecessor C1 brief: site versus station, snapshot with provenance, offline reading, stale states | Port | No designPH dependency in any of it |
| C1's PHPP framing of the radiation data | Drop | The target is Phius and METr. The data shape is the same and is cited from honeybee-ph and PHX instead |
| C1's links into PH-Navigator web and the PHI rules repository | Drop | Both are private repositories |
| Record engine, unit fields | Port | From the foundation transplant |
| Library provider seam for optional user-configured sources | New | See Q3; no provider address or catalog ships |
| honeybee-ph `Site.from_epw()` and `_epw.py` | Reuse | Existing hourly-EPW to PH monthly conversion; do not build a second converter |
| PH-Navigator-Web EPW services | Prior art only | The older app loads EPWs for viewer/weather functions. V2 has catalog, upload and weather-source plumbing plus a normalized climate schema, but its weather source does not yet produce the monthly record. Neither owns the EPW-to-PH-monthly converter |

## What honeybee-ph and METr take

Verified in `honeybee_ph/site.py` and PHX `to_METr_JSON/metr_schemas.py`, `_PhxSite`.

- `Site` holds a `Location` (`latitude`, `longitude`, `site_elevation`, `climate_zone`) and a
  `Climate`.
- `Climate` holds `station_elevation` (m), `summer_daily_temperature_swing` (K),
  `average_wind_speed` (m/s), a ground block, `monthly_temps` (air, dewpoint, sky, ground),
  `monthly_radiation` (north, east, south, west, global; twelve values each, kWh/m²), and
  `peak_loads` (two heating and two cooling cases, each with a temperature and five radiation
  values in W/m²).
- `ClimateProvenance` already exists in honeybee-ph: `source_type`, `source_name`, `source_uri`,
  `source_version`, `source_checksum`, `conversion_method`, `is_certification_approved`,
  `monthly_data_available`, `peak_load_data_available`, `assumptions`.
- METr's site block takes latitude, station elevation, climate zone, daily temperature swing,
  wind speed, and the monthly arrays with the four peak-load cases appended as positions 12 to
  15. So a full snapshot does reach METr.
- honeybee-ph `Site.from_epw()` already converts a caller-supplied annual EPW into the location,
  monthly temperatures, monthly radiation, ground temperatures, wind speed and daily swing above.
  It records checksum, method and `source_type=epw_derived`, sets
  `is_certification_approved=False`, and deliberately leaves peak-load data unavailable. It
  requires an EPW ground-temperature series; the user chooses a depth if the file has several.
- PHX currently refuses that monthly-only Site for export because the METr climate block also
  needs peak-load cases. This is an honest readiness boundary, not missing converter work. D9
  confirms that the user supplies those cases separately before climate-bearing METr export.

## Records

```
Model   gains  site { latitude_deg, longitude_deg, elevation_m, climate_zone }
               climate { name, station_elevation_m, daily_temp_swing_k, wind_speed_m_s,
                         monthly { air_c[12], dewpoint_c[12], sky_c[12], ground_c[12],
                                   rad_north_kwh_m2[12], east, south, west, global },
                         peak_loads { heat_1, heat_2, cool_1, cool_2 },
                         provenance { ...honeybee-ph ClimateProvenance fields } }
```

The snapshot is a copy. The model never needs the source again to be read. A local link may be
kept as a convenience for source-change checks, but the snapshot is authoritative and works
offline. Exported provenance includes a source label, checksum and conversion method, never an
absolute local path. EPW-derived monthly data is valid for preliminary work but is not METr-ready
until the user supplies the required peak-load cases.

## Behaviors

- A Climate section shows the site, the chosen dataset, its source and its twelve-month table.
- **Use local climate file** accepts a user-owned monthly climate file through the provider seam.
- **Use EPW** accepts a local annual EPW and calls honeybee-ph `Site.from_epw()`; it does not
  implement another converter. **Find an EPW** opens the Ladybug EPW Map in the user's browser so
  the user can obtain and select a file. PH-Composer does not scrape, mirror or redistribute it.
- The UI labels EPW results **EPW-derived monthly climate** and **not certification approved**. It
  shows monthly-demand readiness separately from peak-load/METr-export readiness.
- Site location is separate from the climate station, and the distance between them is shown.
- Choosing a dataset replaces the snapshot in one Undo step after a comparison of old and new.
- Offline, the saved snapshot stays fully readable.
- A "source changed" mark appears when the provider's copy differs, the same quiet mark the
  libraries packet uses. Nothing updates on its own.
- Export writes `Site` to the HBJSON and names the source in the Export report, by provider and
  record id, never by address or path.

## Decisions for the interview

| # | Question | Recommendation |
| --- | --- | --- |
| Q1 | Confirm the narrowed climate-picker boundary in D7? | Confirmed: local/user-owned inputs and manual entry are in; hosted map tiles and distributed datasets are out |
| Q2 | Which dataset kinds? | Confirmed in part: user-owned monthly climate data and EPW-derived monthly data. Any future PHI or Phius format is an adapter, not bundled content |
| Q3 | Where do datasets come from? | User-selected local files, manual entry/paste, or an optional provider through the `climates` record kind. **Find an EPW** links to the Ladybug EPW Map; the user obtains the file. No catalog or provider address ships |
| Q4 | May any Phius climate data be redistributed? | Not by PH-Composer for now, regardless of whether permission might later be available. User-supplied data remains local and the repository's public fixtures are synthetic |
| Q5 | What sets the site location? | An explicit value in the Climate section, with a "Read from SketchUp geolocation" button. No silent sync in either direction |
| Q6 | Does the site location write back to SketchUp's geolocation and north? | No |
| Q7 | Manual entry of a full monthly table? | Yes, by paste from a spreadsheet. It keeps the no-provider workflow whole |
| Q8 | EPW ground temperatures are absent or several depths exist | Block conversion when absent. When several exist, show the available depths and require an explicit choice; preselect the shallowest only as a visible recommendation |
| Q9 | How are peak loads supplied for EPW-derived climates? | Confirmed in D9: manual entry, paste or a user-owned dataset. Until supplied, block climate-bearing METr export. Never synthesize them from the EPW |

## Non-goals

No map tiles in the first scope. No bundled, mirrored or redistributed climate catalog or EPW.
No certification claim. No hourly simulation or retention of hourly weather in the model. No
synthetic peak-load cases.

## Dependencies

The libraries packet, for the optional provider seam. Units, for radiation and elevation rows.
honeybee-ph's existing `Site.from_epw()` conversion. The peak-load input and readiness UI are part
of this packet under confirmed D9.

## Acceptance shape

On a synthetic model: load a synthetic monthly climate file, choose it, save and reopen with the
file removed, confirm the snapshot reads in full, change the site and see the distance update,
export and find `Site` in HBJSON. Separately select a synthetic annual EPW, prove the monthly
values and provenance match honeybee-ph's direct converter output, verify multiple/absent ground
temperature handling, remove the EPW and reopen offline, and prove that missing peak loads block
only the climate-bearing METr export with a specific repair route. Supply synthetic peak loads by
one of D9's permitted routes and find the complete monthly and peak arrays in METr JSON.

## Prior art and evidence

- Predecessor `planning/phases/C1_climate-data.md`.
- honeybee-ph `honeybee_ph/site.py`.
- honeybee-ph `honeybee_ph/_epw.py`, `docs/epw-preliminary-climate.md`, and decision 0004.
- PHX `model/phx_site.py`, `to_METr_JSON/metr_schemas.py`.
- Ladybug Tools EPW Map: https://www.ladybug.tools/epwmap/
