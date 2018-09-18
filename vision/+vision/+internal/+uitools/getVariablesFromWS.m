function [variable_data, var_name, user_canceled] = getVariablesFromWS(var_types, var_disp_names, varargin)

%   Copyright 2016 The MathWorks, Inc.


narginchk(2, 4);

if nargin == 3
    % client needs to be a figure
    hFig = varargin{1};
    iptcheckhandle(hFig,{'figure'},mfilename,'HCLIENT',1);
end

% Output variables for function scope
variable_data = [];
var_name = '';
cmap_var_name = '';
user_canceled = true;

hImportFig = figure('Toolbar','none',...
    'Menubar','none',...
    'NumberTitle','off',...
    'IntegerHandle','off',...
    'Tag','cvImportFromWS',...
    'Visible','off',...
    'HandleVisibility','callback',...
    'Name',getString(message('images:privateUIString:importFromWorkspace')),...
    'WindowStyle','modal',...
    'Resize','off',...
    'Color',get(0,'FactoryFigureColor'));

% Layout management
fig_height = 360;
fig_width  = 300;
fig_size = [fig_width fig_height];
left_margin = 10;
right_margin = 10;
bottom_margin = 10;
spacing = 5;
default_panel_width = fig_width - left_margin -right_margin;
button_size = [60 25];
b_type = 'none';

last_selected_value = [];

set(hImportFig,'Position',getCenteredPosition);

% Get workspace variables and store variable names for
% accessibility in nested functions
workspace_vars = evalin('base','whos');

custom_bottom_margin = fig_height - 50;
custom_top_margin = 10;
hFilterPanel = createFilterMenu;

custom_bottom_margin = 10;
custom_top_margin = fig_height - custom_bottom_margin - button_size(2);
createButtonPanel;

custom_bottom_margin = custom_bottom_margin + 20 + 2*spacing;
custom_top_margin = 50 + 2*spacing;
display_panels = [];

for  i = 1:length(var_types)
    display_panels(end+1) = createImportPanel(var_types{i});
end

num_of_panels = length(display_panels);


% force to run callback after creation to do some filtering
hAllList = findobj(display_panels(1),'Tag','allList');
if ~isempty(get(hAllList,'String'))
    listSelected(hAllList,[]);
end

set(display_panels(1),'Visible','on');
set(hImportFig,'Visible','on');

all_list_boxes = findobj(hImportFig,'Type','uicontrol','Style','listbox');
set(all_list_boxes,'BackgroundColor','white');

% This blocks until the user explicitly closes the tool.
uiwait(hImportFig);

%-------------------------------
    function pos = getPanelPos
        % Returns the panel Position based on the custom_bottom_margin
        % and custom_top_margin.  Useful for layout mngment
        height = fig_height - custom_bottom_margin - custom_top_margin;
        pos = [left_margin, custom_bottom_margin, default_panel_width, height];
    end

%--------------------------
    function showPanel(src,evt) %#ok<INUSD>
        % Makes the panel associated with the selected image type visible
        
        ind = get(src,'Value');
        
        set(display_panels(ind),'Visible','on');
        set(display_panels(ind ~= 1:num_of_panels),'Visible','off');
        
    end %showPanel

%----------------------------------
    function pos = getCenteredPosition
        % Returns the position of the import dialog
        % centered on the screen.
        
        old_units = get(0,'Units');
        set(0,'Units','Pixels');
        screen_size = get(0,'ScreenSize');
        set(0,'Units', old_units);
        
        lower_left_pos = 0.5 * (screen_size(3:4) - fig_size);
        pos = [lower_left_pos fig_size];
    end % getCenteredPosition


