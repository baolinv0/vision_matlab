% ImageSequenceReader Reads an imageDatastore and timeStamps as a duration 
% vector. The interface must be identical (not exhaustive) to VideoReader. 
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
%     FrameRate         - Frame rate of the image sequence in frames per second.
%     Path              - Path of the folder containing the image sequence
%     Duration          - Length of the sequence in seconds.
%     Reader            - ImageDataStore containing the folder of images in a sequence.
%     LastTimestampRead - Timestamp of the last frame read.
%     Timestamps        - The timestamp vector of the image sequence.

% Copyright 2016 The MathWorks, Inc.

classdef ImageSequenceReader < handle
    
    properties (GetAccess = 'public', SetAccess = 'private')
        %Name Name of the Image Sequence
        Name
        
        %Path Path of the Image Sequence
        Path
        
        %Duration Duration of the Image Sequence
        Duration              duration
        
        %FrameRate FrameRate of the Image Sequence (set to 1) 
           % The frame rate for image sequences is not clearly defined.
           % Assume it is 1.
        FrameRate
        
        %Reader ImageDataStore containing the folder of images in a
        %sequence
        Reader               
        
        %Timestamps duration vector of timestamps
        Timestamps             duration
        
        %LastTimestamp
        LastTimestampRead      duration
        
    end
    
    properties (Hidden = true, GetAccess = public, SetAccess = private)
        %NumberOfFrames Number of frames
        NumberOfFrames
        
        %CurrentTime Current time (duration scalar) of the Image sequence
        CurrentTime            
        
        %CurrentIndex Current index of the Image sequence
        CurrentIndex
        
    end
    
    properties (Hidden = true, Dependent)
        %Files List of images in the image sequence
        Files
        
    end
    
    %----------------------------------------------------------------------
    % Public API
    %----------------------------------------------------------------------
    methods(Access='public')
        function this = ImageSequenceReader(imgDataStore, timestamps)
            
            % timestamps must be a column vector
            if isrow(timestamps)
                timestamps = timestamps';
            end
            
            if ~isduration(timestamps)
                timestamps = seconds(timestamps);
            end
            
            this.Reader = imgDataStore;
            pathStr = fileparts(imgDataStore.Files{1});
            fileSepIdx = regexp(pathStr, filesep);
            lastFileSepIdx = fileSepIdx(end);
            
            this.Name = pathStr(lastFileSepIdx+1:end);
            this.Path = pathStr(1:lastFileSepIdx);
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
                I.Data = readimage(this.Reader, this.CurrentIndex);
                I.Timestamp = seconds(this.Timestamps(idx));
                this.LastTimestampRead = this.Timestamps(this.CurrentIndex);
                this.CurrentTime = this.CurrentIndex/this.FrameRate;
            end
            
        end
        
        function I = readNextFrame(this)
            
            I = [];
            
            if this.CurrentIndex ~= this.NumberOfFrames
                this.CurrentIndex = this.CurrentIndex+1;
                I.Data = readimage(this.Reader, this.CurrentIndex);
                I.Timestamp = seconds(this.Timestamps(this.CurrentIndex));
                this.LastTimestampRead = this.Timestamps(this.CurrentIndex);
                this.CurrentTime = this.CurrentIndex/this.FrameRate;
                
            end
            
            if isempty(I)
                error('Could not read frame');
            end
            
        end
    
    end
    
    methods
        function files = get.Files(this)
            files = this.Reader.Files;
        end
    end    
end
