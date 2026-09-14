# MISO-TFA platform

This folder is the clean user-facing platform layer. It defines the small
interfaces users call and keeps the existing tested MATLAB implementation as
the initial computational backend.

Run this once at the beginning of a MATLAB session:

```matlab
setupPlatform
```

The public pages are intentionally small:

```matlab
connectedData = connectData("/path/to/recording.xlsx");
misoResults = misoTesting(connectedData);
sisoResults = sisoTesting(connectedData);

simulationSettings = simulationSettings("simple");
simulationResults = runSimulation(simulationSettings);
```

The six planned pages are:

1. `connectData` loads one recording and returns canonical signals and
   metadata.
2. `misoTesting` runs the MISO model on connected data.
3. `sisoTesting` runs the SISO models on connected data.
4. `ncBootstrap` runs the NC subject bootstrap with blocked temporal
   validation and returns the frequency-wise MISO advantage.
5. `simulationSettings` creates the editable simulation design.
6. `runSimulation` executes that design.

Figures and tables are outputs of the relevant analysis page. Data
connection has no plotting responsibility. The existing functions under
`src` remain the backend modules during this transition; the platform pages
are the stable user-facing boundary.

Each model page returns one compact frequency table and one three-panel
figure containing gain, phase in degrees, and coherence. The MISO table also
retains the MAP-CO2 input coherence and phase because those quantities help
interpret a two-input fit. The pages do not calculate model advantage;
truth-based advantage belongs to simulation and held-out advantage belongs
to the NC bootstrap page.

Figures are visible by default. For scripted or headless use:

```matlab
displaySettings = defaultRealDataDisplaySettings("off");
misoResults = misoTesting( ...
    connectedData, defaultMisoRealDataSettings(), displaySettings);
```

## NC bootstrap protocol

The NC page uses the inspected NC folder structure and a fixed, reproducible
protocol:

- one subject/file is the population bootstrap unit;
- each recording is divided into three contiguous 90-second blocks;
- each fold trains on two blocks and holds out the third;
- the Welch window is 90 seconds with zero overlap, so the training data
  contain two non-overlapping spectral segments;
- held-out normalized prediction error is computed by frequency; and
- advantage is `log10(mean SISO error / mean MISO error)`.

The primary plot shows advantage only. The returned frequency table retains
the SISO and MISO error means, their standard deviations, bootstrap standard
deviation, confidence interval, and valid subject count. Subject-level fold
errors and the status table remain available for audit and troubleshooting.

Export the completed result with:

```matlab
exportResults = exportNcBootstrapResults( ...
    results, "/path/to/nc_bootstrap_report");
```

The export includes the advantage figure, frequency summary, subject status,
subject-by-frequency errors, and a MAT archive.
