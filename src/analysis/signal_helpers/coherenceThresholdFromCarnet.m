function [coherenceThreshold, thresholdInfo] = coherenceThresholdFromCarnet(numWindows)
% coherenceThresholdFromCarnet Interpolate CARNET coherence thresholds.

carnetWindows = [3, 4, 5, 6, 7, 8, 9, 10, 15, 20, 25];
carnetThresholds = [0.51, 0.41, 0.34, 0.29, 0.25, 0.22, 0.20, 0.18, 0.12, 0.09, 0.08];

thresholdInfo = struct();
thresholdInfo.source = "";
thresholdInfo.numWindows = numWindows;
thresholdInfo.referenceWindows = carnetWindows;
thresholdInfo.referenceThresholds = carnetThresholds;

exactIndex = find(numWindows == carnetWindows, 1);

if ~isempty(exactIndex)
    coherenceThreshold = carnetThresholds(exactIndex);
    thresholdInfo.source = "CARNET exact";
elseif numWindows < min(carnetWindows)
    coherenceThreshold = carnetThresholds(1);
    thresholdInfo.source = "CARNET capped below table";
elseif numWindows > max(carnetWindows)
    coherenceThreshold = carnetThresholds(end);
    thresholdInfo.source = "CARNET capped above table";
else
    coherenceThreshold = interp1( ...
        carnetWindows, carnetThresholds, numWindows, "linear");
    thresholdInfo.source = "CARNET interpolated";
end

end
