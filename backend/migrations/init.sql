-- PostGIS, UUID, and Trigram Extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "postgis";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";

-- 1. Users Table
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    username VARCHAR(50) UNIQUE NOT NULL,
    full_name VARCHAR(100),
    avatar_url TEXT,
    bio TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Hierarchical Locations Table
CREATE TABLE IF NOT EXISTS locations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    slug VARCHAR(255) UNIQUE NOT NULL,
    continent VARCHAR(50) NOT NULL,
    country VARCHAR(100) NOT NULL,
    state_region VARCHAR(100),
    city VARCHAR(100),
    place_type VARCHAR(50) NOT NULL, -- 'mountain', 'beach', 'fort', 'monument', 'cafe'
    latitude NUMERIC(10, 8) NOT NULL,
    longitude NUMERIC(11, 8) NOT NULL,
    geom GEOGRAPHY(Point, 4326),
    cover_image_url TEXT,
    description TEXT,
    verified BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_locations_geom ON locations USING GIST(geom);
CREATE INDEX IF NOT EXISTS idx_locations_name_trgm ON locations USING GIN (name gin_trgm_ops);

-- 3. Trips Table
CREATE TABLE IF NOT EXISTS trips (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    description TEXT,
    total_expense NUMERIC(12, 2),
    currency VARCHAR(3) DEFAULT 'INR',
    transport_mode VARCHAR(50),
    rating SMALLINT CHECK (rating >= 1 AND rating <= 5),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_trips_user_id ON trips(user_id);

-- 4. Trip Visited Locations Join Table
CREATE TABLE IF NOT EXISTS trip_locations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    trip_id UUID NOT NULL REFERENCES trips(id) ON DELETE CASCADE,
    location_id UUID NOT NULL REFERENCES locations(id) ON DELETE RESTRICT,
    visit_order INT DEFAULT 1 NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_trip_locations_trip_id ON trip_locations(trip_id);
CREATE INDEX IF NOT EXISTS idx_trip_locations_location_id ON trip_locations(location_id);

-- 5. Immutable Raw Reviews Table
CREATE TABLE IF NOT EXISTS reviews (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    location_id UUID NOT NULL REFERENCES locations(id) ON DELETE RESTRICT,
    trip_id UUID REFERENCES trips(id) ON DELETE CASCADE,
    rating SMALLINT NOT NULL CHECK (rating >= 1 AND rating <= 5),
    original_text TEXT NOT NULL,
    visit_date DATE NOT NULL,
    expense_amount NUMERIC(12, 2),
    currency VARCHAR(3) DEFAULT 'USD',
    group_size INT CHECK (group_size > 0),
    transport_mode VARCHAR(50),
    starting_location VARCHAR(150),
    helpful_count INT DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_reviews_location_id ON reviews(location_id);
CREATE INDEX IF NOT EXISTS idx_reviews_trip_id ON reviews(trip_id);

-- 6. Versioned AI Review Representation
CREATE TABLE IF NOT EXISTS review_ai_data (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    review_id UUID UNIQUE NOT NULL REFERENCES reviews(id) ON DELETE CASCADE,
    ai_summary TEXT NOT NULL,
    highlights JSONB DEFAULT '[]'::jsonb,
    challenges JSONB DEFAULT '[]'::jsonb,
    extracted_tips JSONB DEFAULT '[]'::jsonb,
    sentiment VARCHAR(20) NOT NULL, -- 'positive', 'mixed', 'negative', 'neutral'
    extracted_budget_per_person NUMERIC(12, 2),
    model_version VARCHAR(50) NOT NULL,
    processing_status VARCHAR(20) DEFAULT 'completed', -- 'pending', 'completed', 'failed'
    processed_at TIMESTAMPTZ DEFAULT NOW()
);

-- 7. Location-Level Aggregated Community Insights
CREATE TABLE IF NOT EXISTS location_ai_insights (
    location_id UUID PRIMARY KEY REFERENCES locations(id) ON DELETE CASCADE,
    aggregated_positives JSONB DEFAULT '[]'::jsonb,
    aggregated_challenges JSONB DEFAULT '[]'::jsonb,
    expense_range_min NUMERIC(12, 2),
    expense_range_max NUMERIC(12, 2),
    dominant_currency VARCHAR(3) DEFAULT 'USD',
    best_visit_times JSONB DEFAULT '[]'::jsonb,
    sample_size INT DEFAULT 0,
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 8. Media Attachments
CREATE TABLE IF NOT EXISTS review_photos (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    review_id UUID NOT NULL REFERENCES reviews(id) ON DELETE CASCADE,
    location_id UUID NOT NULL REFERENCES locations(id) ON DELETE CASCADE,
    image_url TEXT NOT NULL,
    thumbnail_url TEXT,
    is_flagged BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);
