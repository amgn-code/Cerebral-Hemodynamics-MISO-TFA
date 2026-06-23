function [beatTable, info] = computeBeatToBeatAverages(inputData, exportExcel, outputFile, makePlot)
% computeBeatToBeatAverages
%
% Uses ECG R-peaks to define each beat. MAP, TCD, and ETCO2 are averaged
% from one R-peak to the next. The beat timestamp is the midpoint between
% the two R-peaks.
%
% Examples:
%   [cleanTable, ~] = cleanTCD("/Users/amoghn/Downloads/547_baseline.xlsx");
%   [beatTable, info] = computeBeatToBeatAverages(cleanTable);
%   [beatTable, info] = computeBeatToBeatAverages(cleanTable, true);

    if nargin < 2
        exportExcel = false;
    end

    if nargin < 3 || isempty(outputFile)
        outputFile = "beat_to_beat_results.xlsx";
    end

    if nargin < 4
        makePlot = true;
    end

    %% Settings

    minHeartRate = 40;
    maxHeartRate = 180;

    ecgBaselineWindow_s = 0.60;
    peakThresholdFactor = 5;

    %% Load data

    if istable(inputData)
        dataTable = inputData;
    else
        dataTable = readtable(inputData, "VariableNamingRule", "preserve");
    end

    t = double(dataTable.Time);
    ecg = double(dataTable.ECG);
    map = double(dataTable.BP);
    etco2Raw = double(dataTable.ETCO2);
    peakETCO2 = double(dataTable{:,"Peak ETCO2"});

    if any(string(dataTable.Properties.VariableNames) == "TCD_Clean")
        tcd = double(dataTable.TCD_Clean);
        tcdColumnUsed = "TCD_Clean";
    else
        tcd = double(dataTable.TCD);
        tcdColumnUsed = "TCD";
    end

    validRows = ~isnan(t) & ~isnan(ecg);

    t = t(validRows);
    ecg = ecg(validRows);
    map = map(validRows);
    tcd = tcd(validRows);
    etco2Raw = etco2Raw(validRows);
    peakETCO2 = peakETCO2(validRows);

    [t, sortIdx] = sort(t);
    ecg = ecg(sortIdx);
    map = map(sortIdx);
    tcd = tcd(sortIdx);
    etco2Raw = etco2Raw(sortIdx);
    peakETCO2 = peakETCO2(sortIdx);

    [t, uniqueIdx] = unique(t, "stable");
    ecg = ecg(uniqueIdx);
    map = map(uniqueIdx);
    tcd = tcd(uniqueIdx);
    etco2Raw = etco2Raw(uniqueIdx);
    peakETCO2 = peakETCO2(uniqueIdx);

    fsRaw = (numel(t) - 1) / (t(end) - t(1));

    %% ECG R-peak detection

    ecgFilled = fillmissing(ecg, "linear");
    ecgFilled = fillmissing(ecgFilled, "nearest");

    baselineWindow_n = round(ecgBaselineWindow_s * fsRaw);
    ecgDetrended = ecgFilled - movmedian(ecgFilled, baselineWindow_n, "omitnan");

    centerValue = median(ecgDetrended, "omitnan");
    positiveRange = max(ecgDetrended, [], "omitnan") - centerValue;
    negativeRange = centerValue - min(ecgDetrended, [], "omitnan");

    if negativeRange > positiveRange
        ecgForPeaks = -ecgDetrended;
    else
        ecgForPeaks = ecgDetrended;
    end

    ecgScale = 1.4826 * median( ...
        abs(ecgForPeaks - median(ecgForPeaks, "omitnan")), ...
        "omitnan");

    minPeakProminence = peakThresholdFactor * ecgScale;
    minPeakDistance = round((60 / maxHeartRate) * fsRaw);

    [~, rPeakIdx] = findpeaks(ecgForPeaks, ...
        "MinPeakDistance", minPeakDistance, ...
        "MinPeakProminence", minPeakProminence);

    rPeakTimes = t(rPeakIdx);
    rrIntervals = diff(rPeakTimes);

    minRR = 60 / maxHeartRate;
    maxRR = 60 / minHeartRate;
    validBeat = rrIntervals >= minRR & rrIntervals <= maxRR;

    %% Beat-to-beat averages

    numBeats = sum(validBeat);

    beatTime = NaN(numBeats, 1);
    beatStartTime = NaN(numBeats, 1);
    beatEndTime = NaN(numBeats, 1);
    rr = NaN(numBeats, 1);
    heartRate = NaN(numBeats, 1);

    mapBeat = NaN(numBeats, 1);
    tcdBeat = NaN(numBeats, 1);
    etco2Beat = NaN(numBeats, 1);
    etco2ProcessedBeat = NaN(numBeats, 1);

    outIdx = 0;

    for k = 1:numel(validBeat)

        if ~validBeat(k)
            continue
        end

        outIdx = outIdx + 1;

        startIdx = rPeakIdx(k);
        endIdx = rPeakIdx(k + 1) - 1;

        beatStartTime(outIdx) = rPeakTimes(k);
        beatEndTime(outIdx) = rPeakTimes(k + 1);
        beatTime(outIdx) = mean([beatStartTime(outIdx), beatEndTime(outIdx)]);

        rr(outIdx) = rrIntervals(k);
        heartRate(outIdx) = 60 / rr(outIdx);

        mapBeat(outIdx) = mean(map(startIdx:endIdx), "omitnan");
        tcdBeat(outIdx) = mean(tcd(startIdx:endIdx), "omitnan");
        etco2Beat(outIdx) = mean(etco2Raw(startIdx:endIdx), "omitnan");

        % This mimics the plateau-transition-plateau behavior seen in
        % processed ETCO2 exports.
        etco2ProcessedBeat(outIdx) = mean( ...
            peakETCO2(startIdx:endIdx), "omitnan");

    end

    beatTable = table( ...
        beatTime, ...
        beatStartTime, ...
        beatEndTime, ...
        rr, ...
        heartRate, ...
        mapBeat, ...
        tcdBeat, ...
        etco2Beat, ...
        etco2ProcessedBeat, ...
        'VariableNames', { ...
            'BeatTime', ...
            'BeatStartTime', ...
            'BeatEndTime', ...
            'RRInterval', ...
            'HeartRate_bpm', ...
            'MAP', ...
            'TCD', ...
            'ETCO2', ...
            'ETCO2_Interpolated' ...
        });

    %% Store summary

    info = struct();
    info.estimatedFs = fsRaw;
    info.numSamples = numel(t);
    info.durationSeconds = t(end) - t(1);
    info.numDetectedRPeaks = numel(rPeakIdx);
    info.numCandidateBeats = numel(validBeat);
    info.numValidBeats = numBeats;
    info.numRejectedBeats = sum(~validBeat);
    info.minPeakProminence = minPeakProminence;
    info.tcdColumnUsed = tcdColumnUsed;
    info.timestampConvention = ...
        "BeatTime is the midpoint between consecutive ECG R-peaks.";

    %% Export

    if exportExcel
        writetable(beatTable, outputFile, "Sheet", "BeatToBeatAverages");
    end

    %% Plot

    if makePlot
        figure("Name", "ECG Beat Detection", "NumberTitle", "off")
        plot(t, ecgForPeaks)
        hold on
        plot(rPeakTimes, ecgForPeaks(rPeakIdx), "r.", "MarkerSize", 10)
        xlabel("Time (s)")
        ylabel("Processed ECG")
        title("ECG R-Peak Detection")
        legend("Processed ECG", "Detected R-peaks", "Location", "best")
        grid on

        figure("Name", "Beat-to-Beat Averages", "NumberTitle", "off")

        subplot(4,1,1)
        plot(beatTable.BeatTime, beatTable.MAP, ".-")
        ylabel("MAP")
        title("Beat-to-Beat MAP")
        grid on

        subplot(4,1,2)
        plot(beatTable.BeatTime, beatTable.TCD, ".-")
        ylabel("TCD")
        title("Beat-to-Beat TCD")
        grid on

        subplot(4,1,3)
        plot(beatTable.BeatTime, beatTable.ETCO2, ".-")
        ylabel("ETCO2")
        title("Beat-to-Beat ETCO2 Mean")
        grid on

        subplot(4,1,4)
        plot(beatTable.BeatTime, beatTable.ETCO2_Interpolated, ".-")
        xlabel("Time (s)")
        ylabel("ETCO2")
        title("Processed ETCO2 Averaged Over Each Beat")
        grid on

        sgtitle("Beat-to-Beat Averaged Signals")
    end

end
