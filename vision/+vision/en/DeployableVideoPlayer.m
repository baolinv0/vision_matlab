classdef DeployableVideoPlayer< matlab.system.SFunSystem
%DeployableVideoPlayer Display video
%   depVideoPlayer = vision.DeployableVideoPlayer returns a video player
%   System object, depVideoPlayer, for displaying video frames. Each call
%   to the step() method, described below, displays the next video frame.
%   Unlike vision.VideoPlayer, it can generate C code.
%
%   depVideoPlayer = vision.DeployableVideoPlayer(...,'Name', 'Value')
%   configures the video player properties, specified as one or more
%   name-value pair arguments. Unspecified properties have default values.
%
%   Step method syntax:
%
%   step(depVideoPlayer, I) displays one grayscale or truecolor RGB video
%   frame, I, in the video player.
%
%   step(depVideoPlayer, Y, Cb, Cr) displays one frame of YCbCr 4:2:2 video
%   in the color components Y, Cb, and Cr when the InputColorFormat
%   property is set to 'YCbCr 4:2:2'. The number of columns in the Cb and
%   Cr components must be half the number of columns in the Y component.
%
%   System objects may be called directly like a function instead of using
%   the step method. For example, step(obj, x) and obj(x) are equivalent.
%
%   DeployableVideoPlayer methods:
%
%   step     - See above description for use of this method
%   release  - Allow property value and input characteristics changes, and
%              release deployable video player resources
%   clone    - Create deployable video player object with same property values
%   isLocked - Locked status (logical)
%   isOpen   - Visible or hidden status for video player window (logical)
%              This method is not supported in code generation.
%
%   DeployableVideoPlayer properties:
%
%   Location         - Location of bottom left corner of video window
%   Name             - Video window caption
%   Size             - Size of video display window
%   CustomSize       - Custom size for video player window
%   InputColorFormat - Color format of the input signal
%
%   Example
%   -------
%   % Read video from file and display it on the screen.
%   videoFReader   = vision.VideoFileReader('atrium.mp4');
%   depVideoPlayer = vision.DeployableVideoPlayer;
%
%   cont = ~isDone(videoFReader);
%   while cont
%     frame = step(videoFReader);
%     step(depVideoPlayer, frame);
%     % Continue the loop until the last frame is read.
%     % Exit the loop if the video player window is closed by user.   
%     cont = ~isDone(videoFReader) && isOpen(depVideoPlayer);
%   end
%   release(videoFReader);
%   release(depVideoPlayer);
%
%   See also vision.VideoPlayer, vision.VideoFileReader, 
%            vision.VideoFileWriter.

 
%   Copyright 2008-2016 The MathWorks, Inc.

    methods
        function out=DeployableVideoPlayer
            %DeployableVideoPlayer Display video
            %   depVideoPlayer = vision.DeployableVideoPlayer returns a video player
            %   System object, depVideoPlayer, for displaying video frames. Each call
            %   to the step() method, described below, displays the next video frame.
            %   Unlike vision.VideoPlayer, it can generate C code.
            %
            %   depVideoPlayer = vision.DeployableVideoPlayer(...,'Name', 'Value')
            %   configures the video player properties, specified as one or more
            %   name-value pair arguments. Unspecified properties have default values.
            %
            %   Step method syntax:
            %
            %   step(depVideoPlayer, I) displays one grayscale or truecolor RGB video
            %   frame, I, in the video player.
            %
            %   step(depVideoPlayer, Y, Cb, Cr) displays one frame of YCbCr 4:2:2 video
            %   in the color components Y, Cb, and Cr when the InputColorFormat
            %   property is set to 'YCbCr 4:2:2'. The number of columns in the Cb and
            %   Cr components must be half the number of columns in the Y component.
            %
            %   System objects may be called directly like a function instead of using
            %   the step method. For example, step(obj, x) and obj(x) are equivalent.
            %
            %   DeployableVideoPlayer methods:
            %
            %   step     - See above description for use of this method
            %   release  - Allow property value and input characteristics changes, and
            %              release deployable video player resources
            %   clone    - Create deployable video player object with same property values
            %   isLocked - Locked status (logical)
            %   isOpen   - Visible or hidden status for video player window (logical)
            %              This method is not supported in code generation.
            %
            %   DeployableVideoPlayer properties:
            %
            %   Location         - Location of bottom left corner of video window
            %   Name             - Video window caption
            %   Size             - Size of video display window
            %   CustomSize       - Custom size for video player window
            %   InputColorFormat - Color format of the input signal
            %
            %   Example
            %   -------
            %   % Read video from file and display it on the screen.
            %   videoFReader   = vision.VideoFileReader('atrium.mp4');
            %   depVideoPlayer = vision.DeployableVideoPlayer;
            %
            %   cont = ~isDone(videoFReader);
            %   while cont
            %     frame = step(videoFReader);
            %     step(depVideoPlayer, frame);
            %     % Continue the loop until the last frame is read.
            %     % Exit the loop if the video player window is closed by user.   
            %     cont = ~isDone(videoFReader) && isOpen(depVideoPlayer);
            %   end
            %   release(videoFReader);
            %   release(depVideoPlayer);
            %
            %   See also vision.VideoPlayer, vision.VideoFileReader, 
            %            vision.VideoFileWriter.
        end

        function cloneImpl(in) %#ok<MANU>
        end

        function delete(in) %#ok<MANU>
        end

        function isInactivePropertyImpl(in) %#ok<MANU>
        end

        function isOpen(in) %#ok<MANU>
        end

        function saveObjectImpl(in) %#ok<MANU>
        end

    end
    methods (Abstract)
    end
    properties
        %CustomSize Custom size for video player window
        %   Specify the custom size of the video player window as a two-element
        %   vector. The first and second elements are specified in pixels and
        %   represent the horizontal and vertical components respectively. The
        %   video data will be resized to fit the window. This property applies
        %   when you set the Size property to 'Custom'. The default value for
        %   this property is [300 410].
        CustomSize;

        %InputColorFormat Color format of the input signal
        %   Specify the color format of input data as one of [{'RGB'} | 'YCbCr
        %   4:2:2']. The number of columns in the Cb and Cr components must be
        %   half the number of columns in Y. The default value of this property
        %   is 'RGB'.
        InputColorFormat;

        %Location Location of bottom left corner of video player
        %   Specify the location for the bottom left corner of the video player
        %   window as a two-element vector. The first and second elements are
        %   specified in pixels and represent the horizontal and vertical
        %   coordinates respectively. The coordinates [0 0] represent the
        %   bottom left corner of the screen. The default value of this
        %   property is dependent on the screen resolution, and will result in
        %   a window positioned in the center of the screen.
        Location;

        %Name Video window caption
        %   Specify the caption to display on the video player window as any
        %   string. The default value of this property is 'Deployable Video
        %   Player'.
        Name;

        %Size Size of video player window
        %   Specify the video player window size as one of ['Full-screen'|
        %   {'True size (1:1)'} | 'Custom']. When this property is set to
        %   'Full-screen', use the Esc key to exit out of full-screen mode.
        Size;

    end
end
