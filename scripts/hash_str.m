function h = hash_str(s)
    import java.security.MessageDigest
    import java.math.BigInteger

    md = MessageDigest.getInstance('SHA-256');
    md.update(uint8(s));
    hash = md.digest();

    % Conversione corretta in esadecimale con padding
    bi = BigInteger(1, hash);
    h = char(bi.toString(16));

    % Aggiungi zeri a sinistra se mancano
    h = pad(h, 64, 'left', '0');
end
