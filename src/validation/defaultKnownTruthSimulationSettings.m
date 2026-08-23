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
% Use the "quick" profile while editing code and checking figures. Use the
% "paper" profile only for the final long simulation.

    if nargin < 1
        profileName = "quick";
    end
    profileName = lower(string(profileName));

    settings.profileName = profileName;
    settings.randomSeed = 2026;
    settings.samplingFrequencyHz = 4;
    settings.frequencyRangeHz = [0.005 0.35];
    settings.frequencyBandEdgesHz = ...
        [0.005; 0.024; 0.070; 0.200; 0.350];
    settings.frequencyBandNames = ["VVLF"; "VLF"; "LF"; "HF"];

    %% Family Design

    % These fixed values are assigned as evenly as the family count allows.
    settings.families.targetCoherenceValues = 0.05:0.10:0.95;
    settings.families.spectralSimilarityValues = 0:0.20:1;
    settings.families.petco2ToMapFluctuationSdRatioValues = ...
        [0.05 0.10 0.25 0.50 1 2];
    settings.families.petco2ToMapBandGainRatioValues = ...
        [0.10 0.25 0.50 1 2 4];
    settings.families.co2DelaySecondsValues = [0 2 4 6 8 10];
    settings.families.mapPathwayTimeConstantRange = [1 4];
    settings.families.co2PathwayTimeConstantRange = [2 8];

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
    settings.grouping.inputCoherenceEdges = 0:0.1:1;
    settings.grouping.psdShapeOverlapEdges = 0:0.1:1;
    settings.grouping.petco2ContributionPowerShareEdges = 0:0.1:1;

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

    settings.estimators.ridgeLambdas = [0.001 0.01 0.1];

    % These one-factor-at-a-time checks use the same reference observation.
    settings.estimatorSensitivity.enabled = true;
    settings.estimatorSensitivity.windowLengthSeconds = ...
        [64 75 100 128 150];
    settings.estimatorSensitivity.windowOverlap = [0.25 0.50 0.75];

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

    if profileName == "quick"
        settings.families.numFamilies = 8;
        settings.families.progressEvery = 1;
        settings.observations.durationSeconds = [256 300 320 896];
        settings.observations.outputSnrDb = [Inf 15 0];
        settings.observations.inputNoiseSnrDb = [Inf 15 0];
        settings.observations.alignmentErrorSeconds = [-3 0 3];
        settings.grouping.minimumValidN = 1;
    elseif profileName == "paper"
        settings.families.numFamilies = 1000;
        settings.families.progressEvery = 25;
        settings.observations.durationSeconds = ...
            [256 300 320 384 512 640 896];
        settings.observations.outputSnrDb = ...
            [Inf 30 20 15 10 5 0];
        settings.observations.inputNoiseSnrDb = ...
            [Inf 30 20 15 10 5 0];
        settings.observations.alignmentErrorSeconds = ...
            [-6 -3 0 3 6];
        settings.grouping.minimumValidN = 5;
    else
        error( ...
            "TFA:UnknownSimulationProfile", ...
            "Simulation profileName must be ""quick"" or ""paper"".");
    end

end
