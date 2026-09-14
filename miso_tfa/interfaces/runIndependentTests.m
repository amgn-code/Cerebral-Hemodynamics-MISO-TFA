function results = runIndependentTests()
% runIndependentTests Run every independent-project test class.
%
% The files are run one class at a time so the command remains readable in a
% MATLAB session and a failure identifies the owning test file directly.

    project = setup();
    testFiles = dir(fullfile(project.tests, "*Test.m"));
    testFiles = testFiles(~[testFiles.isdir]);
    [~, order] = sort(string({testFiles.name}));
    testFiles = testFiles(order);

    resultParts = cell(numel(testFiles), 1);
    for fileIndex = 1:numel(testFiles)
        testPath = fullfile(testFiles(fileIndex).folder, ...
            testFiles(fileIndex).name);
        currentResults = runtests(testPath);
        resultParts{fileIndex} = currentResults(:);
    end

    if isempty(resultParts)
        results = matlab.unittest.TestResult.empty(0, 1);
    else
        results = vertcat(resultParts{:});
    end

end
