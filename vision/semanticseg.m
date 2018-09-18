%semanticseg Semantic image segmentation using deep learning.
%   C = semanticseg(I, network) returns a semantic segmentation of the
%   input image using deep learning. The input network is a SeriesNetwork
%   or DAGNetwork object. The output is a categorical array, C, where
%   C(i,j) is the categorical label assigned to pixel I(i,j). The input
%   image can be an image or a 4D array of images, where the first three
%   dimensions index the height, width, and channels of an image, and the
%   fourth dimension indexes the individual images.
%
%   [C, score, allScores] = semanticseg(I, network) additionally returns
%   the classification scores for each categorical label in C. The
%   classification score of pixel I(i,j) is score(i,j). The third optional
%   output, allScores, contains the scores for all label categories the
%   input network is capable of classifying. allScores is a 4D array, where
%   the first three dimensions represent the height, width, and number of
%   categories in C. The fourth dimension index each individual image.
%
%   [...] = semanticseg(I, network, roi) returns the semantic segmentation
%   within a rectangular sub-region of I. roi must be a 4-element vector,
%   [x, y, width, height], that defines a rectangular region of interest
%   fully contained in I. Image pixels outside the rectangular region
%   of interest are have <undefined> categorical labels. If I is a 4D array
%   of images, the same roi is applied to all images.
%
%   pxds = semanticseg(imds, network) returns the semantic segmentation
%   results for a collection of images in imds, an imageDatastore object.
%   The output is a pixelLabelDatastore, pxds, representing the semantic
%   segmentation results for all images in imds. The result for each image
%   is saved as separate uint8 label matrices as PNG images. Use read(pxds)
%   to return the categorical labels assigned to images in imds.
%
%   pxds = semanticseg(..., 'Name', 'Value') specifies additional
%   name-value pair arguments described below:
%
%   'OutputType'             The type used to return the segmentation
%                            results. Valid types are 'categorical' or
%                            'double'. When the output type is 'double',
%                            the segmentation results are represented as a
%                            label matrix where the label IDs are integer
%                            values corresponding to the class names
%                            defined in the pixelClassificationLayer used
%                            in the input network. This name-value pair
%                            does not apply when the input is an
%                            imageDatastore.
%
%                            Default: 'categorical'
%
%   'MiniBatchSize'          The mini-batch size used for processing a
%                            large collection of images. Images are grouped
%                            into mini-batches and processed as a batch to
%                            improve computational efficiency. Larger
%                            mini-batch sizes lead to faster processing, at
%                            the cost of more memory.
%
%                            Default: 128
%
%   'ExecutionEnvironment'   The hardware resources used to process images
%                            with a network. Valid values are:
%
%                               'auto' - Use a GPU if it is available,
%                                        otherwise use the CPU.
%
%                               'gpu'  - Use the GPU. To use a GPU, you
%                                        must have Parallel Computing
%                                        Toolbox(TM), and a CUDA-enabled
%                                        NVIDIA GPU with compute capability
%                                        3.0 or higher. If a suitable GPU
%                                        is not available, an error message
%                                        is issued.
%
%                               'cpu   - Use the CPU.
%
%   The following name-value pair arguments control the writing of image
%   files. These are arguments apply only when processing images in an
%   imageDatastore.
%
%   'WriteLocation'     A scalar string or character vector to specify a
%                       folder location to which extracted image files are
%                       written. The specified folder must exist and have
%                       write permissions.
%
%                       Default: pwd (current working directory)
%
%   'NamePrefix'        A scalar string or character vector to specify the
%                       prefix applied to output image file names. The
%                       image files are named <prefix>_<N>.png, where N is
%                       the index of the corresponding input image file,
%                       imds.Files(N).
%
%                       Default: 'pixelLabel'
%
%   'Verbose'           Set true to display progress information.
%
%                       Default: true
%
% Class Support
% -------------
% The input image I is of type uint8, uint16, single double, logical, or
% int16.
%
% Notes
% -----
% semanticseg supports parallel computing using multiple MATLAB workers
% when processing an imageDatastore. Enable parallel computing using the
% <a href="matlab:preferences('Computer Vision System Toolbox')">preferences dialog</a>.
%
% Example 1 - Semantic image segmentation.
% ----------------------------------------
% % Load pretrained network.
% data = load('triangleSegmentationNetwork');
% net = data.net
%
% % List the network layers.
% net.Layers
%
% % Read and display test image.
% I = imread('triangleTest.jpg');
% figure
% imshow(I)
%
% % Perform semantic image segmentation.
% [C, scores] = semanticseg(I, net);
%
% % Overlay segmentation results on image and display results.
% B = labeloverlay(I, C);
% figure
% imshow(B)
%
% % Display classification scores.
% figure
% imagesc(scores)
% axis square
% colorbar
%
% % Create a binary mask of just the triangles.
% BW = C == 'triangle';
%
% figure
% imshow(BW)
%
% Example 2 - Evaluate test set.
% ------------------------------
% % Load pretrained network.
% data = load('triangleSegmentationNetwork');
% net = data.net;
%
% % Load test images using imageDatastore.
% dataDir = fullfile(toolboxdir('vision'), 'visiondata', 'triangleImages');
% testImageDir = fullfile(dataDir, 'testImages');
% imds = imageDatastore(testImageDir)
%
% % Load ground truth test labels.
% testLabelDir = fullfile(dataDir, 'testLabels');
% classNames = ["triangle" "background"];
% pixelLabelID = [255 0];
% pxdsTruth = pixelLabelDatastore(testLabelDir, classNames, pixelLabelID);
%
% % Run semantic segmentation on all test images.
% pxdsResults = semanticseg(imds, net, 'WriteLocation', tempdir);
%
% % Compare results against ground truth.
% metrics = evaluateSemanticSegmentation(pxdsResults, pxdsTruth)
%
% See also labeloverlay, evaluateSemanticSegmentation, imageLabeler,
%          trainNetwork, imageDatastore, pixelLabelDatastore,
%          pixelClassificationLayer.

