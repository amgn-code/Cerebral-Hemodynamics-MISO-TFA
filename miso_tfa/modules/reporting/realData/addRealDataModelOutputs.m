function results = addRealDataModelOutputs(results, displaySettings)
% addRealDataModelOutputs Add the table and optional figure to one page.

    if nargin < 2 || isempty(displaySettings)
        displaySettings = defaultRealDataDisplaySettings();
    end

    results.frequencyTable = ...
        createRealDataModelFrequencyTable(results);
    results.plotSourceData = results.frequencyTable;
    results.figureHandle = [];

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

end
