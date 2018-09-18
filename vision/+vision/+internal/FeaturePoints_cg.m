%FeaturePoints_cg Object used during codegen instead of FeaturePoints
%
%   FeaturePoints_cg replaces FeaturePoints during codegen.

% Copyright 2012 The MathWorks, Inc.

%#codegen
classdef FeaturePoints_cg < vision.internal.FeaturePointsImpl
    
    methods (Access='public')
        
        function this = FeaturePoints_cg(varargin)            
            this = this@vision.internal.FeaturePointsImpl(varargin{:});
        end                   
        
    end
    methods (Hidden)
        %-------------------------------------------------------------------
        % Returns feature points at specified indices
        %-------------------------------------------------------------------
        function obj = getIndexedObj(this, idx)
            
            validateattributes(idx, {'numeric'}, {'vector', 'integer'}, ...
                'FeaturePoints'); %#ok<EMCA>
            
            location = this.pLocation(idx,:);
            metric   = this.pMetric(idx,:);
            
            obj = vision.internal.FeaturePoints_cg(location,'Metric', metric);
            
        end
    end
end


