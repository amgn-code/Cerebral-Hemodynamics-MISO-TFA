function characterization = characterizeNcInputs(dataFolder, settings)
% characterizeNcInputs Measure the NC input relationships used by simulation.
%
% This is a descriptive NC audit. It does not tune the blocked-validation
% estimator and it does not use CBFV to select simulation factors. Each
% recording is preprocessed with the same acquisition cleanup as the NC
% validation page, then MAP/PETCO2 spectra are summarized over the frozen
% 0.02-0.35 Hz reporting band.

    if nargin < 1 || isempty(dataFolder)
        error("TFA:MissingNCDataFolder", ...
            "Provide the folder that contains the NC subfolder.");
    end
    if nargin < 2 || isempty(settings)
        settings = defaultNcBootstrapSettings();
    end

    subjectList = findIEEMSubjects(dataFolder, settings.group);
    numSubjects = height(subjectList);
    subjectResults = repmat(emptySubjectResult(), numSubjects, 1);
    frequencyHz = [];
    coherenceMatrix = [];
    phaseMatrix = [];
    powerMapMatrix = [];
    powerCo2Matrix = [];
    thresholdMatrix = [];

    for subjectIndex = 1:numSubjects
        subjectInfo = subjectList(subjectIndex, :);
        subjectResults(subjectIndex).subjectID = ...
            string(subjectInfo.SubjectID);
        subjectResults(subjectIndex).sourceFile = ...
            string(subjectInfo.SourceFile);
        try
            signalData = loadSubjectData(subjectInfo.SourceFile);
            preprocessingSettings = settings.analysis.preprocessing;
            preprocessingSettings.normalizeCbv = false;
            preprocessingSettings.meanRemovalEnabled = false;
            preprocessingSettings.detrendEnabled = false;
            processed = preprocessTfaSignals( ...
                signalData, settings.analysis.fsTarget, ...
                preprocessingSettings);
            spectra = estimateWelchSpectra( ...
                processed.map, processed.co2, processed.cbv, ...
                settings.analysis.fsTarget, settings.analysis.pwelch);

            baseMask = spectra.f >= settings.analysis.frequencyRangeHz(1) & ...
                spectra.f <= min( ...
                settings.analysis.frequencyRangeHz(2), ...
                processed.quality.nativeNyquistFrequencyHz);
            mapPower = max(real(spectra.map.power), eps);
            co2Power = max(real(spectra.co2.power), eps);
            coherence = abs(spectra.cross.mapCo2).^2 ./ ...
                max(mapPower.*co2Power, eps);
            coherence = min(1, max(0, real(coherence)));
            [threshold, thresholdSource] = ...
                ordinaryCoherenceThresholdFromCarnet( ...
                spectra.welchInfo.effectiveAverages);
            phaseWrapped = angle(spectra.cross.mapCo2);
            phaseUnwrapped = unwrap(phaseWrapped);
            phaseMask = baseMask & coherence >= threshold & ...
                isfinite(phaseUnwrapped);

            if isempty(frequencyHz)
                frequencyHz = spectra.f(:);
                coherenceMatrix = NaN(numSubjects, numel(frequencyHz));
                phaseMatrix = NaN(numSubjects, numel(frequencyHz));
                powerMapMatrix = NaN(numSubjects, numel(frequencyHz));
                powerCo2Matrix = NaN(numSubjects, numel(frequencyHz));
                thresholdMatrix = NaN(numSubjects, numel(frequencyHz));
            elseif numel(spectra.f) ~= numel(frequencyHz) || ...
                    any(spectra.f(:) ~= frequencyHz)
                error("TFA:NCInputFrequencyGridMismatch", ...
                    "NC input characterization used inconsistent frequency grids.");
            end

            coherenceMatrix(subjectIndex, :) = coherence(:).';
            phaseValues = phaseUnwrapped(:);
            phaseValues(~phaseMask) = NaN;
            phaseMatrix(subjectIndex, :) = phaseValues.';
            powerMapMatrix(subjectIndex, :) = ...
                10*log10(mapPower(:)).';
            powerCo2Matrix(subjectIndex, :) = ...
                10*log10(co2Power(:)).';
            thresholdMatrix(subjectIndex, :) = threshold;

            bandCoherence = coherence(baseMask);
            validBandCoherence = bandCoherence(isfinite(bandCoherence));
            subjectResults(subjectIndex).status = "Completed";
            subjectResults(subjectIndex).statusMessage = "Completed";
            subjectResults(subjectIndex).recordingDurationSeconds = ...
                numel(processed.map)/settings.analysis.fsTarget;
            subjectResults(subjectIndex).nativeNyquistFrequencyHz = ...
                processed.quality.nativeNyquistFrequencyHz;
            subjectResults(subjectIndex).effectiveWelchAverages = ...
                spectra.welchInfo.effectiveAverages;
            subjectResults(subjectIndex).coherenceThreshold = threshold;
            subjectResults(subjectIndex).coherenceThresholdSource = ...
                string(thresholdSource);
            subjectResults(subjectIndex).validPhaseBinCount = nnz(phaseMask);
            subjectResults(subjectIndex).bandMeanCoherence = ...
                mean(validBandCoherence, "omitnan");

            validPhase = phaseMask & isfinite(frequencyHz(:));
            if nnz(validPhase) >= 3
                phaseFit = polyfit(frequencyHz(validPhase), ...
                    phaseUnwrapped(validPhase), 1);
                fittedPhase = polyval(phaseFit, frequencyHz(validPhase));
                residual = phaseUnwrapped(validPhase) - fittedPhase;
                total = phaseUnwrapped(validPhase) - ...
                    mean(phaseUnwrapped(validPhase));
                totalSquared = sum(total.^2);
                if totalSquared > 0
                    fitR2 = 1 - sum(residual.^2)/totalSquared;
                else
                    fitR2 = NaN;
                end
                subjectResults(subjectIndex).phaseLagSeconds = ...
                    -phaseFit(1)/(2*pi);
                subjectResults(subjectIndex).phaseLagFitR2 = fitR2;
            end
            subjectResults(subjectIndex).mapPowerMedianDb = ...
                median(powerMapMatrix(subjectIndex, baseMask), "omitnan");
            subjectResults(subjectIndex).co2PowerMedianDb = ...
                median(powerCo2Matrix(subjectIndex, baseMask), "omitnan");
            subjectResults(subjectIndex).frequencyHz = frequencyHz;
        catch errorInfo
            subjectResults(subjectIndex).status = "Failed";
            subjectResults(subjectIndex).statusMessage = string(errorInfo.message);
        end
    end

    completed = string({subjectResults.status}).' == "Completed";
    if isempty(frequencyHz) || ~any(completed)
        error("TFA:NoCompletedNCInputCharacterization", ...
            "No NC recording completed input characterization.");
    end

    reportingMask = frequencyHz >= settings.analysis.frequencyRangeHz(1) & ...
        frequencyHz <= settings.analysis.frequencyRangeHz(2);
    coherenceSummary = summarizeCoherence( ...
        frequencyHz, coherenceMatrix, thresholdMatrix, reportingMask, ...
        subjectResults, completed);
    phaseSummary = summarizePhase( ...
        frequencyHz, phaseMatrix, thresholdMatrix, reportingMask, ...
        subjectResults, completed);
    powerSummary = summarizePower( ...
        frequencyHz, powerMapMatrix, powerCo2Matrix, reportingMask, completed);

    characterization.dataFolder = string(dataFolder);
    characterization.group = string(settings.group);
    characterization.settings = settings;
    characterization.subjectList = subjectList;
    characterization.subjectResults = subjectResults;
    characterization.subjectTable = createSubjectTable(subjectResults);
    characterization.frequencyHz = frequencyHz;
    characterization.coherence = coherenceSummary;
    characterization.phase = phaseSummary;
    characterization.power = powerSummary;
    characterization.statusTable = createStatusTable(subjectResults);

