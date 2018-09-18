% This class is for internal use only and may change in the future.

function status = trainOCR(language, trainingImages, trainingData, varargin)

import vision.internal.ocr.*

params = parseInputs(varargin{:});

fontnames = {trainingImages(:).Description};

outputdir = fullfile(params.OutputDirectory, language);

if ~isdir(outputdir)
    mkdir(outputdir)
end

% setup wait bar
if params.DisplayWaitbar
    count = sum([trainingImages(:).Count]);
    waitbar = vision.internal.uitools.ImageSetProgressBar(count,...
        'vision:ocrTrainer:TrainingProgressTitle',...
        'vision:ocrTrainer:TrainingProgressMsg');
    updateWaitbar = @()update(waitbar);
else
    waitbar = [];
    updateWaitbar = @()[]; % no-op
end

% generate box and tr files for each image.
boxFiles = {};
trFiles  = {};

% status reporting struct
status = struct('failedImages', '');

runTwice = false; % work around for handling tesseract asserts

for i = 1:numel(trainingImages) % array of imageSet, 1 per font
                
    for j = 1:trainingImages(i).Count
        
        updateWaitbar();
        
        try
            I = read(trainingImages(i),j);
            
            baseFilename = sprintf('%s.%s.exp%d',language, fontnames{i},j);
            
            % write box file given training boxes. These boxes are assumed to have
            % been manually verified using the OCR training app or through some
            % other means.
            boxFile = fullfile(outputdir, [baseFilename '.box']);
            vision.internal.ocr.writeBoxFile(boxFile, trainingData(j), size(I));
            
            
            % Train tesseract using box files and produce TR file.
           
            trFile  = fullfile(outputdir, baseFilename);
            vision.internal.ocr.applyBox(I, boxFile, trFile);
            
            if runTwice
                % an internal error occurred in tesseract. run again to
                % make sure things are reset.
                vision.internal.ocr.applyBox(I, boxFile, trFile);
                runTwice = false;
            end
            
            % Tesseract may fail to create a TR file for an image.
            if exist(strcat(trFile,'.tr'),'file') == 2                
                trFiles  = [trFiles trFile]; 
            else
                status.failedImages{end+1} = trainingImages(i).ImageLocation{j};
            end
            
        catch
            
            % Catch asserts from tesseract. Force next run to run twice to
            % makesure things are reset. Not ideal solution, but works.
            runTwice = true;
            status.failedImages{end+1} = trainingImages(i).ImageLocation{j};            
            continue;
        end
        
        boxFiles = [boxFiles boxFile];
           
    end
end

delete(waitbar);

% add .tr extension
trFiles = strcat(trFiles, '.tr');

checkIfFilesExist(trFiles);

deleteTRAndBoxFiles = onCleanup(@()deleteFiles([boxFiles trFiles]));

% write font properties file
vision.internal.ocr.writeFontProperties(fontnames, outputdir, params.FontProperties);
fontPropertiesFile = fullfile(outputdir, 'font_properties');
checkIfFilesExist(fontPropertiesFile);

deleteFontProps = onCleanup(@()deleteFiles(fontPropertiesFile));

% write unicharset file
tesseractUnicharsetExtractor(outputdir,boxFiles{:}); 
unicharsetFile = fullfile(outputdir, 'unicharset');
checkIfFilesExist(unicharsetFile);

deleteUniCharset = onCleanup(@()deleteFiles(unicharsetFile));

if params.IsIndicLanguage
    % run shapeclustering, only for Indic languages. Produces shapetable.
    tesseractClustering('shapeclustering', ...
        '-D', outputdir, ...
        '-F', fontPropertiesFile, ...
        '-U', unicharsetFile, ...
        trFiles{:});
    
    shapeFile = {fullfile(outputdir,'shapetable')};
    
    checkIfFilesExist(shapeFile);
   
    deleteShapeTable = onCleanup(@()deleteFiles(shapefile));
end

langUnicharset = fullfile(outputdir, sprintf('%s.unicharset',language));

% Run mftraining. Produces inttemp, shapetable, and pffmtable and
% lang.unicharset.
tesseractClustering('mftraining', ...
    '-D', outputdir, ...
    '-F', fontPropertiesFile, ...
    '-U', unicharsetFile, ...
    '-O', langUnicharset, ...  % this is given to combine_tessdata
    trFiles{:});

mftrainingOutputFiles = {'shapetable', 'inttemp', 'pffmtable'};

checkIfFilesExist(fullfile(outputdir, mftrainingOutputFiles));
checkIfFilesExist(langUnicharset);

shapetableFile = addLangPrefixToFile(language, outputdir, 'shapetable');
inttempFile    = addLangPrefixToFile(language, outputdir, 'inttemp');
pffmtableFile  = addLangPrefixToFile(language, outputdir, 'pffmtable');

deleteMFTFiles = onCleanup(@()deleteFiles({langUnicharset, shapetableFile...
    inttempFile, pffmtableFile}));

% Run cntraining. Produces normproto file.
tesseractClustering('cntraining', ...
    '-D', outputdir, ...    
    trFiles{:});

checkIfFilesExist(fullfile(outputdir,'normproto'));

normprotoFile = addLangPrefixToFile(language, outputdir, 'normproto');

deleteNormProto = onCleanup(@()deleteFiles(normprotoFile));

% data dictionary

% unicharambigs

% covert all the intermediate files to expected names
tessdata = fullfile(outputdir,'tessdata');

if ~isdir(tessdata)
    mkdir(tessdata);
end

tesseractCombineTessdata(fullfile(outputdir,language), fullfile(tessdata,language));

checkIfFilesExist(strcat(fullfile(tessdata,language),'.traineddata'));
 
% -------------------------------------------------------------------------
function dst = addLangPrefixToFile(language, outputdir, src)

dst = [language '.' src];
src = fullfile(outputdir, src);
dst = fullfile(outputdir, dst);

movefile(src, dst);

% -------------------------------------------------------------------------
function checkIfFilesExist(files)

files = cellstr(files);
filesExist = cellfun(@(x)exist(x,'file') == 2, files);

if ~all(filesExist)
    missing = files(~filesExist);
    list = sprintf('%s\n ', missing{:});
    error('Failed to create %s.', list);
end
    
% -------------------------------------------------------------------------
function params = parseInputs(varargin)

p = inputParser;
p.addParameter('FontProperties', [], @isstruct);
p.addParameter('OutputDirectory', pwd, @ischar);
p.addParameter('IsIndicLanguage', false, @(x)vision.internal.inputValidation.validateLogical(x,'IsIndicLanguage'));
p.addParameter('DisplayWaitbar', false, @(x)vision.internal.inputValidation.validateLogical(x,'DisplayWaitbar'));
parse(p, varargin{:});
params = p.Results;

%--------------------------------------------------------------------------
function deleteFiles(list)
 
cellfun(@(file)delete(file), cellstr(list));

