function [logAverageMissRate, fppi, missRate] = evaluateDetectionMissRate(...
                                    detectionResults, trainingData, varargin)
%evaluateDetectionMissRate Evaluate the miss rate metric for object detection.
%   logAverageMissRate = evaluateDetectionMissRate(detectionResults,
%   trainingData) returns log-average miss rate to measure the detection
%   performance. For a multi-class detector, logAverageMissRate is a vector
%   of log-average miss rates for each object class. The class order
%   follows the same column order as the trainingData table.
% 
%   Inputs:
%   -------
%   detectionResults  - a table that has two columns for single-class
%                       detector, or three columns for multi-class
%                       detector. The first column contains M-by-4 matrices
%                       of [x, y, width, height] bounding boxes specifying
%                       object locations. The second column contains scores
%                       for each detection. For multi-class detector, the
%                       third column contains the predicted label for each
%                       detection. The label must be categorical type
%                       defined by the variable names of trainingData table.
%
%   trainingData      - a table that has one column for single-class, or
%                       multiple columns for multi-class. Each column
%                       contains M-by-4 matrices of [x, y, width, height]
%                       bounding boxes specifying object locations. The
%                       column name specifies the class label.
%  
%   [..., fppi, missRate] = evaluateDetectionMissRate(...) returns data
%   points for plotting the log-miss-rate/false-positives-per-image(FPPI)
%   curve. You can visualize the performance curve using loglog(fppi,missRate). 
%   For multi-class detector, recall and precision are cell arrays, where
%   each cell contains the data points for each object class.
%
%   [...] = evaluateDetectionMissRate(..., threshold) specifies the
%   overlap threshold for assigning a detection to a ground truth box. The
%   overlap ratio is computed as the intersection over union. The default
%   value is 0.5.
%
%   Example : Evaluate stop sign detector
%   -------------------------------------
%   % Load the ground truth table
%   load('stopSignsAndCars.mat')
%   stopSigns = stopSignsAndCars(:, 1:2);
%   stopSigns.imageFilename = fullfile(toolboxdir('vision'),'visiondata', ...
%       stopSigns.imageFilename);
%
%   % Train an ACF based detector
%   detector = trainACFObjectDetector(stopSigns,'NegativeSamplesFactor',2);
%
%   % Create a struct array to store the results
%   numImages = height(stopSigns);
%   results(numImages) = struct('Boxes', [], 'Scores', []);
%
%   % Run the detector on the training images
%   for i = 1 : numImages
%       I = imread(stopSigns.imageFilename{i});
%       [bboxes, scores] = detect(detector, I);
%       results(i).Boxes = bboxes;
%       results(i).Scores = scores;
%   end
%
%   results = struct2table(results);
%
%   % Evaluate the results against the ground truth data
%   [am, fppi, missRate] = evaluateDetectionMissRate(results, stopSigns(:, 2));
%
%   % Plot log-miss-rate/FPPI curve
%   figure
%   loglog(fppi, missRate);
%   grid on
%   title(sprintf('log Average Miss Rate = %.1f', am))
%
% See also evaluateDetectionPrecision, acfObjectDetector,
%          rcnnObjectDetector, trainACFObjectDetector, trainRCNNObjectDetector.

% Copyright 2016 The MathWorks, Inc.
%
% References
% ----------
%   [1] C. D. Manning, P. Raghavan, and H. Schutze. An Introduction to
%   Information Retrieval. Cambridge University Press, 2008.
%
%   [2] D. Hoiem, Y. Chodpathumwan, and Q. Dai. Diagnosing error in
%   object detectors. In Proc. ECCV, 2012.
%
%   [3] Dollar, Piotr, et al. "Pedestrian Detection: An Evaluation of the
%   State of the Art." Pattern Analysis and Machine Intelligence, IEEE
%   Transactions on 34.4 (2012): 743 - 761.

narginchk(2, 3);

% Validate user inputs
vision.internal.detector.evaluationInputValidation(detectionResults, ...
    trainingData, mfilename, varargin{:});

% Hit/miss threshold for IOU (intersection over union) metric
threshold = 0.5;
if ~isempty(varargin)
    threshold = varargin{1};
end

% Match the detection results with ground truth
s = vision.internal.detector.evaluateDetection(detectionResults, trainingData, threshold);

numImages  = height(trainingData);
numClasses = width(trainingData);
logAverageMissRate = zeros(numClasses, 1);
missRate           = cell(numClasses, 1);
fppi               = cell(numClasses, 1);
    
% Compute the miss rate and fppi for each class
for c = 1 : numClasses
    
    labels = vertcat(s(:,c).labels);
    scores = vertcat(s(:,c).scores);
    numExpected = sum([s(:,c).NumExpected]);

    [amr, m, f] = vision.internal.detector.detectorMissRateFalsePositivesPerImage(...
        labels, scores, numExpected, numImages);  
    
    logAverageMissRate(c) = amr;
    missRate{c}           = m;
    fppi{c}               = f;
end

if numClasses == 1
    missRate = missRate{1};
    fppi    = fppi{1};
end