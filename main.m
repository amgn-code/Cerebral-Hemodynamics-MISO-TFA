%% Clean Start

clearvars; clc; close all;

projectRoot = fileparts(mfilename("fullpath"));
addpath(genpath(fullfile(projectRoot, "src")));
addpath(genpath(fullfile(projectRoot, "studies", "approachPaper")));

%% 1. Run Mode

runType = "simulation";    % "single", "batch", "demo", or "simulation"
runType = lower(convertCharsToStrings(runType));

%% 2. Input Data

% Single-subject input
subjectInfo.subjectID = "105";
subjectInfo.group = "MCI";
subjectInfo.sourceFile = ...
    "/Users/amoghn/Downloads/ieem_data/MCI/105_baseline.xlsx";

% Batch input
batchSettings.dataFolder = "/Users/amoghn/Downloads/ieem_data";
batchSettings.groupsToRun = ["NC"; "MCI"];   % Example: ["MCI"; "NC"; "LC"]
batchSettings.targetSuccessfulSubjectsPerGroup = Inf;
batchSettings.previewOnly = false;

%% 3. Paper 1 Simulation

% "quick" checks execution and figure layout; "paper" runs the final study.
simulationProfile = "quick";    % "quick" or "paper"
simulationProfile = lower(convertCharsToStrings(simulationProfile));

% Save all simulation results and exports under this folder.
simulationOutputFolder = ...
    "/Users/amoghn/Desktop/IEEM Dr. Zhang/Approach Paper/Paper 1 Results Quick v6";

% Load the Paper 1 defaults; the data folder is unused if empirical analysis is off.
paperSettings = approachPaperSettings( ...
    batchSettings.dataFolder, simulationOutputFolder, ...
    simulationProfile);

% Select the Paper 1 stages and outputs.
paperSettings.steps.runEmpiricalAnalysis = false;      % Analyze real NC recordings
paperSettings.steps.runKnownTruthSimulation = true;    % Run the family-based simulation
paperSettings.steps.runRobustnessAnalysis = false;     % Run NC robustness checks; requires empirical analysis
paperSettings.steps.createTables = true;               % Export summary CSV and Excel tables
paperSettings.steps.createFigures = true;              % Export the organized plot library

% Select figure export formats.
paperSettings.export.savePdf = true;                   % Save PDF figures
paperSettings.export.savePng = false;                  % Save PNG figures
paperSettings.export.saveFigureSourceData = true;      % Save CSV values used to draw each plot

simulationSettings = paperSettings.simulation;

% Every family receives all listed durations, noise levels, and alignments.
if simulationProfile == "quick"
    simulationSettings.families.numFamilies = 8;
    simulationSettings.observations.durationSeconds = [256 300 320 896];
    simulationSettings.observations.outputSnrDb = [Inf 15 0];   % CBFV SNR; Inf adds no noise
    simulationSettings.observations.inputNoiseSnrDb = [Inf 15 0]; % Separate MAP and PETCO2 noise sweeps
    simulationSettings.observations.alignmentErrorSeconds = [-3 0 3]; % Negative shifts PETCO2 later
else   % "paper"
    simulationSettings.families.numFamilies = 1000;
    simulationSettings.observations.durationSeconds = ...
        [256 300 320 384 512 640 896];
    simulationSettings.observations.outputSnrDb = ...
        [Inf 30 20 15 10 5 0];                       % CBFV SNR; Inf adds no noise
    simulationSettings.observations.inputNoiseSnrDb = ...
        [Inf 30 20 15 10 5 0];                       % Separate MAP and PETCO2 noise sweeps
    simulationSettings.observations.alignmentErrorSeconds = ...
        [-6 -3 0 3 6];                               % Negative shifts PETCO2 later
end

% These balanced values describe physiology and stay fixed within a family.
simulationSettings.families.targetCoherenceValues = 0.05:0.10:0.95;
simulationSettings.families.spectralSimilarityValues = 0:0.20:1;
simulationSettings.families.petco2ToMapFluctuationSdRatioValues = ...
    [0.05 0.10 0.25 0.50 1 2];
simulationSettings.families.petco2ToMapBandGainRatioValues = ...
    [0.10 0.25 0.50 1 2 4];
simulationSettings.families.co2DelaySecondsValues = [0 2 4 6 8 10];

% Non-duration experiments use this standard duration and state it in their titles.
simulationSettings.observations.referenceDurationSeconds = 300;
simulationSettings.observations.referenceOutputSnrDb = 15;
simulationSettings.observations.runInputNoiseExperiment = true;  % Run separate MAP and PETCO2 noise sweeps
simulationSettings.observations.runAlignmentExperiment = true;   % Run PETCO2 timing-error sweep

simulationSettings.estimators.ridgeLambdas = [0.001 0.01 0.1];   % Sensitivity only; direct MISO stays primary

% Focused estimator checks at the reference observation.
simulationSettings.estimatorSensitivity.windowLengthSeconds = ...
    [64 75 100 128 150];                                        % Welch window sensitivity
