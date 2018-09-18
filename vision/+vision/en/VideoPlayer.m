classdef VideoPlayer< matlabshared.scopes.UnifiedSystemScope
%VideoPlayer Play video or display image
%   videoPlayer = vision.VideoPlayer returns a video player System object,
%   videoPlayer, for displaying video frames. Each call to the step()
%   method, described below, displays the next video frame.
%
%   videoPlayer = vision.VideoPlayer('Name', 'Value') configures 
%   the video player properties, specified as one or more name-value 
%   pair arguments. Unspecified properties have default values.
%
%   Step method syntax:
%
%   step(videoPlayer, I) displays one grayscale or truecolor RGB video
%   frame, I, in the video player.
%
%   System objects may be called directly like a function instead of using
%   the step method. For example, step(obj, x) and obj(x) are equivalent.
%
%   VideoPlayer methods:
%
%   step      - See above description for use of this method
%   release   - Allow property value and input characteristics changes, and
%               release video player resources
%   clone     - Create video player object with same property values
%   isLocked  - Locked status (logical)
%   reset     - Clear video player figure
%   show      - Turn on visibility of video player figure
%   hide      - Turn off visibility of video player figure
%   isOpen    - Visible or hidden status for video player figure (logical)
%   isVisible - Return visibility of video player figure (logical)
%
%   VideoPlayer properties:
%
%   Name     - Caption to display on video player window
%   Position - Scope window position in pixels
%
%   Example
%   -------
%   % Read video from a file and play it on the screen.
%   videoFReader = vision.VideoFileReader('viplanedeparture.mp4');
%   videoPlayer = vision.VideoPlayer;
%
%   cont = ~isDone(videoFReader);
%   while cont
%     frame = step(videoFReader);
%     step(videoPlayer, frame);
%     % Continue the loop until the last frame is read.
%     % Exit the loop if the video player figure is closed by user.     
%     cont = ~isDone(videoFReader) && isOpen(videoPlayer);
%   end
%   release(videoFReader);
%   release(videoPlayer);
%
%   See also vision.DeployableVideoPlayer, vision.VideoFileReader,
%            vision.VideoFileWriter, imshow, implay.

 
%   Copyright 2009-2016 The MathWorks, Inc.

    methods
        function out=VideoPlayer
            %VideoPlayer Play video or display image
            %   videoPlayer = vision.VideoPlayer returns a video player System object,
            %   videoPlayer, for displaying video frames. Each call to the step()
            %   method, described below, displays the next video frame.
            %
            %   videoPlayer = vision.VideoPlayer('Name', 'Value') configures 
            %   the video player properties, specified as one or more name-value 
            %   pair arguments. Unspecified properties have default values.
            %
            %   Step method syntax:
            %
            %   step(videoPlayer, I) displays one grayscale or truecolor RGB video
            %   frame, I, in the video player.
            %
            %   System objects may be called directly like a function instead of using
            %   the step method. For example, step(obj, x) and obj(x) are equivalent.
            %
            %   VideoPlayer methods:
            %
            %   step      - See above description for use of this method
            %   release   - Allow property value and input characteristics changes, and
            %               release video player resources
            %   clone     - Create video player object with same property values
            %   isLocked  - Locked status (logical)
            %   reset     - Clear video player figure
            %   show      - Turn on visibility of video player figure
            %   hide      - Turn off visibility of video player figure
            %   isOpen    - Visible or hidden status for video player figure (logical)
            %   isVisible - Return visibility of video player figure (logical)
            %
            %   VideoPlayer properties:
            %
            %   Name     - Caption to display on video player window
            %   Position - Scope window position in pixels
            %
            %   Example
            %   -------
            %   % Read video from a file and play it on the screen.
            %   videoFReader = vision.VideoFileReader('viplanedeparture.mp4');
            %   videoPlayer = vision.VideoPlayer;
            %
            %   cont = ~isDone(videoFReader);
            %   while cont
            %     frame = step(videoFReader);
            %     step(videoPlayer, frame);
            %     % Continue the loop until the last frame is read.
            %     % Exit the loop if the video player figure is closed by user.     
            %     cont = ~isDone(videoFReader) && isOpen(videoPlayer);
            %   end
            %   release(videoFReader);
            %   release(videoPlayer);
            %
            %   See also vision.DeployableVideoPlayer, vision.VideoFileReader,
            %            vision.VideoFileWriter, imshow, implay.
        end

        function getScopeCfg(in) %#ok<MANU>
        end

        function isOpen(in) %#ok<MANU>
        end

    end
    methods (Abstract)
    end
    properties
        %Name Caption to display on video player window
        %   Specify the caption to display on the scope window as a string.
        %   The default value of this property is 'Video Player'. This property
        %   is tunable.
        Name;

    end
end
