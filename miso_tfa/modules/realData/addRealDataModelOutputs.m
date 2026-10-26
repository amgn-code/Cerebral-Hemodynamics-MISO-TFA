function results = addRealDataModelOutputs(results, displaySettings)
% addRealDataModelOutputs Add optional outputs to one model page.

    if nargin < 2 || isempty(displaySettings)
        displaySettings = defaultRealDataDisplaySettings();
    end

    results.frequencyTable = ...
        createRealDataModelFrequencyTable(results);
    results.plotSourceData = results.frequencyTable;
    results.figureHandle = [];
    results.exportResults = struct();

    if ~isfield(displaySettings, "createFigure")
        displaySettings.createFigure = true;
    end
    if ~islogical(displaySettings.createFigure) || ...
            ~isscalar(displaySettings.createFigure)
        error( ...
            "TFA:InvalidRealDataFigureToggle", ...
            "displaySettings.createFigure must be true or false.");
    end

    if displaySettings.createFigure
        [results.figureHandle, results.plotSourceData] = ...
            plotRealDataModelSummary(results, displaySettings);
    end

    if isfield(displaySettings, "outputFolder") && ...
            strlength(string(displaySettings.outputFolder)) > 0
        results.exportResults = exportRealDataModelResults( ...
            results, displaySettings);
    end

end
