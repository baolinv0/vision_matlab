function code = convertKAZEDiffusionToOCVCode(method)
% -------------------------------------------------------------------------
% Convert diffusion method to opencv code
% -------------------------------------------------------------------------

switch method
    case 'region'
        code = uint8(1);
    case 'sharpedge'
        code = uint8(0);
    case 'edge'
        code = uint8(2);
    otherwise
        error('detectKAZEFeatures: diffusion method cannot be translated to code')
end
end