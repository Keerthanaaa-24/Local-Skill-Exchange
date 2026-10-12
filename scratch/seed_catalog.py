import os
import sys
import csv

# Add backend directory to path
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "backend")))

from app.db.database import SessionLocal
from app.db.models import Skill

DATA_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "backend", "data", "skills"))
CSV_FILE = os.path.join(DATA_DIR, "skills_dataset.csv")

SKILL_DOMAINS = {
    "Programming & Languages": [
        "Python", "JavaScript", "TypeScript", "Java", "C++", "C#", "C Language", "Go (Golang)", "Rust", "Kotlin",
        "Swift", "Dart", "PHP", "Ruby", "Scala", "R Programming", "Elixir", "Haskell", "Lua", "Julia",
        "Perl", "Clojure", "Erlang", "F#", "Groovy", "MATLAB", "Assembly Language", "Fortran", "COBOL", "Solidity",
        "Bash Scripting", "PowerShell", "Zsh", "Vimscript", "Scheme", "Racket", "OCaml", "Nim", "Zig", "D Language"
    ],
    "Web & Frontend Development": [
        "React", "Next.js", "Vue.js", "Nuxt.js", "Angular", "Svelte", "SvelteKit", "Remix", "Gatsby", "Astro",
        "HTML5", "CSS3", "Sass / SCSS", "Tailwind CSS", "Bootstrap 5", "Material-UI (MUI)", "Chakra UI", "Shadcn UI", "Ant Design", "PostCSS",
        "Webpack", "Vite", "Turbopack", "Rollup.js", "Babel", "WebAssembly (WASM)", "Progressive Web Apps (PWA)", "Redux Toolkit", "Zustand", "Pinia",
        "MobX", "Recoil", "Jotai", "jQuery", "Three.js", "D3.js", "Chart.js", "HTML5 Canvas", "WebGL", "WebSockets Client",
        "Server-Sent Events", "Micro-Frontends", "Storybook", "Framer Motion", "GSAP Animation", "Custom Web Components", "Core Web Vitals Optimization", "Responsive Web Design", "Cross-Browser Testing", "Frontend i18n"
    ],
    "Backend & Server Architecture": [
        "Node.js", "Express.js", "FastAPI", "Django", "Flask", "Spring Boot", "ASP.NET Core", "Ruby on Rails", "Laravel", "Symfony",
        "NestJS", "Fastify", "Koa.js", "Gin Framework (Go)", "Echo (Go)", "Fiber (Go)", "Actix Web (Rust)", "Axum (Rust)", "Rocket (Rust)", "Tornado",
        "Celery Task Queue", "RabbitMQ Messaging", "Apache Kafka", "Redis Caching", "Memcached", "GraphQL API Design", "Apollo Server", "gRPC & Protocol Buffers", "RESTful API Architecture", "OpenAPI / Swagger",
        "OAuth 2.0 & OIDC", "JWT Token Authentication", "Role-Based Access Control (RBAC)", "Microservices Architecture", "Event-Driven Architecture", "Domain-Driven Design (DDD)", "CQRS Architecture", "Serverless Architecture", "AWS Lambda Backend", "Google Cloud Functions",
        "Azure Functions", "SQLAlchemy ORM", "Hibernate ORM", "Prisma ORM", "TypeORM", "Drizzle ORM", "Entity Framework Core", "GORM (Go)", "Pydantic Validation", "Database Connection Pooling"
    ],
    "Mobile App Development": [
        "Flutter Development", "Flutter Riverpod", "Flutter Bloc", "Flutter Provider", "Flutter Animations", "Flutter Web & Desktop", "React Native", "React Native Reanimated", "Expo Framework", "Android Jetpack Compose",
        "Android XML Layouts", "Android Room DB", "Android Coroutines & Flow", "Android Retrofit", "iOS SwiftUI", "iOS UIKit", "iOS Core Data & SwiftData", "iOS Combine Framework", "Ionic Framework", "Capacitor Mobile",
        "Firebase Mobile SDK", "Firebase Cloud Messaging (FCM)", "Apple Push Notifications (APNs)", "In-App Purchases (IAP)", "App Store Optimization (ASO)", "Google Play Console", "Apple App Store Connect", "Fastlane Mobile CI/CD", "Mobile Deep Linking", "Mobile Offline Sync"
    ],
    "AI, Machine Learning & LLMs": [
        "PyTorch Deep Learning", "TensorFlow 2.0", "Keras", "Scikit-Learn", "Hugging Face Transformers", "Hugging Face Diffusers", "Large Language Models (LLMs)", "Generative AI Engineering", "Prompt Engineering", "LangChain",
        "LlamaIndex", "Retrieval-Augmented Generation (RAG)", "LLM Fine-Tuning (LoRA / QLoRA)", "Model Quantization (GGUF / AWQ)", "Stable Diffusion", "Midjourney Prompting", "Computer Vision", "OpenCV", "YOLO Object Detection", "Image Segmentation (Mask R-CNN / SAM)",
        "Natural Language Processing (NLP)", "Named Entity Recognition (NER)", "Sentiment Analysis", "Speech-to-Text (OpenAI Whisper)", "Text-to-Speech (TTS)", "Reinforcement Learning (RLHF)", "Deep Q-Learning", "Graph Neural Networks (GNN)", "Time Series Forecasting (Prophet / ARIMA)", "XGBoost",
        "LightGBM", "CatBoost", "Feature Engineering", "Model Evaluation Metrics", "MLOps Infrastructure", "MLflow", "Kubeflow Pipelines", "Weights & Biases", "DVC (Data Version Control)", "Triton Inference Server",
        "ONNX Runtime", "NVIDIA TensorRT", "DeepSpeed", "vLLM High-Throughput Serving", "Ollama Local Deployment", "LangSmith Observability", "Vector Databases (Pinecone / Chroma / Milvus / Qdrant)", "Autonomous AI Agents (CrewAI / AutoGPT)", "Semantic Search", "Explainable AI (SHAP / LIME)"
    ],
    "Data Science, Big Data & Analytics": [
        "Data Analysis with Pandas", "NumPy Numerical Computing", "SciPy", "Matplotlib Visualization", "Seaborn Statistical Plots", "Plotly Interactive Dashboards", "Tableau Desktop", "Microsoft Power BI", "Google Looker Studio", "Excel Advanced Formulas",
        "Excel VBA & Macros", "SQL for Data Analytics", "Window Functions in SQL", "Exploratory Data Analysis (EDA)", "Statistical Hypothesis Testing (t-tests / ANOVA)", "A/B Testing & Experimentation", "Bayesian Data Analysis", "Probability Theory & Distributions", "Linear & Logistic Regression", "Clustering (K-Means / DBSCAN)",
        "Dimensionality Reduction (PCA / t-SNE)", "Web Scraping (BeautifulSoup / Playwright)", "ETL Pipeline Design", "Data Cleaning & Imputation", "Data Warehousing", "Snowflake Data Warehouse", "Google BigQuery", "Amazon Redshift", "Databricks Lakehouse", "Apache Spark (PySpark)",
        "Spark Streaming", "Apache Flink", "dbt (Data Build Tool)", "Apache Airflow", "Prefect Orchestration", "Dagster Orchestration", "Data Quality Testing", "Customer Lifetime Value (CLV)", "Customer Churn Prediction", "Market Basket Analysis"
    ],
    "Databases & Storage": [
        "MySQL Database", "PostgreSQL Advanced", "SQLite Database", "Microsoft SQL Server (T-SQL)", "Oracle Database", "MariaDB", "MongoDB Document DB", "Apache Cassandra", "Couchbase NoSQL", "Amazon DynamoDB",
        "Google Cloud Firestore", "Supabase PostgreSQL", "CockroachDB Distributed SQL", "ClickHouse OLAP DB", "DuckDB Analytical DB", "TimescaleDB Time-Series", "InfluxDB Time-Series", "Elasticsearch Search Engine", "OpenSearch Management", "Redis In-Memory DB",
        "Memcached", "Neo4j Graph Database", "Amazon Aurora", "Database Index Optimization", "Database Sharding & Partitioning", "Database Replication", "Query Execution Plan Tuning (EXPLAIN)", "Database Migrations (Alembic / Flyway)", "ACID Transactions", "CAP Theorem Architecture"
    ],
    "Cloud Computing & Infrastructure": [
        "Amazon Web Services (AWS Architecture)", "AWS EC2 Virtual Servers", "AWS S3 Object Storage", "AWS Lambda Serverless", "AWS RDS & Aurora", "AWS ECS Container Service", "AWS EKS Kubernetes Service", "AWS IAM Security", "AWS CloudFront CDN", "AWS VPC Networking",
        "Microsoft Azure Fundamentals", "Azure Virtual Machines", "Azure Blob Storage", "Azure App Services", "Azure Kubernetes Service (AKS)", "Google Cloud Platform (GCP)", "GCP Compute Engine", "GCP Cloud Storage", "GCP Google Kubernetes Engine (GKE)", "GCP BigQuery Cloud",
        "Docker Containerization", "Docker Compose", "Kubernetes Cluster Management", "Kubernetes Helm Charts", "Kubernetes Ingress & Services", "Kubernetes ConfigMaps & Secrets", "Terraform Infrastructure as Code", "Terraform Cloud", "Ansible Configuration Management", "Linux Server Administration",
        "Ubuntu / Debian Server Management", "Red Hat Enterprise Linux (RHEL)", "Nginx Web Server & Reverse Proxy", "Apache HTTP Web Server", "HAProxy Load Balancing", "Cloudflare DNS & CDN", "Serverless Framework", "Site Reliability Engineering (SRE)", "Infrastructure Monitoring", "Disaster Recovery Planning"
    ],
    "DevOps, CI/CD & Observability": [
        "GitHub Actions CI/CD", "GitLab CI/CD Pipelines", "Jenkins Automation Server", "CircleCI", "ArgoCD GitOps", "Flux GitOps", "Prometheus Metrics Monitoring", "Grafana Dashboards", "PromQL Query Language", "ELK Stack (Elasticsearch / Logstash / Kibana)",
        "Datadog APM & Metrics", "New Relic Observability", "Sentry Real-Time Error Tracking", "OpenTelemetry Tracing", "Jaeger Distributed Tracing", "Grafana Loki Logging", "Chaos Engineering", "Blue-Green Deployments", "Canary Deployments", "Git Branching Strategies (GitFlow / Trunk-Based)",
        "Semantic Versioning", "SonarQube Code Quality Scanning", "Container Vulnerability Scanning (Trivy)", "Secret Management (HashiCorp Vault / AWS Secrets Manager)", "Zero Downtime Deployments", "PFSense Firewall DevOps", "Linux Performance Tuning", "Release Engineering", "Build Automation", "Continuous Security (DevSecOps)"
    ],
    "Cybersecurity & Ethical Hacking": [
        "Ethical Hacking & Penetration Testing", "Network Penetration Testing", "Web App Penetration Testing", "Wireshark Packet Analysis", "Metasploit Framework", "Nmap Port Scanning", "Burp Suite Professional", "OWASP Top 10 Remediation", "SQL Injection (SQLi) Prevention", "Cross-Site Scripting (XSS) Mitigation",
        "Cross-Site Request Forgery (CSRF) Prevention", "Server-Side Request Forgery (SSRF) Defense", "Security Operations Center (SOC) Analysis", "SIEM Management (Splunk / QRadar / Sentinel)", "Incident Handling & Response Plans", "Digital Forensics (Autopsy / Volatility)", "Malware Analysis Fundamentals", "Reverse Engineering (Ghidra / IDA Pro)", "Cryptography & Encryption (AES / RSA / ECC)", "Public Key Infrastructure (PKI)",
        "Firewall Rule Configuration", "Intrusion Detection Systems (Snort / Suricata)", "Zero Trust Network Architecture (ZTNA)", "AWS Cloud Security", "Azure Security Center", "Identity & Access Management (IAM & MFA)", "Social Engineering Awareness", "Cyber Threat Intelligence (OSINT)", "MITRE ATT&CK Mapping", "CompTIA Security+ Mastery"
    ],
    "UI/UX Design & User Research": [
        "Figma UI Design Mastery", "Figma Auto Layout 5.0", "Figma Component Libraries & Design Systems", "Figma Interactive Prototyping", "Figma Variables & Tokens", "User Experience (UX) Architecture", "User Interface (UI) Visual Hierarchy", "User Research & Interviews", "Wireframing (Low & High Fidelity)", "Usability Testing & Heuristic Evaluation",
        "Information Architecture & Sitemaps", "User Journey & Experience Mapping", "User Persona Development", "Competitive UX Benchmarking", "iOS Human Interface Guidelines (HIG)", "Google Material Design 3", "Accessibility Design (WCAG 2.1 AA)", "Micro-Interactions Design", "Adobe XD Prototyping", "Sketch App for Mac",
        "InVision Workflows", "UX Writing & Content Design", "Card Sorting & Treejack Testing", "Customer Empathy Mapping", "Design Thinking Workshop Facilitation", "Affinity Diagramming", "Atomic Design Methodology", "Design Handoff Documentation", "Color Theory & Contrast in UI", "Typography Hierarchy in UI"
    ],
    "Graphic Design & Visual Arts": [
        "Adobe Photoshop Professional", "Adobe Illustrator Vector Art", "Adobe InDesign Editorial Layout", "Logo Design & Visual Identity", "Typography & Font Pairing", "Color Palette Harmony & Psychology", "Poster & Billboard Design", "Brochure & Print Layout", "Packaging & Label Design", "Canva Pro Graphic Design",
        "Digital Painting (Photoshop / Clip Studio)", "Procreate iPad Illustration", "Concept Art for Characters & Environments", "Infographic Design & Data Storytelling", "Icon Design & SVG Systems", "Apparel & Merch Design", "Book Cover & Jacket Design", "Social Media Carousel & Banner Design", "Brand Style Guide Creation", "Caricature & Cartoon Illustration",
        "Pixel Art Creation (Aseprite)", "Matte Painting for Film & Games", "Traditional & Digital Calligraphy", "Album Art & Vinyl Packaging", "Vector Mascot Design", "Photo Retouching & Beauty Clean-up", "Photo Frequency Separation", "Photo Manipulation & Surreal Compositing", "Pattern Design for Textiles", "Sticker & Badge Design"
    ],
    "3D Modeling, Animation & Game Development": [
        "Blender 3D Modeling Fundamentals", "Blender Digital Sculpting", "Blender UV Unwrapping & Retopology", "Blender Procedural Shading & Nodes", "Blender Lighting & Cycles/Eevee Rendering", "Blender Rigging & Weight Painting", "Blender Keyframe 3D Animation", "Autodesk Maya 3D Animation", "Autodesk 3ds Max Architectural Modeling", "Maxon Cinema 4D Motion Graphics",
        "ZBrush High-Detail Sculpting", "Adobe Substance 3D Painter Texturing", "Unity Game Engine Fundamentals", "Unity C# Gameplay Scripting", "Unity 2D Game Mechanics", "Unity 3D Physics & Raycasting", "Unity Particle Systems", "Unity UI Toolkit", "Unreal Engine 5 Fundamentals", "Unreal Engine Blueprints Scripting",
        "Unreal Engine C++ Game Development", "Unreal Engine Nanite & Lumen", "Godot 4 Game Engine", "Godot GDScript Programming", "2D Skeletal Animation (Spine 2D)", "Motion Capture (MoCap) Data Cleanup", "Adobe After Effects Motion Graphics", "Visual Effects (VFX) Compositing", "3D Architectural Visualization", "Game Level Design & Whiteboxing",
        "Game Audio & Sound FX (FMOD / Wwise)", "Shader Programming (HLSL / GLSL / Shader Graph)", "VR Game Development (Meta Quest / OpenXR)", "AR Game Development (ARKit / ARCore)", "Game Optimization & Frame Profiling", "3D Character Modeling", "Environment Art & Terrains", "Rigging Bipedal & Quadruped Characters", "Hard-Surface 3D Modeling", "Game Mechanics Prototyping"
    ],
    "Music Production & Audio Engineering": [
        "FL Studio Beatmaking & Arranging", "Ableton Live Electronic Music Production", "Logic Pro Recording & Mixing", "Pro Tools Professional Audio Editing", "Cubase DAW Orchestral Production", "Studio One Workflows", "Reaper DAW Customization", "Audio Mixing Fundamentals (Gain Staging & Balance)", "Audio Mastering for Streaming Platforms", "Vocal Pitch Correction (Melodyne / Auto-Tune)",
        "Synthesizer Sound Design (Xfer Serum)", "Wavetable Synthesis (Vital / Pigments)", "Subtractive & FM Synthesis (Massive / FM8)", "Parametric EQ Shaping & Dynamic EQ", "Compressors, Limiters & Multiband Dynamics", "Reverb, Delay & Spatial Acoustic Design", "Drum Programming & Groove Sequencing", "MIDI Composition & Orchestration", "Podcast Recording & Audio Cleanup (iZotope RX)", "Voiceover Processing & De-essing",
        "Foley Sound Creation & Field Recording", "Film & Video Game Scoring", "Loudness Standards (LUFS Normalization)", "Music Theory for Producers (Chord Progressions & Modes)", "Songwriting Structure & Melodic Hooks", "Commercial Jingle & Ad Music Production", "Electronic Dance Music (EDM / House / Techno) Production", "Hip-Hop, Trap & Drill Beat Production", "Lo-Fi Hip Hop Beatmaking", "Pop Music Vocal Production",
        "Rock & Metal Guitar Mixing", "Acoustic Instrument Tracking & Microphone Techniques", "Studio Room Acoustic Treatment", "Live Sound Mixing & Console Setup", "Stereo Imaging & Mid/Side Processing", "Sampling & Sample Chopping Techniques", "Bassline Synthesis (808s & Sub Bass)", "Tape Saturation & Analog Warmth", "DJing with Pioneer CDJs & Rekordbox", "DJing with Serato DJ Pro"
    ],
    "Musical Instruments & Vocal Training": [
        "Acoustic Guitar Strumming & Chords", "Electric Guitar Lead Playing & Pentatonic Scales", "Fingerstyle Guitar Techniques", "Classical Guitar Repertoire", "Bass Guitar Slap & Groove Playing", "Beginner Piano Fundamentals", "Jazz Piano Chords & Voicings", "Classical Piano Pieces & Technique", "Synthesizer & Keyboard Performance", "Acoustic Drum Kit Fundamentals & Rudiments",
        "Electronic Drumming & Finger Drumming (MPC / Maschine)", "Violin Posture & Bowing Technique", "Cello Performance & Tone Production", "Ukulele Strumming & Songs", "Vocal Warmups & Diaphragmatic Breathing", "Expanding Vocal Range & Pitch Accuracy", "Bel Canto Classical Singing Method", "Contemporary Pop & R&B Vocal Techniques", "Harmonizing & Backing Vocal Arranging", "Saxophone (Alto & Tenor) Embouchure & Scales",
        "Trumpet Tone & Fingerings", "Flute Breathing & Finger Technique", "Blues Harmonica (Bending Notes)", "Clarinet Fundamentals", "Sight-Reading Standard Sheet Music", "Ear Training & Solfege Exercises", "Indian Classical Vocals (Ragas & Taals)", "Tabla Hand Drumming & Bols", "Djembe West African Rhythms", "Cajon Flamenco & Acoustic Beats",
        "Mandolin Chords & Tremolo", "5-String Banjo Scruggs Style", "Singing High Notes without Strain (Mix Voice)", "Vocal Vibrato Development", "Microphone Technique for Live Singing", "Stage Confidence for Vocalists", "Acoustic Song Arrangement for Solo Performer", "Bassline Walking in Jazz", "Slide Guitar Tuning & Techniques", "Music Improvisation in Any Key"
    ],
    "Foreign Languages & Linguistics": [
        "Conversational Spanish for Beginners", "Spanish Grammar & Subjunctive Mood", "Medical Spanish for Healthcare Professionals", "Business Spanish Communications", "French for Beginners & Travelers", "French Intermediate Conversation & Pronunciation", "French Advanced Grammar & Literature", "German for Beginners (A1-A2)", "German Conversational Fluency (B1-B2)", "German Business Vocabulary",
        "Mandarin Chinese Pinyin & Pronunciation", "Mandarin Chinese Character Writing (Hanzi)", "Mandarin Chinese HSK Exam Preparation", "Conversational Mandarin for Business", "Japanese Hiragana & Katakana Mastery", "Japanese Kanji Learning Strategies", "Japanese Conversational Politeness (Keigo)", "Japanese JLPT Exam Preparation (N5-N1)", "Korean Hangul Alphabet & Phonetics", "Conversational Korean & Culture",
        "Italian Language for Travelers & Foodies", "Italian Intermediate Grammar", "Russian Language Alphabet & Cases", "Russian Conversational Practice", "Modern Standard Arabic (MSA) Reading & Writing", "Egyptian Arabic Dialect Conversation", "Levantine Arabic Dialect", "Brazilian Portuguese Conversation", "European Portuguese Essentials", "Hindi Language Speaking & Devanagari Script",
        "Dutch Language for Beginners", "Swedish Language Basics", "Greek Language Fundamentals", "Turkish Language for Beginners", "Vietnamese Tones & Conversation", "Thai Language Script & Basics", "Indonesian Language (Bahasa Indonesia)", "Polish Language Grammar & Vocabulary", "American Sign Language (ASL) Signs & Fingerspelling", "British Sign Language (BSL) Basics",
        "English as a Second Language (ESL Conversation)", "Business English for Global Professionals", "IELTS Academic Exam Preparation", "TOEFL iBT Test Strategies", "English Pronunciation & Accent Reduction"
    ],
    "Business, Strategy & Entrepreneurship": [
        "Agile Project Management Methodologies", "Certified Scrum Master (CSM) Principles", "Kanban Board Workflow Management", "Product Management Roadmap Execution", "OKRs (Objectives and Key Results) Setting", "Strategic Planning & SWOT Analysis", "Financial Modeling for Startups in Excel", "Discounted Cash Flow (DCF) Valuation", "Business Analysis & Functional Requirements", "Lean Startup Build-Measure-Learn Loop",
        "Venture Capital Fundraising & Pitch Decks", "Angel Investor Networking", "Supply Chain Management & Logistics", "Operations Management & Process Mapping", "Change Management (Kotter 8-Step Model)", "Enterprise Risk Management (ERM)", "Business Process Reengineering (BPR)", "Corporate Governance & Compliance", "High-Stakes Negotiation Tactics", "Public Speaking & Executive Presence",
        "Executive Coaching & Leadership Development", "Team Building & Cross-Functional Leadership", "Stakeholder Expectation Management", "Crisis Management & Strategic PR", "Franchise Business Operations", "E-Commerce Business Model Strategy", "Customer Relationship Management (CRM Architecture)", "Six Sigma Green Belt Methodologies", "Market Research & Customer Discovery", "Brand Positioning & Brand Architecture",
        "Mergers & Acquisitions (M&A) Due Diligence", "Competitive Intelligence & Porter Five Forces", "Organizational Behavior & Corporate Culture", "Bootstrapping & Cash Flow Management", "Business Contract Review Fundamentals", "Intellectual Property & Trademark Basics", "Strategic Partnerships & Business Development", "Pricing Strategies (Value-Based / Freemium / Tiered)", "Outsourcing & Offshore Team Management", "Corporate Social Responsibility (CSR) Strategies"
    ],
    "Digital Marketing, Advertising & Sales": [
        "Search Engine Optimization (SEO Fundamentals)", "On-Page SEO & Content Optimization", "Technical SEO (Crawlability, Indexing, Schema)", "Link Building & Off-Page SEO Strategies", "Google Search Console & GA4 Setup", "Google Ads Search Campaigns (PPC)", "Google Ads Display & Performance Max", "Meta Ads Manager (Facebook & Instagram Ads)", "TikTok Ads & Spark Ads Campaigns", "LinkedIn B2B Ads & InMail Campaigns",
        "Content Marketing Strategy & Calendars", "Direct Response Copywriting", "Landing Page Copywriting & Conversion", "Email Marketing Strategy with Klaviyo", "Email Newsletter Automation with Mailchimp", "Sales Funnel Design (ClickFunnels / Leadpages)", "Affiliate Marketing Program Setup", "Influencer Outreach & Contract Negotiation", "Social Media Community Management", "Conversion Rate Optimization (CRO & Heatmaps)",
        "B2B Outbound Prospecting & Cold Emailing", "Cold Calling Mastery & Handling Objections", "High-Ticket Sales Closing Techniques", "Salesforce CRM Pipeline Management", "HubSpot Inbound Marketing Methodology", "Viral Short-Form Video Strategy (TikTok / Reels / Shorts)", "Podcast Sponsorships & Audio Advertising", "Press Release Writing & Media Pitching", "Amazon FBA Product Listing Optimization", "Shopify Store Optimization & Marketing",
        "Brand Narrative & Storytelling Frameworks", "Video Sales Letter (VSL) Scripting", "SMS Marketing & WhatsApp Campaigns", "Retargeting Campaigns & Pixel Tracking", "Apple Search Ads (ASA)", "Multi-Touch Marketing Attribution Modeling", "Customer Retention & Loyalty Program Design", "Webinar Marketing & Automated Funnels", "Event Marketing & Trade Show Strategy", "Guerrilla & Growth Hacking Marketing"
    ],
    "Finance, Accounting & Wealth Building": [
        "Personal Budgeting & Debt Elimination (Snowball / Avalanche)", "Stock Market Fundamentals & Equity Research", "Technical Analysis (Candlesticks, Support/Resistance, RSI, MACD)", "Options Trading Strategies (Covered Calls, Spreads, Iron Condors)", "Financial Accounting & General Ledger", "QuickBooks Online Bookkeeping", "Xero Cloud Accounting", "Corporate Financial Statement Analysis (P&L, Balance Sheet, Cash Flow)", "US Federal Income Tax Preparation & Deductions", "Real Estate Investment Analysis (Cap Rate, NOI, Cash-on-Cash)",
        "Commercial Real Estate Due Diligence", "Cryptocurrency Trading & Risk Management", "DeFi (Decentralized Finance) Yield Farming & Staking", "Solidity Smart Contract Development", "Web3 Architecture & Decentralized Apps", "Algorithmic Trading Strategies in Python", "Value Investing Principles (Benjamin Graham & Warren Buffett)", "Dividend Growth Investing Strategy", "Retirement Planning (401k, Traditional & Roth IRA)", "Estate Planning, Wills & Living Trusts",
        "Internal Auditing & SOX Compliance", "Forensic Accounting Basics", "Cost Accounting & Variance Analysis", "Macroeconomics & Interest Rate Impacts", "Commodities Trading (Gold, Oil, Agriculture)", "Forex Currency Trading (FX Pairs & Pips)", "Venture Capital Term Sheets & Cap Tables", "Peer-to-Peer Lending & Alternative Investments", "Health Savings Accounts (HSA) Wealth Strategies", "Financial Independence / Retire Early (FIRE) Planning"
    ],
    "Health, Fitness, Athletics & Wellness": [
        "Personal Fitness Coaching & Program Design", "Hypertrophy & Muscle Building Protocols", "Powerlifting Mechanics (Squat, Bench Press, Deadlift)", "Calisthenics & Bodyweight Gymnastic Strength", "High-Intensity Interval Training (HIIT)", "Vinyasa Flow Yoga Practice", "Hatha Yoga Alignment & Asanas", "Yin Yoga & Deep Fascial Release", "Mat Pilates & Core Stability", "Reformer Pilates Techniques",
        "Kettlebell Training (Swings, Snatches, Turkish Get-Ups)", "Olympic Weightlifting (Snatch, Clean and Jerk)", "Marathon & Half-Marathon Training Schedules", "Sprint Mechanics & Acceleration Drills", "Postural Restoration & Ergonomic Alignment", "Mobility Training & Joint Health (CARs / FRC)", "Sports Injury Prevention & Active Recovery", "Macronutrient Calculation & Flexible Dieting (IIFYM)", "Meal Prep Strategies for Lean Muscle", "Sports Nutrition & Ergogenic Aids",
        "Boxing Stance, Footwork & Combinations", "Muay Thai Striking (Elbows, Knees, Kicks)", "Brazilian Jiu-Jitsu (BJJ) Ground Submissions & Escapes", "Practical Self-Defense for Real-World Scenarios", "Freestyle Swimming Technique & Breath Timing", "Road Cycling Endurance & Cadence Training", "Indoor Bouldering & Rock Climbing Footwork", "Tennis Serve & Groundstroke Biomechanics", "Basketball Shooting Mechanics & Ball Handling", "Soccer Dribbling, Passing & Tactical Positioning",
        "Golf Swing Fundamentals & Driving Consistency", "Mindfulness Meditation & Body Scans", "Wim Hof & Controlled Breathwork Protocols", "Sleep Hygiene & Circadian Rhythm Optimization", "Stress Management & Nervous System Regulation", "Ice Baths & Cold Exposure Therapy", "Sauna Protocols for Cardiovascular Health", "Foam Rolling & Self-Myofascial Release", "Youth Athletic Development & Conditioning", "Senior Fitness & Fall Prevention"
    ],
    "Culinary Arts, Baking & Beverage Craft": [
        "Knife Handling & Precision Knife Cuts (Julienne, Brunoise, Chiffonade)", "The 5 French Mother Sauces (Béchamel, Velouté, Espagnole, Tomato, Hollandaise)", "Handmade Italian Pasta (Tagliatelle, Ravioli, Gnocchi)", "Artisan Sourdough Bread & Wild Yeast Starters", "French Pastry & Viennoiserie (Croissants, Pain au Chocolat)", "Éclairs, Cream Puffs & Choux Pastry", "Cake Baking, Layering & Crumb Coating", "Fondant Modeling & Sugar Flower Art", "Chocolate Tempering & Handcrafted Truffles", "Asian Wok Cooking & High-Heat Stir-Frying",
        "Traditional Japanese Sushi & Nigiri Craft", "Authentic Ramen Broth (Tonkotsu / Shoyu / Miso)", "Indian Spicing, Tadka & Curry Making", "Authentic Mexican Salsas, Mole & Taco Craft", "Texas Low & Slow BBQ Smoking (Brisket, Ribs, Pulled Pork)", "Sous Vide Precision Cooking & Searing", "Modern Culinary Food Plating & Presentation", "Gourmet Plant-Based & Vegan Cooking", "Gluten-Free Baking Substitutions & Science", "Lacto-Fermentation (Kimchi, Sauerkraut, Pickles)",
        "Kombucha & Water Kefir Home Brewing", "Sommelier Wine Tasting & Food Pairing Principles", "Craft Beer Homebrewing & All-Grain Mashing", "Craft Cocktail Mixology & Classic Cocktails", "Bar Equipment Mastery (Shakers, Jiggers, Strainers)", "Specialty Coffee Pour-Over Brewing (V60, Chemex, Aeropress)", "Espresso Machine Operation, Dialing In & Latte Art", "Artisan Cheese Making (Mozzarella, Ricotta, Cheddar)", "Home Food Dehydration & Jerky Making", "Home Pressure Canning & Jam Preserving",
        "Molecular Gastronomy (Spherification & Foams)", "Kitchen Inventory & Food Cost Management", "Food Safety & ServSafe Hygiene Standards", "Dessert Plating & Coulis Garnishing", "Herb & Spice Flavor Profiles Around the World", "Seafood Filleting & Cooking Methods", "Poultry Butchery & Roasting Techniques", "Beef Cuts & Steak Searing Techniques", "Vegetarian Mediterranean Cooking", "Homemade Pizza Dough & High-Temp Baking"
    ],
    "Photography & Videography Production": [
        "DSLR / Mirrorless Camera Manual Exposure Triangle (ISO, Aperture, Shutter)", "Portrait Photography & Lighting Setup", "Landscape & Scenic Nature Photography", "Street Photography & Candid Moments", "Commercial Product Photography & Tabletop Sets", "Real Estate & Architectural Photography (HDR / Flambient)", "Macro & Close-Up Photography", "Astrophotography & Milky Way Capture", "Food Photography & Food Styling Tricks", "Adobe Lightroom Classic Catalog & RAW Processing",
        "Lightroom Presets Creation & Batch Editing", "Adobe Photoshop Frequency Separation for Portraits", "Cinematic Composition & Rule of Thirds", "Studio Lighting (Key, Fill, Rim, Softboxes, Modifiers)", "Golden Hour & Natural Available Lighting", "Video Editing in Adobe Premiere Pro", "Video Editing in DaVinci Resolve", "Color Grading with DaVinci Resolve Color Wheels & LUTs", "Final Cut Pro X Video Editing Workflow", "FAA Part 107 Drone Piloting & Aerial Cinematography",
        "3-Axis Gimbal Balance & Camera Movement Techniques", "Wireless Lav & Shotgun Mic Audio Recording for Video", "YouTube Video Production & Hook Crafting", "Instagram Reels & TikTok Short-Form Video Editing", "Documentary Film Production & B-Roll Storytelling", "Wedding Photography Shot List & Pacing", "Event & Concert Photography in Low Light", "Green Screen Chroma Keying & Clean Plates", "Time-Lapse & Hyperlapse Shooting & Deflicker", "Prime vs Zoom Lens Selection & Optical Theory",
        "Slow-Motion 120fps Video Capture", "Multi-Camera Syncing & Multicam Editing", "Video Compression & Bitrate Encoding for Web", "Stop Motion Animation Techniques", "Underwater Photography Basics", "Action Sports Photography & High Burst Shutter", "Flash Photography & On-Camera Speedlights", "Off-Camera Flash (OCF) Radio Triggers", "Fashion Photography & Editorial Direction", "Client Photo Gallery Delivery (Pixieset / ShootProof)"
    ],
    "Crafts, DIY, Maker & Fabrication": [
        "Woodworking Joinery (Mortise & Tenon, Dovetails, Pocket Holes)", "Hand Tool Woodworking (Chisels, Hand Planes, Japanese Saws)", "Custom Furniture Building & Table Construction", "Wood Finishing (Staining, Polyurethane, Tung Oil, Danish Oil)", "Leathercraft Pattern Cutting & Pricking Irons", "Saddle Stitching by Hand for Leather Goods", "Leather Wallet, Belt & Bag Fabrication", "Pottery Wheel Throwing (Centering, Pulling, Trimming)", "Ceramic Handbuilding (Pinch Pots, Coils, Slab Construction)", "Ceramic Underglazing & High-Fire Glaze Chemistry",
        "Knitting Basics (Cast On, Knit, Purl, Bind Off)", "Knitting Sweaters & Circular Needle Work", "Crochet Stitches (Single, Double, Treble, Magic Ring)", "Amigurumi Stuffed Toy Crocheting", "Sewing Machine Operation & Threading", "Garment Pattern Drafting & Alterations", "Hand Embroidery & Decorative Stitches", "Quilting Block Assembly & Free-Motion Quilting", "3D Printer Calibration & Bed Leveling (FDM / SLA)", "3D Slicer Configuration (OrcaSlicer / Bambu Studio / Cura)",
        "3D Modeling for Fabrication (Autodesk Fusion 360)", "SolidWorks Mechanical Part Design", "Arduino C++ Microcontroller Programming", "Raspberry Pi Linux Hardware Projects", "Through-Hole & SMD Soldering Techniques", "Custom PCB Design with KiCAD", "CNC Router Setup & G-Code Generation", "CO2 & Diode Laser Cutting / Engraving", "Epoxy Resin Art & Live-Edge River Tables", "Wire Wrapping & Beaded Jewelry Design",
        "Precious Metal Clay (PMC) Silver Jewelry", "Stained Glass Foiling (Tiffany Method) & Soldering", "Candle Making (Soy Wax, Coconut Wax, Fragrance Load)", "Cold Process Soap Making (Lye Safety, Superfatting)", "Origami & Paper Sculpture Engineering", "Bookbinding & Custom Leather Journal Crafting", "Macrame Knots & Boho Wall Hangings", "Pyrography & Wood Burning Art", "Miniature Painting (Warhammer / Tabletop Miniatures)", "Blacksmithing Basics (Forging, Tapering, Anvil Work)"
    ],
    "Academic Tutoring, Mathematics & Sciences": [
        "Elementary & Middle School Mathematics", "High School Algebra I & II", "Geometry & Geometric Proofs", "Pre-Calculus & Trigonometry", "AP Calculus AB / BC Prep", "Multivariable Calculus & Vector Fields", "Differential Equations & Laplace Transforms", "Linear Algebra (Matrices, Eigenvalues, Vector Spaces)", "Discrete Mathematics (Set Theory, Combinatorics, Graph Theory)", "Probability & Mathematical Statistics",
        "High School Physics (Newtonian Mechanics)", "AP Physics C (Mechanics & Electricity)", "Thermodynamics & Heat Transfer", "Quantum Mechanics Fundamentals", "General Chemistry & Chemical Bonding", "Organic Chemistry Reactions & Mechanisms", "Physical Chemistry (Kinetics & Equilibrium)", "Biochemistry (Enzyme Kinetics, Metabolic Pathways)", "General Biology & Cellular Respiration", "Genetics & Molecular Biology (CRISPR, DNA)",
        "Human Anatomy & Physiology Systems", "Environmental Science & Sustainability", "Earth Science, Plate Tectonics & Meteorology", "Astronomy & Planetary Science", "SAT Math Prep Strategies", "SAT Reading & Writing Exam Prep", "ACT Comprehensive Test Prep", "GRE Quantitative Section Strategies", "GRE Verbal Reasoning & Analytical Writing", "GMAT Focus Edition Math Prep",
        "MCAT Biological and Biochemical Foundations", "LSAT Logic Games & Logical Reasoning Prep", "College Admission Essay Coaching", "Scientific Research Paper Writing (IEEE / APA)", "History Tutoring (World History & US History)", "Microeconomics Principles (Supply & Demand, Elasticity)", "Macroeconomics Principles (GDP, Inflation, Monetary Policy)", "AP Computer Science Principles Prep", "Philosophy Tutoring (Logic & Ethics)", "Academic Study Habits & Spaced Repetition"
    ],
    "Writing, Literature & Communication": [
        "Creative Fiction Writing & Narrative Arcs", "Worldbuilding for Fantasy & Sci-Fi Novels", "Character Arc Design & Internal Conflict", "Writing Compelling Dialogue for Fiction", "Screenwriting Structure (Three-Act & Save the Cat)", "Writing Television Pilot Scripts", "Playwriting & Stage Dialogue", "Non-Fiction Book Outlining & Proposals", "Memoir & Personal Narrative Writing", "Poetry Writing (Haiku, Sonnet, Free Verse)",
        "Technical Writing & Software User Guides", "Developer API Documentation & Markdown", "Journalistic Research & Interview Techniques", "Investigative Reporting & Fact-Checking", "Feature Article & Magazine Writing", "Copyediting & Proofreading (Chicago Manual of Style)", "Ghostwriting Thought Leadership Articles", "Blogging & High-Traffic Content Writing", "Newsletter Curation & Writing (Substack)", "Executive Speechwriting & Persuasive Oratory",
        "Public Relations (PR) Press Releases", "Crisis Communication Messaging", "Grant Writing for Non-Profits", "Academic Essay Structuring & Citations", "Children's Picture Book Writing", "Travel Writing & Destination Guides", "Food & Restaurant Review Writing", "Video Game Narrative Design & Branching Scripts", "Podcast Show Notes & Episode Scriptwriting", "Translation & Localization from Foreign Languages"
    ],
    "Performing Arts, Dance & Stagecraft": [
        "Stanislavski & Method Acting Principles", "Voice Acting for Animations & Video Games", "Audiobook Narration & Character Voicing", "Improv Comedy (Yes, And... Fundamentals)", "Stand-Up Comedy Set Writing & Timing", "Stage Blocking, Movement & Presence", "Monologue Selection & Audition Mastery", "Salsa Dancing (Cross-Body Lead & Spin Technique)", "Bachata Sensual Body Movement & Footwork", "Hip-Hop Choreography & Urban Dance",
        "Contemporary Dance Flow & Floorwork", "Classical Ballet Positions & Barre Work", "Jazz Dance Turns, Leaps & Flexibility", "Tap Dance Rhythms & Time Steps", "K-Pop Dance Routine Synchronization", "Breakdancing (Toprock, Footwork, Freezes, Power Moves)", "Argentine Tango Close Embrace & Ochos", "Ballroom Dancing (Waltz, Foxtrot, Quickstep)", "Stage Makeup & Prosthetics Application", "Theatrical Lighting Design & Cueing",
        "Theatrical Sound Design & Stage Microphones", "Puppetry & Hand-and-Rod Manipulation", "Circus Arts & Juggling Fundamentals", "Stage Combat & Safe Unarmed Fights", "Magic & Sleight of Hand with Playing Cards", "Voice Projection & Diction for Theatre", "Directing Community Theatre Productions", "Costume Design & Theatrical Wardrobe", "Aerial Silks & Lyra Hoop Acrobatics", "Flamenco Dance & Hand Clapping (Palmas)"
    ],
    "Personal Development & Life Skills": [
        "Time Management (Time Blocking & Pomodoro Technique)", "Speed Reading with High Comprehension", "Memory Techniques (Memory Palace, Major System)", "Habit Building (Atomic Habits Framework)", "Critical Thinking & Logical Fallacy Identification", "Emotional Intelligence (Self-Awareness & Empathy)", "Active Listening & Nonviolent Communication", "Burnout Recovery & Stress Resilience", "Career Coaching & Career Transition Strategy", "Resume & Cover Letter Tailoring for ATS",
        "Job Interview Preparation & STAR Method Answers", "Salary & Compensation Package Negotiation", "Professional Networking on LinkedIn", "Personal Branding & Executive Visibility", "Financial Independence Mindset & Frugality", "Minimalism & Intentional Living", "Mind Mapping & Visual Note Taking", "Mental Models for Decision Making (First Principles)", "Daily Journaling & Reflective Writing", "Overcoming Procrastination & Resistance",
        "Conflict Resolution in Personal & Work Life", "Goal Setting with SMART Criteria", "Personal Energy Management & Rest Cycles", "Digital Decluttering & Information Management (Second Brain / Obsidian)", "Public Speaking Anxiety Reduction", "Assertiveness Training & Setting Boundaries", "Speed Learning New Complex Topics (Feynman Technique)", "Mindful Living & Gratitude Practices", "Cross-Cultural Communication Skills", "Personal Productivity Apps (Notion, Todoist)"
    ],
    "Trades, Automotive, Home Repair & Gardening": [
        "Residential Electrical Wiring & Circuit Breakers", "Installing Light Fixtures, Switches & GFCI Outlets", "Home Plumbing Repair (Fixing Leaks, Traps, Faucets)", "Clearing Clogged Drains & P-Trap Replacement", "Drywall Hanging, Taping, Mudding & Texture Matching", "Interior Wall Painting & Edging Techniques", "Exterior House Painting & Power Washing Prep", "Ceramic, Porcelain & Subways Tile Laying", "Laminate, Vinyl Plank & Hardwood Flooring Installation", "Basic Framing & Stud Wall Construction",
        "Automotive Oil Change & Fluid Level Inspection", "Brake Pad and Rotor Replacement", "Car Battery Replacement & Alternator Testing", "OBD-II Diagnostic Trouble Code Scanning", "Spark Plug & Ignition Coil Replacement", "Bicycle Derailleur Adjustment & Gear Indexing", "Bicycle Hydraulic Disc Brake Bleeding & Trueing Wheels", "Small Engine Repair (Lawnmowers, Chainsaws, Weed Eaters)", "Motorcycle Chain Maintenance & Oil Change", "Raised Bed Organic Vegetable Gardening",
        "Soil Science, pH Testing & Organic Composting", "Hydroponic & Aeroponic Vegetable Cultivation", "Drip Irrigation System Sizing & Installation", "Fruit Tree Pruning, Thinning & Grafting", "Lawn Aeration, Overseeding & Weed Control", "Landscape Design & Flower Bed Layouts", "Hardscaping (Paver Patios, Retaining Walls, Walkways)", "Solar PV Panel Installation Basics", "Home HVAC Air Filter & Smart Thermostat Installation", "Locksmithing Basics & Rekeying Door Locks"
    ]
}

