function settings = defaultRealDataDisplaySettings(visibility)
% defaultRealDataDisplaySettings Return model-page display and export settings.

    if nargin < 1
        visibility = "on";
    end

    visibility = lower(string(visibility));
    if ~isscalar(visibility) || ...
            ~any(visibility == ["on", "off"])
        error( ...
            "TFA:InvalidRealDataFigureVisibility", ...
            "visibility must be ""on"" or ""off"".");
    end

    settings.createFigure = true;
    settings.visible = visibility;
    settings.outputFolder = "";
    settings.saveFigure = true;
    settings.saveCsv = true;
    settings.saveMat = true;
    settings.closeFigureAfterExport = false;

end
