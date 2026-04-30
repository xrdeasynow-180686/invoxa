"""Generate 6 Play Store marketing screenshots for InovXA via Gemini Nano Banana."""
import asyncio
import base64
import os
import sys
from pathlib import Path

from dotenv import load_dotenv
from emergentintegrations.llm.chat import LlmChat, UserMessage

load_dotenv("/app/backend/.env")

OUT_DIR = Path("/app/inovxa_marketing")
OUT_DIR.mkdir(exist_ok=True)

MODEL = "gemini-3.1-flash-image-preview"
API_KEY = os.getenv("EMERGENT_LLM_KEY")

BASE_DESIGN = (
    "High-quality Google Play Store marketing screenshot for the InovXA "
    "invoice maker mobile app. Portrait 9:16 phone screenshot composition. "
    "Modern clean indigo to royal blue diagonal gradient background. Bold "
    "white sans-serif headline text near the top. A floating tilted iPhone "
    "mock-up in the center showing the InovXA Android UI. Soft drop shadows. "
    "Subtle decorative blue circles/dots. Minimalist, premium, professional, "
    "no realistic faces, no extra logos, no spelling mistakes. Background "
    "must be solid gradient (no clutter). Headline in single line if possible."
)

SCREENS = [
    (
        "01_create_invoices.png",
        f"{BASE_DESIGN} Headline: 'Create Invoices in Seconds'. The phone "
        "shows a clean form with fields: Business name, Address, Client name, "
        "Items list with quantities and prices, a big indigo 'Generate "
        "Invoice' button. Fields are filled with sample data.",
    ),
    (
        "02_professional_pdf.png",
        f"{BASE_DESIGN} Headline: 'Professional PDF Invoices'. The phone "
        "shows a generated A4 invoice PDF preview with: a small dark logo "
        "top-left, business name in bold, contact icons (pin, phone, email), "
        "big bold 'INVOICE' on the right, a navy 'BILL TO' banner, an "
        "items table with blue header row, and a highlighted total box. "
        "Looks like a real business invoice.",
    ),
    (
        "03_save_manage.png",
        f"{BASE_DESIGN} Headline: 'Save & Manage All Invoices'. The phone "
        "shows a scrollable invoice history list. Each row has a small "
        "indigo receipt icon, client name in bold, invoice number and date "
        "underneath, dollar amount on the right (e.g. $1,250.00). About 5 "
        "rows visible. A floating round indigo '+' button in the bottom "
        "right labelled 'New invoice'.",
    ),
    (
        "04_business_details.png",
        f"{BASE_DESIGN} Headline: 'Add Your Business Details Once'. The "
        "phone shows a form with sections: Business name, Multi-line "
        "address (2 lines visible), Phone, Email, Business / Tax Number. "
        "A circular logo placeholder with a small pencil-edit badge sits "
        "at the top of the screen. Subtle blue check-mark indicating data "
        "saved.",
    ),
    (
        "05_fast_offline.png",
        f"{BASE_DESIGN} Headline: 'Fast - Simple - Offline Ready'. The "
        "phone shows three large feature tiles or icons stacked vertically: "
        "a lightning bolt with the text '< 30 seconds', a cloud-with-slash "
        "icon labelled '100% Offline', and a phone-with-PDF icon labelled "
        "'No account needed'. Below them, a small 'Made for small "
        "business' badge.",
    ),
    (
        "06_share_anywhere.png",
        f"{BASE_DESIGN} Headline: 'Share Anywhere in One Tap'. The phone "
        "shows a system share-sheet style overlay listing app icons: "
        "WhatsApp, Gmail, Google Drive, Outlook, Bluetooth, Print. Behind "
        "the share sheet is a faint preview of the generated invoice PDF. "
        "A bold caption near the top says 'WhatsApp - Email - Drive - "
        "Print'.",
    ),
]


async def gen_one(idx: int, filename: str, prompt: str) -> None:
    print(f"[{idx}/6] {filename} - generating...")
    chat = LlmChat(
        api_key=API_KEY,
        session_id=f"inovxa-shot-{idx}",
        system_message="You are a professional mobile app marketing designer.",
    )
    chat.with_model("gemini", MODEL).with_params(modalities=["image", "text"])
    msg = UserMessage(text=prompt)
    _text, images = await chat.send_message_multimodal_response(msg)
    if not images:
        print(f"   no images returned for {filename}")
        return
    img = images[0]
    out = OUT_DIR / filename
    out.write_bytes(base64.b64decode(img["data"]))
    print(f"   saved {out} ({out.stat().st_size // 1024} KB)")


async def main():
    if not API_KEY:
        print("EMERGENT_LLM_KEY missing", file=sys.stderr)
        sys.exit(1)
    for i, (name, prompt) in enumerate(SCREENS, start=1):
        await gen_one(i, name, prompt)
    print("\nAll done. Files in:", OUT_DIR)


if __name__ == "__main__":
    asyncio.run(main())
