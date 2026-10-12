"""
Course Catalog Data & Curricula Generator for Local Skill Exchange
Provides authentic, topic-specific curricula, lessons, verified public resources,
practice questions, and certification quizzes across all student learning categories:
- Academics (Mathematics, Physics, Chemistry, Biology, Computer Science, etc.)
- Languages (Hindi, English, Tamil, Telugu, Spanish, French, German, Japanese, etc.)
- Programming & Technology (Python, Java, C++, JavaScript, Web Dev, Flutter, SQL, React, etc.)
- Professional Skills (Public Speaking, Resume Building, Leadership, Communication, Excel, etc.)
- Creative Skills (Photography, Graphic Design, UI/UX Design, Video Editing, Music, Drawing, etc.)
- Practical / Life Skills (Cooking, Financial Literacy, First Aid, Fitness, etc.)
"""

import urllib.parse
from typing import Dict, Any, List, Optional

CURATED_COURSES: Dict[str, Dict[str, Any]] = {
    "python": {
        "title": "Python Programming — Foundations & Intermediate",
        "description": "Comprehensive student course covering Python syntax, data types, control flow, functions, collections, OOP principles, and robust exception handling.",
        "estimated_minutes": 200,
        "lessons": [
            {
                "order": 1,
                "title": "1. Python Variables, Data Types & Operations",
                "estimated_minutes": 35,
                "summary": "Master core primitive data types (int, float, str, bool), dynamic typing, f-string formatting, type conversions, and arithmetic operators.",
                "content": """# Python Variables, Data Types & Operations

Python is a high-level, interpreted, dynamically typed programming language created by Guido van Rossum.

## 1. Dynamic Typing and Variables
In Python, variables are created automatically when you assign a value:

```python
student_name = "Keerthana"  # str
courses_completed = 4       # int
current_gpa = 3.92          # float
is_enrolled = True          # bool
```

## 2. Type Inspection and Casting
```python
user_input = "150"
credits_count = int(user_input)  # Converted to int: 150
gpa_str = str(current_gpa)       # Converted to str: "3.92"
```

## 3. String Formatting (f-strings)
```python
greeting = f"Welcome {student_name}, you have completed {courses_completed} courses!"
print(greeting)
```

## 4. Arithmetic & Division Operators
- `+`, `-`, `*`
- `/` (Always returns float: `10 / 2` -> `5.0`)
- `//` (Floor division: `10 // 3` -> `3`)
- `%` (Modulus: `10 % 3` -> `1`)
- `**` (Exponentiation: `2 ** 3` -> `8`)
""",
                "video_url": "https://www.youtube.com/watch?v=rfscVS0vtbw",
                "pdf_url": "https://docs.python.org/3/tutorial/introduction.html",
                "doc_url": "https://docs.python.org/3/tutorial/introduction.html",
                "resources": [
                    {
                        "type": "DOCS",
                        "title": "Official Python 3 Tutorial — An Informal Introduction",
                        "url": "https://docs.python.org/3/tutorial/introduction.html",
                        "source": "Python Software Foundation",
                        "duration": 20,
                        "is_primary": True,
                    },
                    {
                        "type": "VIDEO",
                        "title": "Python for Beginners — Full Course (freeCodeCamp)",
                        "url": "https://www.youtube.com/watch?v=rfscVS0vtbw",
                        "source": "YouTube / freeCodeCamp",
                        "duration": 45,
                        "is_primary": False,
                    },
                    {
                        "type": "PDF",
                        "title": "NCERT Computer Science — Python Fundamentals Guide",
                        "url": "https://ncert.nic.in/textbook/pdf/kecs103.pdf",
                        "source": "NCERT Open Educational Resources",
                        "duration": 25,
                        "is_primary": False,
                    },
                ],
                "questions": [
                    {
                        "question": "Which statement correctly creates an integer variable in Python?",
                        "options": [
                            "age = 20",
                            "int age = 20",
                            "integer age = 20",
                            "var age: integer = 20",
                        ],
                        "correct_answer": "age = 20",
                        "explanation": "Python is dynamically typed and does not require type specifiers when declaring variables.",
                    },
                    {
                        "question": "What is the data type of the expression `10 / 2` in Python 3?",
                        "options": [
                            "float",
                            "int",
                            "double",
                            "number",
                        ],
                        "correct_answer": "float",
                        "explanation": "In Python 3, the `/` operator performs true floating-point division and returns 5.0.",
                    },
                    {
                        "question": "A student wants to record whether they have passed a certification exam. Which Python data type is most appropriate?",
                        "options": [
                            "bool",
                            "str",
                            "float",
                            "list",
                        ],
                        "correct_answer": "bool",
                        "explanation": "Boolean (bool) stores binary true/false state, ideal for pass/fail flags.",
                    },
                    {
                        "question": "Which of the following is an invalid Python variable name?",
                        "options": [
                            "2nd_student",
                            "student_2",
                            "_student_count",
                            "totalScore",
                        ],
                        "correct_answer": "2nd_student",
                        "explanation": "Variable names in Python cannot start with a numerical digit.",
                    },
                    {
                        "question": "What will `print(f'Count: {3 + 2}')` output to the console?",
                        "options": [
                            "Count: 5",
                            "Count: {3 + 2}",
                            "Count: 32",
                            "SyntaxError",
                        ],
                        "correct_answer": "Count: 5",
                        "explanation": "Expressions inside curly braces `{}` within f-strings are evaluated at runtime.",
                    },
                ],
            },
            {
                "order": 2,
                "title": "2. Control Flow: Conditionals, Loops & Iteration",
                "estimated_minutes": 40,
                "summary": "Master conditional branching with if/elif/else, iterative execution with for and while loops, range() generators, and loop control statements.",
                "content": """# Control Flow: Conditionals & Iteration

Control flow determines the order in which statements are executed in Python.

## 1. Conditionals
```python
score = 85
if score >= 90:
    grade = "A"
elif score >= 75:
    grade = "B"
else:
    grade = "C"
```

## 2. Iteration with `for` and `while`
```python
for i in range(1, 6):
    print(f"Step #{i}")
```
""",
                "video_url": "https://www.youtube.com/watch?v=_uQrJ0TkZlc",
                "pdf_url": "https://docs.python.org/3/tutorial/controlflow.html",
                "doc_url": "https://docs.python.org/3/tutorial/controlflow.html",
                "resources": [
                    {
                        "type": "DOCS",
                        "title": "Official Python 3 Tutorial — More Control Flow Tools",
                        "url": "https://docs.python.org/3/tutorial/controlflow.html",
                        "source": "Python Software Foundation",
                        "duration": 25,
                        "is_primary": True,
                    },
                    {
                        "type": "VIDEO",
                        "title": "Python Loops and Control Structures Tutorial",
                        "url": "https://www.youtube.com/watch?v=_uQrJ0TkZlc",
                        "source": "YouTube / Programming with Mosh",
                        "duration": 30,
                        "is_primary": False,
                    },
                ],
                "questions": [
                    {
                        "question": "What is the output of `list(range(1, 5))` in Python?",
                        "options": [
                            "[1, 2, 3, 4]",
                            "[1, 2, 3, 4, 5]",
                            "[0, 1, 2, 3, 4]",
                            "[2, 3, 4, 5]",
                        ],
                        "correct_answer": "[1, 2, 3, 4]",
                        "explanation": "`range(start, stop)` stops before reaching the stop value (stop is exclusive).",
                    },
                    {
                        "question": "Which keyword is used to skip the rest of the current loop iteration and continue with the next?",
                        "options": [
                            "continue",
                            "break",
                            "skip",
                            "pass",
                        ],
                        "correct_answer": "continue",
                        "explanation": "`continue` immediately proceeds to the next cycle of the enclosing loop.",
                    },
                ],
            },
            {
                "order": 3,
                "title": "3. Python Data Structures: Lists, Dictionaries, Sets & Tuples",
                "estimated_minutes": 45,
                "summary": "Deep dive into mutable sequences (lists), key-value associative arrays (dicts), immutable sequences (tuples), and unique sets.",
                "content": """# Python Data Structures

Python includes four versatile built-in collection data types.

## 1. Lists (Ordered, Mutable)
```python
skills = ["Python", "FastAPI", "Flutter"]
skills.append("MySQL")
```

## 2. Dictionaries (Key-Value Pairs)
```python
student_profile = {"name": "Keerthana", "credits": 50}
```
""",
                "video_url": "https://www.youtube.com/watch?v=nLRL_NcnK-4",
                "pdf_url": "https://docs.python.org/3/tutorial/datastructures.html",
                "doc_url": "https://docs.python.org/3/tutorial/datastructures.html",
                "resources": [
                    {
                        "type": "DOCS",
                        "title": "Official Python 3 Data Structures Documentation",
                        "url": "https://docs.python.org/3/tutorial/datastructures.html",
                        "source": "Python Software Foundation",
                        "duration": 30,
                        "is_primary": True,
                    },
                    {
                        "type": "VIDEO",
                        "title": "CS50 Python — Data Structures & Dictionaries",
                        "url": "https://www.youtube.com/watch?v=nLRL_NcnK-4",
                        "source": "YouTube / Harvard CS50",
                        "duration": 40,
                        "is_primary": False,
                    },
                ],
                "questions": [
                    {
                        "question": "What is the primary difference between a Python list and a Python tuple?",
                        "options": [
                            "Lists are mutable, while tuples are immutable",
                            "Lists can store strings, but tuples only store numbers",
                            "Tuples are mutable, while lists are immutable",
                            "Lists cannot be sliced, while tuples can",
                        ],
                        "correct_answer": "Lists are mutable, while tuples are immutable",
                        "explanation": "Lists can be modified in-place, whereas tuple contents cannot be altered after instantiation.",
                    },
                    {
                        "question": "Which data structure is most suitable for storing unique student email addresses with fast lookup?",
                        "options": [
                            "Set",
                            "List",
                            "Tuple",
                            "Nested List",
                        ],
                        "correct_answer": "Set",
                        "explanation": "Sets enforce element uniqueness and offer O(1) average time complexity for membership testing.",
                    },
                ],
            },
        ],
        "quiz": {
            "title": "Python Programming Proficiency & Certification Exam",
            "description": "Comprehensive timed evaluation assessing Python syntax, data types, control flow, functions, collections, OOP, and exception handling.",
            "time_limit_minutes": 20,
            "passing_percentage": 70,
            "questions": [
                {
                    "question": "Which built-in Python data type is immutable?",
                    "options": ["tuple", "list", "dict", "set"],
                    "correct_answer": "tuple",
                    "explanation": "Tuples cannot be altered in-place after creation.",
                    "points": 20,
                },
                {
                    "question": "What is the output of `type(lambda x: x + 1)` in Python?",
                    "options": ["<class 'function'>", "<class 'lambda'>", "<class 'int'>", "<class 'type'>"],
                    "correct_answer": "<class 'function'>",
                    "explanation": "Anonymous lambda expressions create instances of the standard function type.",
                    "points": 20,
                },
                {
                    "question": "What is the time complexity of looking up an existing key in a standard Python dictionary on average?",
                    "options": ["O(1)", "O(n)", "O(log n)", "O(n^2)"],
                    "correct_answer": "O(1)",
                    "explanation": "Python dictionaries use hash tables, providing O(1) average-time complexity for key lookups.",
                    "points": 20,
                },
                {
                    "question": "Which clause is executed in a try-except statement ONLY when NO exception is raised in the try block?",
                    "options": ["else", "finally", "except", "pass"],
                    "correct_answer": "else",
                    "explanation": "The `else` block runs if and only if the `try` block completes without errors.",
                    "points": 20,
                },
                {
                    "question": "What will `list(filter(lambda x: x % 2 == 0, [1, 2, 3, 4, 5, 6]))` return?",
                    "options": ["[2, 4, 6]", "[1, 3, 5]", "[0, 2, 4]", "[True, False, True]"],
                    "correct_answer": "[2, 4, 6]",
                    "explanation": "`filter` retains elements for which the predicate returns True (even numbers here).",
                    "points": 20,
                },
            ],
        },
    },

    "hindi": {
        "title": "Hindi Language & Communication — Beginner to Conversational",
        "description": "Comprehensive student course covering Devanagari script, foundational vocabulary, grammar rules, sentence construction, and everyday conversational fluency.",
        "estimated_minutes": 160,
        "lessons": [
            {
                "order": 1,
                "title": "1. Introduction to Hindi & Devanagari Script (वर्णमाला)",
                "estimated_minutes": 30,
                "summary": "Master the Devanagari alphabet: Vowels (स्वर), Consonants (व्यंजन), and phonetic pronunciation fundamentals.",
                "content": """# Introduction to Hindi & Devanagari Script

Welcome to Hindi learning! Hindi is written in the **Devanagari** (देवनागरी) script.

## 1. Vowels (स्वर - Swar)
- **अ (a)**, **आ (aa)**, **इ (i)**, **ई (ee)**
- **उ (u)**, **ऊ (oo)**, **ऋ (ri)**

## 2. Consonants (व्यंजन - Vyanjan)
- क (ka), ख (kha), ग (ga), घ (gha)
- च (cha), छ (chha), ज (ja), झ (jha)
""",
                "video_url": "https://www.youtube.com/watch?v=kY3jXj7EwB0",
                "pdf_url": "https://ncert.nic.in/textbook/pdf/hhed101.pdf",
                "doc_url": "https://en.wikipedia.org/wiki/Devanagari",
                "resources": [
                    {
                        "type": "VIDEO",
                        "title": "Hindi Devanagari Alphabet & Pronunciation Guide",
                        "url": "https://www.youtube.com/watch?v=kY3jXj7EwB0",
                        "source": "YouTube / Hindi Pod 101",
                        "duration": 25,
                        "is_primary": True,
                    },
                    {
                        "type": "DOCS",
                        "title": "Devanagari Script Reference & Phonetic Chart",
                        "url": "https://en.wikipedia.org/wiki/Devanagari",
                        "source": "Open Educational Resources",
                        "duration": 15,
                        "is_primary": False,
                    },
                ],
                "questions": [
                    {
                        "question": "Which of the following is the first vowel (स्वर) in the Hindi Devanagari alphabet?",
                        "options": ["अ (a)", "क (ka)", "आ (aa)", "इ (i)"],
                        "correct_answer": "अ (a)",
                        "explanation": "अ is the first fundamental vowel in the Devanagari script.",
                    },
                    {
                        "question": "In what script is the standard Hindi language officially written?",
                        "options": ["Devanagari (देवनागरी)", "Brahmi", "Gurmukhi", "Latin"],
                        "correct_answer": "Devanagari (देवनागरी)",
                        "explanation": "Standard modern Hindi is officially written in the Devanagari script.",
                    },
                ],
            },
            {
                "order": 2,
                "title": "2. Basic Vocabulary & Everyday Greetings (शब्दावली और अभिवादन)",
                "estimated_minutes": 35,
                "summary": "Essential words, greetings, and basic family/object vocabulary for daily interactions.",
                "content": """# Basic Vocabulary & Daily Greetings

Build your core Hindi vocabulary for daily communication and social etiquette.

## 1. Greetings & Etiquette
- **नमस्ते (Namaste)**: Hello / Greetings
- **धन्यवाद (Dhanyavaad)**: Thank you
- **कृपया (Kripaya)**: Please
- **फिर मिलेंगे (Phir milenge)**: See you again
""",
                "video_url": "https://www.youtube.com/watch?v=kY3jXj7EwB0",
                "pdf_url": "https://ncert.nic.in/textbook/pdf/hhed102.pdf",
                "doc_url": "https://en.wikipedia.org/wiki/Hindustani_vocabulary",
                "resources": [
                    {
                        "type": "VIDEO",
                        "title": "Top 25 Hindi Words & Phrases for Beginners",
                        "url": "https://www.youtube.com/watch?v=kY3jXj7EwB0",
                        "source": "YouTube Educational Hindi",
                        "duration": 20,
                        "is_primary": True,
                    },
                ],
                "questions": [
                    {
                        "question": "How do you say 'Thank you' formally in Hindi?",
                        "options": ["धन्यवाद (Dhanyavaad)", "नमस्ते (Namaste)", "कृपया (Kripaya)", "अलविदा (Alvida)"],
                        "correct_answer": "धन्यवाद (Dhanyavaad)",
                        "explanation": "धन्यवाद (Dhanyavaad) is the formal expression for 'Thank you'.",
                    },
                    {
                        "question": "Which pronoun is used to address an elder with respect in Hindi?",
                        "options": ["आप (Aap)", "तुम (Tum)", "तू (Tu)", "यह (Yeh)"],
                        "correct_answer": "आप (Aap)",
                        "explanation": "'आप' (Aap) is the formal, respectful second-person pronoun.",
                    },
                ],
            },
            {
                "order": 3,
                "title": "3. Real-World Conversations & Sentences (वार्तालाप)",
                "estimated_minutes": 35,
                "summary": "Conversations: Introducing yourself, asking for directions, and campus dialogues.",
                "content": """# Real-World Hindi Conversations

Apply your knowledge to practical everyday scenarios.

## Scenario 1: Introducing Yourself
- नमस्ते! मेरा नाम प्रिया है। (Hello! My name is Priya.)
- आप कैसे हैं? (How are you?)
- मैं ठीक हूँ, धन्यवाद। (I am fine, thank you.)
""",
                "video_url": "https://www.youtube.com/watch?v=kY3jXj7EwB0",
                "pdf_url": "https://ncert.nic.in/textbook/pdf/hhed103.pdf",
                "doc_url": "https://en.wikipedia.org/wiki/Hindi",
                "resources": [
                    {
                        "type": "DOCS",
                        "title": "Hindi Conversation Guide",
                        "url": "https://en.wikipedia.org/wiki/Hindi",
                        "source": "Open Educational Resources",
                        "duration": 20,
                        "is_primary": True,
                    }
                ],
                "questions": [
                    {
                        "question": "How do you ask 'Where is the library?' in Hindi?",
                        "options": [
                            "पुस्तकालय कहाँ है? (Pustakalay kahan hai?)",
                            "पुस्तकालय क्या है? (Pustakalay kya hai?)",
                            "पुस्तकालय कौन है? (Pustakalay kaun hai?)",
                            "पुस्तकालय कब है? (Pustakalay kab hai?)",
                        ],
                        "correct_answer": "पुस्तकालय कहाँ है? (Pustakalay kahan hai?)",
                        "explanation": "'कहाँ' (kahan) means 'Where' in Hindi.",
                    },
                    {
                        "question": "Which sentence correctly asks 'How much is this?' in a marketplace?",
                        "options": [
                            "यह कितने का है? (Yeh kitne ka hai?)",
                            "यह कहाँ का है? (Yeh kahan ka hai?)",
                            "यह कौन है? (Yeh kaun hai?)",
                            "यह क्यों है? (Yeh kyon hai?)",
                        ],
                        "correct_answer": "यह कितने का है? (Yeh kitne ka hai?)",
                        "explanation": "'कितने का' (kitne ka) is used to inquire about price or cost.",
                    },
                ],
            },
        ],
        "quiz": {
            "title": "Hindi Language Proficiency & Certification Assessment",
            "description": "Timed evaluation assessing Devanagari script, vocabulary, grammar rules, SOV sentence structure, and real-world conversation dialogues.",
            "time_limit_minutes": 15,
            "passing_percentage": 70,
            "questions": [
                {
                    "question": "What is the Devanagari consonant for the sound 'ka'?",
                    "options": ["क", "ख", "ग", "च"],
                    "correct_answer": "क",
                    "explanation": "क is the first consonant in the Devanagari alphabet corresponding to 'ka'.",
                    "points": 50,
                },
                {
                    "question": "In Hindi sentence structure (SOV), where is the verb placed?",
                    "options": ["At the end of the sentence", "At the very beginning", "Immediately after the subject", "Before the object"],
                    "correct_answer": "At the end of the sentence",
                    "explanation": "In Hindi (SOV language), the verb appears at the end of the clause.",
                    "points": 50,
                },
            ],
        },
    },

    "mathematics": {
        "title": "Mathematics — Foundations of Algebra, Geometry & Statistics",
        "description": "Comprehensive curriculum covering algebraic equations, coordinate geometry, trigonometry, probability theory, and descriptive statistical analysis.",
        "estimated_minutes": 180,
        "lessons": [
            {
                "order": 1,
                "title": "1. Algebraic Expressions, Linear & Quadratic Equations",
                "estimated_minutes": 40,
                "summary": "Solve linear equations, systems of linear equations, factoring, and quadratic equations.",
                "content": r"""# Algebraic Expressions & Equations

Algebra forms the analytical backbone of computer science and quantitative problem-solving.

## 1. Linear Equations in One Variable
An equation of form `ax + b = 0`:
$$3x - 12 = 0 \implies 3x = 12 \implies x = 4$$

## 2. Quadratic Equations
$$ax^2 + bx + c = 0$$
""",
                "video_url": "https://www.youtube.com/watch?v=WUvTyaaNkzM",
                "pdf_url": "https://ncert.nic.in/textbook/pdf/kemh101.pdf",
                "doc_url": "https://www.khanacademy.org/math/algebra",
                "resources": [
                    {
                        "type": "DOCS",
                        "title": "Khan Academy — Algebra Foundations & Quadratic Equations",
                        "url": "https://www.khanacademy.org/math/algebra",
                        "source": "Khan Academy",
                        "duration": 30,
                        "is_primary": True,
                    },
                    {
                        "type": "PDF",
                        "title": "NCERT Class 11 Mathematics — Quadratic Equations",
                        "url": "https://ncert.nic.in/textbook/pdf/kemh101.pdf",
                        "source": "NCERT Open Educational Textbooks",
                        "duration": 25,
                        "is_primary": False,
                    },
                ],
                "questions": [
                    {
                        "question": "A shop offers a 20% discount on a ₹1,000 product. What is the final price paid by the customer?",
                        "options": ["₹800", "₹850", "₹750", "₹900"],
                        "correct_answer": "₹800",
                        "explanation": "20% of 1000 is 200. The final price is 1000 - 200 = ₹800.",
                    },
                    {
                        "question": "What is the discriminant of the quadratic equation $x^2 - 6x + 9 = 0$?",
                        "options": ["0", "12", "-18", "36"],
                        "correct_answer": "0",
                        "explanation": "Discriminant = (-6)^2 - 4(1)(9) = 36 - 36 = 0. This indicates one repeated real root.",
                    },
                ],
            },
            {
                "order": 2,
                "title": "2. Coordinate Geometry & Trigonometric Functions",
                "estimated_minutes": 45,
                "summary": "Distance formula, midpoint, slopes of lines, unit circle, and primary trigonometric ratios (sin, cos, tan).",
                "content": """# Coordinate Geometry & Trigonometry

Distance between two points $P(x_1, y_1)$ and $Q(x_2, y_2)$:
$$d = \\sqrt{(x_2 - x_1)^2 + (y_2 - y_1)^2}$$
""",
                "video_url": "https://www.youtube.com/watch?v=WUvTyaaNkzM",
                "pdf_url": "https://ncert.nic.in/textbook/pdf/kemh102.pdf",
                "doc_url": "https://www.khanacademy.org/math/trigonometry",
                "resources": [
                    {
                        "type": "DOCS",
                        "title": "Khan Academy — Trigonometry & Geometric Coordinates",
                        "url": "https://www.khanacademy.org/math/trigonometry",
                        "source": "Khan Academy",
                        "duration": 30,
                        "is_primary": True,
                    },
                ],
                "questions": [
                    {
                        "question": "What is the distance between points (0, 0) and (3, 4) on the Cartesian plane?",
                        "options": ["5", "7", "25", "1"],
                        "correct_answer": "5",
                        "explanation": "sqrt((3-0)^2 + (4-0)^2) = sqrt(9 + 16) = sqrt(25) = 5.",
                    },
                    {
                        "question": "What is the value of sin(30 degrees) in standard trigonometry?",
                        "options": ["1/2 (0.5)", "sqrt(3)/2", "1", "0"],
                        "correct_answer": "1/2 (0.5)",
                        "explanation": "sin(30 degrees) = 1/2.",
                    },
                ],
            },
            {
                "order": 3,
                "title": "3. Probability Theory & Descriptive Statistics",
                "estimated_minutes": 45,
                "summary": "Measures of central tendency (mean, median, mode), variance, and classical probability.",
                "content": """# Probability & Descriptive Statistics

- **Mean**: Sum of items divided by count.
- **Median**: Middle value of ordered items.
- **Mode**: Most frequent value.
""",
                "video_url": "https://www.youtube.com/watch?v=WUvTyaaNkzM",
                "pdf_url": "https://ncert.nic.in/textbook/pdf/kemh103.pdf",
                "doc_url": "https://www.khanacademy.org/math/statistics-probability",
                "resources": [
                    {
                        "type": "DOCS",
                        "title": "Khan Academy — Probability & Statistics",
                        "url": "https://www.khanacademy.org/math/statistics-probability",
                        "source": "Khan Academy",
                        "duration": 30,
                        "is_primary": True,
                    }
                ],
                "questions": [
                    {
                        "question": "What is the mean (average) of the dataset: [10, 20, 30, 40, 50]?",
                        "options": ["30", "25", "35", "40"],
                        "correct_answer": "30",
                        "explanation": "(10 + 20 + 30 + 40 + 50) / 5 = 150 / 5 = 30.",
                    },
                    {
                        "question": "What is the probability of rolling an even number on a fair standard 6-sided die?",
                        "options": ["1/2 (50%)", "1/3 (33.3%)", "1/6 (16.7%)", "2/3 (66.7%)"],
                        "correct_answer": "1/2 (50%)",
                        "explanation": "Favorable outcomes are {2, 4, 6} (3 outcomes) out of 6 possible. 3/6 = 1/2.",
                    },
                ],
            },
        ],
        "quiz": {
            "title": "Mathematics Mastery & Problem Solving Assessment",
            "description": "Timed assessment testing algebra, coordinate geometry, trigonometry, and statistical probability.",
            "time_limit_minutes": 20,
            "passing_percentage": 70,
            "questions": [
                {
                    "question": "If 2x + 5 = 17, what is the value of x?",
                    "options": ["6", "5", "7", "4"],
                    "correct_answer": "6",
                    "explanation": "2x = 17 - 5 = 12, so x = 6.",
                    "points": 50,
                },
                {
                    "question": "What is the slope of a horizontal line on the Cartesian plane?",
                    "options": ["0", "1", "Undefined (infinite)", "-1"],
                    "correct_answer": "0",
                    "explanation": "A horizontal line has zero vertical change (delta y = 0), so slope m = 0.",
                    "points": 50,
                },
            ],
        },
    },

    "photography": {
        "title": "Photography — The Art & Science of Visual Storytelling",
        "description": "Master camera optics, the exposure triangle (aperture, shutter speed, ISO), composition guidelines, lighting techniques, and post-production workflow.",
        "estimated_minutes": 150,
        "lessons": [
            {
                "order": 1,
                "title": "1. The Exposure Triangle: Aperture, Shutter Speed & ISO",
                "estimated_minutes": 35,
                "summary": "Master the three pillars of photographic exposure, depth of field control, and motion capture.",
                "content": """# The Exposure Triangle: Aperture, Shutter Speed & ISO

Exposure is the amount of light that reaches your camera sensor.

## 1. Aperture (f-stop)
- **Wide aperture (f/1.8, f/2.8)**: Shallow depth of field (blurry background/bokeh).
- **Narrow aperture (f/8, f/16)**: Sharp throughout (landscapes).

## 2. Shutter Speed
- Fast speeds (1/1000s) freeze motion; slow speeds (1/15s) create motion blur.
""",
                "video_url": "https://www.youtube.com/watch?v=V7z7BAZdt2M",
                "pdf_url": "https://www.cambridgeincolour.com/tutorials/camera-exposure.htm",
                "doc_url": "https://www.cambridgeincolour.com/tutorials/camera-exposure.htm",
                "resources": [
                    {
                        "type": "DOCS",
                        "title": "Cambridge in Colour — Understanding Camera Exposure & Optics",
                        "url": "https://www.cambridgeincolour.com/tutorials/camera-exposure.htm",
                        "source": "Cambridge in Colour",
                        "duration": 25,
                        "is_primary": True,
                    },
                    {
                        "type": "VIDEO",
                        "title": "Photography Tutorial: The Exposure Triangle Explained",
                        "url": "https://www.youtube.com/watch?v=V7z7BAZdt2M",
                        "source": "YouTube Photography",
                        "duration": 20,
                        "is_primary": False,
                    },
                ],
                "questions": [
                    {
                        "question": "You are photographing a fast-moving athlete in bright daylight. Which setting will help freeze their motion sharply?",
                        "options": [
                            "Fast shutter speed (e.g., 1/1000s or faster)",
                            "Slow shutter speed (e.g., 1/10s)",
                            "Narrow aperture (f/22)",
                            "High ISO (6400)",
                        ],
                        "correct_answer": "Fast shutter speed (e.g., 1/1000s or faster)",
                        "explanation": "A fast shutter speed exposes the sensor for a fraction of a millisecond, freezing rapid movement.",
                    },
                    {
                        "question": "Which aperture setting creates the shallowest depth of field (blurry background bokeh for portraits)?",
                        "options": [
                            "f/1.8",
                            "f/8.0",
                            "f/16.0",
                            "f/22.0",
                        ],
                        "correct_answer": "f/1.8",
                        "explanation": "Smaller f-numbers represent wider physical apertures, resulting in a shallower depth of field.",
                    },
                ],
            },
            {
                "order": 2,
                "title": "2. Composition Rules: Rule of Thirds & Leading Lines",
                "estimated_minutes": 35,
                "summary": "Mastering the rule of thirds, framing, symmetry, and visual storytelling.",
                "content": """# Composition Rules

Composition guides the viewer's eye through the frame.

## 1. Rule of Thirds
Align key subjects along the 3x3 grid lines.
""",
                "video_url": "https://www.youtube.com/watch?v=V7z7BAZdt2M",
                "pdf_url": "https://www.cambridgeincolour.com/tutorials/rule-of-thirds.htm",
                "doc_url": "https://www.cambridgeincolour.com/tutorials/rule-of-thirds.htm",
                "resources": [
                    {
                        "type": "DOCS",
                        "title": "Cambridge in Colour — Rule of Thirds",
                        "url": "https://www.cambridgeincolour.com/tutorials/rule-of-thirds.htm",
                        "source": "Cambridge in Colour",
                        "duration": 20,
                        "is_primary": True,
                    }
                ],
                "questions": [
                    {
                        "question": "What is the primary concept behind the Rule of Thirds in photography?",
                        "options": [
                            "Dividing the image with a 3x3 grid and aligning key subjects along the lines or intersections",
                            "Taking three identical photos of every subject",
                            "Setting the shutter speed to 1/3 of a second",
                            "Using only three colors in every photograph",
                        ],
                        "correct_answer": "Dividing the image with a 3x3 grid and aligning key subjects along the lines or intersections",
                        "explanation": "The Rule of Thirds uses grid lines to position focal points harmoniously off-center.",
                    },
                    {
                        "question": "Why is 'Golden Hour' favored by photographers?",
                        "options": [
                            "The low sun produces soft, warm, diffused light with flattering gentle shadows",
                            "Camera sensors consume less battery power during this hour",
                            "The sky turns completely black",
                            "Lenses auto-focus twice as fast",
                        ],
                        "correct_answer": "The low sun produces soft, warm, diffused light with flattering gentle shadows",
                        "explanation": "The atmospheric angle of the sun diffuses harsh light and casts warm golden tones.",
                    },
                ],
            },
        ],
        "quiz": {
            "title": "Photography & Camera Craft Certification Exam",
            "description": "Timed exam evaluating knowledge of the exposure triangle, lens optics, composition rules, and lighting techniques.",
            "time_limit_minutes": 15,
            "passing_percentage": 70,
            "questions": [
                {
                    "question": "Which camera setting directly controls depth of field?",
                    "options": ["Aperture (f-stop)", "Shutter speed", "ISO sensitivity", "White balance"],
                    "correct_answer": "Aperture (f-stop)",
                    "explanation": "Aperture controls the physical diaphragm opening, dictating the depth of field.",
                    "points": 50,
                },
                {
                    "question": "What happens when using a slow shutter speed (such as 2 seconds) handheld without a tripod?",
                    "options": [
                        "Camera shake causes the entire image to appear blurry",
                        "The image will be completely underexposed",
                        "The aperture will close automatically",
                        "Digital noise will disappear",
                    ],
                    "correct_answer": "Camera shake causes the entire image to appear blurry",
                    "explanation": "Natural hand tremor during long exposures blurs the image; stabilization or a tripod is required.",
                    "points": 50,
                },
            ],
        },
    },

    "javascript": {
        "title": "JavaScript — Modern Web Development & ES6+",
        "description": "Master JavaScript fundamentals, modern ES6+ syntax, asynchronous programming (Promises, async/await), DOM manipulation, and modular web architecture.",
        "estimated_minutes": 180,
        "lessons": [
            {
                "order": 1,
                "title": "1. Modern JavaScript: let, const, Data Types & Arrow Functions",
                "estimated_minutes": 35,
                "summary": "Block scope, primitives, template literals, arrow functions, and destructuring assignment.",
                "content": """# Modern JavaScript (ES6+)

JavaScript is the programming language of the modern web platform.
""",
                "video_url": "https://www.youtube.com/watch?v=PkZNo7MFNFg",
                "pdf_url": "https://developer.mozilla.org/en-US/docs/Web/JavaScript",
                "doc_url": "https://developer.mozilla.org/en-US/docs/Web/JavaScript",
                "resources": [
                    {
                        "type": "DOCS",
                        "title": "MDN Web Docs — JavaScript Language Reference",
                        "url": "https://developer.mozilla.org/en-US/docs/Web/JavaScript",
                        "source": "Mozilla Developer Network (MDN)",
                        "duration": 30,
                        "is_primary": True,
                    },
                ],
                "questions": [
                    {
                        "question": "What is the primary difference between `let` and `const` in modern JavaScript?",
                        "options": [
                            "`const` variables cannot be reassigned after declaration, while `let` variables can",
                            "`let` is function-scoped while `const` is block-scoped",
                            "`const` can only store numbers",
                            "`let` is hoisted but `const` is not",
                        ],
                        "correct_answer": "`const` variables cannot be reassigned after declaration, while `let` variables can",
                        "explanation": "`const` creates an immutable binding, preventing variable reassignment.",
                    },
                ],
            },
        ],
        "quiz": {
            "title": "JavaScript & Web Architecture Certification Exam",
            "description": "Timed assessment testing ES6+ syntax, asynchronous JS, DOM APIs, and functional methods.",
            "time_limit_minutes": 15,
            "passing_percentage": 70,
            "questions": [
                {
                    "question": "Which array method creates a new array populated with the results of calling a provided function on every element?",
                    "options": ["Array.prototype.map()", "Array.prototype.forEach()", "Array.prototype.filter()", "Array.prototype.reduce()"],
                    "correct_answer": "Array.prototype.map()",
                    "explanation": "`.map()` returns a new transformed array without mutating the original.",
                    "points": 50,
                },
                {
                    "question": "What is the output of `0 == false` and `0 === false` in JavaScript?",
                    "options": [
                        "true, false",
                        "true, true",
                        "false, false",
                        "false, true",
                    ],
                    "correct_answer": "true, false",
                    "explanation": "`==` performs loose type coercion (0 becomes false), whereas `===` checks strict type equality without coercion.",
                    "points": 50,
                },
            ],
        },
    },

    "sql": {
        "title": "SQL & Relational Database Management Systems",
        "description": "Comprehensive course covering relational database design, complex queries, JOIN operations, aggregations, data integrity constraints, and query indexing.",
        "estimated_minutes": 160,
        "lessons": [
            {
                "order": 1,
                "title": "1. Relational Database Concepts & The SELECT Query",
                "estimated_minutes": 35,
                "summary": "Tables, primary keys, foreign keys, filtering with WHERE, ordering with ORDER BY, and limiting query output.",
                "content": """# SQL & Relational Databases

SQL is the standard language for relational database management.
""",
                "video_url": "https://www.youtube.com/watch?v=HXV3zeQKqGY",
                "pdf_url": "https://dev.mysql.com/doc/refman/8.0/en/tutorial.html",
                "doc_url": "https://dev.mysql.com/doc/refman/8.0/en/tutorial.html",
                "resources": [
                    {
                        "type": "DOCS",
                        "title": "MySQL 8.0 Reference Manual — SQL Tutorial",
                        "url": "https://dev.mysql.com/doc/refman/8.0/en/tutorial.html",
                        "source": "Oracle MySQL Documentation",
                        "duration": 30,
                        "is_primary": True,
                    },
                ],
                "questions": [
                    {
                        "question": "Which SQL clause is used to filter records that satisfy a specific conditional criterion?",
                        "options": ["WHERE", "ORDER BY", "GROUP BY", "LIMIT"],
                        "correct_answer": "WHERE",
                        "explanation": "`WHERE` filters row records based on specified search conditions.",
                    },
                ],
            },
        ],
        "quiz": {
            "title": "SQL & Relational Database Certification Exam",
            "description": "Timed assessment testing schema design, JOINs, aggregations, DDL/DML, and indexing.",
            "time_limit_minutes": 15,
            "passing_percentage": 70,
            "questions": [
                {
                    "question": "Which SQL command is used to permanently remove a table along with its schema and all data?",
                    "options": ["DROP TABLE", "DELETE TABLE", "TRUNCATE TABLE", "REMOVE TABLE"],
                    "correct_answer": "DROP TABLE",
                    "explanation": "`DROP TABLE` completely removes the table structure and its data from the database catalog.",
                    "points": 50,
                },
                {
                    "question": "What is the primary performance advantage of adding an INDEX to a frequently queried column?",
                    "options": [
                        "Significantly speeds up data retrieval and SELECT search queries",
                        "Reduces disk space usage of the database",
                        "Makes INSERT operations faster",
                        "Prevents table deletion",
                    ],
                    "correct_answer": "Significantly speeds up data retrieval and SELECT search queries",
                    "explanation": "Indexes use B-trees to locate target rows in O(log n) time rather than performing full table scans.",
                    "points": 50,
                },
            ],
        },
    },

    "flutter": {
        "title": "Flutter & Mobile Application Development with Dart",
        "description": "Master cross-platform mobile development using Flutter: widget trees, state management, responsive UI, animations, and REST API integration.",
        "estimated_minutes": 180,
        "lessons": [
            {
                "order": 1,
                "title": "1. Flutter Widget Architecture: Stateless vs StatefulWidget",
                "estimated_minutes": 35,
                "summary": "Understand the declarative UI paradigm, widget tree composition, `build()` lifecycle, and `setState()`.",
                "content": """# Flutter Widget Architecture

In Flutter, everything is a Widget! The UI is declared as a tree of immutable widgets.
""",
                "video_url": "https://www.youtube.com/watch?v=1gDhl4leEzA",
                "pdf_url": "https://docs.flutter.dev/ui",
                "doc_url": "https://docs.flutter.dev/ui",
                "resources": [
                    {
                        "type": "DOCS",
                        "title": "Official Flutter Documentation — Widget Tour",
                        "url": "https://docs.flutter.dev/ui",
                        "source": "Flutter.dev",
                        "duration": 30,
                        "is_primary": True,
                    },
                ],
                "questions": [
                    {
                        "question": "What is the primary difference between a `StatelessWidget` and a `StatefulWidget` in Flutter?",
                        "options": [
                            "A `StatefulWidget` maintains mutable state that can trigger rebuilds via `setState()`, while `StatelessWidget` is immutable",
                            "A `StatelessWidget` can only display text",
                            "A `StatefulWidget` cannot run on iOS devices",
                            "There is no difference in runtime behavior",
                        ],
                        "correct_answer": "A `StatefulWidget` maintains mutable state that can trigger rebuilds via `setState()`, while `StatelessWidget` is immutable",
                        "explanation": "`StatefulWidget` creates a `State` object that manages mutable data across the widget lifecycle.",
                    },
                ],
            },
        ],
        "quiz": {
            "title": "Flutter Mobile Development Certification Exam",
            "description": "Timed assessment testing Flutter widgets, state management, layouts, navigation, and asynchronous Dart streams.",
            "time_limit_minutes": 15,
            "passing_percentage": 70,
            "questions": [
                {
                    "question": "Which widget is used to lay out its children horizontally in a single row?",
                    "options": ["Row", "Column", "Stack", "Wrap"],
                    "correct_answer": "Row",
                    "explanation": "`Row` arranges child widgets horizontally.",
                    "points": 50,
                },
                {
                    "question": "In Flutter, what does `Expanded` do inside a `Row` or `Column`?",
                    "options": [
                        "Forces a child to expand to fill available space along the main axis",
                        "Multiplies the child's font size by 2",
                        "Adds border padding to the child",
                        "Hides the child when space is tight",
                    ],
                    "correct_answer": "Forces a child to expand to fill available space along the main axis",
                    "explanation": "`Expanded` expands a child to consume remaining flex space.",
                    "points": 50,
                },
            ],
        },
    },

    "java": {
        "title": "Java Programming — Core Concepts to OOP Mastery",
        "description": "Master Java development: JVM architecture, strongly typed syntax, OOP principles, inheritance, interfaces, exception handling, and the Java Collections Framework.",
        "estimated_minutes": 190,
        "lessons": [
            {
                "order": 1,
                "title": "1. Java JVM Architecture & Strong Typing Fundamentals",
                "estimated_minutes": 35,
                "summary": "Understand bytecode compilation, the JVM/JRE/JDK ecosystem, primitive data types, and static type declarations.",
                "content": """# Java Architecture & Fundamental Syntax

Java is a class-based, object-oriented, statically-typed programming language.
""",
                "video_url": "https://www.youtube.com/watch?v=A74TOX803D0",
                "pdf_url": "https://docs.oracle.com/javase/tutorial/getStarted/index.html",
                "doc_url": "https://docs.oracle.com/javase/tutorial/getStarted/index.html",
                "resources": [
                    {
                        "type": "DOCS",
                        "title": "Oracle Official Java Tutorials — Getting Started",
                        "url": "https://docs.oracle.com/javase/tutorial/getStarted/index.html",
                        "source": "Oracle Documentation",
                        "duration": 30,
                        "is_primary": True,
                    },
                ],
                "questions": [
                    {
                        "question": "What is the primary role of the Java Virtual Machine (JVM)?",
                        "options": [
                            "Executes compiled Java bytecode and manages memory via Garbage Collection",
                            "Formats source code text files",
                            "Encrypts passwords automatically",
                            "Replaces the operating system",
                        ],
                        "correct_answer": "Executes compiled Java bytecode and manages memory via Garbage Collection",
                        "explanation": "The JVM interprets and JIT-compiles bytecode into native machine code.",
                    },
                ],
            },
        ],
        "quiz": {
            "title": "Java Architecture & OOP Certification Exam",
            "description": "Timed assessment testing Java syntax, JVM architecture, OOP, Collections, and Exception handling.",
            "time_limit_minutes": 15,
            "passing_percentage": 70,
            "questions": [
                {
                    "question": "Which collection in Java preserves insertion order and allows indexed positional access to elements?",
                    "options": ["ArrayList", "HashSet", "TreeSet", "HashMap"],
                    "correct_answer": "ArrayList",
                    "explanation": "`ArrayList` maintains ordered elements accessible via zero-based index.",
                    "points": 50,
                },
                {
                    "question": "What is the return type of a Java constructor method?",
                    "options": [
                        "Constructors have no return type, not even void",
                        "void",
                        "int",
                        "Object",
                    ],
                    "correct_answer": "Constructors have no return type, not even void",
                    "explanation": "Constructors implicitly instantiate and initialize class instances.",
                    "points": 50,
                },
            ],
        },
    },

    "react": {
        "title": "React — Modern Component-Based Web Engineering",
        "description": "Master React UI development: declarative components, JSX, props vs state, React Hooks (useState, useEffect, useMemo), and modular frontend architecture.",
        "estimated_minutes": 170,
        "lessons": [
            {
                "order": 1,
                "title": "1. React Fundamentals: Components, JSX & Props",
                "estimated_minutes": 35,
                "summary": "Understand declarative UI rendering, JSX syntax rules, functional components, and unidirectional data flow via props.",
                "content": """# React Fundamentals: Components, JSX & Props

React is a declarative, component-based JavaScript library for building user interfaces.
""",
                "video_url": "https://www.youtube.com/watch?v=bMknfKXIFA8",
                "pdf_url": "https://react.dev/learn",
                "doc_url": "https://react.dev/learn",
                "resources": [
                    {
                        "type": "DOCS",
                        "title": "Official React Documentation — Describing the UI",
                        "url": "https://react.dev/learn",
                        "source": "React.dev",
                        "duration": 30,
                        "is_primary": True,
                    },
                ],
                "questions": [
                    {
                        "question": "What is JSX in React?",
                        "options": [
                            "A syntax extension for JavaScript that allows writing HTML-like markup inside JS code",
                            "A replacement for SQL queries",
                            "A server-side database engine",
                            "A compiler for Python",
                        ],
                        "correct_answer": "A syntax extension for JavaScript that allows writing HTML-like markup inside JS code",
                        "explanation": "JSX lets developers write declarative UI structures directly within JavaScript.",
                    },
                ],
            },
        ],
        "quiz": {
            "title": "React Frontend Engineering Certification Exam",
            "description": "Timed assessment testing React component architecture, Hooks, Virtual DOM, and state patterns.",
            "time_limit_minutes": 15,
            "passing_percentage": 70,
            "questions": [
                {
                    "question": "What is the primary role of the Virtual DOM in React?",
                    "options": [
                        "Calculates minimal UI diffs in memory before updating the real browser DOM efficiently",
                        "Stores application passwords securely",
                        "Renders 3D graphics inside HTML canvases",
                        "Replaces SQL database tables",
                    ],
                    "correct_answer": "Calculates minimal UI diffs in memory before updating the real browser DOM efficiently",
                    "explanation": "The Virtual DOM optimizes rendering performance by minimizing costly real DOM mutations.",
                    "points": 50,
                },
                {
                    "question": "What is the special prop required when rendering lists of items in React?",
                    "options": ["key", "id", "index", "ref"],
                    "correct_answer": "key",
                    "explanation": "`key` provides a stable identity for list elements across re-renders.",
                    "points": 50,
                },
            ],
        },
    },

    "excel": {
        "title": "Microsoft Excel — Spreadsheet Analytics & Formulas",
        "description": "Comprehensive course covering spreadsheet modeling, essential arithmetic formulas, lookup functions (VLOOKUP, XLOOKUP), Pivot Tables, and automated data cleaning.",
        "estimated_minutes": 140,
        "lessons": [
            {
                "order": 1,
                "title": "1. Spreadsheet Foundations, Arithmetic & Relative/Absolute Referencing",
                "estimated_minutes": 35,
                "summary": "Master cell coordinates, formulas (=SUM, =AVERAGE, =COUNT), and referencing ($A$1 vs A1).",
                "content": """# Excel Foundations & Formulas

Excel is the industry standard tool for data organization and spreadsheet modeling.
""",
                "video_url": "https://www.youtube.com/watch?v=Vl0H-qTclOg",
                "pdf_url": "https://support.microsoft.com/en-us/excel",
                "doc_url": "https://support.microsoft.com/en-us/excel",
                "resources": [
                    {
                        "type": "DOCS",
                        "title": "Microsoft Excel Official Training & Formula Reference",
                        "url": "https://support.microsoft.com/en-us/excel",
                        "source": "Microsoft Support",
                        "duration": 25,
                        "is_primary": True,
                    },
                ],
                "questions": [
                    {
                        "question": "What is the purpose of dollar signs in an Excel cell formula reference such as `$B$4`?",
                        "options": [
                            "Creates an absolute reference locking both column B and row 4 when copied",
                            "Formats the cell value as currency in US dollars",
                            "Multiplies the cell value by 100",
                            "Converts text into numbers",
                        ],
                        "correct_answer": "Creates an absolute reference locking both column B and row 4 when copied",
                        "explanation": "`$B$4` locks both column and row so they remain fixed when the formula is copied.",
                    },
                ],
            },
        ],
        "quiz": {
            "title": "Microsoft Excel Analytics & Modeling Certification Exam",
            "description": "Timed assessment testing Excel formulas, lookup functions, Pivot Tables, and data visualization.",
            "time_limit_minutes": 15,
            "passing_percentage": 70,
            "questions": [
                {
                    "question": "Which modern lookup function in Excel replaces both VLOOKUP and HLOOKUP with bidirectional search capability?",
                    "options": ["XLOOKUP", "INDEX/MATCH", "VLOOKUP2", "FIND"],
                    "correct_answer": "XLOOKUP",
                    "explanation": "`XLOOKUP` searches in any direction and defaults to exact matching.",
                    "points": 50,
                },
                {
                    "question": "What is the primary purpose of an Excel Pivot Table?",
                    "options": [
                        "Quickly summarize, aggregate, and analyze large datasets dynamically",
                        "Encrypt spreadsheet workbooks",
                        "Draw freehand vector artwork",
                        "Run SQL server instances locally",
                    ],
                    "correct_answer": "Quickly summarize, aggregate, and analyze large datasets dynamically",
                    "explanation": "Pivot Tables reorganize and summarize complex tabular records effortlessly.",
                    "points": 50,
                },
            ],
        },
    },

    "public speaking": {
        "title": "Public Speaking — Rhetoric, Delivery & Stage Presence",
        "description": "Master verbal rhetoric, speech structuring, stage presence, overcoming anxiety, vocal variety, and engaging diverse audiences.",
        "estimated_minutes": 130,
        "lessons": [
            {
                "order": 1,
                "title": "1. Structuring Compelling Speeches & Overcoming Stage Anxiety",
                "estimated_minutes": 35,
                "summary": "The Hook-Story-Offer formula, managing adrenaline, diaphragmatic breathing, and purposeful vocal pacing.",
                "content": """# Public Speaking & Speech Craft

Public speaking is a learnable leadership skill rooted in rhetoric and empathetic audience engagement.
""",
                "video_url": "https://www.youtube.com/watch?v=i0a61wFaF8A",
                "pdf_url": "https://www.toastmasters.org/resources",
                "doc_url": "https://www.toastmasters.org/resources",
                "resources": [
                    {
                        "type": "DOCS",
                        "title": "Toastmasters International — Public Speaking Resource Library",
                        "url": "https://www.toastmasters.org/resources",
                        "source": "Toastmasters International",
                        "duration": 25,
                        "is_primary": True,
                    },
                ],
                "questions": [
                    {
                        "question": "What is the recommended duration of eye contact with an individual audience member during a speech?",
                        "options": [
                            "3 to 5 seconds to build personal connection before moving to another person",
                            "Staring unblinkingly for the entire speech",
                            "Looking only at the floor or ceiling",
                            "Closing your eyes while speaking",
                        ],
                        "correct_answer": "3 to 5 seconds to build personal connection before moving to another person",
                        "explanation": "Holding eye contact for 3-5 seconds engages individuals naturally.",
                    },
                ],
            },
        ],
        "quiz": {
            "title": "Public Speaking & Presentation Mastery Certification",
            "description": "Timed assessment testing speech structure, rhetorical strategies, body language, and stagecraft.",
            "time_limit_minutes": 15,
            "passing_percentage": 70,
            "questions": [
                {
                    "question": "When delivering a speech, what is the impact of intentional silence (strategic pausing)?",
                    "options": [
                        "Allows the audience to absorb key points and builds dramatic emphasis",
                        "Indicates the speaker forgot their speech completely",
                        "Shortens the speech artificially",
                        "Causes microphone feedback",
                    ],
                    "correct_answer": "Allows the audience to absorb key points and builds dramatic emphasis",
                    "explanation": "Strategic pauses allow listeners to process critical insights and add authority to the speaker.",
                    "points": 50,
                },
                {
                    "question": "Which posture conveys confidence and openness on stage?",
                    "options": [
                        "Open posture with shoulders relaxed, arms uncrossed, and feet planted shoulder-width apart",
                        "Crossing arms tightly across the chest",
                        "Hiding hands in pockets while looking down",
                        "Pacing frantically back and forth across the stage",
                    ],
                    "correct_answer": "Open posture with shoulders relaxed, arms uncrossed, and feet planted shoulder-width apart",
                    "explanation": "Open, grounded body language establishes credibility and audience rapport.",
                    "points": 50,
                },
            ],
        },
    },
}

