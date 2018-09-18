% RectificationParameters Object that stores the stereo rectification parameters
%
% RectificationParameters properties:
%   H1                 - projective transformation for image 1
%   H2                 - projective transformation for image 2
%   Q                  - 4x4 matrix that maps [x, y, disparity] to [X, Y, Z]
%   XBounds            - the x bounds of output image
%   YBounds            - the y bounds of the output image
%   RectifiedImageSize - image size after rectification
%   Initialized        - true if the rectification parameters have been computed
%
% RectificationParameters methods:
%   needToUpdate - returns true if the rectification parameters need to be updated
%   update       - updates the rectification parameters
%   toStruct     - convert a RectificationParameters object into a struct

% Copyright 2014 MathWorks, Inc.

% References:
%
% G. Bradski and A. Kaehler, "Learning OpenCV : Computer Vision with
% the OpenCV Library," O'Reilly, Sebastopol, CA, 2008.

%#codegen
classdef RectificationParameters < handle
    
    properties (SetAccess=private, GetAccess=public)                
        % H1 A 3x3 matrix containing projective transformation for image 1
        H1;
        
        % H2 A 3x3 matrix containing projective transformation for image 2
        H2;
        
        % Q 4x4 matrix that maps [x, y, disparity] to [X, Y, Z]
        Q = eye(4);
                        
        % XBounds a 2-element vector containing the x bounds of output image
        XBounds = zeros(1, 2);
        
        % YBounds a 2-element vector contraining the y bounds of the output image
        YBounds = zeros(1, 2);
        
        % Initialized A flag set to true by the first call to update method
        Initialized = false;
    end
    
    properties(Access=private)
        % OriginalImageSize Image size before rectification
        OriginalImageSize = zeros(1, 2);        
        
        % OutputView 'full' or 'valid'                
        OutputView = 'full';
        
    end
    
    properties(Dependent, SetAccess=private, GetAccess=public)
        % RectifiedImageSize Image size after rectification
        RectifiedImageSize;
    end
    
    methods
        function this = RectificationParameters()
            this.OutputView = 'full';
            this.OutputView = 'valid';
            this.H1 = projective2d();
            this.H2 = projective2d();
        end
        
        %------------------------------------------------------------------
        function paramStruct = toStruct(this)
        % toStruct - convert a RectificationParameters object into a struct
        %   paramStruct = toStruct(obj) returns a struct containing the
        %   rectification parameters.         
            paramStruct.Initialized = this.Initialized;
            paramStruct.H1 = this.H1.T;
            paramStruct.H2 = this.H2.T;
            paramStruct.Q = this.Q;
            paramStruct.XBounds = this.XBounds;
            paramStruct.YBounds = this.YBounds;
            paramStruct.OriginalImageSize = this.OriginalImageSize;
            paramStruct.OutputView = this.OutputView;
        end
        
        %------------------------------------------------------------------
        % Returns true if the object needs to be updated.
        %------------------------------------------------------------------
        function tf = needToUpdate(this, imageSize, outputView)      
        % needToUpdate Check if the rectification parameters need to be updated
        %   tf = needToUpdate(obj, imageSize, outputView) returns true if
        %   the rectification parameters need to be updated, and false
        %   otherwise. obj is a RectificationParameters object. imageSize
        %   is a 2-element vector [height, width] representing the size of
        %   the input image. outputView is a string that determines the
        %   size of the output image. Valid values are 'full' and 'valid'.
            tf = ~ (isequal(imageSize, this.OriginalImageSize) && ...
                strcmp(outputView, this.OutputView));
        end
        
        %------------------------------------------------------------------
        % Update the rectification parameters.
        %------------------------------------------------------------------
        function update(this, imageSize, h1, h2, q, outputView, ...
                xBounds, yBounds)
        % UPDATE Update the rectification parameters.
        %   UPDATE(obj, imageSize, h1, h2, q, outputView, xBounds, yBounds)
        %   updates the rectification parameters.
            this.Initialized = true;
            this.OriginalImageSize = imageSize;
            this.H1 = h1;
            this.H2 = h2;
            this.Q = q;
            this.OutputView = outputView;
            this.XBounds = xBounds;
            this.YBounds = yBounds;
        end
        
        %------------------------------------------------------------------
        % Computes the size of the rectified image
        %------------------------------------------------------------------
        function imageSize = get.RectifiedImageSize(this)
            imageSize = [this.YBounds(2) - this.YBounds(1) + 1, ...
                         this.XBounds(2) - this.XBounds(1) + 1];
        end
            
    end
    
    %----------------------------------------------------------------------
    methods (Static, Hidden)
        function this = loadobj(that) 
            % handle pre-R2015a version, which did not have the
            % Initialize property.
            this = vision.internal.calibration.RectificationParameters;
            if (isprop(that, 'Initialized') && that.Initialized) ||...
                    (~isprop(that, 'Initialized') && ~isempty(that.Q))
                this.update(that.OriginalImageSize, that.H1, that.H2,...
                    that.Q, that.OutputView, that.XBounds, that.YBounds);
            end
        end
    end
end