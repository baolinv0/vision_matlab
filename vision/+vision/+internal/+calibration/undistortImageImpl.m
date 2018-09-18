function [J, newOrigin] = undistortImageImpl(I, map, interp, fillValues)
% undistortImageImpl implements the core lens undistortion
% algorithm for the undistortImage.m function.  See help for
% undistortImage for further details.

%#codegen

if isa(I,'uint8');
    I = single(I);
    fillValues = single(fillValues);
end

% subtract 2 from Xmap and Ymap since interp2d will end up
% adding it back

map = map - 2;

if isempty(coder.target)
    J = images.internal.interp2d(I, map(:,:,1), map(:,:,2),...
        interp, fillValues);
else
    J = images.internal.coder.interp2d(I, map(:,:,1), map(:,:,2),...
        interp, fillValues);
end

newOrigin = [0 0];