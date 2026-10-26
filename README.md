# Cerebral hemodynamics MISO and SISO analysis

Analyze MAP→CBFV and end-tidal CO₂→CBFV pathways in resting recordings, or compare their recovery in a known-truth simulation.

**Start with [miso_tfa/runAnalysis.m](miso_tfa/runAnalysis.m).** It contains all user settings. There are no backend settings files or named presets. The verified environment is MATLAB R2025b with Signal Processing Toolbox.

## Run a simulation

Open `runAnalysis.m`, edit its sections, and press **Run**. Alternatively:

```matlab
addpath("miso_tfa");
results = runAnalysis();
```

The default runs 50 random recordings per condition. It varies coherence, CO₂ fluctuation size, CO₂ pathway gain, duration, and output noise around an editable reference. Gain and phase advantage are separate figures. These defaults are for exploration; use the reported Monte Carlo uncertainty to choose a study repetition count. The earlier production study used 500.

To configure a run without editing the file:

```matlab
settings = runAnalysis("settings");
settings.simulation.repetitions = 500;
settings.simulation.vary = ["inputCoherence", "co2GainRatio"];
settings.simulation.ranges.inputCoherence = [0 0.15 0.5 0.95];
results = runAnalysis(settings);
```

`"oneAtATime"` changes one condition from the reference. `"factorial"` crosses selected ranges, including reference values. Every combination is retained separately. Advantage figures show reference slices; the CSV/MAT results contain all combinations for interaction analysis.

## Analyze your recordings

One file represents one recording. Use numeric columns containing time in seconds, MAP and end-tidal CO₂ in mmHg, and CBFV in cm/s. CSV and Excel are supported. Timestamps must increase strictly. Short missing intervals may be interpolated; the maximum allowed gap is explicit.

```matlab
settings = runAnalysis("settings");
settings.mode = "data";
settings.data.paths = "/path/to/recordings"; % File(s) or folder(s)
settings.data.columnMap.t = "Time";
settings.data.columnMap.map = "MAP";
settings.data.columnMap.co2 = "PETCO2";
settings.data.columnMap.cbv = "CBFV";
results = runAnalysis(settings);
```

Empty mappings recognize common headings, including IEEM exports. Set `data.sheet` for an Excel worksheet. Time and signal conversion multipliers are beside the mappings.

For multiple groups:

```matlab
settings.data.paths = "/path/to/groups";
settings.data.recursive = true;
settings.data.groupBySubfolder = true;
```

The immediate parent folder names the group; the filename names the recording. Use unique filenames within each group. Summaries are descriptive; this workflow does not perform clinical group hypothesis tests. Imported data retain CO₂ startup cleanup; generated inputs bypass acquisition cleanup.

## Choose the figures

Both input routes have these figure types:

| Figure | Contents |
| --- | --- |
| Pathways | SISO/MISO gain and phase, ordinary/partial coherence, and band-limited impulse responses for both pathways |
| Coherence | Joint MISO multiple coherence and MAP–CO₂ input coherence |
| Differences | MISO-minus-SISO gain and shortest angular phase differences |

Set `plots.individuals`, `plots.averages`, and `plots.showStandardDeviation` independently. Phase means and SD are circular. Shading describes spread across recordings, not uncertainty of the mean. Phase display can be wrapped or unwrapped.

For simulation, `plots.simulationConditionIDs = 1` selects the reference for descriptive figures. Use IDs from `results.simulation.conditions`, or `[]` for all conditions. Simulation individuals are replicate recordings, not calibrated patients.

Simulation also explains the inputs, CBFV contributions, spectra, and generating pathways in a figure. Each selected factor and metric gets an advantage figure with panels for both pathways. Append `"complex"` to `simulation.metrics` if wanted. There are no absolute-error figures or MAP→CO₂ transfer functions.

## Follow the code

```text
runAnalysis.m                     all user-editable settings
  └─ runTfaPipeline
       ├─ data: readTfaRecordings → preprocessTfaSignals
       ├─ simulation: createSimulationConditions
       │                → generateKnownTruthRealization → observeSimulation
       └─ analyzeTfaRecording
            → estimateWelchSpectra → estimateTransferFunctions
            → calculateImpulseResponse
          summarizeTfaRecordings / summarizeAdvantage
          plotTfaResults / plotSimulationResults
          saveTfaResults
```

Files in `miso_tfa/src` correspond to scientific operations:

| Operation | Files |
| --- | --- |
| Import/preparation | `readTfaRecordings`, `loadSubjectData`, `preprocessTfaSignals`, `alignCo2ByDelay` |
| Inputs | `generateKnownTruthRealization`, `createKnownTruthInputSpectra` |
| Known pathways | `createMapAutoregulationKernel`, `createExponentialPathwayKernel`, `scalePathwayToBandGainRatio`, `calculatePetco2ContributionPowerShare` |
| Spectra/fitting | `analyzeTfaRecording`, `estimateWelchSpectra`, `getWelchWindowSettings`, `estimateTransferFunctions`, `calculateMisoCoherenceDiagnostics` |
| Impulses | `calculateImpulseResponse` |
| Conditions/accuracy | `createSimulationConditions`, `simulateTfaStudy`, `observeSimulation`, `calculateFrequencyTruthErrors`, `summarizeAdvantage` |
| Summaries/figures | `summarizeTfaRecordings`, `plotTfaResults`, `plotSimulationResults` |
| Checks/saving | `validateTfaSettings`, `saveTfaResults` |

[METHODS.md](miso_tfa/docs/METHODS.md) explains the generator, equations, units, evidence, and interpretation limits.

## Saved results and reproduction

A run can save one `results.mat`, CSV tables, and selected PNGs. The MAT file contains actual settings, seeds, conditions, truth, individual estimates, summaries, and uncertainty. Figure handles are excluded.

| CSV | Contents |
| --- | --- |
| `recordings.csv` | Individual estimates, coherence, differences, and available truth |
| `group_summaries.csv` | Group means, SD, and valid counts |
| `impulses.csv` | Individual/group impulses with lag in seconds |
| `conditions.csv` | Simulation conditions and reference identification |
| `advantage.csv` | Conditions, frequency, advantage, paired/invalid counts, and Monte Carlo uncertainty |

Reproduce a saved run:

```matlab
saved = load("/path/to/results.mat");
settings = saved.results.settings;
settings.output.folder = "/path/to/reproduced_run";
results = runAnalysis(settings);
```

Real-data reruns still require the original files. Recordings and generated outputs remain local and are ignored by Git.

## Verification and previous versions

```matlab
checks = runtests("miso_tfa/tests");
assert(all([checks.Passed]));
```

Tests cover spectral identities, circular phase, impulse units, condition design, reproducibility, mappings and units, groups, figures, and replay. The refactor was also compared directly with original generator and estimator outputs.

This revision passed 37 focused tests and MATLAB Code Analyzer with zero issues. The full default simulation completed 13 conditions, 650 recordings, and 14 figures. The real-data numerical pipeline also completed all 23 original NC recordings. Default generated signals matched the saved original exactly; estimator outputs agreed within 1e-12.

Previous interfaces, prediction validation, reports, manuscripts, and archived references remain on [matlab-baseline-2026-10-26](https://github.com/amgn-code/Cerebral-Hemodynamics-MISO-TFA/tree/matlab-baseline-2026-10-26). They are not duplicated in the current source tree.
