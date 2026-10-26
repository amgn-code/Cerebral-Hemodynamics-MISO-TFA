# Consolidation record

## Active boundary

`miso_tfa` is the complete runnable project. `setup.m` adds only folders below
this boundary. `tests/independentBoundaryTest.m` and
`checkIndependentDependencies` require every public entry point to resolve
zero MATLAB files from the parent repository.

## Consolidated structure

- `interfaces` contains the small user pages for file connection, MISO, SISO,
  exploratory simulation, NC validation, and tests.
- `modules/realData` owns single-recording loading, display, and export.
- `modules/tfa` and `modules/preprocessing` are the shared
  numerical core.
- `modules/simulation/knownTruth` owns known-truth accuracy engines.
- `modules/ncValidation` owns blocked NC validation and bootstrap.
- `modules/simulation` owns experiment orchestration, source tables, figures,
  replay, and production export.
- `modules/reporting/createFinalMisoTfaReport.m` is the only current PDF report
  builder for the study report. `buildManuscript.m` builds the current paper.

The unused combined descriptive MISO/SISO page was removed. Truth-error
advantage belongs to known-truth simulation; held-out prediction advantage
belongs to NC validation. Per-model export remains integrated with each
real-data page.

The earlier Step 2, Step 3, and Step 4 report builders and protocol notes were
retired after their useful decisions were incorporated into
`SIMULATION_PROTOCOL.md` and the final report. Historical code remains
recoverable from Git.

## Parent repository cleanup

The superseded parent `src`, `platform`, `studies`, legacy `tests`, and
`main.m` were removed in the preceding cleanup. The current paper is now
inside `miso_tfa`. Older manuscripts, cited source papers, presentations,
and review correspondence remain as research records; they are not active
MATLAB code and were not classified as dead code in this refactor.

## Readability refactor

The current manuscript is now in `miso_tfa/manuscript`, so rebuilding it no
longer requires a source folder in the parent repository. Shared phase and
analysis-pipeline functions are in `modules/tfa`; NC validation has its own
module; synthetic validation belongs to `modules/simulation/knownTruth`.

Removed `createBalancedFamilyLevels`: no code, test, or documented workflow
calls it. The active family design uses its existing pairwise-balanced method.
Kept `simulateIllustrativeNcProtocolScenario`: it is a documented scientific
entry point despite having no internal MATLAB caller.

Four one-caller bookkeeping helpers are now local functions in their owners:
`initializeSubjectRunStatus`, `initializeKnownTruthFrequencyResults`,
`calculateValidationPredictionError`, and `calculateBandAveragedGain`.
Their bodies are unchanged. Named physiological pathway functions remain
separate because they make the signal-generation model easier to inspect.

Verification for this refactor: the complete existing suite passed before and
after the changes (99 tests, zero failures or incomplete tests). MATLAB Code
Analyzer reports zero issues across the remaining 92 module files. The
independence audit now also covers the manuscript asset generator and build
entry point, and missing entry points cause an audit error instead of a
misleading empty dependency result.

The manuscript build also completed from its new internal source location and
produced the descriptive 20-page PDF. Frozen simulation and NC result files
were read for the build; the production study was not rerun.

## Archive boundary

The repository root now has one active software boundary and one explicit
archive boundary:

```text
Cerebral-Hemodynamics-MISO-TFA/
├── miso_tfa/                  active runnable project
├── archive/
│   ├── reference_material/    old docs, reviews, manuscripts, slides, data
│   ├── generated_outputs/     large or superseded generated files
│   └── scratch/               temporary render and editing work
├── README.md                  one entry point
└── .vscode/                   editor settings
```

The active project keeps the frozen CSV summaries and source tables required
to rebuild the manuscript. The large raw checkpoint, duplicate raw NC result,
illustrative scenario MAT file, and superseded final report PDF are preserved
under `archive/generated_outputs/` because they are not read by the active
workflow. The move is reversible and does not delete research history.
