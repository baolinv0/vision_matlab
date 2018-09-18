function varargout = vipblkmorphop(varargin)
% VIPBLKMORPHOP Mask dynamic dialog function for Erode/Dilate/Open/Close
%               blocks

% VIPBLKMORPHOP by itself is used to update the mask
%
% [NHOOD NHDIMS] = VIPBLKMORPHOP(STREL) is used to pre-process the input
%     structuring element.  STREL can be an IPT structuring element object,
%     or a numeric or logical array. NHOOD is a column vector that contains
%     all of the neighborhoods concatinated together. NHDIMS is also a
%     column vector containing the dimensions of the individual 
%     neighborhoods. N=LENGTH(NHDIMS)/2 is the number of neighborhoods.
%     The first N elements of NHDIMS are the row sizes of the neighborhoods
%     and the remaining N elements are the column sizes.

% Copyright 1995-2006 The MathWorks, Inc.
%  $Revision $

blk = gcbh;
nhoodsrc_str = get_param(blk,'nhoodsrc');

if nargin == 0 % handle mask visibilities
  
  % handle visibility options for the erode/dilate block
  maskVis = get_param(blk,'MaskVisibilities');
  oldMaskVis = maskVis;
  
  % indices to the components on the mask
  [nhoodsrc_idx,nhood_idx] = deal(1,2);
  % components which are always on
  maskVis{nhoodsrc_idx} = 'on';
  
  % handle dynamic cases
  if strncmp(nhoodsrc_str,'Input',5)
    maskVis{nhood_idx} = 'off';
  else
    maskVis{nhood_idx} = 'on';
  end
  
  % Change the mask if necessary
  if (~isequal(maskVis, oldMaskVis))
    set_param(blk, 'MaskVisibilities', maskVis);
  end
  
else % process the neighborhood or strel if specified on the mask
  varargout{1} = []; % set default output
  varargout{2} = [];
  if strncmp(nhoodsrc_str,'Speci',5)
    % The sfunction only works with neighborhoods.  If the input is a strel
    % object, check that it's flat and then extract its neighborhood.
    [varargout{1} varargout{2}] = strel2nhood(varargin{1});
  end
end

% end of vipblkmorphop.m

