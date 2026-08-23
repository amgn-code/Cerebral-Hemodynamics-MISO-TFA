function statistics = calculateSimulationAdvantageStatistics( ...
    values, alpha, minimumValidN)
% calculateSimulationAdvantageStatistics Test mean model advantage vs zero.
%
% One value represents the paired SISO-versus-MISO comparison from one
% simulated family. Positive values favor MISO and negative values favor
% SISO. The one-sample test is therefore the paired model comparison.

    if nargin < 2 || isempty(alpha)
        alpha = 0.05;
    end
    if nargin < 3 || isempty(minimumValidN)
        minimumValidN = 3;
    end

    values = values(isfinite(values));
    statistics.mean = NaN;
    statistics.sd = NaN;
    statistics.standardError = NaN;
    statistics.ciLower = NaN;
    statistics.ciUpper = NaN;
    statistics.rawP = NaN;
    statistics.validN = numel(values);

    if isempty(values)
        return
    end

    statistics.mean = mean(values);
    statistics.sd = std(values, 0);

    if statistics.validN < minimumValidN
        return
    end

    statistics.standardError = ...
        statistics.sd/sqrt(statistics.validN);

    if statistics.sd == 0
        statistics.ciLower = statistics.mean;
        statistics.ciUpper = statistics.mean;
        if statistics.mean == 0
            statistics.rawP = 1;
        else
            statistics.rawP = 0;
        end
        return
    end

    [~, statistics.rawP, confidenceInterval] = ...
        ttest(values, 0, "Alpha", alpha);
    statistics.ciLower = confidenceInterval(1);
    statistics.ciUpper = confidenceInterval(2);

end
