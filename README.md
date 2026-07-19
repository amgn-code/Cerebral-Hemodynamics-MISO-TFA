# Cerebral Hemodynamics Transfer Function Analysis

This MATLAB project analyzes the frequency-domain relationships between mean
arterial pressure (MAP), end-tidal CO2, and cerebral blood flow
velocity/CBV. It supports both:

- MISO analysis: MAP and CO2 are solved together as inputs to CBV.
- SISO analysis: MAP-to-CBV and CO2-to-CBV are solved independently.

The project can analyze one subject, a batch of subjects, or a generated
test signal.

## Analysis Models

At each frequency, the MISO model is:

```matlab
S_xx = [S_mapmap, S_mapco2;
        S_co2map, S_co2co2];

S_xy = [S_mapcbv;
        S_co2cbv];

H = S_xx \ S_xy;
```

The two transfer functions are:

```matlab
H_mapcbv = H(1);
H_co2cbv = H(2);
```

The current MISO solve intentionally uses the direct spectral-matrix
solution without regularization or SISO fallback logic. The condition
number is stored as a diagnostic so alternative solving methods can be
evaluated later.

The SISO transfer functions are:

```matlab
H_mapcbv = S_mapcbv ./ S_mapmap;
H_co2cbv = S_co2cbv ./ S_co2co2;
```

## Project Flow

```text
main.m
├── single
│   └── loadData → runSubjectTFA
├── batch
│   └── findIEEMSubjects → runBatchTFA
│       └── runSingleSubjectTFA for each subject
└── test
    └── createTestSignal → runSubjectTFA
```

`runSubjectTFA` performs the common subject workflow:

1. Preprocess the time-series arrays.
2. Check the available Welch windows.
3. Run MISO analysis.
4. Optionally run SISO analysis.
5. Calculate frequency-band averages.
6. Limit the returned results to the selected analysis range.
7. Create the selected subject figures.
8. Export the selected Excel results and figures.

Batch processing subsequently organizes successful subject results into
group arrays, means, and standard deviations. The same group structure is
used for plotting and Excel export.

## Data Loading and Preprocessing

`loadData` reads the required time, MAP, CO2, and CBV columns from an Excel
worksheet and stores each signal as a horizontal array:

```matlab
signalData.t
signalData.map
signalData.co2
signalData.cbv
```

`btbPreProcessing` then:

1. Removes samples containing nonfinite values.
2. Removes leading CO2 zeros and the initial transition region.
3. Resamples all signals to `analysisSettings.fsTarget`.
4. Optionally normalizes CBV to percent baseline.
5. Optionally detrends the signals.
6. Optionally removes each signal mean.

The processed arrays remain horizontal throughout the analysis.

## Spectral Analysis

MISO and SISO use the same Welch configuration:

- Window length: `analysisSettings.pwelch.windowLengthSeconds`
- Window overlap: `analysisSettings.pwelch.windowOverlap`
- Minimum accepted windows: `analysisSettings.pwelch.minimumWindows`
- FFT length: the Welch window length in samples
- Spectral smoothing: `[0.25, 0.5, 0.25]`

The models can be run independently or together:

```matlab
analysisSettings.runMISO = true;
analysisSettings.runSISO = true;
```

Only the smoothed power spectra are retained:

```matlab
results.map.power
results.co2.power
results.cbv.power
```

The reported frequency range is controlled by:

```matlab
analysisSettings.frequencyRangeHz
```

Frequency-band averages use:

```matlab
analysisSettings.frequencyBandEdgesHz
analysisSettings.frequencyBandNames
```

## Phase

Each transfer-function pathway stores:

```matlab
results.map.phase.wrapped
results.map.phase.unwrapped

results.co2.phase.wrapped
results.co2.phase.unwrapped
```

The input–input relationship stores the equivalent wrapped and unwrapped
MAP–CO2 phase arrays.

The phase method is selected in `main.m`:

```matlab
analysisSettings.phase.unwrapMethod = "standard";
```

Supported methods are:

- `"standard"`: MATLAB `unwrap`
- `"custom"`: the project-specific coherence-weighted unwrapping method

The selected method is stored once per model:

```matlab
misoResults.phaseUnwrapMethod
sisoResults.phaseUnwrapMethod
```

## Result Structures

### MISO

