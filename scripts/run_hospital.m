% Main entry point for the Hospital Management application
clear; clc;
project_root = fileparts(mfilename('fullpath'));
addpath(genpath(fullfile(project_root,'scripts')));
addpath(genpath(fullfile(project_root,'database')));
addpath(genpath(fullfile(project_root,'data')));
addpath(genpath(project_root));

dbfile = fullfile(project_root,'database','hospital.db');
dbdir = fileparts(dbfile);
if ~exist(dbdir, 'dir')
    mkdir(dbdir);
end

initialize_full_db(dbfile);


max_attempts = 3;
for attempt = 1:max_attempts
    credenziali = inputdlg({'Username:', 'Password:'}, 'Login', [1 35]);
    if isempty(credenziali)
        disp('❌ Login annullato.');
        return;
    end
    username = strtrim(credenziali{1});
    password = strtrim(credenziali{2});

    if validate_login(username, password, dbfile)
        disp('✅ Login successful!');
        break;
    end

    if attempt == max_attempts
        error('❌ Troppi tentativi falliti. Bye!');
    end
end

% Main menu loop
while true
    choice = menu('Hospital Management', ...
        'Load hospital data into DB', ...
        'Compute statistics', ...
        'Generate JSON report for ASL', ...
        'Diabetes study module', ...
        'Import Regional ICP/ICM (XML)', ...
        'Exit');
    switch choice
        case 1
            [file, path] = uigetfile({'*.xls;*.xlsx;*.csv','Data files'}, 'Select hospital data file');
            if isequal(file,0), continue; end
            import_hospital_data(fullfile(path,file), dbfile);
        case 2
            compute_stats();
        case 3
            outfile = fullfile(project_root,'export','hospital_report.json');
            export_json();
        case 4
            datafile = fullfile(project_root,'data','glucose_data.txt');
            outfile = fullfile(project_root,'export','diabetes_report.xml');
            diabetes_module();
        case 5
            [file, path] = uigetfile({'*.xml','XML files'}, 'Select Region XML');
            if isequal(file,0), continue; end
            import_region_xml(fullfile(path,file), dbfile);
        otherwise
            disp('Bye!');
            break;
    end
end
