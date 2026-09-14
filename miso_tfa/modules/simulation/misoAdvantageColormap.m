function colors = misoAdvantageColormap(numColors)
% misoAdvantageColormap Orange favors SISO and blue favors MISO.

    if nargin < 1
        numColors = 257;
    end

    sisoColor = [0.8500 0.3250 0.0980];
    equalColor = [1 1 1];
    misoColor = [0 0.4470 0.7410];
    colorPositions = linspace(-1, 1, numColors)';
    anchors = [-1; 0; 1];
    anchorColors = [sisoColor; equalColor; misoColor];
    colors = interp1( ...
        anchors, anchorColors, colorPositions, "linear");

end
