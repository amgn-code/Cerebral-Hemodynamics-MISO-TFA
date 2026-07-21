function processedSignalData = preprocessTfaSignals( ...
    signalData, targetSamplingFrequencyHz, preprocessingSettings)
% preprocessTfaSignals Clean, resample, and prepare signals for TFA.
%
% The CO2 startup cleanup removes leading zeros and the initial large
% transition into stable recording values. The accepted startup method is
% preserved here as one visible, sequential preprocessing procedure.

    timeRaw = reshape(signalData.t, 1, []);
    mapRaw = reshape(signalData.map, 1, []);
    co2Raw = reshape(signalData.co2, 1, []);
    cbvRaw = reshape(signalData.cbv, 1, []);

    validateattributes( ...
        targetSamplingFrequencyHz, {'numeric'}, ...
        {'real', 'finite', 'scalar', 'positive'}, ...
        mfilename, 'targetSamplingFrequencyHz');

    signalLengths = [ ...
        numel(timeRaw), numel(mapRaw), numel(co2Raw), numel(cbvRaw)];
    if numel(unique(signalLengths)) ~= 1
        error( ...
            'TFA:SignalLengthMismatch', ...
            'Time, MAP, CO2, and CBV must contain the same number of values.');
    end

    %% Remove Rows with Missing or Invalid Values

    validSamples = isfinite(timeRaw) & ...
        isfinite(mapRaw) & ...
        isfinite(co2Raw) & ...
        isfinite(cbvRaw);

    timeValid = timeRaw(validSamples);
    mapValid = mapRaw(validSamples);
    co2Valid = co2Raw(validSamples);
    cbvValid = cbvRaw(validSamples);

    if numel(timeValid) < 31
        error( ...
            'TFA:TooFewSamplesForPreprocessing', ...
            ['At least 31 finite samples are required for the accepted ' ...
             'CO2 startup check.']);
    end

    %% Remove the CO2 Startup Transition

    if any(co2Valid(25:29) == 0)
        warning( ...
            'TFA:Co2StillZeroNearPoint30', ...
            ['CO2 is still zero within the five points before data point 30. ' ...
             'This subject should probably be excluded.']);
    end

    % Estimate a large-jump threshold from the upper 10% of CO2 changes
    % after point 30. This keeps later isolated outliers from defining the
    % end of the startup transition.
    co2Jumps = abs(diff(co2Valid(30:end)));
    sortedCo2Jumps = sort(co2Jumps);
    upperJumpIndex = max(1, round(0.9*numel(sortedCo2Jumps)));
    upperCo2Jumps = sortedCo2Jumps(upperJumpIndex:end);
    co2JumpThreshold = mean(upperCo2Jumps) + std(upperCo2Jumps);

    keepSamples = true(size(co2Valid));
    sampleIndex = 1;

    while sampleIndex < numel(co2Valid)
        currentJump = abs( ...
            co2Valid(sampleIndex + 1) - co2Valid(sampleIndex));

        if co2Valid(sampleIndex) ~= 0 && ...
                currentJump <= co2JumpThreshold
            break
        end

        keepSamples(sampleIndex) = false;
        sampleIndex = sampleIndex + 1;
    end

    if sampleIndex == numel(co2Valid)
        error( ...
            'TFA:NoStableCo2Data', ...
            'No stable CO2 data remained after startup cleanup.');
    end

    timeValid = timeValid(keepSamples);
    mapValid = mapValid(keepSamples);
    co2Valid = co2Valid(keepSamples);
    cbvValid = cbvValid(keepSamples);

    if any(diff(timeValid) <= 0)
        error( ...
            'TFA:InvalidTimeValues', ...
            'Finite time values must be unique and strictly increasing.');
    end

    %% Resample Signals

    targetSampleIntervalSeconds = 1 / targetSamplingFrequencyHz;
    timeResampled = ...
        timeValid(1):targetSampleIntervalSeconds:timeValid(end);

    mapResampled = interp1(timeValid, mapValid, timeResampled, "linear");
    co2Resampled = interp1(timeValid, co2Valid, timeResampled, "linear");
    cbvResampled = interp1(timeValid, cbvValid, timeResampled, "linear");

    %% Select CBV Units for Spectral Analysis

    cbvBaselineCmPerSec = mean(cbvResampled, 'omitnan');

    if ~isfinite(cbvBaselineCmPerSec) || cbvBaselineCmPerSec == 0
        error( ...
            'TFA:InvalidCbvBaseline', ...
            'The resampled CBV baseline must be finite and nonzero.');
    end

    if preprocessingSettings.normalizeCbv
        cbvResampled = (cbvResampled / cbvBaselineCmPerSec) * 100;
        cbvUnits = "% baseline CBV";
    else
        cbvUnits = "cm/s";
    end

    %% Process Signals

    if preprocessingSettings.detrendEnabled
        mapResampled = detrend( ...
            mapResampled, preprocessingSettings.detrendOrder);
        co2Resampled = detrend( ...
            co2Resampled, preprocessingSettings.detrendOrder);
        cbvResampled = detrend( ...
            cbvResampled, preprocessingSettings.detrendOrder);
    end

    if preprocessingSettings.meanRemovalEnabled
        mapResampled = mapResampled - mean(mapResampled, 'omitnan');
        co2Resampled = co2Resampled - mean(co2Resampled, 'omitnan');
        cbvResampled = cbvResampled - mean(cbvResampled, 'omitnan');
    end

    %% Store Result

    processedSignalData.t = timeResampled;
    processedSignalData.map = mapResampled;
    processedSignalData.co2 = co2Resampled;
    processedSignalData.cbv = cbvResampled;
    processedSignalData.fs = targetSamplingFrequencyHz;
    processedSignalData.cbvBaselineCmPerSec = cbvBaselineCmPerSec;
    processedSignalData.cbvUnits = cbvUnits;

end
