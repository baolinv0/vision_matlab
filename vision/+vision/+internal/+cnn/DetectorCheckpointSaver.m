classdef DetectorCheckpointSaver < nnet.internal.cnn.util.Reporter
    % DetectorCheckpointSaver   This class is used to save detector
    % checkpoints during network training. Use this class if you have a
    % detector that contains a network that you'd like to checkpoint.

    %   Copyright 2016-2017 The MathWorks, Inc.
    
    properties
        CheckpointPath
        
        % ConvertorFcn   Handle to function to convert an internal network
        % before saving it
        %
        % Default: identity, i.e., don't convert
        ConvertorFcn = @(x)x                   
        
        % Copy of the partially trained detector. Detector have a one or
        % more networks. The DetectorFcn assigns networks into the detector
        % and then saves the detector.
        Detector
        
        % DetectorFcn Detector function called for assigning network
        % checkpoint into this.Detector.                
        DetectorFcn
        
        % CheckpointPrefix String prefix to use for the checkpoint mat
        % filename, e.g. fast_rcnn or faster_rcnn.
        CheckpointPrefix
    end
    
    methods
        function this = DetectorCheckpointSaver( path )            
            this.CheckpointPath = path;                                    
        end
        
        function setup( ~ )
        end
        
        function start( ~ )
        end
        
        function reportIteration( ~, ~, ~, ~, ~, ~, ~ )
        end
        
        function reportEpoch( this, ~, iteration, network )
            this.saveCheckpoint( network, iteration );
        end
        
        function finish( ~ )
        end
    end
    
    methods(Access = private)
        function saveCheckpoint(this, net, iteration)
            assert(~isempty(this.CheckpointPrefix));
            assert(~isempty(this.Detector));
            
            checkpointPath = this.CheckpointPath;
            
            name = this.generateCheckpointName(iteration);
            
            fullPath = fullfile(checkpointPath, name);
            
            % convert internal network to external network.
            network = this.ConvertorFcn(net);
            
            % store external network into detector checkpoint.
            detector = this.DetectorFcn(network, this.Detector);
            
            iSaveDetector(fullPath, detector);
        end
        
        function name = generateCheckpointName(this, iteration)
            basename = [this.CheckpointPrefix '_checkpoint'];
            timestamp = char(datetime('now', 'Format', 'yyyy_MM_dd__HH_mm_ss'));
            name = [ basename '__' int2str(iteration) '__' timestamp '.mat' ];
        end
    end
end

function iSaveDetector(fullPath,detector)
try
    iSave(fullPath, 'detector', detector);
catch e
    warning( message('nnet_cnn:internal:cnn:Trainer:SaveCheckpointFailed', fullPath, e.message ) )
end
end

function iSave(fullPath, name, value)
S.(name) = value; %#ok<STRNU>
save(fullPath, '-struct', 'S', name);
end


