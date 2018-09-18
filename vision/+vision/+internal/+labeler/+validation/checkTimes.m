function checkTimes(labelData, dataSource)
%checkTimes validate timestamps for labelData and check consistency with
%dataSource.
%   checkTimes(labelData, dataSource)

dsTimes = dataSource.TimeStamps;
ldTimes = labelData.Time;

% Timestamp vectors must be of the same length
if ~isequal(size(dsTimes), size(ldTimes))
    error(message('vision:groundTruth:inconsistentTimeStamps'))
end

% Times must match
maxAbsDiff = max(abs(seconds(dsTimes) - seconds(ldTimes)));
tol = 1e-6; % micro-seconds
if maxAbsDiff > tol
    error(message('vision:groundTruth:inconsistentTimeStamps'))
end
end