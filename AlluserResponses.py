import firebase_admin
from firebase_admin import credentials, firestore
from openpyxl import Workbook
from datetime import datetime
import os

# ------------- FIREBASE SETUP -------------
SERVICE_KEY_PATH = "serviceAccountKey.json"
cred = credentials.Certificate(SERVICE_KEY_PATH)
firebase_admin.initialize_app(cred)
db = firestore.client()

# ------------- OUTPUT FOLDER -------------
output_folder = "AlluserResponses"
os.makedirs(output_folder, exist_ok=True)

# ------------- CREATE WORKBOOK -------------
wb = Workbook()
sheet = wb.active
sheet.title = "All Responses"

# ------------- HEADERS -------------
headers = (
    ["ParticipantID", "Email", "Date", "Time", "Responded"]
    + [f"MADRS_Q{i}" for i in range(1, 11)]
    + [f"Sleep_Q{i}" for i in range(1, 7)]
    + [f"Feedback_Q{i}" for i in range(1, 4)]
)
sheet.append(headers)

# ------------- HELPER FUNCTION -------------
def map_value(answer):
    """Safely map text/dict answers to numeric values."""
    if answer is None or answer == "":
        return "N/A"

    if isinstance(answer, dict):
        if "value" in answer:
            return answer["value"]
        if "text" in answer:
            answer = answer["text"]

    if isinstance(answer, str):
        return answer.strip()

    return answer

# ------------- USER INPUT -------------
print("\n Firestore Response Export Tool")
print("----------------------------------")
print("Select an option to fetch data:\n")
print("1. Fetch all users (all responses)")
print("2. Fetch all users within a specific date range (dd/mm/yyyy - dd/mm/yyyy)")
print("3. Fetch specific user by Participant ID or Email")
print("4. Fetch specific user + date range\n")

choice = input("Enter your choice (1–4): ").strip()

user_filter = None
date_from = None
date_to = None

if choice in ["2", "4"]:
    date_from_str = input("Enter start date (dd/mm/yyyy): ").strip()
    date_to_str = input("Enter end date (dd/mm/yyyy): ").strip()
    try:
        date_from = datetime.strptime(date_from_str, "%d/%m/%Y").date()
        date_to = datetime.strptime(date_to_str, "%d/%m/%Y").date()
    except ValueError:
        print("❌ Invalid date format. Use dd/mm/yyyy.")
        exit()

if choice in ["3", "4"]:
    user_filter = input("Enter Participant ID or Email: ").strip().lower()

# ------------- FETCH USERS -------------
users_ref = db.collection("Users")
users = users_ref.stream()

total_rows = 0

for user_doc in users:
    user_data = user_doc.to_dict()
    email = user_data.get("email", "").lower()
    pid = user_data.get("participantID", "")

    if choice in ["3", "4"] and user_filter:
        if user_filter not in [pid.lower(), email]:
            continue

    uid = user_doc.id

    # Fetch all daily statuses (responded vs not)
    daily_status_docs = db.collection("DailyStatus").where("userID", "==", uid).stream()
    daily_status_map = {d.to_dict().get("date"): d.to_dict() for d in daily_status_docs}

    # Subcollections
    madrs_docs = list(
        db.collection("Users").document(uid).collection("MADRSResponses").stream()
    )
    sleep_docs = list(
        db.collection("Users").document(uid).collection("SleepDiaryResponses").stream()
    )
    device_docs = list(
        db.collection("Users").document(uid).collection("DeviceFeedbackResponses").stream()
    )

    # Build date → response maps
    madrs_by_date = {doc.to_dict().get("date"): doc.to_dict() for doc in madrs_docs}
    sleep_by_date = {doc.to_dict().get("date"): doc.to_dict() for doc in sleep_docs}
    device_by_date = {doc.to_dict().get("date"): doc.to_dict() for doc in device_docs}

    # All dates for this user
    all_dates = sorted(set(
        list(madrs_by_date.keys()) +
        list(sleep_by_date.keys()) +
        list(device_by_date.keys()) +
        list(daily_status_map.keys())
    ))

    for date_str in all_dates:
        # Date filtering
        if date_from and date_to:
            try:
                d_obj = datetime.strptime(date_str, "%Y-%m-%d").date()
                if not (date_from <= d_obj <= date_to):
                    continue
            except:
                pass

        status = daily_status_map.get(date_str, {"responded": False})

        responded = status.get("responded", False)

        if responded is False:
            # USER DID NOT RESPOND → fill everything with N/A
            row = (
                [pid, email, date_str, "N/A", "NO"]
                + ["N/A"] * 10  # MADRS
                + ["N/A"] * 6   # Sleep
                + ["N/A"] * 3   # Feedback
            )
            sheet.append(row)
            total_rows += 1
            continue

        # If responded TRUE → fill real values
        madrs_data = madrs_by_date.get(date_str, {})
        sleep_data = sleep_by_date.get(date_str, {})
        device_data = device_by_date.get(date_str, {})

        time_str = madrs_data.get("time", "N/A")

        madrs_values = [map_value(v) for v in madrs_data.get("responses", {}).values()]
        sleep_values = [map_value(v) for v in sleep_data.get("responses", {}).values()]
        device_values = [map_value(v) for v in device_data.get("responses", {}).values()]

        # Ensure correct lengths
        madrs_values += ["N/A"] * (10 - len(madrs_values))
        sleep_values += ["N/A"] * (6 - len(sleep_values))
        device_values += ["N/A"] * (3 - len(device_values))

        row = [pid, email, date_str, time_str, "YES"] + madrs_values + sleep_values + device_values
        sheet.append(row)
        total_rows += 1

# ------------- SAVE FILE -------------
timestamp = datetime.now().strftime("%Y-%m-%d_%H-%M-%S")
filename = f"AllResponses_{timestamp}.xlsx"
filepath = os.path.join(output_folder, filename)
wb.save(filepath)

print("\nExport completed successfully!")
print(f"File saved at: {filepath}")
print(f"Total rows exported: {total_rows}")
