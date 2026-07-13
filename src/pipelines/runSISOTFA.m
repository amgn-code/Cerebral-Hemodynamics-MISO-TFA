function sisoResults = runSISOTFA( ...
    map, co2, cbv, fs, ...
    frequencyBandEdgesHz, frequencyBandNames, ...
    windowLengthSeconds, windowOverlap, ...
    figureMode, phaseSettings, plotSettings)

if nargin < 10
    phaseSettings = defaultPhaseSettings();
end

if nargin < 11
    plotSettings = defaultPlotSettings();
end

phaseSettings = normalizePhaseSettings(phaseSettings);

% runSISO
%
% SISO PSD / cross-spectral transfer function pipeline.
%
% Estimates two independent SISO transfer functions:
%
%   H_MAP_CBV(f)  = S_MAP_CBV(f)  / S_MAP_MAP(f)
%   H_CO2_CBV(f) = S_CO2_CBV(f) / S_CO2_CO2(f)
%
% SISO limitation:
%   MAP -> CBV is estimated while ignoring CO2.
%   CO2 -> CBV is estimated while ignoring MAP.
%
% This is useful as a comparison against the MISO pipeline.

%% Format signals

mapClean  = reshape(map,  1, []);
co2Clean = reshape(co2, 1, []);
cbvClean = reshape(cbv, 1, []);

% Mean removal, detrending, and optional high-pass filtering are handled in
% btbPreProcessing so SISO and MISO use the same analysis signals.

%% Welch settings

[window, welchInfo] = ...
    windowSettings(windowLengthSeconds, windowOverlap, fs, length(mapClean));

if welchInfo.isTooShort
    error('Signal is shorter than the Welch window. Use a longer signal or reduce windowLengthSeconds.');
end

windowOverlapSamples = welchInfo.windowOverlapSamples;
fftLengthSamples = welchInfo.fftLengthSamples;
numWindows = welchInfo.numWindows;

%% Spectral estimates

[S_mapmap, f]   = cpsd(mapClean,  mapClean,  window, windowOverlapSamples, fftLengthSamples, fs);
[S_co2co2, ~] = cpsd(co2Clean, co2Clean, window, windowOverlapSamples, fftLengthSamples, fs);
[S_cbvcbv, ~] = cpsd(cbvClean, cbvClean, window, windowOverlapSamples, fftLengthSamples, fs);

[S_mapcbv, ~]  = cpsd(mapClean,  cbvClean, window, windowOverlapSamples, fftLengthSamples, fs);
[S_co2cbv, ~] = cpsd(co2Clean, cbvClean, window, windowOverlapSamples, fftLengthSamples, fs);

%% Triangular smoothing

triangularSmoothingWindow = [0.25, 0.5, 0.25];

S_mapmap_smoothed   = conv(S_mapmap,   triangularSmoothingWindow, 'same');
S_co2co2_smoothed = conv(S_co2co2, triangularSmoothingWindow, 'same');
S_cbvcbv_smoothed = conv(S_cbvcbv, triangularSmoothingWindow, 'same');

S_mapcbv_smoothed  = conv(S_mapcbv,  triangularSmoothingWindow, 'same');
S_co2cbv_smoothed = conv(S_co2cbv, triangularSmoothingWindow, 'same');

%% Coherence critical values

[coherenceThreshold, coherenceThresholdInfo] = ...
    coherenceThresholdFromCarnet(numWindows);

welchInfo.coherenceThreshold = coherenceThreshold;
welchInfo.coherenceThresholdSource = coherenceThresholdInfo.source;
welchInfo.usesDefaultCoherenceThreshold = false;
welchInfo.phaseUnwrapMethod = phaseSettings.unwrapMethod;
welchInfo.phaseSettings = phaseSettings;

%% SISO transfer functions

% Correct MATLAB cpsd phase convention for H = output / input
S_mapcbv_tf  = conj(S_mapcbv_smoothed);
S_co2cbv_tf = conj(S_co2cbv_smoothed);

epsilonMap = 1e-6 * max(real(S_mapmap_smoothed));
epsilonCO2 = 1e-6 * max(real(S_co2co2_smoothed));

H_mapcbv = S_mapcbv_tf ./ (S_mapmap_smoothed + epsilonMap);
H_co2cbv = S_co2cbv_tf ./ (S_co2co2_smoothed + epsilonCO2);

%% Univariate coherence

mapCbvCoherence = abs(S_mapcbv_smoothed).^2 ./ ...
    real(S_mapmap_smoothed .* S_cbvcbv_smoothed);

