function manifestTable = createApproachPaperManifest(settings)
% createApproachPaperManifest Record software and analysis provenance.

    [gitStatus, gitHash] = system("git rev-parse HEAD");
    if gitStatus ~= 0
        gitHash = "Unavailable";
    else
        gitHash = strtrim(string(gitHash));
    end

    productInfo = ver;
    productDescriptions = strings(numel(productInfo), 1);
    for productIndex = 1:numel(productInfo)
        productDescriptions(productIndex) = ...
            string(productInfo(productIndex).Name) + " " + ...
            string(productInfo(productIndex).Version);
    end

    item = [ ...
        "Created"
        "MATLAB version"
        "Operating system"
        "Git commit"
        "Profile"
        "Random seed"
        "Installed MATLAB products"];
    value = [ ...
        string(datetime("now", "TimeZone", "local"))
        string(version)
        string(system_dependent("getos"))
        gitHash
        string(settings.profileName)
        string(settings.simulation.randomSeed)
        join(productDescriptions, "; ")];

    manifestTable = table(item, value, ...
        'VariableNames', {'Item', 'Value'});

end
