classdef proofOfConceptFamilyDesignTest < matlab.unittest.TestCase
    % proofOfConceptFamilyDesignTest Verify named profiles and balance.

    methods (TestClassSetup)
        function addProjectFolders(testCase)
            projectRoot = fileparts(fileparts(mfilename("fullpath")));
            testCase.applyFixture( ...
                matlab.unittest.fixtures.PathFixture( ...
                    projectRoot, IncludingSubfolders=true));
        end
    end

    methods (TestMethodSetup)
        function preserveRandomState(testCase)
            originalState = rng;
            testCase.addTeardown(@() rng(originalState));
        end
    end

    methods (Test)
        function namedProfilesHaveExpectedSizes(testCase)
            quick = defaultKnownTruthSimulationSettings("quick");
            smoke = defaultKnownTruthSimulationSettings("designSmoke");
            proof = defaultKnownTruthSimulationSettings("proof250");
            paper = defaultKnownTruthSimulationSettings("paper1000");
            historical = defaultKnownTruthSimulationSettings("paper");

            testCase.verifyEqual(quick.families.numFamilies, 8);
            testCase.verifyEqual(smoke.families.numFamilies, 25);
            testCase.verifyEqual(proof.families.numFamilies, 250);
            testCase.verifyEqual(paper.families.numFamilies, 1000);
            testCase.verifyEqual(historical.profileName, "paper1000");
            testCase.verifyEqual( ...
                proof.families.designMode, "pairwiseFiveLevel");
            testCase.verifyEqual( ...
                proof.grouping.inputCoherenceEdges, 0:0.2:1, ...
                AbsTol=1e-12);
            testCase.verifyEqual( ...
                paper.grouping.inputCoherenceEdges, 0:0.1:1, ...
                AbsTol=1e-12);
        end

        function oneBlockContainsEveryPairOnce(testCase)
            rng(41, "twister");
            [levels, blockId, baseRow] = ...
                createPairwiseBalancedFiveLevelDesign(25);

            testCase.verifySize(levels, [25 5]);
            testCase.verifyEqual( ...
                marginalCounts(levels), 5*ones(5, 5));
            testCase.verifyEqual( ...
                pairCounts(levels), ones(25, 10));
            testCase.verifyEqual(blockId, ones(25, 1));
            testCase.verifyEqual(sort(baseRow), (1:25)');
        end

        function proofDesignHasTenFamiliesPerPair(testCase)
            rng(42, "twister");
            [levels, blockId] = ...
                createPairwiseBalancedFiveLevelDesign(250);

            testCase.verifyEqual( ...
                marginalCounts(levels), 50*ones(5, 5));
            testCase.verifyEqual( ...
                pairCounts(levels), 10*ones(25, 10));
            testCase.verifyEqual( ...
                histcounts(blockId, 0.5:1:10.5)', 25*ones(10, 1));
        end

        function proofProfileBuildsBalancedFamilyTable(testCase)
            settings = defaultKnownTruthSimulationSettings("proof250");
            design = createKnownTruthFamilyDesign(settings);
            levels = extractLevelMatrix(design);

            testCase.verifyEqual(height(design), 250);
            testCase.verifyEqual( ...
                marginalCounts(levels), 50*ones(5, 5));
            testCase.verifyEqual( ...
                pairCounts(levels), 10*ones(25, 10));
            testCase.verifyEqual( ...
                histcounts(design.DesignBlockID, 0.5:1:10.5)', ...
                25*ones(10, 1));
        end

        function paperDesignHasFortyFamiliesPerPair(testCase)
            rng(43, "twister");
            [levels, blockId] = ...
                createPairwiseBalancedFiveLevelDesign(1000);

            testCase.verifyEqual( ...
                marginalCounts(levels), 200*ones(5, 5));
            testCase.verifyEqual( ...
                pairCounts(levels), 40*ones(25, 10));
            testCase.verifyEqual(numel(unique(blockId)), 40);
        end

        function familyDesignIsReproducibleAndRetainsContinuousVariation( ...
                testCase)
            settings = defaultKnownTruthSimulationSettings("designSmoke");
            first = createKnownTruthFamilyDesign(settings);
            second = createKnownTruthFamilyDesign(settings);

            testCase.verifyEqual(first, second);
            testCase.verifyEqual( ...
                marginalCounts(extractLevelMatrix(first)), ...
                5*ones(5, 5));
            testCase.verifyEqual( ...
                pairCounts(extractLevelMatrix(first)), ...
                ones(25, 10));
            testCase.verifyEqual( ...
                numel(unique(first.MAPPathwayTimeConstantSeconds)), 25);
            testCase.verifyEqual( ...
                numel(unique(first.CO2PathwayTimeConstantSeconds)), 25);
            testCase.verifyGreaterThanOrEqual( ...
                first.MAPPathwayTimeConstantSeconds, 1);
            testCase.verifyLessThanOrEqual( ...
                first.MAPPathwayTimeConstantSeconds, 4);
            testCase.verifyGreaterThanOrEqual( ...
                first.CO2PathwayTimeConstantSeconds, 2);
            testCase.verifyLessThanOrEqual( ...
                first.CO2PathwayTimeConstantSeconds, 8);
        end

        function proofProfileHasExpectedAnalysisCounts(testCase)
            settings = defaultKnownTruthSimulationSettings("proof250");
            observationPlan = createKnownTruthObservationPlan(settings);
            estimatorRowsPerFamily = ...
                numel(settings.estimatorSensitivity.windowLengthSeconds) + ...
                numel(settings.estimatorSensitivity.windowOverlap) + ...
                numel(settings.observations.durationSeconds)* ...
                numel(settings.estimatorSensitivity.windowLengthSeconds);

            testCase.verifyEqual(height(observationPlan), 68);
            testCase.verifyEqual( ...
                height(observationPlan)*settings.families.numFamilies, ...
                17000);
            testCase.verifyEqual( ...
                estimatorRowsPerFamily*settings.families.numFamilies, ...
                10750);
            testCase.verifyEqual( ...
                numel(settings.estimators.ridgeLambdas)* ...
                settings.families.numFamilies, 750);
        end

        function incompleteBlockFailsClearly(testCase)
            settings = defaultKnownTruthSimulationSettings("designSmoke");
            settings.families.numFamilies = 24;

            testCase.verifyError( ...
                @() createKnownTruthFamilyDesign(settings), ...
                "TFA:PairwiseDesignRequiresCompleteBlocks");
        end

        function nonFiveLevelFactorFailsClearly(testCase)
            settings = defaultKnownTruthSimulationSettings("designSmoke");
            settings.families.targetCoherenceValues = [0.1 0.4 0.7 0.9];

            testCase.verifyError( ...
                @() createKnownTruthFamilyDesign(settings), ...
                "TFA:PairwiseDesignRequiresFiveLevels");
        end

        function duplicateFactorLevelFailsClearly(testCase)
            settings = defaultKnownTruthSimulationSettings("designSmoke");
            settings.families.co2DelaySecondsValues = [0 2.5 5 5 10];

            testCase.verifyError( ...
                @() createKnownTruthFamilyDesign(settings), ...
                "TFA:DuplicateFamilyFactorLevel");
        end

        function unknownProfileFailsClearly(testCase)
            testCase.verifyError( ...
                @() defaultKnownTruthSimulationSettings("unknown"), ...
                "TFA:UnknownSimulationProfile");
        end
    end
end

function levels = extractLevelMatrix(design)
% extractLevelMatrix Return the five saved factor-level columns.

    levels = [ ...
        design.TargetInputCoherenceLevel, ...
        design.SpectralSimilarityLevel, ...
        design.PETCO2ToMAPFluctuationSDRatioLevel, ...
        design.PETCO2ToMAPBandGainRatioLevel, ...
        design.CO2DelayLevel];

end

function counts = marginalCounts(levels)
% marginalCounts Count each level in every factor.

    counts = zeros(5, 5);
    for factorIndex = 1:5
        counts(:,factorIndex) = ...
            histcounts(levels(:,factorIndex), 0.5:1:5.5)';
    end

end

function counts = pairCounts(levels)
% pairCounts Count all 25 combinations for every factor pair.

    factorPairs = nchoosek(1:5, 2);
    numPairs = size(factorPairs, 1);
    counts = zeros(25, numPairs);
    for pairIndex = 1:numPairs
        firstFactor = factorPairs(pairIndex, 1);
        secondFactor = factorPairs(pairIndex, 2);
        combinationIndex = ...
            (levels(:,firstFactor) - 1)*5 + levels(:,secondFactor);
        counts(:,pairIndex) = ...
            histcounts(combinationIndex, 0.5:1:25.5)';
    end

end
