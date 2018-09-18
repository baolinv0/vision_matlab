classdef VideoFileReader< matlab.system.SFunSystem & matlab.system.mixin.FiniteSource
%VideoFileReader Read video frames and audio samples from video file
%   videoFReader = vision.VideoFileReader(FILENAME) returns a video file
%   reader System object, videoFReader, for sequentially reading video
%   frames and/or audio samples from a video file, FILENAME. Every call to
%   the step() method, described below, returns the next video frame.
%
%   videoFReader = vision.VideoFileReader(FILENAME, 'Name', 'Value')
%   configures the video file reader properties, specified as one or more
%   name-value pair arguments. Unspecified properties have default values.
%
%   Step method syntax:
%
%   I = step(videoFReader) outputs next video frame.
%
%   [Y, Cb, Cr] = step(videoFReader) outputs next frame of YCbCr 4:2:2
%   video in the color components Y, Cb, and Cr. This syntax requires that
%   the ImageColorSpace property is set to 'YCbCr 4:2:2'.
%
%   [I, AUDIO] = step(videoFReader) outputs next video frame, I, and one
%   frame of audio samples, AUDIO. This syntax requires the AudioOutputPort
%   property to be true.
%
%   [Y, Cb, Cr, AUDIO] = step(videoFReader) outputs next frame of YCbCr
%   4:2:2 video in the color components Y, Cb, and Cr, and one frame of
%   audio samples in AUDIO. This syntax requires that the AudioOutputPort
%   property is true, and ImageColorSpace property is 'YCbCr 4:2:2'.
%
%   [..., EOF] = step(videoFReader) returns the end-of-file indicator, EOF.
%   EOF is true each time the output contains the last audio sample and/or
%   video frame.
%
%   System objects may be called directly like a function instead of using
%   the step method. For example, y = step(obj) and y = obj() are
%   equivalent.
%
%   VideoFileReader methods:
%
%   step     - See above description for use of this method
%   release  - Allow property value and input characteristics changes, and
%              release video file reader resources
%   clone    - Create video file reader object with same property
%              values
%   isLocked - Locked status (logical)
%   reset    - Reset to the beginning of the video file
%   isDone   - Returns true if object has reached end-of-file
%   info     - Returns information about the specified video file
%
%   VideoFileReader properties:
%
%   Filename             - Name of video file from which to read
%   PlayCount            - Number of times to play the file
%   AudioOutputPort      - Choose to output audio data
%   ImageColorSpace      - Choose whether output is RGB, intensity, or YCbCr
%   VideoOutputDataType  - Data type of video data output
%   AudioOutputDataType  - Data type of audio samples output
%
%   Example
%   -------
%   % Read a video file and play it. 
%   videoFReader = vision.VideoFileReader('viplanedeparture.mp4');
%   videoPlayer = vision.VideoPlayer;
%   while ~isDone(videoFReader)
%     videoFrame = step(videoFReader);
%     step(videoPlayer, videoFrame);
%   end
%   release(videoPlayer);
%   release(videoFReader);
%
%   See also vision.VideoFileWriter, vision.VideoPlayer, implay

 
%   Copyright 2004-2016 The MathWorks, Inc.

    methods
        function out=VideoFileReader
            %VideoFileReader Read video frames and audio samples from video file
            %   videoFReader = vision.VideoFileReader(FILENAME) returns a video file
            %   reader System object, videoFReader, for sequentially reading video
            %   frames and/or audio samples from a video file, FILENAME. Every call to
            %   the step() method, described below, returns the next video frame.
            %
            %   videoFReader = vision.VideoFileReader(FILENAME, 'Name', 'Value')
            %   configures the video file reader properties, specified as one or more
            %   name-value pair arguments. Unspecified properties have default values.
            %
            %   Step method syntax:
            %
            %   I = step(videoFReader) outputs next video frame.
            %
            %   [Y, Cb, Cr] = step(videoFReader) outputs next frame of YCbCr 4:2:2
            %   video in the color components Y, Cb, and Cr. This syntax requires that
            %   the ImageColorSpace property is set to 'YCbCr 4:2:2'.
            %
            %   [I, AUDIO] = step(videoFReader) outputs next video frame, I, and one
            %   frame of audio samples, AUDIO. This syntax requires the AudioOutputPort
            %   property to be true.
            %
            %   [Y, Cb, Cr, AUDIO] = step(videoFReader) outputs next frame of YCbCr
            %   4:2:2 video in the color components Y, Cb, and Cr, and one frame of
            %   audio samples in AUDIO. This syntax requires that the AudioOutputPort
            %   property is true, and ImageColorSpace property is 'YCbCr 4:2:2'.
            %
            %   [..., EOF] = step(videoFReader) returns the end-of-file indicator, EOF.
            %   EOF is true each time the output contains the last audio sample and/or
            %   video frame.
            %
            %   System objects may be called directly like a function instead of using
            %   the step method. For example, y = step(obj) and y = obj() are
            %   equivalent.
            %
            %   VideoFileReader methods:
            %
            %   step     - See above description for use of this method
            %   release  - Allow property value and input characteristics changes, and
            %              release video file reader resources
            %   clone    - Create video file reader object with same property
            %              values
            %   isLocked - Locked status (logical)
            %   reset    - Reset to the beginning of the video file
            %   isDone   - Returns true if object has reached end-of-file
            %   info     - Returns information about the specified video file
            %
            %   VideoFileReader properties:
            %
            %   Filename             - Name of video file from which to read
            %   PlayCount            - Number of times to play the file
            %   AudioOutputPort      - Choose to output audio data
            %   ImageColorSpace      - Choose whether output is RGB, intensity, or YCbCr
            %   VideoOutputDataType  - Data type of video data output
            %   AudioOutputDataType  - Data type of audio samples output
            %
            %   Example
            %   -------
            %   % Read a video file and play it. 
            %   videoFReader = vision.VideoFileReader('viplanedeparture.mp4');
            %   videoPlayer = vision.VideoPlayer;
            %   while ~isDone(videoFReader)
            %     videoFrame = step(videoFReader);
            %     step(videoPlayer, videoFrame);
            %   end
            %   release(videoPlayer);
            %   release(videoFReader);
            %
            %   See also vision.VideoFileWriter, vision.VideoPlayer, implay
        end

        function canOutputAudio(in) %#ok<MANU>
        end

        function canOutputVideo(in) %#ok<MANU>
        end

        function getOutputStreams(in) %#ok<MANU>
        end

        function infoImpl(in) %#ok<MANU>
            %info Returns information about the specified video file
            %   S = info(OBJ) returns a MATLAB structure, S, with information
            %   about the video file specified in the Filename property. The
            %   number of fields of S varies depending on the audio/video content
            %   of the file. The possible fields and values for the structure S 
            %   are described below:
            %   Audio            - Logical value indicating if the file has audio
            %                      content.
            %   Video            - Logical value indicating if the file has video
            %                      content.
            %   AudioSampleRate  - Audio sampling rate of the video file in
            %                      Hz. This field is available when the file has 
            %                      audio content.
            %   AudioNumBits     - Number of bits used to encode the audio
            %                      stream. This field is available when the file 
            %                      has audio content.
            %   AudioNumChannels - Number of audio channels. This field is
            %                      available when the file has audio content.
            %   FrameRate        - Frame rate of the video stream in frames per
            %                      second. The value may vary from the actual
            %                      frame rate of the recorded video, and takes
            %                      into consideration any synchronization issues
            %                      between audio and video streams when the file
            %                      contains both audio and video content. This
            %                      implies that video frames may be dropped if the
            %                      audio stream leads the video stream by more
            %                      than 1/(actual video frames per second). This
            %                      field is available when the file has video
            %                      content.
            %   VideoSize        - Video size as a two-element numeric vector of 
            %                      the form: 
            %                      [VideoWidthInPixels, VideoHeightInPixels].
            %                      This field is available when the file has
            %                      video content.
            %   VideoFormat      - Video signal format. This field is available
            %                      when the file has video content.
        end

        function isDoneImpl(in) %#ok<MANU>
            %isDone Returns true if System object has reached end-of-file
            %   STATUS = isDone(OBJ) returns a logical value, STATUS, indicating
            %   if the VideoFileReader System object, OBJ, has reached the end of
            %   the video file. If PlayCount property is set to a value
            %   greater than 1, STATUS will be true every time the end is
            %   reached. STATUS is the same as the EOF output value in the
            %   step method syntax.
        end

        function isInactivePropertyImpl(in) %#ok<MANU>
        end

        function loadObjectImpl(in) %#ok<MANU>
        end

        function setFileInfoProps(in) %#ok<MANU>
        end

        function shouldOutputAudio(in) %#ok<MANU>
        end

    end
    methods (Abstract)
    end
    properties
        %AudioOutputDataType Data type of audio samples output
        %   Set the data type of the audio data output from the System object.
        %   This property is only available if the video file contains
        %   audio. This property can be set to one of ['double' | 'single' |
        %   {'int16'} | 'uint8'].
        AudioOutputDataType;

        %AudioOutputPort Choose to output audio data
        %   Use this property to control the audio output from the System
        %   object. This property is only applicable when the file contains
        %   supported audio and video streams. The default value of this
        %   property is false.
        AudioOutputPort;

        %Filename Name of video file from which to read
        %   Specify the name of the video file as a string. The full path
        %   for the file needs to be specified only if the file is not on the
        %   MATLAB path. The default value of this property is
        %   'vipmen.avi'.
        Filename;

        %ImageColorSpace Choose whether output is RGB, YCbCr, or intensity video
        %   Specify whether you want the System object to output RGB, YCbCr
        %   4:2:2 or intensity video frames. This property is available only
        %   when the video file contains video. This property can be set
        %   to one of [{'RGB'} | 'Intensity' | 'YCbCr 4:2:2' ].
        ImageColorSpace;

        %PlayCount Number of times to play the file
        %   Specify a positive integer or inf to represent the number of times
        %   to play the file. The default value of this property is 1.
        PlayCount;

        %VideoOutputDataType Data type of video data output
        %   Set the data type of the video data output from the System object.
        %   This property is only available if the video file contains
        %   video. This property can be set to one of ['double' | {'single'} |
        %   'int8' | 'uint8' | 'int16' | 'uint16' | 'int32' | 'uint32' |
        %   'Inherit'].
        VideoOutputDataType;

        pHasAudio;

    end
end
