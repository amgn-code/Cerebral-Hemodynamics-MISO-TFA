function plotGroupMisoPartitionedPathwayFigure( ...
    misoResults, pathwayName, groupName, frequencyBandEdgesHz, ...
    frequencyBandNames, plotSettings)
% plotGroupMisoPartitionedPathwayFigure Plot group MISO frequency bands.

    pathwayResults = misoResults.(pathwayName);
    pathwayLabel = upper(pathwayName);

    if pathwayName == "co2"
        coherenceColor = plotSettings.colors.co2Coherence;
        coherenceLabel = "CO2 partial coherence | MAP";
        gainLabel = 'Gain (%CBV/mmHg CO2)';
    else
        coherenceColor = plotSettings.colors.mapCoherence;
        coherenceLabel = "MAP partial coherence | CO2";
        gainLabel = 'Gain (%CBV/mmHg)';
    end

    figureName = groupName + "_GroupPartitionedMiso" + ...
        upper(extractBefore(pathwayName, 2)) + ...
        extractAfter(pathwayName, 1) + "ToCbv";
    figure('Name', figureName, 'NumberTitle', 'off')
    plotLayout = tiledlayout(numel(frequencyBandNames), 3);

    for k = 1:numel(frequencyBandNames)
        lowerHz = frequencyBandEdgesHz(k);
        upperHz = frequencyBandEdgesHz(k + 1);

        if k == numel(frequencyBandNames)
            frequencyIndex = misoResults.f >= lowerHz & ...
                misoResults.f <= upperHz;
        else
            frequencyIndex = misoResults.f >= lowerHz & ...
                misoResults.f < upperHz;
        end

        bandFrequency = misoResults.f(frequencyIndex);

        ax = nexttile(plotLayout);
        plotMeanAndSd( ...
            ax, bandFrequency, ...
            pathwayResults.gain.mean(frequencyIndex), ...
            pathwayResults.gain.sd(frequencyIndex), ...
            plotSettings.colors.transferFunction, ...
            plotSettings.transferFunctionStyle, plotSettings);
        xlabel(ax, 'Frequency (Hz)')
        ylabel(ax, gainLabel)
        title(ax, frequencyBandNames(k) + ' Gain')
        xlim(ax, [lowerHz upperHz])
        grid(ax, 'on')

        ax = nexttile(plotLayout);
        plotMeanAndSd( ...
            ax, bandFrequency, ...
            pathwayResults.phase.unwrapped.mean(frequencyIndex), ...
            pathwayResults.phase.unwrapped.sd(frequencyIndex), ...
            plotSettings.colors.transferFunction, ...
            plotSettings.transferFunctionStyle, plotSettings);
        xlabel(ax, 'Frequency (Hz)')
        ylabel(ax, 'Unwrapped phase (rad)')
        title(ax, frequencyBandNames(k) + ' Unwrapped Phase')
        xlim(ax, [lowerHz upperHz])
        grid(ax, 'on')

        ax = nexttile(plotLayout);
        partialHandle = plotMeanAndSd( ...
            ax, bandFrequency, ...
            pathwayResults.coherence.partial.mean(frequencyIndex), ...
            pathwayResults.coherence.partial.sd(frequencyIndex), ...
            coherenceColor, "line", plotSettings);
        multipleHandle = plotMeanAndSd( ...
            ax, bandFrequency, ...
            misoResults.system.multipleCoherence.mean(frequencyIndex), ...
            misoResults.system.multipleCoherence.sd(frequencyIndex), ...
            plotSettings.colors.multipleCoherence, "line", plotSettings);
        xlabel(ax, 'Frequency (Hz)')
        ylabel(ax, 'Coherence')
        title(ax, frequencyBandNames(k) + ' Coherence')
        legend(ax, [partialHandle multipleHandle], ...
            {char(coherenceLabel), 'Multiple coherence'}, 'Location', 'best')
        xlim(ax, [lowerHz upperHz])
        ylim(ax, [0 1])
        grid(ax, 'on')
    end

    title(plotLayout, ...
        groupName + ' Group MISO ' + pathwayLabel + ...
        ' to CBV by Frequency Band')

end
