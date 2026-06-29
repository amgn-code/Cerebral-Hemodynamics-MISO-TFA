function visualizeTimeSeries(t, map, co2, cbv)

    figure('Name', 'TimeSeriesData')

    subplot(2,1,1)
    
    yyaxis left
    plot(t, map)
    ylabel('MAP')
    grid on
    hold on
    
    left_min = min(map, [], 'omitnan');
    left_max = max(map, [], 'omitnan');
    left_min = min(left_min, 0);
    left_max = max(left_max, 0);
    
    if left_min == left_max
        left_min = left_min - 1;
        left_max = left_max + 1;
    end
    
    yyaxis right
    plot(t, co2)
    ylabel('CO2')
    
    right_max = max(abs(co2), [], 'omitnan');
    right_max = max(right_max, 1);
    right_max = 1.05 * right_max;
    
    alignRightYAxisZero(left_min, left_max, right_max)
    
    title('MAP and CO2 Inputs vs. Time')
    xlabel('Time (s)')
    legend('MAP', 'CO2', 'Location', 'best')
    grid on
    
    subplot(2,1,2)
    plot(t, cbv)
    
    title('CBV Output vs. Time')
    xlabel('Time (s)')
    ylabel('Amplitude')
    grid on
        
end