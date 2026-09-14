function settings = completeSimulationOutputSettings(settings)
% completeSimulationOutputSettings Fill and validate output controls.

    if ~isstruct(settings)
        error( ...
            "TFA:InvalidSimulationOutputSettings", ...
            "Simulation output settings must be a structure.");
    end

    defaults = baseDefaults();
    settings = fillFields(settings, defaults);
    settings.bootstrap = fillFields( ...
        settings.bootstrap, defaults.bootstrap);

    logicalFields = [ ...
        "createFigures", "savePng", "saveCsv", "saveMat"];
    for fieldName = logicalFields
        value = settings.(fieldName);
        if ~islogical(value) || ~isscalar(value)
            error( ...
                "TFA:InvalidSimulationOutputToggle", ...
                "%s must be true or false.", fieldName);
        end
    end

    settings.visible = lower(string(settings.visible));
    if ~isscalar(settings.visible) || ...
            ~any(settings.visible == ["on", "off"])
        error( ...
            "TFA:InvalidSimulationFigureVisibility", ...
            "visible must be ""on"" or ""off"".");
    end

    validateattributes( ...
        settings.advantageColorLimit, {'numeric'}, ...
        {'real', 'finite', 'scalar', 'positive'});
    validateattributes( ...
        settings.diagnosticBinEdges, {'numeric'}, ...
        {'real', 'finite', 'vector', 'increasing'});
    settings.diagnosticBinEdges = ...
        double(settings.diagnosticBinEdges(:)');

    bootstrap = settings.bootstrap;
    if ~islogical(bootstrap.enabled) || ~isscalar(bootstrap.enabled)
        error( ...
            "TFA:InvalidSimulationBootstrapToggle", ...
            "bootstrap.enabled must be true or false.");
    end
    validateattributes(bootstrap.numSamples, {'numeric'}, ...
        {'real', 'finite', 'scalar', 'integer', 'positive'});
    validateattributes(bootstrap.randomSeed, {'numeric'}, ...
        {'real', 'finite', 'scalar', 'integer', 'nonnegative'});
    validateattributes(bootstrap.confidenceLevel, {'numeric'}, ...
        {'real', 'finite', 'scalar', '>', 0, '<', 1});

    settings.outputFolder = string(settings.outputFolder);
    if ~isscalar(settings.outputFolder)
        error( ...
            "TFA:InvalidSimulationOutputFolder", ...
            "outputFolder must be one folder path.");
    end

end

function defaults = baseDefaults()
% baseDefaults Avoid recursively calling the public default function.

    defaults.createFigures = true;
    defaults.visible = "on";
    defaults.advantageColorLimit = 1.5;
    defaults.diagnosticBinEdges = 0:0.1:1;
    defaults.bootstrap.enabled = true;
    defaults.bootstrap.numSamples = 1000;
    defaults.bootstrap.randomSeed = 2027;
    defaults.bootstrap.confidenceLevel = 0.95;
    defaults.outputFolder = "";
    defaults.savePng = true;
    defaults.saveCsv = true;
    defaults.saveMat = true;

end

function settings = fillFields(settings, defaults)
% fillFields Fill missing scalar structure fields.

    defaultFields = fieldnames(defaults);
    for fieldIndex = 1:numel(defaultFields)
        fieldName = defaultFields{fieldIndex};
        if ~isfield(settings, fieldName)
            settings.(fieldName) = defaults.(fieldName);
        end
    end

end
