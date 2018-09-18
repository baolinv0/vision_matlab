function alias = convertLanguageToAlias(lang)
% Convert language string to the shorter alias used for naming the
% traineddata file for that language.

%#codegen

if iscell(lang)
    alias = cell(1,numel(lang));
    for i = coder.unroll(1:numel(lang))
        alias{i} = toAlias(lang{i}); %#ok<EMCA>
    end
    
    % tesseract requires '+' between multiple alias strings
    alias = strjoin(alias,'+');
    
else
    alias = toAlias(lang);
end

%--------------------------------------------------------------------------
function alias = toAlias(lang)

loweredLang = lower(lang);

if strcmpi(loweredLang, 'english')
    alias = 'eng';
elseif strcmpi(loweredLang, 'japanese')
    alias = 'jpn';
elseif strcmpi(loweredLang, 'afrikaans')
    alias = 'afr';
elseif strcmpi(loweredLang, 'albanian')
    alias = 'sqi';
elseif strcmpi(loweredLang, 'ancientgreek')
    alias = 'grc';
elseif strcmpi(loweredLang, 'arabic')
    alias = 'ara';
elseif strcmpi(loweredLang, 'azerbaijani')
    alias = 'aze';
elseif strcmpi(loweredLang, 'basque')
    alias = 'eus';
elseif strcmpi(loweredLang, 'belarusian')
    alias = 'bel';
elseif strcmpi(loweredLang, 'bengali')
    alias = 'ben';
elseif strcmpi(loweredLang, 'bulgarian')
    alias = 'bul';
elseif strcmpi(loweredLang, 'catalan')
    alias = 'cat';
elseif strcmpi(loweredLang, 'cherokee')
    alias = 'chr';
elseif strcmpi(loweredLang, 'chinesesimplified')
    alias = 'chi_sim';
elseif strcmpi(loweredLang, 'chinesetraditional')
    alias = 'chi_tra';
elseif strcmpi(loweredLang, 'croatian')
    alias = 'hrv';
elseif strcmpi(loweredLang, 'czech')
    alias = 'ces';
elseif strcmpi(loweredLang, 'danish')
    alias = 'dan';
elseif strcmpi(loweredLang, 'dutch')
    alias = 'nld';
elseif strcmpi(loweredLang, 'esperanto')
    alias = 'epo';
elseif strcmpi(loweredLang, 'esperantoalternative')
    alias = 'epo_alt';
elseif strcmpi(loweredLang, 'estonian')
    alias = 'est';
elseif strcmpi(loweredLang, 'finnish')
    alias = 'fin';
elseif strcmpi(loweredLang, 'frankish')
    alias = 'frk';
elseif strcmpi(loweredLang, 'french')
    alias = 'fra';
elseif strcmpi(loweredLang, 'galician')
    alias = 'glg';
elseif strcmpi(loweredLang, 'german')
    alias = 'deu';
elseif strcmpi(loweredLang, 'greek')
    alias = 'ell';
elseif strcmpi(loweredLang, 'hebrew')
    alias = 'heb';
elseif strcmpi(loweredLang, 'hindi')
    alias = 'hin';
elseif strcmpi(loweredLang, 'hungarian')
    alias = 'hun';
elseif strcmpi(loweredLang, 'icelandic')
    alias = 'isl';
elseif strcmpi(loweredLang, 'indonesian')
    alias = 'ind';
elseif strcmpi(loweredLang, 'italian')
    alias = 'ita';
elseif strcmpi(loweredLang, 'italianold')
    alias = 'ita_old';
elseif strcmpi(loweredLang, 'kannada')
    alias = 'kan';
elseif strcmpi(loweredLang, 'korean')
    alias = 'kor';
elseif strcmpi(loweredLang, 'latvian')
    alias = 'lav';
elseif strcmpi(loweredLang, 'lithuanian')
    alias = 'lit';
elseif strcmpi(loweredLang, 'macedonian')
    alias = 'mkd';
elseif strcmpi(loweredLang, 'malay')
    alias = 'msa';
elseif strcmpi(loweredLang, 'malayalam')
    alias = 'mal';
elseif strcmpi(loweredLang, 'maltese')
    alias = 'mlt';
elseif strcmpi(loweredLang, 'mathequation')
    alias = 'equ';
elseif strcmpi(loweredLang, 'middleenglish')
    alias = 'enm';
elseif strcmpi(loweredLang, 'middlefrench')
    alias = 'frm';
elseif strcmpi(loweredLang, 'norwegian')
    alias = 'nor';
elseif strcmpi(loweredLang, 'polish')
    alias = 'pol';
elseif strcmpi(loweredLang, 'portuguese')
    alias = 'por';
elseif strcmpi(loweredLang, 'romanian')
    alias = 'ron';
elseif strcmpi(loweredLang, 'russian')
    alias = 'rus';
elseif strcmpi(loweredLang, 'serbianlatin')
    alias = 'srp';
elseif strcmpi(loweredLang, 'slovakian')
    alias = 'slk';
elseif strcmpi(loweredLang, 'slovenian')
    alias = 'slv';
elseif strcmpi(loweredLang, 'spanish')
    alias = 'spa';
elseif strcmpi(loweredLang, 'spanishold')
    alias = 'spa_old';
elseif strcmpi(loweredLang, 'swahili')
    alias = 'swa';
elseif strcmpi(loweredLang, 'swedish')
    alias = 'swe';
elseif strcmpi(loweredLang, 'tagalog')
    alias = 'tgl';
elseif strcmpi(loweredLang, 'tamil')
    alias = 'tam';
elseif strcmpi(loweredLang, 'telugu')
    alias = 'tel';
elseif strcmpi(loweredLang, 'thai')
    alias = 'tha';
elseif strcmpi(loweredLang, 'turkish')
    alias = 'tur';
elseif strcmpi(loweredLang, 'ukrainian')
    alias = 'ukr';
else
    alias = lang;
end

