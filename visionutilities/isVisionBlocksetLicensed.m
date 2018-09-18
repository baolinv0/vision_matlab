function [ value, msg ] = isVisionBlocksetLicensed( operation )
    % Copyright 2015, The Mathworks, Inc.
    value = dig.isProductInstalled( 'Computer Vision System Toolbox', 'Video_and_Image_Blockset' );
    msg = '';
    if strcmpi( operation, 'checkout' ) && ~value
       msg = 'Failed to checkout Video and Image Blockset license.'; 
    end    
end