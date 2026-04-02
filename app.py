import os
import pandas as pd
import gspread
from google.auth.transport.requests import Request
from google.oauth2.credentials import Credentials
from google_auth_oauthlib.flow import InstalledAppFlow
import json
import urllib
import gradio as gr
import time
from datetime import datetime
from pytz import timezone
import threading
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# Time zone Conversion
ist = timezone("Asia/Kolkata")

# Scopes (read-only)
SCOPES = ["https://www.googleapis.com/auth/spreadsheets.readonly"]

def authorize():
    creds = None
    
    # Get JSON content from environment variables
    token_json_content = os.getenv('TOKEN_JSON')
    credentials_json_content = os.getenv('CREDENTIALS_JSON')
    
    # Load token from environment variable if exists
    if token_json_content:
        try:
            token_info = json.loads(token_json_content)
            creds = Credentials.from_authorized_user_info(token_info, SCOPES)
        except json.JSONDecodeError:
            print("⚠️ Invalid TOKEN_JSON format in environment variable")
    
    # If no valid credentials, start OAuth flow
    if not creds or not creds.valid:
        if creds and creds.expired and creds.refresh_token:
            creds.refresh(Request())
        else:
            if not credentials_json_content:
                raise ValueError("CREDENTIALS_JSON environment variable is required for OAuth flow")
            
            try:
                credentials_info = json.loads(credentials_json_content)
                flow = InstalledAppFlow.from_client_config(credentials_info, SCOPES)
                creds = flow.run_local_server(port=0)
            except json.JSONDecodeError:
                raise ValueError("Invalid CREDENTIALS_JSON format in environment variable")
        
        # Save token back to environment (for this session only)
        # Note: You may want to update your .env file manually with the new token
        print("🔄 New token generated. Consider updating TOKEN_JSON in your .env file with:")
        print(f"TOKEN_JSON={creds.to_json()}")
    
    return gspread.authorize(creds)

# NEW FUNCTION: Extract subjects and marks
def extract_subjects_and_marks_for_gradio(roll_no):
    """
    Extract subjects with their redeemed points and marks for Gradio interface
    Uses cached studentwise_data instead of making fresh API calls
    """
    if not roll_no.strip():
        return "❌ Please enter a roll number"
    
    try:
        # Get cached data instead of making API calls
        combined_df, studentwise_data, details_info, reward_points_df = get_cached_data()
        
        if not studentwise_data or len(studentwise_data) < 2:
            return "❌ Studentwise data not available in cache"
        
        headers = studentwise_data[0]
        roll_no = roll_no.strip().upper()
        
        # Replace indexing with loop search:
        student_row = None
        for row in studentwise_data[1:]:  # Skip header row
            # Check multiple columns for roll number
            for i, cell in enumerate(row[:5]):  # Check first 5 columns
                if cell.strip().upper() == roll_no:
                    student_row = row
                    break
            if student_row is not None:
                break
        
        if student_row is None:
            return f"❌ Student with Roll No '{roll_no}' not found."

        # Rest of the function remains the same...
        def get_value_if_not_empty(col_name):
            """Helper function to get value only if it's not empty"""
            if col_name in headers:
                idx = headers.index(col_name)
                value = student_row[idx] if idx < len(student_row) else ''
                return value.strip() if value.strip() else None
            return None

        def get_numeric_value(col_name):
            """Helper function to get numeric value, return 0 if empty or invalid"""
            value = get_value_if_not_empty(col_name)
            try:
                return float(value) if value else 0.0
            except (ValueError, TypeError):
                return 0.0

        # Get student basic info
        student_name = get_value_if_not_empty("Student Name") or "Unknown"
        
        # Collect theory subjects (optimized loops)
        theory_subjects = []
        for i in range(1, 10):
            subject_code = get_value_if_not_empty(f"TS{i}")
            if subject_code:
                theory_subjects.append({
                    'code': subject_code,
                    'ip1_points': get_numeric_value(f"IP1TS{i}R"),
                    'ip2_points': get_numeric_value(f"IP2TS{i}R"),
                    'ip1_marks': get_numeric_value(f"IP1TS{i}M"),
                    'ip2_marks': get_numeric_value(f"IP2TS{i}M")
                })

        # Collect lab subjects (optimized loops)
        lab_subjects = []
        for i in range(1, 3):
            subject_code = get_value_if_not_empty(f"LS{i}")
            if subject_code:
                lab_subjects.append({
                    'code': subject_code,
                    'ip1_points': get_numeric_value(f"IP1LS{i}R"),
                    'ip2_points': get_numeric_value(f"IP2LS{i}R"),
                    'ip1_marks': get_numeric_value(f"IP1LS{i}M"),
                    'ip2_marks': get_numeric_value(f"IP2LS{i}M")
                })

        # Calculate totals using list comprehensions (faster)
        for subject in theory_subjects + lab_subjects:
            subject['total_points'] = subject['ip1_points'] + subject['ip2_points']
            subject['total_marks'] = subject['ip1_marks'] + subject['ip2_marks']

        # Calculate grand totals
        total_theory_ip1_points = sum(s['ip1_points'] for s in theory_subjects)
        total_theory_ip2_points = sum(s['ip2_points'] for s in theory_subjects)
        total_lab_ip1_points = sum(s['ip1_points'] for s in lab_subjects)
        total_lab_ip2_points = sum(s['ip2_points'] for s in lab_subjects)
        
        total_theory_ip1_marks = sum(s['ip1_marks'] for s in theory_subjects)
        total_theory_ip2_marks = sum(s['ip2_marks'] for s in theory_subjects)
        total_lab_ip1_marks = sum(s['ip1_marks'] for s in lab_subjects)
        total_lab_ip2_marks = sum(s['ip2_marks'] for s in lab_subjects)

        # Build output with clean card-style formatting
        output = []
        output.append("")
        output.append("🏆 INNOVATIVE PRACTICE (IP) SUMMARY")
        output.append("=" * 80)
        
        # Theory subjects section
        if theory_subjects:
            output.append(f"\n📚 THEORY SUBJECTS ({len(theory_subjects)} subjects)")
            output.append("-" * 50)
            
            for subject in theory_subjects:
                output.append(f"\n🔹 {subject['code']}")
                
                # Points section
                if subject['ip1_points'] > 0 or subject['ip2_points'] > 0:
                    points_line = "   Reward Points: "
                    if subject['ip1_points'] > 0:
                        points_line += f"IP-1: {subject['ip1_points']:.2f}"
                    if subject['ip2_points'] > 0:
                        if subject['ip1_points'] > 0:
                            points_line += f" | IP-2: {subject['ip2_points']:.2f}"
                        else:
                            points_line += f"IP-2: {subject['ip2_points']:.2f}"
                    points_line += f" | Total: {subject['total_points']:.2f}"
                    output.append(points_line)
                
                # Marks section
                if subject['ip1_marks'] > 0 or subject['ip2_marks'] > 0:
                    marks_line = "   Internal Marks: "
                    if subject['ip1_marks'] > 0:
                        marks_line += f"IP-1: {subject['ip1_marks']:.2f}"
                    if subject['ip2_marks'] > 0:
                        if subject['ip1_marks'] > 0:
                            marks_line += f" | IP-2: {subject['ip2_marks']:.2f}"
                        else:
                            marks_line += f"IP-2: {subject['ip2_marks']:.2f}"
                    marks_line += f" | Total: {subject['total_marks']:.2f}"
                    output.append(marks_line)
        
        # Lab subjects section
        if lab_subjects:
            output.append(f"\n🧪 LAB SUBJECTS ({len(lab_subjects)} subjects)")
            output.append("-" * 50)
            
            for subject in lab_subjects:
                output.append(f"\n🔹 {subject['code']}")
                
                # Points section
                if subject['ip1_points'] > 0 or subject['ip2_points'] > 0:
                    points_line = "   Reward Points: "
                    if subject['ip1_points'] > 0:
                        points_line += f"IP-1: {subject['ip1_points']:.2f}"
                    if subject['ip2_points'] > 0:
                        if subject['ip1_points'] > 0:
                            points_line += f" | IP-2: {subject['ip2_points']:.2f}"
                        else:
                            points_line += f"IP-2: {subject['ip2_points']:.2f}"
                    points_line += f" | Total: {subject['total_points']:.2f}"
                    output.append(points_line)
                
                # Marks section
                if subject['ip1_marks'] > 0 or subject['ip2_marks'] > 0:
                    marks_line = "   Internal Marks: "
                    if subject['ip1_marks'] > 0:
                        marks_line += f"IP-1: {subject['ip1_marks']:.2f}"
                    if subject['ip2_marks'] > 0:
                        if subject['ip1_marks'] > 0:
                            marks_line += f" | IP-2: {subject['ip2_marks']:.2f}"
                        else:
                            marks_line += f"IP-2: {subject['ip2_marks']:.2f}"
                    marks_line += f" | Total: {subject['total_marks']:.2f}"
                    output.append(marks_line)
        
        # Summary section
        output.append("\n" + "=" * 80)
        output.append("📊 OVERALL SUMMARY")
        output.append("=" * 80)
        
        # Reward Points Summary
        output.append("\n🏅 REWARD POINTS BREAKDOWN:")
        if theory_subjects:
            theory_total = total_theory_ip1_points + total_theory_ip2_points
            output.append(f"   Theory Subjects: {theory_total:.2f} points")
            if total_theory_ip1_points > 0:
                output.append(f"     ➤ IP-1: {total_theory_ip1_points:.2f}")
            if total_theory_ip2_points > 0:
                output.append(f"     ➤ IP-2: {total_theory_ip2_points:.2f}")
        
        if lab_subjects:
            lab_total = total_lab_ip1_points + total_lab_ip2_points
            output.append(f"   Lab Subjects: {lab_total:.2f} points")
            if total_lab_ip1_points > 0:
                output.append(f"     ➤ IP-1: {total_lab_ip1_points:.2f}")
            if total_lab_ip2_points > 0:
                output.append(f"     ➤ IP-2: {total_lab_ip2_points:.2f}")
        
        grand_total_points = (total_theory_ip1_points + total_theory_ip2_points + 
                             total_lab_ip1_points + total_lab_ip2_points)
        output.append(f"\n🎯 TOTAL REWARD POINTS: {grand_total_points:.2f}")
        
        # Internal Marks Summary
        output.append("\n📝 INTERNAL MARKS BREAKDOWN:")
        if theory_subjects:
            theory_marks_total = total_theory_ip1_marks + total_theory_ip2_marks
            output.append(f"   Theory Subjects: {theory_marks_total:.2f} marks")
            if total_theory_ip1_marks > 0:
                output.append(f"     ➤ IP-1: {total_theory_ip1_marks:.2f}")
            if total_theory_ip2_marks > 0:
                output.append(f"     ➤ IP-2: {total_theory_ip2_marks:.2f}")
        
        if lab_subjects:
            lab_marks_total = total_lab_ip1_marks + total_lab_ip2_marks
            output.append(f"   Lab Subjects: {lab_marks_total:.2f} marks")
            if total_lab_ip1_marks > 0:
                output.append(f"     ➤ IP-1: {total_lab_ip1_marks:.2f}")
            if total_lab_ip2_marks > 0:
                output.append(f"     ➤ IP-2: {total_lab_ip2_marks:.2f}")
        
        grand_total_marks = (total_theory_ip1_marks + total_theory_ip2_marks + 
                            total_lab_ip1_marks + total_lab_ip2_marks)
        output.append(f"\n📊 TOTAL INTERNAL MARKS: {grand_total_marks:.2f}")
        
        total_subjects = len(theory_subjects) + len(lab_subjects)
        output.append(f"\n📚 TOTAL SUBJECTS: {total_subjects}")
        
        output.append("\n" + "=" * 80)
        
        # Log the search
        now_ist = datetime.now(ist).strftime("%Y-%m-%d %H:%M:%S")
        print(f"IP Details Searched - Roll No: {roll_no} | Student: {student_name} | Time (IST): {now_ist}")
        
        return "\n".join(output)
    
    except Exception as e:
        error_msg = f"❌ Error extracting subject details: {str(e)}"
        print(error_msg)
        return error_msg