def get_curated_or_generated_course(skill_name: str, category: Optional[str] = None) -> Dict[str, Any]:
    """
    Returns a high-quality, topic-specific course. If the skill matches one of our
    curated flagship courses, it returns that rich curriculum. Otherwise, it dynamically
    synthesizes a domain-aware, authentic multi-lesson course with topic-specific questions.
    """
    key = skill_name.strip().lower()
    for curated_key, course in CURATED_COURSES.items():
        if curated_key in key or key in curated_key:
            return course

    # Fallback to domain-specific generator based on category or keyword
    cat = (category or "General").lower()
    encoded = urllib.parse.quote_plus(skill_name)
    clean_name = skill_name.title()

    if any(k in cat or k in key for k in ["tech", "program", "code", "software", "comput", "web", "data", "develop"]):
        return _generate_tech_course(clean_name, encoded)
    elif any(k in cat or k in key for k in ["academic", "math", "science", "physics", "chemistry", "biology", "history"]):
        return _generate_academic_course(clean_name, encoded)
    elif any(k in cat or k in key for k in ["language", "linguistics", "french", "german", "spanish", "tamil", "telugu", "japanese", "english"]):
        return _generate_language_course(clean_name, encoded)
    elif any(k in cat or k in key for k in ["creative", "art", "music", "design", "photo", "video", "drawing"]):
        return _generate_creative_course(clean_name, encoded)
    elif any(k in cat or k in key for k in ["profess", "business", "speak", "market", "manage", "communicat", "lead"]):
        return _generate_professional_course(clean_name, encoded)
    else:
        return _generate_general_course(clean_name, encoded)

