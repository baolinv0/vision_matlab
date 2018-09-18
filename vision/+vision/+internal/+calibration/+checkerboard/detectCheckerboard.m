function [points, boardSize] = detectCheckerboard(I, sigma, peakThreshold)

%#codegen

[cxy, c45, Ix, Iy, Ixy, I_45_45] = ...
    vision.internal.calibration.checkerboard.secondDerivCornerMetric(I, sigma);
[Ix2, Iy2, IxIy] = computeJacobianEntries(Ix, Iy);

points0 = vision.internal.calibration.checkerboard.find_peaks(cxy, peakThreshold);
scores0 = cxy(sub2ind(size(cxy), points0(:, 2), points0(:, 1)));
board0 = growCheckerboard(points0, scores0, Ix2, Iy2, IxIy, 0);

points45 = vision.internal.calibration.checkerboard.find_peaks(c45, peakThreshold);
scores45 = c45(sub2ind(size(c45), points45(:, 2), points45(:, 1)));
board45 = growCheckerboard(points45, scores45, Ix2, Iy2, IxIy, pi/4);

points = [];
boardSize = [0 0];
if board0.isValid && board0.Energy < board45.Energy
    board0 = orient(board0, I);
    [points, boardSize] = toPoints(board0);
    points = vision.internal.calibration.checkerboard.subPixelLocation(Ixy, points);
elseif board45.isValid
    board45 = orient(board45, I);
    [points, boardSize] = toPoints(board45);
    points = vision.internal.calibration.checkerboard.subPixelLocation(I_45_45, points);
end

end

%--------------------------------------------------------------------------
function [Ix2, Iy2, Ixy] = computeJacobianEntries(Ix, Iy)

Ix2 = Ix .^ 2;
Iy2 = Iy .^ 2;
Ixy = Ix .* Iy;

G = fspecial('gaussian', 7, 1.5);

Ix2 = imfilter(Ix2, G);
Iy2 = imfilter(Iy2, G);
Ixy = imfilter(Ixy, G);

end
%--------------------------------------------------------------------------
function board = growCheckerboard(points, scores, Ix2, Iy2, Ixy, theta)

% Exit immediately if no corner points were found
if isempty(scores)
    if isempty(coder.target)
        board = struct('BoardIdx', zeros(3), 'BoardCoords', zeros(3,3,3), ...
            'Energy', Inf, 'isValid', 0);
    else
        board = vision.internal.calibration.checkerboard.Checkerboard;
    end
    return;
end

% only use corners with high scores as seeds to reduce computation
seedIdx = 1:size(points, 1);
[~, sortedIdx] = sort(scores(seedIdx), 'descend');
seedIdx = seedIdx(sortedIdx);
if numel(sortedIdx) > 2000
    seedIdx = seedIdx(1:min(2000, round(numel(seedIdx)/2)));
end

angleThreshold = 3 * pi / 16;

if isempty(coder.target)
    v1_matrix = [];
    v2_matrix = [];
    seedIdx_matrix = [];
    
    for i = seedIdx
        [v1, v2] = cornerOrientations(Ix2, Iy2, Ixy, round(points(i, :)));
        alpha1 = abs(atan2(v1(2), v1(1)));
        alpha2 = abs(atan2(v2(2), v2(1)));
        if abs(abs(alpha1 - pi) - theta) > angleThreshold && ...
                abs(abs(alpha2 - pi) - theta) > angleThreshold
            continue;
        else
            v1_matrix = [v1_matrix;v1]; %#ok<AGROW>
            v2_matrix = [v2_matrix;v2]; %#ok<AGROW>
            seedIdx_matrix = [seedIdx_matrix;i]; %#ok<AGROW>
        end
    end
    
    board = visionInitializeAndExpandCheckerboard(seedIdx_matrix,single(points),v1_matrix,v2_matrix);
else
    previousBoard = vision.internal.calibration.checkerboard.Checkerboard;
    currentBoard = vision.internal.calibration.checkerboard.Checkerboard;
    for i = 1:numel(seedIdx)
        [v1, v2] = cornerOrientations(Ix2, Iy2, Ixy, round(points(seedIdx(i), :)));
        alpha1 = abs(atan2(v1(2), v1(1)));
        alpha2 = abs(atan2(v2(2), v2(1)));
        if abs(abs(alpha1 - pi) - theta) > angleThreshold && ...
                abs(abs(alpha2 - pi) - theta) > angleThreshold
            continue;
        end
        
        currentBoard.initialize(seedIdx(i), points, v1, v2);
        expandBoardFully(currentBoard);
        if currentBoard.Energy < previousBoard.Energy            
            tmpBoard = previousBoard;
            previousBoard = currentBoard;
            currentBoard = tmpBoard;
        end
    end
    board = previousBoard;
end
end

%--------------------------------------------------------------------------
function [v1, v2] = cornerOrientations(Ix2, Iy2, Ixy, p)
% The orientation vectors are the eigen vectors of the 
% structure tensor:
% [Ix^2  Ixy ]
% [Ixy   Iy^2]

a = Ix2(p(2), p(1));
b = Ixy(p(2), p(1));
c = Iy2(p(2), p(1));