% Copyright 2017 Mathworks, Inc.
function [C, scores, allScores] = semanticseg(I, net, varargin)
narginchk(2, inf);
params = iParseInputs(I, net, varargin{:});

if isa(I, 'matlab.io.datastore.ImageDatastore')
    nargoutchk(1,1);
    
    % Make a copy of the data store to prevent altering the state of the
    % input datastore.
    imds = copy(I);
    imds.reset();
    imds.ReadSize = params.MiniBatchSize;
    
    if params.UseParallel
        filenames = iProcessImageDatastoreInParallel(imds, net, params);
    else
        filenames = iProcessImageDatastoreSerially(imds, net, params);
    end
    
    % Create output pixelLabelDatastore
    classnames = net.Layers(end).ClassNames;
    values = 1:numel(classnames);
    C = pixelLabelDatastore(filenames, classnames, values);
    
else % process single image.
    
    nargoutchk(1,3);
    
    roi    = params.ROI;
    useROI = params.UseROI;
    
    Iroi = vision.internal.detector.cropImageIfRequested(I, roi, useROI);
    
    % Convert image from RGB <-> grayscale as required by network.
    Iroi = iConvertImageToMatchNumberOfNetworkImageChannels(...
        Iroi, params.NetImageSize);
    
    if ~isa(Iroi,'uint8')
        % convert data to single if not uint8. Network processes data in
        % single. casting to single preserves user data ranges.
        Iroi = single(Iroi);
    end
    
    [Lroi, scores, allScores] = iClassifyImagePixels(Iroi, net, params);
    
    % remove singleton 3rd dim
    Lroi = squeeze(Lroi);
    scores = squeeze(scores);
    
    outputCategorical = strcmpi(params.OutputType,'categorical');
    [H, W, ~, N] = size(I);
    
    if outputCategorical
        % Convert label matrix to categorical
        classnames = net.Layers(params.PixelLayerID).ClassNames;
        classnames = categorical(1:numel(classnames), 1:numel(classnames), classnames);
        Croi = classnames(Lroi);
        
        % Replace NaN maxima with <undefined> labels
        nans = isnan(scores);
        if any(nans(:))
            Croi(nans) = categorical(NaN);
        end
        
        if useROI
            % copy data into ROI region. Treat region outside of ROI as
            % <undefined>. <undefined> scores are NaN.
            C = categorical(NaN, 1:numel(classnames), net.Layers(params.PixelLayerID).ClassNames);
            
            C = repelem(C,H,W,N);
            [c1,c2,r1,r2] = cropRanges(roi);
            C(r1:r2,c1:c2,:) = Croi;
            
        else
            C = Croi;
        end
    else        
        if useROI
            % copy data into ROI region. Treat region outside of ROI as
            % undefined with label ID zero.
            C = zeros(H,W,N,'like',Lroi);
            
            [c1,c2,r1,r2] = cropRanges(roi);
            C(r1:r2,c1:c2,:) = Lroi;
        else
            C = Lroi;
        end
        
    end
    
    if useROI
        if nargout >= 2
            s = NaN(H, W, N, class(scores));
            s(r1:r2,c1:c2,:) = scores;
            scores    = s;
        end
        
        if nargout == 3
            K  = numel(net.Layers(params.PixelLayerID).ClassNames);
            as = NaN(H, W, K, N, class(scores));
            as(r1:r2,c1:c2,:,:) = allScores;
            allScores = as;
        end
        
    end