end

function result = emptySubjectResult()
    result = struct( ...
        "subjectID", "", "sourceFile", "", "status", "NotStarted", ...
        "statusMessage", "", "recordingDurationSeconds", NaN, ...
        "nativeNyquistFrequencyHz", NaN, "effectiveWelchAverages", NaN, ...
        "coherenceThreshold", NaN, "coherenceThresholdSource", "", ...
        "validPhaseBinCount", 0, "bandMeanCoherence", NaN, ...
        "phaseLagSeconds", NaN, "phaseLagFitR2", NaN, ...
        "mapPowerMedianDb", NaN, "co2PowerMedianDb", NaN, ...
        "frequencyHz", []);
end

function summary = summarizeCoherence( ...
    frequencyHz, coherenceMatrix, thresholdMatrix, reportingMask, ...
    subjectResults, completed)
    valid = isfinite(coherenceMatrix) & reportingMask(:).';
    frequencyMean = rowMean(coherenceMatrix, valid);
    frequencyMedian = rowMedian(coherenceMatrix, valid);
    frequencySd = rowStd(coherenceMatrix, valid);
    frequencyMean = frequencyMean(:);
    frequencyMedian = frequencyMedian(:);
    frequencySd = frequencySd(:);
    validN = sum(valid, 1).';
    thresholdMean = rowMean(thresholdMatrix, valid);
    thresholdMean = thresholdMean(:);
    subjectValues = [subjectResults(completed).bandMeanCoherence].';
    subjectValues = subjectValues(isfinite(subjectValues));
    selected = reportingMask(:);
    summary.frequencyTable = table( ...
        frequencyHz(selected), frequencyMean(selected), ...
        frequencyMedian(selected), frequencySd(selected), ...
        validN(selected), thresholdMean(selected), ...
        'VariableNames', {'FrequencyHz', 'MeanCoherence', ...
        'MedianCoherence', 'SDCoherence', 'ValidSubjectN', ...
        'MeanCARNetThreshold'});
    summary.subjectBandMeanCoherence = subjectValues;
    summary.subjectQuantiles = percentileOrNan(subjectValues, [10 50 90]);
    summary.suggestedCoreLevels = [0 summary.subjectQuantiles(1:3)];
