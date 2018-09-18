%==========================================================================
% helper function for search
% returns sorted smallest n elements of each row in an unsorted matrix x
%==========================================================================
function [values, indices] = partialSort(x, n, mode)
% X is the input unsorted matrix
% N is the number of top elements to return
% MODE can be 'ascend' or 'descend', default 'ascend'
%#codegen


if n > size(x, 2), n = size(x, 2); end;
if nargin < 3, mode = 'ascend'; end;

values = zeros(n, size(x, 1), 'like', x);
indices = zeros(n, size(x, 1));

if isempty(x),
    indices = cast(indices, 'uint32');
    return;
end

if n < log2(size(x, 2))
    % using min/max should be faster for small n
    if strcmp(mode, 'ascend')
        for i = 1:n
            [values(i, :), indices(i, :)] = min(x, [], 2);
            inds = sub2ind(size(x), 1:size(x, 1), indices(i, :));
            x(inds) = inf;
        end
    else
        for i = 1:n
            [values(i, :), indices(i, :)] = max(x, [], 2);
            inds = sub2ind(size(x), 1:size(x, 1), indices(i, :));
            x(inds) = -inf;
        end
    end
else
    [xSorted, inds] = sort(x, 2, mode);
    values = xSorted(:, 1:n)';
    indices = inds(:, 1:n)';
end

indices = cast(indices, 'uint32');
