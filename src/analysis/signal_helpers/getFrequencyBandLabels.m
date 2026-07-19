function bandLabels = getFrequencyBandLabels( ...
    f, frequencyBandEdgesHz, frequencyBandNames)
% getFrequencyBandLabels Label each frequency with its analysis band.

    bands = getFrequencyBands( ...
        f, frequencyBandEdgesHz, frequencyBandNames);
    bandLabels = strings(size(f));

    for k = 1:numel(frequencyBandNames)
        bandName = frequencyBandNames(k);
        bandField = lower(char(bandName));
        bandLabels(bands.(bandField).idx) = bandName;
    end

end