%----------------------------------
    function hPanel = createFilterMenu()
        % Creates the image type selection panel
        
        panelPos = getPanelPos;
        
        hPanel = uipanel('parent',hImportFig,...
            'Units','Pixels',...
            'Tag','filterPanel',...
            'BorderType',b_type,...
            'Position',panelPos);
        
        iptui.internal.setChildColorToMatchParent(hPanel, hImportFig);
        
        hFilterLabel = uicontrol('parent',hPanel,...
            'Style','Text',...
            'String',getString(message('images:privateUIString:filterLabel')),...
            'HorizontalAlignment','left',...
            'Units','pixels');
        
        label_extent = get(hFilterLabel,'extent');
        posY = bottom_margin;
        label_position = [left_margin, posY, label_extent(3:4)];
        
        set(hFilterLabel,'Position',label_position);
        
        iptui.internal.setChildColorToMatchParent(hFilterLabel,hPanel);
        
        variable_type_str = var_disp_names;
        
        max_width = panelPos(3)-left_margin-right_margin-label_extent(3)-spacing;
        pmenu_width = min([panelPos(3)-label_extent(3)-left_margin*2,...
            max_width]);
        
        pmenu_pos = [left_margin + label_extent(3) + spacing,...
            posY,pmenu_width, 20];
        
        hFilterMenu = uicontrol('parent',hPanel,...
            'Style','popupmenu',...
            'Tag','filterPMenu',...
            'Units','pixels',...
            'Callback',@showPanel,...
            'String',variable_type_str,...
            'Position',pmenu_pos);
        
        iptui.internal.setChildColorToMatchParent(hFilterMenu,hPanel);
        
        if ispc
            % Sets the background color for the popup menu to be white
            % This matches with how the imgetfile dialog looks like
            set(hFilterMenu,'BackgroundColor','white');
        end
        
    end %createFilterMenu

%----------------------------------
    function hPanel = createImportPanel(var_type, varargin)
        % Panel that displays all qualifying (image) workspace
        % variables
                
        panelPos = getPanelPos;
        
        hPanel = uipanel('parent',hImportFig,...
            'Tag',sprintf('%sPanel',lower(var_type)),...
            'Units','pixels',...
            'BorderType',b_type,...
            'Position',panelPos,...
            'Visible','off');
        
        iptui.internal.setChildColorToMatchParent(hPanel,hImportFig);
        
        hLabel = uicontrol('parent',hPanel,...
            'Style','text',...
            'Units','pixels',...
            'HorizontalAlignment','left',...
            'String',getString(message('images:privateUIString:imgetvarVariablesLabel')));
        
        iptui.internal.setChildColorToMatchParent(hLabel,hPanel);
        
        label_extent = get(hLabel,'Extent');
        label_posX = left_margin;
        label_posY = panelPos(4) - label_extent(4) - spacing;
        label_width = label_extent(3);
        label_height = label_extent(4);
        label_position = [label_posX label_posY label_width label_height];
        
        set(hLabel,'Position',label_position);
        
        hVarList = uicontrol('parent',hPanel,...
            'Style','listbox',...
            'fontname','Courier',...
            'Value',1,...
            'Units','pixels',...
            'Tag',sprintf('%sList',lower(var_type)));
        
        iptui.internal.setChildColorToMatchParent(hVarList,hPanel);
        
        list_posX = left_margin;
        list_posY = bottom_margin;
        list_width = panelPos(3) - 2*list_posX;
        list_height = panelPos(4) - list_posY - label_height - spacing;
        list_position = [list_posX list_posY list_width list_height];
        
        set(hVarList,'Position',list_position);
        set(hVarList,'Callback',@listSelected);
        
        varInd = [];
        
        if( strcmpi(var_type,'All') )
            for k = 1:length(var_types)
                varInd = [varInd filterWorkspaceVars(workspace_vars,var_types{k})];                    
            end
        else
            varInd = filterWorkspaceVars(workspace_vars,var_type);
        end
        
        iptui.internal.displayVarsInList(workspace_vars(varInd),hVarList);
        
    end %createImportPanel

%-----------------------------
    function listSelected(src,evt) %#ok<INUSD>
        % callback for the  list boxes
        % we disable the colormap panel controls for an RGB image
        
        ind = get(src,'Value');        
        double_click = strcmp(get(hImportFig,'SelectionType'),'open');
        clicked_same_list_item = last_selected_value == ind;
        
        if isempty(clicked_same_list_item)
            clicked_same_list_item = 0;
        end
        
        if double_click && clicked_same_list_item && getVars
            user_canceled = false;
            close(hImportFig);
        else
            set(hImportFig,'SelectionType','normal');
        end
        
        last_selected_value = ind;
        
    end %listSelected

