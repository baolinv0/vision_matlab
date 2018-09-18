classdef ROIMaxPooling2DLayer < nnet.cnn.layer.Layer & nnet.internal.cnn.layer.Externalizable
    % ROIMaxPooling2DLayer ROI max pooling layer.
    %
    %   To create an ROI max pooling layer, use roiMaxPooling2dLayer.
    %
    %   ROIMaxPooling2DLayer properties (read-only):
    %     Name     - A name for the layer.
    %     GridSize - The height and width used to partition an ROI for max pooling.
    %
    % Example
    % -------
    % layer = roiMaxPooling2dLayer([6 6])
    %
    % See also roiMaxPooling2dLayer.
    
    % Copyright 2016-2017 The MathWorks, Inc.
    
    properties(Dependent)
        % Name A name for the layer.
        %   The name for the layer. If this is set to '', then a name will
        %   be automatically set at training time.
        Name
    end
    
    properties(SetAccess = private, Dependent)
        % GridSize The height and width by which to partition an ROI for max pooling.
        %  An ROI is divided into GridSize blocks. The dimensions of each
        %  block is floor( [roiHeight roiWidth] ./ GridSize] ) pixels. The
        %  data within each block is max pooled and returned as a feature
        %  map for each input ROI. Grid based partitioning enables
        %  fixed-sized outputs from arbitrarily sized ROIs. The size of the
        %  output is [height width C N], where C is the number of channels
        %  in the layer input and N is the number of input ROIs.
        GridSize
    end
    
    methods
        function this = ROIMaxPooling2DLayer(privateLayer)
            this.PrivateLayer = privateLayer;
        end
        
        function this = set.GridSize(this, sz)
            vision.cnn.layer.ROIMaxPooling2DLayer.validateGridSize(sz, mfilename, 'GridSize');
            this.PrivateLayer.GridSize = sz;
        end
        
        function sz = get.GridSize(this)
            sz = this.PrivateLayer.GridSize;
        end
        
        function name = get.Name(this)
            name = this.PrivateLayer.Name;
        end
        
        function this = set.Name(this, val)
            iAssertValidLayerName(val);
            this.PrivateLayer.Name = char(val);
        end
        
        function s = saveobj(this)
            privateLayer   = this.PrivateLayer;
            s.Version      = 1.0;
            s.Name         = privateLayer.Name;
            s.GridSize     = privateLayer.GridSize;
            s.PoolingLayer = privateLayer.PoolingLayer;
        end
    end
    
    methods(Access = protected)
        function [description, type] = getOneLineDisplay(this)
            sizeString  = mat2str(this.GridSize);
            description = getString(message('vision:roiPooling:oneLineDisp', sizeString));
            
            type = getString(message('vision:roiPooling:Type'));
        end
        
        function groups = getPropertyGroups( this )
            hyperparameters = {
                'GridSize'
                };
            
            groups = [
                this.propertyGroupGeneral( {'Name'} )
                this.propertyGroupHyperparameters( hyperparameters )
                ];
        end
    end
    
    methods(Hidden, Static)
        function validateGridSize(sz, name, varname)
            if isscalar(sz)
                validateattributes(sz, {'numeric'}, ...
                    {'scalar', 'positive', 'real', 'nonsparse'}, ...
                    name, varname);
            else
                validateattributes(sz, {'numeric'}, ...
                    {'row', 'numel', 2, 'positive', 'real', 'nonsparse'}, ...
                    name, varname);
            end
        end
        
        function obj = loadobj(s)
            internalLayer = vision.internal.cnn.layer.ROIMaxPooling2DLayer(...
                s.Name, s.GridSize);
            internalLayer.PoolingLayer = s.PoolingLayer;
            
            obj = vision.cnn.layer.ROIMaxPooling2DLayer(internalLayer);
        end
    end
end

function iAssertValidLayerName(name)
nnet.internal.cnn.layer.paramvalidation.validateLayerName(name);
end
