#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SEED_DIR="$ROOT/RealLifeLingo/ios/Resources/Seed"
mkdir -p "$SEED_DIR"

cp "$(dirname "$0")/sample_my_clippings.txt" "$SEED_DIR/MyClippings.txt"
cp "$(dirname "$0")/sample_transcript.json" "$SEED_DIR/LessonTranscript.json"
cp "$(dirname "$0")/sample_subtitles.srt" "$SEED_DIR/SampleSubtitles.srt"

export SEED_DIR
python3 <<'PY'
import json
import math
import os
import random
import uuid
from datetime import datetime, timedelta
from pathlib import Path

seed_dir = Path(os.environ["SEED_DIR"])
random.seed(42)
now = datetime.utcnow().replace(microsecond=0)
next_bill = now + timedelta(days=30)
week_start = (now - timedelta(days=now.weekday())).replace(hour=0, minute=0, second=0, microsecond=0)
user_id = "seed-user"
org_id = "seed-org"

sources = [
    {
        "sourceId": "seed-source-transcript",
        "userId": user_id,
        "orgId": org_id,
        "type": "transcript",
        "uri": "recording://seed",
        "language": "es",
        "metaJSON": json.dumps({"title": "Lesson", "duration": 120}),
        "firstSeenAt": now.isoformat() + "Z",
        "lastIngestedAt": now.isoformat() + "Z",
    },
    {
        "sourceId": "seed-source-kindle",
        "userId": user_id,
        "orgId": org_id,
        "type": "kindle",
        "uri": "kindle://seed",
        "language": "es",
        "metaJSON": json.dumps({"highlights": 12}),
        "firstSeenAt": now.isoformat() + "Z",
        "lastIngestedAt": now.isoformat() + "Z",
    },
    {
        "sourceId": "seed-source-subtitle",
        "userId": user_id,
        "orgId": org_id,
        "type": "subtitle",
        "uri": "subtitle://seed",
        "language": "es",
        "metaJSON": json.dumps({"lines": 40}),
        "firstSeenAt": now.isoformat() + "Z",
        "lastIngestedAt": now.isoformat() + "Z",
    },
]

transcript_segments = [
    {"speaker": "Teacher", "text": "Bienvenidos a la clase de hoy.", "start": 0.0, "end": 3.2, "isStarred": True},
    {"speaker": "You", "text": "Estoy listo para aprender vocabulario práctico.", "start": 3.2, "end": 7.8, "isStarred": False},
    {"speaker": "Teacher", "text": "Recuerda tomar nota de las frases importantes.", "start": 7.8, "end": 12.0, "isStarred": True},
]

transcripts = [
    {
        "transcriptId": "seed-transcript",
        "sourceId": "seed-source-transcript",
        "durationSec": 120.0,
        "segments": transcript_segments,
    }
]

terms = [
    ("gracias", "thank you"),
    ("de nada", "you're welcome"),
    ("hasta luego", "see you later"),
    ("¿cómo estás?", "how are you?"),
    ("muy bien", "very well"),
    ("me llamo", "my name is"),
    ("¿dónde está el baño?", "where is the bathroom?"),
    ("la cuenta", "the bill"),
    ("buen provecho", "enjoy your meal"),
    ("encantado", "pleased to meet you"),
    ("necesito ayuda", "i need help"),
    ("una mesa para dos", "a table for two"),
    ("la estación", "the station"),
    ("el billete", "the ticket"),
    ("pagar en efectivo", "pay in cash"),
    ("tarjeta de crédito", "credit card"),
    ("la maleta", "the suitcase"),
    ("hacer una reserva", "make a reservation"),
    ("caminar", "to walk"),
    ("seguir derecho", "go straight"),
    ("girar a la izquierda", "turn left"),
    ("girar a la derecha", "turn right"),
    ("disculpe", "excuse me"),
    ("permiso", "pardon me"),
    ("adelante", "come in"),
    ("la taquilla", "the ticket booth"),
    ("próxima parada", "next stop"),
    ("bajar", "to get off"),
    ("subir", "to get on"),
    ("el horario", "the schedule"),
]

placeholder_images = [f"https://picsum.photos/seed/seed{idx}/400/400" for idx in range(1, 11)]