def _generate_tech_course(name: str, encoded: str) -> Dict[str, Any]:
    return {
        "title": f"{name} — Modern Architecture & Practical Mastery",
        "description": f"Comprehensive technical curriculum covering core principles, modern workflows, practical problem solving, testing, and production best practices in {name}.",
        "estimated_minutes": 180,
        "lessons": [
            {
                "order": 1,
                "title": f"1. Core Principles & Environment Setup for {name}",
                "estimated_minutes": 35,
                "summary": f"Foundational architecture, environment configuration, syntax standards, and tooling for {name}.",
                "content": f"# Core Principles of {name}\\n\\nEstablish professional development environments and master foundational principles of {name}.",
                "video_url": f"https://www.youtube.com/results?search_query={encoded}+crash+course+tutorial",
                "pdf_url": "https://en.wikipedia.org/wiki/Computer_programming",
                "doc_url": f"https://en.wikipedia.org/wiki/{encoded}",
                "resources": [
                    {
                        "type": "DOCS",
                        "title": f"Official Reference & Getting Started Guide for {name}",
                        "url": f"https://en.wikipedia.org/wiki/{encoded}",
                        "source": "Open Technical Docs",
                        "duration": 25,
                        "is_primary": True,
                    }
                ],
                "questions": [
                    {
                        "question": f"What is the primary benefit of following structured modular design in {name}?",
                        "options": [
                            "Maintainability, modularity, and team collaboration efficiency",
                            "Increasing file sizes artificially",
                            "Avoiding automated code linting",
                            "Hardcoding application parameters",
                        ],
                        "correct_answer": "Maintainability, modularity, and team collaboration efficiency",
                        "explanation": "Standard design patterns make code clean, testable, and maintainable.",
                    },
                    {
                        "question": f"When configuring a project in {name}, what is the role of dependency management?",
                        "options": [
                            "Explicitly specifying and locking external library versions for reproducible builds",
                            "Deleting source code files automatically",
                            "Disabling network connectivity",
                            "Preventing unit testing",
                        ],
                        "correct_answer": "Explicitly specifying and locking external library versions for reproducible builds",
                        "explanation": "Dependency managers ensure consistent execution environments across team members.",
                    }
                ],
            },
            {
                "order": 2,
                "title": f"2. Essential Workflows & Data Management in {name}",
                "estimated_minutes": 45,
                "summary": f"Data handling, API communication, asynchronous patterns, and state management in {name}.",
                "content": f"# Essential Workflows in {name}\\n\\nBuild robust applications with clean data flow and error handling.",
                "video_url": f"https://www.youtube.com/results?search_query={encoded}+intermediate+tutorial+patterns",
                "pdf_url": "https://en.wikipedia.org/wiki/Software_engineering",
                "doc_url": f"https://en.wikipedia.org/wiki/{encoded}",
                "resources": [
                    {
                        "type": "VIDEO",
                        "title": f"{name} Best Practices & Architecture",
                        "url": f"https://www.youtube.com/results?search_query={encoded}+best+practices",
                        "source": "YouTube Educational Tech",
                        "duration": 35,
                        "is_primary": True,
                    }
                ],
                "questions": [
                    {
                        "question": f"Why is asynchronous non-blocking handling important in modern {name} applications?",
                        "options": [
                            "It prevents blocking the main thread during I/O and network operations",
                            "It makes code run in random order without purpose",
                            "It disables memory garbage collection",
                            "It is required only for command line scripts",
                        ],
                        "correct_answer": "It prevents blocking the main thread during I/O and network operations",
                        "explanation": "Asynchronous operations keep applications responsive during network requests.",
                    }
                ],
            },
            {
                "order": 3,
                "title": f"3. Testing, Security & Optimization in {name}",
                "estimated_minutes": 50,
                "summary": f"Unit testing, integration verification, security best practices, and performance profiling for {name}.",
                "content": f"# Testing & Optimization in {name}\\n\\nEnsure production reliability with automated tests and performance benchmarks.",
                "video_url": f"https://www.youtube.com/results?search_query={encoded}+testing+security+optimization",
                "pdf_url": "https://en.wikipedia.org/wiki/Software_testing",
                "doc_url": f"https://en.wikipedia.org/wiki/{encoded}",
                "resources": [
                    {
                        "type": "DOCS",
                        "title": f"Testing & Security Guide for {name}",
                        "url": f"https://en.wikipedia.org/wiki/{encoded}",
                        "source": "Technical Reference",
                        "duration": 30,
                        "is_primary": True,
                    }
                ],
                "questions": [
                    {
                        "question": f"What is the primary role of automated regression testing in {name} projects?",
                        "options": [
                            "Ensuring existing features continue to work as new changes are introduced",
                            "Slowing down deployment unnecessarily",
                            "Replacing code reviews entirely",
                            "Deleting unused variables automatically",
                        ],
                        "correct_answer": "Ensuring existing features continue to work as new changes are introduced",
                        "explanation": "Regression tests safeguard existing functionality against unintended regressions.",
                    }
                ],
            },
        ],
        "quiz": {
            "title": f"{name} Technical Certification Assessment",
            "description": f"Comprehensive timed exam evaluating architectural mastery, syntax, best practices, and testing in {name}.",
            "time_limit_minutes": 15,
            "passing_percentage": 70,
            "questions": [
                {
                    "question": f"Which principle is central to maintainable software in {name}?",
                    "options": [
                        "Single Responsibility Principle and clear separation of concerns",
                        "Monolithic code in a single file",
                        "Hardcoding credentials in source files",
                        "Disabling error logging in production",
                    ],
                    "correct_answer": "Single Responsibility Principle and clear separation of concerns",
                    "explanation": "Separation of concerns ensures code components remain modular and easily testable.",
                    "points": 25,
                },
                {
                    "question": f"How should sensitive secrets (such as API keys) be managed in {name} projects?",
                    "options": [
                        "Using environment variables and secure secret stores",
                        "Committing plain text keys directly to public Git repositories",
                        "Hardcoding keys in client-side source code",
                        "Sending keys via unencrypted URLs",
                    ],
                    "correct_answer": "Using environment variables and secure secret stores",
                    "explanation": "Environment variables isolate secrets from source repositories.",
                    "points": 25,
                },
                {
                    "question": f"What is the first step in resolving an unexpected runtime bug or performance bottleneck in {name}?",
                    "options": [
                        "Profiling and inspecting diagnostic logs and stack traces",
                        "Rewriting the whole codebase from scratch blindly",
                        "Deleting unit tests to save CPU cycles",
                        "Disabling SSL encryption",
                    ],
                    "correct_answer": "Profiling and inspecting diagnostic logs and stack traces",
                    "explanation": "Diagnostic traces identify the root cause of execution anomalies.",
                    "points": 25,
                },
                {
                    "question": f"In a collaborative Git workflow for {name}, what is the standard practice before merging code?",
                    "options": [
                        "Running automated test suites and conducting peer code reviews",
                        "Force-pushing directly to production branch without testing",
                        "Skipping commit messages",
                        "Deleting historical commits",
                    ],
                    "correct_answer": "Running automated test suites and conducting peer code reviews",
                    "explanation": "Automated verification and code review maintain code health and reliability.",
                    "points": 25,
                },
            ],
        },
    }

