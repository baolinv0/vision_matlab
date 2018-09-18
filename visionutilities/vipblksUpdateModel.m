function vipblksUpdateModel(h)
% Function vipblksUpdateModel is a helper function to be called as part of slupdate.
% it is not intended to be called directly from the command line.

%   Copyright 2008 The MathWorks, Inc.

ReplaceInfo = { ...
   { 'ReferenceBlock', sprintf('viptransforms/2-D FFT')}, ...
   'Remove2DFFTWarnForNormalizeCB';   
    { 'ReferenceBlock', sprintf('vipobslib/Apply Geometric\nTransformation')}, ...
   'vision.internal.blocks.UpdateApplyGeometricTransformation';   

 };
ReplaceInfo = cell2struct(ReplaceInfo, { 'BlockDesc', 'ReplaceFcn'}, 2);
replaceBlocks(h, ReplaceInfo);