end

%--------------------------------------------------------------------------
function [c1,c2,r1,r2] = cropRanges(roi)
c1 = roi(1);
c2 = c1 + roi(3) - 1;
r1 = roi(2);
r2 = roi(2) + roi(4) - 1;

%--------------------------------------------------------------------------
function params = iParseInputs(I, net, varargin)

iCheckNetwork(net);

netSize = iNetworkImageSize(net);
iCheckImage(I, netSize);

isDatastore = isa(I, 'matlab.io.datastore.ImageDatastore');

pxLayerID = iFindAndAssertNetworkHasOnePixelClassificationLayer(net);

p = inputParser;
p.addOptional('roi', zeros(0,4));

p.addParameter('OutputType', 'categorical');

p.addParameter('MiniBatchSize', 128, ...
    @(x)vision.internal.cnn.validation.checkMiniBatchSize(x,mfilename));

p.addParameter('ExecutionEnvironment', 'auto');

p.addParameter('WriteLocation', pwd);

p.addParameter('NamePrefix', 'pixelLabel', @iCheckNamePrefix);

p.addParameter('Verbose', true, ...
    @(x)vision.internal.inputValidation.validateLogical(x,'Verbose'))

if isDatastore
    useParallelDefault = vision.internal.useParallelPreference();
else
    useParallelDefault = false;
end
p.addParameter('UseParallel', useParallelDefault, ...
    @(x)vision.internal.inputValidation.validateLogical(x,'UseParallel'));

p.parse(varargin{:});

userInput = p.Results;

useROI = ~ismember('roi', p.UsingDefaults);

if useROI
    if isDatastore
        error(message('vision:semanticseg:imdsROIInvalid'));
    end
    vision.internal.detector.checkROI(userInput.roi, size(I));
end

wasSpecified = @(x)~ismember(x,p.UsingDefaults);
if ~isDatastore && ...
        (wasSpecified('WriteLocation') || ...
        wasSpecified('NamePrefix') ||...
        wasSpecified('Verbose') || ...
        wasSpecified('UseParallel'))
    
    warning(message('vision:semanticseg:onlyApplyWithImds'))
end

if isDatastore
    % Only check write location when input is a datastore.
    iCheckWriteLocation(userInput.WriteLocation);
end

if userInput.UseParallel
    % Check for PCT installation
    try
        % GCP will error if PCT is not available.
        gcp('nocreate');
    catch
        userInput.UseParallel = false;
    end
end

exeenv = vision.internal.cnn.validation.checkExecutionEnvironment(...
    userInput.ExecutionEnvironment, mfilename);

type = iCheckOutputType(userInput.OutputType);

params.ROI                  = double(userInput.roi);
params.UseROI               = useROI;
params.MiniBatchSize        = double(userInput.MiniBatchSize);
params.OutputType           = type;
params.ExecutionEnvironment = exeenv;
params.PixelLayerID         = pxLayerID;
params.WriteLocation        = char(userInput.WriteLocation);
params.NamePrefix           = char(userInput.NamePrefix);
params.Verbose              = logical(userInput.Verbose);
params.UseParallel          = logical(userInput.UseParallel);
params.NetImageSize         = netSize;

%--------------------------------------------------------------------------
function [L, scores, allScores] = iClassifyImagePixels(X, net, params)
if isa(net,'SeriesNetwork')
    allScores = activations(net, X, params.PixelLayerID, ...
        'OutputAs', 'channels', ...
        'ExecutionEnvironment', params.ExecutionEnvironment, ...
        'MiniBatchSize', params.MiniBatchSize);
else
    name = net.Layers(params.PixelLayerID).Name;
    allScores = activations(net, X, name, ...      
        'ExecutionEnvironment', params.ExecutionEnvironment, ...
        'MiniBatchSize', params.MiniBatchSize);
end

[scores, L] = max(allScores,[],3);

%--------------------------------------------------------------------------
function type = iCheckOutputType(type)
type = validatestring(type,{'categorical','double'},mfilename,'OutputType');
type = char(type);