def _generate_academic_course(name: str, encoded: str) -> Dict[str, Any]:
    return {
        "title": f"{name} — Academic Mastery & Core Foundations",
        "description": f"Rigorous academic curriculum covering fundamental principles, problem-solving methodologies, theoretical proofs, and real-world applications in {name}.",
        "estimated_minutes": 160,
        "lessons": [
            {
                "order": 1,
                "title": f"1. Foundational Concepts & Terminology in {name}",
                "estimated_minutes": 35,
                "summary": f"Historical background, fundamental laws, equations, and basic definitions of {name}.",
                "content": f"# Foundations of {name}\\n\\nMaster the core principles and definitions of {name}.",
                "video_url": f"https://www.youtube.com/results?search_query=khan+academy+{encoded}+fundamentals",
                "pdf_url": "https://openstax.org",
                "doc_url": f"https://en.wikipedia.org/wiki/{encoded}",
                "resources": [
                    {
                        "type": "DOCS",
                        "title": f"{name} Open Educational Textbooks & Articles",
                        "url": f"https://en.wikipedia.org/wiki/{encoded}",
                        "source": "Open Educational Resources",
                        "duration": 30,
                        "is_primary": True,
                    }
                ],
                "questions": [
                    {
                        "question": f"What is the foundational approach to solving problems in {name}?",
                        "options": [
                            "Understanding first principles, defining known variables, and applying standard equations",
                            "Memorizing final numerical answers without understanding derivations",
                            "Ignoring units and dimensions",
                            "Skipping problem statements",
                        ],
                        "correct_answer": "Understanding first principles, defining known variables, and applying standard equations",
                        "explanation": "Structured problem-solving begins with first principles and dimensional analysis.",
                    },
                    {
                        "question": f"When formulating equations in {name}, why is dimensional consistency required?",
                        "options": [
                            "Both sides of a valid equation must have identical physical dimensions",
                            "It makes equations look symmetrical",
                            "It replaces mathematical proofs",
                            "It allows dividing by zero",
                        ],
                        "correct_answer": "Both sides of a valid equation must have identical physical dimensions",
                        "explanation": "Dimensional homogeneity is a physical prerequisite for algebraic validity.",
                    }
                ],
            },
            {
                "order": 2,
                "title": f"2. Analytical Techniques & Problem Solving in {name}",
                "estimated_minutes": 45,
                "summary": f"Step-by-step problem-solving methods, mathematical modeling, and case studies in {name}.",
                "content": f"# Analytical Techniques in {name}\\n\\nExplore quantitative frameworks and empirical problem-solving strategies.",
                "video_url": f"https://www.youtube.com/results?search_query={encoded}+problem+solving+techniques",
                "pdf_url": "https://openstax.org",
                "doc_url": f"https://en.wikipedia.org/wiki/{encoded}",
                "resources": [
                    {
                        "type": "VIDEO",
                        "title": f"{name} Solved Examples & Proofs",
                        "url": f"https://www.youtube.com/results?search_query={encoded}+solved+problems",
                        "source": "YouTube",
                        "duration": 35,
                        "is_primary": True,
                    }
                ],
                "questions": [
                    {
                        "question": f"Why is dimensional analysis critical when evaluating equations in {name}?",
                        "options": [
                            "It verifies physical consistency and catches unit conversion errors",
                            "It eliminates the need for mathematical proofs",
                            "It allows ignoring constants",
                            "It simplifies computer keyboards",
                        ],
                        "correct_answer": "It verifies physical consistency and catches unit conversion errors",
                        "explanation": "Dimensional homogeneity ensures that algebraic equations are physically plausible.",
                    },
                    {
                        "question": f"In analytical modeling for {name}, what is the role of boundary conditions?",
                        "options": [
                            "Specifying constraints at the extremes to determine specific solution constants",
                            "Ignoring real-world limits",
                            "Terminating computer simulations prematurely",
                            "Preventing data graphs from rendering",
                        ],
                        "correct_answer": "Specifying constraints at the extremes to determine specific solution constants",
                        "explanation": "Boundary values fix integration constants to yield physical solutions.",
                    }
                ],
            },
        ],
        "quiz": {
            "title": f"{name} Academic Proficiency Assessment",
            "description": f"Comprehensive academic exam testing definitions, derivations, proofs, and quantitative problem solving in {name}.",
            "time_limit_minutes": 20,
            "passing_percentage": 70,
            "questions": [
                {
                    "question": f"Which methodology is central to scientific and analytical inquiry in {name}?",
                    "options": [
                        "Hypothesis formulation, empirical experimentation, and rigorous data verification",
                        "Relying solely on anecdotal assumptions",
                        "Discarding contradictory experimental observations",
                        "Skipping mathematical derivations",
                    ],
                    "correct_answer": "Hypothesis formulation, empirical experimentation, and rigorous data verification",
                    "explanation": "The scientific method requires empirical verification and reproducible experimentation.",
                    "points": 25,
                },
                {
                    "question": f"When interpreting statistical data in {name}, what does a high correlation between two variables signify?",
                    "options": [
                        "There is a statistical relationship, but correlation does not imply direct causation",
                        "One variable definitively causes the other without exception",
                        "The dataset is invalid and must be deleted",
                        "Both variables must equal zero",
                    ],
                    "correct_answer": "There is a statistical relationship, but correlation does not imply direct causation",
                    "explanation": "Correlation indicates association, but confounding variables may be present.",
                    "points": 25,
                },
            ],
        },
    }

