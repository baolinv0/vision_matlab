classdef RPNClassificationLayer < nnet.cnn.layer.Layer & nnet.internal.cnn.layer.Externalizable
    
    properties(Dependent)
        % Name   A name for the layer
        %   The name for the layer. If this is set to '', then a name will
        %   be automatically set at training time.
        Name
    end
    
    properties(SetAccess = private, Dependent)
        % ClassNames   The names of the classes
        %   A cell array containing the names of the classes. This will be
        %   automatically determined at training time. Prior to training,
        %   it will be empty.
        ClassNames
        
        % OutputSize   The size of the output
        %   The size of the output. This will be determined at training
        %   time. Prior to training, it is set to 'auto'.
        OutputSize
        
        % LossFunction   The loss function for training
        %   The loss function that will be used during training. Possible
        %   values are:
        %       'crossentropyex'    - Cross-entropy for exclusive outputs.
        LossFunction
    end
    
    methods
        function this = RPNClassificationLayer(privateLayer)
            this.PrivateLayer = privateLayer;
        end
        
        function val = get.Name(this)
            val = this.PrivateLayer.Name;
        end
        
        function this = set.Name(this, val)
            iAssertValidLayerName(val);
            this.PrivateLayer.Name = char(val);
        end
        
        function val = get.ClassNames(this)
            val = this.PrivateLayer.ClassNames;
        end
        
        function val = get.OutputSize(this)
            if(isempty(this.PrivateLayer.NumClasses))
                val = 'auto';
            else
                val = this.PrivateLayer.NumClasses;
            end
        end
        
        function val = get.LossFunction(~)
            val = 'crossentropyex';
        end
        
    end
    
    methods(Access = protected)
        function [description, type] = getOneLineDisplay(~)
            
            description = 'RPN classification layer';
            
            type = 'RPN classification layer';
        end
    end
end

function iAssertValidLayerName(name)
    nnet.internal.cnn.layer.paramvalidation.validateLayerName(name);
end