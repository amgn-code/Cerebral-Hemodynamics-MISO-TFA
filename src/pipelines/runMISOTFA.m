function misoTFAResults = runMISOTFA( ...
    map, co2, cbv, fs, ...
    frequencyBandEdgesHz, frequencyBandNames, ...
    windowLengthSeconds, windowOverlap, ...
    figureMode, phaseSettings, plotSettings, regularizationSettings)
%
%Assuming Trecord = 300s and fs = 50Hz
%
if nargin < 10
    phaseSettings = defaultPhaseSettings();
end

if nargin < 11
    plotSettings = defaultPlotSettings();
end

if nargin < 12
    regularizationSettings = defaultMisoRegularizationSettings();
end

phaseSettings = normalizePhaseSettings(phaseSettings);
regularizationSettings = normalizeMisoRegularizationSettings( ...
    regularizationSettings);

mapClean = reshape(map, 1, []);
co2Clean = reshape(co2, 1, []);
cbvClean = reshape(cbv, 1, []);

%% Window Settings for Welch

[window, welchInfo] = ...
    windowSettings(windowLengthSeconds, windowOverlap, fs, length(map));

if welchInfo.isTooShort
    error('Signal is shorter than the Welch window. Use a longer signal or reduce windowLengthSeconds.');
end

windowOverlapSamples = welchInfo.windowOverlapSamples;
fftLengthSamples = welchInfo.fftLengthSamples;
numWindows = welchInfo.numWindows;

%% Transfer Function Formulation

%{

Input overlap matrix          Transfer functions        Input-output relationships

[ S_map,map    S_map,co2  ]     [ H_map→cbv  ]      =      [ S_map,cbv  ]
[ S_co2,map   S_co2,co2 ]     [ H_co2→cbv ]             [ S_co2,cbv ]

%}

%% Auto & Cross Power Spectra

[S_mapmap, f] = cpsd(mapClean, mapClean, window, windowOverlapSamples, fftLengthSamples, fs);
[S_mapco2_conj, ~] = cpsd(mapClean, co2Clean, window, windowOverlapSamples, fftLengthSamples, fs);
[S_co2map_conj, ~] = cpsd(co2Clean, mapClean, window, windowOverlapSamples, fftLengthSamples, fs);
[S_co2co2, ~] = cpsd(co2Clean, co2Clean, window, windowOverlapSamples, fftLengthSamples, fs);

[S_mapcbv_conj, ~] = cpsd(mapClean, cbvClean, window, windowOverlapSamples, fftLengthSamples, fs);
[S_co2cbv_conj, ~] = cpsd(co2Clean, cbvClean, window, windowOverlapSamples, fftLengthSamples, fs);

[S_cbvcbv, ~] = cpsd(cbvClean, cbvClean, window, windowOverlapSamples, fftLengthSamples, fs);

%% CPSD in MATLAB defined as X(Y*) not (X*)Y

S_mapco2 = conj(S_mapco2_conj);
S_co2map = conj(S_co2map_conj);

S_mapcbv = conj(S_mapcbv_conj);
S_co2cbv = conj(S_co2cbv_conj);

%% Apply triangular smoothing to the cross-spectral densities

triangularSmoothingWindow = [0.25,0.5,0.25];

S_mapmap_smoothed = conv(S_mapmap, triangularSmoothingWindow, 'same');
S_mapco2_smoothed = conv(S_mapco2, triangularSmoothingWindow, 'same');
S_co2map_smoothed = conv(S_co2map, triangularSmoothingWindow, 'same');
S_co2co2_smoothed = conv(S_co2co2, triangularSmoothingWindow, 'same');
S_mapcbv_smoothed = conv(S_mapcbv, triangularSmoothingWindow, 'same');
S_co2cbv_smoothed = conv(S_co2cbv, triangularSmoothingWindow, 'same');
S_cbvcbv_smoothed = conv(S_cbvcbv, triangularSmoothingWindow, 'same');

%% Coherence Critical Values

[coherenceThreshold, coherenceThresholdInfo] = ...
    coherenceThresholdFromCarnet(numWindows);

welchInfo.coherenceThreshold = coherenceThreshold;
welchInfo.coherenceThresholdSource = coherenceThresholdInfo.source;
welchInfo.usesDefaultCoherenceThreshold = false;
welchInfo.phaseUnwrapMethod = phaseSettings.unwrapMethod;
welchInfo.phaseSettings = phaseSettings;

%% Solving for MISO System

H_mapcbv = NaN(size(f));
H_co2cbv = NaN(size(f));
multipleCoherence = NaN(size(f));
unexplainedFraction = NaN(size(f));
residualPower = NaN(size(f));

conditionNumber = NaN(size(f));
regularizationLambda = NaN(size(f));

