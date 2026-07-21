function plotGroupSisoPartitionedPathwayFigure( ...
    sisoResults, pathwayName, groupName, frequencyBandEdgesHz, ...
    frequencyBandNames, plotSettings)
% plotGroupSisoPartitionedPathwayFigure Plot group SISO frequency bands.

    pathwayResults = sisoResults.(pathwayName);
    pathwayLabel = upper(pathwayName);

    if pathwayName == "co2"
        coherenceColor = plotSettings.colors.co2Coherence;
        gainLabel = 'Gain (%CBV/mmHg CO2)';
    else
        coherenceColor = plotSettings.colors.mapCoherence;
        gainLabel = 'Gain (%CBV/mmHg)';
    end

    figureName = groupName + "_GroupPartitionedSiso" + ...
        upper(extractBefore(pathwayName, 2)) + ...
        extractAfter(pathwayName, 1) + "ToCbv";
    figure('Name', figureName, 'NumberTitle', 'off')
    plotLayout = tiledlayout(numel(frequencyBandNames), 3);

    for bandIndex = 1:numel(frequencyBandNames)
        lowerHz = frequencyBandEdgesHz(bandIndex);
        upperHz = frequencyBandEdgesHz(bandIndex + 1);

        if bandIndex == numel(frequencyBandNames)
            frequencyIndex = sisoResults.f >= lowerHz & ...
                sisoResults.f <= upperHz;
        else
            frequencyIndex = sisoResults.f >= lowerHz & ...
                sisoResults.f < upperHz;
        end

        bandFrequency = sisoResults.f(frequencyIndex);

        ax = nexttile(plotLayout);
        plotMeanAndSd( ...
            ax, bandFrequency, ...
            pathwayResults.gain.mean(frequencyIndex), ...
            pathwayResults.gain.sd(frequencyIndex), ...
            plotSettings.colors.transferFunction, ...
            plotSettings.transferFunctionStyle, plotSettings);
        xlabel(ax, 'Frequency (Hz)')
        ylabel(ax, gainLabel)
        title(ax, frequencyBandNames(bandIndex) + ' Gain')
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
        title(ax, frequencyBandNames(bandIndex) + ' Unwrapped Phase')
        xlim(ax, [lowerHz upperHz])
        grid(ax, 'on')

        ax = nexttile(plotLayout);
        plotMeanAndSd( ...
            ax, bandFrequency, ...
            pathwayResults.coherence.pairwise.mean(frequencyIndex), ...
            pathwayResults.coherence.pairwise.sd(frequencyIndex), ...
            coherenceColor, "line", plotSettings);
        xlabel(ax, 'Frequency (Hz)')
        ylabel(ax, 'Coherence')
        title(ax, frequencyBandNames(bandIndex) + ' Coherence')
        xlim(ax, [lowerHz upperHz])
        ylim(ax, [0 1])
        grid(ax, 'on')
    end

    title(plotLayout, ...
        groupName + ' Group SISO ' + pathwayLabel + ...
        ' to CBV by Frequency Band')

end
