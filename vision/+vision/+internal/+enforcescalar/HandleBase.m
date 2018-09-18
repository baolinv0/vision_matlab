%#codegen

% Both value and handle versions of are required until codegen supports
% HandleCompatible classes (g930213).

classdef HandleBase < handle
    methods(Abstract, Access=protected)
        enforceNoArray(obj);
    end
    methods(Hidden)
        function objArray = horzcat(obj, varargin) %#ok<*STOUT>
            enforceNoArray(obj);            
        end
        
        function objArray = vertcat(obj, varargin)
            enforceNoArray(obj);            
        end
        
        function objArray = cat(~, varargin)
            enforceNoArray(varargin{1});           
        end
        
        function objArray = repmat(obj, varargin)
            enforceNoArray(obj);            
        end
        %------------------------------------------------------------------
        % Overload subsasgn to error for array formation and
        % parentheses-style indexing
        %------------------------------------------------------------------
        function sobj = subsasgn(obj, s, val)
            switch s(1).type
                case '()'
                    enforceNoArray(obj);
                otherwise
                    sobj = builtin('subsasgn', obj, s, val);
            end
        end
    end
end