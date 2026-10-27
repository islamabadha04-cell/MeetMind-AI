"""
=====================================================
App 4 / 50: Notes App (Python Console Edition)
=====================================================
Ye program aapko choti notes likhne, save karne, 
dekhne, kisi lafz se search karne aur delete karne deta hai.
Data 'notes.json' file mein save hota hai.
"""

import sys
import json
import os
from datetime import datetime

# Windows terminal UTF-8 support
if hasattr(sys.stdout, 'reconfigure'):
    try:
        sys.stdout.reconfigure(encoding='utf-8')
    except Exception:
        pass

NOTES_FILE = "notes.json"


def load_notes():
    """File se purani notes load karta hai."""
    if not os.path.exists(NOTES_FILE):
        default_notes = [
            {
                "id": 1,
                "title": "Cowlar meeting points",
                "content": "Discuss project updates, backend API design, and future timeline.",
                "date": datetime.now().strftime("%Y-%m-%d %H:%M")
            }
        ]
        save_notes(default_notes)
        return default_notes

    try:
        with open(NOTES_FILE, "r", encoding="utf-8") as f:
            return json.load(f)
    except Exception as e:
        print(f"File parhne mein masla: {e}")
        return []


def save_notes(notes):
    """Notes ko 'notes.json' mein save karta hai."""
    try:
        with open(NOTES_FILE, "w", encoding="utf-8") as f:
            json.dump(notes, f, indent=4, ensure_ascii=False)
    except Exception as e:
        print(f"File save karne mein masla: {e}")


def add_note():
    """Nayi note likho aur save karo."""
    print("\n--- [+] NAYI NOTE LIKHEIN ---")
    title = input("Note ka Title likhein (e.g. Cowlar meeting points): ").strip()
    if not title:
        print("[!] Title khali nahi ho sakta!")
        return

    content = input("Note ki Details / Content likhein: ").strip()
    if not content:
        print("[!] Note details khali nahi ho sakti!")
        return

    notes = load_notes()
    
    # Unique ID
    new_id = max([n["id"] for n in notes], default=0) + 1
    new_note = {
        "id": new_id,
        "title": title,
        "content": content,
        "date": datetime.now().strftime("%Y-%m-%d %H:%M")
    }

    notes.append(new_note)
    save_notes(notes)
    print(f"\n[OK] Note '{title}' kamyabi se save ho gayi! (ID: {new_id})")


def view_all_notes():
    """Saari notes ki list dekho."""
    notes = load_notes()
    print("\n--- [LIST] SAARI NOTES KI LIST ---")
    if not notes:
        print("[-] Abhi koi note mojood nahi hai.")
        return

    print(f"Kul Notes: {len(notes)}\n")
    for idx, note in enumerate(notes, start=1):
        print(f"[{idx}] ID: {note['id']} | Title: {note['title']}")
        print(f"    Date   : {note.get('date', 'N/A')}")
        print(f"    Details: {note['content']}")
        print("-" * 50)


def search_notes():
    """Kisi lafz se search karo (e.g. 'meeting')."""
    notes = load_notes()
    if not notes:
        print("\n[-] Notes list khali hai, pehle koi note add karein.")
        return

    keyword = input("\n[?] Search karne ke liye lafz likhein (e.g. 'meeting'): ").strip().lower()
    if not keyword:
        print("[!] Search lafz khali nahi ho sakta!")
        return

    # Search in both title and content
    results = [
        n for n in notes
        if keyword in n["title"].lower() or keyword in n["content"].lower()
    ]

    print(f"\n--- [*] SEARCH RESULTS FOR: '{keyword}' ---")
    if not results:
        print(f"[-] '{keyword}' ke sath koi note nahi mili.")
        return

    print(f"[OK] {len(results)} note(s) mili hain:\n")
    for note in results:
        print(f"ID: {note['id']} | Title: {note['title']}")
        print(f"Date   : {note.get('date', 'N/A')}")
        print(f"Details: {note['content']}")
        print("-" * 50)


def delete_note():
    """Note delete karo."""
    notes = load_notes()
    if not notes:
        print("\n[-] Notes list khali hai, koi note delete karne ko nahi hai.")
        return

    print("\n--- [-] NOTE DELETE KAREIN ---")
    for note in notes:
        print(f"ID {note['id']}: {note['title']}")

    try:
        note_id = int(input("\nDelete karne ke liye Note ki ID likhein: "))
    except ValueError:
        print("[!] Kripya durust number (ID) likhein.")
        return

    note_to_delete = next((n for n in notes if n["id"] == note_id), None)
    if not note_to_delete:
        print(f"[!] ID {note_id} wali koi note nahi mili.")
        return

    confirm = input(f"Kya aap waqai '{note_to_delete['title']}' delete karna chahte hain? (y/n): ").strip().lower()
    if confirm == 'y':
        notes = [n for n in notes if n["id"] != note_id]
        save_notes(notes)
        print(f"[OK] Note '{note_to_delete['title']}' delete kar di gayi!")
    else:
        print("[-] Delete cancel kar diya gaya.")


def main():
    while True:
        print("\n" + "=" * 45)
        print("            NOTES APP (App 4 / 50)")
        print("=" * 45)
        print("1. Nayi Note Likhein aur Save Karein")
        print("2. Saari Notes Dekhein")
        print("3. Kisi Lafz Se Search Karein")
        print("4. Note Delete Karein")
        print("5. Program Band Karein (Exit)")
        print("=" * 45)

        choice = input("Apna intekhab darj karein (1-5): ").strip()

        if choice == "1":
            add_note()
        elif choice == "2":
            view_all_notes()
        elif choice == "3":
            search_notes()
        elif choice == "4":
            delete_note()
        elif choice == "5":
            print("\nShukriya! Notes App band ho raha hai. Khuda Hafiz!\n")
            break
        else:
            print("[!] Ghalat number! 1 se 5 ke darmiyan intekhab karein.")


if __name__ == "__main__":
    main()
