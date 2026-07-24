function [alignedMap, alignedCo2, alignedCbv] = alignCo2ByDelay( ...
    map, co2, cbv, samplingFrequencyHz, assumedDelaySeconds)
% alignCo2ByDelay Advance CO2 by an assumed measurement delay.
%
% A positive value means the measured CO2 signal is assumed to lag MAP and
% CBFV. The beginning of CO2 and the end of MAP/CBFV are trimmed so all
% returned signals remain aligned and have equal length.

    delaySamples = round( ...
        assumedDelaySeconds*samplingFrequencyHz);
    map = map(:);
    co2 = co2(:);
    cbv = cbv(:);

    if delaySamples >= 0
        if delaySamples >= numel(co2)
            error( ...
                "TFA:DelayExceedsSignalLength", ...
                "The assumed CO2 delay exceeds the signal length.");
        end
        alignedCo2 = co2((1 + delaySamples):end);
        alignedMap = map(1:(end - delaySamples));
        alignedCbv = cbv(1:(end - delaySamples));
    else
        advanceSamples = abs(delaySamples);
        if advanceSamples >= numel(co2)
            error( ...
                "TFA:DelayExceedsSignalLength", ...
                "The assumed CO2 delay exceeds the signal length.");
        end
        alignedCo2 = co2(1:(end - advanceSamples));
        alignedMap = map((1 + advanceSamples):end);
        alignedCbv = cbv((1 + advanceSamples):end);
    end

end
