function visualizeTimeSeries(t, map, co2, cbv)

    figure('Name', 'TimeSeriesData')

    subplot(2,1,1)
    
    yyaxis left
    plot(t, map)
    ylabel('Detrended MAP (mmHg)')
    grid on
    hold on
    
    leftMin = min(map, [], 'omitnan');
    leftMax = max(map, [], 'omitnan');
    leftMin = min(leftMin, 0);
    leftMax = max(leftMax, 0);
    
    if leftMin == leftMax
        leftMin = leftMin - 1;
        leftMax = leftMax + 1;
    end
    
    yyaxis right
    plot(t, co2)
    ylabel('Detrended CO2 (mmHg)')
    
    rightMax = max(abs(co2), [], 'omitnan');
    rightMax = max(rightMax, 1);
    rightMax = 1.05 * rightMax;
    
    alignRightYAxisZero(leftMin, leftMax, rightMax)
    
    title('Detrended MAP and CO2 Inputs vs. Time')
    xlabel('Time (s)')
    legend('MAP', 'CO2', 'Location', 'best')
    grid on
    
    subplot(2,1,2)
    plot(t, cbv)
    
    title('Detrended CBV Output vs. Time')
    xlabel('Time (s)')
    ylabel('Detrended CBV (% baseline)')
    grid on
        
end
