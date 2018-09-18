classdef CascadeObjectDetector< matlab.System
%CascadeObjectDetector Detect objects using the Viola-Jones algorithm
%   DETECTOR = vision.CascadeObjectDetector creates a System object
%   that detects objects using the Viola-Jones algorithm. The DETECTOR
%   is capable of detecting a variety of objects, including faces and a
%   person's upper body. The type of object to detect is controlled by
%   the ClassificationModel property. By default, the DETECTOR is
%   configured to detect faces.
%
%   DETECTOR = vision.CascadeObjectDetector(MODEL) creates a System
%   object, DETECTOR, configured to detect objects defined by MODEL.
%   MODEL is a string describing the type of object to detect. There
%   are several valid MODEL strings. Examples include
%   'FrontalFaceCART', 'UpperBody', and 'ProfileFace'.
%
%   <a href="matlab:helpview(fullfile(docroot,'toolbox','vision','vision.map'),'vision.CascadeObjectDetector.ClassificationModel')">A list of all available models is shown in the documentation.</a>        
%   
%   DETECTOR = vision.CascadeObjectDetector(XMLFILE) creates a System 
%   object, DETECTOR, and configures it to use the custom classification
%   model specified with the XMLFILE input. XMLFILE can be created using    
%   the trainCascadeObjectDetector function or OpenCV training 
%   functionality. You must specify a full or relative path to the 
%   XMLFILE, if it is not on the MATLAB path.
%
%   DETECTOR = vision.CascadeObjectDetector(...,Name,Value) configures
%   the System object properties, specified as one or more name-value
%   pair arguments. Unspecified properties have default values.
%
%   BBOXES = step(DETECTOR, I) performs multi-scale object detection on
%   the input image, I, and returns, BBOXES, an M-by-4 matrix defining
%   M bounding boxes containing the detected objects. Each row in
%   BBOXES is a four-element vector, [x y width height], that specifies
%   the upper left corner and size of a bounding box in pixels. When no
%   objects are detected, BBOXES is empty. I must be a grayscale or
%   truecolor (RGB) image.
%
%   [...] = step(DETECTOR, I, ROI) detects objects within the
%   rectangular search region specified by ROI. ROI must be a 4-element
%   vector, [x y width height], that defines a rectangular region of
%   interest within image I. The 'UseROI' property must be true to use
%   this syntax.
%
%   System objects may be called directly like a function instead of using
%   the step method. For example, y = step(obj, x) and y = obj(x) are
%   equivalent.
%
%   CascadeObjectDetector methods:
%
%   step     - See above description for use of this method
%   release  - Allow property value and input characteristics changes
%   clone    - Create cascade object detector object with same property
%              values
%   isLocked - Locked status (logical)
%
%   CascadeObjectDetector properties:
%
%   ClassificationModel   - Name of the classification model
%   MinSize               - Size of the smallest object to detect
%   MaxSize               - Size of the biggest object to detect
%   ScaleFactor           - Scaling for multi-scale object
%                           detection
%   MergeThreshold        - Threshold for merging colocated detections
%   UseROI                - Detect objects within a region of interest
%
%   % Example 1:  Face detection
%   % ----------------------------        
%   faceDetector = vision.CascadeObjectDetector; % Default: finds faces 
%
%   I = imread('visionteam.jpg');
%   bboxes = step(faceDetector, I); % Detect faces
%
%   % Annotate detected faces
%   IFaces = insertObjectAnnotation(I, 'rectangle', bboxes, 'Face');   
%   figure, imshow(IFaces), title('Detected faces'); 
%    
%   % Example 2: Upper body detection
%   % --------------------------------------       
%   bodyDetector = vision.CascadeObjectDetector('UpperBody');    
%   bodyDetector.MinSize = [60 60];
%   bodyDetector.MergeThreshold = 10;
%   bodyDetector.UseROI = true;
%   
%   I2 = imread('visionteam.jpg');       
%
%   % Search for objects in the top half of the image.
%   [height, width, ~] = size(I2);
%   roi = [1 1 width height/2];     
%   bboxBody = step(bodyDetector, I2, roi); % Detect upper bodies
%
%   % Annotate detected upper bodies   
%   IBody = insertObjectAnnotation(I2, 'rectangle', ...
%                                  bboxBody, 'Upper Body');
%   figure, imshow(IBody), title('Detected upper bodies');
%
%   See also trainCascadeObjectDetector, vision.PeopleDetector

     
    %   Copyright 2011-2016 The MathWorks, Inc.

    methods
        function out=CascadeObjectDetector
            %CascadeObjectDetector Detect objects using the Viola-Jones algorithm
            %   DETECTOR = vision.CascadeObjectDetector creates a System object
            %   that detects objects using the Viola-Jones algorithm. The DETECTOR
            %   is capable of detecting a variety of objects, including faces and a
            %   person's upper body. The type of object to detect is controlled by
            %   the ClassificationModel property. By default, the DETECTOR is
            %   configured to detect faces.
            %
            %   DETECTOR = vision.CascadeObjectDetector(MODEL) creates a System
            %   object, DETECTOR, configured to detect objects defined by MODEL.
            %   MODEL is a string describing the type of object to detect. There
            %   are several valid MODEL strings. Examples include
            %   'FrontalFaceCART', 'UpperBody', and 'ProfileFace'.
            %
            %   <a href="matlab:helpview(fullfile(docroot,'toolbox','vision','vision.map'),'vision.CascadeObjectDetector.ClassificationModel')">A list of all available models is shown in the documentation.</a>        
            %   
            %   DETECTOR = vision.CascadeObjectDetector(XMLFILE) creates a System 
            %   object, DETECTOR, and configures it to use the custom classification
            %   model specified with the XMLFILE input. XMLFILE can be created using    
            %   the trainCascadeObjectDetector function or OpenCV training 
            %   functionality. You must specify a full or relative path to the 
            %   XMLFILE, if it is not on the MATLAB path.
            %
            %   DETECTOR = vision.CascadeObjectDetector(...,Name,Value) configures
            %   the System object properties, specified as one or more name-value
            %   pair arguments. Unspecified properties have default values.
            %
            %   BBOXES = step(DETECTOR, I) performs multi-scale object detection on
            %   the input image, I, and returns, BBOXES, an M-by-4 matrix defining
            %   M bounding boxes containing the detected objects. Each row in
            %   BBOXES is a four-element vector, [x y width height], that specifies
            %   the upper left corner and size of a bounding box in pixels. When no
            %   objects are detected, BBOXES is empty. I must be a grayscale or
            %   truecolor (RGB) image.
            %
            %   [...] = step(DETECTOR, I, ROI) detects objects within the
            %   rectangular search region specified by ROI. ROI must be a 4-element
            %   vector, [x y width height], that defines a rectangular region of
            %   interest within image I. The 'UseROI' property must be true to use
            %   this syntax.
            %
            %   System objects may be called directly like a function instead of using
            %   the step method. For example, y = step(obj, x) and y = obj(x) are
            %   equivalent.
            %
            %   CascadeObjectDetector methods:
            %
            %   step     - See above description for use of this method
            %   release  - Allow property value and input characteristics changes
            %   clone    - Create cascade object detector object with same property
            %              values
            %   isLocked - Locked status (logical)
            %
            %   CascadeObjectDetector properties:
            %
            %   ClassificationModel   - Name of the classification model
            %   MinSize               - Size of the smallest object to detect
            %   MaxSize               - Size of the biggest object to detect
            %   ScaleFactor           - Scaling for multi-scale object
            %                           detection
            %   MergeThreshold        - Threshold for merging colocated detections
            %   UseROI                - Detect objects within a region of interest
            %
            %   % Example 1:  Face detection
            %   % ----------------------------        
            %   faceDetector = vision.CascadeObjectDetector; % Default: finds faces 
            %
            %   I = imread('visionteam.jpg');
            %   bboxes = step(faceDetector, I); % Detect faces
            %
            %   % Annotate detected faces
            %   IFaces = insertObjectAnnotation(I, 'rectangle', bboxes, 'Face');   
            %   figure, imshow(IFaces), title('Detected faces'); 
            %    
            %   % Example 2: Upper body detection
            %   % --------------------------------------       
            %   bodyDetector = vision.CascadeObjectDetector('UpperBody');    
            %   bodyDetector.MinSize = [60 60];
            %   bodyDetector.MergeThreshold = 10;
            %   bodyDetector.UseROI = true;
            %   
            %   I2 = imread('visionteam.jpg');       
            %
            %   % Search for objects in the top half of the image.
            %   [height, width, ~] = size(I2);
            %   roi = [1 1 width height/2];     
            %   bboxBody = step(bodyDetector, I2, roi); % Detect upper bodies
            %
            %   % Annotate detected upper bodies   
            %   IBody = insertObjectAnnotation(I2, 'rectangle', ...
            %                                  bboxBody, 'Upper Body');
            %   figure, imshow(IBody), title('Detected upper bodies');
            %
            %   See also trainCascadeObjectDetector, vision.PeopleDetector
        end

        function getNumInputsImpl(in) %#ok<MANU>
        end

        function getNumOutputsImpl(in) %#ok<MANU>
        end

        function loadObjectImpl(in) %#ok<MANU>
        end

        function loadXMLFromClassModel(in) %#ok<MANU>
        end

        function releaseImpl(in) %#ok<MANU>
        end

        function saveObjectImpl(in) %#ok<MANU>
        end

        function stepImpl(in) %#ok<MANU>
        end

        function validateInputsImpl(in) %#ok<MANU>
        end

        function validatePropertiesImpl(in) %#ok<MANU>
            % validate that MinSize is greater than or equal to the minimum
            % object size used to train the classification model
        end

    end
    methods (Abstract)
    end
    properties
        %ClassificationModel A trained cascade classification model
        %   Specify the name of the model as a string. The value specified
        %   for this property may be one of the valid MODEL strings listed 
        %   <a href="matlab:helpview(fullfile(docroot,'toolbox','vision','vision.map'),'vision.CascadeObjectDetector.ClassificationModel')">here</a> or an OpenCV XML file containing custom classification
        %   model data. When an XML file is specified, a full or relative
        %   path is required if the file is not on the MATLAB path.
        %        
        %   Default: 'FrontalFaceCART'           
        %
        %   See also <a href="matlab:helpview(fullfile(docroot,'toolbox','vision','vision.map'),'vision.CascadeObjectDetector.ClassificationModel')">Available models</a>
        ClassificationModel;

        %MaxSize Size of the biggest object to detect
        %   Specify the size of the biggest object to detect, in pixels, as
        %   a two-element vector, [height width]. Use this property to
        %   reduce computation time when the maximum object size is known
        %   prior to processing the image. When this property is not
        %   specified, the maximum detectable object size is SIZE(I). When
        %   'UseROI' is true, the maximum detectable object size is the
        %   defined by the height and width of the ROI. This property is
        %   tunable.
        %
        %   Default: []
        MaxSize;

        %MergeThreshold Threshold for merging colocated detections
        %   Specify a threshold value as a scalar integer. This property
        %   defines the minimum number of colocated detections needed to
        %   declare a final detection. Groups of colocated detections that
        %   meet the threshold are merged to produce one bounding box
        %   around the target object. Increasing this threshold can help
        %   suppress false detections by requiring that the target object
        %   be detected multiple times during the multi-resolution
        %   detection phase. By setting this property to 0, all detections
        %   are returned without merging. This property is tunable.
        %
        %   Default: 4
        MergeThreshold;

        %MinSize Size of the smallest object to detect
        %   Specify the size of the smallest object to detect, in pixels,
        %   as a two-element vector, [height width]. Use this property to
        %   reduce computation time when the minimum object size is known
        %   prior to processing the image. When this property is not
        %   specified, the minimum detectable object size is the image size
        %   used to train the classification model. This property is
        %   tunable.
        %
        %   Default: []              
        MinSize;

        %ScaleFactor Scaling for multi-scale object detection
        %   Specify the factor used to incrementally scale the detection
        %   scale between MinSize and MaxSize. The ScaleFactor must be
        %   greater than or equal to 1.0001. At each increment, N, the
        %   detection scale is
        %
        %     round(TrainingSize*(ScaleFactor^N))
        %
        %   where TrainingSize is the image size used to train the
        %   classification model. The training size used for each
        %   classification model is shown <a href="matlab:helpview(fullfile(docroot,'toolbox','vision','vision.map'),'vision.CascadeObjectDetector.ClassificationModel')">here</a>. This property is tunable.
        %
        %   Default: 1.1
        ScaleFactor;

        % UseROI Detect objects within a ROI
        %    Set to true to detect objects within a rectangular region of
        %    interest within I.
        %
        % Default: false
        UseROI;

    end
end
