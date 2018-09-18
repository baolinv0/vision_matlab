function fmt = getNiceDurationFormat(sec)
%getNiceDurationFormat returns a nice display Format for duration.
%
%   getNiceDurationFormat returns a character vector which can be used to
%   set the Format for duration objects. 
%
%   This is better than the standard display format provided by duration
%   in the following ways:
%   1. Seconds are shown with at least 5 digit precision, which is useful
%      for data coming in at 30 fps.
%   2. For times less than a minute, only seconds are shown.
%   3. For times less than an hour, only minutes and seconds are shown.
%   4. For times longer than an hour, hours, minutes and seconds are shown.
% 
%   See also duration, seconds.

% Copyright 2016 The MathWorks, Inc.

secondsInAMinute = 60;
secondsInAnHour = 3600;

if sec > secondsInAnHour
    fmt = 'hh:mm:ss.SSSSS';
elseif sec > secondsInAMinute
    fmt = 'mm:ss.SSSSS';
else
    fmt = 's';
end