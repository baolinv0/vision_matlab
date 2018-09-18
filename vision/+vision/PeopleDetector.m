classdef PeopleDetector < matlab.System 
    %PeopleDetector Detect upright people using HOG features
    %   DETECTOR = vision.PeopleDetector creates a System object that
    %   detects upright, unoccluded, people. The detector uses Histogram of
    %   Oriented Gradient (HOG) features and a trained Support Vector
    %   Machine (SVM) classifier.
    %
    %   DETECTOR = vision.PeopleDetector(MODEL) creates a System object and
    %   sets the ClassificationModel to MODEL. The input MODEL can be
    %   either 'UprightPeople_128x64' or 'UprightPeople_96x48'.
    %
    %   DETECTOR = vision.PeopleDetector(...,Name,Value) configures the
    %   System object properties, specified as one or more name-value pair
    %   arguments. Unspecified properties have default values.
    %
    %   Step method syntax:
    %
    %   BBOXES = step(DETECTOR,I) performs multi-scale object detection on
    %   the input image, I, and returns, BBOXES, an M-by-4 matrix defining
    %   M bounding boxes containing the detected people. Each row in BBOXES
    %   is a four-element vector, [x y width height], that specifies the
    %   upper left corner and size of a bounding box in pixels. When no
    %   people are detected, BBOXES is empty. I must be a grayscale or
    %   truecolor (RGB) image.
    %
    %   [BBOXES, SCORES] = step(DETECTOR,I) returns the detection SCORES
    %   for each bounding box in an M-by-1 vector. The SCORES are positive
    %   values. Larger score values indicate a higher confidence in the
    %   detection.
    %
    %   [...] = step(DETECTOR, I, ROI) detects people within the
    %   rectangular search region specified by ROI. ROI must be a 4-element
    %   vector, [x y width height], that defines a rectangular region of
    %   interest within image I. The 'UseROI' property must be true to use
    %   this syntax.
    %
    %   System objects may be called directly like a function instead of using
    %   the step method. For example, y = step(obj, x) and y = obj(x) are
    %   equivalent.
    %
    %   PeopleDetector methods:
    %
    %   step     - See above description for use of this method
    %   release  - Allow property value and input characteristics changes
    %   clone    - Create people object detector object with same property
    %              values
    %   isLocked - Locked status (logical)
    %
    %   PeopleDetector properties:
    %
    %   ClassificationModel     - Name of the classification model
    %   ClassificationThreshold - People classification threshold
    %   MinSize                 - Size of the smallest region containing a
    %                             person
    %   MaxSize                 - Size of the biggest region containing a 
    %                             person
    %   ScaleFactor             - Scaling for multi-scale object detection
    %   WindowStride            - Detection window stride
    %   MergeDetections         - Control whether similar detections are
    %                             merged
    %   UseROI                  - Detect people within a region of interest
    %
    %   % Example: Detect people
    %   % ----------------------------        
    %   
    %   % Create people detector    
    %   peopleDetector = vision.PeopleDetector;        
    % 
    %   I = imread('visionteam1.jpg');
    %   [bboxes, scores] = step(peopleDetector, I);  % Detect people
    %
    %   % Annotate detected people    
    %   I = insertObjectAnnotation(I, 'rectangle', bboxes, scores);
    %   figure, imshow(I)
    %   title('Detected people and detection scores'); 
    %
    %   See also peopleDetectorACF, vision.CascadeObjectDetector,
    %   insertObjectAnnotation, extractHOGFeatures
 
    %   Copyright 2012-2016 The MathWorks, Inc.
    
    %   References: 
    %   ----------- 
    %   [1] Dalal, N. and Triggs, B., Histograms of Oriented Gradients for
    %   Human Detection. CVPR 2005.
    
    %#codegen
    %#ok<*EMCA>
    
    properties(Nontunable)
        %ClassificationModel Name of the classification model
        %   Specify the name of the model as a string. Valid values for
        %   this property are 'UprightPeople_128x64' and
        %   'UprightPeople_96x48', where the image size used for training
        %   is 128-by-64 and 96-by-48 pixels, respectively. Note that the
        %   images used to train the models include background pixels
        %   around the actual person. Therefore, the actual size of a
        %   detected person is smaller than the training image size.
        %
        %   Default: 'UprightPeople_128x64'
        ClassificationModel = 'UprightPeople_128x64';
    end
    
    properties       
        %ClassificationThreshold People classification threshold
        %   Specify a threshold value as a non-negative scalar. Use this
        %   threshold to control the classification of individual image
        %   sub-regions as person or non-person during multi-scale object
        %   detection. Increase this threshold in situations where many
        %   false detections occur. This property is tunable. Typical
        %   values range from 0 to 4.
        %
        %   Default: 1
        ClassificationThreshold = 1;
        %MinSize Size of the smallest region containing a person
        %   Specify the size of the smallest region containing a person, in
        %   pixels, as a two-element vector, [height width]. When you know
        %   the minimum person size to detect, you can reduce computation
        %   time by setting this property to a value larger than the image
        %   size used to train the classification model. When you do not
        %   specify this property, the object sets it to the image size
        %   used to train the classification model. This property is
        %   tunable.                
        %
        %   Default: []              
        MinSize = [];
        %MaxSize Size of the biggest region containing a person
        %   Specify the size of the biggest region containing a person, in
        %   pixels, as a two-element vector, [height width]. When you know
        %   the maximum person size to detect, you can reduce computation
        %   time by setting this property to a value smaller than the size
        %   of the input image. When you do not specify this property, the
        %   object sets it to the input image size. This property is
        %   tunable.
        %
        %   Default: []
        MaxSize = [];
        %ScaleFactor Scaling for multi-scale object detection
        %   Specify the factor used to incrementally scale the detection
        %   resolution between MinSize and MaxSize. The ScaleFactor must be
        %   greater than or equal to 1.0001. At each increment, N, the
        %   detection resolution is
        %
        %     round(TrainingSize*(ScaleFactor^N)). 
        %
        %   The TrainingSize is [128 64] for the 'UprightPeople_128x64'
        %   model and [96 48] for the 'UprightPeople_96x48' model.
        %   Decreasing the scale factor can increase the detection
        %   accuracy. However, doing so increases the computation time.
        %   This property is tunable.
        %
        %   Default: 1.05
        ScaleFactor = 1.05;
        %WindowStride Detection window stride
        %   Specify a scalar or a two-element vector [x y] in pixels for
        %   the detection window stride. The object uses the window stride
        %   to slide the detection window across the image. When you
        %   specify this value as a vector, the first and second elements
        %   are the stride size in the x and y directions. When you specify
        %   this value as a scalar, the stride is the same for both x and
        %   y. Decreasing the window stride can increase the detection
        %   accuracy. However, doing so increases computation time.
        %   Increasing the window stride beyond [8 8] can lead to a greater
        %   number of missed detections. This property is tunable. 
        %
        %   Default: [8 8]
        WindowStride = [8 8];
    end
        
    properties(Logical, Nontunable)
        %MergeDetections Control whether similar detections are merged
        %   Specify a logical scalar to control whether similar detections
        %   are merged using a mean shift based algorithm. Set this
        %   property to false to output unprocessed bounding boxes and
        %   detection scores. This is useful if you want to perform a
        %   custom merge operation.
        %
        %   Default: true
        MergeDetections = true; 
        
        % UseROI Detect objects within a ROI
        %    Set to true to detect objects within a rectangular region of
        %    interest within I.
        %
        % Default: false
        UseROI = false;
    end
    
    properties (Transient,Access = private)        
        pHOGDescriptor;      
        pTrainingSize;
    end   

    methods
        %------------------------------------------------------------------
        % Constructor
        %------------------------------------------------------------------
        function obj = PeopleDetector(varargin)       
            if (isSimMode())
                obj.pHOGDescriptor = vision.internal.HOGDescriptor;  
            else
                obj.pHOGDescriptor = ...
                    vision.internal.buildable.HOGDescriptorBuildable.HOGDescriptor_construct();
            end                
            setProperties(obj,nargin,varargin{:},'ClassificationModel');   
            setupModel(obj); 
            validatePropertiesImpl(obj);
        end
        
        %------------------------------------------------------------------
        % ClassificationModel set method
        %------------------------------------------------------------------
        function set.ClassificationModel(obj,value)            
            validateattributes(value,{'char'},{'nonempty','row'}, ...
                mfilename, 'ClassificationModel');   
            
            obj.ClassificationModel = value;               
            setupModel(obj);
        end
        
        %------------------------------------------------------------------
        % ClassificationThreshold set method
        %------------------------------------------------------------------
        function set.ClassificationThreshold(obj,value) 
            validateattributes( value,{'numeric'},...
                {'scalar', '>=',0,'real', 'nonempty','nonsparse','finite'},...
                mfilename,'ClassificationThreshold');
            
            obj.ClassificationThreshold = value;
        end
        
        %------------------------------------------------------------------
        % ScaleFactor set method
        %------------------------------------------------------------------
        function set.ScaleFactor(obj,value) 
            validateattributes( value,{'numeric'},...
                {'scalar', '>=',1.0001,'real', 'nonempty','nonsparse','finite'},...
                mfilename,'ScaleFactor');
            
            obj.ScaleFactor = value;
        end
        
        %------------------------------------------------------------------
        % MinSize set method
        %------------------------------------------------------------------
        function set.MinSize(obj,value)
            validateSize('MinSize',value);
            obj.MinSize = value;
        end
        
        %------------------------------------------------------------------
        % MaxSize set method
        %------------------------------------------------------------------
        function set.MaxSize(obj,value)            
            validateSize('MaxSize',value);
            obj.MaxSize = value;
        end
        
        %------------------------------------------------------------------
        % WindowStride set method
        %------------------------------------------------------------------
        function set.WindowStride(obj,value)
           validateattributes(value,...
               {'numeric'}, ...
               {'real','positive','integer', ...
               'nonempty','row','vector', 'nonsparse'},...
               mfilename,'WindowStride');
            if isscalar(value)
                obj.WindowStride = [value value];
            else
                validateattributes(value,{'numeric'},{'numel',2},...
                    mfilename,'WindowStride');
                obj.WindowStride = value;
            end
        end
        
        %------------------------------------------------------------------
        % MergeDetections set method
        %------------------------------------------------------------------
        function set.MergeDetections(obj,value)            
            obj.MergeDetections = value;
        end
        
        %------------------------------------------------------------------
        % UseROI set method
        %------------------------------------------------------------------
        function set.UseROI(obj, value)                       
            obj.UseROI = logical(value);
        end           
    end
    
    properties (Constant, Hidden, Nontunable)
        ClassificationModelSet = matlab.system.StringSet({'UprightPeople_128x64','UprightPeople_96x48'});
    end
    
    methods(Access = protected)        
        %------------------------------------------------------------------
        % Cross validate properties
        %------------------------------------------------------------------
        function validatePropertiesImpl(obj)

            % validate that MinSize is greater than or equal to the minimum
            % object size used to train the classification model
            if ~isempty(obj.MinSize)
                coder.internal.errorIf(any(obj.MinSize < obj.pTrainingSize) , ...
                    'vision:ObjectDetector:minSizeLTTrainingSize', ...
                    obj.pTrainingSize(1),obj.pTrainingSize(2));
            end
            
            % validate the MaxSize is greater than the TrainingSize when
            % MinSize is not specified
            if isempty(obj.MinSize) && ~isempty(obj.MaxSize)
                coder.internal.errorIf(any(obj.pTrainingSize >= obj.MaxSize) , ...
                    'vision:ObjectDetector:modelMinSizeGTMaxSize', ...
                    obj.pTrainingSize(1),obj.pTrainingSize(2));
            end
            
            % validate that MinSize < MaxSize
            if ~isempty(obj.MaxSize) && ~isempty(obj.MinSize)   
                coder.internal.errorIf(any(obj.MinSize >= obj.MaxSize) , ...
                    'vision:ObjectDetector:minSizeGTMaxSize');
            end
            
        end
             
        %------------------------------------------------------------------
        % Setup implementation 
        %------------------------------------------------------------------
        function setupModel(obj,~)
            % setup the HOG people detector 
            
            switch obj.ClassificationModel
                case 'UprightPeople_128x64'
                    model = 1;
                    obj.pTrainingSize = [128 64];
                case 'UprightPeople_96x48'
                    model = 2;                    
                    obj.pTrainingSize = [96 48];                  
            end               

            if (isSimMode())
                obj.pHOGDescriptor.setup(model);
            else
                vision.internal.buildable.HOGDescriptorBuildable.HOGDescriptor_setup(obj.pHOGDescriptor, model);
            end             
            
        end
        
        %------------------------------------------------------------------
        % Release method implementation
        %------------------------------------------------------------------
        function releaseImpl(obj)
            if (~isSimMode())
                % delete HOGDescriptor object
                vision.internal.buildable.HOGDescriptorBuildable.HOGDescriptor_deleteObj(obj.pHOGDescriptor);
            end
        end
        
        %------------------------------------------------------------------
        % Validate inputs to STEP method
        %------------------------------------------------------------------
        function validateInputsImpl(obj, I, varargin)            
            validateattributes(I,...
                {'uint8','uint16','double','single','int16'},...
                {'real','nonsparse'},...
                'PeopleDetector','I',2);
            numDims = ndims(I);                      
            
            % verify I is 2D or 3D
            coder.internal.errorIf(~any(numDims == [2 3]), ...
                    'vision:dims:imageNot2DorRGB');            
            
            % verify that a 3D I has 3 color planes
            coder.internal.errorIf(numDims == 3 && size(I,3) ~= 3, ...
                    'vision:dims:imageNot2DorRGB');
                                
            if obj.UseROI
                vision.internal.detector.checkROI(varargin{1},size(I));                                                                              
            end
        end
        
        %------------------------------------------------------------------
        % STEP method implementation
        %------------------------------------------------------------------
        function [bbox, score] = stepImpl(obj,I,varargin)
            
            if obj.UseROI
                roi = varargin{1};
            else
                roi = zeros(0,4);
            end
            
            Iroi = vision.internal.detector.cropImageIfRequested(I, roi, obj.UseROI);
            
            Iu8  = im2uint8(Iroi);
            
            if (isSimMode())
                postMergeThreshold = 0;
                [bbox, score] = obj.pHOGDescriptor.detectMultiScale(Iu8, ...
                    double(obj.ScaleFactor), ...
                    double(obj.ClassificationThreshold), ...      
                    postMergeThreshold, ...    
                    int32(obj.MinSize),...
                    int32(obj.MaxSize),...
                    int32(obj.WindowStride),...
                    obj.MergeDetections);
                
            else
                if isempty(obj.MinSize)
                    obj_MinSize = [0 0];
                else
                    obj_MinSize = obj.MinSize;
                end
                if isempty(obj.MaxSize)
                    obj_MaxSize = [0 0];
                else
                    obj_MaxSize = obj.MaxSize;
                end 
                
                postMergeThreshold = 0;
                [bbox, score] = vision.internal.buildable.HOGDescriptorBuildable.HOGDescriptor_detectMultiScale(obj.pHOGDescriptor ,...
                    Iu8, ...
                    obj.ScaleFactor, ... % double
                    obj.ClassificationThreshold, ...    % double   
                    postMergeThreshold, ...  % double  
                    obj_MinSize,... % int32
                    obj_MaxSize,... % int32
                    obj.WindowStride,... % int32
                    obj.MergeDetections); % logical               
            end
                  
            bbox = vision.internal.detector.clipBBox(bbox, size(Iroi));
                  
            bbox(:,1:2) = vision.internal.detector.addOffsetForROI(bbox(:,1:2), roi, obj.UseROI);
                                    
        end
                          
        %------------------------------------------------------------------
        % Return the number of inputs
        %------------------------------------------------------------------
        function num_inputs = getNumInputsImpl(obj)
            if obj.UseROI
                num_inputs = 2;
            else
                num_inputs = 1;
            end
        end
        
        %------------------------------------------------------------------
        % Return the number of outputs
        %------------------------------------------------------------------
        function num_outputs = getNumOutputsImpl(~)
            num_outputs = 2;
        end          
        
             
        %------------------------------------------------------------------
        % Custom save/load method
        %------------------------------------------------------------------
        function s = saveObjectImpl(obj)
            s = saveObjectImpl@matlab.System(obj);
        end
        
        function loadObjectImpl(obj,s,~)                    
            if ~isfield(s, 'UseROI') % UseROI added in R2015a
                s.UseROI = false;
            end
            loadObjectImpl@matlab.System(obj, s);
        end
        
    end
    
end % of classdef

%--------------------------------------------------------------------------
% Validation for MinSize and MaxSize
%--------------------------------------------------------------------------
function validateSize(prop,value)
% By default MaxSize/MinSize is [], and it can be set to empty too.
validateattributes( value,...
    {'numeric'}, {'real','nonsparse','finite','2d','integer', '>=',0},...
    mfilename,prop);
% Using 'vector',2 in validateattributes fails for [] so the
% following check makes sure that MaxSize has 2-elements
coder.internal.errorIf(~isempty(value) && (numel(value) ~= 2), ...
    'vision:ObjectDetector:invalidSize',prop);
end

%==========================================================================
function flag = isSimMode()
    flag = isempty(coder.target);
end
