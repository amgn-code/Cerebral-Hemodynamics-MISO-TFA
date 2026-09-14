function [alignedMap, alignedCo2, alignedCbv, alignment] = ...
    alignCo2ByDelay( ...
        map, co2, cbv, samplingFrequencyHz, delayCorrectionSeconds)
% alignCo2ByDelay Correct a stated CO2 measurement delay by cropping edges.
%
% A positive correction means the recorded CO2 signal is assumed to lag
% MAP and CBFV, so CO2 is advanced. A negative correction delays CO2. No
% samples are wrapped or synthesized: unmatched edges are removed from all
% three signals. Returned signals are column vectors.

    map = map(:);
    co2 = co2(:);
    cbv = cbv(:);
    signalLengths = [numel(map), numel(co2), numel(cbv)];

    if numel(unique(signalLengths)) ~= 1
        error( ...
            "TFA:SignalLengthMismatch", ...
            "MAP, CO2, and CBFV must have the same length before alignment.");
    end
    validateattributes( ...
        samplingFrequencyHz, {'numeric'}, ...
        {'real', 'finite', 'scalar', 'positive'});
    validateattributes( ...
        delayCorrectionSeconds, {'numeric'}, ...
        {'real', 'finite', 'scalar'});

    inputNumSamples = numel(co2);
    delaySamples = round( ...
        delayCorrectionSeconds*samplingFrequencyHz);

    if delaySamples >= 0
        if delaySamples >= numel(co2)
            error( ...
                "TFA:DelayExceedsSignalLength", ...
                "The CO2 delay correction exceeds the signal length.");
        end
        mapStartIndex = 1;
        mapEndIndex = inputNumSamples - delaySamples;
        co2StartIndex = 1 + delaySamples;
        co2EndIndex = inputNumSamples;
    else
        advanceSamples = abs(delaySamples);
        if advanceSamples >= numel(co2)
            error( ...
                "TFA:DelayExceedsSignalLength", ...
                "The CO2 delay correction exceeds the signal length.");
        end
        mapStartIndex = 1 + advanceSamples;
        mapEndIndex = inputNumSamples;
        co2StartIndex = 1;
        co2EndIndex = inputNumSamples - advanceSamples;
    end

    alignedMap = map(mapStartIndex:mapEndIndex);
    alignedCo2 = co2(co2StartIndex:co2EndIndex);
    alignedCbv = cbv(mapStartIndex:mapEndIndex);

    alignment.requestedDelayCorrectionSeconds = ...
        double(delayCorrectionSeconds);
    alignment.appliedDelayCorrectionSamples = delaySamples;
    alignment.appliedDelayCorrectionSeconds = ...
        delaySamples / samplingFrequencyHz;
    alignment.inputNumSamples = inputNumSamples;
    alignment.retainedNumSamples = numel(alignedMap);
    alignment.trimmedSamples = abs(delaySamples);
    alignment.mapStartIndex = mapStartIndex;
    alignment.mapEndIndex = mapEndIndex;
    alignment.co2StartIndex = co2StartIndex;
    alignment.co2EndIndex = co2EndIndex;
    alignment.signConvention = ...
        "Positive correction advances recorded CO2";

end
