classdef UndoRedoQuickAccessBarMixin < handle
    % Define interface for a display so it can support redo/undo via QAB.
    
    properties
        UndoAction
        RedoAction 
        UndoListener 
        RedoListener
    end
    
    events
        EnableUndo
        EnableRedo
    end
    
    methods(Abstract)
        undo(this)
        redo(this)
    end
    
    methods(Sealed)
        function enableQABUndo(this, TF)
            javaMethodEDT('setEnabled', this.UndoAction, TF);
        end
        
        function enableQABRedo(this, TF)
            javaMethodEDT('setEnabled', this.RedoAction, TF);
        end
    end
end