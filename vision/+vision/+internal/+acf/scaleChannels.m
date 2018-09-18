function lambdas = scaleChannels(Is, params)
%scaleChannels Compute lambdas for channel power law scaling.
%
% Notes
% -----
% For a broad family of features, including gradient histograms and all
% channel types tested, the feature responses computed at a single scale
% can be used to approximate feature responses at nearby scales. The
% approximation is accurate at least within an entire scale octave. 
%

% References
% ----------
% [1] P. Dollár, R. Appel, S. Belongie and P. Perona
%   "Fast Feature Pyramids for Object Detection", PAMI 2014.

% construct parameters (don't pad, concat or appoximate)
params.ChannelPadding       = [0 0]; 
params.NumApprox            = 0; 
params.SmoothChannels       = 0;
params.ModelSize(:)         = max(8, params.Shrink * 4);
params.NumScaleLevels       = 8;
params.NumUpscaledOctaves   = 0;

% crop all images to smallest image size
ds = [inf inf]; 
nImages = numel(Is);
for i = 1 : nImages
    ds = min(ds, [size(Is{i},1) size(Is{i},2)]);
end
ds = round(ds/params.Shrink) * params.Shrink;
for i = 1 : nImages
    Is{i} = Is{i}(1:ds(1), 1:ds(2), :); 
end

% compute fs [nImages x nScales x 3] array of feature means
P = vision.internal.acf.computePyramid(Is{1}, params);

scales  = P.Scales'; 
nScales = P.NumScales; 
fs = zeros(nImages, nScales, 3);

if params.UseParallel
    parfor i = 1 : nImages
        P = vision.internal.acf.computePyramid(Is{i}, params);
        for j = 1 : nScales
            %[3 1 params.hog.NumBins]
            f1 = P.Channels{j}(:,:,1:3);
            f2 = P.Channels{j}(:,:,4);
            f3 = P.Channels{j}(:,:,5:end);
            fs(i,j,:) = [mean(f1(:)), mean(f2(:)), mean(f3(:))];
        end
    end
else
    for i = 1 : nImages
        P = vision.internal.acf.computePyramid(Is{i}, params);
        for j = 1 : nScales
            %[3 1 params.hog.NumBins]
            f1 = P.Channels{j}(:,:,1:3);
            f2 = P.Channels{j}(:,:,4);
            f3 = P.Channels{j}(:,:,5:end);
            fs(i,j,:) = [mean(f1(:)), mean(f2(:)), mean(f3(:))];
        end
    end
end

% remove fs with fs(:,1,:) having small values
kp = max(fs(:,1,:)); 
kp = fs(:,1,:) > kp(ones(1, nImages), 1, :) / 50;
kp = min(kp, [], 3); 
fs = fs(kp, :, :); 

% compute ratios, intercepts and lambdas using least squares
scales1 = scales(2:end); 
nScales = nScales - 1; 
O = ones(nScales, 1);
rs = fs(:, 2:end, :)./fs(:, O, :); 
mus = permute(mean(rs,1), [2 3 1]);
out = [O -log2(scales1)] \ log2(mus); 
lambdas = out(2, :);
