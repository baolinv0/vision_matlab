classdef BoundingBoxRegressionOutputLayer < nnet.cnn.layer.Layer & nnet.internal.cnn.layer.Externalizable
% Class specific box regression layer. Uses Smooth L1 loss function.

    properties(Dependent)
        % Name   A name for the layer
        %   The name for the layer. If this is set to '', then a name will
        %   be automatically set at training time.
        Name       
    end
    
    properties(SetAccess = private, Dependent)
        % OutputSize The output size. 
        OutputSize
        
        % LossFunction
        LossFunction            
    end
    
    methods
        function this = BoundingBoxRegressionOutputLayer(privateLayer)          
            this.PrivateLayer = privateLayer;
        end       
        
        function val = get.Name(this)
            val = this.PrivateLayer.Name;
        end
        
        function this = set.Name(this, val)
            iAssertValidLayerName(val);
            this.PrivateLayer.Name = char(val);
        end
        
        function val = get.LossFunction(~)
            val = 'smooth-l1';
        end  
        
        function val = get.OutputSize(this)            
            val = this.PrivateLayer.NumResponses;
            if isempty(val)
                val = 'auto';
            end
        end        
    end
    
    methods(Hidden, Access = protected)
        function [desc, type] = getOneLineDisplay(~)
            desc = 'Bounding Box Regression';
            type = 'BoxRegressionOutputLayer';
        end
        
        function groups = getPropertyGroups( this )
            generalParameters = {
                'Name' 
                'OutputSize'
                };
            
            groups = [
                this.propertyGroupGeneral( generalParameters )
                this.propertyGroupHyperparameters( {'LossFunction'} )
                ];
        end
    end
        
end

function iAssertValidLayerName(name)
nnet.internal.cnn.layer.paramvalidation.validateLayerName(name);
end
