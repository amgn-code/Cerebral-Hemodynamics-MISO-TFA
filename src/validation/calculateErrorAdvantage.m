function advantage = calculateErrorAdvantage( ...
    sisoError, misoError, errorFloor)
% calculateErrorAdvantage Return log10 SISO error divided by MISO error.
%
% Positive values favor MISO. Negative values favor SISO. A value of zero
% means that both methods have the same error.

    advantage = log10( ...
        (sisoError + errorFloor)./(misoError + errorFloor));
    invalid = ~isfinite(sisoError) | ~isfinite(misoError);
    advantage(invalid) = NaN;

end
