function alignRightYAxisZero(leftMin, leftMax, rightMax)

    % Aligns y = 0 on the right axis with y = 0 on the left axis.
    % This is useful when phase has negative values but coherence starts at 0.

    zeroFraction = (0 - leftMin) / (leftMax - leftMin);

    if zeroFraction <= 0
        rightMin = 0;
    elseif zeroFraction >= 1
        rightMin = -rightMax;
    else
        rightMin = -(zeroFraction * rightMax) / (1 - zeroFraction);
    end

    yyaxis right
    ylim([rightMin, rightMax])

    yyaxis left
    ylim([leftMin, leftMax])

end