function compute_stats()

[file, path] = uigetfile({'*.db;*.xls;*.xlsx','Dati ospedale'}, 'Select db or Excel file');
if isequal(file,0), return; end
f = fullfile(path,file);
[outDir,~] = fileparts(f);
statsDir   = fullfile(outDir,[erase(file, '.'), '_stats']);
if ~isfolder(statsDir), mkdir(statsDir); end

[~,~,ext] = fileparts(f);
isDB = strcmpi(ext,'.db');

if isDB
    conn = sqlite(f);
    T = fetch(conn,'SELECT * FROM admissions'); 
    close(conn);
    T.reimbursement_eur = T{:,11} ./ 1936.27;   % l → €
    
    
else
    T = readtable(f,'PreserveVariableNames',true);
    T.reimbursement_eur = T{:,11} ./ 1936.27;   % l → €
    
    old = compose("Var%d",1:31);
    new = ["anno","azienda","istituto","disciplina","progressivo_reparto", ...
           "regime_ricovero","provenienza","drg","giornate_degenza", ...
           "accessi_dh","importo_lire","data_dimissione","comune_residenza", ...
           "eta","sesso","diag_principale","diag_c1","diag_c2","diag_c3","diag_c4", ...
           "proc_p","proc_s1","proc_s2","proc_s3","proc_s4","modalita_accesso", ...
           "modalita_dimissione","tipo_ricovero","data_ingresso","tipo_prescrittore", ...
           "patient_id"];   
    
    T = renamevars(T, old, new);

end

%% STATS -----------------------------------------------------------

% i) sex / age distribution
sex = string(T.sesso);
age = T.eta;
sexAgeTbl = groupsummary(table(sex,age),'sex','mean','age');
writetable(sexAgeTbl, fullfile(statsDir,'sex_age.csv'));

% ii) DRG freq and total reimbursement 
drgDept = groupsummary(T,{'disciplina','drg'},'sum','reimbursement_eur','IncludeMissingGroups',true);
writetable(drgDept, fullfile(statsDir,'drg_dept.csv'));

% iii) ICP / ICM 
tmpReimb = varfun(@(x)sum(x,'omitnan'), T, ...
                  'InputVariables','reimbursement_eur', ...
                  'GroupingVariables','disciplina');
tmpReimb.Properties.VariableNames{end} = 'SumReimb';

tmpDays  = varfun(@(x)sum(x,'omitnan'), T, ...
                  'InputVariables','giornate_degenza', ...
                  'GroupingVariables','disciplina');
tmpDays.Properties.VariableNames{end} = 'SumDays';

tmpCnt   = groupcounts(T,'disciplina');
tmpCnt.Properties.VariableNames{'GroupCount'} = 'N';

icpTbl = join(join(tmpReimb, tmpDays,'Keys','disciplina'), tmpCnt,'Keys','disciplina');
icpTbl.ICP = icpTbl.SumReimb ./ icpTbl.SumDays;
icpTbl.ICM = icpTbl.SumReimb ./ icpTbl.N;

writetable(icpTbl, fullfile(statsDir,'ICP_ICM.csv'));


% iv) freq diagnosis (primary+secondary) and procedures -------------
diagCols = T(:,16:20);              
procCols = T(:,21:25);                
diagAll = string(table2array(diagCols));
diagAll = diagAll(:);
diagAll(diagAll=="") = [];         
diagCat = categorical(diagAll);
[diagGroups,~,idxD] = unique(diagCat);
diagCounts = accumarray(idxD,1);
diagTable  = table(string(diagGroups), diagCounts, ...
                   'VariableNames',{'Diagnosi','Frequenza'});
writetable(diagTable, fullfile(statsDir,'diagnosi_freq.csv'));

procAll = string(table2array(procCols));
procAll = procAll(:);
procAll(procAll=="") = [];
procCat = categorical(procAll);
[procGroups,~,idxP] = unique(procCat);
procCounts = accumarray(idxP,1);
procTable  = table(string(procGroups), procCounts, ...
                   'VariableNames',{'Procedura','Frequenza'});
writetable(procTable, fullfile(statsDir,'procedure_freq.csv'));


% v) Day-Hospital distribution
if ~isnumeric(T.regime_ricovero)
    T.regime_ricovero = str2double(string(T.regime_ricovero));
end
if ~isnumeric(T.accessi_dh)
    T.accessi_dh = str2double(string(T.accessi_dh));
end

dh = T.regime_ricovero == 2;

dhByDiag = groupsummary(T(dh,:), 'diag_principale','sum','accessi_dh','IncludeMissingGroups',true);
writetable(dhByDiag, fullfile(statsDir,'day_hosp_by_diag.csv'));

% vi) freq discharge
mod_dim = string(T.modalita_dimissione);
mod_dim = mod_dim(~ismissing(mod_dim));  
[labels, counts] = groupcounts(categorical(mod_dim));
tbl = table(string(labels), counts, 'VariableNames', {'ModalitaDimissione','Frequenza'});

writetable(tbl, fullfile(statsDir,'dimissioni_freq.csv'));



disp(['Stats ready and saved in ', statsDir]);
end
