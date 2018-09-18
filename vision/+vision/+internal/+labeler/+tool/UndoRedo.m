% An abstract class that defines the interface for undo-redo commands

% Copyright 2015-2016 The MathWorks, Inc.

classdef UndoRedo < handle
    methods (Abstract)
        execute(obj)
        undo(obj)
    end
end
