% PixelClassificationLayer  Pixel classification output layer.
%
%   A pixel classification layer is used as the output layer for a network
%   that performs semantic image segmentation. Use pixelClassificationLayer
%   to create this layer.
%
%   PixelClassificationLayer properties:
%       Name          - A name for the layer.
%       ClassNames    - The names of the classes.
%       ClassWeights  - The weight assigned to each class.
%       OutputSize    - The size of the output.
%       LossFunction  - The loss function that is used for training.
%
% Example
% -------
% % Create a output layer.
% layer = pixelClassificationLayer()
%
% See also semanticseg, pixelLabelImageGenerator, pixelLabelDatastore,
%          pixelLabelImageGenerator/countEachLabel, trainNetwork.

% Copyright 2017 The MathWorks, Inc.

classdef PixelClassificationLayer < nnet.cnn.layer.Layer & nnet.internal.cnn.layer.Externalizable
    
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
        
        % ClassWeights The weight associated with each class
        %   Class weights are stored as a vector W. The weight W(k)
        %   corresponds to k-th class name in ClassNames. Use class
        %   weighting to balance classes when there are underrepresented
        %   classes in the training data. If there are no class weights,
        %   ClassWeights is 'none'.
        ClassWeights
        
        % OutputSize   The size of the output
        %   The size of the output. This will be determined at training
        %   time. Prior to training, it is set to 'auto'.
        OutputSize
    end
    
    properties(SetAccess = private)
        % LossFunction   The loss function for training
        %   The loss function that will be used during training. Possible
        %   values are:
        %       'crossentropyex'    - Cross-entropy for exclusive outputs.
        LossFunction = 'crossentropyex';
    end
    
    methods
        function val = get.OutputSize(this)
            if(isempty(this.PrivateLayer.OutputSize))
                val = 'auto';
            else
                val = this.PrivateLayer.OutputSize;
            end
        end
        
        function val = get.ClassNames(this)
            if ischar(this.PrivateLayer.ClassNames)
                val = this.PrivateLayer.ClassNames;
            else
                val = this.PrivateLayer.ClassNames(:);
            end
        end
        
        function w = get.ClassWeights(this)
            if isempty(this.PrivateLayer.ClassWeights)
                w = 'none';
            else
                w = this.PrivateLayer.ClassWeights;
            end
        end
        
        function val = get.Name(this)
            val = this.PrivateLayer.Name;
        end
        
        function this = set.Name(this, val)
            iAssertValidLayerName(val);
            this.PrivateLayer.Name = char(val);
        end  
    end
    
    methods
        function this = PixelClassificationLayer(privateLayer)
            this.PrivateLayer = privateLayer;
        end
        
        function out = saveobj(this)
            
            privateLayer = this.PrivateLayer;
            out.Version = 1.0;
            out.Name = privateLayer.Name;
            out.OutputSize   = privateLayer.OutputSize;
            out.ClassNames   = privateLayer.ClassNames;
            out.ClassWeights = privateLayer.ClassWeights;
        end
    end
    
    methods(Hidden, Static)
        %------------------------------------------------------------------
        function this = loadobj(in)
            internalLayer = nnet.internal.cnn.layer.SpatialCrossEntropy(...
                in.Name, in.ClassNames, in.ClassWeights, in.OutputSize);
            
            this = nnet.cnn.layer.PixelClassificationLayer(internalLayer);
        end
    end
    
    methods(Hidden, Access = protected)
        %------------------------------------------------------------------
        function [description, type] = getOneLineDisplay(this)
            
            numClasses = numel(this.ClassNames);
            
            if numClasses==0
                classString = '';
                
            elseif numClasses==1
                classString = getString(message('vision:semanticseg:oneLineDisplayOneClass', this.ClassNames{1}));
                
            elseif numClasses==2
                classString = getString(message(...
                    'vision:semanticseg:oneLineDisplayTwoClasses',...
                    this.ClassNames{1},...
                    this.ClassNames{2}));
                
            elseif numClasses>=3
                classString = getString(message(...
                    'vision:semanticseg:oneLineDisplayNClasses',...
                    this.ClassNames{1},...
                    this.ClassNames{2},...
                    int2str(numClasses-2)));
            end
            
            if strcmp(this.ClassWeights, 'none')
                description = getString(message(...
                    'vision:semanticseg:oneLineDisplay', classString));
            else
                description = getString(message(...
                    'vision:semanticseg:oneLineDisplayWeighted', classString));
            end
            
            type = getString(message('vision:semanticseg:OneLineDispName'));
        end
        
        function groups = getPropertyGroups( this )
            if numel(this.ClassNames) < 11 && ~ischar(this.ClassNames)
                propertyList = struct;
                propertyList.Name = this.Name;
                propertyList.ClassNames = this.ClassNames';
                propertyList.ClassWeights = this.ClassWeights;
                propertyList.OutputSize = this.OutputSize;
                groups = [
                    matlab.mixin.util.PropertyGroup(propertyList, '');
                    this.propertyGroupHyperparameters( {'LossFunction'} )
                    ];
            else
                generalParameters = {'Name' 'ClassNames' 'ClassWeights' 'OutputSize'};
                groups = [
                    this.propertyGroupGeneral( generalParameters )
                    this.propertyGroupHyperparameters( {'LossFunction'} )
                    ];
            end
        end
        
    end
    
    methods(Hidden, Static)
        %------------------------------------------------------------------
        function params = parseInputs(varargin)
            p = inputParser();
            
            p.addParameter('Name', '', @nnet.internal.cnn.layer.paramvalidation.validateLayerName);
            p.addParameter('ClassNames', 'auto');
            p.addParameter('ClassWeights', 'none');
            
            p.parse(varargin{:});
            
            userInput = p.Results;
            
            names   = iCheckAndFormatClassNames(userInput.ClassNames);
            weights = iCheckAndFormatClassWeights(userInput.ClassWeights);
            
            % Cross-check weights and classnames
            if ~isempty(weights)
                
                if isempty(names)
                    error(message('vision:semanticseg:ClassNamesRequired'));
                end
                
                if numel(weights) ~= numel(names)
                    error(message('vision:semanticseg:ClassNamesWeightsMismatch'));
                end
            end
            
            params.Name            = char(userInput.Name);
            params.ClassNames      = names;
            params.ClassWeights    = weights;
            
        end
    end
end

%--------------------------------------------------------------------------
function names = iCheckAndFormatClassNames(names)
    if ~(isvector(names) && (ischar(names) || iscellstr(names) || isstring(names)))
        %error('Must be vector of strings or cell array of strings');
        error(message('vision:semanticseg:InvalidClassNames'));
    end
    
    names = string(names);
    isAuto = numel(names)== 1 && names == "auto";
    
    if isAuto
        names = cell(0,1);
    else
        
        if numel(unique(names)) ~= numel(names)
            error(message('vision:semanticseg:NonUniqueClassNames'));
        end
        % return names as cellstr
        names = reshape(cellstr(names),[],1);
    end
    
    
end

%--------------------------------------------------------------------------
function w = iCheckAndFormatClassWeights(w)
    if ischar(w) || isstring(w)
        
        validatestring(w, {'none'}, 'pixelClassificationLayer', 'ClassWeights');
        w = [];
    else
        validateattributes(w, {'numeric'}, {'vector', 'positive', 'finite', 'real', 'nonsparse'}, ...
            'pixelClassificationLayer', 'ClassWeights');
        
        w = reshape(double(w),[],1);
        
    end
end

%--------------------------------------------------------------------------
function iAssertValidLayerName(name)
nnet.internal.cnn.layer.paramvalidation.validateLayerName(name);
end