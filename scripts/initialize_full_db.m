function initialize_full_db(dbfile)

if ~isfile(dbfile)
    create_schema(dbfile, {'patients','admissions','users'});
    disp('No db found, created new db successfully.');
    return;
end

conn = sqlite(dbfile);
tables = {'patients','admissions'};
hasData = false(1, numel(tables));

for i = 1:numel(tables)
    try
        r = fetch(conn, sprintf('SELECT 1 FROM %s LIMIT 1', tables{i}));
        hasData(i) = ~isempty(r);
    catch
        hasData(i) = false;  
    end
end
close(conn);

if ~any(hasData)
    create_schema(dbfile, {'patients','admissions'});
    disp('No data found, created new db successfully.');
    return;
end

% GUI per scegliere quali tabelle sovrascrivere
toDrop = listdlg( ...
    'PromptString','Data found. Select tables to overwrite:', ...
    'SelectionMode','multiple', ...
    'ListString', tables, ...
    'Name','DB detection', ...
    'ListSize',[250,100]);

if isempty(toDrop)
    disp('No table selected. Using old db.');
    return;
end

create_schema(dbfile, tables(toDrop));
fprintf('Tables overwrited successfully: %s\n', strjoin(tables(toDrop), ', '));
end

function create_schema(dbfile, tablesToCreate)

schema = {};
if any(strcmp(tablesToCreate, 'patients'))
    schema{end+1} = "DROP TABLE IF EXISTS patients;";
    schema{end+1} = ...
    "CREATE TABLE patients (" + ...
    "patient_id TEXT PRIMARY KEY, sex TEXT, age INTEGER);";
end

if any(strcmp(tablesToCreate, 'admissions'))
    schema{end+1} = "DROP TABLE IF EXISTS admissions;";
    schema{end+1} = ...
    "CREATE TABLE admissions (" + ...
    "admission_id INTEGER PRIMARY KEY AUTOINCREMENT," + ...
    "patient_id TEXT," + ...
    "anno TEXT, azienda TEXT, istituto TEXT, disciplina TEXT, progressivo_reparto TEXT," + ...
    "regime_ricovero TEXT, provenienza TEXT, drg TEXT, giornate_degenza INTEGER, accessi_dh INTEGER," + ...
    "importo_lire REAL, data_dimissione TEXT, comune_residenza TEXT, eta INTEGER, sesso TEXT," + ...
    "diag_principale TEXT, diag_c1 TEXT, diag_c2 TEXT, diag_c3 TEXT, diag_c4 TEXT," + ...
    "proc_p TEXT, proc_s1 TEXT, proc_s2 TEXT, proc_s3 TEXT, proc_s4 TEXT," + ...
    "modalita_accesso TEXT, modalita_dimissione TEXT, tipo_ricovero TEXT," + ...
    "data_ingresso TEXT, tipo_prescrittore TEXT, reimbursement_eur REAL," + ...
    "FOREIGN KEY(patient_id) REFERENCES patients(patient_id));";
end

if any(strcmp(tablesToCreate, 'users'))
    schema{end+1} = "DROP TABLE IF EXISTS users;";
    schema{end+1} = ...
    "CREATE TABLE users (" + ...
    "username TEXT PRIMARY KEY, passhash TEXT);";
    schema{end+1} = ...
    "INSERT OR IGNORE INTO users VALUES ('admin', " + ...
    "'8c6976e5b5410415bde908bd4dee15dfb167a9c873fc4bb8a81f6f2ab448a918');"; % admin
end

fid = fopen('temp_schema.sql', 'w');
fprintf(fid, '%s\n', schema{:});
fclose(fid);

system(sprintf('sqlite3 "%s" < temp_schema.sql', dbfile));
delete temp_schema.sql;
end
