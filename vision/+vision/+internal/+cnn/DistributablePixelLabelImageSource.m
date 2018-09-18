classdef DistributablePixelLabelImageSource < nnet.internal.cnn.DistributableMiniBatchDatasource
    
    %   Copyright 2017 The MathWorks, Inc.
    
    properties (Hidden, Constant)
        CanPreserveOrder = true;
    end
    
    methods(Hidden)
        
        function [distributedData, subBatchSizes] = distribute( this, proportions )
        % distribute   Split the dispatcher into partitions according to
        % the given proportions

            % Create a cell array of datastores containing one portion of
            % the input datastore per entry in the partitions array.
            [ dsPartitions, pxdsPartitions, subBatchSizes ] = ...
                iSplitDatastore( this.ImageDatastore, this.PixelLabelDatastore, this.MiniBatchSize, proportions );
            
            % Create an pixelLabelImageSource containing each of those
            % datastores.
            numPartitions = numel(proportions);
            distributedData = cell(numPartitions, 1);
            for p = 1:numPartitions
                if isempty( dsPartitions{p} )
                    distributedData{p} = pixelLabelImageSource.empty();
                else
                    distributedData{p} = pixelLabelImageSource( ...
                        dsPartitions{p}, pxdsPartitions{p}, ...
                        'DataAugmentation', this.DataAugmentation, ...
                        'ColorPreprocessing', this.ColorPreprocessing, ...
                        'OutputSize', this.OutputSize, ...
                        'OutputSizeMode', this.OutputSizeMode,...
                        'BackgroundExecution',this.UseParallel);                    
                    distributedData{p}.MiniBatchSize = subBatchSizes(p);
                end
                
            end
        end
        
    end
end

function [imdsPartitions, pxdsPartitions, subBatchSizes] = iSplitDatastore( ...
    imds, pxds, miniBatchSize, proportions )
% Divide up datastore by files according to the given proportions

import nnet.internal.cnn.DistributableMiniBatchDatasource.interleavedSelectionByWeight;

numObservations= numel(imds.Files);
numPartitions = numel(proportions);
imdsPartitions = cell(numPartitions, 1);
pxdsPartitions = cell(numPartitions, 1);

% Get the list of indices into the data for each partition
[indicesCellArray, subBatchSizes] = interleavedSelectionByWeight( ...
    numObservations, miniBatchSize, proportions );

% Loop through copying and indexing into the data to create the partitions
for p = 1:numPartitions
    if subBatchSizes(p) > 0
        % Take a copy of the datastore
        subds = copy(imds);
        subpxds = copy(pxds);
        
        % Prune all files not in the partition. This correctly selects
        % Labels as well.
        mask = true(numObservations, 1);
        mask(indicesCellArray{p}) = false;
        subds.Files(mask) = [];
        
        subpxds.removeFiles(mask);
                
        imdsPartitions{p} = subds;
        pxdsPartitions{p} = subpxds;
    end
end
end

