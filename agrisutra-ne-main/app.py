import os
import streamlit as st
import importlib
import fpe_engine
import input_enricher
import output_enricher
import delivery
importlib.reload(fpe_engine)
from fpe_engine import FPEEngine

# ── AI client: prefer Vertex AI (ADC) → fall back to Gemini API key ──
def _get_ai_model():
    """
    Returns a callable generate(prompt) -> str.
    Priority:
      1. Vertex AI + ADC  (if GCP_PROJECT_ID is set in secrets / env)
      2. Gemini API key   (if GEMINI_API_KEY is set in secrets / env)
    """
    def _secret(key, default=None):
        """Read from st.secrets first, then os.environ. Never crash."""
        try:
            val = st.secrets.get(key)
            if val:
                return val
        except Exception:
            pass
        return os.environ.get(key, default)

    project_id = _secret("GCP_PROJECT_ID") or _secret("GOOGLE_CLOUD_PROJECT")

    if project_id:
        # ── Vertex AI path (uses ADC automatically) ──
        try:
            import vertexai
            from vertexai.generative_models import GenerativeModel as VertexModel
            location = _secret("GCP_LOCATION", "us-central1")
            vertexai.init(project=project_id, location=location)
            model = VertexModel("gemini-1.5-pro")

            def generate(prompt):
                response = model.generate_content(prompt)
                return response.text

            return generate, "Vertex AI (ADC)"
        except Exception as e:
            return None, f"Vertex AI init failed: {e}"

    # ── Fallback: Gemini API key ──
    api_key = _secret("GEMINI_API_KEY")
    if api_key:
        import google.generativeai as genai
        genai.configure(api_key=api_key)
        model = genai.GenerativeModel("gemini-pro")

        def generate(prompt):
            response = model.generate_content(prompt)
            return response.text

        return generate, "Gemini API Key"

    return None, "no_credentials"


def get_explainable_summary_table(crop, yield_target, urea, ssp, mop, is_organic=False, fym=None, vc=None, psnc=None, weather_context=None):
    generate_fn, auth_mode = _get_ai_model()

    if generate_fn is None:
        if auth_mode == "no_credentials":
            return (
                "⚠️ **AI summary unavailable.**\n\n"
                "Set one of the following in `.streamlit/secrets.toml`:\n"
                "- `GCP_PROJECT_ID = \"your-project\"` — uses ADC (recommended locally)\n"
                "- `GEMINI_API_KEY = \"AIza...\"` — uses direct API key"
            )
        return f"⚠️ Could not initialise AI model: {auth_mode}"

    prompt = f"""
    We are recommending fertilizers for {crop} with a target yield of {yield_target} q/ha.
    The recommended amounts are: {urea} kg Urea, {ssp} kg SSP, and {mop} kg MOP (total for the farm).
    """
    if weather_context:
        prompt += (f"\nLocal weather context: The average monthly rainfall is "
                   f"{weather_context.get('avg_monthly_rainfall_mm')} mm. "
                   f"Please briefly mention how this affects application timing and nutrient uptake.\n")
    if is_organic:
        prompt += f"""
        The user has also chosen the organic pathway. Organic nitrogen alternatives per ha:
        - FYM: {fym} t/ha
        - Vermicompost: {vc} t/ha
        - Enriched Compost (PSNC): {psnc} t/ha
        Discuss the benefits of organic approach, slow nutrient release, and hybrid (organic+inorganic) strategy.
        """
    prompt += """
    Provide a detailed, explainable, technical summary.
    Include a clear markdown table breaking down the recommendations and the agronomic reasoning.
    Format the response in clean markdown.
    """
    try:
        return generate_fn(prompt)
    except Exception as e:
        return f"Could not generate summary: {e}"

# ─────────────────────────────────────────────────────────────────────────────
# PAGE CONFIG
# ─────────────────────────────────────────────────────────────────────────────
st.set_page_config(page_title="AgriSutra NE | FPE Advisor", layout="wide", initial_sidebar_state="collapsed")