end

function summary = summarizePhase( ...
    frequencyHz, phaseMatrix, thresholdMatrix, reportingMask, ...
    subjectResults, completed)
    valid = isfinite(phaseMatrix) & reportingMask(:).';
    validN = sum(valid, 1).';
    circularMean = NaN(size(frequencyHz));
    circularSd = NaN(size(frequencyHz));
    for frequencyIndex = 1:numel(frequencyHz)
        values = phaseMatrix(valid(:, frequencyIndex), frequencyIndex);
        if isempty(values)
            continue
        end
        circularMean(frequencyIndex) = angle(mean(exp(1i*values)));
        circularSd(frequencyIndex) = sqrt(max(0, ...
            -2*log(abs(mean(exp(1i*values))))));
    end
    subjectLag = [subjectResults(completed).phaseLagSeconds].';
    subjectLag = subjectLag(isfinite(subjectLag));
    subjectR2 = [subjectResults(completed).phaseLagFitR2].';
    subjectR2 = subjectR2(isfinite(subjectR2));
    selected = reportingMask(:);
    summary.frequencyTable = table( ...
        frequencyHz(selected), rad2deg(circularMean(selected)), ...
        rad2deg(circularSd(selected)), validN(selected), ...
        'VariableNames', {'FrequencyHz', 'CircularMeanPhaseDegrees', ...
        'CircularSDPhaseDegrees', 'ValidSubjectN'});
    summary.subjectLagSeconds = subjectLag;
    summary.subjectLagQuantilesSeconds = ...
        percentileOrNan(subjectLag, [10 50 90]);
    summary.subjectLagFitR2 = subjectR2;
    summary.medianLagFitR2 = median(subjectR2, "omitnan");
    summary.singleLagInterpretation = ...
        isfinite(summary.medianLagFitR2) && summary.medianLagFitR2 >= 0.5;
    summary.provisionalSecondaryLevelsSeconds = [-4 0 4];
end

