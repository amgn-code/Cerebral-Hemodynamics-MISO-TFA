function report = checkIndependentDependencies()
% checkIndependentDependencies Audit active pages for parent-project calls.
%
% MATLAB toolbox files are allowed. The report flags only files resolved from
% the parent repository outside this self-contained project folder.

projectRoot = fileparts(fileparts(mfilename("fullpath")));
parentRoot = fileparts(projectRoot);
entryPoints = [ ...
    "connectData"
    "misoTesting"
    "sisoTesting"
    "ncBootstrap"
    "simulationSettings"
    "runSimulation"
    "runFinalSimulationStudy"
    "exportFinalSimulationStudy"
    "createFinalMisoTfaReport"
    "generateManuscriptAssets"
    "buildManuscript"];

entryPointName = strings(numel(entryPoints), 1);
requiredFileCount = zeros(numel(entryPoints), 1);
externalFileCount = zeros(numel(entryPoints), 1);
externalFiles = cell(numel(entryPoints), 1);

for entryPointIndex = 1:numel(entryPoints)
    entryFile = which(entryPoints(entryPointIndex));
    assert(~isempty(entryFile), "TFA:MissingEntryPoint", ...
        "Entry point %s is missing. Run setup before auditing dependencies.", ...
        entryPoints(entryPointIndex));
    [files, ~] = matlab.codetools.requiredFilesAndProducts(entryFile);
    paths = string(files(:));
    parentProjectFile = startsWith(paths, string(parentRoot) + filesep) & ...
        ~startsWith(paths, string(projectRoot) + filesep);
    entryPointName(entryPointIndex) = entryPoints(entryPointIndex);
    requiredFileCount(entryPointIndex) = numel(paths);
    externalFileCount(entryPointIndex) = nnz(parentProjectFile);
    externalFiles{entryPointIndex} = paths(parentProjectFile);
end

report = table( ...
    entryPointName, requiredFileCount, externalFileCount, externalFiles, ...
    'VariableNames', { ...
        'EntryPoint', 'RequiredFileCount', 'ExternalProjectFileCount', ...
        'ExternalProjectFiles'});

end
