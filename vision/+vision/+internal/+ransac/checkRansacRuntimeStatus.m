%==========================================================================
% Check runtime status and report error if there is one
%==========================================================================
function checkRansacRuntimeStatus(statusCode, status)
if status == statusCode.NotEnoughPts
    warning(message('vision:pointcloud:notEnoughPts'));
elseif status == statusCode.NotEnoughInliers
    warning(message('vision:pointcloud:notEnoughInliers'));
end