function setupPlatform()
% setupPlatform Add the clean platform pages and shared backend modules.

    platformRoot = fileparts(mfilename("fullpath"));
    projectRoot = fileparts(platformRoot);

    addpath(genpath(fullfile(projectRoot, "src")));
    addpath(genpath(fullfile(platformRoot, "interfaces")));

end
