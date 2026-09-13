%% Cerebral Hemodynamics TFA Control Panel

clearvars; clc; close all;

projectRoot = fileparts(mfilename("fullpath"));
addpath(genpath(fullfile(projectRoot, "src")));
addpath(genpath(fullfile(projectRoot, "studies", "approachPaper")));

%% 1. Choose a Workflow and Project Paths

% "single": one spreadsheet | "batch": group folders | "demo": generated
% signal | "simulation": Paper 1 known-truth and empirical study package
runType = lower("simulation");

% Edit this one path to point the single, batch, and paper workflows at a
% different dataset. Expected group folders include NC, MCI, or LC.
dataFolder = "/Users/amoghn/Downloads/ieem_data";

% Generated outputs stay out of the source folders and are ignored by Git.
resultsRoot = fullfile(projectRoot, "results");

%% 2. Select the Subject or Batch

batchSettings = defaultTfaBatchSettings( ...
    dataFolder, ["NC"; "MCI"]);
batchSettings.targetSuccessfulSubjectsPerGroup = Inf;
batchSettings.previewOnly = false;
batchSettings.numSubjectFiguresPerGroup = 1;  % Number, "none", or "all"

subjectInfo.subjectID = "105";
subjectInfo.group = "MCI";
subjectInfo.sourceFile = fullfile( ...
    dataFolder, subjectInfo.group, ...
    subjectInfo.subjectID + "_baseline.xlsx");

%% 3. Configure the Shared TFA Method

% This complete default structure is used by ordinary data analysis and as
% the methodological starting point for the Paper 1 workflow.
analysisSettings = defaultTfaAnalysisSettings( ...
    batchSettings.groupsToRun);

% Models
analysisSettings.runMISO = true;
analysisSettings.runSISO = true;
analysisSettings.misoSolver = defaultMisoSolverSettings();
analysisSettings.retainAnalysisInput = false;

% Sampling and analyzed frequencies
analysisSettings.fsTarget = 4;
analysisSettings.frequencyRangeHz = [0 0.35];
analysisSettings.frequencyBandEdgesHz = ...
    [0.005; 0.024; 0.070; 0.200; 0.350];
analysisSettings.frequencyBandNames = ["VVLF"; "VLF"; "LF"; "HF"];

% Preprocessing
analysisSettings.preprocessing.normalizeCbv = true;
analysisSettings.preprocessing.detrendEnabled = false;
analysisSettings.preprocessing.detrendOrder = 1;
analysisSettings.preprocessing.meanRemovalEnabled = true;

% Welch spectral estimation
analysisSettings.pwelch.windowLengthSeconds = 128;
analysisSettings.pwelch.windowOverlap = 0.5;
analysisSettings.pwelch.minimumWindows = 3;
analysisSettings.pwelch.smoothingEnabled = true;
analysisSettings.pwelch.smoothingKernel = [0.25 0.50 0.25];

% Phase. The custom fields are used only when unwrapMethod is "custom".
analysisSettings.phase.unwrapMethod = "standard";
analysisSettings.phase.custom.windowSize = 11;
analysisSettings.phase.custom.numPasses = 3;
analysisSettings.phase.custom.useCoherenceWeights = true;
analysisSettings.phase.custom.weightMode = "power";
analysisSettings.phase.custom.weightPower = 4;
analysisSettings.phase.custom.expAlpha = 4;
analysisSettings.phase.custom.minWeight = 0.01;

%% 4. Configure Batch Statistics

analysisSettings.statistics.enabled = true;
analysisSettings.statistics.alpha = 0.05;
analysisSettings.statistics.numPhasePermutations = 10000;
analysisSettings.statistics.randomSeed = 2026;
analysisSettings.statistics.groupsToCompare = ...
    batchSettings.groupsToRun;
analysisSettings.statistics.primaryBandNames = ...
    analysisSettings.frequencyBandNames;
analysisSettings.statistics.primaryGroups = ...
    batchSettings.groupsToRun;
analysisSettings.statistics.primaryPathways = ["MAP"; "CO2"];
analysisSettings.statistics.secondaryPathways = strings(0, 1);
analysisSettings.statistics.participantDataFile = "";
analysisSettings.statistics.withinGroupModelComparison.enabled = true;
analysisSettings.statistics.betweenGroupComparison.enabled = ...
    numel(batchSettings.groupsToRun) == 2;

% Frequency-wise tests are exploratory and use adjusted P-value curves.
analysisSettings.statistics.frequencyWise.enabled = true;
analysisSettings.statistics.frequencyWise.groupComparison.gain = true;
analysisSettings.statistics.frequencyWise.groupComparison.coherence = true;
analysisSettings.statistics.frequencyWise.groupComparison.phase = true;
analysisSettings.statistics.frequencyWise.modelComparison.gain = true;
analysisSettings.statistics.frequencyWise.modelComparison.phase = true;

%% 5. Configure Ordinary Figures and Files

% "all" enables every ordinary subject, group, and statistical figure;
% use "none" and turn on individual analysisSettings.plot.show fields when
% only a few figures are needed.
analysisSettings.plot = defaultPlotSettings("all");
analysisSettings.plot.transferFunctionStyle = "stem";  % "stem" or "line"

% "all" or "none" controls the initial state of all 30 Excel metrics.
% Individual fields remain editable, for example:
% outputSettings.excelMetrics.miso.mapGain = false;
outputSettings = defaultTfaOutputSettings( ...
    fullfile(resultsRoot, "ordinary_tfa"), "all");
outputSettings.saveSubjectFigures = true;
outputSettings.saveBatchFigures = true;
outputSettings.saveExcel = true;
outputSettings.excelStatistics = true;

%% 6. Configure the Known-Truth Study

% "quick": reduced unit check | "designSmoke": one balanced 25-family block
% "proof250": presentation proof of concept | "paper1000": likely final run
simulationProfile = lower("proof250");
simulationRunName = "presentation_proof_250_families";
simulationOutputFolder = fullfile( ...
    resultsRoot, "approach_paper_" + simulationRunName);

paperSettings = approachPaperSettings( ...
    dataFolder, simulationOutputFolder, ...
    simulationProfile, analysisSettings);

paperSettings.steps.runEmpiricalAnalysis = false;
paperSettings.steps.runKnownTruthSimulation = true;
paperSettings.steps.runRobustnessAnalysis = false;
paperSettings.steps.createTables = true;
paperSettings.steps.createFigures = true;

paperSettings.export.savePdf = true;
paperSettings.export.savePng = true;
paperSettings.export.saveFigureSourceData = true;
paperSettings.export.saveCaptionFiles = true;
paperSettings.export.saveCaptionCatalog = true;

simulationSettings = paperSettings.simulation;

% The selected profile defines the family count, assigned factor levels,
% observation sweep, five-bin proof grouping, and estimator sensitivities.
% See docs/proof_of_concept_simulation_design.md for the complete design.

% Optional sweep overrides. Uncomment only what should differ from the
% selected named profile. Avoid changing the five assigned family factors
% without also revising and validating the balanced design.
% simulationSettings.observations.durationSeconds = [256 300 512 896];
% simulationSettings.observations.outputSnrDb = [Inf 20 10 0];
% simulationSettings.observations.inputNoiseSnrDb = [Inf 20 10 0];
% simulationSettings.observations.alignmentErrorSeconds = [-6 -3 0 3 6];

paperSettings.simulation = simulationSettings;

%% 7. Run the Selected Workflow

if runType == "simulation"
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
