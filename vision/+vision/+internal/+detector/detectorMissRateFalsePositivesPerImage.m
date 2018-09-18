function [amr, mr, fppi] = detectorMissRateFalsePositivesPerImage(...
    labels, scores, numExpected, numImages)
% Compute log average miss rate metric for detector results. Labels greater
% than zero are for a positive samples and smaller than zero for negative
% samples. 

if isempty(labels)
    fppi = 0; 
    mr = 1; 
    amr = 0;
    return;
end

[~, idx] = sort(scores, 'descend');
labels = labels(idx);

tp = labels > 0;
fp = labels <= 0;

tp = cumsum(tp);
fp = cumsum(fp);
            
fppi = fp / numImages;
if numExpected > 0
    mr = tp / numExpected;
else
    mr = ones(size(tp));
end
fppi_tmp = [-inf; fppi]; 
mr_tmp = [0; mr];

% Use 9 evenly spaced data points in log-space
ref = 10.^(-2:.25:0);
for i = 1:length(ref)
    j = find(fppi_tmp<=ref(i),1,'last'); 
    if isempty(j)
        j = 1;
    end
    ref(i) = mr_tmp(j); 
end

mr = 1 - mr;
samples = 1 - ref;
samples(samples<=0) = 0;
amr = exp(mean(log(samples)));
