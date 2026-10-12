"""
Centralized Category Normalization and Query Service for Local Skill Exchange.

Maintains canonical UI categories, mappings to granular subcategories,
SQL filter generator, and category count aggregator.
"""

from typing import List, Dict, Optional, Tuple
from sqlalchemy import or_, and_, not_
from sqlalchemy.orm import Session
from sqlalchemy.sql.elements import BinaryExpression

PRIMARY_CATEGORIES = [
    "Academics",
    "Languages",
    "Programming & Technology",
    "Professional Skills",
    "Creative Skills",
    "Practical / Life Skills"
]

CATEGORY_SUBCATEGORIES_MAP: Dict[str, List[str]] = {
    "Academics": [
        "Academics",
        "Academic Tutoring, Mathematics & Sciences",
        "Academic Writing, Research & Publishing",
        "Environmental Science, Forestry & Agriculture",
    ],
    "Languages": [
        "Languages",
        "Foreign Languages & Linguistics",
    ],
    "Programming & Technology": [
        "Programming & Technology",
        "Programming & Languages",
        "Programming",
        "AI, Machine Learning & LLMs",
        "Backend & Server Architecture",
        "Cloud Computing & Infrastructure",
        "Cybersecurity & Ethical Hacking",
        "Data Science, Big Data & Analytics",
        "Databases & Storage",
        "DevOps, CI/CD & Observability",
        "Embedded Systems, IoT & Robotics",
        "Emerging Tech",
        "Emerging Tech & Blockchain",
        "Mobile App Development",
        "Mobile Development",
        "Software Testing & Quality Assurance",
        "Web & Frontend Development",
    ],
    "Professional Skills": [
        "Professional Skills",
        "Business, Strategy & Entrepreneurship",
        "Digital Marketing, Advertising & Sales",
        "Finance, Accounting & Wealth Building",
        "Hospitality, Tourism & Event Planning",
        "International Business & Law",
        "Writing, Literature & Communication",
    ],
    "Creative Skills": [
        "Creative Skills",
        "3D Modeling, Animation & Game Development",
        "Audio, Voiceover & Podcasting",
        "Digital Audio Workstation & Synth Mastery",
        "Digital Filmmaking & Screen Production",
        "Fashion Design, Textiles & Styling",
        "Fine Arts, Painting & Sculpture",
        "Game Development Subspecialties",
        "Graphic Design & Visual Arts",
        "Music Production & Audio Engineering",
        "Musical Instruments & Vocal Training",
        "Performing Arts, Dance & Stagecraft",
        "Photography & Videography Production",
        "UI/UX Design & User Research",
    ],
    "Practical / Life Skills": [
        "Practical / Life Skills",
        "Automotive & Motor Engineering",
        "Aviation, Marine & Navigation",
        "Crafts, DIY, Maker & Fabrication",
        "Culinary Arts, Baking & Beverage Craft",
        "Culinary Pastry & Bakery Specialties",
        "Emergency Preparedness & Outdoor Survival",
        "Health, Fitness, Athletics & Wellness",
        "Healthcare, First Aid & Sports Medicine",
        "Personal Development & Life Skills",
        "Personal Finance & Financial Planning",
        "Pet Care, Animal Behavior & Training",
        "Trades & Advanced Fabrication",
        "Trades, Automotive, Home Repair & Gardening",
        "Woodworking & Cabinetry Specializations",
    ]
}

# Reverse lookup for O(1) exact mapping
_REVERSE_MAP: Dict[str, str] = {}
for _primary, _subs in CATEGORY_SUBCATEGORIES_MAP.items():
    for _s in _subs:
        _REVERSE_MAP[_s.strip().lower()] = _primary

