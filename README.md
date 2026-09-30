# ScholarTrack — Scholarship Monitoring System

Implements the required Part II workflow: staff login → register scholar and program → submit grades as Pending → verify → automatic `Compliant` / `With Deficiency` result → live dashboard.

## Supabase setup (about 5 minutes)

1. Go to [Supabase](https://supabase.com), create a project, then open **SQL Editor**.
2. Paste and run all contents of `supabase-schema.sql`.
3. In **Authentication → Providers → Email**, enable Email. In **Authentication → Users**, create a staff user (email/password).
4. Copy the user's UUID. In SQL Editor, run this, replacing values:
   ```sql
   insert into public.profiles (id, full_name, role)
   values ('YOUR_AUTH_USER_UUID', 'Your Name', 'admin');
   ```
5. In **Project Settings → API**, copy the Project URL and anon public key into the two constants at the top of `app.js`.
6. Open `index.html` with Live Server, or deploy to GitHub Pages. Sign in with the user created in step 3.

### Rule documented

This prototype uses the Philippine GWA direction: **lower GWA is better**. A record is Compliant only if `GWA ≤ program required GWA`, enrolled units meet the program minimum, failing grades obey the program policy, and there are no incomplete subjects.

## GitHub Pages

Create an empty GitHub repository, then run:

```powershell
git init
git add .
git commit -m "Initialize scholarship monitoring system"
git branch -M main
git remote add origin https://github.com/YOUR-USERNAME/YOUR-REPOSITORY.git
git push -u origin main
```

On GitHub: **Settings → Pages → Deploy from a branch → main / root → Save**. The page URL will be shown there.
