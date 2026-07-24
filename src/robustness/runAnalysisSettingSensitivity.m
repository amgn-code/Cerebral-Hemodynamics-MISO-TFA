function sensitivityResults = runAnalysisSettingSensitivity( ...
    analysisInput, analysisSettings, variants)
% runAnalysisSettingSensitivity Refit models under analysis alternatives.

    if nargin < 3
        variants = defaultSensitivityVariants();
    end

    allRows = table();
    runLog = table();

    for variantIndex = 1:numel(variants)
        variant = variants(variantIndex);
        currentSettings = analysisSettings;
        map = analysisInput.map(:);
        co2 = analysisInput.co2(:);
        cbv = analysisInput.cbv(:);
        fs = analysisInput.fs;

        try
            if isfinite(variant.samplingFrequencyHz) && ...
                    variant.samplingFrequencyHz ~= fs
                targetFs = variant.samplingFrequencyHz;
                map = resample(map, targetFs, fs);
                co2 = resample(co2, targetFs, fs);
                cbv = resample(cbv, targetFs, fs);
                fs = targetFs;
            end

            if isfinite(variant.detrendOrder)
                map = detrend(map, variant.detrendOrder);
                co2 = detrend(co2, variant.detrendOrder);
                cbv = detrend(cbv, variant.detrendOrder);
            end
            if isfinite(variant.welchWindowLengthSeconds)
                currentSettings.pwelch.windowLengthSeconds = ...
                    variant.welchWindowLengthSeconds;
            end
            if ~isempty(variant.smoothingEnabled)
                currentSettings.pwelch.smoothingEnabled = ...
                    variant.smoothingEnabled;
            end
            if ~isempty(variant.smoothingKernel)
                currentSettings.pwelch.smoothingKernel = ...
                    variant.smoothingKernel;
            end

            comparison = runModelComparisonForSignals( ...
                map, co2, cbv, fs, currentSettings);
            currentRows = summarizeGainModelComparisonByBand( ...
                comparison, currentSettings);
            currentRows.Variant = repmat( ...
                string(variant.name), height(currentRows), 1);
            allRows = [allRows; currentRows];
            status = "Completed";
            message = "";
        catch errorInfo
            status = "Failed";
            message = string(errorInfo.message);
        end

        runLog = [runLog; table( ...
            string(variant.name), status, message, fs, ...
            currentSettings.pwelch.windowLengthSeconds, ...
            currentSettings.pwelch.smoothingEnabled, ...
            'VariableNames', { ...
                'Variant', 'Status', 'Message', 'SamplingFrequencyHz', ...
                'WelchWindowLengthSeconds', 'SmoothingEnabled'})];
    end

    sensitivityResults.summary = allRows;
    sensitivityResults.runLog = runLog;
    sensitivityResults.variants = variants;

end
