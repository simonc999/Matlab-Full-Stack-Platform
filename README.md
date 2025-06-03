# Matlab-Full-Stack-Platform

A comprehensive platform for ingesting, storing, and analysing hospital diabetes‑related data.  
It bundles:

- **Relational database schema** (`database/schema.sql`) designed for SQLite, centred on patient admissions and glycaemic metrics.  
- **MATLAB® scripts** (`scripts/`) that automate end‑to‑end data handling from loading regional Excel/XML files, through validated import into the database, to interactive and reproducible statistical reports.  
- **Sample/raw data** (`data/`) so you can experiment immediately.  
- **XML Schema** (`schemas/diabetes_report.xsd`) for standardised regional reporting.

---

## Getting started

### Prerequisites

| Requirement | Purpose |
|-------------|---------|
| MATLAB R2020a (or newer) | Executes the automation scripts. No Toolboxes are required beyond **Database Toolbox** when you prefer the high‑level interface. |
| SQLite 3.40+ | Command‑line fallback when you wish to inspect the `*.db` file directly. |
| macOS / Windows / Linux | All scripts are OS‑agnostic (tested on Windows 11 & Ubuntu 24.04). |

### Quick 3‑step demo

1. **Clone** the repository

```bash
git clone https://github.com/<your‑org>/hospital‑diabetes‑toolkit.git
cd hospital‑diabetes‑toolkit
```

2. **Launch MATLAB** and run

```matlab
run_hospital
```

The script will:

- create or open `database/hospital.db`,
- apply the SQL schema,
- prompt you to import one of the sample Excel files (e.g. `data/OSPEDALE1_Reg1.xls`), and
- generate a `*_stats` sub‑folder containing CSV summaries and plots.

3. **Explore** the database

```bash
sqlite3 database/hospital.db ".tables"
```

---

## Repository layout

```
.
├── data/                 # Example source files
│   ├── glucose_data.txt
│   └── OSPEDALE1_Reg1.xls
├── database/
│   └── schema.sql        # Authoritative DDL
├── schemas/
│   └── diabetes_report.xsd
└── scripts/              # MATLAB® automation (see below)
    ├── compute_stats.m
    ├── diabetes_module.m
    ├── export_json.m
    ├── hash_str.m
    ├── import_hospital_data.m
    ├── import_region_xml.m
    ├── initialize_full_db.m
    ├── run_hospital.m
    └── validate_login.m
```

### Key scripts

| Script | Role |
|--------|------|
| **`initialize_full_db.m`** | Creates the SQLite file and migrates to the latest schema. |
| **`import_hospital_data.m`** | One‑click ingestion of supplied Excel worksheets. |
| **`import_region_xml.m`** | Validated XML import compliant with `diabetes_report.xsd`. |
| **`compute_stats.m`** | Produces descriptive statistics, charts, and exports as CSV/JSON. |
| **`export_json.m`** | Lightweight REST‑style data extraction for downstream pipelines. |

---

## Contributing

1. Fork the repo and create your feature branch: `git checkout -b feat/my‑awesome‑thing`
2. Commit your changes with conventional messages.
3. Open a pull request and describe **why** the change is valuable.

Bug reports and feature requests are welcome via GitHub Issues.

---

## Licence

Released under the MIT License – see [`LICENSE`](LICENSE) for full text.

---

## Citation

If you use this toolkit for academic work, please cite:

```
@software{hospital_diabetes_toolkit_2025,
  author  = {simonc999},
  title   = {Hospital Diabetes Data Toolkit},
  year    = {2025},
  url     = {https://github.com/simonc999/Matlab-Full-Stack-Platform}
}
```

