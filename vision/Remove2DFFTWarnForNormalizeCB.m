function Remove2DFFTWarnForNormalizeCB(block, h)
%Remove2DFFTWarnForNormalizeCB Remove the warning generated from the block
%when the skip scaling checkbox was moved from fixed-pt tab to main tab. 
% 

%   Copyright 2008 The MathWorks, Inc.

if askToReplace(h, block)    
    reason = 'Stop seeing the warning in 2D FFT block, caused by moving the Scaling checkbox from fixed-pt tab to Main tab';
    blkParams = GetMaskEntries(block);
    if ~strcmp(blkParams{2},'NEW')
        funcSet = uSafeSetParam(h, block,'TableOpt','NEW');
        appendTransaction(h, block, reason, {funcSet});
    end
end
