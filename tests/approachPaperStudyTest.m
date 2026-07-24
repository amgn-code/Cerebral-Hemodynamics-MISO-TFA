classdef approachPaperStudyTest < matlab.unittest.TestCase
    % approachPaperStudyTest Verify the user-facing Paper 1 package.

    methods (TestClassSetup)
        function addProjectFolders(testCase)
            projectRoot = fileparts(fileparts(mfilename('fullpath')));
            testCase.applyFixture( ...
                matlab.unittest.fixtures.PathFixture( ...
                    projectRoot, IncludingSubfolders=true));
        end
    end

    methods (Test)
        function settingsDescribeNcOnlyStatisticalPlan(testCase)
            settings = approachPaperSettings( ...
                "/example/data", "/example/output", "quick");
            analysis = validateTfaSettings(settings.analysis);

            testCase.verifyEqual( ...
                analysis.statistics.groupsToCompare, "NC");
            testCase.verifyEqual( ...
                analysis.statistics.primaryPathways, "MAP");
            testCase.verifyEqual( ...
                analysis.statistics.secondaryPathways, "CO2");
            testCase.verifyFalse( ...
                analysis.statistics.betweenGroupComparison.enabled);
            testCase.verifyTrue( ...
                analysis.statistics.frequencyWise.modelComparison.phase);
            testCase.verifyTrue(analysis.retainAnalysisInput);
            testCase.verifyFalse( ...
                analysis.misoSolver.regularization.enabled);
        end

        function figureExporterCreatesRequestedFile(testCase)
            outputFolder = tempname();
            mkdir(outputFolder);
            testCase.addTeardown(@() rmdir(outputFolder, "s"));
            figureHandle = plotApproachFigure1Concept();
            testCase.addTeardown(@() close(figureHandle));

            exportSettings.widthInches = 4;
            exportSettings.heightInches = 3;
            exportSettings.pngResolution = 72;
            exportSettings.savePdf = false;
            exportSettings.savePng = true;
            files = exportApproachPaperFigure( ...
                figureHandle, fullfile(outputFolder, "figure_1"), ...
                exportSettings);

            testCase.verifyEqual(numel(files), 1);
            testCase.verifyTrue(isfile(files(1)));
        end

        function emptyRobustnessPanelsRemainExplicit(testCase)
            robustness.surrogateSummary = table();
            robustness.surrogateGroupDistribution = table();
            robustness.delaySummary = table();
            robustness.sensitivitySummary = table();
            robustness.lambdaSummary = table();

            [figureHandle, sourceData] = ...
                plotApproachFigure6Robustness(robustness);
            testCase.addTeardown(@() close(figureHandle));

            testCase.verifyTrue(isgraphics(figureHandle));
            testCase.verifyTrue(istable(sourceData.surrogate));
        end

        function frequencyPhaseFigureShowsBothPathways(testCase)
            frequencyHz = repmat([0.01; 0.02; 0.03], 2, 1);
            pathway = [repmat("MAP", 3, 1); repmat("CO2", 3, 1)];
            metric = repmat("Phase", 6, 1);
            misoMean = linspace(-0.4, 0.4, 6)';
            sisoMean = 0.8*misoMean;
            principalDelay = ...
                -(misoMean - sisoMean)./(2*pi*frequencyHz);
            misoCoherence = 0.5*ones(6, 1);
            sisoCoherence = 0.6*ones(6, 1);
            rawP = linspace(0.01, 0.2, 6)';
            adjustedP = min(1, 1.5*rawP);
            phaseTable = table( ...
                frequencyHz, pathway, metric, misoMean, sisoMean, ...
                principalDelay, misoCoherence, sisoCoherence, ...
                rawP, adjustedP, ...
                'VariableNames', { ...
                    'FrequencyHz', 'Pathway', 'Metric', ...
                    'MISOMean', 'SISOMean', ...
                    'PrincipalDelayDifferenceSeconds', ...
                    'MISOCoherenceMean', 'SISOCoherenceMean', ...
                    'RawP', 'BHAdjustedP'});

            [figureHandle, sourceData] = ...
                plotApproachFrequencyPhaseComparison(phaseTable);
            testCase.addTeardown(@() close(figureHandle));

            testCase.verifyTrue(isgraphics(figureHandle));
            testCase.verifyEqual( ...
                sort(unique(sourceData.Pathway)), ...
                ["CO2"; "MAP"]);
        end
    end
end
