function name = convertAliasToLanguageFullName(lang)
% Convert alias to the full name used for the tesseract language.

%#codegen

name = toName(lang);

%--------------------------------------------------------------------------
function name = toName(alias)

switch alias
    case 'afr'
        name = 'Afrikaans language data for Tesseract';
    case 'sqi'
        name = 'Albanian language data for Tesseract';
    case 'grc'
        name = 'Ancient Greek language data for Tesseract';
    case 'ara'
        name = 'Arabic language data for Tesseract';
    case 'aze'
        name = 'Azerbaijani language data for Tesseract';
    case 'eus'
        name = 'Basque language data for Tesseract';
    case 'bel'
        name = 'Belarusian language data for Tesseract';
    case 'ben'
        name = 'Bengali language data for Tesseract';
    case 'bul'
        name = 'Bulgarian language data for Tesseract';
    case 'cat'
        name = 'Catalan language data for Tesseract';
    case 'chr'
        name = 'Cherokee language data for Tesseract';
    case 'chi_sim'
        name = 'Chinese (simplified) language data for Tesseract';
    case 'chi_tra'
        name = 'Chinese (traditional) language data for Tesseract';
    case 'hrv'
        name = 'Croatian language data for Tesseract';
    case 'ces'
        name = 'Czech language data for Tesseract';
    case 'dan'
        name = 'Danish language data for Tesseract';
    case 'nld'
        name = 'Dutch language data for Tesseract';
    case 'eng'
        name = 'English language data for Tesseract';
    case 'epo'
        name = 'Esperanto language data for Tesseract';
    case 'epo_alt'
        name = 'Esperanto (Alternative) language data for Tesseract';
    case 'est'
        name = 'Estonian language data for Tesseract';
    case 'fin'
        name = 'Finnish language data for Tesseract';
    case 'frk'
        name = 'Frankish language data for Tesseract';
    case 'fra'
        name = 'French language data for Tesseract';
    case 'glg'
        name = 'Galician language data for Tesseract';
    case 'deu'
        name = 'German language data for Tesseract';
    case 'ell'
        name = 'Greek language data for Tesseract';
    case 'heb'
        name = 'Hebrew language data for Tesseract';
    case 'hin'
        name = 'Hindi language data for Tesseract';
    case 'hun'
        name = 'Hungarian language data for Tesseract';
    case 'isl'
        name = 'Icelandic language data for Tesseract';
    case 'ind'
        name = 'Indonesian language data for Tesseract';
    case 'ita'
        name = 'Italian language data for Tesseract';
    case 'ita_old'
        name = 'Italian (Old) language data for Tesseract';
    case 'jpn'
        name = 'Japanese language data for Tesseract';
    case 'kan'
        name = 'Kannada language data for Tesseract';
    case 'kor'
        name = 'Korean language data for Tesseract';
    case 'lav'
        name = 'Latvian language data for Tesseract';
    case 'lit'
        name = 'Lithuanian language data for Tesseract';
    case 'mkd'
        name = 'Macedonian language data for Tesseract';
    case 'msa'
        name = 'Malay language data for Tesseract';
    case 'mal'
        name = 'Malayalam language data for Tesseract';
    case 'mlt'
        name = 'Maltese language data for Tesseract';
    case 'equ'
        name = 'Math/Equation language data for Tesseract';
    case 'enm'
        name = 'Middle English language data for Tesseract';
    case 'frm'
        name = 'Middle French language data for Tesseract';
    case 'nor'
        name = 'Norwegian language data for Tesseract';
    case 'pol'
        name = 'Polish language data for Tesseract';
    case 'por'
        name = 'Portuguese language data for Tesseract';
    case 'ron'
        name = 'Romanian language data for Tesseract';
    case 'rus'
        name = 'Russian language data for Tesseract';
    case 'srp'
        name = 'Serbian (Latin) language data for Tesseract';
    case 'slk'
        name = 'Slovakian language data for Tesseract';
    case 'slv'
        name = 'Slovenian language data for Tesseract';
    case 'spa'
        name = 'Spanish language data for Tesseract';
    case 'spa_old'
        name = 'Spanish (Old) language data for Tesseract';
    case 'swa'
        name = 'Swahili language data for Tesseract';
    case 'swe'
        name = 'Swedish language data for Tesseract';
    case 'tgl'
        name = 'Tagalog language data for Tesseract';
    case 'tam'
        name = 'Tamil language data for Tesseract';
    case 'tel'
        name = 'Telugu language data for Tesseract';
    case 'tha'
        name = 'Thai language data for Tesseract';
    case 'tur'
        name = 'Turkish language data for Tesseract';
    case 'ukr'
        name = 'Ukrainian language data for Tesseract';
end