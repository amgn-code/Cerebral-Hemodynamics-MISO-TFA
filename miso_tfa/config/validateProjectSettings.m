function settings = validateProjectSettings(settings)
% validateProjectSettings Validate the small project-level configuration.

    validateattributes( ...
        settings.samplingFrequencyHz, {'numeric'}, ...
        {'scalar', 'finite', 'positive'});

    reportingBand = double(reshape( ...
        settings.analysis.reportingBandHz, 1, []));
    calibrationBand = double(reshape( ...
        settings.analysis.pathwayCalibrationBandHz, 1, []));
    nyquist = settings.samplingFrequencyHz/2;
    validateBand(reportingBand, nyquist, "reportingBandHz");
    validateBand(calibrationBand, nyquist, "pathwayCalibrationBandHz");

    edges = double(settings.analysis.frequencyBandEdgesHz(:));
    names = string(settings.analysis.frequencyBandNames(:));
    if numel(edges) ~= numel(names) + 1 || ...
            any(~isfinite(edges)) || any(diff(edges) <= 0) || ...
            edges(1) < reportingBand(1) || edges(end) > reportingBand(2)
        error( ...
            "TFA:InvalidProjectFrequencyBands", ...
            "Frequency-band edges must increase and lie inside the reporting band.");
    end

    settings.samplingFrequencyHz = double(settings.samplingFrequencyHz);
    settings.analysis.reportingBandHz = reportingBand;
    settings.analysis.pathwayCalibrationBandHz = calibrationBand;
    settings.analysis.frequencyBandEdgesHz = edges;
    settings.analysis.frequencyBandNames = names;
    settings.analysis.nyquistFrequencyHz = nyquist;

end

function validateBand(band, nyquist, fieldName)
% validateBand Validate one two-element frequency interval.

    if numel(band) ~= 2 || any(~isfinite(band)) || ...
            band(1) < 0 || band(1) >= band(2) || band(2) > nyquist
        error( ...
            "TFA:InvalidProjectFrequencyBand", ...
            "%s must be an increasing interval inside [0, Nyquist].", ...
            fieldName);
    end

end
