import os
import sys
from datetime import date

# Add backend directory to sys.path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from app.core.database import SessionLocal, init_db
from app.models.user import User
from app.models.location import Location
from app.models.review import Review
from app.models.review_ai_data import ReviewAIData
from app.models.location_ai_insights import LocationAIInsights
from app.models.trip import Trip
from app.models.trip_location import TripLocation
from app.models.review_photo import ReviewPhoto
from app.api.v1.deps import get_password_hash
from app.core.config import settings

def seed_rich_data():
    init_db()
    db = SessionLocal()
    try:
        print("--- Seeding/Refreshing Rich Travel Data for WanderLust ---")

        # 1. Users
        users_data = [
            {
                "id": "u-10000000-0000-0000-0000-000000000001",
                "email": "explorer@wanderlust.ai",
                "username": "rohan_travels",
                "password_hash": get_password_hash("wanderlust2026"),
                "full_name": "Rohan Sharma",
                "bio": "Motorcycle rider & high-altitude explorer. 45,000+ km across the Himalayas.",
                "avatar_url": "https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=200"
            },
            {
                "id": "u-10000000-0000-0000-0000-000000000002",
                "email": "priya.nomad@wanderlust.ai",
                "username": "priya_explorer",
                "password_hash": get_password_hash("wanderlust2026"),
                "full_name": "Priya Varma",
                "bio": "Solo backpacker & whitewater rafter. Chasing remote river trails.",
                "avatar_url": "https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=200"
            },
            {
                "id": "u-10000000-0000-0000-0000-000000000003",
                "email": "ananya.beach@wanderlust.ai",
                "username": "ananya_coast",
                "password_hash": get_password_hash("wanderlust2026"),
                "full_name": "Ananya Sen",
                "bio": "Coastal hopper, scuba diver, and beach sunset reviewer.",
                "avatar_url": "https://images.unsplash.com/photo-1517841905240-472988babdf9?w=200"
            }
        ]

        users = {}
        for u in users_data:
            user_obj = db.query(User).filter(User.id == u["id"]).first()
            if not user_obj:
                user_obj = db.query(User).filter(User.email == u["email"]).first()
            if not user_obj:
                user_obj = User(**u)
                db.add(user_obj)
            else:
                user_obj.username = u["username"]
                user_obj.full_name = u["full_name"]
                user_obj.avatar_url = u["avatar_url"]
                user_obj.bio = u["bio"]
            db.commit()
            db.refresh(user_obj)
            users[u["username"]] = user_obj
        print(f"Users active: {len(users)}")

        # 2. Locations
        locations_data = [
            {
                "id": "l-20000000-0000-0000-0000-000000000001",
                "name": "Spiti Valley & Key Monastery",
                "slug": "spiti-valley-key-monastery",
                "continent": "Asia",
                "country": "India",
                "state_region": "Himachal Pradesh",
                "city": "Spiti Valley",
                "place_type": "mountain",
                "latitude": 32.2981,
                "longitude": 78.0125,
                "cover_image_url": "https://images.unsplash.com/photo-1506744038136-46273834b3fb?w=1200",
                "description": "High-altitude desert mountain valley at 4,166m altitude. Famous for Tibetan monasteries, bike treks, and rugged Himalayan passes.",
                "verified": True
            },
            {
                "id": "l-20000000-0000-0000-0000-000000000002",
                "name": "Rishikesh Ganga River & Rafting",
                "slug": "rishikesh-ganga-river-rafting",
                "continent": "Asia",
                "country": "India",
                "state_region": "Uttarakhand",
                "city": "Rishikesh",
                "place_type": "adventure",
                "latitude": 30.0869,
                "longitude": 78.2676,
                "cover_image_url": "https://images.unsplash.com/photo-1626621341517-bbf3d9990a23?w=1200",
                "description": "Yoga capital of the world and premier whitewater rafting hub nestled along the holy Ganges river.",
                "verified": True
            },
            {
                "id": "l-20000000-0000-0000-0000-000000000003",
                "name": "Manali & Solang Valley",
                "slug": "manali-solang-valley-pass",
                "continent": "Asia",
                "country": "India",
                "state_region": "Himachal Pradesh",
                "city": "Manali",
                "place_type": "mountain",
                "latitude": 32.2432,
                "longitude": 77.1892,
                "cover_image_url": "https://images.unsplash.com/photo-1586016413664-864c0dd76f53?w=1200",
                "description": "Scenic resort town on the Beas River, starting point for high mountain passes, skiing in Solang, and paragliding.",
                "verified": True
            },
            {
                "id": "l-20000000-0000-0000-0000-000000000004",
                "name": "South Goa Palolem & Agonda",
                "slug": "south-goa-palolem-agonda-beach",
                "continent": "Asia",
                "country": "India",
                "state_region": "Goa",
                "city": "Canacona",
                "place_type": "beach",
                "latitude": 15.0100,
                "longitude": 74.0232,
                "cover_image_url": "https://images.unsplash.com/photo-1512343879784-a960bf40e7f2?w=1200",
                "description": "Pristine crescent bay with serene waters, cliffside wooden beach shacks, dolphin boat trips, and peaceful coastal walks.",
                "verified": True
            },
            {
                "id": "l-20000000-0000-0000-0000-000000000005",
                "name": "Rajmachi Fort & Trek",
                "slug": "rajmachi-fort-lonavala-trek",
                "continent": "Asia",
                "country": "India",
                "state_region": "Maharashtra",
                "city": "Lonavala",
                "place_type": "fort",
                "latitude": 18.8285,
                "longitude": 73.3986,
                "cover_image_url": "https://images.unsplash.com/photo-1590608897129-79da98d15969?w=1200",
                "description": "Historic dual-fortress in the Sahyadri mountains famous for weekend motorcycle rides, monsoon waterfalls, and night firefly treks.",
                "verified": True
            }
        ]

        locs = {}
        for l in locations_data:
            loc_obj = db.query(Location).filter(Location.id == l["id"]).first()
            if not loc_obj:
                loc_obj = Location(**l)
                db.add(loc_obj)
            else:
                loc_obj.name = l["name"]
                loc_obj.slug = l["slug"]
                loc_obj.city = l["city"]
                loc_obj.state_region = l["state_region"]
                loc_obj.country = l["country"]
                loc_obj.place_type = l["place_type"]
                loc_obj.latitude = l["latitude"]
                loc_obj.longitude = l["longitude"]
                loc_obj.cover_image_url = l["cover_image_url"]
                loc_obj.description = l["description"]
                loc_obj.verified = True
            db.commit()
            db.refresh(loc_obj)
            locs[l["name"]] = loc_obj
        print(f"Locations configured: {len(locs)}")

        # 3. Trips
        trips_data = [
            {
                "id": "t-50000000-0000-0000-0000-000000000001",
                "user_id": users["rohan_travels"].id,
                "title": "Spiti High-Altitude Motorcycle Expedition",
                "start_date": date(2026, 7, 10),
                "end_date": date(2026, 7, 16),
                "description": "5-day Himalayan circuit covering Kaza, Key Monastery, Kibber, and Chandratal. Total cost was INR 9,200 per bike including fuel and homestays.",
                "total_expense": 9200.0,
                "currency": "INR",
                "transport_mode": "Motorcycle",
                "rating": 5,
                "locations": [
                    {"loc": locs["Spiti Valley & Key Monastery"], "order": 1},
                    {"loc": locs["Manali & Solang Valley"], "order": 2}
                ]
            },
            {
                "id": "t-50000000-0000-0000-0000-000000000002",
                "user_id": users["priya_explorer"].id,
                "title": "Rishikesh Whitewater Rafting & Cliff Jump Weekend",
                "start_date": date(2026, 8, 1),
                "end_date": date(2026, 8, 3),
                "description": "Thrilling 26km river rafting from Marine Drive, cliff jumping at Magpie, and peaceful Ganga Aarti at Triveni Ghat under INR 4,500.",
                "total_expense": 4500.0,
                "currency": "INR",
                "transport_mode": "Bus / Shared Cab",
                "rating": 5,
                "locations": [
                    {"loc": locs["Rishikesh Ganga River & Rafting"], "order": 1}
                ]
            },
            {
                "id": "t-50000000-0000-0000-0000-000000000003",
                "user_id": users["ananya_coast"].id,
                "title": "South Goa Coastal Scooter Hopping & Sunset Cafes",
                "start_date": date(2026, 8, 12),
                "end_date": date(2026, 8, 15),
                "description": "Scenic scooter ride exploring Palolem, Butterfly Beach hidden cove, and cliffside cafes in Agonda. Total INR 6,800 for 3 days.",
                "total_expense": 6800.0,
                "currency": "INR",
                "transport_mode": "Scooter / Rental",
                "rating": 5,
                "locations": [
                    {"loc": locs["South Goa Palolem & Agonda"], "order": 1}
                ]
            },
            {
                "id": "t-50000000-0000-0000-0000-000000000004",
                "user_id": users["rohan_travels"].id,
                "title": "Rajmachi Monsoon Night Fort Trek",
                "start_date": date(2026, 8, 8),
                "end_date": date(2026, 8, 9),
                "description": "Weekend bike trek under INR 1,000! Raw mud trails, waterfall crossings, and camping at Udhewadi village.",
                "total_expense": 850.0,
                "currency": "INR",
                "transport_mode": "Motorcycle",
                "rating": 5,
                "locations": [
                    {"loc": locs["Rajmachi Fort & Trek"], "order": 1}
                ]
            }
        ]

        for td in trips_data:
            trip_obj = db.query(Trip).filter(Trip.id == td["id"]).first()
            if not trip_obj:
                trip_obj = Trip(
                    id=td["id"],
                    user_id=td["user_id"],
                    title=td["title"],
                    start_date=td["start_date"],
                    end_date=td["end_date"],
                    description=td["description"],
                    total_expense=td["total_expense"],
                    currency=td["currency"],
                    transport_mode=td["transport_mode"],
                    rating=td["rating"]
                )
                db.add(trip_obj)
            else:
                trip_obj.title = td["title"]
                trip_obj.description = td["description"]
                trip_obj.total_expense = td["total_expense"]
                trip_obj.transport_mode = td["transport_mode"]
                trip_obj.rating = td["rating"]
            db.commit()
            db.refresh(trip_obj)

            # Ensure TripLocations
            db.query(TripLocation).filter(TripLocation.trip_id == trip_obj.id).delete()
            for l_item in td["locations"]:
                tl = TripLocation(
                    trip_id=trip_obj.id,
                    location_id=l_item["loc"].id,
                    visit_order=l_item["order"]
                )
                db.add(tl)
            db.commit()

        print("Trips & TripLocations configured.")

        # 4. Rich Reviews & Ground Truth Citations
        reviews_data = [
            {
                "id": "r-30000000-0000-0000-0000-000000000001",
                "user_id": users["rohan_travels"].id,
                "location_id": locs["Spiti Valley & Key Monastery"].id,
                "trip_id": "t-50000000-0000-0000-0000-000000000001",
                "rating": 5,
                "original_text": "Best weekend bike trek under 10k! Completed Kaza to Key Monastery circuit for INR 9,200 total on a Himalayan 450. Fuel was INR 3,800, homestay INR 800/night with tasty hot thukpa and butter tea. Road between Gramphu and Batal has heavy water crossings (mallahs). Must carry tyre inflator, spare clutch cables, and Diamox for acclimatization at 4,000m+.",
                "visit_date": date(2026, 7, 12),
                "expense_amount": 9200.0,
                "currency": "INR",
                "group_size": 2,
                "transport_mode": "Motorcycle",
                "starting_location": "Manali",
                "photos": [
                    "https://images.unsplash.com/photo-1506744038136-46273834b3fb?w=800",
                    "https://images.unsplash.com/photo-1586016413664-864c0dd76f53?w=800"
                ],
                "ai_summary": "High-value Himalayan motorcycle trip under INR 10k with essential advice on water crossings and acclimatization.",
                "highlights": ["Key Monastery views", "Budget bike trek under 10k", "Authentic homestay hospitality"],
                "challenges": ["Deep water crossings near Batal", "Thin air and altitude sickness above 3,800m"],
                "extracted_tips": ["Carry Diamox for altitude sickness", "Pack spare clutch and accelerator cables", "Start early before water crossings swell up"],
                "sentiment": "positive",
                "budget_per_person": 9200.0
            },
            {
                "id": "r-30000000-0000-0000-0000-000000000002",
                "user_id": users["priya_explorer"].id,
                "location_id": locs["Rishikesh Ganga River & Rafting"].id,
                "trip_id": "t-50000000-0000-0000-0000-000000000002",
                "rating": 5,
                "original_text": "26km Marine Drive river rafting cost INR 1,200 per head including cliff jump and body surfing! Stayed in a riverside hostel near Tapovan for INR 700/night. Total 2-day expense INR 4,500. Evening Aarti at Parmarth Niketan was truly divine. Best visited between October and April when rapids are grade 3-4.",
                "visit_date": date(2026, 8, 2),
                "expense_amount": 4500.0,
                "currency": "INR",
                "group_size": 4,
                "transport_mode": "Shared Cab",
                "starting_location": "Delhi",
                "photos": [
                    "https://images.unsplash.com/photo-1626621341517-bbf3d9990a23?w=800"
                ],
                "ai_summary": "Top budget adventure weekend with grade 3-4 whitewater rafting and hostel stays under INR 4,500.",
                "highlights": ["26km Marine Drive rafting", "Cliff jumping", "Ganga Aarti at Parmarth Niketan"],
                "challenges": ["Heavy weekend traffic on Laxman Jhula road"],
                "extracted_tips": ["Book registered rafting operators at Tapovan", "Wear water sandals with straps", "Visit Parmarth Niketan by 5:30 PM for Aarti seats"],
                "sentiment": "positive",
                "budget_per_person": 4500.0
            },
            {
                "id": "r-30000000-0000-0000-0000-000000000003",
                "user_id": users["ananya_coast"].id,
                "location_id": locs["South Goa Palolem & Agonda"].id,
                "trip_id": "t-50000000-0000-0000-0000-000000000003",
                "rating": 5,
                "original_text": "Palolem and Agonda are peaceful compared to North Goa. Rented an Activa for INR 350/day. Hiked to Butterfly Beach through the forest hill—unreal turquoise waters! Beach huts start at INR 1,200/night. Spent INR 6,800 in 3 days including fresh seafood and kayaking at Colomb bay.",
                "visit_date": date(2026, 8, 13),
                "expense_amount": 6800.0,
                "currency": "INR",
                "group_size": 2,
                "transport_mode": "Scooter",
                "starting_location": "Madgaon",
                "photos": [
                    "https://images.unsplash.com/photo-1512343879784-a960bf40e7f2?w=800"
                ],
                "ai_summary": "Peaceful coastal escape with affordable scooter rentals, secluded beach hikes, and watersports.",
                "highlights": ["Butterfly Beach forest hike", "Colomb Bay kayaking", "Sunset beach huts"],
                "challenges": ["Limited network reception inside Butterfly Beach cove"],
                "extracted_tips": ["Rent scooters at Madgaon railway station for cheaper rates", "Kayak during high tide at Colomb Bay"],
                "sentiment": "positive",
                "budget_per_person": 6800.0
            },
            {
                "id": "r-30000000-0000-0000-0000-000000000004",
                "user_id": users["rohan_travels"].id,
                "location_id": locs["Rajmachi Fort & Trek"].id,
                "trip_id": "t-50000000-0000-0000-0000-000000000004",
                "rating": 5,
                "original_text": "Monsoon bike trek to Rajmachi: Total expenditure was only INR 850! Bike fuel from Mumbai INR 400, village camping space INR 300, homestyle Pithla Bhakri lunch INR 150. Heavy fog and lush Sahyadri waterfalls along the route. Ride carefully as the last 8km from Lonavala is rocky off-road.",
                "visit_date": date(2026, 8, 8),
                "expense_amount": 850.0,
                "currency": "INR",
                "group_size": 3,
                "transport_mode": "Motorcycle",
                "starting_location": "Mumbai",
                "photos": [
                    "https://images.unsplash.com/photo-1590608897129-79da98d15969?w=800"
                ],
                "ai_summary": "Ultra-budget weekend monsoon trek under INR 1,000 with scenic waterfall views and rustic local food.",
                "highlights": ["Budget trek under INR 1,000", "Monsoon waterfalls", "Pithla Bhakri village food"],
                "challenges": ["Extremely slippery rocky trail on two-wheelers"],
                "extracted_tips": ["Carry waterproof backpack covers", "Have local villagers cook lunch at Udhewadi"],
                "sentiment": "positive",
                "budget_per_person": 850.0
            }
        ]

        for rd in reviews_data:
            rev_obj = db.query(Review).filter(Review.id == rd["id"]).first()
            if not rev_obj:
                rev_obj = Review(
                    id=rd["id"],
                    user_id=rd["user_id"],
                    location_id=rd["location_id"],
                    trip_id=rd["trip_id"],
                    rating=rd["rating"],
                    original_text=rd["original_text"],
                    visit_date=rd["visit_date"],
                    expense_amount=rd["expense_amount"],
                    currency=rd["currency"],
                    group_size=rd["group_size"],
                    transport_mode=rd["transport_mode"],
                    starting_location=rd["starting_location"],
                    helpful_count=15
                )
                db.add(rev_obj)
            else:
                rev_obj.location_id = rd["location_id"]
                rev_obj.trip_id = rd["trip_id"]
                rev_obj.rating = rd["rating"]
                rev_obj.original_text = rd["original_text"]
                rev_obj.expense_amount = rd["expense_amount"]
                rev_obj.currency = rd["currency"]
                rev_obj.transport_mode = rd["transport_mode"]
            db.commit()
            db.refresh(rev_obj)

            # Update Review AIData
            ai_data = db.query(ReviewAIData).filter(ReviewAIData.review_id == rev_obj.id).first()
            if not ai_data:
                ai_data = ReviewAIData(
                    id=f"ai-{rd['id'][2:]}",
                    review_id=rev_obj.id,
                    ai_summary=rd["ai_summary"],
                    highlights=rd["highlights"],
                    challenges=rd["challenges"],
                    extracted_tips=rd["extracted_tips"],
                    sentiment=rd["sentiment"],
                    extracted_budget_per_person=rd["budget_per_person"],
                    model_version=settings.AI_MODEL_VERSION,
                    processing_status="completed"
                )
                db.add(ai_data)
            else:
                ai_data.ai_summary = rd["ai_summary"]
                ai_data.highlights = rd["highlights"]
                ai_data.challenges = rd["challenges"]
                ai_data.extracted_tips = rd["extracted_tips"]
                ai_data.sentiment = rd["sentiment"]
                ai_data.extracted_budget_per_person = rd["budget_per_person"]
                ai_data.processing_status = "completed"
            db.commit()

            # Photos
            db.query(ReviewPhoto).filter(ReviewPhoto.review_id == rev_obj.id).delete()
            for p_idx, p_url in enumerate(rd["photos"]):
                photo_obj = ReviewPhoto(
                    user_id=rd["user_id"],
                    trip_id=rd["trip_id"],
                    review_id=rev_obj.id,
                    location_id=rd["location_id"],
                    image_url=p_url,
                    display_order=p_idx
                )
                db.add(photo_obj)
            db.commit()

        # 5. Location AI Insights
        insights_map = [
            {
                "location_id": locs["Spiti Valley & Key Monastery"].id,
                "aggregated_positives": ["High-altitude desert vistas", "Key Monastery heritage", "Budget bike treks under 10k"],
                "aggregated_challenges": ["Batal water crossings", "Altitude sickness above 3,800m"],
                "expense_range_min": 8500.0,
                "expense_range_max": 12000.0,
                "dominant_currency": "INR",
                "best_visit_times": ["June", "July", "August", "September"],
                "sample_size": 2
            },
            {
                "location_id": locs["Rishikesh Ganga River & Rafting"].id,
                "aggregated_positives": ["Grade 3-4 rapids", "Cliff jumping", "Peaceful Ganga Aarti"],
                "aggregated_challenges": ["Weekend bridge congestion"],
                "expense_range_min": 3500.0,
                "expense_range_max": 6000.0,
                "dominant_currency": "INR",
                "best_visit_times": ["October", "November", "February", "March", "April"],
                "sample_size": 3
            },
            {
                "location_id": locs["South Goa Palolem & Agonda"].id,
                "aggregated_positives": ["Serene crescent beaches", "Affordable scooter rentals", "Butterfly beach coves"],
                "aggregated_challenges": ["Limited network in forest coves"],
                "expense_range_min": 5000.0,
                "expense_range_max": 9000.0,
                "dominant_currency": "INR",
                "best_visit_times": ["November", "December", "January", "February"],
                "sample_size": 2
            },
            {
                "location_id": locs["Rajmachi Fort & Trek"].id,
                "aggregated_positives": ["Ultra budget trek under 1k", "Monsoon waterfalls", "Fireflies camping"],
                "aggregated_challenges": ["Slippery rocky trail"],
                "expense_range_min": 800.0,
                "expense_range_max": 1800.0,
                "dominant_currency": "INR",
                "best_visit_times": ["July", "August", "September"],
                "sample_size": 3
            }
        ]

        for im in insights_map:
            existing_ins = db.query(LocationAIInsights).filter(LocationAIInsights.location_id == im["location_id"]).first()
            if not existing_ins:
                ins_obj = LocationAIInsights(**im)
                db.add(ins_obj)
            else:
                existing_ins.aggregated_positives = im["aggregated_positives"]
                existing_ins.aggregated_challenges = im["aggregated_challenges"]
                existing_ins.expense_range_min = im["expense_range_min"]
                existing_ins.expense_range_max = im["expense_range_max"]
            db.commit()

        print("--- Rich Travel Data Successfully Seeded & Synchronized! ---")
    except Exception as e:
        print(f"Error during seeding: {e}")
        db.rollback()
    finally:
        db.close()

if __name__ == "__main__":
    seed_rich_data()
