function userCanceled = undoRunDialog(groupName, instanceName)
%undoRunDialog(grpName, instanceName) populates and manages a dialog
%displaying what happens on undo run. The dialog is positioned w.r.t. the
%toolgroup specified by grpName and syncs to settings for the
%groundTruthLabeler or imageLabeler app specified by instanceName.

% Copyright 2016-2017 The MathWorks, Inc.

userCanceled = true;
checkBoxPrefChanged = false;

dlgTitle    = vision.getMessage('vision:labeler:undoRunDlgTitle');
dlgMessage  = vision.getMessage('vision:labeler:undoRunDlgMessage');

dlgSize = [400 200];
dlgPosition = imageslib.internal.apputil.ScreenUtilities.getModalDialogPos(groupName, dlgSize);

% Create dialog
hDlg = dialog('Name', dlgTitle, 'WindowStyle', 'modal', ...
    'Position', dlgPosition', 'tag', 'undoRunDlg', 'Visible', 'on');

% Dialog is positioned using ScreenUtilities, which in edge
% cases may position the dialog off screen under certain
% monitor configurations. Use movegui to bring dialog on screen
% if this is the case.
movegui(hDlg, 'onscreen');

% Set up magic numbers
buttonSize      = [60 20];
textSize        = [340 50];
checkBoxSize    = [340 20];
buttonHalfSpace = 10;
leftOffset      = 30;
bottomOffset    = 10;
vertGap         = 10;

% Add OK button
x = dlgSize(1) / 2 - buttonSize(1) - buttonHalfSpace;
y = bottomOffset;
uicontrol('Parent', hDlg, 'Callback', @onOk, ...
    'Position', [x y buttonSize], 'FontUnits', 'normalized', ...
    'FontSize', 0.6, ...
    'String', vision.getMessage('MATLAB:uistring:popupdialogs:OK'));

% Add Cancel button
x = dlgSize(1) / 2 + buttonHalfSpace;
uicontrol('Parent', hDlg, 'Callback', @onCancel, ...
    'Position', [x y buttonSize], 'FontUnits', 'normalized', ...
    'FontSize', 0.6, ...
    'String', vision.getMessage('MATLAB:uistring:popupdialogs:Cancel'));

% Add Check box
x = leftOffset;
y = y + buttonSize(2) + vertGap;
checkBox = uicontrol('Parent', hDlg, 'Style', 'checkbox', ...
    'Callback', @onCheck, 'Position', [x y checkBoxSize], ...
    'String', vision.getMessage('vision:labeler:DontShowAgain'),...
    'HorizontalAlignment', 'left', 'Value', 0);

% Add Text
x = leftOffset;
y = y + checkBoxSize(2) + vertGap;
uicontrol('Parent', hDlg, 'Style', 'text', ...
    'Position', [x y textSize], 'HorizontalAlignment', 'left', ...
    'String', dlgMessage);

% Update dialog height
hDlg.Position(4) = y + textSize(2) + vertGap;

hDlg.Visible = 'on';
uiwait(hDlg);

%--------------------------------------------------------------
% Nested Callback functions
    function onOk(varargin)
        userCanceled = false;
        
        % Update preference if needed
        if checkBoxPrefChanged
            showDlgFlag = ~checkBox.Value;
            s = settings;
            if strcmpi(instanceName, 'groundTruthLabeler')
                s.driving.groundTruthLabeler.ShowUndoRunDialog.PersonalValue = showDlgFlag;
            elseif strcmpi(instanceName, 'imageLabeler')
                s.vision.imageLabeler.ShowUndoRunDialog.PersonalValue = showDlgFlag;
            end
        end
        close(hDlg);
    end

    function onCancel(varargin)
        userCanceled = true;
        close(hDlg);
    end

    function onCheck(varargin)
        checkBoxPrefChanged = true;
    end
end