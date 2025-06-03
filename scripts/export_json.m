function export_json()
%% EXPORT_JSON  Produce JSON report per ASL da .db o .xls(x)
[file, path] = uigetfile({'*.db;*.xls;*.xlsx','Database o Excel'}, 'Seleziona file sorgente');
if isequal(file, 0), return; end
f = fullfile(path, file);
[~, name, ext] = fileparts(file);

% Output path
outdir = fullfile(path, [name, '_json']);
if ~exist(outdir, 'dir'); mkdir(outdir); end
outfile = fullfile(outdir, 'report.json');

isDB = strcmpi(ext, '.db');

%% Caricamento dati
if isDB
    conn = sqlite(f);
    rows = fetch(conn, ['SELECT p.patient_id, p.sex, p.age, ', ...
        'a.diag_principale, a.diag_c1 || '';'' || a.diag_c2 || '';'' || a.diag_c3 || '';'' || a.diag_c4 AS secondary_diagnoses, ', ...
        'a.proc_p || '';'' || a.proc_s1 || '';'' || a.proc_s2 || '';'' || a.proc_s3 || '';'' || a.proc_s4 AS procedures, ', ...
        'a.modalita_dimissione, a.drg, a.reimbursement_eur, a.giornate_degenza ', ...
        'FROM admissions a JOIN patients p ON p.patient_id = a.patient_id']);

    close(conn);

    vars = {'patient_id','sex','age','primary_diagnosis','secondary_diagnoses', ...
            'procedures','discharge_status','drg','reimbursement_eur','days_stay'};

    S = cell2struct(table2cell(rows)', vars, 1);

else
    % Leggi Excel
    T = readtable(f, 'PreserveVariableNames', true);

    % Rinomina se ha nomi generici
    if all(startsWith(T.Properties.VariableNames, "Var"))
        old = compose("Var%d", 1:31);
        new = ["anno","azienda","istituto","disciplina","progressivo_reparto", ...
               "regime_ricovero","provenienza","drg","giornate_degenza", ...
               "accessi_dh","importo_lire","data_dimissione","comune_residenza", ...
               "eta","sesso","diag_principale","diag_c1","diag_c2","diag_c3","diag_c4", ...
               "proc_p","proc_s1","proc_s2","proc_s3","proc_s4","modalita_accesso", ...
               "modalita_dimissione","tipo_ricovero","data_ingresso","tipo_prescrittore", ...
               "patient_id"];
        T = renamevars(T, old, new);
    end

    % Crea la struttura
    n = height(T);
    S = struct('patient_id', {}, 'sex', {}, 'age', {}, 'primary_diagnosis', {}, ...
               'secondary_diagnoses', {}, 'procedures', {}, 'discharge_status', {}, ...
               'drg', {}, 'reimbursement_eur', {}, 'days_stay', {});
    for i = 1:n
        sid = string(T.patient_id(i));
        sex = string(T.sesso(i));
        age = T.eta(i);
        pd  = string(T.diag_principale(i));
        sd  = strjoin(string(T{i, ["diag_c1","diag_c2","diag_c3","diag_c4"]}), ';');
        pr  = strjoin(string(T{i, ["proc_p","proc_s1","proc_s2","proc_s3","proc_s4"]}), ';');
        ds  = string(T.modalita_dimissione(i));
        drg = string(T.drg(i));
        reimb = T.importo_lire(i) / 1936.27;
        days  = T.giornate_degenza(i);

        S(i) = struct('patient_id', sid, 'sex', sex, 'age', age, ...
                      'primary_diagnosis', pd, ...
                      'secondary_diagnoses', sd, ...
                      'procedures', pr, ...
                      'discharge_status', ds, ...
                      'drg', drg, ...
                      'reimbursement_eur', reimb, ...
                      'days_stay', days);
    end
end

%% Genera JSON
report = struct('hospital_id', 'OSPEDALE1', 'cases', {S});
jsonStr = jsonencode(report, 'PrettyPrint', true);

fid = fopen(outfile, 'w'); 
fwrite(fid, jsonStr, 'char'); 
fclose(fid);

fprintf('✅ JSON salvato in %s\n', outfile);
end