# ─────────────────────────────────────────────────────────────────────────────
# CSS — PREMIUM PRESENTATION THEME (HDMI-ready)
# ─────────────────────────────────────────────────────────────────────────────
st.markdown("""
<style>
@import url('https://fonts.googleapis.com/css2?family=Inter:wght@300;400;600;700;800;900&display=swap');

@keyframes fadeInUp  { from { opacity:0; transform:translateY(24px); } to { opacity:1; transform:translateY(0); } }
@keyframes fadeIn    { from { opacity:0; } to { opacity:1; } }
@keyframes pulse2    { 0%,100%{opacity:1;} 50%{opacity:0.45;} }
@keyframes shimmer   { 0%{background-position:-200% center;} 100%{background-position:200% center;} }
@keyframes glow      { 0%,100%{box-shadow:0 0 8px rgba(105,240,174,.3);} 50%{box-shadow:0 0 24px rgba(105,240,174,.7);} }

html, body, [class*="css"] { font-family:'Inter',sans-serif !important; }
.stApp { background: radial-gradient(ellipse at top, #0d1f0d 0%, #080e08 100%) !important; color:#e8f5e9 !important; }
#MainMenu, footer, .stDeployButton, header[data-testid="stHeader"] { display:none !important; }
.block-container { padding: 1rem 2rem !important; max-width: 100% !important; }

/* ── Header ── */
.app-header {
    background: linear-gradient(135deg,#1b5e20 0%,#2e7d32 60%,#1b5e20 100%);
    padding: 2rem 3rem 1.5rem 3rem;
    border-bottom: 2px solid #2e7d32;
    animation: fadeIn 0.7s ease;
    display: flex; align-items: center; gap: 1.5rem;
}
.app-header-text h1 {
    font-size: 2.6rem; font-weight: 900; margin: 0;
    background: linear-gradient(90deg,#69f0ae,#b9f6ca,#69f0ae);
    background-size: 200% auto;
    -webkit-background-clip: text; -webkit-text-fill-color: transparent;
    animation: shimmer 4s linear infinite;
}
.app-header-text p { color:#a5d6a7; font-size:1rem; margin:0.3rem 0 0 0; font-weight:500; }
.icar-badge {
    background:rgba(0,0,0,.25); border:1px solid rgba(105,240,174,.3);
    border-radius:12px; padding:0.5rem 1rem;
    font-size:0.8rem; color:#81c784; font-weight:700; letter-spacing:1.5px;
    white-space:nowrap;
}

/* ── Step Bar ── */
.step-bar {
    display:flex; background:#0a120a;
    border-bottom:2px solid #1a2d1a;
    animation: fadeIn 0.5s ease;
}
.step-chip {
    flex:1; padding:1rem 0.5rem; text-align:center;
    font-size:0.95rem; font-weight:700; letter-spacing:0.3px;
    color:#3a5238; border-bottom:3px solid transparent;
    transition:all 0.35s cubic-bezier(.4,0,.2,1);
    cursor:default;
}
.step-chip.active {
    color:#69f0ae; border-bottom-color:#69f0ae;
    background:linear-gradient(180deg,transparent,rgba(105,240,174,.07));
    animation: glow 2s ease-in-out infinite;
}
.step-chip.done { color:#43a047; border-bottom-color:#2e7d32; }

/* ── Panel ── */
.panel {
    background:linear-gradient(145deg,#121c12,#0e160e);
    border:1px solid #1e2d1e; border-radius:18px;
    padding:2.5rem; margin:1.5rem 2rem;
    animation:fadeInUp 0.5s ease;
    box-shadow:0 4px 24px rgba(0,0,0,.4);
}
.panel h3 { color:#69f0ae; margin-top:0; font-size:1.4rem; font-weight:800; }
.panel h4 { color:#a5d6a7; margin-top:0; }

/* ── Nutrient Cards ── */
.nutrient-card {
    background:linear-gradient(160deg,#111911,#0c140c);
    border:2px solid #1e2d1e; border-radius:18px;
    padding:2rem 1.5rem; text-align:center;
    transition:all 0.3s cubic-bezier(.4,0,.2,1);
    animation:fadeInUp 0.5s ease;
    cursor:pointer;
}
.nutrient-card:hover {
    border-color:#388e3c; transform:translateY(-6px);
    box-shadow:0 12px 36px rgba(46,125,50,.35);
    background:linear-gradient(160deg,#142014,#0e180e);
}
.nutrient-card.done-card {
    border-color:#43a047; background:linear-gradient(160deg,#0d1f0d,#091509);
    box-shadow:0 4px 20px rgba(67,160,71,.25);
}
.nutrient-card .nut-icon { font-size:3.5rem; margin-bottom:0.6rem; }
.nutrient-card .nut-name { font-size:1.15rem; font-weight:800; color:#cfd8dc; letter-spacing:.5px; }
.nutrient-card .nut-val  { font-size:2.5rem; font-weight:900; color:#69f0ae; margin-top:0.5rem; letter-spacing:-1px; }
.nutrient-card .nut-unit { font-size:0.85rem; color:#546e4a; margin-top:-0.2rem; }
.nutrient-card .nut-pend { font-size:0.9rem; color:#2e4d2e; margin-top:0.5rem; animation:pulse2 2.5s infinite; }

/* ── Result Box ── */
.result-box {
    background:linear-gradient(135deg,#091509,#0d1f0d);
    border:2px solid #2e7d32; border-radius:16px;
    padding:2rem 2.5rem; margin-top:1.5rem;
    animation:fadeInUp 0.4s ease;
    box-shadow:0 0 30px rgba(46,125,50,.2);
}
.result-box .big-val {
    font-size:3.5rem; font-weight:900; color:#69f0ae;
    letter-spacing:-2px; line-height:1;
}
.result-box .eq-text {
    font-size:0.82rem; color:#546e4a;
    font-family:'Courier New',monospace; margin-top:0.8rem;
    background:#081008; padding:0.5rem 0.8rem; border-radius:6px;
    display:inline-block;
}

/* ── Summary Cards ── */
.summary-card {
    background:linear-gradient(160deg,#111911,#0c170c);
    border:2px solid #2e7d32; border-radius:18px;
    padding:2rem 1rem; text-align:center;
    animation:fadeInUp 0.5s ease;
    transition:all 0.3s ease;
    box-shadow:0 4px 20px rgba(46,125,50,.15);
}
.summary-card:hover { box-shadow:0 8px 30px rgba(46,125,50,.35); transform:translateY(-4px); }
.summary-card .s-icon  { font-size:3rem; margin-bottom:0.5rem; }
.summary-card .s-label { color:#78909c; font-size:0.85rem; font-weight:700; letter-spacing:1.5px; text-transform:uppercase; }
.summary-card .s-val   { font-size:3.2rem; font-weight:900; color:#69f0ae; letter-spacing:-2px; margin:0.3rem 0; line-height:1; }
.summary-card .s-unit  { font-size:0.8rem; color:#546e4a; margin-top:-0.2rem; }
.summary-card .s-conv  { font-size:0.95rem; color:#a5d6a7; margin-top:0.8rem; font-weight:600; }
.summary-card.p-card   { border-color:#1565c0; }
.summary-card.p-card .s-val { color:#81d4fa; }
.summary-card.k-card   { border-color:#e65100; }
.summary-card.k-card .s-val { color:#ffcc80; }

/* ── Schedule Cards ── */
.sched-card {
    background:#0d160d; border:1px solid #1a2e1a;
    border-radius:14px; padding:1.5rem;
    text-align:center; animation:fadeInUp 0.5s ease;
}
.sched-card .sched-time { font-size:0.78rem; color:#546e4a; font-weight:700; letter-spacing:1px; text-transform:uppercase; }
.sched-card .sched-dose { font-size:1rem; color:#cfd8dc; margin-top:0.5rem; font-weight:600; line-height:1.5; }

/* ── Divider ── */
.divider { border-top:1px solid #1a2d1a; margin:1.5rem 0; }

/* ── Buttons ── */
.stButton > button {
    border-radius:12px !important; font-weight:700 !important;
    font-size:1rem !important; padding:0.75rem 1.5rem !important;
    transition:all 0.25s cubic-bezier(.4,0,.2,1) !important;
    letter-spacing:0.3px !important;
}
.stButton > button[kind="primary"] {
    background:linear-gradient(135deg,#2e7d32,#43a047) !important;
    border:none !important; color:#fff !important;
}
.stButton > button[kind="primary"]:hover {
    transform:translateY(-3px) !important;
    box-shadow:0 8px 24px rgba(46,125,50,.5) !important;
}
</style>
""", unsafe_allow_html=True)

