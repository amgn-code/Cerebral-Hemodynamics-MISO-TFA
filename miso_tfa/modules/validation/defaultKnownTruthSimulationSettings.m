function settings = defaultKnownTruthSimulationSettings(profileName)
% defaultKnownTruthSimulationSettings Configure the Paper 1 simulation.
%
% The simulation has three simple levels:
%
%   1. A family is one long, clean random MAP/PETCO2 realization.
%   2. A scenario fixes the input relationship and true pathways.
%   3. An observation changes duration, noise, or alignment without
%      changing the underlying family or physiological truth.
%
% Use "simple" for the small interpretable study, "quick" for fast unit checks, "designSmoke" for one complete
% pairwise-balanced block, "proof250" for the presentation proof of
% concept, and "paper1000" for the likely final-paper simulation.

    if nargin < 1
        profileName = "quick";
    end
    profileName = canonicalProfileName(profileName);
    projectConfiguration = projectSettings();

    settings.profileName = profileName;
    settings.randomSeed = 2026;
    settings.samplingFrequencyHz = ...
        projectConfiguration.samplingFrequencyHz;
    settings.frequencyRangeHz = ...
        projectConfiguration.analysis.reportingBandHz;
    settings.pathways.calibrationBandHz = ...
        projectConfiguration.analysis.pathwayCalibrationBandHz;
    settings.frequencyBandEdgesHz = ...
        [0.005; 0.024; 0.070; 0.200; 0.350];
    settings.frequencyBandNames = ["VVLF"; "VLF"; "LF"; "HF"];

    %% Family Design

    % Five assigned levels support the pairwise-balanced proof design.
    settings.families.targetCoherenceValues = ...
        [0.05 0.25 0.50 0.75 0.95];
    settings.families.spectralSimilarityValues = ...
        [0 0.25 0.50 0.75 1];
    settings.families.petco2ToMapFluctuationSdRatioValues = ...
        [0.05 0.25 0.50 1 2];
    settings.families.petco2ToMapBandGainRatioValues = ...
        [0.10 0.50 1 2 4];
    settings.families.co2DelaySecondsValues = [0 2.5 5 7.5 10];
    settings.families.inputPhaseLagSecondsValues = 0;
    settings.families.mapPathwayTimeConstantRange = [1 4];
    settings.families.co2PathwayTimeConstantRange = [2 8];
    settings.families.designMode = "marginalBalanced";

    %% Input Spectrum Design

    % Spectral similarity controls how close the MAP and PETCO2 spectral
    % centers are. The actual overlap is calculated after generation and is
    % retained as a continuous diagnostic.
    settings.inputs.mapSpectrumCenterHz = 0.06;
    settings.inputs.spectrumBandwidthHz = 0.045;
    settings.inputs.maximumCenterSeparationHz = 0.22;
    settings.inputs.spectrumFloorFraction = 0.01;
    settings.inputs.mapStandardDeviation = 1;
    settings.inputs.coherenceProfile = "flat";

    %% True Physiological Pathways

    settings.pathways.mapHighFrequencyGain = 1.5;
    settings.pathways.mapLowFrequencyGainFraction = 0.25;
    settings.pathways.co2UnscaledGain = 1;
    settings.pathways.filterDurationTimeConstants = 6;
    settings.pathways.burnInSeconds = 120;
    settings.pathways.nonlinearInteractionStrength = 0;

    %% Observation Variants

    % Main experiment: every family receives every duration and output SNR.
    settings.observations.referenceDurationSeconds = 300;
    settings.observations.referenceOutputSnrDb = 15;

    % Secondary paired experiments use the standard duration and reference
    % output SNR. The longest clean record characterizes each family.
    settings.observations.runInputNoiseExperiment = true;
    settings.observations.runAlignmentExperiment = true;

    %% Plot Grouping

    % Intrinsic family factors use fixed, interpretable ranges. Empty
    % groups remain visible so a sparse simulation cannot look complete.
    settings.grouping.inputCoherenceEdges = 0:0.2:1;
    settings.grouping.psdShapeOverlapEdges = 0:0.2:1;
    settings.grouping.petco2ContributionPowerShareEdges = 0:0.2:1;

    %% Welch and Phase Settings

    settings.welch.windowLengthSeconds = 128;
    settings.welch.windowOverlap = 0.5;
    settings.welch.minimumWindows = 3;
    settings.welch.smoothingEnabled = true;
    settings.welch.smoothingKernel = [0.25 0.50 0.25];

    settings.phase.unwrapMethod = "standard";
    settings.phase.custom.windowSize = 11;
    settings.phase.custom.numPasses = 3;
    settings.phase.custom.useCoherenceWeights = true;
    settings.phase.custom.weightMode = "power";
    settings.phase.custom.weightPower = 4;
    settings.phase.custom.expAlpha = 4;
    settings.phase.custom.minWeight = 0.01;

    %% Estimators and Saved Metrics

    settings.metrics.errorFloor = 1e-12;
    settings.metrics.phaseMinimumTruthGainFraction = 0.05;
    settings.metrics.extremeCoefficientThreshold = 25;

    % Inference treats each simulated family as one independent unit.
    settings.statistics.alpha = 0.05;
    settings.statistics.minimumValidN = 3;
    settings.statistics.multipleTestingMethod = ...
        "Benjamini-Hochberg";

    settings.storage.retainFrequencyResults = true;
    settings.storage.retainExampleFamily = true;

    %% Profile Sizes

    switch profileName
        case "simple"
            settings = applySimpleStudy(settings);
        case "quick"
            settings.families.numFamilies = 8;
            settings.families.progressEvery = 1;
            settings.observations.durationSeconds = [256 300 320 896];
            settings.observations.outputSnrDb = [Inf 15 0];
            settings.observations.inputNoiseSnrDb = [Inf 15 0];
            settings.observations.alignmentErrorSeconds = [-3 0 3];
            settings.grouping.minimumValidN = 1;
        case "designsmoke"
            settings = applyFullSweep(settings);
            settings.families.numFamilies = 25;
            settings.families.progressEvery = 5;
            settings.families.designMode = "pairwiseFiveLevel";
            settings.grouping.minimumValidN = 1;
        case "proof250"
            settings = applyFullSweep(settings);
            settings.families.numFamilies = 250;
            settings.families.progressEvery = 10;
            settings.families.designMode = "pairwiseFiveLevel";
            settings.grouping.minimumValidN = 5;
        case "paper1000"
            settings = applyFullSweep(settings);
            settings.families.numFamilies = 1000;
            settings.families.progressEvery = 25;
            settings.families.designMode = "pairwiseFiveLevel";
            % The final-paper grouping will be confirmed after proof250.
            % Ten intervals are retained as the provisional finer grid.
            settings.grouping.inputCoherenceEdges = 0:0.1:1;
            settings.grouping.psdShapeOverlapEdges = 0:0.1:1;
            settings.grouping.petco2ContributionPowerShareEdges = 0:0.1:1;
            settings.grouping.minimumValidN = 5;
    end

