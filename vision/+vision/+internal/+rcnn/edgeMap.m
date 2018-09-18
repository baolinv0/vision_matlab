function [map, bw, varargout] = edgeMap(I)

if ~ismatrix(I)
    I = rgb2gray(I);
end

bw = edge(I, 'sobel');

[gx, gy] = computeGradient(I);

gMag = hypot(gx,gy);

map = zeros(size(I),'like', gMag);
map(bw) = gMag(bw);

if nargout == 3    
    gDir = atan2d(-gy,gx);
    ori = zeros(size(I),'like', gDir);
    ori(bw) = gDir(bw);
    varargout{1} = ori;
end

% -------------------------------------------------------------------------
function [gx, gy] = computeGradient(img)

img = single(img);

gx = zeros(size(img), 'like', img);
gy = zeros(size(img), 'like', img);

gx(:,2:end-1) = conv2(img, single([1 0 -1]), 'valid');
gy(2:end-1,:) = conv2(img, single([1;0;-1]), 'valid');

% forward difference on borders
gx(:,1)   = img(:,2)   - img(:,1);
gx(:,end) = img(:,end) - img(:,end-1);

gy(1,:)   = img(2,:)   - img(1,:);
gy(end,:) = img(end,:) - img(end-1,:);