# ─────────────────────────────────────────────────────────────────────────────
# SESSION STATE INIT
# ─────────────────────────────────────────────────────────────────────────────
DEFAULTS = {
    "step": 1,          # 1=setup, 2=hub, 3=nutrient_page, 4=summary
    "crop": None,
    "target_yield": None,
    "active_nutrient": None,   # "N", "P", or "K"

    "N_done": False, "P_done": False, "K_done": False,
    "FN": None,      "FP": None,      "FK": None,
    "N_urea": None,  "P_ssp": None,   "K_mop": None,
    "N_eq": "",      "P_eq": "",      "K_eq": "",
    
    # New additions
    "lat": 25.9, "lon": 94.3,
    "land_area": 1.0, "area_unit": "Hectares",
    "weather_context": None,
    "saved_history": False,
}
for k, v in DEFAULTS.items():
    if k not in st.session_state:
        st.session_state[k] = v

# ─────────────────────────────────────────────────────────────────────────────
# HELPERS
# ─────────────────────────────────────────────────────────────────────────────
def go(step, **kwargs):
    st.session_state.step = step
    for k, v in kwargs.items():
        st.session_state[k] = v
    st.rerun()

def all_done():
    return st.session_state.N_done and st.session_state.P_done and st.session_state.K_done

NUTRIENT_META = {
    "N":  {"icon": "🌿", "label": "Nitrogen",    "unit": "FN",   "fert": "Urea",  "conv_label": "Urea",  "color": "#69f0ae"},
    "P":  {"icon": "🌱", "label": "Phosphorus",  "unit": "FP₂O₅","fert": "SSP",   "conv_label": "SSP",   "color": "#81d4fa"},
    "K":  {"icon": "🌾", "label": "Potassium",   "unit": "FK₂O", "fert": "MOP",   "conv_label": "MOP",   "color": "#ffcc80"},
}

