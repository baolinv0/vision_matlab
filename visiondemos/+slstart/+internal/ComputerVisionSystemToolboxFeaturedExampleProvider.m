classdef ComputerVisionSystemToolboxFeaturedExampleProvider < slstart.internal.FeaturedExampleProvider
    % Featured Examples for the Computer Vision System Toolbox

    % Copyright 2015 The MathWorks, Inc.

    properties (GetAccess = public, SetAccess = private)
        % The customer visible product name this example ships with
        Product = 'Computer Vision System Toolbox';

        % The short name for this product as used by the Help Browser.
        ProductShortName = 'vision';

        % Featured examples in this product
        FeaturedExamples = {'vipldws',...
            'viptrafficExample',...
            'vipmosaicking',...
            'vipwarningsigns'};
    end
end
