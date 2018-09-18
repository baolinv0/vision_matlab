function [si,so,dtInfo] = vipblkhough
% VIPBLKHOUGH Mask dynamic dialog function for Hough Transform BLock 
% Copyright 1995-2004 The MathWorks, Inc.

blkh = gcbh;
% num = misc(1)
        % output H (2)
        % accum(4)
        % prodOutput(8)
        % firstCoeff for sine table - (32)
        % secondCoeff for rho (64)=125;         
        % memory for theta outport(16)
dtInfo = dspGetFixptDataTypeInfo(blkh,127);
[si, so] = getPortLabels(blkh);

% -----------------------------------------------
function [si, so] = getPortLabels(blkh)

si(1).port = 1;si(1).txt='BW';
so(1).port = 1;so(1).txt='Hough';

HasThetaRhoOutport =  strcmp(get_param(blkh,'out_theta_rho'),'on');
if HasThetaRhoOutport
    so(2).port = 2;so(2).txt='Theta';  
    so(3).port = 3;so(3).txt='Rho';  
else
    so(2).port = 1;so(2).txt='Hough';  
    so(3).port = 1;so(3).txt='Hough'; 
end    

% [EOF] vipblkhough.m