%------------------------------------------------
    function createButtonPanel
        % panel containing the OK and Cancel buttons
        
        panelPos = getPanelPos;
        hButtonPanel = uipanel('parent',hImportFig,...
            'Tag','buttonPanel',...
            'Units','pixels',...
            'Position',panelPos,...
            'BorderType',b_type);
        
        iptui.internal.setChildColorToMatchParent(hButtonPanel,hImportFig);
        
        % add buttons
        button_strs_n_tags = {getString(message('images:commonUIString:ok')), 'okButton';...
            getString(message('images:commonUIString:cancel')),'cancelButton'};
        
        num_of_buttons = length(button_strs_n_tags);
        
        button_spacing = (panelPos(3)-(num_of_buttons * button_size(1)))/(num_of_buttons+1);
        posX = button_spacing;
        posY = 1; %maintain minimum possible gap from bottom panel.
        buttons = zeros(num_of_buttons,1);
        
        for n = 1:num_of_buttons
            buttons(n) = uicontrol('parent',hButtonPanel,...
                'Style','pushbutton',...
                'String',button_strs_n_tags{n,1},...
                'Tag',button_strs_n_tags{n,2});
            
            iptui.internal.setChildColorToMatchParent(buttons(n), hButtonPanel);
            
            set(buttons(n),'Position',[posX, posY, button_size]);
            set(buttons(n),'Callback',@doButtonPress);
            posX = posX + button_size(1) + button_spacing;
            
        end
        
    end % createButtonPanel

%------------------------------
    function doButtonPress(src,evt) %#ok<INUSD>
        % call back function for the OK and Cancel buttons
        tag = get(src,'tag');
        
        switch tag
            case 'okButton'
                
                if getVars
                    user_canceled = false;
                    close(hImportFig);
                end
                
            case 'cancelButton'
                var_name = '';
                cmap_var_name = '';
                close(hImportFig);
                
        end
        
    end %doButtonPress

%------------------------------------------------
    function status = getVars
        
        SUCCESS = true;
        FAILURE = false;
        
        status = SUCCESS; %#ok<NASGU>
        
        % get the listbox in the active display panel
        im_type_menu = findobj(hFilterPanel,'tag','filterPMenu');
        im_type_ind = get(im_type_menu,'Value');
        hVarList = findobj(display_panels(im_type_ind),'Type','uicontrol',...
            'style','listbox');
        list_str = get(hVarList,'String');        
        
        % return if there are no variables listed in current panel
        if isempty(list_str)
            hAllVarList = findobj(display_panels(1),'Type','uicontrol','style','listbox');
            all_str = get(hAllVarList,'String');
            if isempty(all_str)
                error_str = getString(message('vision:labeler:NoRequiredVarInWS'));
            else
                error_str = getString(message('images:privateUIString:noSelectedVariableStr'));
            end
            errordlg(error_str);
            status = FAILURE;
            return;
        end
        
        ind = get(hVarList,'Value');
        
        var_name = strtok(list_str{ind});
                
        [variable_data, eval_passed] = evaluateVariable(var_name);
        status = eval_passed;
        
        
    end %getVars

%----------------------------------------
    function [out, eval_passed] = evaluateVariable(var_name)
        
        eval_passed = true;
        out = [];
        try
            out = evalin('base',sprintf('%s;',var_name));
        catch ME
            errordlg(ME.message)
            eval_passed = false;
        end
        
    end %evaluateVariable
end
%--------------------------------------------------------------------------
function [varIndices] = filterWorkspaceVars(ws_vars, filter)
    varIndices = [];
    for i = 1:numel(ws_vars)
        if isNotEmpty(ws_vars(i)) && isequal(ws_vars(i).class, filter)
            varIndices = [varIndices, i]; %#ok<AGROW>
        end
    end
end

%--------------------------------------------------------------------------
function TF = isNotEmpty(var_struct)
TF = ~any(var_struct.size==0);
end

            