```text
misoResults
├── f
├── map
│   ├── power
│   ├── transferFunction
│   ├── gain
│   ├── phase.wrapped
│   ├── phase.unwrapped
│   └── coherence.partial
├── co2
│   ├── power
│   ├── transferFunction
│   ├── gain
│   ├── phase.wrapped
│   ├── phase.unwrapped
│   └── coherence.partial
├── cbv.power
├── system
│   ├── multipleCoherence
│   ├── unexplainedFraction
│   └── residualPower
├── inputRelationship
│   ├── coherence
│   ├── phase.wrapped
│   └── phase.unwrapped
├── diagnostics.conditionNumber
├── phaseUnwrapMethod
├── welchInfo
└── bandAverages
```

### SISO

```text
sisoResults
├── f
├── map
│   ├── power
│   ├── transferFunction
│   ├── gain
│   ├── phase.wrapped
│   ├── phase.unwrapped
│   ├── coherence.pairwise
│   ├── unexplainedFraction
│   └── residualPower
├── co2
│   └── equivalent CO2-to-CBV fields
├── cbv.power
├── inputRelationship
├── phaseUnwrapMethod
├── welchInfo
└── bandAverages
```

Partial and multiple coherence belong to the MISO model. Pairwise
input-output coherence belongs to the SISO model.

## Running the Project

Configure the project in `main.m`, then select:

```matlab
runType = "single";
runType = "batch";
runType = "test";
```

### Single

Set `subjectInfo` to one Excel file. The file is loaded and passed into the
common subject workflow.

### Batch

Set:

```matlab
batchSettings.dataFolder
batchSettings.groupsToRun
batchSettings.numSubjectsPerGroup
```

Each entry in `batchSettings.groupsToRun` is matched to a folder with that
name. For example, `["MCI"; "NC"; "LC"]` uses the `MCI`, `NC`, and `LC`
folders. Subject files use names such as:

```text
101_baseline.xlsx
```

Setting `batchSettings.previewOnly = true` loads and preprocesses each
subject and reports whether it contains enough Welch windows without
running the TFA models.

### Test

Test mode calls `createTestSignal`, which returns a deterministic horizontal
Sho-style signal. MAP contains components at 0.03, 0.10, and 0.30 Hz; CO2
contains components at 0.05, 0.11, and 0.40 Hz; and both inputs contain a
shared 0.08 Hz component. CBV is constructed with known pathway-specific
gains and phase shifts. Its raw CBV variation is scaled around a 50 cm/s
baseline so the stored Sho gains are recovered directly when the default
percent-baseline normalization is enabled. The test signal then runs through
the same preprocessing and analysis workflow used for a real subject.

## Plotting

Nine complete figure types can be selected in `main.m`:

1. Subject/group overview
2. MISO MAP pathway
3. MISO CO2 pathway
4. SISO MAP pathway
5. SISO CO2 pathway
6. Partitioned MISO MAP pathway
7. Partitioned MISO CO2 pathway
8. Partitioned SISO MAP pathway
9. Partitioned SISO CO2 pathway

Transfer-function gain and phase use stem plots by default. Spectra,
coherence, condition number, and group mean/SD results use line plots.

Partitioned figures use the frequency bands defined in `main.m`; the number
of rows changes automatically with the number of configured bands.

## Excel Output

Subject workbooks contain:

- `Status`
- `MISO_Full`
- `MISO_Bands`
- `SISO_Full` and `SISO_Bands` when SISO is enabled
- `MISO_vs_SISO` when SISO is enabled

Batch workbooks contain:

- `Run_Status`
- `Band_Averages`
- `Metric_Definitions`
- Full-frequency metric sheets prefixed with `FF_`
- Band-average metric sheets prefixed with `BA_`

Batch metric sheets contain subject columns followed by group mean and
standard-deviation columns.

## Repository Structure

```text
.
├── main.m
├── src
│   ├── analysis
│   ├── batch
│   ├── data_loaders
│   ├── io
│   ├── pipelines
│   ├── plotting
│   ├── preprocessing
│   ├── simulation_signals
│   └── workflows
└── tests
    └── helpers
```

Each MATLAB function has its own file.

## Requirements

The current dependency audit reports:

- MATLAB
- Signal Processing Toolbox
- Statistics and Machine Learning Toolbox

The project is currently tested with MATLAB R2025b.

## Tests

Run:

```matlab
results = runtests("tests");
```

The tests cover preprocessing, frequency-range limiting, MISO results, SISO
results, phase unwrapping, and band averages. Test mode, plotting, Excel
export, subject discovery, preview, and batch aggregation are also used as
integration smoke checks during development.

This project is under active development and is intended for research and
validation use.