# Function to get data from a specific sheet
def get_sheet_data(spreadsheet, gid, sheet_name):
    try:
        sheet = spreadsheet.get_worksheet_by_id(gid)
        all_values = sheet.get_all_values()
        
        if not all_values or len(all_values) <= 4:
            print(f"⚠️ {sheet_name} sheet doesn't have enough data")
            return pd.DataFrame()
        
        # Use row 4 as headers (the actual column names)
        headers = all_values[4]
        clean_headers = []
        seen_headers = {}
        
        for i, header in enumerate(headers):
            if header.strip():  # Non-empty header
                base_header = header.strip()
                # Handle duplicate headers by adding a counter
                if base_header in seen_headers:
                    seen_headers[base_header] += 1
                    clean_header = f"{base_header}_{seen_headers[base_header]}"
                else:
                    seen_headers[base_header] = 0
                    clean_header = base_header
                clean_headers.append(clean_header)
            else:  # Empty header
                clean_headers.append(f"Empty_Col_{i}")

        # Create DataFrame starting from row 5 (after headers)
        data_rows = all_values[5:]
        if data_rows:
            df = pd.DataFrame(data_rows, columns=clean_headers)
            # Remove completely empty columns
            df = df.loc[:, (df != '').any(axis=0)]
            return df
        else:
            print(f"⚠️ No data rows found in {sheet_name}")
            return pd.DataFrame()
            
    except Exception as e:
        print(f"❌ Error loading {sheet_name}: {str(e)}")
        return pd.DataFrame()

# Function to get studentwise reward points data
def get_studentwise_data(spreadsheet):
    try:
        worksheet = spreadsheet.worksheet("Studentwise Reward Points")
        all_values = worksheet.get_all_values()
        
        if len(all_values) < 3:
            print("⚠️ Studentwise Reward Points sheet doesn't have enough data")
            return None
        
        print(f"✅ Loaded {len(all_values)} rows from Studentwise Reward Points")
        return all_values
        
    except Exception as e:
        print(f"❌ Error loading Studentwise Reward Points: {str(e)}")
        return None

# Function to load and cache reward points activity data
def load_reward_points_data():
    """Load and cache reward points activity data"""
    try:
        # Get the reward points sheet ID from environment
        REWARD_POINTS_SHEET_ID = os.getenv('REWARD_POINTS_SHEET_ID')
        
        if not REWARD_POINTS_SHEET_ID:
            print("⚠️ REWARD_POINTS_SHEET_ID not found in environment variables")
            return None
        
        client = authorize()
        spreadsheet = client.open_by_key(REWARD_POINTS_SHEET_ID)
        worksheet = spreadsheet.get_worksheet_by_id(658808574)  # Activity Sheet GID
        all_values = worksheet.get_all_values()
        
        if not all_values or len(all_values) < 2:
            print("⚠️ Reward Points sheet doesn't have enough data")
            return None
        
        # First row is header
        headers = all_values[0]
        df = pd.DataFrame(all_values[1:], columns=headers)
        
        if df.empty:
            print("⚠️ Reward Points sheet is empty")
            return None
        
        print(f"✅ Loaded {len(df)} rows from Reward Points Entry sheet")
        return df
        
    except Exception as e:
        print(f"❌ Error loading Reward Points data: {str(e)}")
        return None

