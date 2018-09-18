% NullPrinter is part of the vision.internal.MessagePrinter infrastructure.
% It implements the non-verbose printing option.
%
% Example
% ------- 
%   isVerbose = false;
%   printer = vision.internal.MessagePrinter.configure(isVerbose); 
%   printer.print('message');

classdef NullPrinter < vision.internal.MessagePrinter
    methods
        function this = print(this, varargin)
            % empty on purpose
        end
        
        function this = printMessageNoReturn(this,varargin)
            % empty on purpose
        end
        
        function printDoNotEscapePercent(~, varargin)
            % empty on purpose
        end
        
        function linebreak(varargin)
            % empty on purpose
        end
    end
end