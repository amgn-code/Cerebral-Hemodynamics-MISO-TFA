function alignRightYAxisZero(left_min, left_max, right_max)

    % Aligns y = 0 on the right axis with y = 0 on the left axis.
    % This is useful when phase has negative values but coherence starts at 0.

    zero_fraction = (0 - left_min) / (left_max - left_min);

    if zero_fraction <= 0
        right_min = 0;
    elseif zero_fraction >= 1
        right_min = -right_max;
    else
        right_min = -(zero_fraction * right_max) / (1 - zero_fraction);
    end

    yyaxis right
    ylim([right_min, right_max])

    yyaxis left
    ylim([left_min, left_max])

end