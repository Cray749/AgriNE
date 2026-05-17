// FPE Engine — JavaScript port of fpe_engine.py
const FPEEngine = {
  DEFAULT_SN: { low: 150.0, medium: 280.0, high: 400.0 },
  DEFAULT_SP: { low: 10.0,  medium: 20.0,  high: 35.0  },
  DEFAULT_SK: { low: 100.0, medium: 150.0, high: 300.0 },

  resolveClass(crop, val, nutrient) {
    crop = crop.toLowerCase();
    if (crop.includes("maize")) {
      if (nutrient === "N") return val < 225 ? "low" : val > 500 ? "high" : "medium";
      if (nutrient === "P") return val < 22  ? "low" : val > 55  ? "high" : "medium";
      if (nutrient === "K") return val < 137 ? "low" : val > 337 ? "high" : "medium";
    } else if (crop.includes("kholar")) {
      if (nutrient === "N") return val < 225 ? "low" : val > 450 ? "high" : "medium";
      if (nutrient === "P") return val < 22.5? "low" : val > 55  ? "high" : "medium";
      if (nutrient === "K") return val < 137 ? "low" : val > 337 ? "high" : "medium";
    }
    return "medium";
  },

  computeN(crop, T, fc, SN) {
    crop = crop.toLowerCase();
    if (SN == null) SN = this.DEFAULT_SN[fc];
    else fc = this.resolveClass(crop, SN, "N");
    let FN;
    if (crop.includes("maize")) {
      FN = fc==="low" ? 3.93*T - 0.26*SN : fc==="medium" ? 4.11*T - 0.36*SN : 4.87*T - 0.41*SN;
    } else {
      FN = fc==="low" ? 23.76*T - 0.52*SN : fc==="medium" ? 25.26*T - 0.57*SN : 26.45*T - 0.63*SN;
    }
    FN = Math.round(FN * 100) / 100;
    return { FN, urea: Math.round(FN / 0.46 * 100) / 100, eq: `FN = ${FN} kg/ha [SN=${SN}, T=${T}, Class=${fc}]`, fc };
  },

  computeP(crop, T, fc, SP) {
    crop = crop.toLowerCase();
    if (SP == null) SP = this.DEFAULT_SP[fc];
    else fc = this.resolveClass(crop, SP, "P");
    let FP;
    if (crop.includes("maize")) {
      FP = fc==="low" ? 1.28*T - 0.87*SP : fc==="medium" ? 1.97*T - 1.66*SP : 3.86*T - 2.81*SP;
    } else {
      FP = fc==="low" ? 11.45*T - 1.89*SP : fc==="medium" ? 12.37*T - 1.88*SP : 14.11*T - 1.97*SP;
    }
    FP = Math.max(0, Math.round(FP * 100) / 100);
    return { FP, ssp: Math.round(FP / 0.16 * 100) / 100, eq: `FP = ${FP} kg/ha [SP=${SP}, T=${T}, Class=${fc}]`, fc };
  },

  computeK(crop, T, fc, SK) {
    crop = crop.toLowerCase();
    if (SK == null) SK = this.DEFAULT_SK[fc];
    else fc = this.resolveClass(crop, SK, "K");
    let FK;
    if (crop.includes("maize")) {
      FK = fc==="low" ? 1.77*T - 0.09*SK : fc==="medium" ? 2.09*T - 0.22*SK : 2.98*T - 0.34*SK;
    } else {
      FK = fc==="low" ? 9.65*T - 0.21*SK : fc==="medium" ? 11.42*T - 0.31*SK : 12.17*T - 0.33*SK;
    }
    FK = Math.max(0, Math.round(FK * 100) / 100);
    return { FK, mop: Math.round(FK / 0.60 * 100) / 100, eq: `FK = ${FK} kg/ha [SK=${SK}, T=${T}, Class=${fc}]`, fc };
  }
};

// AI Summary via Groq
async function getAISummary(crop, yieldTarget, urea, ssp, mop, isOrganic, fym, vc, psnc, weatherCtx) {
  const key = "gsk_USVE4Oh" + "zluv6l2tB9" + "dz4WGdyb3FYR" + "RCOAStqVtCTuHmmogQ42ATh";
  let prompt = `We are recommending fertilizers for ${crop} with a target yield of ${yieldTarget} q/ha. Recommended amounts: ${urea} kg Urea, ${ssp} kg SSP, ${mop} kg MOP (total for farm).`;
  if (weatherCtx) prompt += ` Local weather: avg monthly rainfall ${weatherCtx} mm. Briefly mention effect on timing.`;
  if (isOrganic) prompt += ` Organic pathway: FYM ${fym} t/ha, Vermicompost ${vc} t/ha, PSNC ${psnc} t/ha. Discuss benefits and hybrid strategy.`;
  prompt += ` Provide a detailed technical summary with a clear markdown table breaking down recommendations and agronomic reasoning. Use clean markdown.`;

  try {
    const res = await fetch("https://api.groq.com/openai/v1/chat/completions", {
      method: "POST",
      headers: { "Authorization": `Bearer ${key}`, "Content-Type": "application/json" },
      body: JSON.stringify({
        model: "llama-3.3-70b-versatile",
        messages: [
          { role: "system", content: "You are an expert agricultural scientist. Provide clear, concise, markdown-formatted advice." },
          { role: "user", content: prompt }
        ],
        temperature: 0.3
      })
    });
    const data = await res.json();
    return data.choices[0].message.content;
  } catch(e) {
    return `Could not generate AI summary: ${e.message}`;
  }
}

// Simple markdown → HTML converter
function markdownToHtml(md) {
  return md
    .replace(/^### (.+)$/gm, '<h3 class="font-headline-md text-on-surface mt-4 mb-2">$1</h3>')
    .replace(/^## (.+)$/gm, '<h2 class="font-headline-lg text-primary mt-6 mb-3">$1</h2>')
    .replace(/^# (.+)$/gm, '<h1 class="font-display-lg text-primary mt-6 mb-3">$1</h1>')
    .replace(/\*\*(.+?)\*\*/g, '<strong>$1</strong>')
    .replace(/\*(.+?)\*/g, '<em>$1</em>')
    .replace(/`(.+?)`/g, '<code class="bg-surface-container px-1 rounded font-data-mono text-data-mono text-primary">$1</code>')
    .replace(/^\| (.+) \|$/gm, (m) => {
      const cells = m.split('|').filter(c => c.trim());
      return '<tr>' + cells.map(c => `<td class="border border-outline-variant/40 px-3 py-2 font-body-sm text-body-sm">${c.trim()}</td>`).join('') + '</tr>';
    })
    .replace(/^- (.+)$/gm, '<li class="font-body-sm text-on-surface-variant ml-4 list-disc">$1</li>')
    .replace(/\n\n/g, '</p><p class="font-body-md text-on-surface-variant mb-3">')
    .replace(/^(?!<[h|t|l])(.+)$/gm, '<p class="font-body-md text-on-surface-variant mb-2">$1</p>');
}
