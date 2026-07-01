function addFrequencyBandLines(frequencyBandEdgesHz, frequencyBandNames)

    frequencyBandEdgesHz = frequencyBandEdgesHz(:);
    frequencyBandNames = frequencyBandNames(:);

    for k = 1:(numel(frequencyBandNames) - 1)

        boundaryHz = frequencyBandEdgesHz(k + 1);
        boundaryLabel = char(frequencyBandNames(k) + "/" + frequencyBandNames(k + 1));

        xline(boundaryHz, '--', boundaryLabel, ...
            'LabelVerticalAlignment', 'top', ...
            'LabelHorizontalAlignment', 'center');

    end

end
