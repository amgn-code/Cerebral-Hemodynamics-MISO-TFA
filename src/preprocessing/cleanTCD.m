function [cleanTable, info] = cleanTCD(filename, makePlot)
% cleanTCD
%
% Conservative TCD artifact cleaning.
%
% Steps:
%   1. Mark near-zero signal loss.
%   2. Mark very high values using a robust median/MAD threshold.
%   3. Mark only large local spike artifacts.
%   4. Interpolate short artifact gaps.

    if nargin < 1 || isempty(filename)
        filename = "/Users/amoghn/Downloads/547_baseline.xlsx";
    end

    if nargin < 2
        makePlot = true;
    end

    %% Settings

    minTCD = 5;
    maxTCD = 200;

    globalThresholdFactor = 6;
    spikeThresholdFactor = 12;
    minLocalScale = 5;

    spikeWindow_s = 0.50;
    maxGap_s = 0.10;

    %% Load data

    dataTable = readtable(filename, "VariableNamingRule", "preserve");

    t = double(dataTable.Time);
    tcdRaw = double(dataTable.TCD);

    validRows = ~isnan(t) & ~isnan(tcdRaw);
    cleanTable = dataTable(validRows, :);
    t = t(validRows);
    tcdRaw = tcdRaw(validRows);

    [t, sortIdx] = sort(t);
    cleanTable = cleanTable(sortIdx, :);
    tcdRaw = tcdRaw(sortIdx);

    [t, uniqueIdx] = unique(t, "stable");
    cleanTable = cleanTable(uniqueIdx, :);
    tcdRaw = tcdRaw(uniqueIdx);

    fsRaw = (numel(t) - 1) / (t(end) - t(1));

    spikeWindow_n = max(3, round(spikeWindow_s * fsRaw));
    maxGap_n = max(1, round(maxGap_s * fsRaw));

    %% Range artifacts

    lowSignalArtifact = tcdRaw < minTCD;

    tcdReference = tcdRaw(tcdRaw >= minTCD & tcdRaw <= maxTCD);
    globalMedian = median(tcdReference, "omitnan");
    globalScale = 1.4826 * median(abs(tcdReference - globalMedian), "omitnan");

    adaptiveMaxTCD = globalMedian + globalThresholdFactor * globalScale;
    upperTCDLimit = min(maxTCD, adaptiveMaxTCD);

    highRangeArtifact = tcdRaw > upperTCDLimit;
    rangeArtifact = lowSignalArtifact | highRangeArtifact;

    %% Local spike artifacts

    tcdForSpikeDetection = tcdRaw;
    tcdForSpikeDetection(rangeArtifact) = NaN;

    localMedian = movmedian(tcdForSpikeDetection, spikeWindow_n, "omitnan");
    residual = abs(tcdForSpikeDetection - localMedian);

    localScale = 1.4826 * movmedian(residual, spikeWindow_n, "omitnan");
    localScale = max(localScale, minLocalScale);

    spikeArtifact = residual > spikeThresholdFactor * localScale;
    spikeArtifact(isnan(spikeArtifact)) = false;

    artifact = rangeArtifact | spikeArtifact;

    %% Clean signal

    tcdClean = tcdRaw;
    tcdClean(artifact) = NaN;
    tcdClean = fillShortNaNGaps(t, tcdClean, maxGap_n);

    cleanTable.TCD_Clean = tcdClean;
    cleanTable.TCD_LowSignalArtifact = lowSignalArtifact;
    cleanTable.TCD_HighRangeArtifact = highRangeArtifact;
    cleanTable.TCD_RangeArtifact = rangeArtifact;
    cleanTable.TCD_SpikeArtifact = spikeArtifact;
    cleanTable.TCD_Artifact = artifact;

    %% Store summary

    info = struct();
    info.filename = string(filename);
    info.numSamples = numel(tcdRaw);
    info.durationSeconds = t(end) - t(1);
    info.estimatedFs = fsRaw;
    info.upperTCDLimit = upperTCDLimit;
    info.numLowSignalArtifacts = sum(lowSignalArtifact);
    info.numHighRangeArtifacts = sum(highRangeArtifact);
    info.numSpikeArtifacts = sum(spikeArtifact);
    info.numTotalArtifacts = sum(artifact);
    info.percentArtifacts = 100 * mean(artifact);

    %% Plot

    if makePlot
        figure("Name", "TCD Cleaning Diagnostics", "NumberTitle", "off")

        plot(t, tcdRaw, "Color", [0.7 0.7 0.7])
        hold on
        plot(t, tcdClean, "b", "LineWidth", 1.0)
        plot(t(rangeArtifact), tcdRaw(rangeArtifact), "r.", "MarkerSize", 8)
        plot(t(spikeArtifact), tcdRaw(spikeArtifact), "m.", "MarkerSize", 8)

        xlabel("Time (s)")
        ylabel("TCD")
        title("TCD Artifact Cleaning")
        legend("Raw TCD", "Cleaned TCD", ...
            "Range artifact", "Spike artifact", ...
            "Location", "best")
        grid on
    end

end


function xFilled = fillShortNaNGaps(t, x, maxGap_n)

    xFilled = x;
    missing = isnan(x);

    gapStart = find(diff([false; missing(:)]) == 1);
    gapEnd = find(diff([missing(:); false]) == -1);

    for k = 1:numel(gapStart)
        idx = gapStart(k):gapEnd(k);

        if numel(idx) > maxGap_n
            continue
        end

        leftIdx = gapStart(k) - 1;
        rightIdx = gapEnd(k) + 1;

        if leftIdx < 1 || rightIdx > numel(x)
            continue
        end

        xFilled(idx) = interp1( ...
            t([leftIdx; rightIdx]), ...
            x([leftIdx; rightIdx]), ...
            t(idx), ...
            "linear");
    end

end
