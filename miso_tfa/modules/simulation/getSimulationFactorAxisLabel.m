function axisLabel = getSimulationFactorAxisLabel( ...
    factorName, fallbackLabel)
% getSimulationFactorAxisLabel Return compact labels for repeated panels.

    factorName = string(factorName);
    switch factorName
        case "DurationSeconds"
            axisLabel = "Duration (s)";
        case "OutputSNRdB"
            axisLabel = "Broadband CBFV output SNR (dB)";
        case {"FamilyInputCoherence", "RealizedInputCoherence"}
            axisLabel = "Mean input coherence";
        case {"FamilyPSDShapeOverlap", "RealizedPSDShapeOverlap"}
            axisLabel = "PSD-shape overlap";
        case { ...
                "AssignedPETCO2ToMAPFluctuationSDRatio", ...
                "FamilyPETCO2ToMAPFluctuationSDRatio", ...
                "RealizedPETCO2ToMAPFluctuationSDRatio"}
            axisLabel = "PETCO2/MAP fluctuation ratio";
        case { ...
                "AssignedPETCO2ToMAPBandGainRatio", ...
                "AchievedPETCO2ToMAPBandGainRatio"}
            axisLabel = "PETCO2/MAP pathway gain";
        case { ...
                "FamilyPETCO2ContributionPowerShare", ...
                "RealizedPETCO2ContributionPowerShare"}
            axisLabel = "PETCO2 contribution share";
        case "CO2DelaySeconds"
            axisLabel = "True PETCO2 delay (s)";
        case "AlignmentErrorSeconds"
            axisLabel = "Applied PETCO2 shift (s)";
        case "MAPInputSNRdB"
            axisLabel = "MAP SNR (dB)";
        case "CO2InputSNRdB"
            axisLabel = "PETCO2 SNR (dB)";
        case "WelchWindowLengthSeconds"
            axisLabel = "Welch window (s)";
        case "WelchWindowOverlap"
            axisLabel = "Welch overlap";
        otherwise
            axisLabel = string(fallbackLabel);
    end

end
