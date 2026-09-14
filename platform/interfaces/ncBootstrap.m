function results = ncBootstrap(dataFolder, settings)
% ncBootstrap Run the NC subject bootstrap validation page.
%
% Example:
%   setupPlatform
%   results = ncBootstrap("/path/to/ieem_data");
%
% The returned frequencyTable contains the held-out SISO and MISO errors,
% the signed MISO advantage, subject counts, and bootstrap uncertainty.

    setupPlatform();

    if nargin < 1 || isempty(dataFolder)
        error( ...
            "TFA:MissingNCDataFolder", ...
            "Provide the folder that contains the NC subfolder.");
    end
    if nargin < 2 || isempty(settings)
        settings = defaultNcBootstrapSettings();
    end

    results = runNcBootstrap(dataFolder, settings);
    settings = results.settings;

    if settings.plot.enabled
        [results.figureHandle, results.plotSourceData] = ...
            plotNcBootstrapAdvantage(results, settings.plot);
    else
        results.plotSourceData = results.frequencyTable;
    end

    results.interfaceName = "ncBootstrap";

end