# ─────────────────────────────────────────────────────────────────────────────
# SHARED HEADER
# ─────────────────────────────────────────────────────────────────────────────
def render_header():
    import base64, pathlib
    logo_path = pathlib.Path(__file__).parent / "icar_logo.png"
    if logo_path.exists():
        b64 = base64.b64encode(logo_path.read_bytes()).decode()
        logo_html = f'<img src="data:image/png;base64,{b64}" style="height:50px;border-radius:8px;" alt="ICAR">'
    else:
        logo_html = '<div class="icar-badge">ICAR</div>'
    st.markdown(f"""
    <div class="app-header">
        <div class="app-header-text">
            <h1>🌾 AgriSutra NE</h1>
            <p>AI-Powered Fertilizer Prescription Engine &nbsp;|&nbsp; STCR/FPE Methodology &nbsp;|&nbsp; Kiphire, Nagaland</p>
        </div>
        <div style="margin-left:auto;display:flex;align-items:center;gap:10px;">
            {logo_html}
            <div class="icar-badge">ICAR</div>
        </div>
    </div>
    """, unsafe_allow_html=True)

# ─────────────────────────────────────────────────────────────────────────────
# STEP INDICATOR
# ─────────────────────────────────────────────────────────────────────────────
def render_step_bar():
    steps = ["① Crop & Yield", "② Nutrient Hub", "③ Summary"]
    step_map = {1:1, 2:2, 4:3}  # internal step -> display index
    cur_display = step_map.get(st.session_state.step, 2)
    chips = ""
    for i, label in enumerate(steps, start=1):
        cls = "active" if i == cur_display else ("done" if i < cur_display else "")
        chips += f'<div class="step-chip {cls}">{label}</div>'
    st.markdown(f'<div class="step-bar">{chips}</div>', unsafe_allow_html=True)

# ─────────────────────────────────────────────────────────────────────────────
# STEP 1 — CROP & TARGET YIELD
# ─────────────────────────────────────────────────────────────────────────────
def step1_setup():
    st.markdown('<div class="panel">', unsafe_allow_html=True)
    st.markdown("### 📋 Step 1 — Select Crop & Target Yield")
    st.markdown("These values will be used in all three nutrient equations.")
    st.markdown('<div class="divider"></div>', unsafe_allow_html=True)

    col1, col2 = st.columns(2)
    with col1:
        crop = st.selectbox("🌽 Crop", ["Maize (Local)", "Maize (Hybrid)", "Kholar"], key="sel_crop")
    with col2:
        default_t = 40.0 if "Maize" in crop else 10.0
        T = st.number_input("🎯 Target Yield (q/ha)", min_value=1.0, max_value=100.0, value=default_t, step=1.0, key="sel_yield")

    st.markdown('<div class="divider"></div>', unsafe_allow_html=True)
    st.markdown("### 🌍 Farm Details")
    c_lat, c_lon, c_area = st.columns(3)
    with c_lat:
        lat = st.number_input("Latitude", value=25.9, step=0.01, help="Kiphire approx: 25.9")
    with c_lon:
        lon = st.number_input("Longitude", value=94.3, step=0.01, help="Kiphire approx: 94.3")
    with c_area:
        area = st.number_input("Land Area (Hectares)", min_value=0.1, value=1.0, step=0.1)
        unit = "Hectares"

    st.markdown('</div>', unsafe_allow_html=True)

    st.markdown("<br>", unsafe_allow_html=True)
    if st.button("✅ Confirm & Proceed to Nutrient Selection", type="primary", use_container_width=True):
        engine_crop = "maize" if "Maize" in crop else "kholar"
        
        with st.spinner("Fetching weather context from NASA POWER..."):
            weather_ctx = input_enricher.get_weather_context(lat, lon)
        
        go(2, crop=engine_crop, target_yield=float(T),
           lat=lat, lon=lon, land_area=area, area_unit=unit,
           weather_context=weather_ctx,
           N_done=False, P_done=False, K_done=False,
           FN=None, FP=None, FK=None,
           N_urea=None, P_ssp=None, K_mop=None)

