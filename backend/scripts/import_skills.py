import os
import sys
import csv

sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

from app.db.database import SessionLocal
from app.db.models import Skill

DATA_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', 'data', 'skills'))
CSV_FILE = os.path.join(DATA_DIR, 'skills_dataset.csv')

def import_skills():
    if not os.path.exists(CSV_FILE):
        print(f'CSV file not found at {CSV_FILE}')
        return
        
    db = SessionLocal()
    try:
        existing_skills = db.query(Skill).all()
        existing_dict = {s.name.lower(): s for s in existing_skills}
        
        added = 0
        updated = 0
        
        with open(CSV_FILE, mode='r', newline='', encoding='utf-8') as f:
            reader = csv.DictReader(f)
            for row in reader:
                name = row['name'].strip()
                category = row['category'].strip()
                key = name.lower()
                
                if key in existing_dict:
                    skill_obj = existing_dict[key]
                    if skill_obj.category != category and skill_obj.category == 'General':
                        skill_obj.category = category
                        updated += 1
                else:
                    new_skill = Skill(name=name, category=category)
                    db.add(new_skill)
                    existing_dict[key] = new_skill
                    added += 1
                    
        db.commit()
        total = db.query(Skill).count()
        print(f'Skill import complete: Added {added}, Updated {updated}, Total: {total}')
    except Exception as e:
        db.rollback()
        print(f'Error: {e}')
        raise
    finally:
        db.close()

if __name__ == '__main__':
    import_skills()
