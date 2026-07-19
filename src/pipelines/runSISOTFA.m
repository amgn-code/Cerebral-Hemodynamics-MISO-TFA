function sisoResults = runSISOTFA( ...
    map, co2, cbv, fs, ...
    windowLengthSeconds, windowOverlap, ...
    phaseSettings)
% runSISOTFA Calculate independent MAP-to-CBV and CO2-to-CBV results.

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
    S_mapcbv = conj(S_mapcbv_conj);
    S_co2cbv = conj(S_co2cbv_conj);

    %% Smooth Spectra

    triangularSmoothingWindow = [0.25, 0.5, 0.25];

    S_mapmap_smoothed = conv(S_mapmap, triangularSmoothingWindow, 'same');
    S_co2co2_smoothed = conv(S_co2co2, triangularSmoothingWindow, 'same');
    S_cbvcbv_smoothed = conv(S_cbvcbv, triangularSmoothingWindow, 'same');
    S_mapco2_smoothed = conv(S_mapco2, triangularSmoothingWindow, 'same');
    S_mapcbv_smoothed = conv(S_mapcbv, triangularSmoothingWindow, 'same');
    S_co2cbv_smoothed = conv(S_co2cbv, triangularSmoothingWindow, 'same');

    %% Coherence Threshold

    [coherenceThreshold, coherenceThresholdInfo] = ...
        coherenceThresholdFromCarnet(numWindows);

    welchInfo.coherenceThreshold = coherenceThreshold;
    welchInfo.coherenceThresholdSource = coherenceThresholdInfo.source;
    welchInfo.usesDefaultCoherenceThreshold = false;

    %% Solve Independent SISO Transfer Functions

    H_mapcbv = S_mapcbv_smoothed ./ S_mapmap_smoothed;
    H_co2cbv = S_co2cbv_smoothed ./ S_co2co2_smoothed;

    %% Coherence and Residual Quantities

    mapCbvCoherence = abs(S_mapcbv_smoothed).^2 ./ ...
        real(S_mapmap_smoothed .* S_cbvcbv_smoothed);
    co2CbvCoherence = abs(S_co2cbv_smoothed).^2 ./ ...
        real(S_co2co2_smoothed .* S_cbvcbv_smoothed);
    inputInputCoherence = abs(S_mapco2_smoothed).^2 ./ ...
        real(S_mapmap_smoothed .* S_co2co2_smoothed);

    mapCbvCoherence = real(mapCbvCoherence);
    co2CbvCoherence = real(co2CbvCoherence);
    inputInputCoherence = real(inputInputCoherence);

    mapUnexplainedFraction = 1 - mapCbvCoherence;
    co2UnexplainedFraction = 1 - co2CbvCoherence;
    mapResidualPower = real(S_cbvcbv_smoothed) .* mapUnexplainedFraction;
    co2ResidualPower = real(S_cbvcbv_smoothed) .* co2UnexplainedFraction;

    %% Phase

    mapPhaseWrapped = angle(H_mapcbv);
    mapPhaseUnwrapped = unwrapTfaPhase( ...
        mapPhaseWrapped, f, mapCbvCoherence, phaseSettings);

    co2PhaseWrapped = angle(H_co2cbv);
    co2PhaseUnwrapped = unwrapTfaPhase( ...
        co2PhaseWrapped, f, co2CbvCoherence, phaseSettings);

    inputPhaseWrapped = angle(S_mapco2_smoothed);
    inputPhaseUnwrapped = unwrapTfaPhase( ...
        inputPhaseWrapped, f, inputInputCoherence, phaseSettings);

    %% Store Results

    sisoResults.f = f;

    sisoResults.map.power = S_mapmap_smoothed;
    sisoResults.map.transferFunction = H_mapcbv;
    sisoResults.map.gain = abs(H_mapcbv);
    sisoResults.map.phase.wrapped = mapPhaseWrapped;
    sisoResults.map.phase.unwrapped = mapPhaseUnwrapped;
    sisoResults.map.coherence.pairwise = mapCbvCoherence;
    sisoResults.map.unexplainedFraction = mapUnexplainedFraction;
    sisoResults.map.residualPower = mapResidualPower;

    sisoResults.co2.power = S_co2co2_smoothed;
    sisoResults.co2.transferFunction = H_co2cbv;
    sisoResults.co2.gain = abs(H_co2cbv);
    sisoResults.co2.phase.wrapped = co2PhaseWrapped;
    sisoResults.co2.phase.unwrapped = co2PhaseUnwrapped;
    sisoResults.co2.coherence.pairwise = co2CbvCoherence;
    sisoResults.co2.unexplainedFraction = co2UnexplainedFraction;
    sisoResults.co2.residualPower = co2ResidualPower;

    sisoResults.cbv.power = S_cbvcbv_smoothed;

    sisoResults.inputRelationship.coherence = inputInputCoherence;
    sisoResults.inputRelationship.phase.wrapped = inputPhaseWrapped;
    sisoResults.inputRelationship.phase.unwrapped = inputPhaseUnwrapped;

    sisoResults.phaseUnwrapMethod = string(phaseSettings.unwrapMethod);
    sisoResults.welchInfo = welchInfo;

end
