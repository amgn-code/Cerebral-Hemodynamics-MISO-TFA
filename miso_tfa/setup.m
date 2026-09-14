function project = setup()
% setup Add the self-contained MISO-TFA project to the MATLAB path.
%
% Call this function once from a clean MATLAB session before using any of
% the interface pages. The project does not depend on the parent repository
% folders.

    projectRoot = fileparts(mfilename("fullpath"));
    addpath(fullfile(projectRoot, "interfaces"));
    addpath(fullfile(projectRoot, "config"));
    addpath(genpath(fullfile(projectRoot, "modules")));

    project.root = projectRoot;
    project.interfaces = fullfile(projectRoot, "interfaces");
    project.config = fullfile(projectRoot, "config");
    project.modules = fullfile(projectRoot, "modules");
    project.tests = fullfile(projectRoot, "tests");
    project.output = fullfile(projectRoot, "output");

end
