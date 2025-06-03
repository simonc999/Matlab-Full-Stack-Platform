function diabetes_module()
% DIABETES_MODULE  Stima modello glucosio, curve simulate e XML per ASL

%% 1. Selezione sorgente dati -------------------------------------------
[file,path] = uigetfile({'*.xls;*.xlsx;*.txt;*.dat;*.db', ...
    'File glucosio o Database'}, 'Seleziona file dati / db');
if isequal(file,0), disp('Operazione annullata.');  return; end
f = fullfile(path,file);
[~,name,ext] = fileparts(f);
isDB = strcmpi(ext,'.db');

%% 2. Caricamento dati paziente-tempo-glicemia ----------------------------
if isDB
    conn = sqlite(f);
    raw  = fetch(conn,'SELECT patient,time,glucose FROM glucose_data ORDER BY patient,time;');
    close(conn);
    T = cell2table(raw,'VariableNames',{'patient','time','glucose'});
else
    % lettura file testo / Excel
    T = readtable(f,'FileType','text','Delimiter',{' ','\t',','}, ...
                  'ReadVariableNames',true);

    % se non riconosce i nomi in italiano, mettili tu
    if ~all(ismember({'paziente','tempo','glucosio'}, lower(T.Properties.VariableNames)))
        % file senza header: Var1 Var2 Var3
        T.Properties.VariableNames = {'paziente','tempo','glucosio'};
    else
        % normalizza comunque in minuscolo
        T = renamevars(T, T.Properties.VariableNames, ...
                          lower(T.Properties.VariableNames));
    end

    % uniforma i nomi a 'patient','time','glucose'
    T = renamevars(T, {'paziente','tempo','glucosio'}, ...
                      {'patient','time','glucose'});
end

%% 3. Preparazione ----------------------------------------------------------------
pids    = unique(T.patient);
if iscell(T.patient) || isstring(T.patient)
    T.patient = str2double(string(T.patient));
end
nPat    = numel(pids);
results = struct([]);

% opzioni lsqcurvefit
model   = @(b,t) b(4) + b(1)*(exp(-b(2)*t)-exp(-b(3)*t)); % b=[A a b g0]
opt     = optimoptions('lsqcurvefit','Display','off');
lb      = [0  0   0  50];      % limiti realistici
ub      = [500 5   5 400];
template = struct('patient_id', [], 'A', [], 'a', [], 'b', [], 'g0', [], ...
                  'peak', [], 't_peak', [], 'auc', [], 't_return5', [], ...
                  'intolerance', []);
results = repmat(template, nPat, 1);

%% 4. Stima parametri e indicatori per ogni paziente ----------------------
for k = 1:nPat
    idx = T.patient == pids(k);
    t   = T.time(idx);
    g   = T.glucose(idx);

    b0  = [30 0.4 0.05 max(60,min(g))];             % iniziali
    b   = lsqcurvefit(model,b0,t,g,lb,ub,opt);       % stima

    g_hat = model(b,t);
    [peak,pi] = max(g_hat);          t_peak = t(pi);
    auc       = trapz(t,g_hat);      % area sotto curva
    % tempo di ritorno: < 5% sopra baseline
    g5  = b(4) * 1.05;
    t_ret = interp1(g_hat,t,g5,'linear','extrap');
    if isnan(t_ret) || t_ret<min(t), t_ret = max(t); end

    % flag intolleranza
    flag_int = (b(4) > 110) || (peak + b(4) > 250);

    results(k).patient_id  = pids(k);
    results(k).A           = b(1);
    results(k).a           = b(2);
    results(k).b           = b(3);
    results(k).g0          = b(4);
    results(k).peak        = peak;
    results(k).t_peak      = t_peak;
    results(k).auc         = auc;
    results(k).t_return5   = t_ret;
    results(k).intolerance = flag_int;
end

%% 5. Simulazione curva media con modello compartimentale -----------------
mean_b = [mean([results.A]) mean([results.a]) mean([results.b]) mean([results.g0])];
Amean  = mean_b(1);  a_mean = mean_b(2);  b_mean = mean_b(3); g0_mean = mean_b(4);

% sistema compartimentale equivalente (k02=a, k21=b, V=(D/A)*(k21/(k21-k02)))
k02 = a_mean;  k21 = b_mean;   D = 10;  V = (D/Amean)*(k21/(k21-k02));
odef = @(t,y) [-k02*y(1) + k21*y(2);  k02*y(1) - k21*y(2)];
y0   = [D/V 0];
[t_sim,y_sim] = ode23(odef, linspace(0,5,100), y0);
g_sim = g0_mean + Amean*(exp(-a_mean*t_sim)-exp(-b_mean*t_sim));

figure('Name','Curva media glucosio'); plot(t_sim,g_sim,'LineWidth',1.4);
xlabel('Tempo (h)'); ylabel('Glucosio (mg/dL)'); grid on;

%% 6. Costruzione XML -----------------------------------------------------
[~,base] = fileparts(f);
outdir   = fullfile(path,[base '_diab']);
if ~exist(outdir,'dir'), mkdir(outdir); end
outfile  = fullfile(outdir,'diabetes_report.xml');

doc = com.mathworks.xml.XMLUtils.createDocument('HospitalDiabetesReport');
root= doc.getDocumentElement;
root.setAttribute('hospital_id','OSPEDALE1');

for k = 1:nPat
    R = results(k);
    pat = doc.createElement('Patient'); pat.setAttribute('id',num2str(R.patient_id));

    mp = doc.createElement('ModelParameters');
    mp.setAttribute('A',  num2str(R.A));
    mp.setAttribute('a',  num2str(R.a));
    mp.setAttribute('b',  num2str(R.b));
    mp.setAttribute('g0', num2str(R.g0));
    pat.appendChild(mp);

    ind = doc.createElement('Indicators');
    ind.setAttribute('peak',       num2str(R.peak));
    ind.setAttribute('t_peak',     num2str(R.t_peak));
    ind.setAttribute('auc',        num2str(R.auc));
    ind.setAttribute('t_return5',  num2str(R.t_return5));
    ind.setAttribute('intolerance',num2str(R.intolerance));
    pat.appendChild(ind);

    root.appendChild(pat);
end

xmlwrite(outfile, doc);
fprintf('✅ Report XML scritto in %s\n', outfile);
end
