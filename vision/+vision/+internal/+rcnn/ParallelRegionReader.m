% Parallel region reader for pre-fetching image regions to fill
% mini-batches for training. 
%
% Copyright 2016 The MathWorks, Inc.
classdef ParallelRegionReader < vision.internal.rcnn.RegionReader
   
    properties
        % Pool The parpool to use for parallel processing.
        Pool
        
        % ReadFutureBuffer A vector of future objects that hold the result
        %                  of the parallel pre-fetching operation.
        ReadFutureBuffer       
        
        % Constant copies of static data that is sent to the workers. This
        % avoids transferring this data each time we call process an epoch.
        WorkerDatastore
        WorkerTable
        WorkerTrainingSamples
        WorkerRegionResizer
        WorkerRandomSelector
    end
  
    methods        
        
        %------------------------------------------------------------------
        function this = ParallelRegionReader(groundTruth, regionProposals, params)            
         
            this = this@vision.internal.rcnn.RegionReader(...
                groundTruth, regionProposals, params);
            
            % Assign the pool to use for pre-fetching image regions.
            this.Pool = gcp('nocreate');
            if isempty(this.Pool)
                this.Pool = tryToCreateLocalPool();                
            end
            
            % Initialize data on the workers.
            this.copyDataToWorkersAsConstant();
        end
        
        %------------------------------------------------------------------
        function [miniBatchData, miniBatchResponse, miniBatchIndices] = readNextBatch(this)
            % next   Get the data and response for the next mini batch and
            % correspondent indices
            
            if ~isempty(this.ReadFutureBuffer)
                
                future = this.ReadFutureBuffer(1);
                
                [miniBatchData, miniBatchResponse] = fetchOutputs(future);
                
                this.ReadFutureBuffer(1) = [];
                                               
                n = size(miniBatchData,4);
                miniBatchIndices = (1:n)' + n*(this.NumMiniBatches);
                this.NumMiniBatches = this.NumMiniBatches + 1;
                
                % Kick off next reads
                this.fillReadBuffer;
            end                       
        end
        
        %------------------------------------------------------------------
        function start(this)
            reset( this.Datastore );
            this.CurrentImageIndex = 1;
            this.Start = 1;
            this.NumMiniBatches = 0;
            this.IsEndOfEpoch = false;
                        
            % Kill existing work
            for w = 1:length(this.ReadFutureBuffer)
                cancel(this.ReadFutureBuffer(w));
            end
            this.ReadFutureBuffer = parallel.FevalFuture.empty;
            
            % start scanning for regions
            this.nextBatch(); 
            
            % Make sure the read buffer is full
            this.fillReadBuffer;
            
        end       
        
        %------------------------------------------------------------------
        function shuffle(this)
            % shuffle   Shuffle the data
            
            shuffle@vision.internal.rcnn.RegionReader(this);
            
            % Kill existing work
            for w = 1:length(this.ReadFutureBuffer)
                cancel(this.ReadFutureBuffer(w));
            end
            this.ReadFutureBuffer = parallel.FevalFuture.empty;
            
            % Update workers copies
            this.copyDataToWorkersAsConstant();
            
            this.nextBatch(); % initialize start/stop
            
            % Make sure read buffer is full
            this.fillReadBuffer()
        end
        
        %------------------------------------------------------------------
        % Return true when the future buffer is empty and IsEndOfEpoch is
        % true. Otherwise return false. 
        %------------------------------------------------------------------
        function tf = isDone(this)
            if isempty(this.ReadFutureBuffer) && this.IsEndOfEpoch
                tf = true;
            else
                tf = false;
            end
        end
    end
    
    %======================================================================
    methods (Access = private)
        
        %------------------------------------------------------------------
        function copyDataToWorkersAsConstant(this)
            % Copy data to workers as constant.
            this.WorkerDatastore       = parallel.pool.Constant(this.Datastore);
            this.WorkerTrainingSamples = parallel.pool.Constant(this.TrainingSamples);
            this.WorkerTable           = parallel.pool.Constant(this.Table);
            this.WorkerRegionResizer   = parallel.pool.Constant(this.RegionResizer);
            this.WorkerRandomSelector  = parallel.pool.Constant(this.RandomSelector);
            
        end
        
        %------------------------------------------------------------------        
        function fillReadBuffer( this )

            while ~this.IsEndOfEpoch && ...
                    length(this.ReadFutureBuffer) < this.Pool.NumWorkers
                
                start = this.Start;
                stop  = this.Stop;
                
                this.CurrentImageIndex = this.CurrentImageIndex + stop - start;
                               
                future = parfeval(this.Pool, @vision.internal.rcnn.batchReadAndCropParallel, 2, ...
                    this.WorkerDatastore, this.WorkerTable, this.WorkerTrainingSamples, this.WorkerRegionResizer, this.WorkerRandomSelector, ...
                    start, stop, this.NumPositiveSamplesPerBatch, this.NumPos, this.MiniBatchSize);
                
                this.ReadFutureBuffer(end+1) = future;
                
                this.nextBatch();   % updates IsEndOfEpoch
            end
            
        end                
    end
end

function pool = tryToCreateLocalPool()
defaultProfile = ...
    parallel.internal.settings.ProfileExpander.getClusterType(parallel.defaultClusterProfile());

if(defaultProfile == parallel.internal.types.SchedulerType.Local)
    % Create the default pool (ensured local)
    pool = parpool;
else
    % Default profile not local   
    error(message('vision:vision_utils:noLocalPool', parallel.defaultClusterProfile()));    
end
end
