# docs/AZURE_SETUP.md
# Setting up Azure App Registration for Power BI API

This is a one-time setup. Takes about 10 minutes.
You need an Azure admin account (or ask your IT admin to do steps 1–4).

---

## Step 1 — Create the App Registration

1. Go to https://portal.azure.com
2. Search for "App registrations" → New registration
3. Name: `PowerBI-SAP-Pipeline`
4. Supported account types: Single tenant
5. Click Register

**Save these values** (you'll need them for .env):
- Application (client) ID  →  `PBI_CLIENT_ID`
- Directory (tenant) ID    →  `PBI_TENANT_ID`

---

## Step 2 — Create a Client Secret

1. In your new app → Certificates & secrets → New client secret
2. Description: `pipeline-secret`
3. Expires: 24 months (set a calendar reminder to renew)
4. Click Add

**Copy the secret VALUE immediately** (it won't show again):
- Secret value  →  `PBI_CLIENT_SECRET`

---

## Step 3 — Add Power BI API Permissions

1. In your app → API permissions → Add a permission
2. Select: Power BI Service
3. Select: Application permissions (not Delegated)
4. Check these permissions:
   - `Dataset.ReadWrite.All`
   - `Workspace.Read.All`
5. Click Add permissions
6. Click "Grant admin consent for [your org]" → Yes

---

## Step 4 — Enable Service Principals in Power BI

This must be done by a Power BI admin:

1. Go to app.powerbi.com → Settings (gear icon, top right)
2. Admin portal → Tenant settings
3. Find "Allow service principals to use Power BI APIs"
4. Enable it → Apply to: specific security group (or entire org)
5. If using a security group, add your app's service principal to it

---

## Step 5 — Add the App to Your Power BI Workspace

1. Go to app.powerbi.com → open your workspace
2. Workspace settings → Access
3. Add member: paste the `PBI_CLIENT_ID` (Application ID)
4. Role: Member (minimum required for pushing data)
5. Save

---

## Step 6 — Get Your Workspace ID

Look at the URL when you have the workspace open:
```
https://app.powerbi.com/groups/THIS-IS-YOUR-WORKSPACE-ID/list
```
Copy that UUID → `PBI_WORKSPACE_ID`

---

## Done — fill in .env

```
PBI_TENANT_ID=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
PBI_CLIENT_ID=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
PBI_CLIENT_SECRET=your_secret_value
PBI_WORKSPACE_ID=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
```

Then test with:
```bash
python main.py --dry-run
```