co2CbvCoherence = abs(S_co2cbv_smoothed).^2 ./ ...
    real(S_co2co2_smoothed .* S_cbvcbv_smoothed);

% Clean impossible numerical values
mapCbvCoherence = real(mapCbvCoherence);
co2CbvCoherence = real(co2CbvCoherence);

coherenceDiagnostics = [
    validateCoherenceValues(mapCbvCoherence, "SISO MAP-CBV")
    validateCoherenceValues(co2CbvCoherence, "SISO CO2-CBV")
];

mapUnexplainedFraction = 1 - mapCbvCoherence;
co2UnexplainedFraction = 1 - co2CbvCoherence;
mapInputPowerNormalized = normalizePowerSpectrum(S_mapmap_smoothed);
co2InputPowerNormalized = normalizePowerSpectrum(S_co2co2_smoothed);

mapCbvPhaseData = computePhaseRepresentations( ...
    H_mapcbv, f, mapCbvCoherence, coherenceThreshold, phaseSettings, "map");
co2CbvPhaseData = computePhaseRepresentations( ...
    H_co2cbv, f, co2CbvCoherence, coherenceThreshold, phaseSettings, "co2");

if figureMode ~= "none"
    plotSISOResults( ...
        f, ...
        H_mapcbv, ...
        H_co2cbv, ...
        mapCbvPhaseData, ...
        co2CbvPhaseData, ...
        mapCbvCoherence, ...
        co2CbvCoherence, ...
        mapUnexplainedFraction, ...
        co2UnexplainedFraction, ...
        mapInputPowerNormalized, ...
        co2InputPowerNormalized, ...
        coherenceThreshold, ...
        frequencyBandEdgesHz, ...
        frequencyBandNames, ...
        figureMode, ...
        plotSettings);
end

%% Band Averages

bandAverages = computeSISOBandAverages( ...
    f, ...
    H_mapcbv, ...
    H_co2cbv, ...
    mapCbvCoherence, ...
    co2CbvCoherence, ...
    coherenceThreshold, ...
    frequencyBandEdgesHz, ...
    frequencyBandNames, ...
    phaseSettings);

%% Store results

sisoResults.f = f;

sisoResults.mapPower = S_mapmap;
sisoResults.mapPowerSmooth = S_mapmap_smoothed;
sisoResults.co2Power = S_co2co2;
sisoResults.co2PowerSmooth = S_co2co2_smoothed;
sisoResults.cbvPower = S_cbvcbv;
sisoResults.cbvPowerSmooth = S_cbvcbv_smoothed;

sisoResults.mapCbvGain = abs(H_mapcbv);
sisoResults.mapCbvPhaseWrapped = mapCbvPhaseData.wrapped;
sisoResults.mapCbvPhaseUnwrapped = mapCbvPhaseData.unwrapped;
sisoResults.mapCbvPhaseAnchored = mapCbvPhaseData.anchored;
sisoResults.mapCbvPhase = mapCbvPhaseData.display;

sisoResults.co2CbvGain = abs(H_co2cbv);
sisoResults.co2CbvPhaseWrapped = co2CbvPhaseData.wrapped;
sisoResults.co2CbvPhaseUnwrapped = co2CbvPhaseData.unwrapped;
sisoResults.co2CbvPhaseAnchored = co2CbvPhaseData.anchored;
sisoResults.co2CbvPhase = co2CbvPhaseData.display;

sisoResults.mapCbvCoh = mapCbvCoherence;
sisoResults.co2CbvCoh = co2CbvCoherence;
sisoResults.mapUnexplainedFraction = mapUnexplainedFraction;
sisoResults.co2UnexplainedFraction = co2UnexplainedFraction;
sisoResults.mapInputPowerNormalized = mapInputPowerNormalized;
sisoResults.co2InputPowerNormalized = co2InputPowerNormalized;
sisoResults.coherenceDiagnostics = coherenceDiagnostics;
sisoResults.mapCbvPhaseAnchorInfo = mapCbvPhaseData.anchorInfo;
sisoResults.co2CbvPhaseAnchorInfo = co2CbvPhaseData.anchorInfo;

sisoResults.bandAverages = bandAverages;
sisoResults.welchInfo = welchInfo;
sisoResults.phaseUnwrapMethod = phaseSettings.unwrapMethod;
sisoResults.phaseSettings = phaseSettings;

% Keep the spectral solve unchanged, then expose only the configured
% analysis range to plotting, exports, and batch aggregation.
sisoResults = limitResultsToFrequencyRange( ...
    sisoResults, plotSettings.frequencyLimitsHz);


end