# ─────────────────────────────────────────────────────────────────────────────
# STEP 2 — NUTRIENT HUB / SELECTION
# ─────────────────────────────────────────────────────────────────────────────
def step2_hub():
    crop_label = "Maize" if "maize" in st.session_state.crop else "Kholar"
    crop = st.session_state.crop
    T = st.session_state.target_yield

    st.markdown(f"""
    <div class="panel">
        <h3>🧭 Step 2 — Nutrient Hub</h3>
        <p style="color:#78909c">Crop: <strong style="color:#cfd8dc">{crop_label}</strong>
        &nbsp;|&nbsp; Target Yield: <strong style="color:#cfd8dc">{T} q/ha</strong></p>
        <p>Compute each nutrient below. All three must be done to proceed.</p>
    </div>
    """, unsafe_allow_html=True)

    # ── Process each nutrient inline ──
    for nut_key in ["N", "P", "K"]:
        meta = NUTRIENT_META[nut_key]
        done = st.session_state[f"{nut_key}_done"]
        val_key = {"N": "FN", "P": "FP", "K": "FK"}[nut_key]
        conv_map = {"N": "N_urea", "P": "P_ssp", "K": "K_mop"}
        conv_lbls = {"N": "Urea", "P": "SSP", "K": "MOP"}
        eq_map = {"N": "N_eq", "P": "P_eq", "K": "K_eq"}

        with st.expander(f"{meta['icon']}  {meta['label']} ({meta['fert']})  {'  ✅ Done' if done else '  ⏳ Pending'}", expanded=not done):
            if done:
                val = st.session_state[val_key]
                conv = st.session_state[conv_map[nut_key]]
                eq = st.session_state[eq_map[nut_key]]
                st.markdown(f"""
                <div class="result-box">
                    <div class="big-val">{val} <span style="font-size:1.2rem;color:#43a047">kg/ha</span></div>
                    <div style="margin-top:0.8rem;color:#81c784;font-size:1.1rem;font-weight:700">→ {conv_lbls[nut_key]}: <span style="color:#fff;font-size:1.4rem">{conv} kg/ha</span></div>
                    <div class="eq-text">{eq}</div>
                </div>
                """, unsafe_allow_html=True)

            # Input form (always shown so user can recompute)
            input_mode = st.radio(
                "Input method:",
                ["Fertility Class (Low / Medium / High)", "Direct Soil Test Value"],
                horizontal=True, key=f"imode_{nut_key}"
            )
            fc, raw_val = None, None
            soil_key = {"N": "SN (kg/ha)", "P": "SP (kg/ha)", "K": "SK (kg/ha)"}[nut_key]
            default_raw = {"N": 280.0, "P": 20.0, "K": 150.0}[nut_key]

            if input_mode.startswith("Fertility"):
                fc = st.selectbox(f"{meta['label']} Soil Fertility", ["Low", "Medium", "High"], key=f"fc_{nut_key}")
            else:
                raw_val = st.number_input(f"{soil_key}", min_value=0.0, step=1.0, value=default_raw, key=f"raw_{nut_key}")
                fc_display = FPEEngine._resolve_class_from_value(crop, raw_val, nut_key)
                st.info(f"**Detected Fertility Level:** {fc_display.capitalize()}")

            if st.button(f"⚡ Compute {meta['label']}", type="primary", use_container_width=True, key=f"cmp_{nut_key}"):
                try:
                    if nut_key == "N":
                        res = FPEEngine.compute_N(crop, T, fertility_class=fc, SN=raw_val)
                        st.session_state.FN = res["FN"]
                        st.session_state.N_urea = res["urea_kg_ha"]
                        st.session_state.N_eq = res["equation"]
                        st.session_state.N_done = True
                    elif nut_key == "P":
                        res = FPEEngine.compute_P(crop, T, fertility_class=fc, SP=raw_val)
                        st.session_state.FP = res["FP"]
                        st.session_state.P_ssp = res["ssp_kg_ha"]
                        st.session_state.P_eq = res["equation"]
                        st.session_state.P_done = True
                    else:
                        res = FPEEngine.compute_K(crop, T, fertility_class=fc, SK=raw_val)
                        st.session_state.FK = res["FK"]
                        st.session_state.K_mop = res["mop_kg_ha"]
                        st.session_state.K_eq = res["equation"]
                        st.session_state.K_done = True
                    st.rerun()
                except Exception as e:
                    st.error(f"Calculation error: {e}")

    st.markdown("<br>", unsafe_allow_html=True)

    # ── Navigation row ──
    bcol, fcol = st.columns([1, 3])
    with bcol:
        if st.button("← Back to Setup"):
            go(1)
    with fcol:
        if all_done():
            if st.button("🏁 View Final Summary →", type="primary", use_container_width=True):
                go(4)
        else:
            remaining = [NUTRIENT_META[n]["label"] for n in ["N","P","K"] if not st.session_state[f"{n}_done"]]
            st.info(f"Still pending: **{', '.join(remaining)}**. Compute all to unlock the summary.")

