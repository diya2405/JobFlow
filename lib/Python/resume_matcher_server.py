from flask import Flask, request, jsonify
import firebase_admin
from firebase_admin import credentials, firestore, storage
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.metrics.pairwise import cosine_similarity
from pdfminer.high_level import extract_text
import requests
import os

app = Flask(__name__)

# Initialize Firebase (MUST happen once, outside any route)
cred = credentials.Certificate(r'C:\Users\DIYA SHAH\Downloads\fir-bemo-281db-firebase-adminsdk-wzajm-de9ee5c599.json')
firebase_admin.initialize_app(cred, {
    'storageBucket': 'fir-bemo-281db.appspot.com'
})

# Initialize Firestore and Storage
db = firestore.client()
bucket = storage.bucket()

def fetch_candidates():
    candidates_ref = db.collection('User_Data')
    candidates = candidates_ref.stream()
    return [{**candidate.to_dict(), 'id': candidate.id} for candidate in candidates]

def fetch_job_details(job_id):
    job_ref = db.collection('Job_Posts').document(job_id)
    job = job_ref.get()
    if job.exists:
        return job.to_dict()
    else:
        print(f"Job with ID {job_id} not found.")
        return None

def download_pdf(url, filename):
    try:
        response = requests.get(url)
        response.raise_for_status()
        with open(filename, 'wb') as f:
            f.write(response.content)
    except requests.exceptions.RequestException as e:
        print(f"Error downloading the PDF from {url}: {e}")
        return False
    return True

def extract_text_from_pdf(filename):
    try:
        text = extract_text(filename)
        return text
    except Exception as e:
        print(f"Error extracting text: {e}")
        return ""

def calculate_similarity(requirements, resume):
    vectorizer = TfidfVectorizer(stop_words='english')
    tfidf_matrix = vectorizer.fit_transform([requirements, resume])
    similarity = cosine_similarity(tfidf_matrix[0:1], tfidf_matrix[1:2])
    return round(float(similarity[0][0] * 100), 2)

def update_match_scores_for_all_jobs():
    job_posts_ref = db.collection('Job_Posts')
    job_posts = job_posts_ref.stream()

    candidates = fetch_candidates()

    for job in job_posts:
        job_data = job.to_dict()
        job_id = job.id
        job_requirements = job_data.get('requirements', '')

        if not job_requirements:
            print(f"Job requirements for job {job_id} are empty.")
            continue

        print(f"Processing job: {job_id} with requirements: {job_requirements[:50]}...")

        for candidate in candidates:
            resume_url = candidate.get('Resume', '')
            if not resume_url:
                print(f"Skipping {candidate.get('Name', 'Unknown')} — No Resume URL.")
                continue

            local_pdf = f"temp_{candidate['id']}.pdf"
            try:
                if not download_pdf(resume_url, local_pdf):
                    continue

                resume_text = extract_text_from_pdf(local_pdf)

                if not resume_text.strip():
                    print(f"Skipping {candidate.get('Name', 'Unknown')} — Empty resume after extraction.")
                    continue

                match_score = calculate_similarity(job_requirements, resume_text)
                print(f"Updating {candidate.get('Name', 'Unknown')} for job {job_id} with MatchScore: {match_score}%")

                job_match_ref = db.collection('User_Data').document(candidate['id']).collection('JobMatches').document(job_id)
                job_match_ref.set({
                    'MatchScore': match_score,
                    'JobId': job_id,
                    'JobRequirements': job_requirements,
                    'JobTitle': job_data.get('title', 'N/A')
                })

            finally:
                if os.path.exists(local_pdf):
                    os.remove(local_pdf)

# ✅ Define a route properly
@app.route('/', methods=['POST', 'GET'])
def resume_matcher():

    try:
        update_match_scores_for_all_jobs()
        return jsonify({'message': 'Resume matcher executed successfully'}), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500

# ✅ Start the app properly
if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
