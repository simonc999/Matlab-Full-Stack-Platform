function ok = validate_login(user, pass, dbfile)
    ok = false;

    if isempty(strtrim(user)) || isempty(strtrim(pass))
        fprintf('Empty username or password. Retry.\n');
        return;
    end

    if ~isfile(dbfile)
        fprintf('Db not found: %s\n', dbfile);
        return;
    end

    passhash = hash_str(pass);

    sql = sprintf(['SELECT 1 FROM users WHERE username = ''%s'' ', ...
                   'AND passhash = ''%s'' LIMIT 1;'], user, passhash);

    cmd = sprintf('sqlite3 "%s" "%s"', dbfile, sql);
    [status, result] = system(cmd);

    if status ~= 0
        fprintf('DB access error.\n');
        return;
    end

    if ~isempty(strtrim(result))
        ok = true;
    else
        fprintf('Wrong username or password.\n');
    end
end
