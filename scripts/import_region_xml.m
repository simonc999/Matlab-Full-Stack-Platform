function import_region_xml(xmlfile, dbfile)
xDoc = xmlread(xmlfile);
ICP = str2double(xDoc.getElementsByTagName('ICP').item(0).getTextContent);
ICM = str2double(xDoc.getElementsByTagName('ICM').item(0).getTextContent);
fprintf('Received Region ICP = %.3f  |  ICM = %.3f\n', ICP, ICM);
conn = sqlite(dbfile);
exec(conn, sprintf('INSERT INTO region_indices (ICP,ICM) VALUES (%.3f,%.3f)', ICP, ICM));
close(conn);
end
