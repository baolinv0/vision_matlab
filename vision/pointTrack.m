%pointTrack Object for storing matching points from multiple views
%  You can use this object to store matching 2-D points from multiple
%  views. You can create a pointTrack object using the findTracks method
%  of viewSet class.
%
%  track = pointTrack(viewIds, points) returns a pointTrack object.
%  viewIds is an M-element vector containing the ids of the views 
%  containing the points. points is an M-by-2 matrix containing the [x,y] 
%  coordinates of the image points. 
%
%  pointTrack properties:
%  
%  ViewIds - an M-element vector of view ids
%  Points  - an M-by-2 matrix of x-y point coordinates
%
%  Example - Create a pointTrack Object
%  --------------------------------------
%  points = [10, 20; 11, 21; 12, 22];
%  viewIds = [1 2 3];
%  track = pointTrack(viewIds, points);
%
%  See also viewSet, bundleAdjustment, triangulateMultiview, matchFeatures, 
%    vision.PointTracker

% Copyright 2015 Mathworks, Inc.

classdef pointTrack
    properties 
        % ViewIds An M-element vector of view ids
        ViewIds;
        
        % Points An M-by-2 matrix of [x,y] point coordinates
        Points;
    end    
    
    methods
        %------------------------------------------------------------------
        function this = pointTrack(viewIds, points)
            if nargin == 0
                this.ViewIds = zeros(1, 0, 'uint32');
                this.Points = zeros(0, 2);
            else
                this.ViewIds = uint32(viewIds(:)');
                this.Points = points;
            end
        end
        
        %------------------------------------------------------------------
        function this = set.Points(this, points)
            this.Points = ...
                vision.internal.inputValidation.checkAndConvertPoints(...
                points, mfilename, 'points');
        end
        
        %------------------------------------------------------------------
        function this = set.ViewIds(this, viewIds)
            validateattributes(viewIds, {'numeric'}, ...
                {'vector', 'integer', 'nonnegative', 'nonsparse'}, ...
                mfilename);
            viewIds = viewIds(:)';
            this.ViewIds = uint32(viewIds);
        end
    end
    
    methods(Hidden)
        %------------------------------------------------------------------
        function s = toStruct(this)
            s = struct('ViewIds', {this(:).ViewIds}, ...
                'Points', {this(:).Points});
        end
        
        %------------------------------------------------------------------
        function s = saveobj(this)
            s = toStruct(this);
        end
    end
    
    methods(Static, Hidden)
        %------------------------------------------------------------------
        function this = loadobj(that)
            this = pointTrack(that.ViewIds, that.Points);
        end
    end
end