for k = 1:length(f)

    S_xx = [S_mapmap_smoothed(k), S_mapco2_smoothed(k);
            S_co2map_smoothed(k), S_co2co2_smoothed(k)];

    S_xy = [S_mapcbv_smoothed(k);
           S_co2cbv_smoothed(k)];

    conditionNumber(k) = cond(S_xx);

    inputPowerScale = max(real(diag(S_xx)));
    if ~isfinite(inputPowerScale) || inputPowerScale <= 0
        inputPowerScale = eps;
    end

    conditionMultiplier = 1;
    if regularizationSettings.conditionAware && ...
            isfinite(conditionNumber(k)) && ...
            conditionNumber(k) > regularizationSettings.conditionThreshold
        conditionMultiplier = conditionNumber(k) / ...
            regularizationSettings.conditionThreshold;
        conditionMultiplier = min( ...
            conditionMultiplier, ...
            regularizationSettings.maxConditionMultiplier);
    end

    regularizationLambda(k) = ...
        regularizationSettings.baseLambdaScale * ...
        inputPowerScale * conditionMultiplier;
    H = (S_xx + regularizationLambda(k)*eye(2)) \ S_xy;

    H_mapcbv(k) = H(1,1);
    H_co2cbv(k) = H(2,1);

    % Multiple Coherence from Peng
    cbvPowerAtFrequency = real(S_cbvcbv_smoothed(k));
    multipleCoherence(k) = real(H'*S_xx*H) / cbvPowerAtFrequency;
    unexplainedFraction(k) = 1 - multipleCoherence(k);
    residualPower(k) = cbvPowerAtFrequency * unexplainedFraction(k);


end

%% Partial Coherence as Defined by Perreault 

% Needed conjugate spectra
S_cbvco2 = conj(S_co2cbv_smoothed);
S_co2map = conj(S_mapco2_smoothed);

% Residual spectra after removing CO2
S_mapcbv_given_co2 = S_mapcbv_smoothed - ...
    (S_mapco2_smoothed .* S_co2cbv_smoothed) ./ S_co2co2_smoothed;

S_mapmap_given_co2 = S_mapmap_smoothed - ...
    (S_mapco2_smoothed .* S_co2map) ./ S_co2co2_smoothed;

S_cbvcbv_given_co2 = S_cbvcbv_smoothed - ...
    (S_cbvco2 .* S_co2cbv_smoothed) ./ S_co2co2_smoothed;

% Partial coherence: MAP-CBV after removing CO2
partialCohMapCbvGivenCo2 = abs(S_mapcbv_given_co2).^2 ./ ...
    real(S_mapmap_given_co2 .* S_cbvcbv_given_co2);

% Needed conjugate spectra
S_cbvmap = conj(S_mapcbv_smoothed);
S_mapco2 = conj(S_co2map_smoothed);

% Residual spectra after removing MAP
S_co2cbv_given_map = S_co2cbv_smoothed - ...
    (S_co2map_smoothed .* S_mapcbv_smoothed) ./ S_mapmap_smoothed;

S_co2co2_given_map = S_co2co2_smoothed - ...
    (S_co2map_smoothed .* S_mapco2) ./ S_mapmap_smoothed;

S_cbvcbv_given_map = S_cbvcbv_smoothed - ...
    (S_cbvmap .* S_mapcbv_smoothed) ./ S_mapmap_smoothed;

% Partial coherence: CO2-CBV after removing MAP
partialCohCo2CbvGivenMap = abs(S_co2cbv_given_map).^2 ./ ...
    real(S_co2co2_given_map .* S_cbvcbv_given_map);

%% Coherence Diagnostics

% SISO Coherence
mapCbvCoherence = abs(S_mapcbv_smoothed).^2 ./ ...
    real(S_mapmap_smoothed .* S_cbvcbv_smoothed);

co2CbvCoherence = abs(S_co2cbv_smoothed).^2 ./ ...
    real(S_co2co2_smoothed .* S_cbvcbv_smoothed);

inputInputCoherence = abs(S_mapco2_smoothed).^2 ./ ...
    real(S_mapmap_smoothed .* S_co2co2_smoothed);

coherenceDiagnostics = [
    validateCoherenceValues(multipleCoherence, "MISO multiple")
    validateCoherenceValues(partialCohMapCbvGivenCo2, "MISO MAP partial")
    validateCoherenceValues(partialCohCo2CbvGivenMap, "MISO CO2 partial")
    validateCoherenceValues(mapCbvCoherence, "MISO MAP-CBV pairwise")
    validateCoherenceValues(co2CbvCoherence, "MISO CO2-CBV pairwise")
    validateCoherenceValues(inputInputCoherence, "MISO MAP-CO2 input")
];

inputInputPhaseData = computePhaseRepresentations( ...
    S_mapco2_smoothed, f, inputInputCoherence, coherenceThreshold, ...
    phaseSettings, "input");
mapCbvPhaseData = computePhaseRepresentations( ...
    H_mapcbv, f, partialCohMapCbvGivenCo2, coherenceThreshold, ...
    phaseSettings, "map");
co2CbvPhaseData = computePhaseRepresentations( ...
    H_co2cbv, f, partialCohCo2CbvGivenMap, coherenceThreshold, ...
    phaseSettings, "co2");

if figureMode ~= "none"

    plotMISOResults( ...
        f, ...
        H_mapcbv, ...
        H_co2cbv, ...
        mapCbvPhaseData, ...
        co2CbvPhaseData, ...
        multipleCoherence, ...
        partialCohMapCbvGivenCo2, ...
        partialCohCo2CbvGivenMap, ...
        mapCbvCoherence, ...
        co2CbvCoherence, ...
        inputInputCoherence, ...
        inputInputPhaseData, ...
        conditionNumber, ...
        regularizationLambda, ...
        unexplainedFraction, ...
        coherenceThreshold, ...
        frequencyBandEdgesHz, ...
        frequencyBandNames, ...
        figureMode, ...
        plotSettings);

end

%% Band Averages

bandAverages = computeMISOBandAverages( ...
    f, ...
    H_mapcbv, ...
    H_co2cbv, ...
    multipleCoherence, ...
    partialCohMapCbvGivenCo2, ...
    partialCohCo2CbvGivenMap, ...
    coherenceThreshold, ...
    frequencyBandEdgesHz, ...
    frequencyBandNames, ...
    phaseSettings);

%% Store Results

misoTFAResults.f = f;

misoTFAResults.mapPower = S_mapmap;
misoTFAResults.mapPowerSmooth = S_mapmap_smoothed;
misoTFAResults.co2Power = S_co2co2;
misoTFAResults.co2PowerSmooth = S_co2co2_smoothed;
misoTFAResults.cbvPower = S_cbvcbv;
misoTFAResults.cbvPowerSmooth = S_cbvcbv_smoothed;

misoTFAResults.mapCbvGain = abs(H_mapcbv);
misoTFAResults.mapCbvPhaseWrapped = mapCbvPhaseData.wrapped;
misoTFAResults.mapCbvPhaseUnwrapped = mapCbvPhaseData.unwrapped;
misoTFAResults.mapCbvPhaseAnchored = mapCbvPhaseData.anchored;
misoTFAResults.mapCbvPhase = mapCbvPhaseData.display;

misoTFAResults.co2CbvGain = abs(H_co2cbv);
misoTFAResults.co2CbvPhaseWrapped = co2CbvPhaseData.wrapped;
misoTFAResults.co2CbvPhaseUnwrapped = co2CbvPhaseData.unwrapped;
misoTFAResults.co2CbvPhaseAnchored = co2CbvPhaseData.anchored;
misoTFAResults.co2CbvPhase = co2CbvPhaseData.display;

misoTFAResults.multipleCoh = multipleCoherence;
misoTFAResults.partialCohMap = partialCohMapCbvGivenCo2;
misoTFAResults.partialCohCo2 = partialCohCo2CbvGivenMap;
misoTFAResults.unexplainedFraction = unexplainedFraction;
misoTFAResults.residualPower = residualPower;

misoTFAResults.inputInputCoh = inputInputCoherence;
misoTFAResults.inputInputPhaseWrapped = inputInputPhaseData.wrapped;
misoTFAResults.inputInputPhaseUnwrapped = inputInputPhaseData.unwrapped;
misoTFAResults.inputInputPhaseAnchored = inputInputPhaseData.anchored;
misoTFAResults.inputInputPhase = inputInputPhaseData.display;
misoTFAResults.mapCbvPhaseAnchorInfo = mapCbvPhaseData.anchorInfo;
misoTFAResults.co2CbvPhaseAnchorInfo = co2CbvPhaseData.anchorInfo;

misoTFAResults.conditionNumber = conditionNumber;
misoTFAResults.regularizationLambda = regularizationLambda;
misoTFAResults.regularizationSettings = regularizationSettings;
misoTFAResults.coherenceDiagnostics = coherenceDiagnostics;

misoTFAResults.bandAverages = bandAverages;
misoTFAResults.welchInfo = welchInfo;
misoTFAResults.phaseUnwrapMethod = phaseSettings.unwrapMethod;
misoTFAResults.phaseSettings = phaseSettings;

% Keep the spectral solve unchanged, then expose only the configured
% analysis range to plotting, exports, and batch aggregation.
misoTFAResults = limitResultsToFrequencyRange( ...
    misoTFAResults, plotSettings.frequencyLimitsHz);

end
