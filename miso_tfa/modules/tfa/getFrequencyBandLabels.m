function bandLabels = getFrequencyBandLabels( ...
    f, frequencyBandEdgesHz, frequencyBandNames)
% getFrequencyBandLabels Label each frequency with its analysis band.

    f = f(:);
    frequencyBandEdgesHz = frequencyBandEdgesHz(:);
    frequencyBandNames = frequencyBandNames(:);

    bandLabels = strings(size(f));
    numBands = numel(frequencyBandNames);

    for bandIndex = 1:numBands
        lowerFrequencyHz = frequencyBandEdgesHz(bandIndex);
        upperFrequencyHz = frequencyBandEdgesHz(bandIndex + 1);

        if bandIndex == numBands
            frequenciesInBand = ...
                f >= lowerFrequencyHz & f <= upperFrequencyHz;
        else
            frequenciesInBand = ...
                f >= lowerFrequencyHz & f < upperFrequencyHz;
        end

        bandLabels(frequenciesInBand) = frequencyBandNames(bandIndex);
    end

end
