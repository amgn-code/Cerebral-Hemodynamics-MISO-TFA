function [figureHandle, sourceData] = ...
    plotRealDataModelSummary(results, displaySettings)
% plotRealDataModelSummary Plot gain, phase, and coherence for one model.

    if nargin < 2 || isempty(displaySettings)
        displaySettings = defaultRealDataDisplaySettings();
    end
    displaySettings = validateDisplaySettings(displaySettings);

    sourceData = createRealDataModelFrequencyTable(results);
    modelName = upper(string(results.interfaceModel));
    frequencyHz = sourceData.FrequencyHz;

    mapColor = [0.00 0.36 0.67];
    co2Color = [0.85 0.33 0.10];
    multipleColor = [0.49 0.18 0.56];

    figureHandle = figure( ...
        Name=modelName + " real-data summary", ...
        NumberTitle="off", ...
        Color="w", ...
        Visible=displaySettings.visible, ...
        Position=[100 100 820 760]);
    layout = tiledlayout(3, 1, ...
        TileSpacing="compact", Padding="compact");

    gainAxes = nexttile(layout);
    plot(gainAxes, frequencyHz, sourceData.MAPGain, ...
        LineWidth=1.4, Color=mapColor);
    hold(gainAxes, "on");
    plot(gainAxes, frequencyHz, sourceData.CO2Gain, ...
        LineWidth=1.4, Color=co2Color);
    hold(gainAxes, "off");
    ylabel(gainAxes, "Gain");
    title(gainAxes, "Transfer-function gain");
    legend(gainAxes, "MAP to CBFV", "CO2 to CBFV", ...
        Location="best");
    formatFrequencyAxes(gainAxes, frequencyHz);

    phaseAxes = nexttile(layout);
    plot(phaseAxes, frequencyHz, sourceData.MAPPhaseDegrees, ...
        LineWidth=1.4, Color=mapColor);
    hold(phaseAxes, "on");
    plot(phaseAxes, frequencyHz, sourceData.CO2PhaseDegrees, ...
        LineWidth=1.4, Color=co2Color);
    hold(phaseAxes, "off");
    ylabel(phaseAxes, "Phase (degrees)");
    title(phaseAxes, "Wrapped transfer-function phase");
    ylim(phaseAxes, [-180 180]);
    legend(phaseAxes, "MAP to CBFV", "CO2 to CBFV", ...
        Location="best");
    formatFrequencyAxes(phaseAxes, frequencyHz);

    coherenceAxes = nexttile(layout);
    if modelName == "MISO"
        plot(coherenceAxes, frequencyHz, ...
            sourceData.MAPPartialCoherence, ...
            LineWidth=1.4, Color=mapColor);
        hold(coherenceAxes, "on");
        plot(coherenceAxes, frequencyHz, ...
            sourceData.CO2PartialCoherence, ...
            LineWidth=1.4, Color=co2Color);
        plot(coherenceAxes, frequencyHz, ...
            sourceData.MultipleCoherence, ...
            LineWidth=1.6, Color=multipleColor);
        hold(coherenceAxes, "off");
        legend(coherenceAxes, ...
            "MAP partial | CO2", "CO2 partial | MAP", ...
            "Multiple coherence", Location="best");
        title(coherenceAxes, "Partial and multiple coherence");
    else
        plot(coherenceAxes, frequencyHz, sourceData.MAPCoherence, ...
            LineWidth=1.4, Color=mapColor);
        hold(coherenceAxes, "on");
        plot(coherenceAxes, frequencyHz, sourceData.CO2Coherence, ...
            LineWidth=1.4, Color=co2Color);
        coherenceThreshold = ...
            results.sisoResults.welchInfo.coherenceThreshold;
        yline(coherenceAxes, coherenceThreshold, "--", ...
            "Ordinary-coherence reference", ...
            Color=[0.35 0.35 0.35]);
        hold(coherenceAxes, "off");
        legend(coherenceAxes, ...
            "MAP-CBFV", "CO2-CBFV", Location="best");
        title(coherenceAxes, "Ordinary coherence");
    end
    xlabel(coherenceAxes, "Frequency (Hz)");
    ylabel(coherenceAxes, "Coherence");
    ylim(coherenceAxes, [0 1]);
    formatFrequencyAxes(coherenceAxes, frequencyHz);

    title(layout, modelName + " transfer-function analysis");

end

function settings = validateDisplaySettings(settings)
% validateDisplaySettings Fill and check the two display controls.

    defaults = defaultRealDataDisplaySettings();
    if ~isstruct(settings)
        error( ...
            "TFA:InvalidRealDataDisplaySettings", ...
            "displaySettings must be a structure.");
    end
    if ~isfield(settings, "createFigure")
        settings.createFigure = defaults.createFigure;
    end
    if ~isfield(settings, "visible")
        settings.visible = defaults.visible;
    end

    if ~islogical(settings.createFigure) || ...
            ~isscalar(settings.createFigure)
        error( ...
            "TFA:InvalidRealDataFigureToggle", ...
            "displaySettings.createFigure must be true or false.");
    end

    settings.visible = lower(string(settings.visible));
    if ~isscalar(settings.visible) || ...
            ~any(settings.visible == ["on", "off"])
        error( ...
            "TFA:InvalidRealDataFigureVisibility", ...
            "displaySettings.visible must be ""on"" or ""off"".");
    end

end

function formatFrequencyAxes(axesHandle, frequencyHz)
% formatFrequencyAxes Apply the shared frequency-domain presentation.

    xlim(axesHandle, [min(frequencyHz), max(frequencyHz)]);
    grid(axesHandle, "on");

end
