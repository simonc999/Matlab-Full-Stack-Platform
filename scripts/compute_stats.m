function compute_stats()
%% Scegli file .db  oppure .xls(x)  e calcola tutte le statistiche richieste

[file, path] = uigetfile({'*.db;*.xls;*.xlsx','Dati ospedale'}, 'Seleziona db o Excel');
if isequal(file,0), return; end
f = fullfile(path,file);
[outDir,~] = fileparts(f);
statsDir   = fullfile(outDir,[erase(file, '.'), '_stats']);
if ~isfolder(statsDir), mkdir(statsDir); end

[~,~,ext] = fileparts(f);
isDB = strcmpi(ext,'.db');

if isDB
    conn = sqlite(f);
    T = fetch(conn,'SELECT * FROM admissions');  % restituisce una tabella direttamente

    close(conn);
    T.reimbursement_eur = T{:,11} ./ 1936.27;   % lire → €
    
    %--- mappa Var1-Var31 → nomi corti usati nello schema/STAT ---
    
else
    T = readtable(f,'PreserveVariableNames',true);
    T.reimbursement_eur = T{:,11} ./ 1936.27;   % lire → €
    
    %--- mappa Var1-Var31 → nomi corti usati nello schema/STAT ---
    old = compose("Var%d",1:31);
    new = ["anno","azienda","istituto","disciplina","progressivo_reparto", ...
           "regime_ricovero","provenienza","drg","giornate_degenza", ...
           "accessi_dh","importo_lire","data_dimissione","comune_residenza", ...
           "eta","sesso","diag_principale","diag_c1","diag_c2","diag_c3","diag_c4", ...
           "proc_p","proc_s1","proc_s2","proc_s3","proc_s4","modalita_accesso", ...
           "modalita_dimissione","tipo_ricovero","data_ingresso","tipo_prescrittore", ...
           "patient_id"];   % 31 nomi esatti
    
    T = renamevars(T, old, new);

end

%% STATISTICHE -----------------------------------------------------------

% i) distribuzione pazienti per sesso / età
sex = string(T.sesso);
age = T.eta;
sexAgeTbl = groupsummary(table(sex,age),'sex','mean','age');
writetable(sexAgeTbl, fullfile(statsDir,'sex_age.csv'));

% ii) DRG freq e rimborso complessivo e per reparto
drgDept = groupsummary(T,{'disciplina','drg'},'sum','reimbursement_eur','IncludeMissingGroups',true);
writetable(drgDept, fullfile(statsDir,'drg_dept.csv'));

% iii) ICP / ICM per reparto ---------------------------------------------
% somma rimborso per reparto
tmpReimb = varfun(@(x)sum(x,'omitnan'), T, ...
                  'InputVariables','reimbursement_eur', ...
                  'GroupingVariables','disciplina');
tmpReimb.Properties.VariableNames{end} = 'SumReimb';

% somma giornate degenza per reparto
tmpDays  = varfun(@(x)sum(x,'omitnan'), T, ...
                  'InputVariables','giornate_degenza', ...
                  'GroupingVariables','disciplina');
tmpDays.Properties.VariableNames{end} = 'SumDays';

% conteggio ricoveri per reparto
tmpCnt   = groupcounts(T,'disciplina');
tmpCnt.Properties.VariableNames{'GroupCount'} = 'N';

% unisci tabelle e calcola indici
icpTbl = join(join(tmpReimb, tmpDays,'Keys','disciplina'), tmpCnt,'Keys','disciplina');
icpTbl.ICP = icpTbl.SumReimb ./ icpTbl.SumDays;
icpTbl.ICM = icpTbl.SumReimb ./ icpTbl.N;

writetable(icpTbl, fullfile(statsDir,'ICP_ICM.csv'));


% iv) frequenza diagnosi (principali+secondarie) e interventi -------------
diagCols = T(:,16:20);                % colonne diagnosi
procCols = T(:,21:25);                % colonne procedure

% diagnosi
diagAll = string(table2array(diagCols));
diagAll = diagAll(:);
diagAll(diagAll=="") = [];            % elimina vuoti
diagCat = categorical(diagAll);
[diagGroups,~,idxD] = unique(diagCat);
diagCounts = accumarray(idxD,1);
diagTable  = table(string(diagGroups), diagCounts, ...
                   'VariableNames',{'Diagnosi','Frequenza'});
writetable(diagTable, fullfile(statsDir,'diagnosi_freq.csv'));

% procedure
procAll = string(table2array(procCols));
procAll = procAll(:);
procAll(procAll=="") = [];
procCat = categorical(procAll);
[procGroups,~,idxP] = unique(procCat);
procCounts = accumarray(idxP,1);
procTable  = table(string(procGroups), procCounts, ...
                   'VariableNames',{'Procedura','Frequenza'});
writetable(procTable, fullfile(statsDir,'procedure_freq.csv'));


% v) distribuzione dei Day-Hospital per diagnosi principale
if ~isnumeric(T.regime_ricovero)
    T.regime_ricovero = str2double(string(T.regime_ricovero));
end
if ~isnumeric(T.accessi_dh)
    T.accessi_dh = str2double(string(T.accessi_dh));
end

dh = T.regime_ricovero == 2;

dhByDiag = groupsummary(T(dh,:), 'diag_principale','sum','accessi_dh','IncludeMissingGroups',true);
writetable(dhByDiag, fullfile(statsDir,'day_hosp_by_diag.csv'));

% vi) frequenza modalità di dimissione
mod_dim = string(T.modalita_dimissione);
mod_dim = mod_dim(~ismissing(mod_dim));  % rimuove eventuali missing
[labels, counts] = groupcounts(categorical(mod_dim));
tbl = table(string(labels), counts, 'VariableNames', {'ModalitaDimissione','Frequenza'});


writetable(tbl, fullfile(statsDir,'dimissioni_freq.csv'));



disp(['✅ Statistiche calcolate e salvate in ', statsDir]);
end
