function [r3,T3,dr3dr1,dr3dT1,dr3dr2,dr3dT2,dT3dr1,dT3dT1,dT3dr2,dT3dT2] = composeMotion(r1,T1,r2,T2)
% composeMotion Compute derivative of composed motion, where
% r3 = rodrigues(R3)
% R3 = R2 * R1
% R2 = rodrigues(r1)
% R1 = rodrigues(r2)
% and
% T3 = R2 * T1 + T2

% Copyright 2017 MathWorks, Inc.

outputClass = class(r1);

% Rotations:

[R1, dR1dr1] = vision.internal.calibration.rodriguesVectorToMatrix(r1);

[R2, dR2dr2] = vision.internal.calibration.rodriguesVectorToMatrix(r2);

[R3,dR3dR2,dR3dR1] = vision.internal.calibration.matrixMultDerivative(R2,R1);

[r3,dr3dR3] = vision.internal.calibration.rodriguesMatrixToVector(R3);

dr3dr1 = dr3dR3 * dR3dR1 * dR1dr1;
dr3dr2 = dr3dR3 * dR3dR2 * dR2dr2;

dr3dT1 = zeros(3,3,outputClass);
dr3dT2 = zeros(3,3,outputClass);

% Translations:
[R2T1,dR2T1dR2,dR2T1dT1] = vision.internal.calibration.matrixMultDerivative(R2,T1);

dR2T1dr2 = dR2T1dR2 * dR2dr2;

T3 = R2T1 + T2;

dT3dT1 = dR2T1dT1;
dT3dT2 = eye(3,outputClass);

dT3dr2 = dR2T1dr2;
dT3dr1 = zeros(3,3,outputClass);

end