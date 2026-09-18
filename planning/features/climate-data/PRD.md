# Climate data

DATE: 2026-09-18
STATUS: Requested. Post-MVP draft, not interviewed.
AUTHOR: Ed May, BLDGTYP, with Claude
ISSUE: none (no remote)

## Problem

METr needs a climate. If the export carries none, the consultant sets it in METr after every
export. If the export carries one, a variant study needs no manual step. The climate also feeds
two later views, the sun path and the window radiation overlay.

## Product boundary

`docs/PRD.md` currently lists "climate map" among the exclusions and scopes "Climate and site" as
"PV and the site data METr needs". A map-based picker contradicts the first line. Ed must lift
or narrow that exclusion before this packet is scoped. See Q1.

## Port disposition

| Part | Disposition | Note |
| --- | --- | --- |
| Predecessor C1 brief: site versus station, snapshot with provenance, offline reading, stale states | Port | No designPH dependency in any of it |
| C1's PHPP framing of the radiation data | Drop | The target is Phius and METr. The data shape is the same and is cited from honeybee-ph and PHX instead |
| C1's links into PH-Navigator web and the PHI rules repository | Drop | Both are private repositories |
| Record engine, unit fields | Port | From the foundation transplant |
| Library provider seam as the catalog source | New | See Q3 |

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

## Records

```
Model   gains  site { latitude_deg, longitude_deg, elevation_m, climate_zone }
               climate { name, station_elevation_m, daily_temp_swing_k, wind_speed_m_s,
                         monthly { air_c[12], dewpoint_c[12], sky_c[12], ground_c[12],
                                   rad_north_kwh_m2[12], east, south, west, global },
                         peak_loads { heat_1, heat_2, cool_1, cool_2 },
                         provenance { ...honeybee-ph ClimateProvenance fields } }
```

The snapshot is a copy. The model never needs the source again to be read or exported.

## Behaviors

- A Climate section shows the site, the chosen dataset, its source and its twelve-month table.
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
| Q1 | Lift the "climate map" exclusion in `docs/PRD.md`? | Narrow it: a list and search picker is in, a map is a later addition. The list needs no tile service and works offline |
| Q2 | Which dataset kinds? | Phius monthly climate sets only. EPW and PHI sets are out |
| Q3 | Where do datasets come from? | Through the library provider seam as a fifth record kind, `climates`. A file provider reads a folder of climate files; a connection provider reads a server. No catalog ships in the repository |
| Q4 | May any Phius climate data be redistributed? | Unknown. Ask Phius. Until answered, the user supplies the file, and the starter library carries none |
| Q5 | What sets the site location? | An explicit value in the Climate section, with a "Read from SketchUp geolocation" button. No silent sync in either direction |
| Q6 | Does the site location write back to SketchUp's geolocation and north? | No |
| Q7 | Manual entry of a full monthly table? | Yes, by paste from a spreadsheet. It keeps the no-provider workflow whole |

## Non-goals

No map tiles in the first scope. No bundled catalog. No certification claim. No hourly weather.

## Dependencies

The libraries packet, for the provider seam. Units, for radiation and elevation rows.

## Acceptance shape

On a synthetic model: load a synthetic climate file through the file provider, choose it, save
and reopen with the file removed, confirm the snapshot reads in full, change the site and see
the distance update, export and find `Site` in HBJSON and the monthly arrays in METr JSON.

## Prior art and evidence

- Predecessor `planning/phases/C1_climate-data.md`.
- honeybee-ph `honeybee_ph/site.py`.
- PHX `model/phx_site.py`, `to_METr_JSON/metr_schemas.py`.
