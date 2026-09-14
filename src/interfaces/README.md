# Interfaces and shared modules

The interface layer is the user-facing boundary. It assembles settings and
calls the reusable modules under `src`.

## Real data

```matlab
connectedData = connectTfaData("/path/to/recording.xlsx");
miso = runMisoRealData(connectedData);
siso = runSisoRealData(connectedData);
```

For a combined run with separate settings:

```matlab
settings = defaultRealDataInterfaceSettings();
settings.miso.misoSolver = defaultMisoSolverSettings();
results = runMisoSisoRealData(connectedData, settings);
```

To create a compact descriptive frequency report after the analysis:

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

The simulation interface passes its nested settings to the known-truth
runner. It does not connect real-data files.

## NC bootstrap

```matlab
settings = defaultNcBootstrapSettings();
results = ncBootstrap("/path/to/ieem_data", settings);
exportResults = exportNcBootstrapResults( ...
    results, "/path/to/nc_bootstrap_report");
```

The export includes the advantage figure, frequency summary, subject status,
subject-by-frequency errors, and a MAT archive.
