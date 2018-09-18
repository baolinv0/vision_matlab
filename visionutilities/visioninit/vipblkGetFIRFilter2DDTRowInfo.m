function dtRows = vipblkGetFIRFilter2DDTRowInfo()
%vipblkGetFIRFilter2DDTRowInfo
%
%  Computer Vision System Toolbox library block mask helper function
%  used by the 2D FIR Filter block

% Copyright 1995-2009 The MathWorks, Inc.

dtRows = dspblkGetDefaultDTRowInfo(4);


%1=coeff; 2=prod; 3= accum; 4=output;
%mdlOrder = [1 4 3 2];
maskOrder = [1 2 3 4];
ORDER = maskOrder;%mdlOrder;   
dtRows{ORDER(1)}.name                 = getString(message('vision:masks:Coefficients'));
dtRows{ORDER(1)}.prefix               = 'firstCoeff';
dtRows{ORDER(1)}.defaultUDTStrValue   = 'fixdt(1,16)';%Specify word length
dtRows{ORDER(1)}.inheritSameWLAsInput = 1;
dtRows{ORDER(1)}.binaryPointScaling   = 1;
dtRows{ORDER(1)}.bestPrecisionMode    = 1;
dtRows{ORDER(1)}.hasValBestPrecFLMode = 1;
dtRows{ORDER(1)}.valBestPrecFLMaskPrm = 'filterMtrx';
dtRows{ORDER(1)}.signedSignedness     = 1;
dtRows{ORDER(1)}.unsignedSignedness   = 1;
dtRows{ORDER(1)}.hasDesignMin         = 1;
dtRows{ORDER(1)}.hasDesignMax         = 1;

dtRows{ORDER(2)}.name                = 'prodOutput';
dtRows{ORDER(2)}.defaultUDTStrValue  = 'fixdt([],32,10)';
dtRows{ORDER(2)}.inheritInput        = 1;
dtRows{ORDER(2)}.autoSignedness      = 1;%dnherit signedness from input(s)
dtRows{ORDER(2)}.signedSignedness    = 0;
%default value for binaryPointScaling is 1

dtRows{ORDER(3)}.name                = 'accum';
dtRows{ORDER(3)}.defaultUDTStrValue  = 'Inherit: Same as product output';
dtRows{ORDER(3)}.inheritInput        = 1;
dtRows{ORDER(3)}.inheritProdOutput   = 1;
dtRows{ORDER(3)}.autoSignedness      = 1;%dnherit signedness from input(s)
dtRows{ORDER(3)}.signedSignedness    = 0;
%default value for binaryPointScaling is 1

dtRows{ORDER(4)}.name                = 'output';
dtRows{ORDER(4)}.defaultUDTStrValue  = 'Inherit: Same as input';
dtRows{ORDER(4)}.inheritInput        = 1;
dtRows{ORDER(4)}.autoSignedness      = 1;%same as first input (for backward compatibility)
dtRows{ORDER(4)}.signedSignedness    = 1;
dtRows{ORDER(4)}.unsignedSignedness  = 1;
dtRows{ORDER(4)}.hasDesignMin        = 1;
dtRows{ORDER(4)}.hasDesignMax        = 1;
%default value for binaryPointScaling is 1