def seed():
    os.makedirs(DATA_DIR, exist_ok=True)
    all_skills = []
    seen = set()

    for category, skills in SKILL_DOMAINS.items():
        for s in skills:
            clean = s.strip()
            k = clean.lower()
            if k not in seen:
                seen.add(k)
                all_skills.append({"name": clean, "category": category})

    all_skills.sort(key=lambda x: (x["category"], x["name"]))

    with open(CSV_FILE, "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=["name", "category"])
        writer.writeheader()
        for row in all_skills:
            writer.writerow(row)

    print(f"Generated {len(all_skills)} curated skills in {CSV_FILE}")

    db = SessionLocal()
    try:
        existing = db.query(Skill).all()
        existing_map = {s.name.lower(): s for s in existing}

        added = 0
        updated = 0
        for item in all_skills:
            k = item["name"].lower()
            if k in existing_map:
                sk = existing_map[k]
                if sk.category in ["General", "Unknown", None] and item["category"] != "General":
                    sk.category = item["category"]
                    updated += 1
            else:
                new_s = Skill(name=item["name"], category=item["category"])
                db.add(new_s)
                existing_map[k] = new_s
                added += 1

        db.commit()
        total = db.query(Skill).count()
        print(f"MySQL Import Complete: Added {added} new skills, Updated {updated} categories, Total catalog size: {total}")
    except Exception as e:
        db.rollback()
        print(f"Database error: {e}")
        raise
    finally:
        db.close()

if __name__ == "__main__":
    seed()