# Function to get activity details from cached data in breakdown format

# Function to get activity details from cached data in breakdown format
def get_activity_details(roll_no, reward_points_df):
    """Get activity details for a specific roll number from cached reward points data."""
    try:
        if reward_points_df is None or reward_points_df.empty:
            return ""

        roll_no_search = roll_no.strip().upper()

        # -----------------------------
        # FIXED ROLL NUMBER DETECTION
        # -----------------------------
        roll_col = None

        # 1️⃣ Try header match
        for col in reward_points_df.columns:
            cl = col.lower().replace(" ", "")
            if "roll" in cl or "reg" in cl:
                roll_col = col
                break

        # 2️⃣ Pattern match (fallback)
        if roll_col is None:
            for col in reward_points_df.columns:
                sample = (
                    reward_points_df[col]
                    .astype(str)
                    .str.upper()
                    .head(40)
                )
                if sample.str.match(r"(7376|2025)[A-Z0-9]+").sum() >= 2:
                    roll_col = col
                    break

        # 3️⃣ Ultimate fallback
        if roll_col is None:
            roll_col = reward_points_df.columns[len(reward_points_df.columns)//2]

        # Normalize roll number column
        df = reward_points_df.copy()
        df[roll_col] = df[roll_col].astype(str).str.strip().str.upper()

        student_rows = df[df[roll_col] == roll_no_search]

        # Try partial match
        if student_rows.empty:
            partial_matches = df[df[roll_col].str.contains(roll_no_search, na=False)]
            if not partial_matches.empty:
                student_rows = partial_matches

        if student_rows.empty:
            return ""  # No activity rows

        # Build output
        output = []
        activity_summary = {}
        activity_count = {}
        total_points = 0

        for _, row in student_rows.iterrows():
            activity_type = str(row.get("Activity Type", "")).strip()
            reward_points = str(row.get("Reward Points", "0")).replace(",", "")

            # Convert points
            try:
                points_val = float(reward_points)
            except:
                points_val = 0

            total_points += points_val

            # Update summary
            activity_summary[activity_type] = activity_summary.get(activity_type, 0) + points_val
            activity_count[activity_type] = activity_count.get(activity_type, 0) + 1

        output.append("📋 DETAILED ACTIVITY LIST")
        output.append("=" * 80)

        for idx, (_, row) in enumerate(student_rows.iterrows(), 1):
            name = str(row.get("Activity Name", "")).strip()
            points = str(row.get("Reward Points", "0"))
            activity_type = str(row.get("Activity Type", "")).strip()
            display = name[:85] + "..." if len(name) > 85 else name
            output.append(f"{idx:2d}. {activity_type}: {display} - {points} pts")

        output.append("=" * 80)
        output.append(f"🎯 TOTAL REWARD POINTS FROM ACTIVITIES: {total_points:.2f}")
        output.append("=" * 80)

        return "\n".join(output)

    except Exception as e:
        print(f"❌ Error fetching activity details: {str(e)}")
        return ""


# Function to get details sheet information
def get_details_info(spreadsheet):
    try:
        details_sheet = spreadsheet.get_worksheet_by_id(847680829)
        all_values = details_sheet.get_all_values()
        
        if not all_values:
            return None
        
        # Use row 4 as headers
        headers = all_values[4]
        clean_headers = []
        for i, header in enumerate(headers):
            if header.strip():
                clean_headers.append(header.strip())
            else:
                clean_headers.append(f"Empty_Col_{i}")
        
        # Get data rows after header
        data_rows = all_values[5:]
        
        if data_rows:
            df = pd.DataFrame(data_rows, columns=clean_headers)
            df = df.loc[:, (df != '').any(axis=0)]
            
            details_info = {}
            
            # Extract specific information
            for idx in range(len(df)):
                student_data = df.iloc[idx]
                year_value = str(student_data.get('YEAR', '')).strip()
                
                # Get Average Reward Points
                if 'AVERAGE REWARD POINT' in year_value:
                    details_info['average_points'] = {
                        'I': student_data.get('I', ''),
                        'II': student_data.get('II', ''),
                        'II L': student_data.get('II L', ''),
                        'III': student_data.get('III', ''),
                        'IV': student_data.get('IV', '')
                    }
                
                # Get IP 2 Redemption Dates
                elif 'Last Day for IP 2 Redemption Duration' in str(student_data.get('Redemption Dates', '')):
                    details_info['ip2_redemption'] = {
                        'S1': student_data.get('S1', ''),
                        'S2': student_data.get('S2', ''),
                        'S3': student_data.get('S3', ''),
                        'S4': student_data.get('S4', ''),
                        'S5': student_data.get('S5', ''),
                        'S6': student_data.get('S6', ''),
                        'S7': student_data.get('S7', ''),
                        'S8': student_data.get('S8', '')
                    }
                
                # Get IP 1 Redemption Dates
                elif 'Last Day for IP 1 Redemption Duration' in str(student_data.get('Redemption Dates', '')):
                    details_info['ip1_redemption'] = {
                        'S1': student_data.get('S1', ''),
                        'S2': student_data.get('S2', ''),
                        'S3': student_data.get('S3', ''),
                        'S4': student_data.get('S4', ''),
                        'S5': student_data.get('S5', ''),
                        'S6': student_data.get('S6', ''),
                        'S7': student_data.get('S7', ''),
                        'S8': student_data.get('S8', '')
                    }
                
                # Get Last Updated Information
                elif 'POINTS LAST UPDATED' in year_value:
                    details_info['last_updated'] = year_value
            
            return details_info
            
    except Exception as e:
        print(f"❌ Error loading Details Sheet: {str(e)}")
        return None

# Initialize global variables
print("🚀 Initializing application...")
client = authorize()

# Get spreadsheet IDs from environment variables
MAIN_SHEET_ID = os.getenv('GOOGLE_SHEET_ID')  # Your main sheets (20 sheets)
STUDENTWISE_SHEET_ID = os.getenv('STUDENTWISE_SHEET_ID')  # Studentwise Reward Points sheet

if not MAIN_SHEET_ID:
    raise ValueError("GOOGLE_SHEET_ID environment variable is required")

# Open both spreadsheets
main_spreadsheet = client.open_by_key(MAIN_SHEET_ID)
studentwise_spreadsheet = client.open_by_key(STUDENTWISE_SHEET_ID)

# Load data from all sheets (Original 3 + New 17 = 20 sheets total)
sheet_configs = [
    # Original sheets
    {"gid": 212584501, "name": "AIML"},
    {"gid": 987009028, "name": "AIDS"}, 
    {"gid": 1787666621, "name": "Sheet_3"},
    {"gid": 1767133750, "name": "Sheet_4"},
    {"gid": 474768794, "name": "Sheet_5"},
    {"gid": 1603336568, "name": "Sheet_6"},
    {"gid": 585316530, "name": "Sheet_7"},
    {"gid": 47220595, "name": "Sheet_8"},
    {"gid": 401996823, "name": "Sheet_9"},
    {"gid": 1090232826, "name": "Sheet_10"},
    {"gid": 2136186210, "name": "Sheet_11"},
    {"gid": 1171443986, "name": "Sheet_12"},
    {"gid": 552072393, "name": "Sheet_13"},
    {"gid": 2004248702, "name": "Sheet_14"},
    {"gid": 338745439, "name": "Sheet_15"},
    {"gid": 1726045106, "name": "Sheet_16"},
    {"gid": 1614595844, "name": "Sheet_17"},
    {"gid": 829636275, "name": "Sheet_18"},
    {"gid": 1604596346, "name": "Sheet_19"},
    # {"gid": 400900059, "name": "Sheet_20"}
]

# GLOBAL DATA CACHE WITH 12-HOUR AUTO-REFRESH
data_cache = {
    "combined_df": None,
    "studentwise_data": None,
    "details_info": None,
    "reward_points_df": None,
    "last_update": None,
    "cache_duration_hours": 12,  # 12 hours cache
    "is_loading": False
}

def load_all_data():
    """Load and cache all data from Google Sheets (auto-retries failed sheets with backoff)"""
    global data_cache
    
    if data_cache["is_loading"]:
        print("⏳ Data loading already in progress...")
        return (data_cache["combined_df"], data_cache["studentwise_data"], 
                data_cache["details_info"], data_cache["reward_points_df"])
    
    data_cache["is_loading"] = True
    print(f"🔄 Loading data from {len(sheet_configs)} Google Sheets + Reward Points sheet...")
    start_time = time.time()
    
    try:
        all_dataframes = []
        failed_sheets = []
        max_retries = 5  # Prevent infinite recursion
        retry_delay = 2   # Start with 2 seconds

        # 1️⃣ First attempt to load each sheet
        print("📋 Initial loading attempt...")
        for config in sheet_configs:
            df = get_sheet_data(main_spreadsheet, config["gid"], config["name"])
            if df.empty:
                print(f"⚠️ {config['name']} failed to load, will retry...")
                failed_sheets.append(config)
            else:
                df['Source_Sheet'] = config["name"]
                all_dataframes.append(df)
                print(f"✅ Loaded {len(df)} rows from {config['name']}")

        # 2️⃣ Retry failed sheets with exponential backoff
        for attempt in range(1, max_retries + 1):
            if not failed_sheets:
                break
                
            print(f"🔄 Retry attempt {attempt}/{max_retries} for {len(failed_sheets)} failed sheets...")
            time.sleep(retry_delay)
            
            retry_failed = []
            for config in failed_sheets:
                print(f"   🔄 Retrying {config['name']}...")
                df = get_sheet_data(main_spreadsheet, config["gid"], config["name"])
                if df.empty:
                    print(f"   ❌ Still failed: {config['name']}")
                    retry_failed.append(config)
                else:
                    df['Source_Sheet'] = config["name"]
                    all_dataframes.append(df)
                    print(f"   ✅ Retry success: {config['name']} ({len(df)} rows)")

            failed_sheets = retry_failed
            retry_delay *= 2  # Exponential backoff: 2s, 4s, 8s

        # 3️⃣ Handle permanently failed sheets
        if failed_sheets:
            failed_names = [config['name'] for config in failed_sheets]
            print(f"⚠️ Warning: {len(failed_sheets)} sheets failed after {max_retries} retries: {', '.join(failed_names)}")
            
            # Continue with available data instead of aborting
            if all_dataframes:
                print(f"✅ Continuing with {len(all_dataframes)} successfully loaded sheets")
            else:
                print("❌ Critical: No sheets loaded successfully!")
                # Return empty data but don't crash
                return pd.DataFrame(), None, None, None
        
        # 4️⃣ Combine successfully loaded sheets
        if all_dataframes:
            try:
                combined_df = pd.concat(all_dataframes, ignore_index=True, sort=False)
                print(f"✅ Successfully combined {len(combined_df)} records from {len(all_dataframes)} sheets")
            except Exception as e:
                print(f"❌ Error combining dataframes: {str(e)}")
                print("🔄 Trying alternative approach...")
                
                # Alternative approach: standardize columns first
                standard_columns = ['SL. NO.', 'YEAR', 'ROLL NO.', 'STUDENT NAME', 'COURSE CODE', 
                                   'DEPARTMENT', 'MENTOR NAME', 'CUMULATIVE REWARD POINTS', 
                                   'REEDEMED POINTS', 'BALANCE POINTS', 'Source_Sheet']
                
                standardized_dfs = []
                for df in all_dataframes:
                    new_df = pd.DataFrame()
                    for col in standard_columns:
                        if col == 'Source_Sheet':
                            new_df[col] = df.get('Source_Sheet', '')
                        else:
                            # Try to find matching column
                            found_col = None
                            for df_col in df.columns:
                                if col.upper() in df_col.upper() or df_col.upper() in col.upper():
                                    found_col = df_col
                                    break
                            
                            if found_col:
                                new_df[col] = df[found_col]
                            else:
                                new_df[col] = ''
                    
                    standardized_dfs.append(new_df)
                
                combined_df = pd.concat(standardized_dfs, ignore_index=True, sort=False)
                print(f"✅ Alternative approach successful: {len(combined_df)} records combined")
        else:
            combined_df = pd.DataFrame()
            print("⚠️ No sheets loaded successfully")

        # 5️⃣ Load supporting data (with error handling)
        print("📊 Loading supporting data...")
        studentwise_data = get_studentwise_data(studentwise_spreadsheet)
        details_info = get_details_info(main_spreadsheet)
        reward_points_df = load_reward_points_data()

        # 6️⃣ Update cache
        data_cache.update({
            "combined_df": combined_df,
            "studentwise_data": studentwise_data,
            "details_info": details_info,
            "reward_points_df": reward_points_df,
            "last_update": datetime.now(),
        })

        load_time = time.time() - start_time
        
        if failed_sheets:
            print(f"⚠️ Partial load completed in {load_time:.2f} seconds")
            print(f"✅ {len(all_dataframes)}/{len(sheet_configs)} sheets loaded successfully")
        else:
            print(f"⏱️ All data successfully loaded in {load_time:.2f} seconds")
            print("✅ Application ready — all sheets verified")

        return combined_df, studentwise_data, details_info, reward_points_df

    except Exception as e:
        print(f"❌ Critical error in load_all_data: {str(e)}")
        return (
            data_cache.get("combined_df", pd.DataFrame()),
            data_cache.get("studentwise_data", None),
            data_cache.get("details_info", None),
            data_cache.get("reward_points_df", None),
        )

    finally:
        data_cache["is_loading"] = False


def get_cached_data():
    """Get data from cache or refresh if 12 hours have passed"""
    now = datetime.now()
    
    # Check if cache is empty or expired (12 hours)
    if (data_cache["last_update"] is None or 
        data_cache["combined_df"] is None or
        (now - data_cache["last_update"]).total_seconds() > (data_cache["cache_duration_hours"] * 3600)):
        
        print("🔄 Cache expired or empty, loading fresh data...")
        return load_all_data()
    else:
        cache_age_hours = (now - data_cache["last_update"]).total_seconds() / 3600
        print(f"🚀 Using cached data (age: {cache_age_hours:.1f} hours)")
        return (data_cache["combined_df"], data_cache["studentwise_data"], 
                data_cache["details_info"], data_cache["reward_points_df"])

def auto_refresh_worker():
    """Background worker to auto-refresh data every 12 hours"""
    while True:
        try:
            # Sleep for 12 hours (43200 seconds)
            time.sleep(43200)
            print("⏰ 12-hour auto-refresh triggered...")
            load_all_data()
        except Exception as e:
            print(f"❌ Auto-refresh error: {str(e)}")
            # If error, wait 1 hour before trying again
            time.sleep(3600)

def details_sheet_watcher():
    """Background watcher: checks every 30 seconds (drift-free, IST logs) if 'POINTS LAST UPDATED' changed safely"""
    import time
    from datetime import datetime

    last_seen_update = None
    consecutive_errors = 0
    max_errors = 10

    watcher_client = None
    watcher_spreadsheet = None
    watcher_sheet = None
    last_connection_time = None
    connection_duration = 3600  # 1 hour
    check_interval = 30  # seconds
    next_check = time.time()

    TARGET_ROW, TARGET_COL = 16, 2

    print(f"👀 Starting optimized details sheet watcher (R{TARGET_ROW}C{TARGET_COL}, every {check_interval}s)...")

    global last_auth_refresh
    last_auth_refresh = 0

    while True:
        try:
            if data_cache["is_loading"]:
                print("⏳ Watcher: Skipping check – data loading in progress")
            else:
                current_time = datetime.now()

                # Refresh only if 24 hours passed or connection lost
                should_refresh = (
                    watcher_client is None
                    or watcher_sheet is None
                    or last_connection_time is None
                    or (current_time - last_connection_time).total_seconds() > connection_duration
                )

                if should_refresh:
                    # Enforce 5-min cooldown between authorizations
                    if time.time() - last_auth_refresh < 300:
                        print("⏳ Skipping token refresh — recently done.")
                    else:
                        print("🔄 Watcher: Refreshing connection...")
                        try:
                            watcher_client = authorize()
                            watcher_spreadsheet = watcher_client.open_by_key(os.getenv("GOOGLE_SHEET_ID"))
                            watcher_sheet = watcher_spreadsheet.get_worksheet_by_id(847680829)
                            last_connection_time = current_time
                            last_auth_refresh = time.time()
                            print(f"✅ Watcher: Connection refreshed (monitoring cell R{TARGET_ROW}C{TARGET_COL})")
                        except Exception as e:
                            print(f"⚠️ Watcher: Failed to refresh connection — {str(e)[:100]}")
                            time.sleep(60)
                            continue

                # Skip check if no valid sheet
                if not watcher_sheet:
                    time.sleep(check_interval)
                    continue

                try:
                    # Fetch only specific cell value
                    cell_value = watcher_sheet.cell(TARGET_ROW, TARGET_COL).value
                    current_update = str(cell_value).strip() if cell_value else ""
                    now_ist = datetime.now(ist).strftime("%Y-%m-%d %H:%M:%S")

                    if last_seen_update is None:
                        last_seen_update = current_update
                        print(f"🕒 Watcher started at {now_ist}")
                        print(f"    Target R{TARGET_ROW}C{TARGET_COL}: {current_update[:80]}...")
                    elif current_update != last_seen_update:
                        print(f"🔄 CHANGE DETECTED! ({now_ist})")
                        print(f"    Old: {last_seen_update[:60]}...")
                        print(f"    New: {current_update[:60]}...")
                        last_seen_update = current_update

                        if not data_cache["is_loading"]:
                            print("🔄 Reloading data directly...")
                            load_all_data()
                            print(f"✅ Data reload completed successfully ({now_ist})")
                        else:
                            print(f"⏳ Data already loading, skipping reload ({now_ist})")
                    else:
                        current_ist = datetime.now(ist)
                        if current_ist.minute % 5 == 0 and current_ist.second < check_interval:
                            print(f"✅ Watcher: No changes detected in R{TARGET_ROW}C{TARGET_COL} ({current_ist.strftime('%H:%M:%S')})")

                except Exception as cell_error:
                    print(f"⚠️ Error reading cell R{TARGET_ROW}C{TARGET_COL}: {str(cell_error)[:200]}")
                    consecutive_errors += 1

            # Reset error counter if stable
            if consecutive_errors > 0:
                print(f"✅ Watcher: Connection restored (cleared {consecutive_errors} errors)")
                consecutive_errors = 0

        except Exception as e:
            consecutive_errors += 1
            print(f"⚠️ Watcher error #{consecutive_errors}: {str(e)[:200]}")
            watcher_client = None
            watcher_spreadsheet = None
            watcher_sheet = None

            if consecutive_errors >= max_errors:
                print("❌ Too many watcher errors, waiting 5 minutes before retry...")
                time.sleep(300)
                consecutive_errors = 0

        # Drift-free sleep to maintain 30s sync
        next_check += check_interval
        time.sleep(max(0, next_check - time.time()))


def get_detailed_student_points(roll_no, studentwise_data):
    """Get detailed points breakdown from studentwise data"""
    if not studentwise_data or len(studentwise_data) < 3:
        return ""
    
    headers = studentwise_data[0]
    student_found = None
    for row in studentwise_data[2:]:
        if len(row) > 1 and row[1].strip().upper() == roll_no.strip().upper():
            student_found = row
            break
    if not student_found:
        return ""
    
    student_data = {}
    for i, header in enumerate(headers):
        student_data[header] = student_found[i] if i < len(student_found) else ""
    
    output = []
    output.append("")
    output.append("🏆 REWARD POINTS BREAKDOWN")
    output.append("=" * 80)
    
    # Using a different approach - no column headers, just data with clear labels
    categories = [
        ("INITIAL POINTS / CARRY-OVER", "-", "Initial Points"),
        ("TECHNICAL EVENTS", "Technical Events Count", "Technical Events Points"),
        ("SKILLS", "Skill Count", "Skill Points"),
        ("ASSIGNMENTS", "Assignement Count", "Assignment Points"),
        ("INTERVIEW", "Interview Count", "Interview Points"),
        ("TECHNICAL SOCIETY ACTIVITIES", "TECHNICAL SOCIETY ACTIVITIES Count", "TECHNICAL SOCIETY ACTIVITIES Points"),
        ("P SKILL", "P Skill Count", "P Skill Points"),
        ("TAC", "TAC Count", "TAC Points"),
        ("SPECIAL LAB INITIATIVES", "Special Lab Initiatives Count", "Special Lab Initiatives Points"),
        ("EXTRA-CURRICULAR ACTIVITIES", "EXTRA-CURRICULAR ACTIVITIES COUNT", "EXTRA-CURRICULAR ACTIVITIES POINTS"),
        ("STUDENT INITIATIVES", "STUDENT INITIATIVES COUNT", "STUDENT INITIATIVES POINTS"),
        ("EXTERNAL EVENTS", "EXTERNAL EVENTS COUNT", "EXTERNAL EVENTS POINTS"),
        ("TOTAL (2025-2026 EVEN)", "Total Count", "Total Points"),
        ("PENALTIES", "Negative Count", "Negative Points"),
        ("CUMULATIVE POINTS", "-", "Cumulative Points"),
        ("INNOVATIVE PRACTICE - 1 (IP-1)", "-", "IP 1 R"),
        ("INNOVATIVE PRACTICE - 2 (IP-2)", "-", "IP 2 R"),
        ("REDEEMED POINTS", "-", "Redeemed Points"),
        ("BALANCE POINTS", "-", "Balance Points"),
        ("CARRY FORWARD TO NEXT SEMESTER", "-", "EL. CA. FR. POINTS")
    ]
    
    total_earned = 0
    total_redeemed = 0

    for idx, (category_name, count_key, points_key) in enumerate(categories):
        count_val = "-" if count_key == "-" else student_data.get(count_key, "0")
        points_val = student_data.get(points_key, "0.00")
        
        try:
            if points_val and points_val != "-":
                points_float = float(str(points_val).replace(',', ''))
                points_val = f"{points_float:.2f}"
                if points_key == "Cumulative Points":
                    total_earned = points_float
                elif points_key == "Redeemed Points":
                    total_redeemed = points_float
        except:
            pass

        # Alternative format - more readable
        output.append(f"📋 **{category_name}**")
        output.append(f"   Count: {count_val}  |  Points: {points_val}")

    output.append("=" * 80)

    return "\n".join(output)

def calculate_yearwise_average_points():
    """Calculate year-wise average points from the combined data"""
    combined_df, _, _, _ = get_cached_data()
    if combined_df.empty:
        return "❌ No data available to calculate averages"

    # Try to find columns automatically
    year_col, points_col = None, None
    for col in combined_df.columns:
        if 'year' in col.lower():
            year_col = col
        if 'balance' in col.lower() and 'points' in col.lower():
            points_col = col
    
    if not year_col or not points_col:
        return "⚠️ Required columns not found in the data"

    # Create a copy for processing
    df = combined_df[[year_col, points_col]].copy()
    
    # Clean and convert points data
    df[points_col] = pd.to_numeric(
        df[points_col].astype(str).str.replace(',', '').str.strip(), 
        errors='coerce'
    )
    df.dropna(subset=[points_col], inplace=True)
    
    # Remove rows with zero or negative points for more accurate averages
    df = df[df[points_col] > 0]

    if df.empty:
        return "⚠️ No valid points data found for calculation"

    # Group by year
    yearwise = df.groupby(year_col)[points_col].agg(['sum', 'count', 'mean', 'min', 'max']).reset_index()
    yearwise['average'] = yearwise['mean']  # Use pandas mean for consistency

    # Format the output neatly
    output = []
    output.append("=" * 90)
    output.append(" ")
    output.append("📊 YEAR-WISE AVERAGE REWARD POINTS (CALCULATED)")
    output.append("-" * 90)
    
    for _, row in yearwise.iterrows():
        year = str(row[year_col]).strip()
        total_points = f"{row['sum']:.0f}"
        count = int(row['count'])
        avg = f"{row['average']:.2f}"
        min_pts = f"{row['min']:.0f}"
        max_pts = f"{row['max']:.0f}"
        
        output.append(f"Year {year:<10} {avg}")
    
    output.append("=" * 90)
    return "\n".join(output)

# Load initial data
print("📊 Loading initial data...")
load_all_data()

# Start background auto-refresh thread
refresh_thread = threading.Thread(target=auto_refresh_worker, daemon=True)
refresh_thread.start()
print("🕒 Auto-refresh thread started (updates every 12 hours)")

# Start details sheet watcher thread
watcher_thread = threading.Thread(target=details_sheet_watcher, daemon=True)
watcher_thread.start()
print("👀 Details sheet watcher started (checks every 1 minute)")

# Function to search student with cached data
def search_student(roll_no):
    if not roll_no.strip():
        return "❌ Please enter a roll number"
    
    # Convert roll number to uppercase for consistent searching
    roll_no = roll_no.strip().upper()
    
    # Get cached data (fast response, auto-refreshes every 12 hours)
    combined_df, studentwise_data, details_info, reward_points_df = get_cached_data()
    
    if combined_df.empty:
        return "❌ No data available from Google Sheets"
    
    # Look for 'ROLL NO.' column
    roll_column = None
    for col in combined_df.columns:
        if 'roll' in col.lower() and 'no' in col.lower():
            roll_column = col
            break
    
    if roll_column is None:
        return f"❌ Roll number column not found. Available columns: {list(combined_df.columns)}"
    
    # Convert the roll numbers in DataFrame to uppercase for comparison
    student = combined_df[combined_df[roll_column].astype(str).str.strip().str.upper() == roll_no]
    if student.empty:
        return f"❌ Roll No '{roll_no}' not found in any sheet" 
    
    record = student.iloc[0].to_dict()
    student_name = str(record.get('STUDENT NAME', 'Unknown')).strip()
    student_year = str(record.get('YEAR', '')).strip()

    now_ist = datetime.now(ist).strftime("%Y-%m-%d %H:%M:%S")
    # Log to see which roll number and student name is searched by user
    print(f"Roll No Searched: {roll_no} | Student Name: {student_name} | Time (IST): {now_ist}")
    
    # Format output - Simplified version
    output = []
    output.append(f"Hello {student_name} 👋")
    output.append("=" * 80)
    output.append("YOUR DETAILS")
    output.append("=" * 80)
    
    # Main student details
    main_fields = ['ROLL NO.', 'STUDENT NAME', 'YEAR', 'DEPARTMENT', 'MENTOR NAME', 
                   'CUMULATIVE REWARD POINTS', 'REEDEMED POINTS', 'BALANCE POINTS']
    
    for field in main_fields:
        value = record.get(field, '')
        if str(value).strip():
            output.append(f"{field:<25}: {value}")
    
    # Get student's current points (clean numeric value)
    try:
        student_points_str = str(record.get('BALANCE POINTS', '')).replace(',', '').strip()
        student_points = float(student_points_str) if student_points_str else 0
    except:
        student_points = 0
    
    # Add year-specific average points and analysis
    if details_info and 'average_points' in details_info:
        output.append("\n" + "=" * 80)
        output.append(f"AVERAGE REWARD POINTS FOR YEAR {student_year}")
        output.append("=" * 80)
        
        if student_year in details_info['average_points']:
            avg_points_str = details_info['average_points'][student_year]
            try:
                avg_points = float(avg_points_str) if avg_points_str else 0
            except:
                avg_points = 0
            
            if avg_points > 0:
                output.append(f"Average Points for Year {student_year:<8}: {avg_points_str}")
                
                # Calculate difference and provide guidance
                points_difference = avg_points - student_points
                
                if points_difference > 0:
                    # Student is below average
                    output.append(f"\n🎯 POINTS NEEDED TO REACH AVERAGE: {points_difference:.0f} points")
                    output.append("\n💡 WAYS TO EARN POINTS:")
                    output.append("   • PS Activities")
                    output.append("   • TAC")
                    output.append("   • Hackathons / Technical Events")
                    output.append("   • Project Competitions")
                    output.append("   • Refer Reward points Breakdown for more details")
                else:
                    # Student is at or above average
                    output.append(f"\n🎉 EXCELLENT! You are {abs(points_difference):.0f} points ABOVE the average!")
                    output.append("   Keep up the great work! 🌟")
                    output.append("   Refer Reward points Breakdown for more details")
    
    # Add individual activity details from cached reward points data
    activity_details = get_activity_details(roll_no, reward_points_df)
    if activity_details:
        output.append(activity_details)
    
    # Add detailed points breakdown from studentwise data
    detailed_points = get_detailed_student_points(roll_no, studentwise_data)
    if detailed_points:
        output.append(detailed_points)
    
    # Add last updated info
    if details_info and 'last_updated' in details_info:
        output.append("\n" + "-" * 60)
        output.append("LAST UPDATE INFO")
        output.append("-" * 60)
        output.append(details_info['last_updated'])
    
    # Show cache info
    if data_cache["last_update"]:
        cache_age = datetime.now() - data_cache["last_update"]
        hours = cache_age.total_seconds() / 3600
        next_refresh_hours = 12 - hours
        output.append(f"\n📊 Data age: {hours:.1f} hours")
        if next_refresh_hours > 0:
            output.append(f"⏰ Next auto-refresh in: {next_refresh_hours:.1f} hours")
        else:
            output.append("⏰ Auto-refresh due now")
    
    output.append("\n" + "=" * 80)
    
    return "\n".join(output)

# Function to get system information
def get_system_info():
    combined_df, studentwise_data, details_info, reward_points_df = get_cached_data()
    
    if not details_info:
        return "❌ No system information available"
    
    output = []
    output.append("=" * 80)
    output.append("SYSTEM INFORMATION")
    output.append("=" * 80)

    # Average Points
    if 'average_points' in details_info:
        output.append("\nAVERAGE REWARD POINTS BY YEAR:")
        output.append("-" * 40)
        for year, points in details_info['average_points'].items():
            if points:
                output.append(f"Year {year:<10}: {points}")

    # Calculated Year-wise Average Points
    calculated_averages = calculate_yearwise_average_points()
    if calculated_averages and not calculated_averages.startswith("❌") and not calculated_averages.startswith("⚠️"):
        output.append(calculated_averages)
    
    # Redemption Dates
    if 'ip1_redemption' in details_info:
        output.append("\nIP 1 REDEMPTION DATES:")
        output.append("-" * 40)
        for semester, date in details_info['ip1_redemption'].items():
            if date and date != '-':
                output.append(f"{semester:<10}: {date}")
    
    if 'ip2_redemption' in details_info:
        output.append("\nIP 2 REDEMPTION DATES:")
        output.append("-" * 40)
        for semester, date in details_info['ip2_redemption'].items():
            if date and date != '-':
                output.append(f"{semester:<10}: {date}")
    
    if 'last_updated' in details_info:
        output.append(f"\nLAST UPDATED:")
        output.append("-" * 40)
        output.append(details_info['last_updated'])
    
    # Cache info
    if data_cache["last_update"]:
        cache_age = datetime.now() - data_cache["last_update"]
        hours = cache_age.total_seconds() / 3600
        next_refresh_hours = 12 - hours
        output.append(f"\n📊 Data age: {hours:.1f} hours")
        if next_refresh_hours > 0:
            output.append(f"⏰ Next auto-refresh in: {next_refresh_hours:.1f} hours")
        else:
            output.append("⏰ Auto-refresh due now")
    
    output.append("\n" + "=" * 80)
    
    return "\n".join(output)

# Admin UI Controls
def build_admin_section():
    """Build admin controls section"""
    with gr.Accordion("🔧 Admin Controls", open=False, visible=True) as admin_accordion:
        admin_key = gr.Textbox(
            label="Enter Admin Key", 
            type="password", 
            placeholder="Admin Only",
            value=""
        )
        load_button = gr.Button("🔁 Reload All Data", visible=False, variant="primary")
        admin_status = gr.Markdown("ℹ️ Enter admin key to access controls", visible=True)

        def verify_admin_key(key):
            """Verify admin key and show/hide controls"""
            if key.strip() == os.getenv("ADMIN_KEY", ""):
                return (
                    gr.update(visible=True),  # Show reload button
                    "✅ Access granted. You can reload data now."
                )
            elif key.strip() == "":
                return (
                    gr.update(visible=False),  # Hide reload button
                    "ℹ️ Enter admin key to access controls"
                )
            else:
                return (
                    gr.update(visible=False),  # Hide reload button
                    "❌ Invalid admin key."
                )

        def admin_reload():
            """Admin function to reload all data"""
            try:
                print("🔧 Admin reload triggered...")
                combined_df, studentwise_data, details_info, reward_points_df = load_all_data()
                
                timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
                return f"✅ Data reloaded successfully at {timestamp}\n📊 Total records: {len(combined_df) if not combined_df.empty else 0}"
            except Exception as e:
                return f"❌ Error reloading data: {str(e)}"

        # Event handlers
        admin_key.change(
            fn=verify_admin_key, 
            inputs=admin_key, 
            outputs=[load_button, admin_status]
        )
        
        load_button.click(
            fn=admin_reload, 
            outputs=admin_status
        )
    
    return admin_accordion, admin_key, load_button, admin_status

# Function to determine if admin mode is enabled via URL parameter
def check_admin_mode(request: gr.Request) -> bool:
    """Check if admin mode is enabled via URL parameter"""
    try:
        query_params = urllib.parse.parse_qs(str(request.url).split('?')[1] if '?' in str(request.url) else "")
        admin_param = query_params.get(os.getenv("ADMIN_MODE_URL"), [""])[0]
        admin_mode_key = os.getenv("ADMIN_MODE_KEY", "")
        
        is_admin = admin_param == admin_mode_key and admin_mode_key != ""
        if is_admin:
            print(f"🔧 Admin mode activated via URL parameter")
        return is_admin
    except Exception as e:
        print(f"⚠️ Error checking admin mode: {str(e)}")
        return False




# Create Gradio interface
with gr.Blocks(
    title="Student Reward Points Check", 
    theme=gr.themes.Soft(),
) as app:
    gr.Markdown("## 🎓 Student Reward Points Checker")
    gr.HTML(
        """
        <style>
        .info-banner {
            background: linear-gradient(90deg, #2c3e50, #4b6cb7);
            padding: 14px 18px;
            border-radius: 10px;
            color: #ffffff;
            font-size: 15px;
            font-weight: 600;
            text-align: center;
            box-shadow: 0 2px 10px rgba(0,0,0,0.25);
            margin-bottom: 14px;
        }
        
        .info-banner span {
            color: #ffd966;
            font-weight: 700;
        }
        </style>
        
        <div class="info-banner">
        ℹ️ <strong>IP 1 Redemption is Live for 2nd and 3rd Years. Check it using IP Tab</strong>
        </div>
        """
    )
    gr.Markdown("##### Search for Reward Points, Redemption Dates and Innovative Practice (IP) Details")
    gr.Markdown("##### எல்லா புகழும் இறைவனுக்கே ✝ 🕉 ☪")
    gr.Markdown("""
    ***Available Features*** :
    **🔍 Student Search Tab**,
    **📚 IP Details Tab**,
    **ℹ️ System Info Tab**
    """)
    gr.Markdown("💻 **Mode**: Use Desktop Mode in browser for Good UI and UX")
    gr.Markdown("🕒 **Auto-Updates**: Data automatically refreshes when there is a change in Reward Points Sheet")
    gr.Markdown("📝 **Issue/Feedback Form** : [Issue/Feedback Form](https://docs.google.com/forms/d/e/1FAIpQLScnl0udcN2pUDENHl45HIj5HZbvDuwZ0g2eepBbp8tJYg-NvQ/viewform)")    
    
    with gr.Tabs():
        with gr.TabItem("🔍 Student Search"):
            with gr.Row():
                with gr.Column(scale=3):
                    roll_input = gr.Textbox(
                        label="Enter Roll Number",
                        placeholder="e.g., 7376222AL181",
                        value=""
                    )
                with gr.Column(scale=1):
                    search_btn = gr.Button("🔍 Search Student", variant="primary")
            
            result_output = gr.Textbox(
                label="Student Details",
                lines=50,
                max_lines=60,
                show_copy_button=True,
                autoscroll=False
            )
        
        with gr.TabItem("📚 Innovative Practice (IP) Details"):
            with gr.Row():
                with gr.Column(scale=3):
                    subject_roll_input = gr.Textbox(
                        label="Enter Roll Number for Innovative Practice (IP) Details",
                        placeholder="e.g., 7376222AL181",
                        value=""
                    )
                with gr.Column(scale=1):
                    subject_search_btn = gr.Button("📚 Get Innovative Practice (IP) Details", variant="primary")

            subject_output = gr.Textbox(
                label="Innovative Practice (IP) Details",
                lines=50,
                max_lines=60,
                show_copy_button=True,
                autoscroll=False
            )
            
        with gr.TabItem("ℹ️ System Information"):
            with gr.Row():
                with gr.Column():
                    system_btn = gr.Button("📊 Get System Information", variant="secondary", size="lg")
            
            system_output = gr.Textbox(
                label="System Information",
                lines=50,
                max_lines=60,
                show_copy_button=True,
                autoscroll=False
            )

        with gr.TabItem("🔧 Admin Controls", visible=False) as admin_tab:  # Start hidden by default
            gr.Markdown("### 🔐 Administrative Functions")
            gr.Markdown("⚠️ **Access restricted to authorized personnel only**")
            
            with gr.Row():
                with gr.Column(scale=1):
                    admin_key = gr.Textbox(
                        label="Enter Admin Key", 
                        type="password", 
                        placeholder="Enter admin password",
                        value=""
                    )
                    
                with gr.Column(scale=1):
                    load_button = gr.Button("🔁 Reload All Data", visible=False, variant="primary", size="lg")
            
            admin_status = gr.Markdown("ℹ️ Enter admin key to access controls", visible=True)
            
            # Admin functions
            def verify_admin_key(key):
                """Verify admin key and show/hide controls"""
                if key.strip() == os.getenv("ADMIN_KEY", ""):
                    return (
                        gr.update(visible=True),  # Show reload button
                        "✅ **Access Granted!** You can now reload data."
                    )
                elif key.strip() == "":
                    return (
                        gr.update(visible=False),  # Hide reload button
                        "ℹ️ Enter admin key to access controls"
                    )
                else:
                    return (
                        gr.update(visible=False),  # Hide reload button
                        "❌ **Access Denied!** Invalid admin key."
                    )

            def admin_reload():
                """Admin function to reload all data"""
                try:
                    print("🔧 Admin reload triggered...")
                    combined_df, studentwise_data, details_info, reward_points_df = load_all_data()
                    
                    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
                    total_records = len(combined_df) if not combined_df.empty else 0
                    
                    return f"""✅ **Data Reload Successful!**
                    
                        📅 **Timestamp:** {timestamp}\n
                        📊 **Total Records:** {total_records:,}\n
                        🔄 **Status:** All data sources refreshed\n
                        ⏰ **Next Auto-refresh:** 12 hours from now\n
                        🎯 **Data Sources Updated:**\n
                        • Main spreadsheet ({len(sheet_configs)} sheets)\n
                        • Studentwise reward points data\n
                        • Activity breakdown data\n
                        • System information"""
                    
                except Exception as e:
                    return f"❌ **Error reloading data:** {str(e)}"

            # Event handlers for admin tab
            admin_key.change(
                fn=verify_admin_key, 
                inputs=admin_key, 
                outputs=[load_button, admin_status]
            )
            
            load_button.click(
                fn=admin_reload, 
                outputs=admin_status
            )
    
    
    # Event handlers - FIXED: Proper input/output mapping
    
    # 1. Student search handlers
    search_btn.click(
        fn=search_student, 
        inputs=roll_input,  # Changed from [roll_input] to roll_input
        outputs=result_output
    )
    
    roll_input.submit(
        fn=search_student, 
        inputs=roll_input,  # Changed from [roll_input] to roll_input
        outputs=result_output
    )
    
    # 2. IP Details handlers - FIXED: Proper input parameter
    subject_search_btn.click(
        fn=extract_subjects_and_marks_for_gradio, 
        inputs=subject_roll_input,  # Changed from [subject_roll_input] to subject_roll_input
        outputs=subject_output
    )
    
    subject_roll_input.submit(
        fn=extract_subjects_and_marks_for_gradio, 
        inputs=subject_roll_input,  # Changed from [subject_roll_input] to subject_roll_input
        outputs=subject_output
    )
    
    # 3. System info handler - Correct (no inputs needed)
    system_btn.click(
        fn=get_system_info, 
        inputs=[], 
        outputs=system_output
    )
    
    # Footer section
    gr.Markdown("---")
    with gr.Row():
        with gr.Column():
            gr.Markdown(
                """
                <div style="text-align: center; margin-top: 20px; padding: 20px; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); border-radius: 10px; color: white;">
                    <h3 style="margin: 0; color: white;">💻 Developed with ❤️ by</h3>
                    <a href="https://praneshjs.vercel.app" target="_blank" style="text-decoration: none;">
                        <h2 style="margin: 5px 0; color: #ffd700; cursor: pointer; transition: color 0.3s ease;">PRANESH S</h2>
                    </a>
                    <div style="margin: 15px 0;">
                        <a href="https://github.com/Pranesh-2005" target="_blank" style="color: #ffd700; text-decoration: none; margin: 0 10px; font-size: 16px;">
                            🐱 GitHub
                        </a>
                        <span style="color: #ffd700;">|</span>
                        <a href="https://www.linkedin.com/in/pranesh5264/" target="_blank" style="color: #ffd700; text-decoration: none; margin: 0 10px; font-size: 16px;">
                            💼 LinkedIn
                        </a>
                        <span style="color: #ffd700;">|</span>
                        <a href="https://mail.google.com/mail/?view=cm&fs=1&to=praneshmadhan646@gmail.com&su=Student%20Reward%20Points%20App%20-%20Feedback&body=Hi%20Pranesh,%0A%0AI%20am%20writing%20regarding%20the%20Student%20Reward%20Points%20application.%0A%0A" target="_blank" style="color: #ffd700; text-decoration: none; margin: 0 10px; font-size: 16px;">
                            📧 Contact Developer
                        </a>
                    </div>
                    <p style="margin: 10px 0; font-style: italic; color: #e0e0e0;">Made with 💝 Love and Support</p>
                    <p style="margin: 5px 0; font-size: 14px; color: #b0b0b0;">🚀 Empowering students with instant reward points tracking</p>
                </div>
                """,
                elem_id="footer"
            )

    def setup_admin_mode(request: gr.Request):
        """Setup admin mode based on URL parameters"""
        try:
            is_admin = check_admin_mode(request)
            if is_admin:
                print("🔧 Admin tab will be visible")
                return gr.update(visible=True)  # Show admin tab
            else:
                return gr.update(visible=False)  # Hide admin tab
        except Exception as e:
            print(f"⚠️ Error in setup_admin_mode: {str(e)}")
            return gr.update(visible=False)  # Hide admin tab on error



    # System info initialization function - Fixed to handle errors gracefully
    def initialize_system_info():
        """Initialize system information display with error handling"""
        try:
            return get_system_info()
        except Exception as e:
            error_msg = f"⚠️ Error initializing system info: {str(e)}"
            print(error_msg)
            return "⚠️ System information will be available after data loads completely. Please click 'Get System Information' button to retry."
    
    app.load(
        fn=setup_admin_mode,
        outputs=admin_tab
    )
    
    # Load system info on startup
    app.load(
        fn=initialize_system_info,
        inputs=[],
        outputs=system_output
    )

# Launch the app
if __name__ == "__main__":
    print("🚀 Launching Gradio interface...")
    app.launch(share=False, debug=True, server_name="0.0.0.0", server_port=7860, pwa=True)