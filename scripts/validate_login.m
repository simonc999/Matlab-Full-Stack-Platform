function ok = validate_login(user, pass, dbfile)
    ok = false;

    if isempty(strtrim(user)) || isempty(strtrim(pass))
        fprintf('❌ Username o password vuoti. Riprova.\n');
        return;
    end

    if ~isfile(dbfile)
        fprintf('❌ Database non trovato: %s\n', dbfile);
        return;
    end

    passhash = hash_str(pass);

    % Query SQL
    sql = sprintf(['SELECT 1 FROM users WHERE username = ''%s'' ', ...
                   'AND passhash = ''%s'' LIMIT 1;'], user, passhash);

    cmd = sprintf('sqlite3 "%s" "%s"', dbfile, sql);
    [status, result] = system(cmd);

    if status ~= 0
        fprintf('❌ Errore durante accesso al database.\n');
        return;
    end

    if ~isempty(strtrim(result))
        ok = true;
    else
        fprintf('❌ Username o password errati.\n');
    end
end
