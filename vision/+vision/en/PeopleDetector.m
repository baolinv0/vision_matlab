classdef PeopleDetector< matlab.System
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

    methods
        function out=PeopleDetector
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
        end

        function getNumInputsImpl(in) %#ok<MANU>
        end

        function getNumOutputsImpl(in) %#ok<MANU>
        end

        function loadObjectImpl(in) %#ok<MANU>
        end

        function releaseImpl(in) %#ok<MANU>
        end

        function saveObjectImpl(in) %#ok<MANU>
        end

        function setupModel(in) %#ok<MANU>
            % setup the HOG people detector 
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
        ClassificationModel;

        %ClassificationThreshold People classification threshold
        %   Specify a threshold value as a non-negative scalar. Use this
        %   threshold to control the classification of individual image
        %   sub-regions as person or non-person during multi-scale object
        %   detection. Increase this threshold in situations where many
        %   false detections occur. This property is tunable. Typical
        %   values range from 0 to 4.
        %
        %   Default: 1
        ClassificationThreshold;

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
        MaxSize;

        %MergeDetections Control whether similar detections are merged
        %   Specify a logical scalar to control whether similar detections
        %   are merged using a mean shift based algorithm. Set this
        %   property to false to output unprocessed bounding boxes and
        %   detection scores. This is useful if you want to perform a
        %   custom merge operation.
        %
        %   Default: true
        MergeDetections;

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
        MinSize;

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
        ScaleFactor;

        % UseROI Detect objects within a ROI
        %    Set to true to detect objects within a rectangular region of
        %    interest within I.
        %
        % Default: false
        UseROI;

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
        WindowStride;

    end
end
