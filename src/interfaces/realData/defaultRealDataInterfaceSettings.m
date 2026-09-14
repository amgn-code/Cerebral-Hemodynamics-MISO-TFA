function settings = defaultRealDataInterfaceSettings()
% defaultRealDataInterfaceSettings Return the real-data interface settings.
%
% The file path is deliberately separate from model settings. MISO and SISO
% can therefore be configured independently before the combined interface
% runs them on the same connected recording.

    settings.filePath = "";
    settings.miso = defaultMisoRealDataSettings();
    settings.siso = defaultSisoRealDataSettings();

end
