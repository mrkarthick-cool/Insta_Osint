#!/usr/bin/env bash
# Insta_Osint.sh - Top-centered avatar & vertical info layout (robust)
# Usage: ./Insta_Osint.sh <instagram_username>
clear 
set -euo pipefail
IFS=$'\n\t'

# ---- Dependencies ----
for cmd in curl jq file base64; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "Error: required command '$cmd' not found. Please install it."
    exit 1
  fi
done

# ---- Check args ----
if [ $# -lt 1 ]; then
  echo "Usage: $0 <instagram_username>"
  exit 1
fi
USERNAME="$1"

# optional second arg --download (not required here but kept for compatibility)
DOWNLOAD_FLAG="${2:-}"

logo() {
cat <<'EOF'
╭━━╮╱╱╱╱╱╭╮╱╱╱╱╭━━━┳━━━┳━━┳━╮╱╭┳━━━━╮
╰┫┣╯╱╱╱╱╭╯╰╮╱╱╱┃╭━╮┃╭━╮┣┫┣┫┃╰╮┃┃╭╮╭╮┃
╱┃┃╭━╮╭━┻╮╭╋━━╮┃┃╱┃┃╰━━╮┃┃┃╭╮╰╯┣╯┃┃╰╯
╱┃┃┃╭╮┫━━┫┃┃╭╮┃┃┃╱┃┣━━╮┃┃┃┃┃╰╮┃┃╱┃┃
╭┫┣┫┃┃┣━━┃╰┫╭╮┃┃╰━╯┃╰━╯┣┫┣┫┃╱┃┃┃╱┃┃
╰━━┻╯╰┻━━┻━┻╯╰╯╰━━━┻━━━┻━━┻╯╱╰━╯╱╰╯

Tool by https:/t.me/Drak24Evil | Cybersecurity & Ethical Insta-OSINT

EOF
}
logo
echo "🔍 Fetching public data for @$USERNAME ..."

# ---- Fetch profile JSON ----
RAW_JSON=$(curl -sS \
  -H "User-Agent: Mozilla/5.0 (iPhone; CPU iPhone OS 14_0 like Mac OS X)" \
  -H "x-ig-app-id: 936619743392459" \
  "https://i.instagram.com/api/v1/users/web_profile_info/?username=${USERNAME}" ) || {
    echo "❌ curl failed to fetch profile JSON."
    exit 1
}

# ensure we got JSON and it contains user
if ! printf '%s' "$RAW_JSON" | jq -e '.data.user' >/dev/null 2>&1; then
  echo "❌ Error: failed to parse profile JSON or profile is private/not found."
  printf "%s\n" "$RAW_JSON" > "${USERNAME}_raw.json"
  echo "🔧 Raw response saved to ${USERNAME}_raw.json for debugging."
  exit 1
fi

# ---- Extract fields into a clean JSON file ----
printf '%s\n' "$RAW_JSON" | jq -r '
  .data.user |
  {
    id: .id,
    username: .username,
    name: .full_name,
    bio: .biography,
    category: .category_name,
    followers: .edge_followed_by.count,
    following: .edge_follow.count,
    posts: .edge_owner_to_timeline_media.count,
    highlights: .highlight_reel_count,
    is_private: .is_private,
    verified: .is_verified,
    external_link: .external_url,
    profile_url: ("https://www.instagram.com/" + .username + "/"),
    profile_pic_hd: .profile_pic_url_hd
  }' > "${USERNAME}.json"

# ---- Load variables ----
NAME=$(jq -r '.name // ""' "${USERNAME}.json")
USERNAME_J=$(jq -r '.username // ""' "${USERNAME}.json")
BIO=$(jq -r '.bio // ""' "${USERNAME}.json")
CATEGORY=$(jq -r '.category // ""' "${USERNAME}.json")
FOLLOWERS=$(jq -r '.followers // 0' "${USERNAME}.json")
FOLLOWING=$(jq -r '.following // 0' "${USERNAME}.json")
POSTS=$(jq -r '.posts // 0' "${USERNAME}.json")
HIGHLIGHTS=$(jq -r '.highlights // 0' "${USERNAME}.json")
PRIVATE=$(jq -r '.is_private // false' "${USERNAME}.json")
VERIFIED=$(jq -r '.verified // false' "${USERNAME}.json")
EXTERNAL=$(jq -r '.external_link // ""' "${USERNAME}.json")
PROFILE=$(jq -r '.profile_url // ""' "${USERNAME}.json")
PHOTO_RAW=$(jq -r '.profile_pic_hd // ""' "${USERNAME}.json")

# ---- Prepare embedded profile image (base64) ----
IMG_DATAURI=""
if [ -n "$PHOTO_RAW" ] && [ "$PHOTO_RAW" != "null" ]; then
  TMPBIN="$(mktemp)"
  if curl -sS -L -o "$TMPBIN" --fail "$PHOTO_RAW"; then
    # determine MIME type if `file` works; fallback to jpeg
    if command -v file >/dev/null 2>&1; then
      MIME=$(file --brief --mime-type "$TMPBIN" 2>/dev/null || echo "image/jpeg")
    else
      MIME="image/jpeg"
    fi

    # base64 without linewrap portably
    if base64 --help 2>&1 | grep -q -- '-w'; then
      BASE64DATA=$(base64 -w 0 "$TMPBIN")
    else
      BASE64DATA=$(base64 "$TMPBIN" | tr -d '\n')
    fi

    IMG_DATAURI="data:${MIME};base64,${BASE64DATA}"
    rm -f "$TMPBIN"
  else
    rm -f "$TMPBIN"
    echo "⚠️ Couldn't download profile image; using placeholder in HTML."
  fi
fi

# final image source (data URI if available, else placeholder)
IMG_SRC="${IMG_DATAURI:-https://via.placeholder.com/180?text=No+Image}"

# ---- Emit responsive, top-centered layout HTML ----
cat > index.html <<EOF
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8" />
<meta name="viewport" content="width=device-width,initial-scale=1" />
<title>OSINT - @$USERNAME_J</title>
<style>
:root{--bg:#06080b;--neon:#00ff99;--muted:#7fd8b7;}
html,body{height:100%;margin:0;font-family:monospace;background:var(--bg);color:var(--neon);overflow-x:hidden}
canvas#matrix{position:fixed;inset:0;z-index:0;opacity:0.30;mix-blend-mode:screen}
.container{position:relative;z-index:2;min-height:100vh;display:flex;flex-direction:column;align-items:center;padding:20px 12px;gap:10px}
.avatar{width:180px;height:180px;border-radius:50%;border:3px solid var(--neon);object-fit:cover;box-shadow:0 10px 30px rgba(0,255,153,0.06);transition:transform .18s}
.avatar:hover{transform:scale(1.04)}
.username{font-size:20px;font-weight:800;margin-top:6px}
.name{font-size:14px;color:var(--muted)}
.bio{max-width:720px;text-align:center;color:var(--neon);font-size:14px;line-height:1.45;margin-top:6px;padding:0 8px}
.stats{font-size:13px;color:var(--muted);margin-top:8px}
.buttons{display:flex;gap:8px;flex-wrap:wrap;justify-content:center;margin-top:8px}
.btn{padding:8px 12px;border-radius:8px;border:1px solid rgba(0,255,153,0.12);background:transparent;color:var(--neon);cursor:pointer}
.btn:hover{background:rgba(0,255,153,0.04)}
.terminal{width:100%;max-width:820px;background:linear-gradient(180deg, rgba(0,0,0,0.12), rgba(0,0,0,0.06));border-radius:10px;padding:14px;color:var(--neon);min-height:180px;overflow:auto;border:1px solid rgba(0,255,153,0.06);box-shadow:inset 0 1px 0 rgba(255,255,255,0.02)}
.term-lines{white-space:pre-wrap;word-break:break-word}
.cursor{display:inline-block;width:10px;height:18px;background:var(--neon);margin-left:6px;vertical-align:bottom;animation:blink 1s steps(2) infinite}
@keyframes blink{50%{opacity:0}}
.meta{font-size:12px;color:var(--muted);margin-top:8px;text-align:center}
@media (max-width:520px){
  .avatar{width:130px;height:130px}
  .username{font-size:18px}
  .bio{font-size:13px}
}
</style>
</head>
<body>
<canvas id="matrix"></canvas>

<div class="container">
  <a id="profileLink" href="$PROFILE" target="_blank" title="Open profile">
    <img class="avatar" src="${IMG_SRC}" alt="@$USERNAME_J">
  </a>

  <div class="username">@${USERNAME_J}</div>
  <div class="name">${NAME}</div>
  <div class="bio">${BIO}</div>

  <div class="stats">
    Followers: ${FOLLOWERS} | Following: ${FOLLOWING} | Posts: ${POSTS} |
    Highlights: ${HIGHLIGHTS} | Verified: ${VERIFIED} | Private: ${PRIVATE}
  </div>

  <div class="buttons">
    <button class="btn" id="btnOpen">Open Profile</button>
    <button class="btn" id="btnCopy">Copy JSON</button>
    <a class="btn" href="https://t.me/Drak24Evil" target="_blank">Contact Dev</a>
    <a class="btn" href="https://t.me/teluguhackersgroup1" target="_blank">Join Telegram</a>
  </div>

  <div class="terminal" id="terminal" role="region" aria-label="OSINT terminal">
    <div class="term-lines" id="term-lines"></div><span class="cursor" id="cursor"></span>
  </div>

 
<div class="meta" style="display:flex;flex-direction:column;align-items:center;gap:8px;">
  <div class="meta-links" style="display:flex;gap:10px;flex-wrap:wrap;justify-content:center;align-items:center;">
  
    <a href="https://t.me/Drak24Evil" target="_blank" rel="noopener" style="color:var(--neon);text-decoration:none;display:inline-flex;gap:6px;align-items:center;font-size:13px;">
      <svg width="14" height="14" viewBox="0 0 24 24" fill="none" aria-hidden focusable="false" style="filter:drop-shadow(0 0 6px rgba(0,255,153,0.08));">
        <path d="M22 3L2 12.1l4.4 1.6L8.5 19l3.4-2.2L20.4 21 22 3z" fill="currentColor"/>
      </svg>
      <strong>@Drak24Evil</strong>
    </a>

 
    <a href="https://www.instagram.com/mr_rkarthik" target="_blank" rel="noopener" style="color:var(--neon);text-decoration:none;display:inline-flex;gap:6px;align-items:center;font-size:13px;">
      <svg width="14" height="14" viewBox="0 0 24 24" fill="none" aria-hidden focusable="false" style="filter:drop-shadow(0 0 6px rgba(0,255,153,0.06));">
        <path d="M7 2h10a5 5 0 0 1 5 5v10a5 5 0 0 1-5 5H7a5 5 0 0 1-5-5V7a5 5 0 0 1 5-5z" stroke="currentColor" stroke-width="1.2" fill="none"/>
        <circle cx="12" cy="12" r="3" fill="currentColor"/>
      </svg>
      mr_rkarthik
    </a>

 
    <a href="https://t.me/teluguhackersgroup1" target="_blank" rel="noopener" style="color:var(--neon);text-decoration:none;display:inline-flex;gap:6px;align-items:center;font-size:13px;">
      <svg width="14" height="14" viewBox="0 0 24 24" fill="none" aria-hidden focusable="false">
        <path d="M22 3L2 12.1l4.4 1.6L8.5 19l3.4-2.2L20.4 21 22 3z" fill="currentColor"/>
      </svg>
      TeluguHackersGroup
    </a>

 
    <a href="https://www.youtube.com/@mranonymousking5638" target="_blank" rel="noopener" style="color:var(--neon);text-decoration:none;display:inline-flex;gap:6px;align-items:center;font-size:13px;">
      <svg width="14" height="14" viewBox="0 0 24 24" fill="none" aria-hidden focusable="false">
        <path d="M21 7.5s-.2-1.4-.8-2c-.7-.8-1.5-.8-1.9-.9C16.1 4.3 12 4.3 12 4.3h0s-4.1 0-6.3.4c-.4.1-1.2.1-1.9.9-.6.6-.8 2-.8 2S2 9.3 2 11.1v1.8c0 1.8.3 3.6.3 3.6s.2 1.4.8 2c.7.8 1.6.8 2 .9 1.8.2 7.5.4 7.5.4s4.1 0 6.3-.4c.4-.1 1.2-.1 1.9-.9.6-.6.8-2 .8-2s.3-1.8.3-3.6v-1.8c0-1.8-.3-3.6-.3-3.6z" stroke="currentColor" stroke-width="0.4" fill="currentColor"/>
        <path d="M10 15V9l5 3-5 3z" fill="#000"/>
      </svg>
      YouTube
    </a>
  </div>

 
  <div style="display:flex;gap:8px;align-items:center;justify-content:center;font-size:13px;flex-wrap:wrap;">
    <div style="color:var(--muted);">Donate (GPay / UPI):</div>
    <div id="gpayId" style="font-weight:700;letter-spacing:0.4px;">mrkarthick246@oksbi</div>
    <button id="copyGpay" style="padding:6px 8px;border-radius:6px;border:1px solid rgba(0,255,153,0.12);background:transparent;color:var(--neon);cursor:pointer;">Copy</button>
  </div>
</div>

<script>
 
  (function(){
    const btn = document.getElementById('copyGpay');
    const idEl = document.getElementById('gpayId');
    if(!btn || !idEl) return;
    btn.addEventListener('click', async () => {
      const text = idEl.innerText.trim();
      try {
        await navigator.clipboard.writeText(text);
        btn.innerText = 'Copied';
        setTimeout(()=> btn.innerText = 'Copy', 1400);
      } catch(e) {
        alert('Copy failed — GPay ID: ' + text);
      }
    });
  })();
</script>



<script>

(function(){
  const c=document.getElementById('matrix'), ctx=c.getContext('2d');
  let w,h,cols,drops,fs=12;
  function resize(){ w=c.width=innerWidth; h=c.height=innerHeight; cols=Math.floor(w/fs); drops=Array(cols).fill(0); }
  window.addEventListener('resize', resize); resize();
  const chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789@#$%^&*()*+=-—<>/";
  (function draw(){
    ctx.fillStyle = "rgba(6,8,11,0.16)"; ctx.fillRect(0,0,w,h);
    ctx.fillStyle = "rgba(0,255,153,0.08)"; ctx.font = fs + "px monospace";
    for (let i=0;i<drops.length;i++){
      const ch = chars.charAt(Math.floor(Math.random()*chars.length));
      ctx.fillText(ch, i*fs, drops[i]*fs);
      if (drops[i]*fs > h && Math.random() > 0.975) drops[i] = 0;
      drops[i]++;
    }
    requestAnimationFrame(draw);
  })();
})();


(function(){
  const lines = [
    "Initializing OSINT module...",
    "Loading profile data: @$USERNAME_J",
    "Name: ${NAME}",
    "Bio: ${BIO}",
    "Followers: ${FOLLOWERS} | Following: ${FOLLOWING} | Posts: ${POSTS}",
    "Highlights: ${HIGHLIGHTS} | Verified: ${VERIFIED} | Private: ${PRIVATE}",
    "Profile: $PROFILE",
    "",
    "Status: ✅ Data retrieved",
    "Tip: Click avatar or press 'o' to open profile."
  ];
  const term = document.getElementById('term-lines');
  const cursor = document.getElementById('cursor');
  let i=0, j=0, speed=18;
  function escapeHtml(s){ return s.replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;'); }
  function typeNext(){
    if (i >= lines.length) { cursor.style.display = 'inline-block'; return; }
    const cur = lines[i];
    if (j <= cur.length){
      term.innerHTML = lines.slice(0,i).map(ln=>escapeHtml(ln)).join("<br>") + (i? "<br>": "") + escapeHtml(cur.slice(0,j));
      j++; setTimeout(typeNext, speed + Math.random()*20);
    } else { i++; j = 0; setTimeout(typeNext, 220); }
    term.parentElement.scrollTop = term.parentElement.scrollHeight;
  }
  setTimeout(typeNext, 400);
  document.getElementById('terminal').addEventListener('click', ()=>{ term.innerHTML=''; i=0; j=0; typeNext(); });
})();


document.getElementById('btnOpen').addEventListener('click', ()=> window.open(document.getElementById('profileLink').href, '_blank'));
document.getElementById('btnCopy').addEventListener('click', async ()=>{
  try{
    const j = await fetch('${USERNAME}.json').then(r => r.ok ? r.text() : '{}');
    await navigator.clipboard.writeText(j);
    alert('✅ JSON copied to clipboard!');
  }catch(e){ console.error(e); alert('Copy failed'); }
});
window.addEventListener('keydown', (ev)=> { if (ev.key === 'o' || ev.key === 'O') window.open(document.getElementById('profileLink').href, '_blank'); });

</script>
</body>
</html>
EOF

echo "index.html generated with top-centered profile and stacked info."
echo "Open index.html in your browser to view."
echo "Share with Your Friends"
                                                 
         
