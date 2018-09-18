function useParallel = useParallelPreference()
% Returns true if the UseParallel preference is enabled, otherwise returns
% false.

prefDoesNotExist = ~ispref('ComputerVision','UseParallel');

if prefDoesNotExist
    % set the default preference for the first time.
    setpref('ComputerVision','UseParallel', 0);    
end

useParallel = logical(getpref('ComputerVision','UseParallel'));
