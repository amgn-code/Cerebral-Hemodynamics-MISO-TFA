function settings = defaultRealDataDisplaySettings(visibility)
% defaultRealDataDisplaySettings Return compact model-page output settings.

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

end
