% Class to manage the ROI label undo-redo activities
% Copyright 2015-2016 The MathWorks, Inc.

classdef UndoRedoManager < handle 
    
    properties (SetAccess = private)
        undoStack = {}; 
        redoStack = {}; 
    end
    
    
    methods
        
        %------------------------------------------------------------------
        % Executes a UndoRedo instance and adds it to the
        % list of undoStack that are available.
       
        function executeCommand(thisObj, roiUndoRedoParamObj)

            roiUndoRedoParamObj.execute();            
            
            % avoid two successive duplicate data entries
            if thisObj.isSameAsPrevious(roiUndoRedoParamObj)
                return;
            end
            
            % push in undoStack
            thisObj.undoStack{end+1} = roiUndoRedoParamObj;
            
            % clear redoStack
            thisObj.redoStack = {}; % see note below
            % NOTE: redoStack is reset once a state changing command (ROI
            % change) is executed.
        end
        
        %------------------------------------------------------------------
        function flag = isSameAsPrevious(thisObj, roiUndoRedoParamObj)
           if thisObj.isUndoStackEmpty()
               flag = false;
           else
               if isequal(thisObj.undoStack{end}, roiUndoRedoParamObj)
                   flag = true;
               else
                   flag = false;
               end
           end
        end
        
        %------------------------------------------------------------------
        function flag = isUndoStackEmpty(thisObj)
            flag = isempty(thisObj.undoStack);
        end
        
        %------------------------------------------------------------------
        function resetUndoRedoBuffer(thisObj)
            thisObj.undoStack = {}; 
            thisObj.redoStack = {}; 
        end        
    
        %------------------------------------------------------------------
        % Returns true if there is at least one undoable Command
        % available on the undo list.
        function flag = isUndoAvailable(thisObj)
            % Here we save current state after the roi is drawn (instead of
            % saving the changes)
            % Also at the beginning we save the state of image (before any
            % ROI changes are made)
            
            flag = length(thisObj.undoStack)>1;
        end
        
        %------------------------------------------------------------------
        % Undoes the next available command to undo. If four commands
        % were executed, the undo operations for those commands will
        % happen in reverse order with four calls to this method.
        %
        % Preconditions:
        %   Undo stack must not be empty

        function undo(thisObj)
            assert(thisObj.isUndoAvailable());
            
            % pop in undoStack
            command = thisObj.undoStack{end}; thisObj.undoStack(end) = []; % 'pop' removes the entry from last cell
            
            command.undo();
            
            % push in redoStack
            thisObj.redoStack{end+1} = command;
        end
        
        %------------------------------------------------------------------
        % Returns true if there is at least one redoable Command
        % available on the redo list.

        function flag = isRedoAvailable(thisObj)
            flag = ~isempty(thisObj.redoStack);
        end
        
        %------------------------------------------------------------------
        % Redoes the next available command to redo.
        %
        % Preconditions:
        %  Redo stack must not be empty

        function redo(thisObj)
            assert(isRedoAvailable(thisObj));
            
            % pop in redoStack
            command = thisObj.redoStack{end}; thisObj.redoStack(end) = []; % 'pop' removes the entry from last cell
            command.execute();
            
            % push in undoStack
            thisObj.undoStack{end+1} = command;
        end
    end
end