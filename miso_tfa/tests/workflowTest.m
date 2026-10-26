classdef workflowTest < matlab.unittest.TestCase
    % workflowTest Real-data import, cohort use, units, exports, and figures.

    methods (TestClassSetup)
        function addProject(testCase)
            folder = fileparts(fileparts(mfilename("fullpath")));
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture(folder, IncludingSubfolders=true));
            runAnalysis("settings");
        end
    end

    methods (TestMethodSetup)
        function preserveState(testCase)
            previous = rng;
            testCase.addTeardown(@() rng(previous));
            testCase.addTeardown(@() close("all"));
        end
    end

    methods (Test)
        function customHeadingsAndSubfoldersProduceGroupResults(testCase)
            [settings, folder] = dataFixture();
            testCase.addTeardown(@() rmdir(folder, "s"));
            mkdir(fullfile(folder, "Control"));
            mkdir(fullfile(folder, "OtherLab"));
            data = exampleData();
            writetable(data, fullfile(folder, "Control", "P01.csv"));
            writetable(data, fullfile(folder, "Control", "P02.csv"));
            writetable(data, fullfile(folder, "OtherLab", "P03.csv"));
            settings.data.paths = folder;
            settings.data.recursive = true;
            settings.data.groupBySubfolder = true;
            results = runAnalysis(settings);
            testCase.verifyEqual(numel(results.recordings), 3);
            testCase.verifyEqual(numel(results.groups), 2);
            testCase.verifyEqual(sort([results.groups.count]), [1 2]);
            testCase.verifyEmpty(results.simulation);
        end

        function nativeAndPercentUnitsUseTheExpectedGainScaling(testCase)
            [settings, folder] = dataFixture();
            testCase.addTeardown(@() rmdir(folder, "s"));
            data = exampleData();
            file = fullfile(folder, "P01.csv");
            writetable(data, file);
            settings.data.paths = file;
            settings.analysis.preprocessing.normalizeCbv = false;
            native = runAnalysis(settings);
            settings.analysis.preprocessing.normalizeCbv = true;
            percent = runAnalysis(settings);
            testCase.verifyEqual(median(native.recordings.miso.map.gain), 0.8, AbsTol=1e-10);
            testCase.verifyEqual(percent.recordings.miso.map.gain, ...
                native.recordings.miso.map.gain*100/mean(data.Flow), AbsTol=1e-10);
        end

        function timestampAndSignalUnitConversionsAreForwardFacing(testCase)
            [settings, folder] = dataFixture();
            testCase.addTeardown(@() rmdir(folder, "s"));
            data = exampleData();
            data.Clock = data.Clock*1000;
            data.Gas = data.Gas/7.50062;
            file = fullfile(folder, "Converted.csv");
            writetable(data, file);
            settings.data.paths = file;
            settings.data.timeScaleToSeconds = 0.001;
            settings.data.signalScale.co2 = 7.50062;
            settings.analysis.preprocessing.normalizeCbv = false;
            results = runAnalysis(settings);
            testCase.verifyEqual(median(results.recordings.miso.co2.gain), 0.6, AbsTol=1e-10);
        end

        function explicitExcelSheetOverridesTheDefaultSheetNames(testCase)
            [settings, folder] = dataFixture();
            testCase.addTeardown(@() rmdir(folder, "s"));
            file = fullfile(folder, "P01.xlsx");
            writetable(table((1:3).'), file, Sheet="Unused");
            writetable(exampleData(), file, Sheet="LabExport");
            settings.data.paths = file;
            settings.data.sheet = "LabExport";
            results = runAnalysis(settings);
            testCase.verifyEqual(numel(results.recordings), 1);
            testCase.verifyTrue(all(isfinite(results.recordings.miso.map.gain)));
        end

        function missingRequiredColumnsGiveAnActionableError(testCase)
            [settings, folder] = dataFixture();
            testCase.addTeardown(@() rmdir(folder, "s"));
            data = removevars(exampleData(), "Gas");
            file = fullfile(folder, "Missing.csv");
            writetable(data, file);
            settings.data.paths = file;
            testCase.verifyError(@() runAnalysis(settings), "TFA:MissingDataColumn");
        end

        function shortRecordingsAreRejectedRatherThanSilentlyAnalyzed(testCase)
            [settings, folder] = dataFixture();
            testCase.addTeardown(@() rmdir(folder, "s"));
            data = exampleData();
            file = fullfile(folder, "Short.csv");
            writetable(data(1:100, :), file);
            settings.data.paths = file;
            testCase.verifyError(@() runAnalysis(settings), "TFA:InsufficientWelchWindows");
        end

        function co2StartupCleanupIsRetainedAndRecorded(testCase)
            [settings, folder] = dataFixture();
            testCase.addTeardown(@() rmdir(folder, "s"));
            data = exampleData();
            data.Gas(1:32) = 0;
            file = fullfile(folder, "Startup.csv");
            writetable(data, file);
            settings.data.paths = file;
            results = runAnalysis(settings);
            removed = results.recordings.preprocessing.co2Startup.removedDurationSeconds;
            testCase.verifyGreaterThanOrEqual(removed, 8);
            testCase.verifyLessThan(removed, 10);
        end

        function exportedSettingsCanReproduceTheAnalysis(testCase)
            [settings, folder] = dataFixture();
            testCase.addTeardown(@() rmdir(folder, "s"));
            file = fullfile(folder, "P01.csv");
            writetable(exampleData(), file);
            settings.data.paths = file;
            settings.output.folder = fullfile(folder, "output");
            settings.output.saveMat = true;
            settings.output.saveCsv = true;
            first = runAnalysis(settings);
            saved = load(fullfile(settings.output.folder, "results.mat"));
            replay = saved.results.settings;
            replay.output.saveMat = false;
            replay.output.saveCsv = false;
            second = runAnalysis(replay);
            testCase.verifyEqual(first.recordings.miso.map.transferFunction, ...
                second.recordings.miso.map.transferFunction, AbsTol=0);
            testCase.verifyTrue(isfile(fullfile(settings.output.folder, "recordings.csv")));
            testCase.verifyTrue(isfile(fullfile(settings.output.folder, "group_summaries.csv")));
            testCase.verifyTrue(isfile(fullfile(settings.output.folder, "impulses.csv")));
        end

        function individualAndAverageFiguresUseTheSameNumericalResults(testCase)
            settings = runAnalysis("settings");
            settings.simulation.vary = strings(1, 0);
            settings.simulation.repetitions = 1;
            settings.simulation.bootstrapSamples = 0;
            settings.plots.visible = "off";
            settings.plots.individuals = true;
            settings.plots.showStandardDeviation = false;
            settings.output.saveMat = false;
            settings.output.saveCsv = false;
            settings.output.saveFigures = false;
            results = runAnalysis(settings);
            testCase.verifyEqual(numel(results.figures), 7);
            testCase.verifyTrue(all(isgraphics([results.figures.handle], "figure")));
        end
    end
end

function [settings, folder] = dataFixture()
    settings = runAnalysis("settings");
    settings.mode = "data";
    settings.data.columnMap.t = "Clock";
    settings.data.columnMap.map = "Pressure";
    settings.data.columnMap.co2 = "Gas";
    settings.data.columnMap.cbv = "Flow";
    settings.plots.createFigures = false;
    settings.output.saveMat = false;
    settings.output.saveCsv = false;
    settings.output.saveFigures = false;
    folder = string(tempname);
    mkdir(folder);
end

function data = exampleData()
    previous = rng;
    restore = onCleanup(@() rng(previous));
    rng(951);
    time = (0:1199)'/4;
    map = 90 + sin(2*pi*0.1*time) + 0.3*randn(size(time));
    co2 = 40 + sin(2*pi*0.06*time) + 0.3*randn(size(time));
    cbv = 60 + 0.8*(map - 90) + 0.6*(co2 - 40);
    data = table(time, map, co2, cbv, VariableNames=["Clock", "Pressure", "Gas", "Flow"]);
    clear restore
end