cards = []
for idx, (term, gloss) in enumerate(terms, start=1):
    source = sources[(idx - 1) % len(sources)]
    due = now.isoformat() + "Z" if idx <= 10 else None
    strength = 1.0 if idx <= 10 else 0.0
    card = {
        "cardId": f"seed-card-{idx:02d}",
        "userId": user_id,
        "sourceType": source["type"],
        "sourceId": source["sourceId"],
        "sourceLoc": f"{(idx - 1) * 5}",
        "l1Text": gloss,
        "l2Text": term,
        "gloss": gloss,
        "pos": "phrase" if " " in term else "noun",
        "cefr": random.choice(["A2", "B1", "B2"]),
        "imageURL": placeholder_images[idx % len(placeholder_images)],
        "audioURL": None,
        "exampleL2": f"{term.capitalize()} es útil en la vida diaria.",
        "exampleL1": f"{gloss.capitalize()} in everyday life.",
        "tags": [source["type"], "seed", "demo"] + (["starred"] if idx % 7 == 0 else []),
        "createdAt": now.isoformat() + "Z",
        "strength": strength,
        "ease": 2.5,
        "nextDueAt": due,
    }
    cards.append(card)

reviews = []
for idx, card in enumerate(cards[:10], start=1):
    reviews.append({
        "reviewId": f"seed-review-{idx:02d}",
        "cardId": card["cardId"],
        "userId": user_id,
        "dueAt": (now - timedelta(hours=2)).isoformat() + "Z",
        "shownAt": (now - timedelta(hours=1)).isoformat() + "Z",
        "grade": random.randint(3, 5),
        "ease": 2.5,
        "intervalDays": 1.0,
        "nextDueAt": card["nextDueAt"],
        "device": "seed",
    })

usage_events = [
    {
        "eventId": str(uuid.uuid4()),
        "userId": user_id,
        "orgId": org_id,
        "type": "transcribe",
        "createdAt": now.isoformat() + "Z",
        "payloadJSON": json.dumps({"duration": 60}),
    },
    {
        "eventId": str(uuid.uuid4()),
        "userId": user_id,
        "orgId": org_id,
        "type": "ai_generate",
        "createdAt": (now + timedelta(minutes=5)).isoformat() + "Z",
        "payloadJSON": json.dumps({"cards": len(cards)}),
    },
]

weekly_usage = [
    {
        "orgId": None,
        "userId": user_id,
        "weekStart": week_start.isoformat() + "Z",
        "transcripts": 1,
        "cardsReviewed": len(reviews),
        "newCards": len(cards),
        "activeMinutes": len(cards) * 3,
        "lastActivityAt": (now + timedelta(minutes=5)).isoformat() + "Z",
    },
    {
        "orgId": org_id,
        "userId": user_id,
        "weekStart": week_start.isoformat() + "Z",
        "transcripts": 1,
        "cardsReviewed": len(reviews),
        "newCards": len(cards),
        "activeMinutes": len(cards) * 3,
        "lastActivityAt": (now + timedelta(minutes=5)).isoformat() + "Z",
    },
]

payload = {
    "users": [
        {
            "userId": user_id,
            "email": "learner@example.com",
            "displayName": "Demo Learner",
            "planTier": "active",
            "lastUsageAt": (now + timedelta(minutes=5)).isoformat() + "Z",
            "nextBillDate": next_bill.isoformat() + "Z",
            "lastBilledAt": now.isoformat() + "Z",
            "orgIds": [org_id],
            "lastStateChangeAt": now.isoformat() + "Z",
            "cloudAIEnabled": True,
            "autoReactivate": True,
            "goalDailyNew": 20,
            "hobbies": "Travel, food",
            "l1": "en",
            "l2": "es",
            "proficiency": "B1",
            "timePerDay": "30",
            "voicePreference": "Neutral",
            "nsfwFilter": True,
        }
    ],
    "orgs": [
        {
            "orgId": org_id,
            "name": "RealLife Academy",
            "billingEmail": "billing@reallifelingo.app",
            "createdAt": now.isoformat() + "Z",
        }
    ],
    "memberships": [
        {
            "orgId": org_id,
            "userId": user_id,
            "role": "admin",
        }
    ],
    "sources": sources,
    "transcripts": transcripts,
    "cards": cards,
    "reviews": reviews,
    "usageEvents": usage_events,
    "weeklyUsage": weekly_usage,
}

(seed_dir / "seed_state.json").write_text(json.dumps(payload, indent=2))
PY

echo "Seed data generated in $SEED_DIR"
echo "Import the fixtures via the Import sheet and start reviewing the prebuilt deck."
