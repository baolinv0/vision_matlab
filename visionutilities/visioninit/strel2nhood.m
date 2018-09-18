function [nhood, nhdims] = strel2nhood(se)
% STREL2NHOOD Helper function used by VIPBLKMORPHOP.
%
% [NHOOD NHDIMS] = STREL2NHOOD(STREL) is used to pre-process the input
%     structuring element.  STREL can be an IPT structuring element object,
%     or a numeric or logical array. NHOOD is a column vector that contains
%     all of the neighborhoods concatinated together. NHDIMS is also a
%     column vector containing the dimensions of the individual 
%     neighborhoods. N=LENGTH(NHDIMS)/2 is the number of neighborhoods.
%     The first N elements of NHDIMS are the row sizes of the neighborhoods
%     and the remaining N elements are the column sizes.

% Copyright 1995-2006 The MathWorks, Inc.
%  $Revision $

% set defaults
nhood  = [];
nhdims = [];

if ~isa(se,'strel') % for further processing, convert to IPT strel object
    
  if isempty(se)
      error(message('vision:vipblkmorphop:strelMustBeNonEmpty'));
  end      
  
  if (~isa(se,'numeric') && ~islogical(se)) || isa(se,'embedded.fi')
      error(message('vision:vipblkmorphop:strelMustBeNumericOrLogical'));
  end
  
  if ndims(se) ~= 2
      error(message('vision:vipblkmorphop:strelMustBe2D'));
  end
    
  se = strel('arbitrary',se);
end

se = getsequence(se);  % try to decompose the strel

if ~all(isflat(se))
    error(message('vision:vipblkmorphop:nonFlatStrel'));
end

strel_is_all_2d = true;
for k = 1:length(se)
  if (ndims(getnhood(se(k))) > 2)
    strel_is_all_2d = false;
    break;
  end
end

if ~strel_is_all_2d
    error(message('vision:vipblkmorphop:non2DStrel'));
end

% extract the neighborhood
num_strels = length(se);
nhdims = zeros(2*num_strels,1,'int32');
nhood = logical([]);
for i=1:num_strels
  nh = getnhood(se(i));
  nhood = [nhood; nh(:)];
  [nhdims(i) nhdims(i+num_strels)] = size(nh);
end

% end of strel2nhood.m
