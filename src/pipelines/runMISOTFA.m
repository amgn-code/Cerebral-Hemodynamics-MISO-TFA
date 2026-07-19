function misoResults = runMISOTFA( ...
    map, co2, cbv, fs, ...
    windowLengthSeconds, windowOverlap, ...
    phaseSettings)
% runMISOTFA Calculate two-input, one-output transfer-function results.

    %% Window Settings for Welch

    [window, welchInfo] = windowSettings( ...
        windowLengthSeconds, windowOverlap, fs, length(map));

    if welchInfo.isTooShort
        error([ ...
            'Signal is shorter than the Welch window. ' ...
            'Use a longer signal or reduce windowLengthSeconds.']);
    end

    windowOverlapSamples = welchInfo.windowOverlapSamples;
    fftLengthSamples = welchInfo.fftLengthSamples;
    numWindows = welchInfo.numWindows;

    %% Auto and Cross Power Spectra

    [S_mapmap, f] = cpsd( ...
        map, map, window, windowOverlapSamples, fftLengthSamples, fs);
    [S_co2co2, ~] = cpsd( ...
        co2, co2, window, windowOverlapSamples, fftLengthSamples, fs);
    [S_cbvcbv, ~] = cpsd( ...
        cbv, cbv, window, windowOverlapSamples, fftLengthSamples, fs);

    [S_mapco2_conj, ~] = cpsd( ...
        map, co2, window, windowOverlapSamples, fftLengthSamples, fs);
    [S_mapcbv_conj, ~] = cpsd( ...
        map, cbv, window, windowOverlapSamples, fftLengthSamples, fs);
    [S_co2cbv_conj, ~] = cpsd( ...
        co2, cbv, window, windowOverlapSamples, fftLengthSamples, fs);

    % MATLAB defines CPSD as X(Y*), while the equations below use (X*)Y.
    S_mapco2 = conj(S_mapco2_conj);
    S_co2map = conj(S_mapco2);
    S_mapcbv = conj(S_mapcbv_conj);
    S_co2cbv = conj(S_co2cbv_conj);

    %% Smooth Spectra

    triangularSmoothingWindow = [0.25, 0.5, 0.25];

    S_mapmap_smoothed = conv(S_mapmap, triangularSmoothingWindow, 'same');
    S_mapco2_smoothed = conv(S_mapco2, triangularSmoothingWindow, 'same');
    S_co2map_smoothed = conv(S_co2map, triangularSmoothingWindow, 'same');
    S_co2co2_smoothed = conv(S_co2co2, triangularSmoothingWindow, 'same');
    S_mapcbv_smoothed = conv(S_mapcbv, triangularSmoothingWindow, 'same');
    S_co2cbv_smoothed = conv(S_co2cbv, triangularSmoothingWindow, 'same');
    S_cbvcbv_smoothed = conv(S_cbvcbv, triangularSmoothingWindow, 'same');

    %% Coherence Threshold

    [coherenceThreshold, coherenceThresholdInfo] = ...
        coherenceThresholdFromCarnet(numWindows);

    welchInfo.coherenceThreshold = coherenceThreshold;
    welchInfo.coherenceThresholdSource = coherenceThresholdInfo.source;
    welchInfo.usesDefaultCoherenceThreshold = false;

    %% Solve MISO System at Each Frequency

    H_mapcbv = complex(NaN(size(f)));
    H_co2cbv = complex(NaN(size(f)));
    multipleCoherence = NaN(size(f));
    conditionNumber = NaN(size(f));

    for k = 1:length(f)
        S_xx = [S_mapmap_smoothed(k), S_mapco2_smoothed(k);
                S_co2map_smoothed(k), S_co2co2_smoothed(k)];

        S_xy = [S_mapcbv_smoothed(k);
                S_co2cbv_smoothed(k)];

        H = S_xx \ S_xy;

        H_mapcbv(k) = H(1);
        H_co2cbv(k) = H(2);

        conditionNumber(k) = cond(S_xx);
        cbvPowerAtFrequency = real(S_cbvcbv_smoothed(k));
        multipleCoherence(k) = real(S_xy' * H) / cbvPowerAtFrequency;
    end

    unexplainedFraction = 1 - multipleCoherence;
    residualPower = real(S_cbvcbv_smoothed) .* unexplainedFraction;

    %% Partial Coherence

    S_cbvco2 = conj(S_co2cbv_smoothed);

    S_mapcbv_given_co2 = S_mapcbv_smoothed - ...
        (S_mapco2_smoothed .* S_co2cbv_smoothed) ./ S_co2co2_smoothed;
    S_mapmap_given_co2 = S_mapmap_smoothed - ...
        (S_mapco2_smoothed .* S_co2map_smoothed) ./ S_co2co2_smoothed;
    S_cbvcbv_given_co2 = S_cbvcbv_smoothed - ...
        (S_cbvco2 .* S_co2cbv_smoothed) ./ S_co2co2_smoothed;

    partialCohMapCbvGivenCo2 = abs(S_mapcbv_given_co2).^2 ./ ...
        real(S_mapmap_given_co2 .* S_cbvcbv_given_co2);

    S_cbvmap = conj(S_mapcbv_smoothed);

    S_co2cbv_given_map = S_co2cbv_smoothed - ...
        (S_co2map_smoothed .* S_mapcbv_smoothed) ./ S_mapmap_smoothed;
    S_co2co2_given_map = S_co2co2_smoothed - ...
        (S_co2map_smoothed .* S_mapco2_smoothed) ./ S_mapmap_smoothed;
    S_cbvcbv_given_map = S_cbvcbv_smoothed - ...
        (S_cbvmap .* S_mapcbv_smoothed) ./ S_mapmap_smoothed;

    partialCohCo2CbvGivenMap = abs(S_co2cbv_given_map).^2 ./ ...
        real(S_co2co2_given_map .* S_cbvcbv_given_map);

    %% Input-Input Coherence

    inputInputCoherence = abs(S_mapco2_smoothed).^2 ./ ...
        real(S_mapmap_smoothed .* S_co2co2_smoothed);

    %% Phase

    mapPhaseWrapped = angle(H_mapcbv);
    mapPhaseUnwrapped = unwrapTfaPhase( ...
        mapPhaseWrapped, f, partialCohMapCbvGivenCo2, phaseSettings);

    co2PhaseWrapped = angle(H_co2cbv);
    co2PhaseUnwrapped = unwrapTfaPhase( ...
        co2PhaseWrapped, f, partialCohCo2CbvGivenMap, phaseSettings);

    inputPhaseWrapped = angle(S_mapco2_smoothed);
    inputPhaseUnwrapped = unwrapTfaPhase( ...
        inputPhaseWrapped, f, inputInputCoherence, phaseSettings);

    %% Store Results

    misoResults.f = f;

    misoResults.map.power = S_mapmap_smoothed;
    misoResults.map.transferFunction = H_mapcbv;
    misoResults.map.gain = abs(H_mapcbv);
    misoResults.map.phase.wrapped = mapPhaseWrapped;
    misoResults.map.phase.unwrapped = mapPhaseUnwrapped;
    misoResults.map.coherence.partial = partialCohMapCbvGivenCo2;

    misoResults.co2.power = S_co2co2_smoothed;
    misoResults.co2.transferFunction = H_co2cbv;
    misoResults.co2.gain = abs(H_co2cbv);
    misoResults.co2.phase.wrapped = co2PhaseWrapped;
    misoResults.co2.phase.unwrapped = co2PhaseUnwrapped;
    misoResults.co2.coherence.partial = partialCohCo2CbvGivenMap;

    misoResults.cbv.power = S_cbvcbv_smoothed;

    misoResults.system.multipleCoherence = multipleCoherence;
    misoResults.system.unexplainedFraction = unexplainedFraction;
    misoResults.system.residualPower = residualPower;

    misoResults.inputRelationship.coherence = inputInputCoherence;
    misoResults.inputRelationship.phase.wrapped = inputPhaseWrapped;
    misoResults.inputRelationship.phase.unwrapped = inputPhaseUnwrapped;

    misoResults.diagnostics.conditionNumber = conditionNumber;

    misoResults.phaseUnwrapMethod = string(phaseSettings.unwrapMethod);
    misoResults.welchInfo = welchInfo;

end
