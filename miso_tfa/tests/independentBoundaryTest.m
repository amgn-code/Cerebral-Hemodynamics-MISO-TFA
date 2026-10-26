classdef independentBoundaryTest < matlab.unittest.TestCase
    % independentBoundaryTest Ensure public pages stay inside miso_tfa.

    methods (TestClassSetup)
        function addProjectFolders(testCase)
            projectRoot = fileparts(fileparts(mfilename("fullpath")));
            testCase.applyFixture( ...
                matlab.unittest.fixtures.PathFixture( ...
                    projectRoot, IncludingSubfolders=true));
        end
    end

    methods (Test)
        function publicPagesHaveNoParentProjectDependencies(testCase)
            dependencyReport = checkIndependentDependencies();

            testCase.verifyEqual( ...
                dependencyReport.ExternalProjectFileCount, ...
                zeros(height(dependencyReport), 1));
        end
    end
end
