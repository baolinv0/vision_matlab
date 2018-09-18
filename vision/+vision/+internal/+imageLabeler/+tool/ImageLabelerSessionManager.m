classdef ImageLabelerSessionManager < vision.internal.uitools.SessionManager
    methods
        %------------------------------------------------------------------
        function this = ImageLabelerSessionManager()
            this = this@vision.internal.uitools.SessionManager();
            this.AppName = 'Image Labeler';
            this.SessionField = 'imageLabelingSession';
            this.SessionClass = 'vision.internal.imageLabeler.tool.Session';
        end 
        
        %------------------------------------------------------------------
        function session = loadSession(this, pathname, filename)
            session = [];
            
            try 
                % load the MAT file
                fullname = [pathname, filename];
                temp = load(fullname,'-mat');
                
                if isValidSessionFile(this, temp)
                    % image labeler session
                    session = temp.(this.SessionField);
                    if isempty(session.FileName)
                        session.FileName = fullname;
                    end
                    
                    session.checkImagePaths(pathname, session.FileName); 
                    session.FileName = fullname;
                    
                elseif isTrainingImageLabelerSession(this, temp)
                    % training image labeler session. Convert it to image
                    % labeler session.
                    
                    % Issue warning dialog about importing old version.
                    msg = vision.getMessage('vision:imageLabeler:ImportTrainingImageLabelerMsg');
                    dlgTitle = vision.getMessage('vision:imageLabeler:ImportTrainingImageLabelerTitle');
                    dlg = warndlg(msg, dlgTitle, 'modal');
                    uiwait(dlg);
                    
                    tilSessionMngr = vision.internal.cascadeTrainer.tool.TrainingImageLabelerSessionManager();
                    
                    tilSession = tilSessionMngr.loadSession(pathname, filename);
                    
                    session = importTrainingImageLabelerSession(this, tilSession);
                    
                else
                    errorMsg = getString(message(this.CustomErrorMsgId, ...
                        fullname, this.AppName));
                    dlgTitle = getString(message('vision:uitools:LoadingSessionFailedTitle'));
                    errordlg(errorMsg, dlgTitle, 'modal');
                end
                
            catch loadSessionEx
                session = [];
                if strcmp(loadSessionEx.identifier, 'MATLAB:load:notBinaryFile')
                    errorMsg = getString(message('vision:uitools:invalidSessionFile',...
                        fullname, this.AppName));
                else
                    errorMsg = loadSessionEx.message;
                end                

                errordlg(errorMsg, ...
                    getString(message('vision:uitools:LoadingSessionFailedTitle')), ...
                    'modal');
            end            
            
        end
        
        %------------------------------------------------------------------
        function saveSession(this, session, filename)
            
            session.FileName = filename;
            sessionVar = this.SessionField;
            assignSessionVar(sessionVar, session');
                        
            try 
                eval(sprintf('saveSessionData(%s);',sessionVar));
                save(filename, sessionVar);                
                session.IsChanged = false;     
                session.IsPixelLabelChanged = false(size(session.ImageFilenames));
            catch savingEx
                errordlg(savingEx.message, ...
                    vision.getMessage('vision:uitools:SavingSessionFailedTitle'), ...
                    'modal');                
            end
        end
        
        %------------------------------------------------------------------
        function TF = isTrainingImageLabelerSession(~, sessionStruct)
            TF = isfield(sessionStruct, 'labelingSession') && ...
                isa(sessionStruct.labelingSession, 'vision.internal.cascadeTrainer.tool.Session');
        end
        
        %------------------------------------------------------------------
        function session = importTrainingImageLabelerSession(~, tilSession)
            
            session = vision.internal.imageLabeler.tool.Session();
            
            % add ROI Labels
            numROI = tilSession.NumCategories;
            for i = 1:numROI
                labelName = tilSession.getCategoryName(i);
                
                roiLabel = vision.internal.labeler.ROILabel(...
                    labelType.Rectangle, labelName, '');
                
                % Color is NOT imported. 
                
                session.addROILabel(roiLabel);                
            end
            
            % add Images
            filenames = {tilSession.ImageSet.ImageStruct(:).imageFilename};
            session.addImagesToSession(filenames);
            
            % add label data
            numImages = tilSession.getNumImages();
            catset = tilSession.CategorySet;
            
            for i = 1:numImages

                catID = tilSession.ImageSet.ImageStruct(i).catID;
                
                % gather boxes by name
                map = containers.Map; 
                for j = 1:numel(catID)
                    name = catset.CategoryStruct(catID(j)).categoryName; 
                    if isKey(map, name)
                        % stack boxes
                        map(name) = vertcat(map(name), ...
                            tilSession.ImageSet.ImageStruct(i).objectBoundingBoxes(j,:));
                    else
                        map(name) = tilSession.ImageSet.ImageStruct(i).objectBoundingBoxes(j,:);
                    end 
                end
                
                session.addROILabelAnnotations(i, keys(map), values(map))
                
            end
            
        end
    end
end

%--------------------------------------------------------------------------
function assignSessionVar(sessionVar, session)
% unfortunately there is no way to assign a variable in the current
% function's workspace, so we need another level of indirection.
assignin('caller', sessionVar, session');
end