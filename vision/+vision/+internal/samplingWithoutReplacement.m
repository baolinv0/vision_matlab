function samples = samplingWithoutReplacement(N, K)
% samplingWithoutReplacement Randomly generate K unique numbers from [1, ..., N].
%  N is positive integer. K is the number of samples. samples is a vector with
%  sampled K integers.

% Copyright 2014 The MathWorks, Inc.

% Validate the first argument
validateattributes(N, {'numeric'}, {'scalar', 'real', 'nonnegative', 'integer'}, mfilename, 'N');

% Validate the first argument
validateattributes(K, {'numeric'}, {'scalar', 'real', 'nonnegative', 'integer', '<=', N}, mfilename, 'K');

% if more than 20% is needed, we use random permutation
if 5*K > N
    rp = randperm(N);
    samples = rp(1:K);
else
    % More efficient if K is a small value
    % Repeatedly sample with replacement
    x = false(N, 1);
    sumx = 0;
    while sumx < K
        x(randi(N,1,K-sumx)) = true; 
        sumx = sum(x);
    end
    samples = find(x);
    samples = samples(randperm(K));
end
