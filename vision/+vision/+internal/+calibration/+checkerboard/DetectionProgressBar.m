classdef DetectionProgressBar < handle
% DetectionProgressBar A progress bar for detecting checkerboard points in a set of images.
%
% waitBar = DetectionProgress(numImages) returns an object that
% encapsulates a wait bar for detecting checkerboard points in a set of
% images.
%
% DetectionProgressBar methods:
%   update - advance the progress bar by one image.
%   delete - close the progress bar window
%

% Copyright 2013 The MathWorks, Inc.

    properties(Access=private)
        hWaitBar = [];
        NumImages = 0;
        ImageIdx = 1;
    end
    
    properties(Dependent, GetAccess=public)
        Canceled;   
    end
    
    methods
        function this = DetectionProgressBar(numImages)
            this.NumImages = numImages;
            if this.NumImages > 1
                this.ImageIdx = 1;
                waitBarMsg = getWaitBarMessage(1, numImages);
                this.hWaitBar = waitbar(0, waitBarMsg, ...
                    'Tag', 'CheckerboardDetectionProgressBar',...
                    'WindowStyle', 'modal',...
                    'Name', getString(message('vision:calibrate:AnalyzingImagesTitle')));
            end
        end
        
        %------------------------------------------------------------------
        function canceled = get.Canceled(this)
            canceled = this.NumImages > 1 && (isempty(this.hWaitBar) || ~ishandle(this.hWaitBar));
        end
        
        %------------------------------------------------------------------
        function update(this)            
            % update(this) advance the progress bar by one image
            if this.NumImages > 1 && ~this.Canceled
                waitBarMsg = getWaitBarMessage(this.ImageIdx, this.NumImages);
                waitbar(this.ImageIdx/this.NumImages, this.hWaitBar, waitBarMsg);
                this.ImageIdx = this.ImageIdx + 1;
            end
        end
        
        %------------------------------------------------------------------
        function delete(this)
            % close the progress bar window
            if ishandle(this.hWaitBar)
                delete(this.hWaitBar);
            end
        end        
    end
end

%--------------------------------------------------------------------------
function waitBarMsg = getWaitBarMessage(i, numImages)
waitBarMsg = getString(message('vision:calibrate:detectCheckerboardWaitbar', ...
    i, numImages));
end