# Step 3 is now merged into step 2 above. Keeping stub for router compatibility.
def step3_nutrient():
    nut = st.session_state.active_nutrient   # "N", "P", or "K"
    meta = NUTRIENT_META[nut]
    crop = st.session_state.crop
    T    = st.session_state.target_yield

    crop_label = "Maize" if "maize" in crop else "Kholar"

    st.markdown(f"""
    <div class="panel">
        <h3>{meta['icon']} Step 3 — {meta['label']} ({meta['unit']})</h3>
        <p style="color:#78909c">Crop: <strong style="color:#cfd8dc">{crop_label}</strong>
        &nbsp;|&nbsp; T = <strong style="color:#cfd8dc">{T} q/ha</strong></p>
        <p>This page computes <strong>{meta['label']}</strong> ONLY. No other nutrient is touched.</p>
    </div>
    """, unsafe_allow_html=True)

    # ── Input mode ──
    input_mode = st.radio(
        "Input method for this nutrient:",
        ["Fertility Class (Low / Medium / High)", "Direct Soil Test Value"],
        horizontal=True,
        key=f"imode_{nut}"
    )

    fc, raw_val = None, None
    soil_key = {"N": "SN (kg/ha)", "P": "SP (kg/ha)", "K": "SK (kg/ha)"}[nut]
    default_raw = {"N": 280.0, "P": 20.0, "K": 150.0}[nut]

    col_in = st.container()

    with col_in:
        if input_mode.startswith("Fertility"):
            fc = st.selectbox(f"{meta['label']} Soil Fertility", ["Low", "Medium", "High"], key=f"fc_{nut}")
            fc_display = fc.lower()
        else:
            raw_val = st.number_input(f"{soil_key}", min_value=0.0, step=1.0, value=default_raw, key=f"raw_{nut}")
            fc_display = FPEEngine._resolve_class_from_value(crop, raw_val, nut)
            st.info(f"**Detected Fertility Level:** {fc_display.capitalize()}")
            
            # Warnings logic
            if "maize" in crop:
                if nut == "N" and (raw_val < 225 or raw_val > 500):
                    st.warning("Value is outside typical Maize N bounds (225-500). Proceeding with extreme category.")
                elif nut == "P" and (raw_val < 22 or raw_val > 55):
                    st.warning("Value is outside typical Maize P bounds (22-55).")
                elif nut == "K" and (raw_val < 137 or raw_val > 337):
                    st.warning("Value is outside typical Maize K bounds (137-337).")
            elif "kholar" in crop:
                if nut == "N" and (raw_val < 100 or raw_val > 500):
                    st.warning("Value is outside typical Kholar N bounds (100-500).")
                elif nut == "P" and (raw_val < 10 or raw_val > 90):
                    st.warning("Value is outside typical Kholar P bounds (10-90).")
                elif nut == "K" and (raw_val < 90 or raw_val > 400):
                    st.warning("Value is outside typical Kholar K bounds (90-400).")

    st.markdown("<br>", unsafe_allow_html=True)

    # ── Compute button ──
    if st.button(f"⚡ Compute {meta['label']}", type="primary", use_container_width=True, key=f"cmp_{nut}"):
        try:
            if nut == "N":
                res = FPEEngine.compute_N(crop, T, fertility_class=fc, SN=raw_val)
                st.session_state.FN    = res["FN"]
                st.session_state.N_urea = res["urea_kg_ha"]
                st.session_state.N_eq  = res["equation"]
                st.session_state.N_done = True
            elif nut == "P":
                res = FPEEngine.compute_P(crop, T, fertility_class=fc, SP=raw_val)
                st.session_state.FP    = res["FP"]
                st.session_state.P_ssp = res["ssp_kg_ha"]
                st.session_state.P_eq  = res["equation"]
                st.session_state.P_done = True
            else:
                res = FPEEngine.compute_K(crop, T, fertility_class=fc, SK=raw_val)
                st.session_state.FK    = res["FK"]
                st.session_state.K_mop = res["mop_kg_ha"]
                st.session_state.K_eq  = res["equation"]
                st.session_state.K_done = True
            st.rerun()
        except Exception as e:
            st.error(f"Calculation error: {e}")

    # ── Show result if already computed ──
    done_key  = f"{nut}_done"
    val_map   = {"N": "FN",    "P": "FP",    "K": "FK"}
    conv_map  = {"N": "N_urea","P": "P_ssp", "K": "K_mop"}
    conv_lbls = {"N": "Urea",  "P": "SSP",   "K": "MOP"}
    eq_map    = {"N": "N_eq",  "P": "P_eq",  "K": "K_eq"}

    if st.session_state[done_key]:
        val  = st.session_state[val_map[nut]]
        conv = st.session_state[conv_map[nut]]
        clbl = conv_lbls[nut]
        eq   = st.session_state[eq_map[nut]]
        st.markdown(f"""
        <div class="result-box">
            <div style="font-size:0.8rem;color:#546e4a;font-weight:700;letter-spacing:1px;text-transform:uppercase;margin-bottom:0.3rem">✅ Computed</div>
            <div class="big-val">{val} <span style="font-size:1.2rem;color:#43a047">kg/ha</span></div>
            <div style="margin-top:0.8rem;color:#81c784;font-size:1.1rem;font-weight:700">→ {clbl}: <span style="color:#fff;font-size:1.4rem">{conv} kg/ha</span></div>
            <div class="eq-text">{eq}</div>
        </div>
        """, unsafe_allow_html=True)

    # ── Navigation ──
    st.markdown("<br>", unsafe_allow_html=True)
    n1, n2 = st.columns([1, 1])
    with n1:
        if st.button("← Back to Nutrient Hub"):
            go(2)
    with n2:
        if all_done():
            if st.button("🏁 View Final Summary →", type="primary", use_container_width=True):
                go(4)

