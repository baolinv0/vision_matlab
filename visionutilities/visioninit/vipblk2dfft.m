function varargout = vipblk2dfft(action) %#ok
% DSPBLKFFT2 DSP Blockset FFT block helper function.

% Copyright 1995-2010 The MathWorks, Inc.

if nargin==0, action = 'dynamic'; end
blk = gcb;

switch action
 case 'init'
    lower_blk = [blk,'/2D IFFT'];
    BLKtableOpt = get_param(blk, 'TableOpt');
    LBLKtableOpt = get_param(lower_blk, 'TableOpt');
    if ~strcmp(BLKtableOpt,LBLKtableOpt)
        set_param(lower_blk, 'TableOpt', BLKtableOpt);
    end
    BLKBitRevOrder = get_param(blk, 'BitRevOrder');
    LBLKBitRevOrder = get_param(lower_blk, 'BitRevOrder');
    if ~strcmp(BLKBitRevOrder,LBLKBitRevOrder)
        set_param(lower_blk, 'BitRevOrder', BLKBitRevOrder);
    end
    BLKcs_in = get_param(blk,'cs_in');
    LBLKcs_in = get_param(lower_blk,'cs_in');
    if ~strcmp(BLKcs_in,LBLKcs_in)
        set_param(lower_blk, 'cs_in', BLKcs_in);
    end
    BLKSkipNorm = get_param(blk,'SkipNorm');  
    LBLKSkipNorm = get_param(lower_blk,'SkipNorm');  
    if ~strcmp(BLKSkipNorm,LBLKSkipNorm)
        set_param(lower_blk, 'SkipNorm', BLKSkipNorm);
    end
    BLKFirstCoeffM = get_param(blk,'firstCoeffMode');
    LBLKFirstCoeffM = get_param(lower_blk,'firstCoeffMode');
    if ~strcmp(BLKFirstCoeffM,LBLKFirstCoeffM)
        set_param(lower_blk, 'firstCoeffMode', BLKFirstCoeffM);
    end
    BLKOutputM = get_param(blk,'outputMode');
    LBLKOutputM = get_param(lower_blk,'outputMode');
    if ~strcmp(BLKOutputM,LBLKOutputM)
        set_param(lower_blk, 'outputMode', BLKOutputM);
    end
    BLKAccumM = get_param(blk,'accumMode');
    LBLKAccumM = get_param(lower_blk,'accumMode');
    if ~strcmp(BLKAccumM,LBLKAccumM)
        set_param(lower_blk, 'accumMode', BLKAccumM);
    end
    BLKProdOutM = get_param(blk,'prodOutputMode');
    LBLKProdOutM = get_param(lower_blk,'prodOutputMode');
    if ~strcmp(BLKProdOutM,LBLKProdOutM)
        set_param(lower_blk, 'prodOutputMode', BLKProdOutM);
    end
    BLKRoundM = get_param(blk,'roundingMode');
    LBLKRoundM = get_param(lower_blk,'roundingMode');
    if ~strcmp(BLKRoundM,LBLKRoundM)
        set_param(lower_blk, 'roundingMode', BLKRoundM);
    end
    BLKOverflowM = get_param(blk,'overflowMode');
    LBLKOverflowM = get_param(lower_blk,'overflowMode');
    if ~strcmp(BLKOverflowM,LBLKOverflowM)
        set_param(lower_blk, 'overflowMode', BLKOverflowM);
    end
    BLKLockSlace = get_param(blk,'LockScale');
    LBLKLockSlace = get_param(lower_blk,'LockScale');
    if ~strcmp(BLKLockSlace,LBLKLockSlace)
        set_param(lower_blk, 'LockScale', BLKLockSlace);
    end
    BLKFFTImpl = get_param(blk,'FFTImplementation');
    LBLKFFTImpl = get_param(lower_blk,'FFTImplementation');
    if ~strcmp(BLKFFTImpl,LBLKFFTImpl)
        set_param(lower_blk, 'FFTImplementation', BLKFFTImpl);
    end
end
