"""
Deletes Firestore profile documents whose UID has no matching Firebase Auth account.

Usage:
  1. Go to Firebase Console → Project Settings → Service Accounts
  2. Click "Generate new private key" and save the JSON file as
     serviceAccountKey.json in the UniLink project root (it is gitignored).
  3. Install the Admin SDK once:
       pip install firebase-admin
  4. Run:
       python tools/cleanup_orphaned_profiles.py

The script is DRY-RUN by default — it prints what it would delete without
actually deleting anything. Pass --delete to perform the real deletion.
"""

import sys
import firebase_admin
from firebase_admin import auth, credentials, firestore

DRY_RUN = "--delete" not in sys.argv

# ── Initialise Admin SDK ──────────────────────────────────────────────────────
cred = credentials.Certificate("serviceAccountKey.json")
firebase_admin.initialize_app(cred)
db = firestore.client()

# ── 1. Collect all Firebase Auth UIDs ────────────────────────────────────────
print("Fetching all Firebase Auth users...")
auth_uids: set[str] = set()
page = auth.list_users()
while page:
    for user in page.users:
        auth_uids.add(user.uid)
    page = page.get_next_page()
print(f"  Found {len(auth_uids)} Auth user(s).")

# ── 2. Collect all Firestore profile document IDs ────────────────────────────
print("Fetching all Firestore profiles...")
profile_docs = db.collection("profiles").stream()
profile_ids: list[str] = [doc.id for doc in profile_docs]
print(f"  Found {len(profile_ids)} profile document(s).")

# ── 3. Find orphans ───────────────────────────────────────────────────────────
orphans = [uid for uid in profile_ids if uid not in auth_uids]
print(f"\n{'[DRY RUN] ' if DRY_RUN else ''}Orphaned profiles: {len(orphans)}")

if not orphans:
    print("Nothing to delete. All profiles have matching Auth accounts.")
    sys.exit(0)

for uid in orphans:
    print(f"  {'Would delete' if DRY_RUN else 'Deleting'}: profiles/{uid}")

# ── 4. Delete (only if --delete flag is passed) ───────────────────────────────
if DRY_RUN:
    print("\nRe-run with --delete to permanently remove these profiles.")
else:
    batch = db.batch()
    for uid in orphans:
        batch.delete(db.collection("profiles").document(uid))
    batch.commit()
    print(f"\nDeleted {len(orphans)} orphaned profile(s).")