% % Computing eigenvectors "by hand", because the eig() function behaves
% % differently in codegen.
% % Since the matrix is positive-semidefinite, its eigenvectors are
% % orthogonal. Compute the first eigenvector, then swap its elements and
% % negate the y-component to make the second one.
sm = a + c;
df = a - c;
adf = abs(df);
tb = b + b;
ab = abs(tb);

if adf > ab
    rt = adf * sqrt(1 + (ab/adf)^2);
elseif adf < ab
    rt = ab * sqrt(1 + (adf/ab)^2);
else
    rt = ab * sqrt(2);
end

if sm < 0
    sgn1 = -1;
else
    sgn1 = 1;
end

if df > 0
    cs = df + rt;
    sgn2 = 1;
else
    cs = df - rt;
    sgn2 = -1;
end

acs = abs(cs);
if acs > ab
    ct = -tb / cs;
    sn1 = 1 / sqrt(1 + ct * ct);
    cs1 = ct * sn1;
else
    if ab == single(0)
        cs1 = single(1);
        sn1 = single(0);
    else
        tn = -cs / tb;
        cs1 = 1 / sqrt(1 + tn * tn);
        sn1 = tn * cs1;
    end
end
if sgn1 == sgn2
    tn = cs1;
    cs1 = -sn1;
    sn1 = tn;
end

v1 = [-sn1, cs1];
v2 = [cs1, sn1];

% Rotate the vectors by 45 degrees to align with square edges.
R = [cos(pi/4) -sin(pi/4); sin(pi/4) cos(pi/4)];
v1 = v1 * R;
v2 = v2 * R;
end

%--------------------------------------------------------------------------

function [points, boardSize] = toPoints(this)
% returns the points as an Mx2 matrix of x,y coordinates, and
% the size of the board

if any(this.BoardIdx(:) == 0)
    points = [];
    boardSize = [0 0];
    return;
end

numPoints = size(this.BoardCoords, 1) * size(this.BoardCoords, 2);
points = zeros(numPoints, 2);
x = this.BoardCoords(:, :, 1)';
points(:, 1) = x(:);
y = this.BoardCoords(:, :, 2)';
points(:, 2) = y(:);
boardSize = [size(this.BoardCoords, 2)+1, size(this.BoardCoords, 1)+1];
end

    
%--------------------------------------------------------------------------
function board = orient(board, I)

    if ~isinf(board.Energy)
        % orient the board so that the long side is the X-axis
        if size(board.BoardCoords, 1) < size(board.BoardCoords, 2)
            board = rot90_checkerboard(board, 1);
        end

        % try to orient the board so that (0,0) is on a black square
        if ~isUpperLeftBlack(board, I);
            board = rot90_checkerboard(board, 2);
        end

        % if both sides are odd or both sides are even, make sure
        % that (0,0) is at the upper-left corner.
        if ~xor(mod(size(board.BoardCoords, 1), 2) == 0,... 
            mod(size(board.BoardCoords, 2), 2) == 0)
            if any(board.BoardCoords(1,1,:) > board.BoardCoords(end, end, :))
                board = rot90_checkerboard(board, 2);
            end
        end
    end
end

%--------------------------------------------------------------------------
function board = rot90_checkerboard(board, k)
board.BoardIdx = rot90(board.BoardIdx, k);
newBoardCoords1 = rot90(board.BoardCoords(:,:,1), k);
newBoardCoords2 = rot90(board.BoardCoords(:,:,2), k);
board.BoardCoords = cat(3, newBoardCoords1, newBoardCoords2);
end

%--------------------------------------------------------------------------

function tf = isUpperLeftBlack(this, I)
% check if the upper-left square of the board is black

% create a mask for the upper-left square
upperLeftPolyX = [this.BoardCoords(1, 1, 1), ...
    this.BoardCoords(1, 2, 1), this.BoardCoords(2, 2, 1), ...
    this.BoardCoords(2, 1, 1)];
upperLeftPolyY = [this.BoardCoords(1, 1, 2), ...
    this.BoardCoords(1, 2, 2), this.BoardCoords(2, 2, 2), ...
    this.BoardCoords(2, 1, 2)];
upperLeftMask = poly2RectMask(upperLeftPolyX, upperLeftPolyY, ...
    size(I, 1), size(I, 2));

% create a mask for the square to the right of it
nextSquarePolyX = [this.BoardCoords(1, 2, 1), ...
    this.BoardCoords(1, 3, 1), this.BoardCoords(2, 3, 1), ...
    this.BoardCoords(2, 2, 1)];
nextSquarePolyY = [this.BoardCoords(1, 2, 2), ...
    this.BoardCoords(1, 3, 2), this.BoardCoords(2, 3, 2), ...
    this.BoardCoords(2, 2, 2)];
nextSquareMask = poly2RectMask(nextSquarePolyX, nextSquarePolyY,...
    size(I, 1), size(I, 2));

% check if the first square is darker than the second
tf = mean(mean(I(upperLeftMask))) < mean(mean(I(nextSquareMask)));
end

%--------------------------------------------------------------------------
function mask = poly2RectMask(X, Y, height, width)
X = sort(X);
Y = sort(Y);
x1 = X(2);
x2 = X(3);
y1 = Y(2);
y2 = Y(3);
mask = false(height, width);
mask(y1:y2, x1:x2) = true;
end