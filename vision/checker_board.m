function x = checker_board(P,N)
%CHECKER_BOARD RGB test image using a checker-board pattern.
%   The board has red and blue checkers, with a green color ramp
%	increasing linearly from top to bottom.  Default image size
%	is 100x100, with 10 checkers per side.
%
%	CHECKER_BOARD(P,N) specifies PxP pixel checkers with N
%	checkers  per side, where N must specify an even number of
%	checkers.
%
%  Example:
%     image(checker_board)         % 10x10 pixels, 10x10 grid
%     image(checker_board(20,6))   % 20x20 pixels, 6x6 grid

% Copyright 2004-2006 The MathWorks, Inc.

% Provide defaults:
if nargin<1, P=10; end
if nargin<2, N=10; end
N=round(N);  % Checkers per side of image
P=round(P);  % Pixels per checker
if P<1,
    error(message('vision:checker_board:noPixel'));
end

% Build one checker-board plane:
if N==1,
    x = ones(P);
elseif rem(N,2)==1,  % odd
    x = repmat([ones(P) zeros(P) ; zeros(P) ones(P)],(N-1)/2,(N-1)/2);
    x = [x repmat([ones(P); zeros(P)],(N-1)/2,1) ];
    x = [x; x(1:P,:,:)];  % copy first "row" of blocks to last "row"
else  % even
    x = repmat([ones(P) zeros(P) ; zeros(P) ones(P)],N/2,N/2);
end

% Construct RGB image:
D = N*P;
r = x;            % Red checkers
b = 1-x;          % Blue checkers
g=(0:D-1)'/(D-1); % Green ramp
x=cat(3, r, g(:,ones(D,1)), b);

% [EOF] checker_board.m
