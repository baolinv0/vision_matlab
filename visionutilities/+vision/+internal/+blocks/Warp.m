classdef  Warp < matlab.System & matlab.system.mixin.Propagates
    %Warp Apply 2-D spatial transformation to an image
    %   hWarp = vision.Warp returns a geometric transformation
    %   System object, hWarp, which applies projective or affine
    %   transformation to an image.
    %
    %   hWarp = vision.Warp(Name, Value,...)
    %   returns a geometric transformation object, hWarp, with each specified
    %   property set to the specified value.
    %
    %   Step method syntax:
    %
    %   J = step(hWarp, I, tform) outputs the transformed image, J, of the
    %   input image, I. I is either an truecolor or a grayscale image. 
    %   tform is the applied transformation matrix. tform can be a 3-by-2 
    %   affine transformation matrix, or a 3-by-3 projective transformation
    %   matrix.
    %
    %   J = step(hWarp, I) outputs the transformed image, J, of the input
    %   image, I, when the TransformMatrixSource property is 'Custom'.
    %
    %   J = step(hWarp, I, roi) outputs the transformed image of the input
    %   image within the rectangular region of interest, roi. roi must be a
    %   4-element vector [x, y, width, height].
    %
    %   [J, roiValidity] = (hWarp, I, ...) returns a logical flag, roiValidity,
    %   indicating if any part of the region of interest is outside the input
    %   image, when the ROIValidityOutputPort property is true.
    %
    %   The above operations can be used simultaneously, provided the System
    %   object properties are set appropriately. One example of providing all
    %   possible inputs is shown below: [J, roiValidity] = step(hWarp,
    %   I, tform, roi) outputs the transformed image, J, of the input image, I,
    %   within the region of interest, roi, and using the transformation
    %   matrix, tform. roiValidity, indicating if any part of the region of
    %   interest is outside the input image is also returned.
    %
    %   Warp methods:
    %
    %   step     - See above description for use of this method
    %   release  - Allow property value and input characteristics changes
    %   clone    - Create geometric transformation object with same property values
    %   isLocked - Locked status (logical)
    %
    %   Warp properties:
    %
    %   TransformMatrixSource     - Source of transformation matrix
    %   TransformMatrix           - Transformation matrix
    %   InterpolationMethod       - Interpolation method
    %   BackgroundFillValue       - Background fill value
    %   OutputImagePositionSource - How to specify output image location and size
    %   OutputImagePosition       - Output image position vector [x y width height]
    %   ROIInputPort              - Enables the region of interest input port
    %   ROIValidityOutputPort     - Output flag indicating if any part of roi is
    %                               outside input image
    %
    %   Example - Apply a horizontal shear to an intensity image.
    %   ---------------------------------------------------------
    %
    %   htrans1 = vision.internal.blocks.Warp(...
    %                 'TransformMatrixSource', 'Custom', ...
    %                 'TransformMatrix',[1 0 0; .5 1 0; 0 0 1],...
    %                 'OutputImagePositionSource', 'Custom',...
    %                 'OutputImagePosition', [0 0 750 400]);
    %   img1 = imread('peppers.png');
    %   transimg1 = step(htrans1,img1);
    %   figure; imshow(transimg1);
    %
    %   See also estimateGeometricTransform, imwarp
    
    %   Copyright 2004-2014 The MathWorks, Inc.
    
    %#codegen
    
    %#ok<*EMCLS>
    %#ok<*EMCA>
    
    properties (Nontunable)
        %TransformMatrixSource Transformation matrix source
        %   Specify the TransformMatrixSource property as one of ['Custom' |
        %   {'Input port'}].
        TransformMatrixSource = 'Input port';

        %TransformMatrix Transformation matrix
        %   Specify the applied transformation matrix as a 3-by-2 affine 
        %   transformation matrix or a 3-by-3 projective transformation 
        %   matrix. This property is applicable when the 
        %   TransformMatrixSource property is 'Custom'. 
        %   The default value is [1 0 0; 0 1 0; 0 0 1].
        TransformMatrix = eye(3);
        
        %InterpolationMethod Interpolation method
        %   Specify the InterpolationMethod property as one of ['Nearest
        %   neighbor' | {'Bilinear'} | 'Bicubic'] for calculating the output
        %   pixel value.
        InterpolationMethod = 'Bilinear';

        %BackgroundFillValue Background fill value
        %   Specify the value of the pixels that are outside of the input
        %   image. The value can be either scalar or a P-element vector, where
        %   P is the number of color planes. The default value is 0.
        BackgroundFillValue = 0;

        %OutputImagePositionSource Output image position source
        %   Specify the OutputImagePositionSource property as one of 
        %   [{'Same as input image'} | 'Custom'].  
        OutputImagePositionSource = 'Same as input image';

        %OutputImagePosition Output image position vector [x y width height]
        %   Specify the location and size of output image in pixels, as a
        %   four-element vector of the form: [x y width height]. This property
        %   is applicable when the OutputImagePositionSource property is
        %   'Custom'. The default value is [1 1 512 512].
        OutputImagePosition = [1 1 512 512];
    end
    
    properties (Nontunable, Logical)
        %ROIInputPort Enable ROI input port
        %   Set this property to true to enable the input of the region of
        %   interest. When set to false, then the whole input image is
        %   processed. The default value of this property is false.
        ROIInputPort = false;
        
        %ROIValidityOutputPort Enable output port indicating if any part of ROI is outside input image
        %   Set this property to true to enable the output of an roi flag
        %   indicating when any part of the roi is outside the input image. This
        %   property is applicable when the ROIInputPort property is true. The
        %   default value is false.
        ROIValidityOutputPort = false;
    end
    
    properties (Constant, Hidden)
        TransformMatrixSourceSet = ...
            matlab.system.StringSet({'Custom', 'Input port'});
        InterpolationMethodSet = ...
            matlab.system.StringSet({'Nearest neighbor', 'Bilinear', 'Bicubic'});
        OutputImagePositionSourceSet = ...
            matlab.system.StringSet({'Same as input image', 'Custom'});
    end
    
    properties(Access=private)
        TformAffine;
        TformProjective;
    end
    
    properties(Nontunable, Access=private)
        Interp;
    end
    
    properties(Hidden)
        % These properties are used for backward compatibility, to be able to
        % automatically replace Warp block with the obsolete Apply Geometric
        % Transform block. This allows the user to export the model to be used
        % with previous versions of Simulink.
        
        ObsoleteOutputSize;
        ObsoleteOutputLoc;
    end
    
    methods
        %------------------------------------------------------------------
        function obj = Warp(varargin)
            setProperties(obj, nargin, varargin{:});            
        end
        
        %------------------------------------------------------------------
        function set.OutputImagePosition(obj, value) 
            validateattributes(value, {'double', 'single'}, ...
                {'real', 'nonsparse', 'finite', 'vector', 'numel', 4}, ...
                mfilename);
             coder.internal.errorIf(value(3) < 1 || value(4) < 1, ...
                 'vision:validation:invalidOutputPositionWidthHeight');
            obj.OutputImagePosition = round(single(value(:)'));
        end        
        
        %------------------------------------------------------------------
        function set.TransformMatrix(this, T)
            validateTform(T);
            this.TransformMatrix = T;
        end
        
        %------------------------------------------------------------------
        function set.BackgroundFillValue(this, fillVal)
            validateattributes(fillVal, {'numeric'},...
                {'nonempty', 'real', 'nonsparse', 'vector'}, ...
                mfilename, 'BackgroundFillValue');
            coder.internal.errorIf(numel(fillVal) ~= 1 && numel(fillVal) ~= 3,...
                'vision:calibrate:scalarOrTripletFillValueRequired');
            this.BackgroundFillValue = fillVal;
        end
    end
            
    methods (Access=protected)        
        %------------------------------------------------------------------
        function setupImpl(this, ~, T, ~)     
            coder.extrinsic('visionsyslinit');
            visionsyslinit;
                        
            % Create tform objects of the right data type
            if nargin > 1 && strcmpi(this.TransformMatrixSource, 'Input port')
                tformType = class(T);
            else
                tformType = class(this.TransformMatrix);
            end
            
            this.TformAffine = affine2d(cast(eye(3), tformType));
            this.TformProjective = projective2d(cast(eye(3), tformType));
            
            % Handle interp
            if strcmpi(this.InterpolationMethod, 'Nearest neighbor')
                this.Interp = 'nearest';
            else
                this.Interp = this.InterpolationMethod;
            end
        end
                
        %------------------------------------------------------------------
        function [outputImageSize, flagSize]  = getOutputSizeImpl(this)
            inputImageSize = propagatedInputSize(this, 1);
            if(~isempty(inputImageSize))
                if numel(inputImageSize) > 2
                    numChannels = inputImageSize(3);
                else
                    numChannels = 1;
                end
                
                if strcmpi(this.OutputImagePositionSource, 'Custom')
                    outputImageSize = double([this.OutputImagePosition(4:-1:3), numChannels]);
                else
                    outputImageSize = double(inputImageSize);
                end
                
                flagSize = [1 1];
            else
                outputImageSize = [];
                flagSize = [];
            end
        end
        
        %------------------------------------------------------------------
        function [outputImageDataType, flagType] = getOutputDataTypeImpl(this)
            outputImageDataType = propagatedInputDataType(this, 1);
            flagType = 'logical';
        end
        
        %------------------------------------------------------------------
        function [image, flag] = isOutputFixedSizeImpl(this)
            image = propagatedInputFixedSize(this, 1);
            flag = true;
        end
        
        %------------------------------------------------------------------
        function [image, flag] = isOutputComplexImpl(this)
            image = propagatedInputComplexity(this, 1);
            flag = false;
        end
        
        %------------------------------------------------------------------
        function numInputs = getNumInputsImpl(this)
            numInputs = 1;
            if strcmpi(this.TransformMatrixSource, 'Input port')
                numInputs = numInputs + 1;
            end
            
            if this.ROIInputPort
                numInputs = numInputs + 1;
            end
        end
        
        %------------------------------------------------------------------
        function [imagePort, port2, port3] = getInputNamesImpl(this)
            imagePort = '';
            port2 = '';
            
            useTformPort = strcmpi(this.TransformMatrixSource, 'Input port');
            useROIPort = this.ROIInputPort;
            
            if useTformPort && useROIPort
                imagePort = 'Image';
                port2 = 'TForm';
                port3 = 'ROI';
            elseif useTformPort
                imagePort = 'Image';
                port2 = 'TForm';
            elseif useROIPort
                imagePort = 'Image';
                port2 = 'ROI';
            end
        end
        
        %------------------------------------------------------------------
        function numOutputs = getNumOutputsImpl(this)
            if this.ROIValidityOutputPort
                numOutputs = 2;
            else
                numOutputs = 1;
            end
        end
        
        %------------------------------------------------------------------
        function [imageOutput, roiValidityOutput] = getOutputNamesImpl(this)
             if this.ROIValidityOutputPort
                 imageOutput = 'Image';
                 roiValidityOutput = 'Err_roi';
             else
                 imageOutput = '';
                 roiValidityOutput = '';
             end
        end
        
        %------------------------------------------------------------------
        function validateInputsImpl(this, I, input2, input3)
            vision.internal.inputValidation.validateImage(I);
            
            coder.internal.errorIf(...
                size(I, 3) == 1 && ~isscalar(this.BackgroundFillValue), ...
                'vision:calibrate:scalarFillValueRequired');
                
            % validate tform
            isTransformInputPort = strcmpi(this.TransformMatrixSource, 'Input port');                
            if nargin > 2 && isTransformInputPort
                T = input2;
                validateTform(T);
            end             
            
            % validate ROI
            if this.ROIInputPort
                if isTransformInputPort
                    roi = input3;
                else
                    roi = input2;
                end
                % roi must be 1-by-4 numeric vector
                validateattributes(roi, {'numeric'}, ...
                    {'real', 'nonsparse', 'finite', 'numel',4,'vector'},...
                    'checkROI', 'ROI');
                
                % width and height must be >= 0
                coder.internal.errorIf(roi(3) < 0 || roi(4) < 0, ...
                    'vision:validation:invalidROIWidthHeight');                
            end
        end
        
        %------------------------------------------------------------------
        function [Jout, invalidROI] = stepImpl(this, Image, input2, input3)
            invalidROI = false;
            if strcmpi(this.OutputImagePositionSource, 'Custom')
                pos = this.OutputImagePosition;
                imageSize = pos([4,3]);
                xLimits = [round(pos(1))-0.5, round(pos(1) + pos(3)) - 0.5];
                yLimits = [round(pos(2))-0.5, round(pos(2) + pos(4)) - 0.5];
            else
                imageSize = [size(Image,1), size(Image,2)];
                xLimits = [0.5, size(Image,2)+.5];
                yLimits = [0.5, size(Image,1)+.5];
            end
               
            outputRef = imref2d(imageSize, xLimits, yLimits);
            
            if isa(Image, 'logical')
                Jout = coder.nullcopy(true(imageSize));
            else
                Jout = coder.nullcopy(...
                    zeros([imageSize, size(Image, 3)], 'like', Image));
            end
                        
            roi = [0 0 0 0];
            switch nargin
                case 2
                    TForm = this.TransformMatrix;
                    useROI = false;                    
                case 3
                    if isvector(input2)
                        TForm = this.TransformMatrix;
                        useROI = true;
                        roi = double(input2);
                    else
                        TForm = input2;
                        useROI = false;
                    end
                case 4
                    TForm = input2;
                    roi = double(input3);
                    useROI = true;
            end
                        
            if useROI
                % check roi validity
                invalidROI = isROIInvalid(roi, [size(Image, 1), size(Image, 2)]);
                if invalidROI
                    x = max(round(roi(1)), 1);
                    y = max(round(roi(2)), 1);
                    x2 = min(round(roi(1) + roi(3))-1, size(Image, 2));
                    y2 = min(round(roi(2) + roi(4))-1, size(Image, 1));
                else
                    x = round(roi(1));
                    y = round(roi(2));
                    x2 = round(roi(1) + roi(3))-1;
                    y2 = round(roi(2) + roi(4))-1;
                end
                roi = [x, y, x2 - x + 1, y2 - y + 1];
                
                xlims = [roi(1), roi(1)+roi(3)-1];
                ylims = [roi(2), roi(2)+roi(4)-1];
                
                I = Image(ylims(1):ylims(2), xlims(1):xlims(2),:);
                inputRef = imref2d([size(I, 1), size(I, 2)], [xlims(1)-0.5, xlims(2)+0.5],...
                    [ylims(1)-0.5, ylims(2)+0.5]);
            else
                I = Image;
                inputRef = imref2d([size(I, 1), size(I, 2)]);
            end
            
            if size(TForm, 2) == 2
                this.TformAffine.T = TForm;
                J = transformImage(this, I, this.TformAffine, ...
                    inputRef, outputRef);
            else
                this.TformProjective.T = TForm;
                J = transformImage(this, I, this.TformProjective, ...
                    inputRef, outputRef);
            end
            Jout(:,:,:) = J(1:size(Jout,1), 1:size(Jout,2), 1:size(Jout,3));
        end
        
        %------------------------------------------------------------------
        function flag = isInactivePropertyImpl(obj, prop)
            props = {};
            if strcmp(obj.TransformMatrixSource,'Input port')
                props{end+1} = 'TransformMatrix';
            end
            if ~strcmp(obj.OutputImagePositionSource, 'Custom')
                props{end+1} = 'OutputImagePosition';
            end
            
            if ~obj.ROIInputPort
                props{end+1} = 'ROIShape';
                props{end+1} = 'ROIValidityOutputPort';
            end
            
            flag = ismember(prop, props);
        end                
        
        %------------------------------------------------------------------
        function s = saveObjectImpl(this)
            s.TransformMatrixSource = this.TransformMatrixSource;
            s.TransformMatrix = this.TransformMatrix;
            s.InterpolationMethod = this.InterpolationMethod;
            s.BackgroundFillValue = this.BackgroundFillValue;
            s.OutputImagePositionSource = this.OutputImagePositionSource;
            s.OutputImagePosition = this.OutputImagePosition;
            s.ROIInputPort = this.ROIInputPort;
            s.TformAffine = this.TformAffine;
            s.TformProjective = this.TformProjective;
            s.Interp = this.Interp;
        end
        
        %------------------------------------------------------------------
        function loadObjectImpl(this, s, ~)
            this.TransformMatrixSource = s.TransformMatrixSource;
            this.TransformMatrix = s.TransformMatrix;
            this.InterpolationMethod = s.InterpolationMethod;
            this.BackgroundFillValue = s.BackgroundFillValue;
            this.OutputImagePositionSource = s.OutputImagePositionSource;
            this.OutputImagePosition = s.OutputImagePosition;
            this.ROIInputPort = s.ROIInputPort;
            this.TformAffine = s.TformAffine;
            this.TformProjective = s.TformProjective;
            this.Interp = s.Interp;
        end
    end % methods, protected API
    

    methods(Access=private)
        function J = transformImage(this, Image, tform, inputRef, outputRef)
            J = imwarp(Image, inputRef, tform, this.Interp, 'OutputView',...
                outputRef, 'FillValues', this.BackgroundFillValue);
        end
    end   
    
    methods(Static, Access=protected)
        %------------------------------------------------------------------
        % Configure the block's dialog header
        %------------------------------------------------------------------
        function header = getHeaderImpl()
            header = matlab.system.display.Header('vision.internal.blocks.Warp',...
                'Title', 'Warp', 'Text', ...
                getString(message('vision:warp:header')), ...
                'ShowSourceLink', false);
        end
        
        %------------------------------------------------------------------
        % Configure the property prompts of the block's dialog 
        %------------------------------------------------------------------
        function group = getPropertyGroupsImpl()            
            transformMatrixSourceProp = propertyLabel('TransformMatrixSource', ...
                'vision:warp:transformMatrixSource');
            
            transformMatrixProp = propertyLabelIndented(...
                'TransformMatrix', 'vision:warp:transformMatrix');
            
            interpProp = propertyLabel('InterpolationMethod', ...
                'vision:warp:interpolationMethod');
            
            fillValueProp = propertyLabel('BackgroundFillValue', ...
                'vision:warp:fillValue');
        
            outputPositionSourceProp = propertyLabel('OutputImagePositionSource', ...
                'vision:warp:outputImagePositionSource');
            
            outputPositionProp = propertyLabelIndented(...
                'OutputImagePosition', 'vision:warp:outputImagePosition');
            
            roiInputPortProp = propertyLabel('ROIInputPort', ...
                'vision:warp:roiInputPort');
            
            roiValidityProp = propertyLabelIndented(...
                'ROIValidityOutputPort', 'vision:warp:roiValidityOutputPort');
            
            group = matlab.system.display.Section('Title', 'Parameters', ...
                'PropertyList', {transformMatrixSourceProp, transformMatrixProp, ...
                interpProp, fillValueProp, ...
                outputPositionSourceProp, outputPositionProp, ...
                roiInputPortProp, roiValidityProp});
         end

    end
end

%--------------------------------------------------------------------------
% Create a property prompt label for the dialog
%--------------------------------------------------------------------------
function prop = propertyLabel(name, descriptionId)
description = getString(message(descriptionId));
prop = matlab.system.display.internal.Property(name, 'Description', ...
    description);
end

%--------------------------------------------------------------------------
% Create an indented property prompt label for the dialog
%--------------------------------------------------------------------------
function prop = propertyLabelIndented(name, descriptionId)
indent = '      ';
description = [indent, getString(message(descriptionId))];
prop = matlab.system.display.internal.Property(name, 'Description', ...
    description);
end

%--------------------------------------------------------------------------
function tf = isROIInvalid(roi, imageSize)
tf = roi(1) < 1 || roi(2) < 1 ||...
    roi(1) + roi(3) - 1 > imageSize(2) || ...
    roi(2) + roi(4) - 1 > imageSize(1);
end

%--------------------------------------------------------------------------
function validateTform(T)
validateattributes(T, {'double', 'single'},...
                {'real', 'nonsparse', 'finite', '2d'}, ...
                mfilename, 'TransformMatrix');
coder.internal.errorIf(...
    size(T, 1) ~= 3 || (size(T, 2) ~= 2 && size(T, 2) ~= 3), ...
    'vision:validation:invalidTransformMatrixSize');
end
