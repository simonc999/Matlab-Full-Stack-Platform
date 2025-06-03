PRAGMA foreign_keys = ON;

CREATE TABLE IF NOT EXISTS patients (
    patient_id INTEGER PRIMARY KEY,
    sex TEXT CHECK (sex IN ('M','F')),
    birth_date TEXT
);

CREATE TABLE IF NOT EXISTS admissions (
    admission_id INTEGER PRIMARY KEY AUTOINCREMENT,
    patient_id INTEGER,
    dept TEXT,
    drg INTEGER,
    primary_diagnosis TEXT,
    secondary_diagnoses TEXT,
    procedures TEXT,
    discharge_status TEXT,
    days_stay INTEGER,
    reimbursement_eur REAL,
    FOREIGN KEY (patient_id) REFERENCES patients(patient_id)
);

CREATE TABLE IF NOT EXISTS region_indices (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    ICP REAL,
    ICM REAL,
    ts DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_adm_drg ON admissions(drg);
CREATE INDEX IF NOT EXISTS idx_pat_sex ON patients(sex);
