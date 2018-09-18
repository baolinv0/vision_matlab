% CustomReader Reads a custom data source using a reader function handle
% and timestamps as a duration vector. The interface must be identical (not
% exhaustive) to VideoReader.
%
% The constructor doesn't do any error checking.
%
%   Methods:
%     readNextFrame       - Read the next available frame from a video file
%     readFrameAtPosition - Read the frame at a given time or a given
%                           index. For time based seeking, the input to
%                           this function should be a duration. For frame
%                           based seeking, the input should be a integer
%                           valued numeric (including doubles)
%
%   Properties:
%     Name              - Name of the folder to be read.
%     FrameRate         - Frame rate of the custom data source in frames per second.
%     Path              - Path of the folder containing the custom data source
%     Duration          - Length of the sequence in seconds.
%     Reader            - Function handle to the custom reader function
%     LastTimestampRead - Timestamp of the last frame read.
%     Timestamps        - The timestamp vector of the custom data source.

% Copyright 2016 The MathWorks, Inc.

classdef CustomReader < handle
    
    properties (GetAccess = 'public', SetAccess = 'private')
        %Name Name of the custom data source
        Name
        
        %Path Path of the custom data source
        Path
        
        %Duration Duration of the custom data source
        Duration              duration
        
        %FrameRate FrameRate of the custom data source (set to 1)
        % The frame rate for image sequences is not clearly defined.
        % Assume it is 1.
        FrameRate
        
        %Reader Function handle to the custom reader function
        Reader
        
        %Timestamps duration vector of timestamps
        Timestamps             duration
        
        %LastTimestamp
        LastTimestampRead      duration
        
    end
    
    properties (Hidden = true, GetAccess = public, SetAccess = private)
        %NumberOfFrames Number of frames
        NumberOfFrames
        
        %CurrentTime Current time (duration scalar) of the custom data source
        CurrentTime
        
        %CurrentIndex Current index of the custom data source
        CurrentIndex
    end
    
    %----------------------------------------------------------------------
    % Public API
    %----------------------------------------------------------------------
    methods(Access='public')
        function this = CustomReader(sourceName, customReaderFunctionHandle, timestamps)
            
            % timestamps must be a column vector
            if isrow(timestamps)
                timestamps = timestamps';
            end
            
            if ~isduration(timestamps)
                timestamps = seconds(timestamps);
            end
            
            this.Reader = customReaderFunctionHandle;

            this.Name = sourceName;
            % Path is not set for custom reader. The user input,sourceName
            % is used as-is.
            this.Path = '';
            this.FrameRate = 1;
            this.CurrentTime = timestamps(1)/this.FrameRate;
            this.NumberOfFrames = numel(timestamps);
            this.Duration = seconds(this.NumberOfFrames)/this.FrameRate;
            
            this.CurrentIndex = 1;
            
            this.Timestamps = timestamps;
            this.LastTimestampRead = timestamps(this.CurrentIndex);
            
        end
        
        function I = readFrameAtPosition(this, idx)
            validateattributes(idx, {'numeric'}, {'scalar', 'nonnegative', 'integer'});
            
            if idx > this.NumberOfFrames
                error(vision.getMessage('vision:labeler:IndexExceedsNumFrames'));
            end
            
            if idx >= 1 && idx <= this.NumberOfFrames
                this.CurrentIndex = idx;
                I.Data = this.Reader(this.Name,this.Timestamps(this.CurrentIndex));
                I.Timestamp = seconds(this.Timestamps(idx));
                this.LastTimestampRead = this.Timestamps(this.CurrentIndex);
                this.CurrentTime = this.CurrentIndex/this.FrameRate;
            end
        end
        
        function I = readNextFrame(this)
            
            I = [];
            
            if this.CurrentIndex ~= this.NumberOfFrames
                this.CurrentIndex = this.CurrentIndex+1;
                I.Data = this.Reader(this.Name,this.Timestamps(this.CurrentIndex));
                I.Timestamp = seconds(this.Timestamps(this.CurrentIndex));
                this.LastTimestampRead = this.Timestamps(this.CurrentIndex);
                this.CurrentTime = this.CurrentIndex/this.FrameRate;
                
            end
            
            if isempty(I)
                error('Could not read frame');
            end
            
        end
        
    end
end
