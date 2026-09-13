function [levelIndices, blockId, baseRow] = ...
    createPairwiseBalancedFiveLevelDesign(numFamilies)
% createPairwiseBalancedFiveLevelDesign Create balanced five-factor blocks.
%
% Each 25-row block contains five factors with five levels. Every level is
% used five times in each factor, and every pair of factors contains all 25
% level combinations exactly once. The function uses the active random
% stream to permute level labels and row order independently in each block.

    arguments
        numFamilies (1,1) double {mustBeInteger, mustBePositive}
    end

    blockSize = 25;
    numLevels = 5;
    numFactors = 5;
    if mod(numFamilies, blockSize) ~= 0
        error( ...
            "TFA:PairwiseDesignRequiresCompleteBlocks", ...
            ['The pairwise five-level design requires a family count ' ...
             'that is a multiple of 25.']);
    end

    [firstCoordinate, secondCoordinate] = ...
        ndgrid(0:(numLevels - 1), 0:(numLevels - 1));
    firstCoordinate = firstCoordinate(:);
    secondCoordinate = secondCoordinate(:);
    baseDesign = [ ...
        firstCoordinate, ...
        secondCoordinate, ...
        mod(firstCoordinate + secondCoordinate, numLevels), ...
        mod(firstCoordinate + 2*secondCoordinate, numLevels), ...
        mod(firstCoordinate + 3*secondCoordinate, numLevels)] + 1;

    numBlocks = numFamilies/blockSize;
    levelIndices = zeros(numFamilies, numFactors);
    blockId = zeros(numFamilies, 1);
    baseRow = zeros(numFamilies, 1);

    for blockIndex = 1:numBlocks
        currentDesign = baseDesign;
        for factorIndex = 1:numFactors
            levelOrder = randperm(numLevels);
            currentDesign(:,factorIndex) = ...
                levelOrder(currentDesign(:,factorIndex));
        end
        rowOrder = randperm(blockSize);
        rows = (blockIndex - 1)*blockSize + (1:blockSize);
        levelIndices(rows,:) = currentDesign(rowOrder,:);
        blockId(rows) = blockIndex;
        baseRow(rows) = rowOrder;
    end

end