%--------------------------------------------------------------------------
function iCheckImage(I, netSize)
validateattributes(I, ...
    {'logical', 'numeric', 'matlab.io.datastore.ImageDatastore'},{},...
    mfilename, 'I');

if isnumeric(I) || islogical(I)
    if ndims(I) <= 3
        vision.internal.inputValidation.validateImage(I, 'I');
    else
        % 4D input
        validateattributes(I, {'numeric'}, {'ndims', 4}, mfilename, 'I');
        try
            % verify 3rd dim is 1 or 3.
            vision.internal.inputValidation.validateImage(I(:,:,:,1), 'I');
        catch
            error(message('vision:semanticseg:invalid4DImage'));
        end
    end
    
    sz = size(I);
    if any(sz(1:2) < netSize(1:2))
        error(message('vision:rcnn:imageSmallerThanNetwork',mat2str(netSize(1:2))));
    end
    
end

%--------------------------------------------------------------------------
function iCheckNetwork(net)
validateattributes(net, {'SeriesNetwork', 'DAGNetwork'}, ...
    {'scalar', 'nonempty'}, mfilename, 'net');

%--------------------------------------------------------------------------
function id = iFindAndAssertNetworkHasOnePixelClassificationLayer(net)
id = arrayfun(@(x)isa(x, 'nnet.cnn.layer.PixelClassificationLayer'), net.Layers);
id = find(id);
if isempty(id)
    error(message('vision:semanticseg:noPixelClassificationLayer'));
end

if numel(id) > 1
    error(message('vision:semanticseg:tooManyPixelClsLayers'));
end

%--------------------------------------------------------------------------
function iCheckWriteLocation(x)
validateattributes(x, {'char','string'}, {'scalartext'}, ...
    mfilename, 'WriteLocation')

if ~exist(x,'dir')
    error(message('vision:semanticseg:dirDoesNotExist'));
end

vision.internal.inputValidation.checkWritePermissions(x);

%--------------------------------------------------------------------------
function iCheckNamePrefix(x)
validateattributes(x, {'char','string'}, {'scalartext'}, ...
    mfilename, 'NamePrefix')

%--------------------------------------------------------------------------
function filenames = iWritePixelLabelData(L, indices, params, N)
writeLocation = params.WriteLocation;
numImages     = size(L,4);

filenames = cell(numImages,1);
for i = 1:numImages
    name = iCreateFileName(params.NamePrefix, indices(i), N);
    filenames{i} = fullfile(writeLocation, name);
    imwrite(uint8(L(:,:,:,i)), filenames{i});
end

%--------------------------------------------------------------------------
function name = iCreateFileName(prefix, idx, numImages)
format = sprintf('%%s_%%0%dd.png', string(numImages).strlength);
name = sprintf(format, prefix, idx);

%--------------------------------------------------------------------------
function iPrintHeader(printer, N)
printer.printMessage('vision:semanticseg:verboseHeader');
printer.print('-------------------------------------');
printer.linebreak();
printer.printMessage('vision:semanticseg:verboseInfo', N);

%--------------------------------------------------------------------------
function updateMessage(printer, prevMessage, nextMessage)
backspace = sprintf(repmat('\b',1,numel(prevMessage))); % figure how much to delete
printer.print([backspace nextMessage]);

%--------------------------------------------------------------------------
function nextMessage = iPrintInitProgress(printer, prevMessage, k, K)
txt = getString(message('vision:semanticseg:verboseProgressTxt'));
nextMessage = sprintf('%s: %.2f%%%',txt,100*k/K);
updateMessage(printer, prevMessage(1:end-1), nextMessage);

%--------------------------------------------------------------------------
function nextMessage = iPrintProgress(printer, prevMessage, k, K)
txt = getString(message('vision:semanticseg:verboseProgressTxt'));
nextMessage = sprintf('%s: %.2f%%%',txt,100*k/K);
updateMessage(printer, prevMessage, nextMessage);

%--------------------------------------------------------------------------
function [futureWriteBuffer, filename] = ...
    iParallelWritePixelLabelData(L, idx, params, futureWriteBuffer, numImages)
% Push write operation onto future buffer. First remove finished futures.
% If buffer is full, wait till one complete then pop it from the buffer.

iErrorIfAnyFutureFailed(futureWriteBuffer);

% Remove finished futures.
finished = arrayfun(@(f)strcmp(f.State,'finished'),futureWriteBuffer);
futureWriteBuffer(finished) = [];

