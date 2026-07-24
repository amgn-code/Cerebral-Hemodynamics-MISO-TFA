function bandResults = calculateSubjectBandValues( ...
    frequencyHz, subjectValues, analysisSettings, statistic, ...
    wrappedValues, coherenceValues)
% calculateSubjectBandValues Calculate one value per subject and band.
%
% Arithmetic quantities are averaged normally within each band. Phase is
% averaged circularly so values near -pi and +pi are treated as neighbors.

    if nargin < 5
        wrappedValues = [];
    end

    if nargin < 6
        coherenceValues = [];
    end

    frequencyHz = frequencyHz(:);
    frequencyBandEdgesHz = analysisSettings.frequencyBandEdgesHz(:);
    frequencyBandNames = string(analysisSettings.frequencyBandNames(:));
    statistic = string(statistic);

    isPhase = statistic == "phaseWrapped" || ...
        statistic == "phaseUnwrapped";

    numBands = numel(frequencyBandNames);
    numSubjects = size(subjectValues, 2);

    bandValues = NaN(numBands, numSubjects);
    bandWrappedValues = NaN(numBands, numSubjects);
    bandUnwrappedValues = NaN(numBands, numSubjects);
    bandCoherenceValues = NaN(numBands, numSubjects);
    numFrequencyBins = zeros(numBands, 1);

    %% Calculate Each Subject's Value in Each Frequency Band

    for bandIndex = 1:numBands
        lowerFrequencyHz = frequencyBandEdgesHz(bandIndex);
        upperFrequencyHz = frequencyBandEdgesHz(bandIndex + 1);

        if bandIndex == numBands
            frequencyMask = frequencyHz >= lowerFrequencyHz & ...
                frequencyHz <= upperFrequencyHz;
        else
            frequencyMask = frequencyHz >= lowerFrequencyHz & ...
                frequencyHz < upperFrequencyHz;
        end

        numFrequencyBins(bandIndex) = sum(frequencyMask);

        for subjectIndex = 1:numSubjects
            if isPhase
                bandWrappedValues(bandIndex,subjectIndex) = ...
                    circularMeanPhase( ...
                        wrappedValues(frequencyMask,subjectIndex));

                bandCoherenceValues(bandIndex,subjectIndex) = mean( ...
                    coherenceValues(frequencyMask,subjectIndex), ...
                    'omitnan');
            else
                bandValues(bandIndex,subjectIndex) = mean( ...
                    subjectValues(frequencyMask,subjectIndex), ...
                    'omitnan');
            end
        end
    end

    %% Select the Requested Phase Representation

    bandCentersHz = mean( ...
        [frequencyBandEdgesHz(1:end - 1), ...
         frequencyBandEdgesHz(2:end)], 2);

    if isPhase
        for subjectIndex = 1:numSubjects
            bandUnwrappedValues(:,subjectIndex) = unwrapTfaPhase( ...
                bandWrappedValues(:,subjectIndex), ...
                bandCentersHz, ...
                bandCoherenceValues(:,subjectIndex), ...
                analysisSettings.phase);
        end

        if statistic == "phaseUnwrapped"
            bandValues = bandUnwrappedValues;
        else
            bandValues = bandWrappedValues;
        end
    end

    %% Store the Band Values and Supporting Information

    bandResults.names = frequencyBandNames;
    bandResults.centersHz = bandCentersHz;
    bandResults.numFrequencyBins = numFrequencyBins;
    bandResults.values = bandValues;
    bandResults.wrappedValues = bandWrappedValues;
    bandResults.unwrappedValues = bandUnwrappedValues;
    bandResults.coherenceValues = bandCoherenceValues;

end
