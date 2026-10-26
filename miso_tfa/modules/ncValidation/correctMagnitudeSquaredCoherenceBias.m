function corrected = correctMagnitudeSquaredCoherenceBias( ...
    measured, effectiveAverages)
% correctMagnitudeSquaredCoherenceBias Remove finite-average MSC bias.
%
% Under the usual independent-average approximation, the null expectation
% of magnitude-squared coherence is 1/L for L effective averages. The
% inverse correction is (L*C-1)/(L-1), bounded to the physical interval.

    validateattributes(effectiveAverages, {'numeric'}, ...
        {'scalar', 'finite', '>', 1});
    corrected = (effectiveAverages*measured - 1)/(effectiveAverages - 1);
    corrected = min(1, max(0, real(corrected)));

end
