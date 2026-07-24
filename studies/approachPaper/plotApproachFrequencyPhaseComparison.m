function [figureHandle, sourceData] = ...
    plotApproachFrequencyPhaseComparison(frequencyModelComparisons)
% plotApproachFrequencyPhaseComparison Show phase and BH results by bin.
%
% The delay panel reports the principal equivalent delay difference. It is
% derived from wrapped phase and is therefore defined modulo one period.

    phaseRows = frequencyModelComparisons.Metric == "Phase";
    sourceData = frequencyModelComparisons(phaseRows, :);
    if isempty(sourceData)
        error( ...
            "TFA:NoFrequencyPhaseResults", ...
            "No frequency-wise phase comparisons are available.");
    end

    pathways = ["MAP"; "CO2"];
    colors.miso = [0 0.4470 0.7410];
    colors.siso = [0.8500 0.3250 0.0980];
    colors.difference = [0.25 0.25 0.25];
    colors.coherence = [0.20 0.60 0.50];

    figureHandle = figure( ...
        "Name", "Approach Paper Frequency Phase Comparison", ...
        "Color", "white", "Visible", "off");
    layout = tiledlayout(figureHandle, 2, 3, ...
        "TileSpacing", "compact", "Padding", "compact");

    for pathwayIndex = 1:numel(pathways)
        pathway = pathways(pathwayIndex);
        data = sourceData(sourceData.Pathway == pathway, :);
        data = sortrows(data, "FrequencyHz");
        panelOffset = (pathwayIndex - 1)*3;

        axesHandle = nexttile(layout);
        plot(axesHandle, data.FrequencyHz, ...
            rad2deg(data.MISOMean), ...
            "Color", colors.miso, "LineWidth", 1.4, ...
            "DisplayName", "MISO");
        hold(axesHandle, "on");
        plot(axesHandle, data.FrequencyHz, ...
            rad2deg(data.SISOMean), ...
            "Color", colors.siso, "LineWidth", 1.4, ...
            "DisplayName", "SISO");
        yline(axesHandle, 0, "k:", ...
            "HandleVisibility", "off");
        xlabel(axesHandle, "Frequency (Hz)");
        ylabel(axesHandle, "Circular mean phase (degrees)");
        title(axesHandle, ...
            panelLetter(panelOffset + 1) + "  " + ...
            pathway + " phase");
        legend(axesHandle, "Location", "best");
        grid(axesHandle, "on");

        axesHandle = nexttile(layout);
        yyaxis(axesHandle, "left");
        plot(axesHandle, data.FrequencyHz, ...
            data.PrincipalDelayDifferenceSeconds, ...
            "Color", colors.difference, "LineWidth", 1.4);
        yline(axesHandle, 0, "k:", ...
            "HandleVisibility", "off");
        ylabel(axesHandle, ...
            "Principal equivalent delay difference (s)");
        axesHandle.YAxis(1).Color = colors.difference;

        yyaxis(axesHandle, "right");
        minimumMeanCoherence = min( ...
            [data.MISOCoherenceMean, data.SISOCoherenceMean], ...
            [], 2);
        plot(axesHandle, data.FrequencyHz, minimumMeanCoherence, ...
            "--", "Color", colors.coherence, "LineWidth", 1.0);
        ylabel(axesHandle, "Lower mean coherence");
        ylim(axesHandle, [0 1]);
        axesHandle.YAxis(2).Color = colors.coherence;
        xlabel(axesHandle, "Frequency (Hz)");
        title(axesHandle, ...
            panelLetter(panelOffset + 2) + ...
            "  Principal delay difference");
        grid(axesHandle, "on");

        axesHandle = nexttile(layout);
        semilogy(axesHandle, data.FrequencyHz, data.RawP, ...
            "Color", [0.55 0.55 0.55], "LineWidth", 1.0, ...
            "DisplayName", "Raw P");
        hold(axesHandle, "on");
        semilogy(axesHandle, data.FrequencyHz, data.BHAdjustedP, ...
            "Color", colors.miso, "LineWidth", 1.5, ...
            "DisplayName", "BH-adjusted P");
        yline(axesHandle, 0.05, "r:", ...
            "DisplayName", "0.05");
        significantRows = data.BHAdjustedP < 0.05;
        scatter(axesHandle, data.FrequencyHz(significantRows), ...
            data.BHAdjustedP(significantRows), ...
            15, "r", "filled", "HandleVisibility", "off");
        xlabel(axesHandle, "Frequency (Hz)");
        ylabel(axesHandle, "P value");
        ylim(axesHandle, [1e-4 1]);
        title(axesHandle, ...
            panelLetter(panelOffset + 3) + ...
            "  Circular-test P values");
        legend(axesHandle, "Location", "best");
        grid(axesHandle, "on");
    end

end

function letter = panelLetter(panelNumber)
% panelLetter Return A through F for the six figure panels.

    letter = string(char(double('A') + panelNumber - 1));

end