# Alias / partial matches
_ALIAS_MAP = {
    "programming": "Programming & Technology",
    "technology": "Programming & Technology",
    "tech": "Programming & Technology",
    "coding": "Programming & Technology",
    "software": "Programming & Technology",
    "web development": "Programming & Technology",
    "mobile development": "Programming & Technology",
    "data science": "Programming & Technology",
    "machine learning": "Programming & Technology",
    "cybersecurity": "Programming & Technology",
    "cloud": "Programming & Technology",
    "language": "Languages",
    "languages": "Languages",
    "foreign language": "Languages",
    "linguistics": "Languages",
    "academic": "Academics",
    "academics": "Academics",
    "math": "Academics",
    "mathematics": "Academics",
    "science": "Academics",
    "professional": "Professional Skills",
    "professional skills": "Professional Skills",
    "business": "Professional Skills",
    "marketing": "Professional Skills",
    "finance": "Professional Skills",
    "management": "Professional Skills",
    "creative": "Creative Skills",
    "creative skills": "Creative Skills",
    "design": "Creative Skills",
    "art": "Creative Skills",
    "arts": "Creative Skills",
    "photography": "Creative Skills",
    "music": "Creative Skills",
    "video": "Creative Skills",
    "practical": "Practical / Life Skills",
    "practical skills": "Practical / Life Skills",
    "life skills": "Practical / Life Skills",
    "practical / life skills": "Practical / Life Skills",
    "practical/life skills": "Practical / Life Skills",
    "fitness": "Practical / Life Skills",
    "cooking": "Practical / Life Skills",
    "culinary": "Practical / Life Skills",
    "gardening": "Practical / Life Skills",
}

def normalize_category(category_name: Optional[str]) -> str:
    """
    Normalizes any database category or subcategory name into one of the 6 canonical categories.
    Falls back to 'General' if no match.
    """
    if not category_name:
        return "General"
    cat_clean = category_name.strip()
    cat_lower = cat_clean.lower()
    
    # 1. Exact match in reverse lookup
    if cat_lower in _REVERSE_MAP:
        return _REVERSE_MAP[cat_lower]
    
    # 2. Match aliases
    if cat_lower in _ALIAS_MAP:
        return _ALIAS_MAP[cat_lower]
        
    # 3. Substring heuristic
    for alias_key, target_primary in _ALIAS_MAP.items():
        if alias_key in cat_lower:
            return target_primary
            
    return cat_clean

def get_subcategories(primary_category: str) -> List[str]:
    """
    Returns the list of subcategories belonging to a primary category.
    """
    norm = normalize_category(primary_category)
    return CATEGORY_SUBCATEGORIES_MAP.get(norm, [primary_category])

def get_test_skill_filter(skill_model):
    """
    Returns an SQLAlchemy condition to filter OUT synthetic test dummy records
    (e.g., Skill_Updated_1234, SkillDirectTestSuccess, Skill_Test).
    Keeps legitimate curriculum skills (like 'Python pytest Framework', 'ACT Comprehensive Test Prep').
    """
    return and_(
        skill_model.name.notilike("Skill_Updated_%"),
        skill_model.name.notilike("SkillDirectTest%"),
        skill_model.name.notilike("Skill_Test%"),
        skill_model.name.notilike("E2E Skill%"),
        skill_model.name.notilike("Test Skill%"),
    )

def build_category_filter_condition(skill_model, category_input: str):
    """
    Builds an SQLAlchemy filter condition matching the selected category.
    Supports comma-separated categories or single category (e.g. 'Languages', 'Programming & Technology').
    """
    if not category_input or category_input.strip() in ("", "All", "all"):
        return None
        
    categories = [c.strip() for c in category_input.split(",") if c.strip() and c.strip() != "All"]
    if not categories:
        return None
        
    conditions = []
    for cat in categories:
        norm = normalize_category(cat)
        subcats = get_subcategories(norm)
        if norm in PRIMARY_CATEGORIES:
            # Precise set of matching subcategories
            conditions.append(skill_model.category.in_(subcats))
        else:
            cat_clauses = [skill_model.category == s for s in subcats]
            cat_clauses.append(skill_model.category.ilike(f"%{cat}%"))
            conditions.append(or_(*cat_clauses))
        
    return or_(*conditions)

def get_category_counts(db: Session, skill_model) -> List[Dict[str, any]]:
    """
    Returns accurate real-data counts for each of the 6 canonical categories.
    """
    test_filter = get_test_skill_filter(skill_model)
    skills = db.query(skill_model.category).filter(test_filter).all()
    
    counts = {cat: 0 for cat in PRIMARY_CATEGORIES}
    counts["All"] = len(skills)
    
    for (raw_cat,) in skills:
        norm = normalize_category(raw_cat)
        if norm in counts:
            counts[norm] += 1
            
    return [
        {"category": "All", "count": counts["All"]},
        *[{"category": cat, "count": counts[cat]} for cat in PRIMARY_CATEGORIES]
    ]