simulationSettings.estimatorSensitivity.windowOverlap = ...
    [0.25 0.50 0.75];                                           % Welch overlap sensitivity

% Statistical markers compare paired MISO and SISO errors across families.
simulationSettings.statistics.alpha = 0.05;
simulationSettings.statistics.minimumValidN = 3;

%% 4. Models

analysisSettings.runMISO = true;
analysisSettings.runSISO = true;

% The direct MISO solution remains the default. Standardized ridge is an
% explicit optional analysis and is never turned on automatically.
analysisSettings.misoSolver = defaultMisoSolverSettings();

% Set true only when later surrogate or sensitivity analyses need the
% preprocessed subject signals and shared spectra.
analysisSettings.retainAnalysisInput = false;

%% 5. Frequency Configuration

% Results and figures are limited to this frequency range.
analysisSettings.frequencyRangeHz = [0 0.35];

% Frequency bands are the intervals between consecutive edges.
% The final band includes its upper edge.
analysisSettings.frequencyBandEdgesHz = ...
    [0.005; 0.024; 0.070; 0.200; 0.350];
analysisSettings.frequencyBandNames = ["VVLF"; "VLF"; "LF"; "HF"];

% Use this same frequency configuration throughout the Paper 1 workflow.
paperSettings.analysis.frequencyRangeHz = ...
    analysisSettings.frequencyRangeHz;
paperSettings.analysis.frequencyBandEdgesHz = ...
    analysisSettings.frequencyBandEdgesHz;
paperSettings.analysis.frequencyBandNames = ...
    analysisSettings.frequencyBandNames;
simulationSettings.frequencyRangeHz = ...
    analysisSettings.frequencyRangeHz;
simulationSettings.frequencyBandEdgesHz = ...
    analysisSettings.frequencyBandEdgesHz;
simulationSettings.frequencyBandNames = ...
    analysisSettings.frequencyBandNames;
paperSettings.simulation = simulationSettings;

%% 6. Preprocessing

analysisSettings.fsTarget = 4;
analysisSettings.preprocessing.normalizeCbv = true;
analysisSettings.preprocessing.detrendEnabled = false;
analysisSettings.preprocessing.detrendOrder = 1;
analysisSettings.preprocessing.meanRemovalEnabled = true;

%% 7. Welch Spectral Analysis

analysisSettings.pwelch.windowLengthSeconds = 128;
analysisSettings.pwelch.windowOverlap = 0.5;
analysisSettings.pwelch.minimumWindows = 3;
% Apply the same frequency-domain smoothing to every auto- and cross-spectrum.
analysisSettings.pwelch.smoothingEnabled = true;
analysisSettings.pwelch.smoothingKernel = [0.25 0.50 0.25];

%% 8. Phase

analysisSettings.phase.unwrapMethod = "standard";    % "standard" or "custom"
analysisSettings.phase.custom.windowSize = 11;
analysisSettings.phase.custom.numPasses = 3;
analysisSettings.phase.custom.useCoherenceWeights = true;
analysisSettings.phase.custom.weightMode = "power";
analysisSettings.phase.custom.weightPower = 4;
analysisSettings.phase.custom.expAlpha = 4;
analysisSettings.phase.custom.minWeight = 0.01;

%% 9. Statistical Analysis

analysisSettings.statistics.enabled = true;
analysisSettings.statistics.alpha = 0.05;
analysisSettings.statistics.numPhasePermutations = 10000;
analysisSettings.statistics.randomSeed = 2026;
% Statistical group order follows the batch group order selected above.
analysisSettings.statistics.groupsToCompare = batchSettings.groupsToRun;
analysisSettings.statistics.primaryBandNames = ["VVLF"; "VLF"; "LF"; "HF"];
analysisSettings.statistics.primaryGroups = batchSettings.groupsToRun;
analysisSettings.statistics.primaryPathways = ["MAP"; "CO2"];
analysisSettings.statistics.secondaryPathways = strings(0, 1);
analysisSettings.statistics.withinGroupModelComparison.enabled = true;
analysisSettings.statistics.betweenGroupComparison.enabled = true;
% Optional standardized file with one row per subject and SubjectID/Group.
analysisSettings.statistics.participantDataFile = "";

% Frequency-wise tests are exploratory. Each enabled metric gets an
% adjusted P-value curve across the configured frequency range.
analysisSettings.statistics.frequencyWise.enabled = true;
analysisSettings.statistics.frequencyWise.groupComparison.gain = true;
analysisSettings.statistics.frequencyWise.groupComparison.coherence = true;
analysisSettings.statistics.frequencyWise.groupComparison.phase = true;
analysisSettings.statistics.frequencyWise.modelComparison.gain = true;
analysisSettings.statistics.frequencyWise.modelComparison.phase = true;

%% 10. Figures

analysisSettings.plot = defaultPlotSettings();
analysisSettings.plot.transferFunctionStyle = "stem";    % "stem" or "line"
analysisSettings.plot.colors.co2Coherence = [0.9290 0.4940 0.1250];
analysisSettings.plot.showSisoCoherenceReference = true;

