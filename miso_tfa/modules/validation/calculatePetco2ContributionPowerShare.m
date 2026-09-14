function contributionShare = calculatePetco2ContributionPowerShare( ...
    mapContribution, co2Contribution)
% calculatePetco2ContributionPowerShare Measure known PETCO2 output power.
%
% The denominator is the sum of the separately known pathway powers. It
% intentionally excludes their covariance so the result remains between
% zero and one even when the simulated inputs are correlated.

    mapPower = mean(abs(mapContribution(:)).^2, "omitnan");
    co2Power = mean(abs(co2Contribution(:)).^2, "omitnan");
    totalSeparatePower = mapPower + co2Power;

    if totalSeparatePower <= 0 || ~isfinite(totalSeparatePower)
        contributionShare = NaN;
    else
        contributionShare = co2Power/totalSeparatePower;
    end

end