def _generate_language_course(name: str, encoded: str) -> Dict[str, Any]:
    return {
        "title": f"{name} — Fluency, Grammar & Conversational Mastery",
        "description": f"Master vocabulary, phonetics, syntax structures, grammar rules, and practical conversational fluency in {name}.",
        "estimated_minutes": 150,
        "lessons": [
            {
                "order": 1,
                "title": f"1. Alphabet, Phonetics & Core Vocabulary in {name}",
                "estimated_minutes": 35,
                "summary": f"Pronunciation fundamentals, alphabet/script, and essential daily vocabulary in {name}.",
                "content": f"# Alphabet & Phonetics in {name}\\n\\nLearn accurate pronunciation and master the foundational alphabet of {name}.",
                "video_url": f"https://www.youtube.com/results?search_query=learn+{encoded}+alphabet+pronunciation",
                "pdf_url": "https://en.wikipedia.org/wiki/Language",
                "doc_url": f"https://en.wikipedia.org/wiki/{encoded}",
                "resources": [
                    {
                        "type": "DOCS",
                        "title": f"{name} Phonetic Guide & Grammar Handbook",
                        "url": f"https://en.wikipedia.org/wiki/{encoded}",
                        "source": "Open Linguistic Resources",
                        "duration": 25,
                        "is_primary": True,
                    }
                ],
                "questions": [
                    {
                        "question": f"What is the most effective approach to mastering new vocabulary in {name}?",
                        "options": [
                            "Spaced repetition, contextual sentences, and active conversational practice",
                            "Translating isolated word lists without practicing speaking",
                            "Avoiding reading texts in {name}",
                            "Only studying once a year",
                        ],
                        "correct_answer": "Spaced repetition, contextual sentences, and active conversational practice",
                        "explanation": "Contextual usage and spaced repetition significantly enhance long-term language retention.",
                    },
                    {
                        "question": f"Why is phonetic articulation important when learning {name}?",
                        "options": [
                            "Accurate pronunciation prevents misunderstandings and aids listening comprehension",
                            "Pronunciation has no impact on conversation",
                            "It only matters for professional singers",
                            "Grammar rules make pronunciation irrelevant",
                        ],
                        "correct_answer": "Accurate pronunciation prevents misunderstandings and aids listening comprehension",
                        "explanation": "Phonetics ensures clear oral communication and acoustic recognition.",
                    }
                ],
            },
            {
                "order": 2,
                "title": f"2. Sentence Structure & Conversational Etiquette in {name}",
                "estimated_minutes": 40,
                "summary": f"Forming compound sentences, tenses, formal vs informal etiquette, and dialogues in {name}.",
                "content": f"# Conversations in {name}\\n\\nMaster greetings, inquiries, directions, and social conversations.",
                "video_url": f"https://www.youtube.com/results?search_query={encoded}+conversation+dialogues",
                "pdf_url": "https://en.wikipedia.org/wiki/Language",
                "doc_url": f"https://en.wikipedia.org/wiki/{encoded}",
                "resources": [
                    {
                        "type": "VIDEO",
                        "title": f"Daily Dialogues & Listening Practice for {name}",
                        "url": f"https://www.youtube.com/results?search_query={encoded}+dialogues+beginners",
                        "source": "YouTube",
                        "duration": 30,
                        "is_primary": True,
                    }
                ],
                "questions": [
                    {
                        "question": f"Why is understanding formal vs informal address important in {name}?",
                        "options": [
                            "It conveys appropriate social respect depending on context, age, and relationships",
                            "Formal words are always grammatically incorrect",
                            "It has no impact on comprehension",
                            "Informal words cannot be written down",
                        ],
                        "correct_answer": "It conveys appropriate social respect depending on context, age, and relationships",
                        "explanation": "Social register and politeness distinctions are central to linguistic etiquette.",
                    }
                ],
            },
        ],
        "quiz": {
            "title": f"{name} Language Proficiency Assessment",
            "description": f"Comprehensive language assessment evaluating vocabulary, syntax, grammar accuracy, and dialogue comprehension in {name}.",
            "time_limit_minutes": 15,
            "passing_percentage": 70,
            "questions": [
                {
                    "question": f"When engaging in a dialogue with a stranger in {name}, what is the recommended practice?",
                    "options": [
                        "Use polite formal greetings and clear enunciation",
                        "Use slang terms exclusively",
                        "Avoid responding to greetings",
                        "Speak in a whisper",
                    ],
                    "correct_answer": "Use polite formal greetings and clear enunciation",
                    "explanation": "Standard polite greetings establish positive communication rapport.",
                    "points": 50,
                },
                {
                    "question": f"Which strategy accelerates listening comprehension in {name}?",
                    "options": [
                        "Immersing in native audio with subtitles and shadowing pronunciation",
                        "Avoiding listening to native speakers",
                        "Reading only dictionary definitions",
                        "Never practicing pronunciation",
                    ],
                    "correct_answer": "Immersing in native audio with subtitles and shadowing pronunciation",
                    "explanation": "Active listening and vocal shadowing train auditory processing and phonetic fluency.",
                    "points": 50,
                }
            ],
        },
    }

