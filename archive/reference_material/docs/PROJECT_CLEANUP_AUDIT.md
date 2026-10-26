# Project cleanup audit

This audit records the boundary between the active platform and the older
batch and approach-paper workflows. It is intentionally based on MATLAB's
`requiredFilesAndProducts` dependency analysis rather than on folder names.

## Active platform dependency set

The public pages under `platform/interfaces` have no dependency on
`studies/approachPaper` or `src/robustness`:

| Entry point | Required project files | Approach-paper dependencies | Robustness dependencies |
| --- | ---: | ---: | ---: |
| `connectData` | 4 | 0 | 0 |
| `misoTesting` | 30 | 0 | 0 |
| `sisoTesting` | 30 | 0 | 0 |
| `ncBootstrap` | 27 | 0 | 0 |
| `simulationSettings` | 4 | 0 | 0 |
| `runSimulation` | 58 | 0 | 0 |

The union of these entry-point dependency sets is 89 project MATLAB files.
The simulation page uses the shared validation and analysis modules directly;
it does not call the old approach-paper exporter.

## What remains intentionally retained

The repository contains 256 MATLAB files. The remaining files are not all
dead code:

| Subsystem | Current role | Evidence |
| --- | --- | --- |
| `src/workflow/runTFA` and `src/plotting` | Backward-compatible batch and legacy figure workflow | `runTFA` requires 67 project files, including 18 plotting and 10 statistics files |
| `src/workflow/userFacing` | Older file-based compatibility wrapper | It has a separate 28-file dependency set and is exercised by compatibility tests |
| `src/statistics` and `src/group` | Batch/group reporting backend | Required by the old batch path and its regression tests |
| `src/robustness` | Sensitivity, surrogate, lambda, and influence analyses | Required by the approach-paper robustness path and robustness tests |
| `studies/approachPaper` | Separate paper-study orchestration and historical output workflow | `runApproachPaper` requires 162 files and is covered by four approach-paper test classes |

The active platform is therefore cleanly separated, but the old study is not
safe to delete in this cleanup pass without also deleting its tests and its
documented paper workflow. That would remove a tested research subsystem, not
just unused clutter. Claude's final review can make that removal decision once
the scientific protocol and paper figures are settled.

## Safe cleanup completed

The duplicate simulation plotting and summary helpers were moved from the
approach-paper plotting folder into `src/interfaces/simulation` and
`src/validation`. CO2 alignment was moved into `src/preprocessing` and now
has one explicit zero-default correction setting. The active platform pages,
their source tables, manifests, and exports no longer reach back into the
approach-paper folder.

## Recommended deletion decision for the final review

Keep the legacy subsystem until the scientific review confirms that the new
platform outputs replace every paper figure and table that still matters.
Then remove the old workflow and its tests in one deliberate commit. Until
that decision, the dependency boundary documented here prevents legacy code
from obscuring how a normal user runs the platform.
