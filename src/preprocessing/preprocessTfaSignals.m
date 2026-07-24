function processedSignalData = preprocessTfaSignals( ...
    signalData, targetSamplingFrequencyHz, preprocessingSettings)
% preprocessTfaSignals Clean, resample, and prepare signals for TFA.
%
% The CO2 startup cleanup removes leading zeros and the initial large
% transition into stable recording values. It examines the available CO2
% changes directly and does not assume that startup ends at a fixed point.

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

    if numel(timeValid) < 3
        error( ...
            'TFA:TooFewSamplesForPreprocessing', ...
            'At least three finite samples are required for preprocessing.');
    end

    %% Remove the CO2 Startup Transition

    originalStartTimeSeconds = timeValid(1);
    originalEndTimeSeconds = timeValid(end);

    firstNonzeroIndex = find(co2Valid ~= 0, 1, "first");
    if isempty(firstNonzeroIndex) || firstNonzeroIndex == numel(co2Valid)
        error( ...
            'TFA:NoStableCo2Data', ...
            'No nonzero CO2 data were available for startup cleanup.');
    end

    % Estimate a large-jump threshold from the nonzero portion of the
    % recording. The upper group of changes represents unusually large
    % transitions without tying the calculation to a fixed data point.
    co2Jumps = abs(diff(co2Valid(firstNonzeroIndex:end)));
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

    stableStartTimeSeconds = timeValid(1);
    co2StartupRemovedSeconds = ...
        stableStartTimeSeconds - originalStartTimeSeconds;

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

    %% Calculate Physiological Summaries Before Signal Processing

    mapBaselineMmHg = mean(mapResampled, 'omitnan');
    co2BaselineMmHg = mean(co2Resampled, 'omitnan');
    cbvBaselineCmPerSec = mean(cbvResampled, 'omitnan');

    mapWithinRecordingSdMmHg = std(mapResampled, 0, 'omitnan');
    co2WithinRecordingSdMmHg = std(co2Resampled, 0, 'omitnan');
    cbvWithinRecordingSdCmPerSec = std(cbvResampled, 0, 'omitnan');

    if ~isfinite(mapBaselineMmHg) || ~isfinite(co2BaselineMmHg)
        error( ...
            'TFA:InvalidPhysiologicalBaseline', ...
            'The MAP and CO2 baselines must be finite.');
    end

    %% Select CBV Units for Spectral Analysis

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

    processedSignalData.physiology.meanMapMmHg = mapBaselineMmHg;
    processedSignalData.physiology.meanPetco2MmHg = co2BaselineMmHg;
    processedSignalData.physiology.meanCbvCmPerSec = ...
        cbvBaselineCmPerSec;
    processedSignalData.physiology.mapSdMmHg = ...
        mapWithinRecordingSdMmHg;
    processedSignalData.physiology.petco2SdMmHg = ...
        co2WithinRecordingSdMmHg;
    processedSignalData.physiology.cbvSdCmPerSec = ...
        cbvWithinRecordingSdCmPerSec;
    processedSignalData.physiology.cvri = ...
        mapBaselineMmHg / cbvBaselineCmPerSec;

    processedSignalData.co2Startup.stableStartTimeSeconds = ...
        stableStartTimeSeconds;
    processedSignalData.co2Startup.removedDurationSeconds = ...
        co2StartupRemovedSeconds;
    processedSignalData.co2Startup.originalStartTimeSeconds = ...
        originalStartTimeSeconds;
    processedSignalData.co2Startup.originalEndTimeSeconds = ...
        originalEndTimeSeconds;

end
