# Equipment

Author the mechanical and electrical equipment a Phius model needs and say which Zones each item
serves. Seven families, one packet, interviewed and delivered one family at a time. New work:
the predecessor held this as two discovery briefs, Q1 and B4.

## Read order

1. [PRD.md](PRD.md): the shared shape every family follows, then one section per family with its
   honeybee-ph class and fields, then the decisions.
2. [STATUS.md](STATUS.md).

## Family map

The accepted [definition/context ownership pattern](../../../archive/code-review-refactoring/ZONE_CHILD_PATTERN.md)
guides this future feature. Equipment that serves Zones can use an explicit assignment relationship;
it need not be a native child Group. Reusable equipment values remain independent, and a higher-level
service composes assignment/copy/delete through owner contracts. Shared-system copy policy remains
for the equipment interview; this reference authorizes no implementation or product-policy change.

| # | Family | honeybee-ph carrier | Unlocks |
| --- | --- | --- | --- |
| 1 | Ventilators | `Ventilator` in a `PhVentilationSystem` | ERV ducting, the by-ventilator airflow balance in Spaces |
| 2 | Hot water: tanks and heaters | `PhHotWaterSystem`, `PhHvacHotWaterTank`, `PhHvacHotWaterHeater` variants | Hot water piping |
| 3 | Heat pumps | `PhHeatPumpSystem` variants with cooling parameters | |
| 4 | Electric heaters | `PhHeatingDirectElectric` | |
| 5 | Pumps | `PhSupportiveDevice` types 4, 6, 7 | |
| 6 | Fans | Exhaust ventilators or `PhSupportiveDevice` type 10. Open, see Q6 | |
| 7 | Appliances | `PhEquipment` family on the Room's electric equipment load | |

The order is a proposal. Families 1 and 2 go first because two other packets wait on them.

## Scope

In: a record per equipment item, assignment to Zones, an Equipment subtab under Systems with one
family view at a time, validation, export.

Out: data sheet hosting, specification status, procurement tracking, equipment sizing, load
calculations, schedules.
