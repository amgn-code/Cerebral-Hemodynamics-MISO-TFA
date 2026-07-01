function bands = getFrequencyBands(f, frequencyBandEdgesHz, frequencyBandNames)

    f = f(:);
    frequencyBandEdgesHz = frequencyBandEdgesHz(:);
    frequencyBandNames = frequencyBandNames(:);

    for k = 1:numel(frequencyBandNames)

        bandName = lower(char(frequencyBandNames(k)));
        lowerHz = frequencyBandEdgesHz(k);
        upperHz = frequencyBandEdgesHz(k + 1);

        if k == numel(frequencyBandNames)
            bandIndex = f >= lowerHz & f <= upperHz;
        else
            bandIndex = f >= lowerHz & f < upperHz;
        end

        bands.(bandName).idx = bandIndex;
        bands.(bandName).f = f(bandIndex);

    end

end
