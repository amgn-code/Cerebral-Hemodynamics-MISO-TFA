function definitionsTable = createMetricDefinitionsTable()
% createMetricDefinitionsTable Explain abbreviated batch sheet metrics.

    definitionsTable = table( ...
        [
            "MAP_Power"
            "CO2_Power"
            "CBV_Power"
            "MAP_Gain"
            "CO2_Gain"
            "MAP_PhW"
            "MAP_PhU"
            "CO2_PhW"
            "CO2_PhU"
            "MultCoh"
            "MAP_PartCoh"
            "CO2_PartCoh"
            "MAP_Coh"
            "CO2_Coh"
            "InputCoh"
            "Input_PhW"
            "Unexplained"
            "Residual"
            "CondNum"
            "Pct_"
        ], ...
        [
            "Processed MAP power in dB."
            "Processed CO2 power in dB."
            "Processed CBV power in dB."
            "MAP-to-CBV transfer-function gain."
            "CO2-to-CBV transfer-function gain."
            "MAP-to-CBV wrapped phase in radians."
            "MAP-to-CBV unwrapped phase in radians."
            "CO2-to-CBV wrapped phase in radians."
            "CO2-to-CBV unwrapped phase in radians."
            "MISO multiple coherence."
            "MISO MAP partial coherence given CO2."
            "MISO CO2 partial coherence given MAP."
            "SISO MAP-to-CBV pairwise coherence."
            "SISO CO2-to-CBV pairwise coherence."
            "MAP-to-CO2 input coherence."
            "MAP-to-CO2 wrapped phase difference in radians."
            "One minus the applicable coherence."
            "Unexplained CBV power in dB."
            "Condition number of the MISO input spectral matrix."
            "Percentage of values passing the coherence threshold."
        ], ...
        'VariableNames', {'Metric', 'Meaning'});

end