def _generate_creative_course(name: str, encoded: str) -> Dict[str, Any]:
    return {
        "title": f"{name} — Creative Expression & Design Mastery",
        "description": f"Explore creative fundamentals, visual composition, techniques, digital/traditional tools, and portfolio creation in {name}.",
        "estimated_minutes": 140,
        "lessons": [
            {
                "order": 1,
                "title": f"1. Foundations, Principles & Aesthetics of {name}",
                "estimated_minutes": 35,
                "summary": f"Visual harmony, color/form theory, equipment/tools, and artistic techniques in {name}.",
                "content": f"# Foundations of {name}\\n\\nMaster core aesthetic principles and tools.",
                "video_url": f"https://www.youtube.com/results?search_query={encoded}+creative+techniques+masterclass",
                "pdf_url": "https://en.wikipedia.org/wiki/The_arts",
                "doc_url": f"https://en.wikipedia.org/wiki/{encoded}",
                "resources": [
                    {
                        "type": "DOCS",
                        "title": f"{name} Creative Guide & Techniques",
                        "url": f"https://en.wikipedia.org/wiki/{encoded}",
                        "source": "Open Arts Resources",
                        "duration": 25,
                        "is_primary": True,
                    }
                ],
                "questions": [
                    {
                        "question": f"What is the primary role of visual balance and contrast in {name}?",
                        "options": [
                            "Directing viewer attention, creating harmony, and emphasizing focal points",
                            "Making all elements identical in size and color",
                            "Overcrowding the canvas completely",
                            "Eliminating negative space",
                        ],
                        "correct_answer": "Directing viewer attention, creating harmony, and emphasizing focal points",
                        "explanation": "Contrast and balance guide visual hierarchy and aesthetic appeal.",
                    },
                    {
                        "question": f"How does repetition with variation create rhythm in {name}?",
                        "options": [
                            "It establishes visual patterns while sustaining viewer interest through subtle contrasts",
                            "It forces the viewer to look away immediately",
                            "It deletes layers from the canvas",
                            "It reduces print resolution",
                        ],
                        "correct_answer": "It establishes visual patterns while sustaining viewer interest through subtle contrasts",
                        "explanation": "Harmonious rhythm combines predictable repetition with engaging variation.",
                    }
                ],
            },
        ],
        "quiz": {
            "title": f"{name} Creative Mastery Assessment",
            "description": f"Comprehensive timed evaluation assessing aesthetic principles, tool mastery, and visual storytelling in {name}.",
            "time_limit_minutes": 15,
            "passing_percentage": 70,
            "questions": [
                {
                    "question": f"In creative composition for {name}, why is 'negative space' valuable?",
                    "options": [
                        "It gives the primary subject breathing room and prevents visual clutter",
                        "It indicates an incomplete project",
                        "It reduces the file resolution",
                        "It makes color reproduction impossible",
                    ],
                    "correct_answer": "It gives the primary subject breathing room and prevents visual clutter",
                    "explanation": "Negative space isolates the subject and enhances clarity.",
                    "points": 50,
                },
                {
                    "question": f"What is the first step in conceptualizing an original project in {name}?",
                    "options": [
                        "Brainstorming, moodboarding, and sketching preliminary compositions",
                        "Printing the final output without preparation",
                        "Deleting all reference materials",
                        "Skipping the planning phase",
                    ],
                    "correct_answer": "Brainstorming, moodboarding, and sketching preliminary compositions",
                    "explanation": "Iterative sketching and conceptualization produce robust final creations.",
                    "points": 50,
                },
            ],
        },
    }

