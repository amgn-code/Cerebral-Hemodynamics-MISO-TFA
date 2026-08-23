function factorTitle = getSimulationFactorTitle( ...
    factorName, fallbackLabel)
% getSimulationFactorTitle Return a concise phrase for figure titles.

    factorName = string(factorName);
    switch factorName
        case "DurationSeconds"
            factorTitle = "recording duration";
        case "OutputSNRdB"
            factorTitle = "CBFV output SNR";
        case {"FamilyInputCoherence", "RealizedInputCoherence"}
            factorTitle = "family mean MAP-PETCO2 coherence";
        case {"FamilyPSDShapeOverlap", "RealizedPSDShapeOverlap"}
            factorTitle = ...
                "PSD-shape overlap (Bhattacharyya coefficient)";
        case { ...
                "AssignedPETCO2ToMAPFluctuationSDRatio", ...
                "FamilyPETCO2ToMAPFluctuationSDRatio", ...
                "RealizedPETCO2ToMAPFluctuationSDRatio"}
            factorTitle = "PETCO2-to-MAP fluctuation SD ratio";
        case { ...
                "AssignedPETCO2ToMAPBandGainRatio", ...
                "AchievedPETCO2ToMAPBandGainRatio"}
            factorTitle = "PETCO2-to-MAP pathway band-gain ratio";
        case { ...
                "FamilyPETCO2ContributionPowerShare", ...
                "RealizedPETCO2ContributionPowerShare"}
            factorTitle = "realized PETCO2 contribution-power share";
        case "CO2DelaySeconds"
            factorTitle = "true PETCO2 response delay";
        case "AlignmentErrorSeconds"
            factorTitle = "applied PETCO2 timing misalignment";
        case "MAPInputSNRdB"
            factorTitle = "MAP measurement SNR";
        case "CO2InputSNRdB"
            factorTitle = "PETCO2 measurement SNR";
        case "WelchWindowLengthSeconds"
            factorTitle = "Welch window length";
        case "WelchWindowOverlap"
            factorTitle = "Welch window overlap";
        otherwise
            factorTitle = lower(string(fallbackLabel));
    end

end
