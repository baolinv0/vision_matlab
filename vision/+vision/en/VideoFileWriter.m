classdef VideoFileWriter< matlab.system.SFunSystem
%VideoFileWriter Write video frames and audio samples to video file
%   The VideoFileWriter writes video and/or audio to an AVI or WMV file.
%   WMV files can be written only on Windows (R). The video and audio can be
%   compressed. The available compression types depend on the encoders 
%   installed on the platform.
%
%   videoFWriter = vision.VideoFileWriter returns a video file writer
%   System object, videoFWriter, that writes video frames to an
%   uncompressed 'output.avi' video file. Every call to the step() method,
%   described below, writes the next video frame.
%
%   videoFWriter = vision.VideoFileWriter(FILENAME) returns a video file 
%   writer System object, that writes video to a file, FILENAME. The file
%   type can be AVI or WMV and is determined by the FileFormat property
%   described below.
%
%   videoFWriter = vision.VideoFileWriter(..., 'Name', 'Value') configures 
%   the video file writer properties, specified as one or more name-value 
%   pair arguments. Unspecified properties have default values.
%
%   Step method syntax:
%
%   step(videoFWriter, I) writes one frame of video, I, to the output file.
%   I can be M-by-N-by-3 truecolor RGB video frame, or an M-by-N grayscale
%   video frame.
%
%   step(videoFWriter, Y, Cb, Cr) writes one frame of YCbCr 4:2:2 video.
%   The width of Cb and Cr color components must be half of the width of Y,
%   and the value of the FileColorSpace property must be set to 'YCbCr 4:2:2'.
%
%   step(videoFWriter, I, AUDIO) writes one frame of video, I, and one
%   frame of audio samples, AUDIO, to the output file when the
%   AudioInputPort property is enabled.
%
%   step(videoFWriter, Y, Cb, Cr, AUDIO) writes one frame of YCbCr 4:2:2
%   video, and one frame of audio samples, AUDIO, to the output file when
%   the AudioInputPort is enabled and the value of the FileColorSpace
%   property is set to 'YCbCr 4:2:2'. The width of Cb and Cr color
%   components must be half of the width of Y.
%
%   System objects may be called directly like a function instead of using
%   the step method. For example, step(obj, x) and obj(x) are equivalent.
%
%   VideoFileWriter methods:
%
%   step     - See above description for use of this method
%   release  - Allow property value and input characteristics changes, and
%              release video file writer resources
%   clone    - Create video file writer object with same property values
%   isLocked - Locked status (logical)
%
%   VideoFileWriter properties:
%
%   Filename            - Name of video file to which to write
%   FileFormat          - Format of created file.
%   AudioInputPort      - Set to true to write audio data
%   FrameRate           - Video frame rate
%   AudioCompressor     - Encoder used to compress audio
%   VideoCompressor     - Encoder used to compress video
%   AudioDataType       - Data type of the uncompressed audio
%   FileColorSpace      - Color space used when creating a file
%   Quality             - Control the size of the output video file
%   CompressionFactor   - Target ratio between number of bytes in input
%                         image and compressed image
%
%   Example
%   -------
%   % Write a video to an AVI file. 
%   videoFReader = vision.VideoFileReader('viplanedeparture.mp4');
%   videoFWriter = vision.VideoFileWriter('myFile.avi', ...
%                        'FrameRate', videoFReader.info.VideoFrameRate);
%   % write the first 50 frames of viplanedeparture.avi into myFile.avi
%   for i=1:50
%      videoFrame = step(videoFReader);
%      step(videoFWriter, videoFrame);  % write video to myFile.avi
%   end
%   release(videoFReader); % close the input file
%   release(videoFWriter); % close the output file
%
%   See also vision.VideoFileReader, vision.VideoPlayer, implay

 
%   Copyright 2004-2016 The MathWorks, Inc.

    methods
        function out=VideoFileWriter
            %VideoFileWriter Write video frames and audio samples to video file
            %   The VideoFileWriter writes video and/or audio to an AVI or WMV file.
            %   WMV files can be written only on Windows (R). The video and audio can be
            %   compressed. The available compression types depend on the encoders 
            %   installed on the platform.
            %
            %   videoFWriter = vision.VideoFileWriter returns a video file writer
            %   System object, videoFWriter, that writes video frames to an
            %   uncompressed 'output.avi' video file. Every call to the step() method,
            %   described below, writes the next video frame.
            %
            %   videoFWriter = vision.VideoFileWriter(FILENAME) returns a video file 
            %   writer System object, that writes video to a file, FILENAME. The file
            %   type can be AVI or WMV and is determined by the FileFormat property
            %   described below.
            %
            %   videoFWriter = vision.VideoFileWriter(..., 'Name', 'Value') configures 
            %   the video file writer properties, specified as one or more name-value 
            %   pair arguments. Unspecified properties have default values.
            %
            %   Step method syntax:
            %
            %   step(videoFWriter, I) writes one frame of video, I, to the output file.
            %   I can be M-by-N-by-3 truecolor RGB video frame, or an M-by-N grayscale
            %   video frame.
            %
            %   step(videoFWriter, Y, Cb, Cr) writes one frame of YCbCr 4:2:2 video.
            %   The width of Cb and Cr color components must be half of the width of Y,
            %   and the value of the FileColorSpace property must be set to 'YCbCr 4:2:2'.
            %
            %   step(videoFWriter, I, AUDIO) writes one frame of video, I, and one
            %   frame of audio samples, AUDIO, to the output file when the
            %   AudioInputPort property is enabled.
            %
            %   step(videoFWriter, Y, Cb, Cr, AUDIO) writes one frame of YCbCr 4:2:2
            %   video, and one frame of audio samples, AUDIO, to the output file when
            %   the AudioInputPort is enabled and the value of the FileColorSpace
            %   property is set to 'YCbCr 4:2:2'. The width of Cb and Cr color
            %   components must be half of the width of Y.
            %
            %   System objects may be called directly like a function instead of using
            %   the step method. For example, step(obj, x) and obj(x) are equivalent.
            %
            %   VideoFileWriter methods:
            %
            %   step     - See above description for use of this method
            %   release  - Allow property value and input characteristics changes, and
            %              release video file writer resources
            %   clone    - Create video file writer object with same property values
            %   isLocked - Locked status (logical)
            %
            %   VideoFileWriter properties:
            %
            %   Filename            - Name of video file to which to write
            %   FileFormat          - Format of created file.
            %   AudioInputPort      - Set to true to write audio data
            %   FrameRate           - Video frame rate
            %   AudioCompressor     - Encoder used to compress audio
            %   VideoCompressor     - Encoder used to compress video
            %   AudioDataType       - Data type of the uncompressed audio
            %   FileColorSpace      - Color space used when creating a file
            %   Quality             - Control the size of the output video file
            %   CompressionFactor   - Target ratio between number of bytes in input
            %                         image and compressed image
            %
            %   Example
            %   -------
            %   % Write a video to an AVI file. 
            %   videoFReader = vision.VideoFileReader('viplanedeparture.mp4');
            %   videoFWriter = vision.VideoFileWriter('myFile.avi', ...
            %                        'FrameRate', videoFReader.info.VideoFrameRate);
            %   % write the first 50 frames of viplanedeparture.avi into myFile.avi
            %   for i=1:50
            %      videoFrame = step(videoFReader);
            %      step(videoFWriter, videoFrame);  % write video to myFile.avi
            %   end
            %   release(videoFReader); % close the input file
            %   release(videoFWriter); % close the output file
            %
            %   See also vision.VideoFileReader, vision.VideoPlayer, implay
        end

        function isInactivePropertyImpl(in) %#ok<MANU>
            % The properties that are visible for all file formats are
            % 'Filename', 'FileFormat' and 'FrameRate'
        end

        function validateInputsImpl(in) %#ok<MANU>
            % If writing audio is enabled, the possible syntaxes for STEP are:
            % 3-inputs: step(obj, img, audio) OR 
            % 5-inputs step(obj, comp1, comp2, comp3, audio)
        end

    end
    methods (Abstract)
    end
    properties
        %AudioCompressor Encoder used to compress audio data
        %   Specify the audio compressor. By default, the files are written
        %   uncompressed. The available compressors will depend on the
        %   capabilities of your platform. To get a list of available
        %   compressors, use the TAB completion from the command prompt:
        %     >> videoFWriter = vision.VideoFileWriter; 
        %     >> videoFWriter.AudioCompressor = '<Press TAB to get a list>
        %   This property is only available when writing AVI files on
        %   Windows (R) platforms.
        %
        %   Default: 'None (uncompressed)'
        AudioCompressor;

        %AudioDataType Data type of the uncompressed audio
        %   Specify the type of uncompressed audio data which is written to the
        %   file as one of 'inherit' | 'uint8' | 'int16' | 'int24' | 'single'. 
        %   The default is 'int16'. Note that this property is not currently
        %   used when writing any of the file formatss supported by this system
        %   object
        AudioDataType;

        %AudioInputPort Choose to write audio data
        %   Use this property to control whether the System object writes audio
        %   samples to the video file. This property is false by default.
        AudioInputPort;

        %CompressionFactor Target ratio between number of bytes in input image
        %and compressed image
        %   Specify the compression factor as an integer greater than 1 to
        %   indicate the target ratio between the number of bytes in the input
        %   image and compressed image. The data is compressed as much as
        %   possible, up to the specified target. This property is applicable
        %   only when writing Lossy MJ2000 files.
        CompressionFactor;

        %FileColorSpace Color space used when creating a file
        %   Specify the color space of AVI files as one of [{'RGB'} | 'YCbCr
        %   4:2:2'].
        FileColorSpace;

        %FileFormat Format of created file
        %   Specify the format of the video file.  
        %   On Windows (R) platforms, this may be one of: 
        %       [{'AVI'} | 'WMV' | 'MJ2000' | 'MPEG4'].
        %   On Linux (R) platforms, this may be one of:
        %       [{'AVI'} | 'MJ2000']. 
        %   On Mac OS X (R) platforms, this may be one of:
        %       [{'AVI'} | 'MJ2000' | 'MPEG4']
        %   These abbreviations
        %   correspond to the following file formats: 
        %   WMV: Windows Media Video
        %   AVI: Audio-Video Interleave
        %   MJ2000: Motion JPEG 2000
        %   MPEG4: MPEG-4/H.264 Video
        FileFormat;

        %Filename Name of video file
        %   Specify the name of the video file. Supported file name extensions
        %   are - .avi, .wmv, .mj2, .mp4 or .m4v
        %      Default: 'output.avi'.
        Filename;

        %FrameRate Video frame rate
        %   Specify the frame rate of the video data in frames per second as a
        %   positive numeric scalar. The default value of this property is 30.
        %   For videos which also contain audio data, the rate of the audio 
        %   data will be determined as the rate of the video multiplied by the 
        %   number of audio samples passed in each invocation of the step 
        %   method.  For example, if you use a frame rate of 30 and pass 1470 
        %   audio samples to the step method, the audio sample rate will be 
        %   1470*30 = 44100 
        FrameRate;

        %Quality Controls the size of the output video
        %   Specify the output video quality as an integer between 0 and 100.
        %   Higher quality numbers result in higher video quality and larger
        %   file sizes. Lower quality numbers result in lower video quality and
        %   smaller file sizes.
        %   Applicable only for the following cases:
        %       Writing MPEG-4/H.264 video
        %       Writing Motion JPEG AVI files containing only video streams on
        %       Linux (R) and Mac OS X (R)
        Quality;

        %VideoCompressor Encoder used to compress video data
        %   Specify the video compressor. By default, the files are written
        %   uncompressed. The available compressors will depend on the
        %   capabilities of your platform. To get a list of available
        %   compressors, use the TAB completion from the command prompt:
        %     >> videoFWriter = vision.VideoFileWriter; 
        %     >> videoFWriter.VideoCompressor = '<Press TAB to get a list>
        %   
        %   Default: 'None (uncompressed)'
        VideoCompressor;

    end
end
