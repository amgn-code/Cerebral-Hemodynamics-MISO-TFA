function results = runMisoSisoTfaFromFile(filePath, analysisSettings)
% runMisoSisoTfaFromFile Analyze one user-selected recording.
%
% This is the small entry point for the user-facing workflow. It accepts
% one Excel file, uses the shared loading and analysis modules, and returns
% the SISO and MISO results together. It does not create figures, Excel
% workbooks, or simulation results.
%
% Example:
%   filePath = "/path/to/recording.xlsx";
%   results = runMisoSisoTfaFromFile(filePath);
%   results.misoResults.diagnostics.multipleMinusMapCoherence
%
% A caller can pass a complete analysisSettings structure when a different
% frequency range, Welch window, or phase method is needed.

    interfaceSettings = defaultRealDataInterfaceSettings();
    if nargin >= 2 && ~isempty(analysisSettings)
        interfaceSettings.miso = analysisSettings;
        interfaceSettings.siso = analysisSettings;
    end

    results = runMisoSisoRealData( ...
        filePath, interfaceSettings);

end
