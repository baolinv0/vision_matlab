classdef TrainingImageLabelerSessionManager < vision.internal.uitools.SessionManager
    methods
        %------------------------------------------------------------------
        function this = TrainingImageLabelerSessionManager()
            this = this@vision.internal.uitools.SessionManager();
            this.AppName = 'Training Image Labeler';
            this.SessionField = 'labelingSession';
            this.SessionClass = 'vision.internal.cascadeTrainer.tool.Session';
        end
        
        %------------------------------------------------------------------
        function session = loadSession(this, pathname, filename)
            session = [];
            filename = [pathname, filename];
            
            try 
                % load the MAT file
                temp = load(filename,'-mat');
                
                if isValidSessionFile(this, temp)
                    % Do additional checking on the BoardSet
                    session = temp.(this.SessionField);
                    if isempty(session.FileName)
                        session.FileName = filename;
                    end
                    session.checkImagePaths(pathname, session.FileName); 
                    session.FileName = filename;
                elseif isTableROIs(temp) || isStructROIs(temp)
                    [ROIs, varName] = getROIs(temp);
                    session = vision.internal.cascadeTrainer.tool.Session(...
                        ROIs, pathname, filename);
                    session.ExportVariableName = varName;
                    session.FileName = filename;                    
                else
                    errorMsg = getString(message(this.CustomErrorMsgId, ...
                        filename, this.AppName));
                    dlgTitle = getString(message('vision:uitools:LoadingSessionFailedTitle'));
                    errordlg(errorMsg, dlgTitle, 'modal');
                end
                
            catch loadSessionEx
                session = [];
                if strcmp(loadSessionEx.identifier, 'MATLAB:load:notBinaryFile')
                    errorMsg = getString(message('vision:uitools:invalidSessionFile',...
                        filename, this.AppName));
                else
                    errorMsg = loadSessionEx.message;
                end                

                errordlg(errorMsg, ...
                    getString(message('vision:uitools:LoadingSessionFailedTitle')), ...
                    'modal');
            end            
        end
    end
end

%--------------------------------------------------------------------------
function tf = isTableROIs(s)
fn = fieldnames(s);
tf = (numel(fn) == 1) && istable(s.(fn{1}));
end

%--------------------------------------------------------------------------
function [ROIs, varName] = getROIs(s)
fn = fieldnames(s);
ROIs = s.(fn{1});
varName = fn{1};
end

%--------------------------------------------------------------------------
function tf = isStructROIs(s)
fn = fieldnames(s);
s = s.(fn{1});
tf = isstruct(s) && isfield(s, 'imageFilename') && isfield(s, 'objectBoundingBoxes');
end