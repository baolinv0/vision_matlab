% Computer Vision System Toolbox
% Version 8.0 (R2017b) 24-Jul-2017
%
% Video Display
%   vision.DeployableVideoPlayer  - Display video (Windows and Linux)
%   vision.VideoPlayer            - Play video or display image
%   implay                        - View video from files, the MATLAB workspace, or Simulink signals
%
% Video File I/O
%   vision.VideoFileReader        - Read video frames and audio samples from video file
%   vision.VideoFileWriter        - Write video frames and audio samples to video file
%   vision.BinaryFileReader       - Read binary video data from files
%   vision.BinaryFileWriter       - Write binary video data to files
%
% Feature Detection, Extraction and Matching
%   detectHarrisFeatures          - Find corners using the Harris-Stephens algorithm
%   detectMinEigenFeatures        - Find corners using the minimum eigenvalue algorithm
%   detectFASTFeatures            - Find corners using the FAST algorithm
%   detectSURFFeatures            - Find SURF features
%   detectKAZEFeatures            - Find KAZE features
%   detectMSERFeatures            - Find MSER features
%   detectBRISKFeatures           - Find BRISK features
%   extractFeatures               - Extract feature vectors from image
%   extractHOGFeatures            - Extract HOG features
%   extractLBPFeatures            - Extract LBP features
%   matchFeatures                 - Find matching features
%   showMatchedFeatures           - Display corresponding feature points
%   cornerPoints                  - Object for storing corner points
%   SURFPoints                    - Object for storing SURF interest points
%   KAZEPoints                    - object for storing KAZE interest points
%   MSERRegions                   - Object for storing MSER regions
%   BRISKPoints                   - Object for storing BRISK interest points
%   binaryFeatures                - Object for storing binary feature vectors
%
% Object Detection and Recognition
%   ocr                                 - Recognize text using Optical Character Recognition
%   ocrText                             - Object for storing OCR results
%   ocrTrainer                          - OCR training app
%   vision.CascadeObjectDetector        - Detect objects using the Viola-Jones algorithm
%   vision.PeopleDetector               - Detect upright people using HOG features
%   peopleDetectorACF                   - Detect upright people using ACF features
%   acfObjectDetector                   - Detect objects using ACF features
%   rcnnObjectDetector                  - Detect objects using R-CNN deep learning detector
%   fastRCNNObjectDetector              - Detect objects using Fast R-CNN deep learning detector
%   fasterRCNNObjectDetector            - Detect objects using Faster R-CNN deep learning detector
%   trainCascadeObjectDetector          - Train a model for a cascade object detector
%   trainACFObjectDetector              - Train a model for an ACF object detector
%   trainRCNNObjectDetector             - Train an R-CNN deep learning object detector
%   trainFastRCNNObjectDetector         - Train a Fast R-CNN deep learning object detector
%   trainFasterRCNNObjectDetector       - Train a Faster R-CNN deep learning object detector
%   evaluateDetectionPrecision          - Evaluate the precision metric for object detection
%   evaluateDetectionMissRate           - Evaluate the miss rate metric for object detection
%   selectStrongestBbox                 - Select strongest bounding boxes from overlapping clusters
%   bagOfFeatures                       - Create bag of visual features
%   trainImageCategoryClassifier        - Train bag of features based image category classifier
%   imageCategoryClassifier             - Predict image category
%   indexImages                         - Create an index for image search
%   retrieveImages                      - Search for similar images
%   invertedImageIndex                  - Search index that maps visual words to images
%   evaluateImageRetrieval              - Evaluate image search results 
%
% Semantic Segmentation
%   semanticseg                         - Semantic image segmentation using deep learning
%   evaluateSemanticSegmentation        - Evaluate semantic segmentation data set against ground truth
%   segnetLayers                        - Create SegNet for semantic segmentation using deep learning
%   fcnLayers                           - Create Fully Convolutional Network (FCN) for semantic segmentation
%   labeloverlay                        - Overlay semantic segmentation results on an image
%   pixelLabelImageSource               - Data source for semantic segmentation networks
%   pixelLabelDatastore                 - Create a PixelLabelDatastore to work with collections of pixel label data
%   pixelClassificationLayer            - Pixel classification layer for semantic segmentation
%   crop2dLayer                         - 2-D crop layer
%
% Ground Truth Labeling
%   imageLabeler                        - App for labeling ground truth data in a collection of images
%   groundTruth                         - Object for storing ground truth labels
%   groundTruthDataSource               - Create ground truth data source
%   labelType                           - Enumeration of ground truth label types
%   vision.labeler.AutomationAlgorithm  - Interface for automated labeling
%   objectDetectorTrainingData          - Create training data for an object detector from groundTruth
%
% Motion Analysis and Tracking
%   assignDetectionsToTracks      - Assign detections to tracks for multi-object tracking
%   vision.BlockMatcher           - Estimate motion between images or video frames
%   vision.ForegroundDetector     - Detect foreground using Gaussian Mixture Models
%   vision.HistogramBasedTracker  - Track object in video based on histogram
%   configureKalmanFilter         - Create a Kalman filter for object tracking
%   vision.KalmanFilter           - Kalman filter
%   opticalFlow                   - Object for storing optical flow
%   opticalFlowFarneback          - Estimate object velocities using Farneback algorithm
%   opticalFlowHS                 - Estimate object velocities using Horn-Schunck algorithm
%   opticalFlowLK                 - Estimate object velocities using Lucas-Kanade algorithm
%   opticalFlowLKDoG              - Estimate object velocities using modified Lucas-Kanade algorithm
%   vision.PointTracker           - Track points in video using Kanade-Lucas-Tomasi (KLT) algorithm
%   vision.TemplateMatcher        - Locate template in image
%
% Camera Calibration
%   cameraCalibrator              - Single camera calibration app
%   stereoCameraCalibrator        - Stereo camera calibration app
%   estimateCameraParameters      - Calibrate a single camera or a stereo camera
%   estimateFisheyeParameters     - Calibrate a fisheye camera
%   detectCheckerboardPoints      - Detect a checkerboard pattern in an image
%   generateCheckerboardPoints    - Generate checkerboard point locations
%   showExtrinsics                - Visualize extrinsic camera parameters
%   showReprojectionErrors        - Visualize calibration errors
%   cameraParameters              - Object for storing camera parameters
%   stereoParameters              - Object for storing parameters of a stereo camera system
%   fisheyeParameters             - Object for storing fisheye camera parameters
%   cameraIntrinsics              - Object for storing intrinsic camera parameters
%   fisheyeIntrinsics             - Object for storing intrinsic fisheye camera parameters
%   cameraCalibrationErrors       - Object for storing standard errors of estimated camera parameters
%   stereoCalibrationErrors       - Object for storing standard errors of estimated stereo parameters    
%   fisheyeCalibrationErrors      - Object for storing standard errors of estimated fisheye camera parameters
%   undistortImage                - Correct image for lens distortion
%   undistortPoints               - Correct point coordinates for lens distortion
%   undistortFisheyeImage         - Correct fisheye image for lens distortion
%   undistortFisheyePoints        - Correct point coordinates for fisheye lens distortion
%
% Stereo Vision
%   disparity                         - Compute disparity map
%   epipolarLine                      - Compute epipolar lines for stereo images
%   estimateUncalibratedRectification - Uncalibrated stereo rectification
%   isEpipoleInImage                  - Determine whether the epipole is inside the image
%   lineToBorderPoints                - Compute the intersection points of lines and image border
%   reconstructScene                  - Reconstructs a 3-D scene from a disparity map
%   rectifyStereoImages               - Rectifies a pair of stereo images
%   stereoAnaglyph                    - Create a red-cyan anaglyph from a stereo pair of images
%
% Multiple View Geometry
%   bundleAdjustment             - Refine camera poses and 3-D points
%   cameraMatrix                 - Compute camera projection matrix
%   cameraPoseToExtrinsics       - Convert camera pose to extrinsics
%   estimateEssentialMatrix      - Estimate the essential matrix
%   estimateFundamentalMatrix    - Estimate the fundamental matrix
%   estimateWorldCameraPose      - Estimate camera pose from 3-D to 2-D point correspondences
%   extrinsics                   - Compute location of a calibrated camera
%   extrinsicsToCameraPose       - Convert extrinsics into camera pose
%   plotCamera                   - Plot a camera in 3-D coordinates
%   pointTrack                   - Object for storing matching points from multiple views
%   relativeCameraPose           - Compute relative up-to-scale pose of calibrated camera
%   rotationMatrixToVector       - Convert a 3-D rotation matrix into a rotation vector
%   rotationVectorToMatrix       - Convert a 3-D rotation vector into a rotation matrix
%   triangulate                  - Find 3-D locations of matching points between pairs of images
%   triangulateMultiview         - Triangulate 3-D locations of points matched across multiple views
%   viewSet                      - Object for managing data for structure-from-motion and visual odometry
%
% Point Cloud Processing
%   pointCloud                        - Object for storing a 3-D point cloud
%   pcdenoise                         - Remove noise from a 3-D point cloud
%   pcdownsample                      - Downsample a 3-D point cloud
%   pcnormals                         - Estimate normal vectors for a point cloud
%   pcmerge                           - Merge two 3-D point clouds
%   pcregrigid                        - Register two point clouds with ICP algorithm
%   pctransform                       - Rigid transform a 3-D point cloud
%   pcfitplane                        - Fit plane to a 3-D point cloud
%   pcfitsphere                       - Fit sphere to a 3-D point cloud
%   pcfitcylinder                     - Fit cylinder to a 3-D point cloud
%   pcshow                            - Plot 3-D point cloud
%   pcshowpair                        - Visualize differences between point clouds
%   pcplayer                          - Player for visualizing streaming 3-D point cloud data
%   pcread                            - Read a 3-D point cloud from PLY file
%   pcwrite                           - Write a 3-D point cloud to PLY file
%   pcfromkinect                      - Get point cloud from Kinect for Windows
%   planeModel                        - Object for storing a parametric plane model
%   sphereModel                       - Object for storing a parametric sphere model
%   cylinderModel                     - Object for storing a parametric cylinder model
%
% Enhancement
%   vision.Deinterlacer           - Remove motion artifacts by deinterlacing input video signal
%
% Conversions
%   vision.ChromaResampler        - Downsample or upsample chrominance components of images
%   vision.DemosaicInterpolator   - Bayer-pattern image conversion to true color
%   vision.GammaCorrector         - Gamma correction
%
% Filtering
%   isfilterseparable             - Check filter separability
%   integralImage                 - Compute integral image
%   integralFilter                - Filter using integral image
%   integralKernel                - Define filter for use with integral images
%   vision.Convolver              - 2-D convolution
%
% Geometric Transformations
%   estimateGeometricTransform         - Estimate geometric transformation from matching point pairs
%   vision.GeometricShearer            - Shift rows or columns of image by linearly varying offset
%
% Statistics
%   vision.Autocorrelator       - 2-D autocorrelation
%   vision.BlobAnalysis         - Properties of connected regions
%   vision.Crosscorrelator      - 2-D cross-correlation
%   vision.LocalMaximaFinder    - Local maxima
%   vision.Maximum              - Maximum values
%   vision.Mean                 - Mean value
%   vision.Median               - Median values
%   vision.Minimum              - Minimum values
%   vision.StandardDeviation    - Standard deviation
%   vision.Variance             - Variance
%
% Text and Graphics
%   insertObjectAnnotation      - Insert annotation in image or video stream
%   insertMarker                - Insert markers in image or video stream
%   insertShape                 - Insert shapes in image or video stream
%   insertText                  - Insert text in image or video stream
%   listTrueTypeFonts           - List available TrueType fonts
%   vision.AlphaBlender         - Combine images, overlay images, or highlight selected pixels
%
% Transforms
%   vision.DCT                  - 2-D discrete cosine transform
%   vision.FFT                  - 2-D fast Fourier transform
%   vision.IDCT                 - 2-D inverse discrete cosine transform
%   vision.IFFT                 - 2-D inverse fast Fourier transform
%   vision.Pyramid              - Gaussian pyramid decomposition
%
% Utilities
%   bbox2points                 - Convert a rectangle into a list of points
%   bboxOverlapRatio            - Compute bounding box overlap ratio
%   visionSupportPackages       - Launches the support package installer
%
% Examples
%   visiondemos                 - Index of Computer Vision System Toolbox examples
%
% Simulink functionality
%   <a href="matlab:visionlib">visionlib</a>                   - Open Computer Vision System Toolbox Simulink library
%
% See also images/Contents