# ─────────────────────────────────────────────────────────────────────────────
# STEP 4 — FINAL SUMMARY
# ─────────────────────────────────────────────────────────────────────────────
def step4_summary():
    crop_label = "Maize" if "maize" in st.session_state.crop else "Kholar"
    T = st.session_state.target_yield
    area = st.session_state.land_area
    area_unit = st.session_state.area_unit

    st.markdown(f"""
    <div class="panel">
        <h3>🏁 Step 4 — Final Fertilizer Summary</h3>
        <p style="color:#78909c">Crop: <strong style="color:#cfd8dc">{crop_label}</strong>
        &nbsp;|&nbsp; Target Yield: <strong style="color:#cfd8dc">{T} q/ha</strong>
        &nbsp;|&nbsp; Plot Size: <strong style="color:#cfd8dc">{area} {area_unit}</strong></p>
    </div>
    """, unsafe_allow_html=True)
    
    # ── Organic Pathway Decision ──
    st.markdown("### 🌱 Organic Pathway Decision")
    go_organic = st.radio("Do you want to go the organic way?", ["No", "Yes"], horizontal=True)

    fym_t, vc_t, psnc_t = None, None, None
    is_org = (go_organic == "Yes")
    
    if is_org:
        n_req = st.session_state.FN
        fym_t = round(n_req / 5, 2)
        vc_t = round(n_req / 15, 2)
        psnc_t = round(n_req / 29, 2)
        
        st.markdown(f"""
        <div class="panel">
            <h4 style="color: #69f0ae;">Organic Alternatives for Nitrogen (choose one):</h4>
            <ul style="color: #cfd8dc; font-size: 1.1rem; line-height: 1.6;">
                <li><strong>FYM:</strong> {fym_t} t/ha</li>
                <li><strong>Vermicompost:</strong> {vc_t} t/ha</li>
                <li><strong>Enriched Compost:</strong> {psnc_t} t/ha</li>
            </ul>
            <div style="margin-top: 1rem; padding-top: 1rem; border-top: 1px solid #252d25;">
                <p style="color: #81d4fa; font-size: 0.95rem; margin-bottom: 0.5rem;">
                    <em>Note: Organic sources release nutrients slowly.</em>
                </p>
                <p style="color: #81d4fa; font-size: 0.95rem; margin-bottom: 0;">
                    <em>Suggestion: Combine organic + inorganic for the best yield (hybrid recommendation).</em>
                </p>
            </div>
        </div>
        """, unsafe_allow_html=True)

    # Output Enricher
    adj_FN, adj_FP, adj_FK, explanation = output_enricher.enrich_output(
        st.session_state.FN, 
        st.session_state.FP, 
        st.session_state.FK, 
        is_org, 
        fym_t
    )
    
    if explanation:
        st.info(f"**Organic Adjustment:** {explanation}")

    # Compute Fertilizer products (per ha)
    urea_ha = round(adj_FN / 0.46, 2) if adj_FN else 0
    ssp_ha  = round(adj_FP / 0.16, 2) if adj_FP else 0
    mop_ha  = round(adj_FK / 0.60, 2) if adj_FK else 0

    area_ha = area   # already in hectares

    # Scale by farm area (all totals in kg)
    urea_tot = round(urea_ha * area_ha, 2)
    ssp_tot  = round(ssp_ha  * area_ha, 2)
    mop_tot  = round(mop_ha  * area_ha, 2)

    c1, c2, c3 = st.columns(3)

    area_display = f"{area_ha} ha"

    for col, nut, val, conv, conv_lbl, unit in [
        (c1, "N", adj_FN,  urea_tot,"Urea",  "kg N/ha"),
        (c2, "P", adj_FP,  ssp_tot, "SSP",   "kg P₂O₅/ha"),
        (c3, "K", adj_FK,  mop_tot, "MOP",   "kg K₂O/ha"),
    ]:
        meta = NUTRIENT_META[nut]
        extra_cls = "p-card" if nut == "P" else ("k-card" if nut == "K" else "")
        col.markdown(f"""
        <div class="summary-card {extra_cls}">
            <div class="s-icon">{meta['icon']}</div>
            <div class="s-label">{meta['label']} · {meta['fert']}</div>
            <div class="s-val">{val}</div>
            <div class="s-unit">{unit}</div>
            <div class="s-conv">📦 {conv_lbl} for {area_display}<br><strong style="font-size:1.3rem">{conv} kg</strong></div>
        </div>
        """, unsafe_allow_html=True)

    # ── Application schedule ──
    st.markdown("<br>", unsafe_allow_html=True)
    st.markdown("### 📅 Recommended Application Schedule (Total Plot)")
    
    if "maize" in crop_label.lower():
        sch_cols = st.columns(3)
        schedules = [
            (
                "🌱 50 percent nitrogen as basal (During final land preparation)",
                f"All SSP ({ssp_tot} kg) + All MOP ({mop_tot} kg) + "
                f"{round(urea_tot * 0.50, 1)} kg Urea"
            ),
            (
                "📅 25 percent at knee high stage 30 Days after sowing",
                f"{round(urea_tot * 0.25, 1)} kg Urea"
            ),
            (
                "📅 Next 25 percent at 60 Days after sowing",
                f"{round(urea_tot * 0.25, 1)} kg Urea"
            ),
        ]
    else:
        # Kholar (legume) gets full basal dose
        sch_cols = st.columns(1)
        schedules = [
            (
                "🌱 At Sowing (Basal — Full Dose)",
                f"All SSP ({ssp_tot} kg) + All MOP ({mop_tot} kg) + All Urea ({urea_tot} kg)"
            ),
        ]
        
    for col, (timing, dose) in zip(sch_cols, schedules):
        col.markdown(f"""
        <div class="sched-card">
            <div class="sched-time">{timing}</div>
            <div class="sched-dose">{dose}</div>
        </div>
        """, unsafe_allow_html=True)

    # Delivery & Saving (only once per computation)
    if not st.session_state.get("saved_history", False):
        delivery.save_to_history(crop_label, T, adj_FN, adj_FP, adj_FK, urea_tot, ssp_tot, mop_tot, is_org, area, area_unit)
        st.session_state["saved_history"] = True

    # Action Buttons
    st.markdown("<br>", unsafe_allow_html=True)
    col_pdf, col_wa, _ = st.columns([1, 1, 2])
    with col_pdf:
        pdf_path = delivery.generate_pdf_report(crop_label, T, urea_tot, ssp_tot, mop_tot, area, area_unit, is_org, fym_t, explanation)
        with open(pdf_path, "rb") as f:
            st.download_button("📄 Download PDF Prescription", f, file_name="agrisutra_prescription.pdf", mime="application/pdf", use_container_width=True)
    with col_wa:
        wa_link = delivery.get_whatsapp_link(crop_label, T, urea_tot, ssp_tot, mop_tot, area, area_unit)
        st.link_button("💬 Share on WhatsApp", wa_link, use_container_width=True)

    st.markdown("<br>", unsafe_allow_html=True)
    st.markdown("### 📊 AI-Driven Explainable Summary")
    with st.spinner("Generating detailed technical summary from AI..."):
        summary_table = get_explainable_summary_table(
            crop_label, T, urea_tot, ssp_tot, mop_tot,
            is_org, fym_t, vc_t, psnc_t,
            st.session_state.weather_context
        )
        st.markdown(summary_table)

    st.markdown("<br>", unsafe_allow_html=True)
    if st.button("🔄 Start New Recommendation", use_container_width=True):
        for k in list(st.session_state.keys()):
            del st.session_state[k]
        st.rerun()


# ─────────────────────────────────────────────────────────────────────────────
# ROUTER
# ─────────────────────────────────────────────────────────────────────────────
render_header()
render_step_bar()

step = st.session_state.step
if   step == 1: step1_setup()
elif step == 2: step2_hub()
elif step == 3: step2_hub()   # step 3 merged into step 2
elif step == 4: step4_summary()
