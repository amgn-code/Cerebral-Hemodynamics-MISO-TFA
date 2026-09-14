# User-facing TFA workflow

The user-facing workflow is a small interface layer around the shared TFA
modules. It is separate from the known-truth simulation study under
`studies/approachPaper`, but both workflows use the same preprocessing,
Welch spectra, SISO, MISO, and diagnostic functions. The public interface
functions are under `src/interfaces/realData`.

Connect one recording once, then run either model interface:

```matlab
filePath = "/path/to/recording.xlsx";
connectedData = connectTfaData(filePath);
miso = runMisoRealData(connectedData);
siso = runSisoRealData(connectedData);
```

Use `runMisoSisoRealData` when one result structure containing both model
families is more convenient. The Excel worksheet must contain a supported
time column and the MAP, CO2, and CBV columns recognized by
`loadSubjectData`. The returned structures contain preprocessing metadata,
retained analysis inputs, diagnostics, and the original file path.

MISO and SISO settings are separate:

```matlab
settings = defaultRealDataInterfaceSettings();
settings.miso.frequencyRangeHz = [0.02 0.35];
settings.siso.phase.unwrapMethod = "custom";
results = runMisoSisoRealData(connectedData, settings);
```

These interfaces do not write figures or workbooks. A later reporting
interface can consume the returned model structures. The compact report
interface is:

```matlab
exportResults = exportRealDataResults( ...
    results, "/path/to/real_data_report");
```

The simulation study does not call this function. Its purpose is to compare
known-truth SISO and MISO recovery under controlled paired observations.
