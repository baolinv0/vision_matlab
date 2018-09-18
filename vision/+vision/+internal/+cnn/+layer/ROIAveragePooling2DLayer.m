classdef ROIAveragePooling2DLayer < vision.internal.cnn.layer.ROIMaxPooling2DLayer
    
    %   Copyright 2016 The MathWorks, Inc.
    
    methods
        function this = ROIAveragePooling2DLayer(name, varargin)
            this = this@vision.internal.cnn.layer.ROIMaxPooling2DLayer(name, varargin{:});
                                   
            this.ExecutionStrategy = vision.internal.cnn.layer.util.ROIAveragePooling2DHostStrategy();
        end
                                       
        function this = setupForHostPrediction(this)
            this.ExecutionStrategy = vision.internal.cnn.layer.util.ROIAveragePooling2DHostStrategy();
        end
        
        function this = setupForGPUPrediction(this)
            this.ExecutionStrategy = vision.internal.cnn.layer.util.ROIAveragePooling2DGPUStrategy();
        end
        
        function this = setupForHostTraining(this)
            this.ExecutionStrategy = vision.internal.cnn.layer.util.ROIAveragePooling2DHostStrategy();
        end
        
        function this = setupForGPUTraining(this)
            this.ExecutionStrategy = vision.internal.cnn.layer.util.ROIAveragePooling2DGPUStrategy();
        end
        
    end

end

