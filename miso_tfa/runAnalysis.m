function results = runAnalysis(configuration)
% runAnalysis Configure and run the real-data or known-truth TFA pipeline.
%
% Edit the settings below, then press Run or call results = runAnalysis().
% To configure a run programmatically:
%   settings = runAnalysis("settings");
%   settings.mode = "data";
%   settings.data.paths = "/path/to/recordings";
%   results = runAnalysis(settings);
%
% This is the only settings file. src/ contains the scientific operations.

    projectFolder = fileparts(mfilename("fullpath"));
    addpath(fullfile(projectFolder, "src"));

    %% Choose the workflow
    settings.mode = "simulation";                 % "data" or "simulation"

    %% Your recordings: numeric time, MAP, end-tidal CO2, and CBFV columns
    settings.data.paths = strings(0, 1);           % File(s) or folder(s)
    settings.data.filePatterns = ["*.xlsx", "*.xls", "*.csv"];
    settings.data.recursive = false;
    settings.data.groupBySubfolder = false;
    settings.data.groupLabel = "All";
    settings.data.sheet = "";                     % Empty: use a known sheet name
    % Empty mappings recognize common headers, including the IEEM exports.
    % For another lab, enter the exact column headings here.
    settings.data.columnMap.t = "";               % e.g. "Time"
    settings.data.columnMap.map = "";             % e.g. "MAP"
    settings.data.columnMap.co2 = "";             % e.g. "PETCO2"
    settings.data.columnMap.cbv = "";             % e.g. "CBFV"
    settings.data.timeScaleToSeconds = 1;         % Milliseconds: 0.001
    settings.data.signalScale.map = 1;            % Convert inputs to mmHg
    settings.data.signalScale.co2 = 1;            % kPa to mmHg: 7.50062
    settings.data.signalScale.cbv = 1;            % Convert CBFV to cm/s

    %% Shared signal preparation and spectral analysis
    settings.analysis.fsTarget = 4;               % Samples/second
    settings.analysis.frequencyRangeHz = [0.02 0.35];
    settings.analysis.preprocessing.normalizeCbv = true; % % baseline or native units
    settings.analysis.preprocessing.meanRemovalEnabled = true;
    settings.analysis.preprocessing.detrendEnabled = false; % Whole-record detrending
    settings.analysis.preprocessing.detrendOrder = 1;
    settings.analysis.preprocessing.co2DelayCorrectionSeconds = 0;
    settings.analysis.preprocessing.maximumGapSeconds = 2;
    settings.analysis.preprocessing.maximumCo2StartupSeconds = 45;
    settings.analysis.preprocessing.co2StartupStableFraction = 0.80;
    settings.analysis.pwelch.windowLengthSeconds = 100;
    settings.analysis.pwelch.windowOverlap = 0.5;
    settings.analysis.pwelch.minimumWindows = 3;
    settings.analysis.pwelch.smoothingEnabled = true;
    settings.analysis.pwelch.smoothingKernel = [0.25 0.50 0.25];
    % Welch segments are linearly detrended before the Hann window, as in
    % the original method. Both estimators always use the same spectra.

    %% Simulation reference condition
    % These are experimental reference values, not population normal ranges.
    % 0.15 coherence is informed by the resting NC input characterization.
    settings.simulation.baseline.inputCoherence = 0.15;
    settings.simulation.baseline.co2FluctuationRatio = 1; % CO2 SD / MAP SD
    settings.simulation.baseline.co2GainRatio = 1;        % Band RMS gain ratio
    settings.simulation.baseline.mapTimeConstantSeconds = 3;
    settings.simulation.baseline.co2TimeConstantSeconds = 5;
    settings.simulation.baseline.co2DelaySeconds = 3;     % Inside the true pathway
    settings.simulation.baseline.inputLagSeconds = 0;    % CO2 relative to MAP
    settings.simulation.baseline.spectralSimilarity = 1;
    settings.simulation.baseline.durationSeconds = 300;
    settings.simulation.baseline.outputSnrDb = 10;
    settings.simulation.baseline.mapInputSnrDb = Inf;
    settings.simulation.baseline.co2InputSnrDb = Inf;
    settings.simulation.baseline.alignmentErrorSeconds = 0; % Recording error

    %% Conditions to investigate
    % oneAtATime: change one field from the reference, leaving others fixed.
    % factorial: cross the listed fields; use this to examine interactions.
    settings.simulation.design = "oneAtATime";
    settings.simulation.vary = ["inputCoherence", "co2FluctuationRatio", ...
        "co2GainRatio", "durationSeconds", "outputSnrDb"];
    settings.simulation.ranges.inputCoherence = [0 0.15 0.50 0.95];
    settings.simulation.ranges.co2FluctuationRatio = [0.05 0.25 0.50 1 2];
    settings.simulation.ranges.co2GainRatio = [0 0.25 1];
    settings.simulation.ranges.mapTimeConstantSeconds = [1 3 4];
    settings.simulation.ranges.co2TimeConstantSeconds = [2 5 8];
    settings.simulation.ranges.co2DelaySeconds = [0 3 5 10];
    settings.simulation.ranges.inputLagSeconds = [-6 0 4];
    settings.simulation.ranges.spectralSimilarity = [0 0.5 1];
    settings.simulation.ranges.durationSeconds = [300 600];
    settings.simulation.ranges.outputSnrDb = [Inf 10 0];
    settings.simulation.ranges.mapInputSnrDb = [Inf 10 0];
    settings.simulation.ranges.co2InputSnrDb = [Inf 10 0];
    settings.simulation.ranges.alignmentErrorSeconds = [-3 0 3];
    settings.simulation.repetitions = 50;          % Independent recordings/condition
    settings.simulation.randomSeed = 2026;
    settings.simulation.masterDurationSeconds = 1200;

    %% Existing input generator and known pathway rules
    settings.simulation.inputs.mapStandardDeviation = 1;
    settings.simulation.inputs.spectrumModel = "ncMonotonic";
    settings.simulation.inputs.rolloffFrequencyHz = 0.0290;
    settings.simulation.inputs.rolloffExponent = 2.5514;
    settings.simulation.inputs.spectrumFloorFraction = 0.01;
    % The older Gaussian-spectrum option permits a spectral-overlap sweep.
    % These three settings apply only when spectrumModel is "gaussian".
    settings.simulation.inputs.mapSpectrumCenterHz = 0.06;
    settings.simulation.inputs.spectrumBandwidthHz = 0.045;
    settings.simulation.inputs.maximumCenterSeparationHz = 0.22;
    settings.simulation.pathways.mapHighFrequencyGain = 1.5;
    settings.simulation.pathways.mapLowFrequencyGainFraction = 0.25;
    settings.simulation.pathways.filterDurationTimeConstants = 6;
    settings.simulation.pathways.burnInSeconds = 120;
    settings.simulation.pathways.calibrationBandHz = [0.02 0.35];
    settings.simulation.noiseSpectrum = "signalShaped"; % or "white"
    % Simulation amplitudes use arbitrary units. This reference is used
    % only for conversion to percent; 100 preserves the original gains.
    settings.simulation.cbvNormalizationReference = 100;

    %% Accuracy summaries: errors are calculated but have no error figures
    settings.simulation.metrics = ["gain", "phase"]; % Optionally append "complex"
    settings.simulation.phaseMinimumTruthGainFraction = 0.05;
    settings.simulation.bootstrapSamples = 1000;   % 0 disables Monte Carlo intervals
    settings.simulation.confidenceLevel = 0.95;

    %% Figures shared by real and simulated recordings
    settings.plots.createFigures = true;
    settings.plots.visible = "on";                % "off" for unattended export
    settings.plots.individuals = false;
    settings.plots.averages = true;
    settings.plots.simulationConditionIDs = 1;    % 1 = reference; [] = all
    settings.plots.showStandardDeviation = true; % Across recordings, not a CI
    settings.plots.phaseStyle = "wrapped";        % or "unwrapped"
    settings.plots.showDifferences = true;        % MISO minus SISO, both modes
    settings.plots.explainSimulation = true;
    settings.plots.exampleDurationSeconds = 120;
    settings.plots.advantageColorLimit = NaN;      % NaN: automatic symmetric limits
    settings.plots.impulseTimeLimitsSeconds = [-10 30];
    settings.plots.individualLimit = Inf;

    %% Save settings, numerical results, tables, and selected figures
    runName = settings.mode + "_" + string(datetime("now", Format="yyyyMMdd_HHmmss"));
    settings.output.folder = fullfile(projectFolder, "output", runName);
    settings.output.saveMat = true;
    settings.output.saveCsv = true;
    settings.output.saveFigures = true;

    %% Run; the remaining functions receive these settings explicitly
    if nargin > 0 && isstring(configuration) && isscalar(configuration) ...
            && configuration == "settings"
        results = settings;
        return
    end
    if nargin > 0
        settings = configuration;
    end
    results = runTfaPipeline(settings);
end
