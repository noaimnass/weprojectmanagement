# openproject-pilotage — WeProjectManagement steering module

Portfolio steering layer by WeWorld Tech (GPL v3): cockpit, PMO 360, master plan, workload, reporting compliance, registers, milestone reviews, status reports, project requests, organisation 360, governance, printable reports and the steering reference.

Functional guide (French): `docs/weprojectmanagement/PILOTAGE.md`.

## Layout

```
lib/open_project/pilotage/engine.rb     permissions, menus, settings
lib/open_project/pilotage/defaults.rb   non-reloadable defaults (categories, axes, life cycle keys, register kinds)
config/routes.rb                        /pilotage/*, /admin/pilotage, /projects/:project_id/pilotage/*
db/migrate                              pilotage_* tables
app/models/pilotage                     Entity, ProjectProfile, RegisterItem, MilestoneReview, StatusReport, ProjectRequest, Instance, Session, ProjectExtension
app/services/pilotage                   Classification, Lifecycle, Signals, PortfolioSummary, MasterPlan, Workload, DeviceIndicators, MySpace, ConvertRequestService, Exports::Csv, Imports::RegisterCsv
app/controllers/pilotage                one controller per page family (global pages use the "global" layout, project pages the project layout)
app/components/pilotage                 KpiTile, SignalBar, PageHeader, MasterPlan (SVG) + _pilotage.sass
app/views/pilotage                      server-rendered ERB with Primer components; layouts/pilotage/print for printable reports
app/helpers/pilotage_helper.rb          labels, money, dates, select options
config/locales/{en,fr}.yml              all texts, settings labels, permissions
lib/tasks/pilotage.rake                 seed_governance, enable_all, demo
spec/                                   factories and specs (run with the core spec helper)
```

## Conventions

- Health levels are `green`, `amber`, `red`; the computed health is the worst signal (`Pilotage::Signals`).
- Thresholds are expressed in budget units (`Setting.pilotage_budget_unit`, 1,000,000 by default) and configured in Administration › Steering.
- Register kinds and their JSON detail fields are declared in `Pilotage::RegisterItem::DETAIL_FIELDS`; adding a kind only requires a prefix, its fields and locale keys.
- Milestone keys follow `OpenProject::Pilotage::Defaults::LIFECYCLE_KEYS` (P0–P8); labels per category come from the `pilotage_lifecycle_labels` setting.

## Tests

```bash
bundle exec rspec modules/pilotage/spec
```