def _generate_professional_course(name: str, encoded: str) -> Dict[str, Any]:
    return {
        "title": f"{name} — Professional Excellence & Leadership",
        "description": f"Master leadership, communication, strategic planning, client engagement, and high-impact workplace skills in {name}.",
        "estimated_minutes": 140,
        "lessons": [
            {
                "order": 1,
                "title": f"1. Strategic Frameworks & Fundamentals of {name}",
                "estimated_minutes": 35,
                "summary": f"Core methodologies, stakeholder communication, and industry standards for {name}.",
                "content": f"# Professional Frameworks in {name}\\n\\nEstablish effective workplace habits and strategies.",
                "video_url": f"https://www.youtube.com/results?search_query={encoded}+professional+skills+masterclass",
                "pdf_url": "https://en.wikipedia.org/wiki/Professional",
                "doc_url": f"https://en.wikipedia.org/wiki/{encoded}",
                "resources": [
                    {
                        "type": "DOCS",
                        "title": f"{name} Executive Summary & Practice Guidelines",
                        "url": f"https://en.wikipedia.org/wiki/{encoded}",
                        "source": "Professional Reference",
                        "duration": 25,
                        "is_primary": True,
                    }
                ],
                "questions": [
                    {
                        "question": f"What is the key to effective stakeholder management in {name}?",
                        "options": [
                            "Clear expectations, active listening, and transparent regular communication",
                            "Withholding status updates until project completion",
                            "Ignoring feedback from clients",
                            "Making unverified promises without data",
                        ],
                        "correct_answer": "Clear expectations, active listening, and transparent regular communication",
                        "explanation": "Transparency and proactive updates build stakeholder alignment and trust.",
                    },
                    {
                        "question": f"How should priorities be managed when facing multiple competing deadlines in {name}?",
                        "options": [
                            "Using priority matrices (Urgent vs Important) to focus on high-impact deliverables",
                            "Working on tasks completely at random",
                            "Ignoring all incoming client emails",
                            "Refusing to communicate with project managers",
                        ],
                        "correct_answer": "Using priority matrices (Urgent vs Important) to focus on high-impact deliverables",
                        "explanation": "Structured prioritization matrices ensure focus on strategic, value-driven milestones.",
                    }
                ],
            },
        ],
        "quiz": {
            "title": f"{name} Professional Certification Exam",
            "description": f"Timed exam evaluating leadership, strategic decision-making, and professional execution in {name}.",
            "time_limit_minutes": 15,
            "passing_percentage": 70,
            "questions": [
                {
                    "question": f"When leading a collaborative project in {name}, what is the best strategy for resolving team disagreements?",
                    "options": [
                        "Facilitating open dialogue, focusing on objective project goals, and finding constructive consensus",
                        "Imposing arbitrary decisions without discussion",
                        "Ignoring conflicting viewpoints",
                        "Canceling the project immediately",
                    ],
                    "correct_answer": "Facilitating open dialogue, focusing on objective project goals, and finding constructive consensus",
                    "explanation": "Collaborative problem-solving produces sustainable team consensus.",
                    "points": 50,
                },
                {
                    "question": f"Which metric is most critical when evaluating ROI in {name} initiatives?",
                    "options": [
                        "Measurable business outcomes against invested time and capital",
                        "Number of slide decks created",
                        "Length of internal meetings",
                        "Volume of emails sent",
                    ],
                    "correct_answer": "Measurable business outcomes against invested time and capital",
                    "explanation": "ROI measures quantifiable business impact versus total resource investment.",
                    "points": 50,
                },
            ],
        },
    }