end

function profileName = canonicalProfileName(profileName)
% canonicalProfileName Validate names and preserve the historical alias.

    profileName = lower(string(profileName));
    if profileName == "paper"
        profileName = "paper1000";
    end
    validProfiles = ["simple" "quick" "designsmoke" "proof250" "paper1000"];
    if ~ismember(profileName, validProfiles)
        error( ...
            "TFA:UnknownSimulationProfile", ...
            ['Simulation profileName must be "simple", "quick", "designSmoke", ' ...
             '"proof250", or "paper1000".']);
    end

end

function settings = applyFullSweep(settings)
% applyFullSweep Use the complete proof and paper observation grid.

    settings.observations.durationSeconds = ...
        [256 300 320 384 512 640 896];
    settings.observations.outputSnrDb = ...
        [Inf 30 20 15 10 5 0];
    settings.observations.inputNoiseSnrDb = ...
        [Inf 30 20 15 10 5 0];
    settings.observations.alignmentErrorSeconds = [-6 -3 0 3 6];

end

function settings = applySimpleStudy(settings)
% applySimpleStudy Configure the small, interpretable simulation study.
%
% The simple profile varies coherence, CO2 pathway strength, recording
% duration, CBFV output noise, MAP input noise, and CO2 input noise. Input
% phase is fixed at zero until its factor levels are confirmed. Alignment is
% retained as a secondary robustness condition. Welch settings and nuisance
% physiology remain fixed.

    settings.profileName = "simple";
    settings.frequencyRangeHz = [0.005 0.35];
    settings.pathways.calibrationBandHz = [0.005 0.35];
    settings.frequencyBandEdgesHz = [0.005; 0.025; 0.070; 0.200; 0.350];
    settings.frequencyBandNames = ["0.005-0.025"; "0.025-0.070"; ...
        "0.070-0.200"; "0.200-0.350"];

    settings.families.targetCoherenceValues = [0 0.50 0.95];
    settings.families.spectralSimilarityValues = 1;
    settings.families.petco2ToMapFluctuationSdRatioValues = 1;
    settings.families.petco2ToMapBandGainRatioValues = [0 0.25 1];
    settings.families.co2DelaySecondsValues = 3;
    settings.families.inputPhaseLagSecondsValues = 0;
    settings.families.mapPathwayTimeConstantRange = [3 3];
    settings.families.co2PathwayTimeConstantRange = [5 5];
    settings.families.designMode = "fullFactorial";
    settings.families.repetitionsPerCondition = 1;
    settings.families.numFamilies = 9;
    settings.families.progressEvery = 1;

    settings.inputs.maximumCenterSeparationHz = 0;
    settings.inputs.mapStandardDeviation = 1;

    settings.observations.referenceDurationSeconds = 300;
    settings.observations.referenceOutputSnrDb = 10;
    settings.observations.durationSeconds = [300 600];
    settings.observations.outputSnrDb = [Inf 10 0];
    settings.observations.inputNoiseSnrDb = [Inf 10 0];
    settings.observations.alignmentErrorSeconds = [-3 0 3];
    settings.observations.runInputNoiseExperiment = true;
    settings.observations.runAlignmentExperiment = true;

    settings.welch.windowLengthSeconds = 100;
    settings.welch.windowOverlap = 0.5;
    settings.welch.minimumWindows = 3;
    settings.grouping.inputCoherenceEdges = 0:0.25:1;
    settings.grouping.petco2ContributionPowerShareEdges = 0:0.25:1;
    settings.grouping.minimumValidN = 1;

end
