classdef Crop2DLayer < nnet.cnn.layer.Layer & nnet.internal.cnn.layer.Externalizable
    % Crop2DLayer 2D crop layer
    %
    %   A 2D cropping layer. This layer crops an input feature map along
    %   the first and second dimensions. To create a 2D crop layer, use
    %   crop2dLayer.
    %
    %   Crop2DLayer properties:
    %       Name         - A name for the layer.
    %       Location     - Location of the cropping window.
    %
    % Example:
    %    Create a 2D crop layer and connect both of its inputs using a
    %    layerGraph object.
    %
    %    layers = [
    %        imageInputLayer([32 32 3], 'Name', 'image')
    %        crop2dLayer([3 4], 'Name', 'crop')
    %        ]
    %
    %    % Create a layerGraph. The first input of crop2dLayer is automatically
    %    % connected to the first output of the image input layer.
    %    lgraph = layerGraph(layers)
    %
    %    % Connect the second input to the image layer output.
    %    lgraph = connectLayers(lgraph, 'image/out', 'crop/in2')
    %
    %   See also crop2dLayer.
    
    %   Copyright 2017 The MathWorks, Inc.
    
    properties(Dependent)
        % Name   A name for the layer
        %   The name for the layer. If this is set to '', then a name will
        %   be automatically set at training time.
        Name        
    end
    
    properties(SetAccess = private, Dependent)
        % Mode The cropping mode
        %   The cropping mode is either 'centercrop' or 'custom'. In
        %   'centercrop' mode, the cropping window is automatically
        %   positioned in the center of the input feature map. In 'custom'
        %   mode, the 'Location' value is used.
        Mode
        
        % Location The location of the cropping window 
        %   The location is an [X Y] vector that defines the upper-left
        %   corner of the cropping window. X is the location in the
        %   horizontal direction and Y is the location in the vertical
        %   direction. When the 'Mode' is 'centercrop', 'Location' is
        %   'auto'.
        Location
    end
    
    methods(Hidden, Static)
        function this = loadobj(in)
            internalLayer = nnet.internal.cnn.layer.Crop2DLayer(...
                in.Name, in.Location, in.Mode);
            
            this = nnet.cnn.layer.Crop2DLayer(internalLayer);
        end
    end
    
    methods
        function this = Crop2DLayer(internalLayer)
            this.PrivateLayer = internalLayer;
        end
        
        function out = saveobj(this)
            privateLayer = this.PrivateLayer;
            out.Version  = 1.0;
            out.Name     = privateLayer.Name;
            out.Location = privateLayer.Location;
            out.Mode     = privateLayer.Mode;
        end
        
        function val = get.Name(this)
            val = this.PrivateLayer.Name;
        end
        
        function this = set.Name(this, val)
            nnet.internal.cnn.layer.paramvalidation.validateLayerName(val);
            this.PrivateLayer.Name = char(val);
        end
        
        function v = get.Location(this)
            v = this.PrivateLayer.Location;
        end
        
        function v = get.Mode(this)
            v = this.PrivateLayer.Mode;
        end
    end
    
    methods(Hidden, Access = protected)
        function [description, type] = getOneLineDisplay(this)
            
            if strcmp(this.Mode, 'centercrop')
                description = getString(message(...
                    'vision:cnn_layers:crop2dCenterCropDescription'));
            else
                description = getString(message(...
                    'vision:cnn_layers:crop2dDescription', mat2str(this.Location)));
            end
            
            type = getString(message('vision:cnn_layers:crop2dType'));
        end
    end
  
end