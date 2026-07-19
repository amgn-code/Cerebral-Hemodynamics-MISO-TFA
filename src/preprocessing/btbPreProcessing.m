function processedSignalData = btbPreProcessing( ...
    signalData, fsTarget, preprocessingSettings)

    t_raw = signalData.t;
    map_raw = signalData.map;
    co2_raw = signalData.co2;
    cbv_raw = signalData.cbv;

    %% Clear Blank Entries
    validRows = isfinite(t_raw) & ...
            isfinite(map_raw) & ...
            isfinite(co2_raw) & ...
            isfinite(cbv_raw);

    t_valid = t_raw(validRows);
    map_valid = map_raw(validRows);
    co2_valid = co2_raw(validRows);
    cbv_valid = cbv_raw(validRows);

    %% Remove CO2 Startup Transition
    if any(co2_valid(25:29) == 0)
        warning( ...
            'TFA:Co2StillZeroNearPoint30', ...
            ['CO2 is still zero within the five points before data point 30. ' ...
             'This subject should probably be excluded.']);
    end

    % Find Jumps
    % Sort Ascending
    % Find 90-100% jump + STD
    % Assign Thresshold
    co2Jumps = abs(diff(co2_valid(30:end)));
    sortedCo2Jumps = sort(co2Jumps);
    upperJumpIndex = round(0.9*length(sortedCo2Jumps));
    upperCo2Jumps = sortedCo2Jumps(upperJumpIndex:end);
    co2JumpThreshold = mean(upperCo2Jumps) + std(upperCo2Jumps);

    % Define samples to keep: [0, 0, ..., 0, 1, 1, 1, ..., 1]
    keepSamples = ones(size(co2_valid), 'logical');
    sampleIndex = 1;
    currentJump = abs(co2_valid(sampleIndex + 1) - co2_valid(sampleIndex));

    while co2_valid(sampleIndex) == 0 || ...
            currentJump > co2JumpThreshold
        keepSamples(sampleIndex) = 0;
        sampleIndex = sampleIndex + 1;
        currentJump = abs( ...
            co2_valid(sampleIndex + 1) - co2_valid(sampleIndex));
    end

    % Arrays without start up and transition region
    t_valid = t_valid(keepSamples);
    map_valid = map_valid(keepSamples);
    co2_valid = co2_valid(keepSamples);
    cbv_valid = cbv_valid(keepSamples);

    %% Resample Signals

    dtTarget = 1 / fsTarget;
 
    t_resampled = t_valid(1):dtTarget:t_valid(end);
 
    map_resampled = interp1(t_valid, map_valid, t_resampled, "linear");
    co2_resampled = interp1(t_valid, co2_valid, t_resampled, "linear");
    cbv_resampled = interp1(t_valid, cbv_valid, t_resampled, "linear");

    %% Select CBV Units for Spectral Analysis

    cbvBaselineCmPerSec = mean(cbv_resampled, 'omitnan');

    if preprocessingSettings.normalizeCbv
        cbv_resampled = (cbv_resampled / cbvBaselineCmPerSec) * 100;
        cbvUnits = "% baseline CBV";
    else
        cbvUnits = "cm/s";
    end

    %% Process Signals
    if preprocessingSettings.detrendEnabled
        map_resampled = detrend( ...
            map_resampled, preprocessingSettings.detrendOrder);
        co2_resampled = detrend( ...
            co2_resampled, preprocessingSettings.detrendOrder);
        cbv_resampled = detrend( ...
            cbv_resampled, preprocessingSettings.detrendOrder);
    end

    if preprocessingSettings.meanRemovalEnabled
        map_resampled = map_resampled - mean(map_resampled, 'omitnan');
        co2_resampled = co2_resampled - mean(co2_resampled, 'omitnan');
        cbv_resampled = cbv_resampled - mean(cbv_resampled, 'omitnan');
    end

    
    %% Store Result

    processedSignalData.t   = t_resampled;
    processedSignalData.map = map_resampled;
    processedSignalData.co2 = co2_resampled;
    processedSignalData.cbv = cbv_resampled;
    processedSignalData.fs = fsTarget;
    processedSignalData.cbvBaselineCmPerSec = cbvBaselineCmPerSec;
    processedSignalData.cbvUnits = cbvUnits;

end
