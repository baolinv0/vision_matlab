%SURFPoints_cg Object used during codegen instead of SURFPoints
%
%   SURFPoints_cg replaces SURFPoints during codegen.

% Copyright 2010-2011 The MathWorks, Inc.

%#codegen
classdef SURFPoints_cg < vision.internal.SURFPointsImpl

   methods (Access='public')
       function this = SURFPoints_cg(varargin)
           this = this@vision.internal.SURFPointsImpl(varargin{:});
       end  
                         
   end
              
   methods (Access='public', Hidden=true)

       %-------------------------------------------------------------------
       % Returns feature points at specified indices. Indexing operations
       % that exceed the dimensions of the object will error out.
       %-------------------------------------------------------------------             
       function obj = getIndexedObj(this, idx)
           
           if islogical(idx)
               validateattributes(idx, {'logical'}, {'vector'}, 'SURFPoints'); %#ok<*EMCA>
           else
               validateattributes(idx, {'numeric'}, {'vector', 'integer'}, 'SURFPoints'); %#ok<*EMCA>
           end
                      
           location        = this.pLocation(idx,:);
           metric          = this.pMetric(idx,:);
           scale           = this.pScale(idx,:);
           signOfLaplacian = this.pSignOfLaplacian(idx,:);
           orientation     = this.pOrientation(idx,:);
           
           obj = vision.internal.SURFPoints_cg(location,'Metric',metric,...
               'Scale',scale, 'SignOfLaplacian', signOfLaplacian,...
               'Orientation', orientation);
           
       end
       
        %------------------------------------------------------------------
        % Set Orientation values. 
        %------------------------------------------------------------------
        function this = setOrientation(this, orientation)            
            this.pOrientation = orientation;
        end
   end    
end

% LocalWords:  Laplacian
% LocalWords:  OpenCV


