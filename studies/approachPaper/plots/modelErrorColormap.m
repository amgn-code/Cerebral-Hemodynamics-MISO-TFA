function colors = modelErrorColormap(modelName, numColors)
% modelErrorColormap Create a white-to-model-color error scale.

    if nargin < 2
        numColors = 256;
    end

    modelName = lower(string(modelName));
    if modelName == "miso"
        modelColor = [0 0.4470 0.7410];
    elseif modelName == "siso"
        modelColor = [0.8500 0.3250 0.0980];
    else
        error( ...
            "TFA:UnknownSimulationModel", ...
            "modelName must be MISO or SISO.");
    end

    positions = linspace(0, 1, numColors)';
    colors = interp1( ...
        [0; 1], [1 1 1; modelColor], positions, "linear");

end
