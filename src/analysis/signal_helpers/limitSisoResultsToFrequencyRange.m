function results = limitSisoResultsToFrequencyRange(results, frequencyRangeHz)
% limitSisoResultsToFrequencyRange Select the reported SISO frequency bins.

    frequencyIndex = results.f >= frequencyRangeHz(1) & ...
        results.f <= frequencyRangeHz(2);

    if ~any(frequencyIndex)
        error( ...
            'TFA:EmptyAnalysisFrequencyRange', ...
            ['No computed frequency bins fall inside [%.6g %.6g] Hz. ' ...
             'Adjust analysisSettings.frequencyRangeHz.'], ...
            frequencyRangeHz(1), frequencyRangeHz(2));
    end

    results.f = results.f(frequencyIndex);

    results.map.power = results.map.power(frequencyIndex);
    results.map.transferFunction = results.map.transferFunction(frequencyIndex);
    results.map.gain = results.map.gain(frequencyIndex);
    results.map.phase.wrapped = results.map.phase.wrapped(frequencyIndex);
    results.map.phase.unwrapped = results.map.phase.unwrapped(frequencyIndex);
    results.map.coherence.pairwise = ...
        results.map.coherence.pairwise(frequencyIndex);
    results.map.unexplainedFraction = ...
        results.map.unexplainedFraction(frequencyIndex);
    results.map.residualPower = results.map.residualPower(frequencyIndex);

    results.co2.power = results.co2.power(frequencyIndex);
    results.co2.transferFunction = results.co2.transferFunction(frequencyIndex);
    results.co2.gain = results.co2.gain(frequencyIndex);
    results.co2.phase.wrapped = results.co2.phase.wrapped(frequencyIndex);
    results.co2.phase.unwrapped = results.co2.phase.unwrapped(frequencyIndex);
    results.co2.coherence.pairwise = ...
        results.co2.coherence.pairwise(frequencyIndex);
    results.co2.unexplainedFraction = ...
        results.co2.unexplainedFraction(frequencyIndex);
    results.co2.residualPower = results.co2.residualPower(frequencyIndex);

    results.cbv.power = results.cbv.power(frequencyIndex);

    results.inputRelationship.coherence = ...
        results.inputRelationship.coherence(frequencyIndex);
    results.inputRelationship.phase.wrapped = ...
        results.inputRelationship.phase.wrapped(frequencyIndex);
    results.inputRelationship.phase.unwrapped = ...
        results.inputRelationship.phase.unwrapped(frequencyIndex);

    results.analysisFrequencyRangeHz = frequencyRangeHz;
    results.welchInfo.analysisFrequencyRangeHz = frequencyRangeHz;

end
