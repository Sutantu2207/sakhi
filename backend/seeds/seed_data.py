import os
import sys
from datetime import datetime, timezone, timedelta

root_dir = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
if root_dir not in sys.path:
    sys.path.append(root_dir)

from sqlalchemy.orm import Session
from backend.app.db.session import SessionLocal, engine, Base
import backend.app.db.base  # ensure all models are registered in mapper
from backend.app.models.user import User, UserRole
from backend.app.models.contact import EmergencyContact
from backend.app.models.resource import EmergencyResource, SupportResource, ResourceCategory, SupportCategory
from backend.app.models.incident import Incident, IncidentCategory, IncidentSeverity, IncidentStatus
from backend.app.core.security import get_password_hash


def seed_database():
    Base.metadata.create_all(bind=engine)
    db: Session = SessionLocal()

    try:
        # 1. Admin User
        admin = db.query(User).filter(User.email == "admin@sakhi.network").first()
        if not admin:
            admin = User(
                email="admin@sakhi.network",
                phone="+919876543210",
                full_name="Sakhi Central Operations",
                hashed_password=get_password_hash("Admin@Sakhi2026"),
                role=UserRole.ADMIN,
                is_active=True
            )
            db.add(admin)

        # 2. Test User
        user = db.query(User).filter(User.email == "priya@example.com").first()
        if not user:
            user = User(
                email="priya@example.com",
                phone="+919812345678",
                full_name="Priya Sharma",
                hashed_password=get_password_hash("SakhiUser123!"),
                role=UserRole.USER,
                is_active=True,
                safety_network_opt_in=True
            )
            db.add(user)
            db.flush()

            # Emergency contacts for Priya
            c1 = EmergencyContact(
                user_id=user.id,
                name="Sunita Sharma (Mother)",
                phone="+919800011122",
                relationship_label="Mother",
                notify_on_sos=True,
                priority_order=1
            )
            c2 = EmergencyContact(
                user_id=user.id,
                name="Rohan Sharma (Brother)",
                phone="+919800033344",
                relationship_label="Brother",
                notify_on_sos=True,
                priority_order=2
            )
            db.add_all([c1, c2])

        # 3. Emergency Resources (Verified Police, Hospitals, Safe Havens)
        if db.query(EmergencyResource).count() == 0:
            resources = [
                EmergencyResource(
                    name="Central Police Headquarters - Women Safety Cell",
                    category=ResourceCategory.POLICE,
                    phone="112",
                    address="Connaught Place Central Station, New Delhi",
                    latitude=28.6315,
                    longitude=77.2167,
                    is_verified=True,
                    operating_hours="24/7 Dedicated Women Helpdesk"
                ),
                EmergencyResource(
                    name="South Metro Police Station",
                    category=ResourceCategory.POLICE,
                    phone="011-26510000",
                    address="Ring Road, Hauz Khas",
                    latitude=28.5494,
                    longitude=77.2001,
                    is_verified=True,
                    operating_hours="24/7"
                ),
                EmergencyResource(
                    name="AIIMS Emergency Trauma Centre",
                    category=ResourceCategory.HOSPITAL,
                    phone="011-26588500",
                    address="Sri Aurobindo Marg, Ansari Nagar",
                    latitude=28.5672,
                    longitude=77.2100,
                    is_verified=True,
                    operating_hours="24/7 Level-1 Trauma Care"
                ),
                EmergencyResource(
                    name="Safdarjung Hospital Emergency",
                    category=ResourceCategory.HOSPITAL,
                    phone="011-26165060",
                    address="Ring Road, Opposite AIIMS",
                    latitude=28.5701,
                    longitude=77.2078,
                    is_verified=True,
                    operating_hours="24/7 Emergency Casualty"
                ),
                EmergencyResource(
                    name="Sakhi One-Stop Crisis Center (OSC)",
                    category=ResourceCategory.WOMEN_SHELTER,
                    phone="181",
                    address="District Women & Child Welfare Complex, Delhi",
                    latitude=28.6189,
                    longitude=77.2100,
                    is_verified=True,
                    operating_hours="24/7 Medical, Legal & Psychological Support"
                ),
                EmergencyResource(
                    name="Rajiv Chowk Metro 24/7 Help Point",
                    category=ResourceCategory.SAFE_PLACE,
                    phone="155370",
                    address="DMRC Station Control, Gate 7, Connaught Place",
                    latitude=28.6328,
                    longitude=77.2195,
                    is_verified=True,
                    operating_hours="24/7 CISF Security Hub"
                )
            ]
            db.add_all(resources)

        # 4. Support & Legal Resources
        if db.query(SupportResource).count() == 0:
            support_items = [
                SupportResource(
                    category=SupportCategory.HELPLINE,
                    title="National Emergency Helpline (112)",
                    organization="Ministry of Home Affairs",
                    phone="112",
                    website="https://112.gov.in",
                    description="Single emergency response number for immediate police, fire, and ambulance dispatch across all states.",
                    jurisdiction="All India",
                    actionable_steps="1. Dial 112 directly.\n2. State your location and emergency type.\n3. Automatic GPS location ping is captured by the state control room."
                ),
                SupportResource(
                    category=SupportCategory.HELPLINE,
                    title="National Commission for Women Helpline (1091)",
                    organization="National Commission for Women (NCW)",
                    phone="1091",
                    website="http://ncw.nic.in",
                    description="24/7 dedicated helpline for women in distress, stalking, domestic violence, or harassment.",
                    jurisdiction="National",
                    actionable_steps="1. Call 1091 or 7827170170.\n2. Free counselling, immediate police intervention, and shelter referral."
                ),
                SupportResource(
                    category=SupportCategory.CYBERCRIME,
                    title="National Cyber Crime Reporting Portal (1930)",
                    organization="Indian Cybercrime Coordination Centre (I4C)",
                    phone="1930",
                    website="https://cybercrime.gov.in",
                    description="Official portal for reporting online harassment, cyberstalking, non-consensual image sharing, impersonation, and financial fraud.",
                    jurisdiction="National",
                    actionable_steps="1. Preserve screenshots, URLs, and chat logs.\n2. File complaint under 'Women / Children Crime' category.\n3. Can be reported anonymously or with official identity."
                ),
                SupportResource(
                    category=SupportCategory.POSH,
                    title="PoSH (Prevention of Sexual Harassment at Workplace)",
                    organization="Ministry of Women and Child Development",
                    phone="011-23386408",
                    website="https://shebox.wcd.gov.in",
                    description="Guidelines and SHe-Box portal for submitting workplace harassment complaints directly to the Internal Committee (IC) or Local Committee (LC).",
                    jurisdiction="Organized & Unorganized Sectors",
                    actionable_steps="1. Submit written complaint to Internal Committee within 3 months.\n2. Inquire about interim relief (leave/transfer).\n3. Confidential inquiry completed within 90 days."
                ),
                SupportResource(
                    category=SupportCategory.DOMESTIC_ABUSE,
                    title="Protection of Women from Domestic Violence Act (PWDVA)",
                    organization="National Legal Services Authority (NALSA)",
                    phone="15100",
                    website="https://nalsa.gov.in",
                    description="Free legal aid, Protection Officers, residence orders, and emergency maintenance orders for women facing physical, verbal, emotional, or economic abuse.",
                    jurisdiction="National",
                    actionable_steps="1. Contact local Protection Officer or District Legal Services Authority (DLSA).\n2. Request emergency Protection Order.\n3. Free legal representation provided to all women."
                )
            ]
            db.add_all(support_items)

        # 5. Verified Historical Incident Reports (for realistic risk assessment)
        if db.query(Incident).count() == 0:
            now = datetime.now(timezone.utc)
            incidents = [
                Incident(
                    category=IncidentCategory.POOR_LIGHTING,
                    severity=IncidentSeverity.MEDIUM,
                    description="Street lights non-operational along the 400m stretch behind the market complex.",
                    incident_time=now - timedelta(days=2, hours=3),
                    latitude=28.6340,
                    longitude=77.2180,
                    status=IncidentStatus.VERIFIED,
                    moderator_notes="Verified via municipal inspection notice."
                ),
                Incident(
                    category=IncidentCategory.HARASSMENT,
                    severity=IncidentSeverity.HIGH,
                    description="Catcalling and persistent tailing reported near bus stand after 9 PM.",
                    incident_time=now - timedelta(days=5, hours=4),
                    latitude=28.6290,
                    longitude=77.2150,
                    status=IncidentStatus.VERIFIED,
                    moderator_notes="Patrol PCR van notified for routine night patrols."
                ),
                Incident(
                    category=IncidentCategory.UNSAFE_AREA,
                    severity=IncidentSeverity.LOW,
                    description="Isolated pedestrian subway with broken CCTV cameras.",
                    incident_time=now - timedelta(days=8, hours=2),
                    latitude=28.6380,
                    longitude=77.2200,
                    status=IncidentStatus.VERIFIED,
                    moderator_notes="Forwarded to municipal transit authority."
                )
            ]
            db.add_all(incidents)

        db.commit()
        print("Database seeded successfully with realistic admin, resources, incidents, and test user.")
    except Exception as e:
        db.rollback()
        print(f"Error seeding database: {e}")
    finally:
        db.close()


if __name__ == "__main__":
    seed_database()