function summary = summarizePower( ...
    frequencyHz, mapPowerMatrix, co2PowerMatrix, reportingMask, completed)
    mapValues = mapPowerMatrix;
    co2Values = co2PowerMatrix;
    mapValues(~completed, :) = NaN;
    co2Values(~completed, :) = NaN;
    mapValues(:, ~reportingMask) = NaN;
    co2Values(:, ~reportingMask) = NaN;
    selected = reportingMask(:);
    mapMean = rowMean(mapValues, isfinite(mapValues));
    mapMedian = rowMedian(mapValues, isfinite(mapValues));
    mapSd = rowStd(mapValues, isfinite(mapValues));
    co2Mean = rowMean(co2Values, isfinite(co2Values));
    co2Median = rowMedian(co2Values, isfinite(co2Values));
    co2Sd = rowStd(co2Values, isfinite(co2Values));
    mapMean = mapMean(:);
    mapMedian = mapMedian(:);
    mapSd = mapSd(:);
    co2Mean = co2Mean(:);
    co2Median = co2Median(:);
    co2Sd = co2Sd(:);
    validN = sum(isfinite(mapValues), 1).';
    summary.frequencyTable = table( ...
        frequencyHz(selected), mapMean(selected), ...
        mapMedian(selected), mapSd(selected), ...
        co2Mean(selected), co2Median(selected), co2Sd(selected), ...
        validN(selected), ...
        'VariableNames', {'FrequencyHz', 'MAPPowerMeanDb', ...
        'MAPPowerMedianDb', 'MAPPowerSDDb', 'CO2PowerMeanDb', ...
        'CO2PowerMedianDb', 'CO2PowerSDDb', 'ValidSubjectN'});
    summary.units = "dB relative to 1 signal-unit-squared per Hz";
end

function tableOut = createSubjectTable(subjectResults)
    tableOut = table( ...
        string({subjectResults.subjectID}).', ...
        string({subjectResults.status}).', ...
        string({subjectResults.statusMessage}).', ...
        [subjectResults.recordingDurationSeconds].', ...
        [subjectResults.nativeNyquistFrequencyHz].', ...
        [subjectResults.effectiveWelchAverages].', ...
        [subjectResults.coherenceThreshold].', ...
        [subjectResults.validPhaseBinCount].', ...
        [subjectResults.bandMeanCoherence].', ...
        [subjectResults.phaseLagSeconds].', ...
        [subjectResults.phaseLagFitR2].', ...
        [subjectResults.mapPowerMedianDb].', ...
        [subjectResults.co2PowerMedianDb].', ...
        'VariableNames', {'SubjectID', 'Status', 'StatusMessage', ...
        'RecordingDurationSeconds', 'NativeNyquistFrequencyHz', ...
        'EffectiveWelchAverages', 'CARNetThreshold', 'ValidPhaseBinCount', ...
        'BandMeanCoherence', 'PhaseLagSeconds', 'PhaseLagFitR2', ...
        'MAPPowerMedianDb', 'CO2PowerMedianDb'});
end

function tableOut = createStatusTable(subjectResults)
    tableOut = table( ...
        string({subjectResults.subjectID}).', ...
        string({subjectResults.status}).', ...
        string({subjectResults.statusMessage}).', ...
        'VariableNames', {'SubjectID', 'Status', 'StatusMessage'});
end

function values = rowMean(matrix, valid)
    values = NaN(1, size(matrix, 2));
    for index = 1:size(matrix, 2)
        current = matrix(valid(:, index), index);
        if ~isempty(current)
            values(index) = mean(current, "omitnan");
        end
    end
end

function values = rowMedian(matrix, valid)
    values = NaN(1, size(matrix, 2));
    for index = 1:size(matrix, 2)
        current = matrix(valid(:, index), index);
        if ~isempty(current)
            values(index) = median(current, "omitnan");
        end
    end
end

function values = rowStd(matrix, valid)
    values = NaN(1, size(matrix, 2));
    for index = 1:size(matrix, 2)
        current = matrix(valid(:, index), index);
        if numel(current) >= 2
            values(index) = std(current, 0, "omitnan");
        end
    end
end

function values = percentileOrNan(data, percentiles)
    if isempty(data)
        values = NaN(size(percentiles));
    else
        values = prctile(data, percentiles);
    end
end