def _generate_general_course(name: str, encoded: str) -> Dict[str, Any]:
    return {
        "title": f"{name} — Complete Practical Guide",
        "description": f"Structured practical curriculum covering foundational concepts, real-world techniques, and step-by-step mastery in {name}.",
        "estimated_minutes": 130,
        "lessons": [
            {
                "order": 1,
                "title": f"1. Foundations & Essential Techniques in {name}",
                "estimated_minutes": 35,
                "summary": f"Step-by-step introduction, safety/best practices, and core mechanics of {name}.",
                "content": f"# Foundations of {name}\\n\\nLearn the essential techniques and best practices of {name}.",
                "video_url": f"https://www.youtube.com/results?search_query={encoded}+tutorial+guide",
                "pdf_url": "https://en.wikipedia.org/wiki/Main_Page",
                "doc_url": f"https://en.wikipedia.org/wiki/{encoded}",
                "resources": [
                    {
                        "type": "DOCS",
                        "title": f"{name} Overview & Guide",
                        "url": f"https://en.wikipedia.org/wiki/{encoded}",
                        "source": "Open Educational Reference",
                        "duration": 25,
                        "is_primary": True,
                    }
                ],
                "questions": [
                    {
                        "question": f"What is the most effective way to build long-term proficiency in {name}?",
                        "options": [
                            "Consistent hands-on practice, feedback from peers, and progressive skill challenges",
                            "Only reading theory without ever practicing",
                            "Giving up after the first mistake",
                            "Skipping foundational techniques",
                        ],
                        "correct_answer": "Consistent hands-on practice, feedback from peers, and progressive skill challenges",
                        "explanation": "Deliberate practice and progressive challenge build genuine competence.",
                    },
                    {
                        "question": f"What should you do before attempting an advanced project in {name}?",
                        "options": [
                            "Ensure core fundamentals and safety prerequisites are thoroughly mastered",
                            "Jump directly into complex tasks without prior training",
                            "Ignore standard instructions",
                            "Skip safety equipment",
                        ],
                        "correct_answer": "Ensure core fundamentals and safety prerequisites are thoroughly mastered",
                        "explanation": "Mastering foundational mechanics prevents errors and builds a solid foundation for advanced work.",
                    }
                ],
            },
        ],
        "quiz": {
            "title": f"{name} Skill Certification Assessment",
            "description": f"Timed evaluation testing foundational knowledge and practical execution in {name}.",
            "time_limit_minutes": 15,
            "passing_percentage": 70,
            "questions": [
                {
                    "question": f"What is the first step when undertaking a new complex task in {name}?",
                    "options": [
                        "Understanding safety precautions, gathering necessary tools, and planning the steps",
                        "Rushing to execute without preparation",
                        "Ignoring standard guidelines",
                        "Skipping instructions",
                    ],
                    "correct_answer": "Understanding safety precautions, gathering necessary tools, and planning the steps",
                    "explanation": "Proper preparation and safety awareness ensure high quality and prevent accidents.",
                    "points": 50,
                },
                {
                    "question": f"How can you verify that you have successfully mastered a skill in {name}?",
                    "options": [
                        "By demonstrating consistent, reproducible results across varied practical scenarios",
                        "By reading a single article once",
                        "By guessing without testing",
                        "By copying someone else's work blindly",
                    ],
                    "correct_answer": "By demonstrating consistent, reproducible results across varied practical scenarios",
                    "explanation": "Mastery is demonstrated through consistent practical execution.",
                    "points": 50,
                },
            ],
        },
    }
