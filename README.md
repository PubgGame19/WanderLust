# Wanderlust AI (TravelX)
> Production-Ready, Mobile-First Travel Knowledge & Community Platform

Wanderlust AI is built from the ground up to guarantee authentic, zero-hallucination travel intelligence through four fundamental architectural invariants.

---

## 🏛️ Fundamental Engineering Invariants

1. **Strict Spatial Normalization:** Every review, expense, and media attachment strictly references a validated hierarchical `location_id`.
2. **Immutable Raw Data vs. Versioned AI Derivative:** The user's original text, expenses, transport mode, and media are immutable source-of-truth in `reviews`. AI extractions reside separately in `review_ai_data`.
3. **Resilient Asynchronous Ingestion:** Submitting a review immediately commits raw data to the database in $<15\text{ms}$ returning `HTTP 201 Created` with `ai_status: "pending"`, offloading extraction and embedding to a background task queue.
4. **Anti-Hallucination Guardrails:** AI extraction enforces Strict JSON Schema Mode and deterministic extraction. If details (e.g. parking, amenities) are not in raw text, the AI returns `null`/empty lists and never fabricates facts.

---

## 📁 System Architecture

```
├── backend/
│   ├── app/
│   │   ├── api/v1/          # RESTful Endpoints (Auth, Locations, Reviews, AI)
│   │   ├── core/            # Config, DB connections, Haversine spatial math
│   │   ├── models/          # SQLAlchemy Models (PostgreSQL + PostGIS & SQLite)
│   │   ├── schemas/         # Pydantic v2 DTOs (2-layer reviews, strict AI schemas)
│   │   ├── services/        # AI Extractor, Insights Aggregator, RAG Assistant, Queue
│   │   └── main.py          # FastAPI Application & Lifecycle
│   ├── migrations/
│   │   └── init.sql         # PostgreSQL 16 + PostGIS + pg_trgm DDL migrations
│   ├── tests/               # Pytest automated test suite
│   ├── worker.py            # Async AI Fact-Extraction Worker process
│   ├── verify_system.py     # Live verification & invariant proof script
│   ├── Dockerfile           # Multi-stage production container
│   └── docker-compose.yml   # PostgreSQL + PostGIS, Redis 7, API, Worker
│
└── frontend/
    ├── lib/
    │   ├── core/
    │   │   ├── theme/       # Dynamic Theme Engine (OLED Dark & Minimalist Light)
    │   │   ├── models/      # Domain & DTO models
    │   │   └── network/     # HTTP API Client
    │   ├── features/
    │   │   ├── onboarding/  # 3-Page Parallax Onboarding Carousel (delta*60 / delta*40)
    │   │   ├── locations/   # Location Detail Hub & Aggregated AI Insights
    │   │   ├── reviews/     # 2-Layer Review Card Component & Submission Flow
    │   │   ├── ai_assistant/# RAG Chatbot with Community Citations
    │   │   └── home/        # Explore Tab, Category Filters & Profile
    │   └── main.dart        # Entry point with Riverpod ProviderScope
    └── pubspec.yaml         # Flutter dependencies
```

---

## 🚀 Running the Backend

### Quick Standalone Mode (Zero External Dependencies)
```bash
cd backend
python -m pip install -r requirements.txt

# Run full test suite
python -m pytest tests -v

# Run system verification and invariant proof
python verify_system.py

# Start API server
python -m uvicorn app.main:app --reload --port 8000
```

### Full Production Mode (Docker Compose with PostgreSQL + PostGIS + Redis)
```bash
cd backend
docker-compose up --build
```
Interactive OpenAPI documentation will be available at: `http://localhost:8000/docs`.

---

## 📱 Running the Flutter Mobile App

```bash
cd frontend
flutter pub get
flutter run
```

### Key Mobile Features
- **Dynamic Theme Engine:** Switch seamlessly between **OLED Pure Dark Mode** (`#0A0B0E`) and **Minimalist Light Mode** (`#F7F9FC`).
- **Interactive Parallax Onboarding:** Background cards translate at $\Delta \times 60$, center icons at $\Delta \times 40$, with liquid dot width expansion ($8\text{px} \to 32\text{px}$) and morphing action button.
- **2-Layer Review Card Component:**
  - **Layer 1 (AI Summary):** Shimmering badge, green-tinted highlights, amber/red-tinted alerts, metadata pills.
  - **Interactive Action:** "View Original Experience" slides open an animated bottom drawer displaying exact unaltered text, timestamps, and uncompressed media.
- **RAG AI Concierge:** Interactive conversational interface providing grounded advice with clickable traveler citations.