% Each Boolean controls one complete figure.
analysisSettings.plot.show.overview = true;
analysisSettings.plot.show.miso.map = true;
analysisSettings.plot.show.miso.co2 = true;
analysisSettings.plot.show.siso.map = true;
analysisSettings.plot.show.siso.co2 = true;
analysisSettings.plot.show.misoPartitioned.map = true;
analysisSettings.plot.show.misoPartitioned.co2 = true;
analysisSettings.plot.show.sisoPartitioned.map = true;
analysisSettings.plot.show.sisoPartitioned.co2 = true;

% Statistical figures use the same subject band values as the tests.
analysisSettings.plot.show.statistics.modelComparison = true;
analysisSettings.plot.show.statistics.groupComparison = true;
analysisSettings.plot.show.statistics.pathwayBalance = true;
analysisSettings.plot.show.statistics.inputAssociation = true;
analysisSettings.plot.show.statistics.frequencyWiseComparison = true;

outputSettings.saveSubjectFigures = true;
batchSettings.numSubjectFiguresPerGroup = 1;    % Number, "none", or "all"
outputSettings.saveBatchFigures = true;

%% 11. Excel Export

outputSettings.baseOutputFolder = ...
    "/Users/amoghn/Desktop/TFA Results New Latest Boss 1";
outputSettings.saveExcel = true;
outputSettings.excelFileName = "tfa_results.xlsx";
outputSettings.excelStatistics = true;

% Signal and input metrics shared by MISO and SISO
outputSettings.excelMetrics.signals.mapPower = true;
outputSettings.excelMetrics.signals.co2Power = true;
outputSettings.excelMetrics.signals.cbvPower = true;
outputSettings.excelMetrics.inputs.coherence = true;
outputSettings.excelMetrics.inputs.phaseWrapped = true;
outputSettings.excelMetrics.inputs.phaseUnwrapped = true;

% MISO metrics
outputSettings.excelMetrics.miso.mapGain = true;
outputSettings.excelMetrics.miso.mapPhaseWrapped = true;
outputSettings.excelMetrics.miso.mapPhaseUnwrapped = true;
outputSettings.excelMetrics.miso.co2Gain = true;
outputSettings.excelMetrics.miso.co2PhaseWrapped = true;
outputSettings.excelMetrics.miso.co2PhaseUnwrapped = true;
outputSettings.excelMetrics.miso.multipleCoherence = true;
outputSettings.excelMetrics.miso.mapPartialCoherence = true;
outputSettings.excelMetrics.miso.co2PartialCoherence = true;
outputSettings.excelMetrics.miso.unexplainedFraction = true;
outputSettings.excelMetrics.miso.residualPower = true;
outputSettings.excelMetrics.miso.conditionNumber = true;

% SISO metrics
outputSettings.excelMetrics.siso.mapGain = true;
outputSettings.excelMetrics.siso.mapPhaseWrapped = true;
outputSettings.excelMetrics.siso.mapPhaseUnwrapped = true;
outputSettings.excelMetrics.siso.mapCoherence = true;
outputSettings.excelMetrics.siso.mapUnexplainedFraction = true;
outputSettings.excelMetrics.siso.mapResidualPower = true;
outputSettings.excelMetrics.siso.co2Gain = true;
outputSettings.excelMetrics.siso.co2PhaseWrapped = true;
outputSettings.excelMetrics.siso.co2PhaseUnwrapped = true;
outputSettings.excelMetrics.siso.co2Coherence = true;
outputSettings.excelMetrics.siso.co2UnexplainedFraction = true;
outputSettings.excelMetrics.siso.co2ResidualPower = true;

%% Run Selected Workflow

if runType == "simulation"
    paperSettings.analysis.pwelch = analysisSettings.pwelch;
    paperSettings.analysis.phase = analysisSettings.phase;
    simulationSettings.welch = analysisSettings.pwelch;
    simulationSettings.phase = analysisSettings.phase;
    paperSettings.simulation = simulationSettings;
    fprintf( ...
        "\nRun type: simulation | Profile: %s | Families: %d\n\n", ...
        simulationProfile, simulationSettings.families.numFamilies);
    runResults = runApproachPaper(paperSettings);
else
    fprintf("\nRun type: %s | MISO: %s | SISO: %s\n", ...
        runType, string(analysisSettings.runMISO), ...
        string(analysisSettings.runSISO));
    fprintf( ...
        "Frequency range: %.3f-%.3f Hz | Welch window: %.1f s\n\n", ...
        analysisSettings.frequencyRangeHz(1), ...
        analysisSettings.frequencyRangeHz(2), ...
        analysisSettings.pwelch.windowLengthSeconds);

    runResults = runTFA( ...
        runType, subjectInfo, batchSettings, ...
        analysisSettings, outputSettings);
end

if isfield(runResults, "previewTable")
    disp(runResults.previewTable)
end
