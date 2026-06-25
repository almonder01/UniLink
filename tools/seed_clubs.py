"""
Seeds the 8 default clubs into Firestore.

Usage:
  1. Make sure serviceAccountKey.json is in the UniLink project root
     (Firebase Console → Project Settings → Service Accounts → Generate key).
  2. Install the Admin SDK once:
       pip install firebase-admin
  3. Run a dry-run to preview what will be written:
       python tools/seed_clubs.py
  4. Actually write to Firestore:
       python tools/seed_clubs.py --write

Flags:
  --write     Commit changes to Firestore (default is dry-run).
  --overwrite Overwrite existing clubs even if they already exist.
              Without this flag, clubs that already exist are skipped.
"""

import argparse
import sys
import os

import firebase_admin
from firebase_admin import credentials, firestore

# ---------------------------------------------------------------------------
# Club data (mirrors lib/services/club_service.dart)
# ---------------------------------------------------------------------------
CLUBS = [
    {
        "id": "cs_club",
        "name": "Computer Science Club",
        "description": (
            "A vibrant community for tech enthusiasts to explore programming, AI, "
            "web development, and innovation. We host weekly coding sessions, "
            "hackathons, and industry talks."
        ),
        "category": "Tech",
        "logo_color": "FF6366F1",
        "manager_name": "Jordan Lee",
        "member_count": 342,
    },
    {
        "id": "chess_club",
        "name": "Chess Club",
        "description": (
            "Sharpen your analytical mind through the timeless game of strategy and "
            "skill. Open to all levels from beginners to tournament players."
        ),
        "category": "Academic",
        "logo_color": "FF10B981",
        "manager_name": "Sam Chen",
        "member_count": 78,
    },
    {
        "id": "photo_soc",
        "name": "Photography Society",
        "description": (
            "Capture life's most beautiful moments through the lens. We do workshops, "
            "photo walks, exhibitions and competitions. All skill levels welcome!"
        ),
        "category": "Arts",
        "logo_color": "FFF59E0B",
        "manager_name": "Maya Patel",
        "member_count": 156,
    },
    {
        "id": "drama_club",
        "name": "Drama Club",
        "description": (
            "Express yourself on the stage and screen. We produce theatre productions, "
            "short films, and improv shows every semester."
        ),
        "category": "Arts",
        "logo_color": "FFEF4444",
        "manager_name": "Chris Wong",
        "member_count": 92,
    },
    {
        "id": "basketball_club",
        "name": "Basketball Club",
        "description": (
            "Competitive and recreational basketball for all students. Join us for "
            "training, inter-university tournaments and social matches."
        ),
        "category": "Sports",
        "logo_color": "FFFF6B35",
        "manager_name": "Tyler Brooks",
        "member_count": 210,
    },
    {
        "id": "mun_club",
        "name": "Model United Nations",
        "description": (
            "Develop leadership, diplomacy, research, and public speaking skills "
            "through MUN conferences. Represent countries, debate global issues, "
            "and build resolutions."
        ),
        "category": "Academic",
        "logo_color": "FF3B82F6",
        "manager_name": "Priya Sharma",
        "member_count": 127,
    },
    {
        "id": "env_club",
        "name": "Environmental Club",
        "description": (
            "Making our campus greener one initiative at a time. We run tree-planting "
            "drives, recycling programs, awareness campaigns and sustainability workshops."
        ),
        "category": "Environment",
        "logo_color": "FF22C55E",
        "manager_name": "Emma Liu",
        "member_count": 88,
    },
    {
        "id": "music_soc",
        "name": "Music Society",
        "description": (
            "Unite through the universal language of music. We host jam sessions, "
            "concerts, songwriting workshops and open mic nights for all genres "
            "and instruments."
        ),
        "category": "Music",
        "logo_color": "FFA855F7",
        "manager_name": "Kai Nakamura",
        "member_count": 175,
    },
]


def main():
    parser = argparse.ArgumentParser(description="Seed clubs into Firestore.")
    parser.add_argument(
        "--write",
        action="store_true",
        help="Commit changes (default: dry-run).",
    )
    parser.add_argument(
        "--overwrite",
        action="store_true",
        help="Overwrite clubs that already exist in Firestore.",
    )
    args = parser.parse_args()

    # Locate serviceAccountKey.json relative to the project root
    script_dir = os.path.dirname(os.path.abspath(__file__))
    key_path = os.path.join(script_dir, "..", "serviceAccountKey.json")
    if not os.path.exists(key_path):
        print(f"ERROR: serviceAccountKey.json not found at {key_path}")
        print("       Download it from Firebase Console → Project Settings → Service Accounts.")
        sys.exit(1)

    cred = credentials.Certificate(key_path)
    firebase_admin.initialize_app(cred)
    db = firestore.client()
    col = db.collection("clubs")

    print(f"{'DRY RUN — ' if not args.write else ''}Seeding {len(CLUBS)} clubs\n")

    to_write = []
    to_skip = []

    for club in CLUBS:
        club_id = club["id"]
        doc_ref = col.document(club_id)
        data = {k: v for k, v in club.items() if k != "id"}

        if not args.overwrite:
            existing = doc_ref.get()
            if existing.exists:
                to_skip.append(club_id)
                continue

        to_write.append((club_id, doc_ref, data))

    if to_skip:
        print(f"Skipping {len(to_skip)} clubs already in Firestore:")
        for cid in to_skip:
            print(f"  • {cid}  (pass --overwrite to update)")
        print()

    if not to_write:
        print("Nothing to write.")
        return

    print(f"{'Would write' if not args.write else 'Writing'} {len(to_write)} clubs:")
    for club_id, _, data in to_write:
        print(f"  • {club_id:20s}  {data['name']}")

    if not args.write:
        print("\nRe-run with --write to commit.")
        return

    print()
    batch = db.batch()
    for _, doc_ref, data in to_write:
        batch.set(doc_ref, data)
    batch.commit()
    print(f"✓ {len(to_write)} clubs written to Firestore.")


if __name__ == "__main__":
    main()