% Add to future buffer.
name = iCreateFileName(params.NamePrefix, idx, numImages);
name = fullfile(params.WriteLocation, name);
filename = {name};
futureWriteBuffer(end+1) = parfeval(@imwrite, 0, uint8(L), name);

if length(futureWriteBuffer) > params.MiniBatchSize
    % Buffer is full. Wait till one of the futures is done.
    idx = fetchNext(futureWriteBuffer);
    futureWriteBuffer(idx) = [];
end

%--------------------------------------------------------------------------
function filenames = iProcessImageDatastoreSerially(imds, net, params)
numImages = numel(imds.Files);

filenames = cell(numImages, 1);

printer = vision.internal.MessagePrinter.configure(params.Verbose);

iPrintHeader(printer, numImages);
msg = iPrintInitProgress(printer,'', 1, numImages);

% Iterate through data and write results to disk.
k = 1;
while hasdata(imds)
    X = read(imds);
    
    idx = k:k+numel(X)-1;
    
    for i = 1:numel(X)
        
        L = iClassifyImagePixels(X{i}, net, params);
        
        filenames(idx(i)) = iWritePixelLabelData(L, idx(i), params, numImages);
        
        msg = iPrintProgress(printer, msg, idx(i), numImages);
        
    end
    
    k = idx(end)+1;
end
printer.linebreak(2);

%--------------------------------------------------------------------------
function filenames = iProcessImageDatastoreInParallel(imds, net, params)

isLocalPoolOpen = iAssertOpenPoolIsLocal();

if ~isLocalPoolOpen
    tryToCreateLocalPool();
end

numImages = numel(imds.Files);

filenames = cell(numImages, 1);

printer = vision.internal.MessagePrinter.configure(params.Verbose);

iPrintHeader(printer, numImages);

msg = iPrintInitProgress(printer,'', 1, numImages);

% pre-allocate future buffer.
futureWriteBuffer = parallel.FevalFuture.empty();

k = 1;
while hasdata(imds)
    X = read(imds);
    
    idx = k:k+numel(X)-1;
    
    for i = 1:numel(X)
        
        L = iClassifyImagePixels(X{i}, net, params);
        
        [futureWriteBuffer, filenames(idx(i))] = ...
            iParallelWritePixelLabelData(L, idx(i), params, futureWriteBuffer, numImages);
        
        msg = iPrintProgress(printer, msg, idx(i), numImages);
    end
    
    k = idx(end)+1;
end

% wait for all futures to finish
fetchOutputs(futureWriteBuffer);
iErrorIfAnyFutureFailed(futureWriteBuffer);

printer.linebreak(2);

%--------------------------------------------------------------------------
function iErrorIfAnyFutureFailed(futures)
failed = arrayfun(@(x)strcmpi(x.State,'failed'), futures);

if any(failed)
    % kill existing work and throw error.
    for i = 1:numel(futures)
        futures(i).cancel();
    end
    
    throw(futures(find(failed,1)).Error);
end

%--------------------------------------------------------------------------
function sz = iNetworkImageSize(net)
found = false;
for i = 1:numel(net.Layers)
    if isa(net.Layers(i), 'nnet.cnn.layer.ImageInputLayer')
        found = true;
        break
    end
end
assert(found, 'Missing image input layer');
sz = net.Layers(i).InputSize;

%--------------------------------------------------------------------------
function I = iConvertImageToMatchNumberOfNetworkImageChannels(I, imageSize)

isNetImageRGB = numel(imageSize) == 3 && imageSize(end) == 3;
isImageRGB    = size(I,3) == 3;

if isImageRGB && ~isNetImageRGB
    I = rgb2gray(I);
    
elseif ~isImageRGB && isNetImageRGB
    I = repmat(I,1,1,3);
end

%--------------------------------------------------------------------------
function pool = tryToCreateLocalPool()
defaultProfile = ...
    parallel.internal.settings.ProfileExpander.getClusterType(parallel.defaultClusterProfile());

if(defaultProfile == parallel.internal.types.SchedulerType.Local)
    % Create the default pool (ensured local)
    pool = parpool;
else
    % Default profile not local
    error(message('vision:vision_utils:noLocalPool', parallel.defaultClusterProfile()));
end

%--------------------------------------------------------------------------
function TF = iAssertOpenPoolIsLocal()
pool = gcp('nocreate');
if isempty(pool)
    TF = false;
else
    if pool.Cluster.Type ~= parallel.internal.types.SchedulerType.Local
        error(message('vision:vision_utils:noLocalPool', pool.Cluster.Type));
    else
        TF = true;
    end
end
