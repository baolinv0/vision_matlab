function applyBox(I, boxFile, trFile)
% applyBox(I, boxFile, trFile) creates a TR file from the box data in
% boxFile. boxFile can be a full or relative path to a box file and must
% include the .box extension. The name of the TR file is specified in
% trFile and should not include the .tr extension.

% Convert I to uint8 (including binary images to allow tesseract to
% pre-process the image). A flag similar to the PreprocessBinaryImage flag
% in ocr may be added in the future to process binary images as-is.
Iu8 = im2uint8(I);    
I = vision.internal.ocr.convertRGBToGray(Iu8);

% Set variables for ApplyBox step from box.train.stderr
setVariable.tessedit_pageseg_mode         = '3'; 
setVariable.file_type                     = '.bl';
setVariable.textord_fast_pitch_test       = 'T';
setVariable.tessedit_single_match         = '0';
setVariable.tessedit_zero_rejection       = 'T';
setVariable.tessedit_minimal_rejection    = 'F';
setVariable.tessedit_write_rep_codes      = 'F';
setVariable.il1_adaption_test             = '1';
setVariable.edges_children_fix            = 'F';
setVariable.edges_childarea               = '0.65';
setVariable.edges_boxarea                 = '0.9';
setVariable.tessedit_resegment_from_boxes = 'T';
setVariable.tessedit_train_from_boxes     = 'T';
setVariable.textord_no_rejects            = 'T';

% No initialization variables for ApplyBox step
initVariable = [];

language = 'English'; % Tesseract needs the language set even though it does 
                      % not use it.
tessOpts.lang         = vision.internal.ocr.convertLanguageToAlias(language);
tessOpts.tessdata     = vision.internal.ocr.locateTessdataFolder(tessOpts.lang);
tessOpts.setVariable  = setVariable;
tessOpts.initVariable = initVariable;

tesseractApplyBox(tessOpts, I, boxFile, trFile);
