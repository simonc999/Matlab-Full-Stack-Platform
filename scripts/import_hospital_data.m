function import_hospital_data(filename, dbfile)

assert(isfile(filename), 'File non trovato.');

T = readtable(filename,'PreserveVariableNames',true);
T.reimbursement_eur = T{:,11}/1936.27;          % l → €

initialize_full_db(dbfile);                   

h = waitbar(0,'Importazione…');

for i = 1:height(T)
    waitbar(i/height(T),h,sprintf('Riga %d di %d',i,height(T)));

    pid = string(T{i,31});                      
    if pid=="",  continue;  end

    sex = string(T{i,15});
    eta = T{i,14};
    system(sprintf( ...
        'sqlite3 "%s" "INSERT OR IGNORE INTO patients VALUES (''%s'',''%s'',%d);"', ...
        dbfile, pid, esc(sex), eta));

    valsCell = cell(1,30);
    for c = 1:30
        v = T{i,c};
        if isnumeric(v)
            if isnan(v)
                valsCell{c} = '''''';           % -> ''
            else
                valsCell{c} = sprintf('''%g''', v);
            end
        else
            valsCell{c} = ['''' esc(string(v)) ''''];
        end
    end
    valsCell = cellfun(@char, valsCell, 'UniformOutput', false);
    vals     = strjoin(valsCell, ',');

    columns =  ...
    "patient_id, anno, azienda, istituto, disciplina, progressivo_reparto," + ...
    "regime_ricovero, provenienza, drg, giornate_degenza, accessi_dh, importo_lire," + ...
    "data_dimissione, comune_residenza, eta, sesso, diag_principale, diag_c1," + ...
    "diag_c2, diag_c3, diag_c4, proc_p, proc_s1, proc_s2, proc_s3, proc_s4," + ...
    "modalita_accesso, modalita_dimissione, tipo_ricovero, data_ingresso," + ...
    "tipo_prescrittore, reimbursement_eur" ;

    sql = sprintf("INSERT INTO admissions (%s) VALUES ('%s',%s,%.2f);", ...
                  columns, pid, vals, T.reimbursement_eur(i));

    system(sprintf('sqlite3 "%s" "%s"', dbfile, sql));
end

close(h);
disp('Import finished.');
end


function s = esc(x)                
s = replace(char(x), '''', '''''');
end
