function [coherenceThreshold, thresholdSource] = ...
    ordinaryCoherenceThresholdFromCarnet(numWindows)
% ordinaryCoherenceThresholdFromCarnet Return the CARNET reference value.
%
% This threshold applies to ordinary pairwise coherence. It is used as a
% visual benchmark for the SISO coherence plots, not to filter results.

    carnetWindows = [3, 4, 5, 6, 7, 8, 9, 10, 15, 20, 25];
    carnetThresholds = ...
        [0.51, 0.41, 0.34, 0.29, 0.25, 0.22, 0.20, 0.18, 0.12, 0.09, 0.08];

    exactIndex = find(numWindows == carnetWindows, 1);

    if ~isempty(exactIndex)
        coherenceThreshold = carnetThresholds(exactIndex);
        thresholdSource = "CARNET exact";
    elseif numWindows < carnetWindows(1)
        coherenceThreshold = carnetThresholds(1);
        thresholdSource = "CARNET capped below table";
    elseif numWindows > carnetWindows(end)
        coherenceThreshold = carnetThresholds(end);
        thresholdSource = "CARNET capped above table";
    else
        coherenceThreshold = interp1( ...
            carnetWindows, carnetThresholds, numWindows, "linear");
        thresholdSource = "CARNET interpolated";
    end

end
