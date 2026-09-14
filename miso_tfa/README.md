# MISO-TFA independent project

This folder is the consolidated user-facing MISO/SISO TFA project. It is
designed to run independently of the parent repository's legacy workflows.

Start from a clean MATLAB session:

```matlab
project = setup;
connectedData = connectData("/path/to/recording.xlsx");
misoResults = misoTesting(connectedData);
sisoResults = sisoTesting(connectedData);
```

The public interfaces are:

1. `connectData` loads one recording and returns canonical signals.
2. `misoTesting` runs the two-input MAP/CO2 model.
3. `sisoTesting` runs the MAP-only and CO2-only models.
4. `ncBootstrap` runs blocked NC validation and subject bootstrap.
5. `simulationSettings` creates the reviewed simulation design.
6. `runSimulation` executes the known-truth simulation and optional export.

The active project uses a fixed 4 Hz sampling rate and a physiological
reporting band ending at 0.35 Hz. The Nyquist frequency is 2 Hz; frequencies
above the reporting band are not part of the primary physiological analysis.

Simulation, real-data analysis, and NC validation share the numerical modules
under `modules/`, but their settings and results remain separate. Generated
files belong under `output/` and are not source code.

Run the independent test set with:

```matlab
project = setup;
results = runtests(project.tests);
table(results)
```

The factor table, estimands, calibration-band decision, provenance labels, and
final protocol will be added to `config/` and `docs/` before the final study
run. The current parent-level files are migration sources and are not required
by this project.
