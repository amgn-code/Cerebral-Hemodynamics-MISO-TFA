# Interfaces and shared modules

The interface layer is the user-facing boundary. It assembles settings and
calls the reusable modules under `src`.

## Real data

```matlab
connectedData = connectTfaData("/path/to/recording.xlsx");
miso = runMisoRealData(connectedData);
siso = runSisoRealData(connectedData);
```

The platform pages `misoTesting` and `sisoTesting` add one model-specific
frequency table and one compact gain, phase, and coherence figure. This
keeps descriptive real-data output separate from the numerical runners.

For a combined run with separate settings:

```matlab
settings = defaultRealDataInterfaceSettings();
settings.miso.misoSolver = defaultMisoSolverSettings();
results = runMisoSisoRealData(connectedData, settings);
```

The older combined descriptive export remains available during cleanup:

```matlab
exportResults = exportRealDataResults( ...
    results, "/path/to/real_data_report");
```

The report includes model gains, SISO/MISO coherence quantities, and the
frequency-wise MISO coherence diagnostics. It does not calculate a
truth-based model advantage for observed data.

## Simulation

```matlab
settings = defaultSimulationInterfaceSettings("simple");
simulationResults = runSimulationInterface(settings);
```

`runSimulationInterface` is the numerical boundary: it passes its nested
settings to the known-truth runner and does not connect real-data files.
The platform page `runSimulation` adds the five primary frequency maps and
can export them with their source tables and reproducibility record:

```matlab
settings = simulationSettings("simple");
outputSettings = defaultSimulationOutputSettings("off");
outputSettings.outputFolder = "/path/to/simulation_output";
results = runSimulation(settings, outputSettings);
```

`createSimulationOutputs` builds the maps and
`exportSimulationResults` writes PNG figures, CSV source data, a compact
manifest, and a MAT archive containing the complete settings and numerical
results. These reusable modules live in `src`; the simulation page no
longer depends on the approach-paper reporting folder.

## NC bootstrap

```matlab
settings = defaultNcBootstrapSettings();
results = ncBootstrap("/path/to/ieem_data", settings);
exportResults = exportNcBootstrapResults( ...
    results, "/path/to/nc_bootstrap_report");
```

The export includes the advantage figure, frequency summary, subject status,
subject-by-frequency errors, and a MAT archive.
