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

The primary simulation factor schema contains MAP-CO2 input coherence,
MAP-CO2 input phase lag, relative CO2 pathway strength, recording duration,
CBFV output SNR, MAP measurement SNR, and CO2 measurement SNR. CO2 timing
misalignment is a secondary robustness condition. Each level carries a
provenance label in `config/simulationFactors.m`; provisional levels must be
confirmed against NC data or cited physiology before the final paper run.

The 4 Hz sampling rate gives a 2 Hz Nyquist frequency. The primary reporting
band ends at 0.35 Hz. The simulation stores a separate pathway-calibration
band so changing the displayed band cannot change the generated pathway truth.
The primary workflow uses the unregularized MISO solution; ridge sensitivity is
not part of the simplified study.

NC validation performs acquisition cleanup before splitting the record, then
fits centering and CBV conditioning from the training blocks and applies those
parameters to the held-out block. Frequencies above each recording's native
usable Nyquist frequency are masked and reported in the subject status table.

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

Saved simulation archives can be replayed without rebuilding settings by
calling `replaySimulation("/path/to/simulation_results.mat")`. The replay
function uses the saved interface settings and manifest rather than today's
defaults.
