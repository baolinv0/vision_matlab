classdef BlockMatch< matlab.system.SFunSystem
%BlockMatch Block Match

 
%   Copyright 2009-2013 The MathWorks, Inc.

    methods
        function out=BlockMatch
            %BlockMatch Block Match
        end

        function setPortDataTypeConnections(in) %#ok<MANU>
        end

    end
    methods (Abstract)
    end
    properties
        AccumulatorDataType;

        BlockSize;

        CustomAccumulatorDataType;

        CustomOutputDataType;

        CustomProductDataType;

        MatchCriteria;

        MaximumDisplacement;

        OutputDataType;

        OutputValue;

        OverflowAction;

        Overlap;

        ProductDataType;

        ReferenceFrameSource;

        RoundingMethod;

        SearchMethod;

    end
end
