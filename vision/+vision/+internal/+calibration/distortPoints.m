function distortedPoints = distortPoints(points, intrinsicMatrix, ...
    radialDistortion, tangentialDistortion)

%#codegen

% unpack the intrinisc matrix
cx = intrinsicMatrix(3, 1);
cy = intrinsicMatrix(3, 2);
fx = intrinsicMatrix(1, 1);
fy = intrinsicMatrix(2, 2);
skew = intrinsicMatrix(2, 1);

% center the points
center = [cx, cy];
centeredPoints = bsxfun(@minus, points, center);

% normalize the points
yNorm = centeredPoints(:, 2, :) ./ fy;
xNorm = (centeredPoints(:, 1, :) - skew * yNorm) ./ fx;

% compute radial distortion
r2 = xNorm .^ 2 + yNorm .^ 2;
r4 = r2 .* r2;
r6 = r2 .* r4;

k = zeros(1, 3, 'like', radialDistortion);
k(1:2) = radialDistortion(1:2);
if numel(radialDistortion) < 3
    k(3) = 0;
else
    k(3) = radialDistortion(3);
end

alpha = k(1) * r2 + k(2) * r4 + k(3) * r6;

% compute tangential distortion
p = tangentialDistortion;
xyProduct = xNorm .* yNorm;
dxTangential = 2 * p(1) * xyProduct + p(2) * (r2 + 2 * xNorm .^ 2);
dyTangential = p(1) * (r2 + 2 * yNorm .^ 2) + 2 * p(2) * xyProduct;

% apply the distortion to the points
normalizedPoints = [xNorm, yNorm];
distortedNormalizedPoints = normalizedPoints + normalizedPoints .* [alpha, alpha] + ...
    [dxTangential, dyTangential];

% convert back to pixels
distortedPointsX = distortedNormalizedPoints(:, 1) * fx + cx + ...
    skew * distortedNormalizedPoints(:,2);
distortedPointsY = distortedNormalizedPoints(:, 2) * fy + cy;


distortedPoints = [distortedPointsX, distortedPointsY];