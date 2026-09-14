function overlap = calculatePSDShapeOverlap(firstPower, secondPower)
% calculatePSDShapeOverlap Compare two normalized PSD shapes.
%
% This is the Bhattacharyya coefficient:
%
%   overlap = sum(sqrt(firstNormalized .* secondNormalized))
%
% Zero means little shared spectral support. One means identical
% normalized power spectral density shapes.

    firstPower = max(real(firstPower(:)), 0);
    secondPower = max(real(secondPower(:)), 0);

    firstTotal = sum(firstPower, "omitnan");
    secondTotal = sum(secondPower, "omitnan");
    if firstTotal <= 0 || secondTotal <= 0
        overlap = NaN;
        return
    end

    firstNormalized = firstPower/firstTotal;
    secondNormalized = secondPower/secondTotal;
    overlap = sum( ...
        sqrt(firstNormalized.*secondNormalized), "omitnan");
    overlap = min(1, max(0, overlap));

end
