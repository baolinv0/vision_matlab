% This class wraps the RANDPERM function to provide a mechanism to simplify
% testing.
classdef RandomSelector
    methods
        function i = randperm(~, N, K)
            if nargin > 2
                i = randperm(N, K);
            else
                i = randperm(N);
            end
        end
    end
end