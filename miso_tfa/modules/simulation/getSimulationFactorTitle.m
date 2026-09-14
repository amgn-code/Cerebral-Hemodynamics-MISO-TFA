function factorTitle = getSimulationFactorTitle( ...
    factorName, fallbackLabel)
% getSimulationFactorTitle Return a concise phrase for figure titles.

    factorName = string(factorName);
    switch factorName
        case "DurationSeconds"
            factorTitle = "recording duration";
        case "OutputSNRdB"
            factorTitle = "broadband CBFV output SNR";
        case {"FamilyInputCoherence", "RealizedInputCoherence"}
            factorTitle = "input coherence";
        case {"FamilyPSDShapeOverlap", "RealizedPSDShapeOverlap"}
            factorTitle = "PSD-shape overlap";
        case { ...
                "AssignedPETCO2ToMAPFluctuationSDRatio", ...
                "FamilyPETCO2ToMAPFluctuationSDRatio", ...
                "RealizedPETCO2ToMAPFluctuationSDRatio"}
            factorTitle = "PETCO2/MAP fluctuation ratio";
        case { ...
                "AssignedPETCO2ToMAPBandGainRatio", ...
                "AchievedPETCO2ToMAPBandGainRatio"}
            factorTitle = "PETCO2/MAP pathway gain";
        case { ...
                "FamilyPETCO2ContributionPowerShare", ...
                "RealizedPETCO2ContributionPowerShare"}
            factorTitle = "PETCO2 contribution share";
        case "CO2DelaySeconds"
            factorTitle = "true PETCO2 delay";
        case "AlignmentErrorSeconds"
            factorTitle = "PETCO2 timing misalignment";
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
