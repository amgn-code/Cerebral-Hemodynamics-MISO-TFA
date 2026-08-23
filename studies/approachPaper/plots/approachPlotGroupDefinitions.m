function groups = approachPlotGroupDefinitions()
% approachPlotGroupDefinitions Define stable export folders for Paper 1.

    groupNumber = (1:24)';
    folderName = [ ...
        "01_Simulated_System"
        "02_Generator_Validation"
        "03_Recording_Duration"
        "04_CBFV_Output_Noise"
        "05_MAP_Measurement_Noise"
        "06_PETCO2_Measurement_Noise"
        "07_Input_Coherence"
        "08_PSD_Shape_Overlap"
        "09_PETCO2_to_MAP_Fluctuation_SD_Ratio"
        "10_PETCO2_to_MAP_Pathway_Band_Gain_Ratio"
        "11_Realized_PETCO2_Contribution_Power_Share"
        "12_True_PETCO2_Response_Delay"
        "13_PETCO2_Timing_Misalignment"
        "14_Ridge_Regularization"
        "15_Welch_Window_Length"
        "16_Welch_Window_Overlap"
        "17_Coherence_by_PSD_Overlap"
        "18_Fluctuation_by_Pathway_Gain"
        "19_Duration_by_Welch_Window"
        "20_Delay_by_Misalignment"
        "21_NC_Simulation_Coverage"
        "22_NC_Operating_Map_Placement"
        "23_NC_Model_Comparison"
        "24_NC_Robustness"];
    title = replace(folderName, "_", " ");

    groups = table( ...
        groupNumber, folderName, title, ...
        'VariableNames', {'GroupNumber', 'FolderName', 'Title'});

end
