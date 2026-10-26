# MISO-TFA

`miso_tfa` is the complete, standalone MATLAB project. It does not require
the parent repository's `src`, `platform`, `studies`, or `model_generator`
folders.

Start MATLAB in this folder and run:

```matlab
project = setup;
```

## User workflows

### Analyze one recording

Connect the file once, then pass the same canonical data to either model:

```matlab
data = connectData("/path/to/recording.xlsx");
miso = misoTesting(data);
siso = sisoTesting(data);
```

`connectData` accepts Excel or CSV files and returns time, MAP, CO2, and CBFV
signals. It does not run a model or create a plot. `misoTesting` returns the
two-input result; `sisoTesting` returns the two separate single-input results.

Each model page returns a frequency table and a three-panel gain, phase, and
coherence figure. Export belongs to the model page:

```matlab
display = defaultRealDataDisplaySettings("off");
display.outputFolder = fullfile(pwd, "output", "my_recording");
miso = misoTesting(data, defaultMisoRealDataSettings(), display);
```

### Run the known-truth simulation

```matlab
settings = simulationSettings("simple");
results = runSimulation(settings);
```

The primary outputs are frequency-by-factor heatmaps of
`log10(mean SISO error / mean MISO error)`. Positive values favor MISO. The
reviewed protocol and all factor definitions are in
`docs/SIMULATION_PROTOCOL.md` and `config/simulationFactors.m`.

The frozen final design runs the core and the separate phase, input-noise,
alignment, and white-noise experiments without mixing their rows:

```matlab
output = defaultSimulationOutputSettings("off");
output.createFigures = false;
study = runFinalSimulationStudy(500, output);
exportFinalSimulationStudy(study, fullfile(pwd, "output", "final"));
```

Production uses 2,000 paired bootstrap draws and audits the predeclared 0.05
log10-unit Monte Carlo standard-error target. Use a smaller repetition count
only for a wiring check.

### Validate on the NC recordings

```matlab
results = ncBootstrap("/path/to/ieem_data");
```

This workflow trains on two blocks, predicts the held-out block, and reports
frequency-resolved MISO advantage with subject-bootstrap uncertainty. It is
an empirical validation workflow and does not claim known transfer-function
truth.

## Project layout

```text
miso_tfa/
├── setup.m           initialize paths
├── interfaces/       data, MISO, SISO, simulation, and NC entry points
├── config/           shared settings and factor definitions
├── modules/
│   ├── data/         recording import and synthetic input utilities
│   ├── preprocessing/  signal preparation and alignment
│   ├── tfa/          common analysis pipeline, Welch, SISO, MISO, and phase
│   ├── realData/     single-recording analysis, plots, and export
│   ├── simulation/   experiment runners, plots, replay, and export
│   │   └── knownTruth/  signal families, known pathways, and error measures
│   ├── ncValidation/  blocked validation, bootstrap, and NC characterization
│   └── reporting/    report and manuscript figure generation
├── manuscript/       current paper source, figures, and tables
├── buildManuscript.m  rebuild the current paper from saved results
├── tests/
├── examples/
├── docs/
└── output/           generated results and PDFs; ignored by Git
```

Simulation, NC validation, and real-data analysis all call the same
preprocessing, Welch, phase, SISO, and MISO functions. Their settings and
estimands remain separate because they answer different questions.

The project uses 4 Hz sampling, which gives a 2 Hz Nyquist frequency. Results
are cropped to the physiological reporting band of 0.02–0.35 Hz. The active
simulation compares unregularized MISO and SISO estimators; ridge is available
only inside the low-level solver for numerical diagnostics and is not a study
factor.

## Verification

From a clean MATLAB session:

```matlab
restoredefaultpath
cd("/path/to/miso_tfa")
setup;
results = runIndependentTests;
table(results)
checkIndependentDependencies()
```

The dependency audit must report zero parent-project files for every public
page. Saved exploratory simulations can be regenerated with
`replaySimulation("/path/to/simulation_results.mat")`.

See `examples/quick_start.m` for a compact script, `docs/WORKFLOW.md` for the
data flow, and `docs/CONSOLIDATION_RECORD.md` for the cleanup boundary.

## Read or rebuild the current paper

The current source is [manuscript/main.tex](manuscript/main.tex). Run
`buildManuscript` after `setup` to regenerate its assets from `output/final`
and compile `output/pdf/MISO_TFA_simulation_study_manuscript.pdf`.
The paper and its build now live entirely within this folder.

Older manuscripts, presentations, and review correspondence are retained under
the repository-level `archive/reference_material/` folder. Start here for the
active software and paper.
