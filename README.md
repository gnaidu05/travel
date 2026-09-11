# CampusRoute team travel roster

An editable, shared campus-assessment roster combining people, availability, colleges, assignments, assessment/interview dates, nearest airports and railway stations.

## Deploy

1. Create a Supabase project.
2. Run `supabase/migrations/001_initial.sql` in the Supabase SQL editor.
3. Enable Email authentication. For production, configure a company-approved SMTP provider so magic links reach `@capgemini.com` mailboxes.
4. Copy `config.example.js` to `config.js` and add the Supabase project URL and public anon key. The anon key is designed for browser use; database access remains protected by Row Level Security.
5. Add the GitHub Pages URL to Supabase Authentication > URL Configuration.
6. In GitHub, open Settings > Pages and select **GitHub Actions** as the source.

## Import the supplied workbook privately

Employee email addresses must not be committed to this public repository. Prepare and import the workbook locally:

```bash
python scripts/prepare-import.py /path/to/data.xlsx private-import/data.json
SUPABASE_URL=https://PROJECT.supabase.co SUPABASE_SERVICE_ROLE_KEY=YOUR_SERVICE_KEY node scripts/import-data.mjs private-import/data.json
```

The import preserves all original college columns in `source_data`, in addition to normalized fields used by the app. The generated private import file and `.env` are excluded from Git.

## Access model

All application tables use Row Level Security. Authenticated accounts whose email ends in `@capgemini.com` can read and edit. Anonymous visitors cannot read the roster or employee data.
