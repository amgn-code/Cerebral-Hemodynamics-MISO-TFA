function misoTFAResults = runMISOTFA( ...
    map, co2, cbv, fs, ...
    frequencyBandEdgesHz, frequencyBandNames, ...
    windowLengthSeconds, windowOverlap, ...
    figureMode)
%
%Assuming Trecord = 300s and fs = 50Hz
%
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

numWelchWindows = [3, 4, 5, 6, 7, 8, 9,10, 15, 20, 25];
coherenceCriticalValues = [0.51, 0.41, 0.34, 0.29, 0.25, 0.22, 0.20, 0.18, 0.12, 0.09, 0.08];
coherenceThresholdIndex = find(numWindows == numWelchWindows, 1);

if isempty(coherenceThresholdIndex)
    warning('numWindows does not match coherence lookup table. Using default threshold of 0.51.');
    coherenceThreshold = 0.51;
    welchInfo.usesDefaultCoherenceThreshold = true;
else
    coherenceThreshold = coherenceCriticalValues(coherenceThresholdIndex);
end

welchInfo.coherenceThreshold = coherenceThreshold;

%% Solving for MISO System

H_mapcbv = NaN(size(f));
H_co2cbv = NaN(size(f));
multipleCoherence = NaN(size(f));

conditionNumber = NaN(size(f));

for k = 1:length(f)

    S_xx = [S_mapmap_smoothed(k), S_mapco2_smoothed(k);
            S_co2map_smoothed(k), S_co2co2_smoothed(k)];

    S_xy = [S_mapcbv_smoothed(k);
           S_co2cbv_smoothed(k)];

    conditionNumber(k) = cond(S_xx);

    %H = inv(S_xx)*S_xy;
    %Better Formulation to reduce Noise
    Eps = 1e-6 * max(diag(S_xx)); % Dynamic safety threshold based on peak power
    H = (S_xx + Eps*eye(2)) \ S_xy; % Robust, regularized matrix division

    H_mapcbv(k) = H(1,1);
    H_co2cbv(k) = H(2,1);

    % Multiple Coherence from Peng
    multipleCoherence(k) = real(H'*S_xx*H) / (S_cbvcbv_smoothed(k));


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

inputInputPhase = angle(S_mapco2_smoothed);

if figureMode ~= "none"

    plotMISOResults( ...
        f, ...
        H_mapcbv, ...
        H_co2cbv, ...
        multipleCoherence, ...
        partialCohMapCbvGivenCo2, ...
        partialCohCo2CbvGivenMap, ...
        mapCbvCoherence, ...
        co2CbvCoherence, ...
        inputInputCoherence, ...
        inputInputPhase, ...
        conditionNumber, ...
        coherenceThreshold, ...
        frequencyBandEdgesHz, ...
        frequencyBandNames, ...
        figureMode);

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
    frequencyBandNames);

%% Store Results

misoTFAResults.f = f;

misoTFAResults.mapPower = S_mapmap;
misoTFAResults.mapPowerSmooth = S_mapmap_smoothed;
misoTFAResults.co2Power = S_co2co2;
misoTFAResults.co2PowerSmooth = S_co2co2_smoothed;
misoTFAResults.cbvPower = S_cbvcbv;
misoTFAResults.cbvPowerSmooth = S_cbvcbv_smoothed;

misoTFAResults.mapCbvGain = abs(H_mapcbv);
misoTFAResults.mapCbvPhase = angle(H_mapcbv);

misoTFAResults.co2CbvGain = abs(H_co2cbv);
misoTFAResults.co2CbvPhase = angle(H_co2cbv);

misoTFAResults.multipleCoh = multipleCoherence;
misoTFAResults.partialCohMap = partialCohMapCbvGivenCo2;
misoTFAResults.partialCohCo2 = partialCohCo2CbvGivenMap;

misoTFAResults.inputInputCoh = inputInputCoherence;
misoTFAResults.inputInputPhase = inputInputPhase;

misoTFAResults.conditionNumber = conditionNumber;

misoTFAResults.bandAverages = bandAverages;
misoTFAResults.welchInfo = welchInfo;

end
