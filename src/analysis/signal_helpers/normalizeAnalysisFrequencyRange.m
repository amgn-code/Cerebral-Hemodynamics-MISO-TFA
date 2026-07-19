function analysisSettings = normalizeAnalysisFrequencyRange(analysisSettings)
% normalizeAnalysisFrequencyRange
%
% Validates the user-facing analysis range and makes it the single source of
% truth for plotting limits. Legacy callers that only provide
% plot.frequencyLimitsHz remain supported.

defaultPlot = defaultPlotSettings();

if ~isfield(analysisSettings, 'plot') || isempty(analysisSettings.plot)
    analysisSettings.plot = defaultPlot;
end

if isfield(analysisSettings, 'frequencyRangeHz')
    frequencyRangeHz = analysisSettings.frequencyRangeHz;
elseif isfield(analysisSettings.plot, 'frequencyLimitsHz')
    frequencyRangeHz = analysisSettings.plot.frequencyLimitsHz;
else
    frequencyRangeHz = defaultPlot.frequencyLimitsHz;
end

validateattributes( ...
    frequencyRangeHz, {'numeric'}, ...
    {'real', 'finite', 'vector', 'numel', 2, 'nonnegative'}, ...
    mfilename, 'analysisSettings.frequencyRangeHz');

frequencyRangeHz = double(reshape(frequencyRangeHz, 1, []));

if frequencyRangeHz(1) >= frequencyRangeHz(2)
    error('TFA:InvalidFrequencyRange', ...
        'analysisSettings.frequencyRangeHz must be [lower upper] with lower < upper.');
end

if isfield(analysisSettings, 'frequencyBandEdgesHz')
    frequencyBandEdgesHz = analysisSettings.frequencyBandEdgesHz;
    validateattributes( ...
        frequencyBandEdgesHz, {'numeric'}, ...
        {'real', 'finite', 'vector', 'increasing'}, ...
        mfilename, 'analysisSettings.frequencyBandEdgesHz');

    tolerance = 10 * eps(max([1, abs(frequencyRangeHz)]));

    if frequencyBandEdgesHz(1) < frequencyRangeHz(1) - tolerance || ...
            frequencyBandEdgesHz(end) > frequencyRangeHz(2) + tolerance
        error('TFA:FrequencyBandsOutsideAnalysisRange', ...
            ['All frequencyBandEdgesHz must lie inside frequencyRangeHz. ' ...
             'Current range is [%.6g %.6g] Hz.'], ...
            frequencyRangeHz(1), frequencyRangeHz(2));
    end
end

analysisSettings.frequencyRangeHz = frequencyRangeHz;
analysisSettings.plot.frequencyLimitsHz = frequencyRangeHz;

end
