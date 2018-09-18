% BRISKPoints_cg replaces BRISKPoints during code generation. 

%#codegen
classdef BRISKPoints_cg < vision.internal.BRISKPointsImpl
    
    methods
        function this = BRISKPoints_cg(varargin)
            this = this@vision.internal.BRISKPointsImpl(varargin{:});
        end        
    end
    
    methods(Hidden)
        %------------------------------------------------------------------
        % Returns feature points at specified indices. Indexing operations
        % that exceed the dimensions of the object will error out.
        %------------------------------------------------------------------
        function obj = getIndexedObj(this, idx)
                        
            if islogical(idx)
                validateattributes(idx, {'logical'}, {'vector'}, 'SURFPoints'); %#ok<*EMCA>
            else               
                validateattributes(idx, {'numeric'}, {'vector', 'integer'}, 'SURFPoints'); %#ok<*EMCA>
            end
    
            % If idx is larger than dimensions of object, there will be a
            % run-time error thrown by MATLAB coder.
            
            location    = this.pLocation(idx,:);
            metric      = this.pMetric(idx);
            scale       = this.pScale(idx);
            orientation = this.pOrientation(idx);
            
            obj = vision.internal.BRISKPoints_cg(location,'Metric', metric, ...
                'Scale', scale', 'Orientation', orientation);
            
            
        end
    end

end % classdef