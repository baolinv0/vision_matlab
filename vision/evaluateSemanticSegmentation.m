function metrics = evaluateSemanticSegmentation(varargin)
%evaluateSemanticSegmentation Evaluate semantic segmentation data set against ground truth
%
%   metrics = evaluateSemanticSegmentation(pxdsResults,pxdsTruth) computes
%   various metrics to evaluate the quality of the semantic segmentation
%   results.
%
%   pxdsResults and pxdsTruth can be pixelLabelDatastore objects or cell
%   arrays of pixelLabelDatastore objects, which encapsulate label image
%   files on disk. pxdsResults represents the results of semantic
%   segmentation and holds the predicted pixel labels. pxdsTruth represents
%   the ground truth semantic segmentation and holds the true pixel labels.
%
%   metrics is a semanticSegmentationMetrics object with the following
%   properties:
%
%    * metrics.ConfusionMatrix is the confusion matrix for the classes in
%      the data set. It is a square table where element (i,j) is the count
%      of pixels known to belong to class i but predicted to belong to
%      class j.
%
%    * metrics.NormalizedConfusionMatrix is the confusion matrix normalized
%      by the number of pixels known to belong to each class. Element (i,j)
%      represents the fraction, in [0,1], of pixels known to belong to
%      class i but predicted to belong to class j.
%
%    * metrics.DataSetMetrics is a 1-by-5 table presenting the following
%      metrics computed over the data set:
%
%       - GlobalAccuracy: Fraction of correctly classified pixels
%                         regardless of class.
%       - MeanAccuracy:   Fraction of correctly classified pixels
%                         averaged over the classes.
%       - MeanIoU:        Intersection over union (IoU) coefficient
%                         averaged over the classes. The IoU is also
%                         known as the Jaccard index.
%       - WeightedIoU:    IoU average weighted by the number of pixels
%                         (cardinal) in each class.
%       - MeanBFScore:    Mean over all the images of the mean BF score
%                         for each image. The BF score is a contour
%                         matching metric based on the F1-measure. It
%                         assesses how well predicted boundaries of objects
%                         match ground truth boundaries.
%
%    * metrics.ClassMetrics is a C-by-3 table, where C is the number of
%      classes, presenting the following metrics computed for each class:
%
%       - Accuracy:    Fraction of correctly classified pixels
%                      in each class.
%       - IoU:         Intersection over union (IoU) coefficient for each
%                      class.
%       - MeanBFScore: Average over all the images of the BF score
%                      for each class.
%
%    * metrics.ImageMetrics is a F-by-5 table, where F is the number of
%      images in the data set, listing the same metrics as in
%      metrics.DataSetMetrics but computed for each image individually.
%      If pxdsResults and pxdsTruth are cell arrays of pixelLabelDatastore
%      objects, then metrics.ImageMetrics is a cell array of tables.
%
%   metrics = evaluateSemanticSegmentation(___,Name,Value,...) computes
%   semantic segmentation metrics using name-value pairs to control the
%   evaluation. Parameters include:
%
%      "Metrics"  -  Metric or list of metrics to compute, specified as
%                    a vector of strings. This parameter changes which
%                    variables in the DataSetMetrics, ClassMetrics, and
%                    ImageMetrics tables are computed. ConfusionMatrix and
%                    NormalizedConfusionMatrix are computed no matter what
%                    the value of this parameter is. Valid values are:
%                    "accuracy", "all", "bfscore", "global-accuracy",
%                    "iou", and "weighted-iou".
%
%                    Default: "all"
%
%      "Verbose"  -  Set true to display progress information.
%
%                    Default: true
%
%   Notes
%   -----
%   - Control which metrics are computed using the "Metrics" parameter.
%     evaluateSemanticSegmentation always computes the classification
%     matrix.
%
%   - evaluateSemanticSegmentation supports parallel computing using
%     multiple MATLAB workers. Enable parallel computing using the 
%     <a href="matlab:preferences('Computer Vision System Toolbox')">preferences dialog</a>.
%
%   - If pxdsResults and pxdsTruth are cell arrays of pixelLabelDatastore
%     objects, then metrics.ImageMetrics is a cell array of tables listing
%     the metrics for each image with each table corresponding to a
%     distinct pixelLabelDatastore object.
%
%   Reference
%   ---------
%   - Csurka, Gabriela, et al. "What is a good evaluation measure for
%     semantic segmentation?." BMVC. Vol. 27. 2013.
%
%   Example: Evaluate the results of semantic segmentation
%   ------------------------------------------------------
%
%     % The triangleImages data set has 100 test images with
%     % ground truth labels. Define the location of the data set.
%     dataSetDir = fullfile(toolboxdir('vision'),'visiondata','triangleImages');
%
%     % Define the location of the test images.
%     testImagesDir = fullfile(dataSetDir,'testImages');
%
%     % Define the location of the ground truth labels.
%     testLabelsDir = fullfile(dataSetDir,'testLabels');
%
%     % Create an imageDatastore holding the test images.
%     imds = imageDatastore(testImagesDir);
%
%     % Define the class names and their associated label IDs.
%     classNames = ["triangle", "background"];
%     labelIDs   = [255 0];
%
%     % Create a pixelLabelDatastore holding the
%     % ground truth pixel labels for the test images.
%     pxdsTruth = pixelLabelDatastore(testLabelsDir, classNames, labelIDs);
%
%     % Load a semantic segmentation network that has 
%     % been trained on the training images of noisyShapes.
%     net = load('triangleSegmentationNetwork');
%     net = net.net;
%
%     % Run the network on the test images. Predicted labels are written to
%     % disk in a temporary directory and returned as a pixelLabelDatastore.
%     pxdsResults = semanticseg(imds, net, "WriteLocation", tempdir);
%
%     % Evaluate the prediction results against the ground truth.
%     metrics = evaluateSemanticSegmentation(pxdsResults, pxdsTruth);
%
%     % Display the classification accuracy, the intersection
%     % over union, and the boundary F-1 score for each class.
%     metrics.ClassMetrics
%
%   See also BFSCORE, JACCARD, pixelLabelDatastore, semanticSegmentationMetrics.

%   Copyright 2017 The MathWorks, Inc.

metrics = semanticSegmentationMetrics.compute(varargin{:});
