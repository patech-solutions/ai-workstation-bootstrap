#!/usr/bin/env python3
"""Honcho Memory Dashboard — http://localhost:8080"""

import json
import os
import subprocess
import urllib.error
import urllib.parse
import urllib.request
from http.server import BaseHTTPRequestHandler, HTTPServer

HONCHO_URL = os.environ.get("HONCHO_URL", "http://localhost:8000")
WORKSPACE  = os.environ.get("HONCHO_WORKSPACE", "patech-wsa-01")
PORT       = int(os.environ.get("DASHBOARD_PORT", "8080"))


# ── Honcho helpers ───────────────────────────────────────────────────────────

def hget(path):
    try:
        with urllib.request.urlopen(f"{HONCHO_URL}{path}", timeout=8) as r:
            return json.loads(r.read())
    except Exception as e:
        return {"error": str(e)}


def hpost(path, data=None):
    try:
        body = json.dumps(data or {}).encode()
        req  = urllib.request.Request(
            f"{HONCHO_URL}{path}", data=body,
            headers={"Content-Type": "application/json"},
        )
        with urllib.request.urlopen(req, timeout=15) as r:
            return json.loads(r.read())
    except Exception as e:
        return {"error": str(e)}


def ollama_status():
    try:
        out   = subprocess.check_output(["ollama", "ps"], timeout=5, text=True)
        lines = [l for l in out.strip().splitlines() if l and not l.startswith("NAME")]
        result = []
        for line in lines:
            p = line.split()
            if len(p) >= 4:
                result.append({
                    "name": p[0], "size": f"{p[2]} {p[3]}",
                    "processor": p[4] if len(p) > 4 else "",
                    "context":   p[6] if len(p) > 6 else "",
                })
        return result
    except Exception:
        return []


def vram_status():
    try:
        out  = subprocess.check_output(
            ["nvidia-smi", "--query-gpu=memory.used,memory.free,memory.total",
             "--format=csv,noheader"], timeout=5, text=True)
        p    = [x.strip().replace(" MiB", "") for x in out.strip().split(",")]
        if len(p) == 3:
            return {"used_mib": int(p[0]), "free_mib": int(p[1]), "total_mib": int(p[2])}
    except Exception:
        pass
    return None


# ── Aggregate endpoints ──────────────────────────────────────────────────────

def api_status():
    health   = hget("/health")
    queue    = hget(f"/v3/workspaces/{WORKSPACE}/queue/status")
    peers_r  = hpost(f"/v3/workspaces/{WORKSPACE}/peers/list", {"size": 50})
    sessions_r = hpost(f"/v3/workspaces/{WORKSPACE}/sessions/list", {"size": 50})

    peers = []
    for p in peers_r.get("items", []):
        pid = p["id"]
        repr_d = hget(f"/v3/workspaces/{WORKSPACE}/peers/{pid}/representation")
        peers.append({
            "id":             pid,
            "created_at":     (p.get("created_at") or "")[:10],
            "representation": repr_d.get("content") or "",
        })

    sessions = []
    for s in sessions_r.get("items", []):
        sid  = s["id"]
        msgs = hpost(f"/v3/workspaces/{WORKSPACE}/sessions/{sid}/messages/list", {"size": 1})
        sessions.append({
            "id":             sid,
            "created_at":     (s.get("created_at") or "")[:16].replace("T", " "),
            "total_messages": msgs.get("total", 0),
        })

    return {
        "workspace": WORKSPACE,
        "health":    health,
        "queue":     queue,
        "peers":     peers,
        "sessions":  sessions,
        "ollama":    ollama_status(),
        "vram":      vram_status(),
    }


def api_session_messages(sid, page=1, size=50):
    offset = (page - 1) * size
    data   = hpost(
        f"/v3/workspaces/{WORKSPACE}/sessions/{sid}/messages/list",
        {"size": size, "page": page},
    )
    messages = []
    for m in data.get("items", []):
        peer_id = m.get("peer_id", "")
        messages.append({
            "id":         m.get("id"),
            "peer_id":    peer_id,
            "content":    m.get("content") or "",
            "created_at": (m.get("created_at") or "")[:16].replace("T", " "),
            "tokens":     m.get("token_count", 0),
        })
    return {
        "session_id": sid,
        "messages":   messages,
        "total":      data.get("total", 0),
        "page":       page,
        "size":       size,
        "pages":      data.get("pages", 1),
    }


def api_conclusions(observer=None, observed=None, page=1, size=30):
    payload = {"size": size, "page": page}
    if observer:
        payload["observer"] = observer
    if observed:
        payload["observed"] = observed
    data = hpost(f"/v3/workspaces/{WORKSPACE}/conclusions/list", payload)
    docs = []
    for d in data.get("items", []):
        docs.append({
            "id":         d.get("id") or "",
            "content":    d.get("content") or "",
            "observer":   d.get("observer") or "",
            "observed":   d.get("observed") or "",
            "level":      d.get("level") or "",
            "created_at": (d.get("created_at") or "")[:16].replace("T", " "),
            "session":    d.get("session_name") or "",
        })
    return {
        "docs":  docs,
        "total": data.get("total", 0),
        "page":  page,
        "pages": data.get("pages", 1),
    }


def api_peer_detail(pid):
    repr_d   = hget(f"/v3/workspaces/{WORKSPACE}/peers/{pid}/representation")
    peers_r  = hpost(f"/v3/workspaces/{WORKSPACE}/peers/list", {"size": 50})
    peer_ids = [p["id"] for p in peers_r.get("items", []) if p["id"] != pid]

    contexts = {}
    for obs_id in peer_ids:
        ctx = hget(f"/v3/workspaces/{WORKSPACE}/peers/{pid}/context?observer={urllib.parse.quote(obs_id)}")
        contexts[obs_id] = ctx.get("representation") or ""

    self_ctx = hget(f"/v3/workspaces/{WORKSPACE}/peers/{pid}/context?observer={urllib.parse.quote(pid)}")
    contexts[pid] = self_ctx.get("representation") or ""

    return {
        "id":             pid,
        "representation": repr_d.get("content") or "",
        "contexts":       contexts,
    }


# ── HTML ─────────────────────────────────────────────────────────────────────

HTML = r"""<!DOCTYPE html>
<html lang="nl">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>Honcho Dashboard</title>
<style>
:root {
  --bg:#0f1117;--surface:#1a1d27;--surface2:#22263a;--border:#2a2d3e;
  --text:#e2e8f0;--muted:#64748b;--accent:#6366f1;--accent2:#818cf8;
  --green:#22c55e;--yellow:#eab308;--red:#ef4444;--blue:#3b82f6;
  --sidebar:220px;
}
*{box-sizing:border-box;margin:0;padding:0;}
body{background:var(--bg);color:var(--text);font:13px/1.5 system-ui,sans-serif;display:flex;min-height:100vh;}
a{color:var(--accent2);text-decoration:none;}

/* Sidebar */
#sidebar{width:var(--sidebar);min-height:100vh;background:var(--surface);border-right:1px solid var(--border);padding:16px 0;flex-shrink:0;display:flex;flex-direction:column;}
.brand{padding:0 16px 16px;border-bottom:1px solid var(--border);margin-bottom:8px;}
.brand h1{font-size:15px;font-weight:700;color:var(--text);}
.brand .sub{font-size:11px;color:var(--muted);}
nav a{display:flex;align-items:center;gap:8px;padding:8px 16px;color:var(--muted);font-size:13px;font-weight:500;border-left:3px solid transparent;transition:all .15s;}
nav a:hover{color:var(--text);background:var(--surface2);}
nav a.active{color:var(--accent2);background:var(--surface2);border-left-color:var(--accent);}
.nav-section{font-size:10px;color:var(--muted);padding:12px 16px 4px;text-transform:uppercase;letter-spacing:.06em;}
.sidebar-footer{margin-top:auto;padding:12px 16px;font-size:11px;color:var(--muted);border-top:1px solid var(--border);}

/* Main */
#main{flex:1;min-width:0;padding:20px;}
.page{display:none;}.page.active{display:block;}
h2{font-size:12px;font-weight:600;text-transform:uppercase;letter-spacing:.05em;color:var(--muted);margin-bottom:12px;}
h3{font-size:14px;font-weight:600;margin-bottom:8px;}

/* Cards grid */
.grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(260px,1fr));gap:14px;margin-bottom:18px;}
.card{background:var(--surface);border:1px solid var(--border);border-radius:10px;padding:16px;}

/* Stats */
.stat-val{font-size:26px;font-weight:700;}
.stat-label{font-size:11px;color:var(--muted);margin-top:2px;}
.progress-wrap{background:var(--border);border-radius:4px;height:5px;margin-top:10px;overflow:hidden;}
.progress-bar{height:100%;border-radius:4px;transition:width .5s;}
.nums{display:flex;gap:14px;margin-top:8px;font-size:12px;}
.nums span{color:var(--muted);} .nums b{color:var(--text);}

/* Model/VRAM */
.model-row{display:flex;align-items:center;gap:6px;margin-bottom:6px;}
.model-name{flex:1;font-family:monospace;font-size:11px;}
.pill{font-size:10px;padding:1px 6px;border-radius:10px;background:var(--surface2);color:var(--muted);}
.pill.gpu{background:#1e3a5f;color:var(--blue);}
.vram-label{font-size:11px;color:var(--muted);margin-top:4px;display:flex;justify-content:space-between;}

/* Table */
table{width:100%;border-collapse:collapse;font-size:12px;}
th{text-align:left;color:var(--muted);font-size:10px;font-weight:600;text-transform:uppercase;letter-spacing:.04em;padding:0 10px 8px 0;border-bottom:1px solid var(--border);}
td{padding:7px 10px 7px 0;border-bottom:1px solid var(--border);vertical-align:top;}
tr:last-child td{border-bottom:none;}
tr.clickable{cursor:pointer;}tr.clickable:hover td{background:var(--surface2);}

/* Session messages */
#msg-panel{background:var(--surface);border:1px solid var(--border);border-radius:10px;padding:16px;margin-top:14px;}
.msg-back{font-size:12px;color:var(--accent2);cursor:pointer;margin-bottom:12px;display:inline-block;}
.msg-back:hover{text-decoration:underline;}
.msg{display:flex;gap:10px;margin-bottom:10px;padding-bottom:10px;border-bottom:1px solid var(--border);}
.msg:last-child{border-bottom:none;}
.msg-avatar{width:28px;height:28px;border-radius:50%;display:flex;align-items:center;justify-content:center;font-size:11px;font-weight:700;flex-shrink:0;}
.msg-avatar.atlas{background:#312e81;color:var(--accent2);}
.msg-avatar.pascal{background:#14532d;color:var(--green);}
.msg-avatar.other{background:var(--surface2);color:var(--muted);}
.msg-body{flex:1;min-width:0;}
.msg-header{display:flex;gap:8px;align-items:baseline;margin-bottom:4px;}
.msg-peer{font-size:11px;font-weight:600;}
.msg-time{font-size:10px;color:var(--muted);}
.msg-tokens{font-size:10px;color:var(--muted);}
.msg-content{font-size:12px;line-height:1.6;white-space:pre-wrap;word-break:break-word;}
.pager{display:flex;gap:8px;align-items:center;margin-top:14px;font-size:12px;}
.btn{background:var(--surface);border:1px solid var(--border);color:var(--text);padding:4px 12px;border-radius:6px;cursor:pointer;font-size:12px;}
.btn:hover{border-color:var(--accent);}
.btn:disabled{opacity:.4;cursor:default;}

/* Memory filters */
.filters{display:flex;gap:8px;margin-bottom:14px;flex-wrap:wrap;align-items:center;}
select,input{background:var(--surface);border:1px solid var(--border);color:var(--text);padding:5px 10px;border-radius:6px;font-size:12px;}
select:focus,input:focus{outline:none;border-color:var(--accent);}
.doc-item{padding:10px 0;border-bottom:1px solid var(--border);position:relative;}
.doc-item:last-child{border-bottom:none;}
.doc-content{font-size:13px;line-height:1.5;padding-right:52px;}
.doc-meta{font-size:10px;color:var(--muted);margin-top:4px;display:flex;gap:10px;flex-wrap:wrap;}
.level-badge{font-size:10px;padding:1px 6px;border-radius:10px;}
.level-badge.explicit{background:#1e3a5f;color:var(--blue);}
.level-badge.deductive{background:#3b1f5e;color:#c084fc;}
.doc-del{position:absolute;top:10px;right:0;background:none;border:1px solid transparent;color:var(--muted);cursor:pointer;font-size:11px;padding:2px 7px;border-radius:4px;transition:all .15s;}
.doc-del:hover{color:var(--red);border-color:var(--red);background:rgba(239,68,68,.08);}
.doc-del.confirm{color:var(--red);border-color:var(--red);font-weight:600;}

/* Peer detail */
.repr-box{background:var(--surface2);border:1px solid var(--border);border-radius:8px;padding:14px;font-size:12px;line-height:1.7;white-space:pre-wrap;max-height:500px;overflow-y:auto;margin-bottom:14px;}
.peer-tabs{display:flex;gap:4px;margin-bottom:12px;flex-wrap:wrap;}
.peer-tab{padding:5px 12px;border-radius:6px;cursor:pointer;font-size:12px;background:var(--surface2);border:1px solid var(--border);color:var(--muted);}
.peer-tab.active{background:var(--accent);border-color:var(--accent);color:#fff;}

/* Misc */
.badge{font-size:11px;padding:2px 8px;border-radius:20px;font-weight:600;}
.badge.ok{background:#14532d;color:var(--green);}
.badge.err{background:#450a0a;color:var(--red);}
.tag{font-family:monospace;font-size:11px;color:var(--accent2);}
.empty{color:var(--muted);font-style:italic;font-size:13px;}
.spinner{display:inline-block;width:14px;height:14px;border:2px solid var(--border);border-top-color:var(--accent);border-radius:50%;animation:spin .7s linear infinite;}
@keyframes spin{to{transform:rotate(360deg);}}
.header-row{display:flex;align-items:center;gap:10px;margin-bottom:16px;}
.header-row h2{margin:0;}
</style>
</head>
<body>

<div id="sidebar">
  <div class="brand">
    <h1>Honcho</h1>
    <div class="sub" id="ws-label">...</div>
  </div>
  <nav>
    <div class="nav-section">Overzicht</div>
    <a href="#" data-page="overview" class="active">⬡ Dashboard</a>
    <div class="nav-section">Data</div>
    <a href="#" data-page="sessions">◈ Sessies</a>
    <a href="#" data-page="memory">◉ Geheugen</a>
    <a href="#" data-page="peers">◎ Peers</a>
  </nav>
  <div class="sidebar-footer" id="last-updated">ophalen...</div>
</div>

<div id="main">

  <!-- OVERVIEW -->
  <div class="page active" id="page-overview">
    <div class="grid">
      <div class="card" id="queue-card"><div class="spinner"></div></div>
      <div class="card" id="vram-card"><div class="spinner"></div></div>
    </div>
    <div class="card" id="peers-summary"><div class="spinner"></div></div>
  </div>

  <!-- SESSIONS -->
  <div class="page" id="page-sessions">
    <div class="header-row">
      <h2>Sessies</h2>
      <span class="badge ok" id="session-count"></span>
    </div>
    <div class="card" id="sessions-table"><div class="spinner"></div></div>
    <div id="msg-panel" style="display:none"></div>
  </div>

  <!-- MEMORY -->
  <div class="page" id="page-memory">
    <div class="header-row"><h2>Geheugen / Observaties</h2></div>
    <div class="filters">
      <select id="obs-observer" onchange="loadDocs()"><option value="">Alle observers</option></select>
      <select id="obs-observed" onchange="loadDocs()"><option value="">Alle observed</option></select>
      <span id="doc-total" style="color:var(--muted);font-size:12px;margin-left:4px;"></span>
    </div>
    <div class="card" id="docs-list"><div class="spinner"></div></div>
    <div class="pager" id="docs-pager" style="display:none">
      <button class="btn" id="docs-prev" onclick="docPage(-1)">← Vorige</button>
      <span id="docs-page-label" style="color:var(--muted)"></span>
      <button class="btn" id="docs-next" onclick="docPage(1)">Volgende →</button>
    </div>
  </div>

  <!-- PEERS -->
  <div class="page" id="page-peers">
    <div class="header-row"><h2>Peers</h2></div>
    <div id="peer-selector" class="peer-tabs"></div>
    <div id="peer-detail"><div class="spinner"></div></div>
  </div>

</div><!-- /main -->

<script>
// ─── State ───────────────────────────────────────────────────────────────────
let state = { peers: [], sessions: [] };
let docState = { page: 1, pages: 1 };
let currentMsgSession = null;
let msgPage = 1;
let refreshTimer;

// ─── Nav ─────────────────────────────────────────────────────────────────────
document.querySelectorAll('nav a').forEach(a => {
  a.addEventListener('click', e => {
    e.preventDefault();
    document.querySelectorAll('nav a').forEach(x => x.classList.remove('active'));
    document.querySelectorAll('.page').forEach(x => x.classList.remove('active'));
    a.classList.add('active');
    document.getElementById('page-' + a.dataset.page).classList.add('active');
    if (a.dataset.page === 'memory') loadDocs();
    if (a.dataset.page === 'peers') loadPeerDetail(state.peers[0]?.id);
  });
});

// ─── Helpers ─────────────────────────────────────────────────────────────────
const $ = id => document.getElementById(id);
const fmt = n => (n ?? 0).toLocaleString('nl');
const esc = s => s.replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;');

function peerAvatar(pid) {
  if (!pid) return 'other';
  if (pid.includes('pascal') || pid.includes('pascal')) return 'pascal';
  if (pid === 'atlas') return 'atlas';
  return 'other';
}
function peerInitial(pid) {
  return (pid || '?')[0].toUpperCase();
}

// ─── Overview ────────────────────────────────────────────────────────────────
function renderQueue(q) {
  const total   = q.total_work_units ?? 0;
  const done    = q.completed_work_units ?? 0;
  const pending = q.pending_work_units ?? 0;
  const active  = q.in_progress_work_units ?? 0;
  const pct     = total > 0 ? Math.round(done / total * 100) : 100;
  const color   = pending === 0 ? 'var(--green)' : 'var(--accent)';
  return `<h2>Queue</h2>
    <div class="stat-val">${fmt(done)} <span style="font-size:16px;color:var(--muted)">/ ${fmt(total)}</span></div>
    <div class="stat-label">completed van totaal</div>
    <div class="progress-wrap"><div class="progress-bar" style="width:${pct}%;background:${color}"></div></div>
    <div class="nums">
      <div><span>Pending</span> <b>${fmt(pending)}</b></div>
      <div><span>Actief</span> <b>${fmt(active)}</b></div>
      <div><span>Klaar</span> <b>${pct}%</b></div>
    </div>`;
}

function renderVram(vram, ollama) {
  let html = '<h2>VRAM &amp; Modellen</h2>';
  (ollama || []).forEach(m => {
    html += `<div class="model-row">
      <span class="model-name">${esc(m.name)}</span>
      <span class="pill">${esc(m.size)}</span>
      <span class="pill gpu">${esc(m.processor)}</span>
      ${m.context ? `<span class="pill">ctx ${esc(m.context)}</span>` : ''}
    </div>`;
  });
  if (!ollama || ollama.length === 0) html += '<div class="empty">geen modellen geladen</div>';
  if (vram) {
    const pct   = Math.round(vram.used_mib / vram.total_mib * 100);
    const color = pct > 90 ? 'var(--red)' : pct > 75 ? 'var(--yellow)' : 'var(--green)';
    const gb    = x => (x/1024).toFixed(1) + ' GB';
    html += `<div class="progress-wrap" style="margin-top:10px"><div class="progress-bar" style="width:${pct}%;background:${color}"></div></div>
      <div class="vram-label"><span>${gb(vram.used_mib)} gebruikt</span><span>${gb(vram.free_mib)} vrij / ${gb(vram.total_mib)} totaal</span></div>`;
  }
  return html;
}

function renderPeersSummary(peers) {
  if (!peers.length) return '<div class="empty">geen peers</div>';
  return `<h2>Peers</h2><table>
    <thead><tr><th>ID</th><th>Aangemaakt</th><th>Representatie (preview)</th></tr></thead>
    <tbody>${peers.map(p => {
      const preview = (p.representation || '').replace(/^##[^\n]+\n/gm,'').trim().substring(0,120) || '—';
      return `<tr><td class="tag">${esc(p.id)}</td><td>${esc(p.created_at)}</td><td style="color:var(--muted)">${esc(preview)}</td></tr>`;
    }).join('')}</tbody></table>`;
}

// ─── Sessions ────────────────────────────────────────────────────────────────
function renderSessionsTable(sessions) {
  if (!sessions.length) return '<div class="empty">geen sessies</div>';
  return `<table>
    <thead><tr><th>Sessie ID</th><th>Aangemaakt</th><th style="text-align:right">Berichten</th></tr></thead>
    <tbody>${sessions.map(s =>
      `<tr class="clickable" onclick="openSession('${esc(s.id)}')">
        <td class="tag">${esc(s.id)}</td>
        <td>${esc(s.created_at)}</td>
        <td style="text-align:right">${fmt(s.total_messages)}</td>
      </tr>`
    ).join('')}</tbody></table>`;
}

async function openSession(sid) {
  currentMsgSession = sid;
  msgPage = 1;
  $('sessions-table').style.display = 'none';
  const panel = $('msg-panel');
  panel.style.display = 'block';
  panel.innerHTML = `<span class="msg-back" onclick="closeSession()">← Terug naar sessies</span>
    <h3>${esc(sid)}</h3><div class="spinner"></div>`;
  await loadMessages(sid, 1);
}

function closeSession() {
  $('msg-panel').style.display = 'none';
  $('sessions-table').style.display = '';
}

async function loadMessages(sid, page) {
  const res  = await fetch(`/api/sessions/${encodeURIComponent(sid)}/messages?page=${page}&size=40`);
  const data = await res.json();
  msgPage    = data.page;

  const msgs = data.messages.map(m => {
    const cls  = peerAvatar(m.peer_id);
    const init = peerInitial(m.peer_id);
    return `<div class="msg">
      <div class="msg-avatar ${cls}">${init}</div>
      <div class="msg-body">
        <div class="msg-header">
          <span class="msg-peer">${esc(m.peer_id || '?')}</span>
          <span class="msg-time">${esc(m.created_at)}</span>
          <span class="msg-tokens">${m.tokens ? m.tokens + ' tok' : ''}</span>
        </div>
        <div class="msg-content">${esc(m.content)}</div>
      </div>
    </div>`;
  }).join('') || '<div class="empty">geen berichten</div>';

  const pager = data.pages > 1 ? `
    <div class="pager">
      <button class="btn" onclick="loadMessages('${esc(sid)}',${page-1})" ${page<=1?'disabled':''}>← Vorige</button>
      <span style="color:var(--muted)">Pagina ${page} van ${data.pages} (${fmt(data.total)} berichten)</span>
      <button class="btn" onclick="loadMessages('${esc(sid)}',${page+1})" ${page>=data.pages?'disabled':''}>Volgende →</button>
    </div>` : `<div style="color:var(--muted);font-size:11px;margin-top:8px">${fmt(data.total)} berichten</div>`;

  $('msg-panel').innerHTML = `
    <span class="msg-back" onclick="closeSession()">← Terug naar sessies</span>
    <h3 style="margin-bottom:14px">${esc(sid)}</h3>
    ${msgs}${pager}`;
}

// ─── Memory ──────────────────────────────────────────────────────────────────
function populatePeerFilters(peers) {
  const obsrvr = $('obs-observer');
  const obsrvd = $('obs-observed');
  peers.forEach(p => {
    [obsrvr, obsrvd].forEach(sel => {
      const opt = document.createElement('option');
      opt.value = p.id; opt.textContent = p.id;
      sel.appendChild(opt);
    });
  });
}

async function loadDocs() {
  const observer = $('obs-observer').value;
  const observed = $('obs-observed').value;
  const page     = docState.page;
  $('docs-list').innerHTML = '<div class="spinner"></div>';

  const res  = await fetch(`/api/conclusions?observer=${encodeURIComponent(observer)}&observed=${encodeURIComponent(observed)}&page=${page}&size=30`);
  const data = await res.json();
  docState.pages = data.pages;
  $('doc-total').textContent = `${fmt(data.total)} observaties`;

  if (!data.docs.length) {
    $('docs-list').innerHTML = '<div class="empty">geen observaties gevonden</div>';
    $('docs-pager').style.display = 'none';
    return;
  }

  $('docs-list').innerHTML = data.docs.map(d => `
    <div class="doc-item" data-id="${esc(d.id)}">
      <button class="doc-del" title="Verwijder observatie" onclick="deleteConcl('${esc(d.id)}',this)">✕</button>
      <div class="doc-content">${esc(d.content)}</div>
      <div class="doc-meta">
        <span class="level-badge ${d.level}">${esc(d.level)}</span>
        <span>observer: <b>${esc(d.observer)}</b></span>
        <span>observed: <b>${esc(d.observed)}</b></span>
        <span>${esc(d.created_at)}</span>
        ${d.session ? `<span>sessie: ${esc(d.session)}</span>` : ''}
      </div>
    </div>`).join('');

  $('docs-pager').style.display = data.pages > 1 ? 'flex' : 'none';
  $('docs-page-label').textContent = `Pagina ${data.page} van ${data.pages}`;
  $('docs-prev').disabled = data.page <= 1;
  $('docs-next').disabled = data.page >= data.pages;
}

function docPage(delta) {
  docState.page = Math.max(1, Math.min(docState.pages, docState.page + delta));
  loadDocs();
}

function deleteConcl(id, btn) {
  if (btn.dataset.confirm === '1') {
    btn.textContent = '…'; btn.disabled = true;
    fetch('/api/conclusions/' + encodeURIComponent(id), {method: 'DELETE'})
      .then(r => {
        if (r.ok || r.status === 204) {
          const item = btn.closest('.doc-item');
          item.style.transition = 'opacity .25s';
          item.style.opacity = '0';
          setTimeout(() => { item.remove(); updateDocTotal(-1); }, 260);
        } else {
          btn.textContent = 'Fout'; btn.disabled = false; btn.dataset.confirm = '';
          setTimeout(() => { btn.textContent = '✕'; btn.classList.remove('confirm'); }, 2000);
        }
      });
  } else {
    btn.dataset.confirm = '1'; btn.textContent = 'Zeker?'; btn.classList.add('confirm');
    setTimeout(() => {
      if (btn.dataset.confirm === '1') {
        btn.dataset.confirm = ''; btn.textContent = '✕'; btn.classList.remove('confirm');
      }
    }, 3000);
  }
}

function updateDocTotal(delta) {
  const el = $('doc-total');
  const m = el.textContent.match(/(\d+)/);
  if (m) el.textContent = el.textContent.replace(m[0], Math.max(0, parseInt(m[0]) + delta));
}

// ─── Peers ───────────────────────────────────────────────────────────────────
async function loadPeerDetail(pid) {
  if (!pid) return;
  document.querySelectorAll('.peer-tab').forEach(t => {
    t.classList.toggle('active', t.dataset.pid === pid);
  });
  $('peer-detail').innerHTML = '<div class="spinner"></div>';

  const res  = await fetch(`/api/peers/${encodeURIComponent(pid)}`);
  const data = await res.json();

  const ctxTabs = Object.entries(data.contexts).map(([obs, content]) =>
    `<div class="peer-tab ${obs===pid?'active':''}" data-ctx="${esc(obs)}" onclick="switchCtx(this,'${esc(pid)}')">${esc(obs)}</div>`
  ).join('');

  const ctxPanels = Object.entries(data.contexts).map(([obs, content]) =>
    `<div class="repr-box ctx-panel" id="ctx-${esc(obs)}" style="${obs===pid?'':'display:none'}">${esc(content) || '(leeg)'}</div>`
  ).join('');

  $('peer-detail').innerHTML = `
    <h3 style="margin-bottom:12px">${esc(pid)}</h3>
    <h2>Globale Representatie</h2>
    <div class="repr-box">${esc(data.representation) || '(leeg)'}</div>
    <h2>Context per Observer</h2>
    <div class="peer-tabs" id="ctx-tabs">${ctxTabs}</div>
    ${ctxPanels}`;
}

function switchCtx(el, pid) {
  document.querySelectorAll('#ctx-tabs .peer-tab').forEach(t => t.classList.remove('active'));
  el.classList.add('active');
  document.querySelectorAll('.ctx-panel').forEach(p => p.style.display = 'none');
  const target = document.getElementById('ctx-' + el.dataset.ctx);
  if (target) target.style.display = 'block';
}

function renderPeerTabs(peers) {
  $('peer-selector').innerHTML = peers.map(p =>
    `<div class="peer-tab" data-pid="${esc(p.id)}" onclick="loadPeerDetail('${esc(p.id)}')">${esc(p.id)}</div>`
  ).join('');
}

// ─── Main load ───────────────────────────────────────────────────────────────
async function load() {
  clearTimeout(refreshTimer);
  try {
    const res = await fetch('/api/status');
    const d   = await res.json();

    state.peers    = d.peers    || [];
    state.sessions = d.sessions || [];

    $('ws-label').textContent = d.workspace;

    const ok = d.health?.status === 'ok';
    $('last-updated').innerHTML =
      `<span class="badge ${ok?'ok':'err'}">${ok?'✓ online':'✗ offline'}</span><br>` +
      new Date().toLocaleTimeString('nl-NL');

    // Overview
    $('queue-card').innerHTML = renderQueue(d.queue || {});
    $('vram-card').innerHTML  = renderVram(d.vram, d.ollama);
    $('peers-summary').innerHTML = renderPeersSummary(state.peers);

    // Sessions
    $('session-count').textContent = state.sessions.length + ' sessies';
    $('sessions-table').innerHTML  = renderSessionsTable(state.sessions);

    // Populate peer filters (once)
    if ($('obs-observer').options.length <= 1) populatePeerFilters(state.peers);

    // Peer tabs
    renderPeerTabs(state.peers);

  } catch (e) {
    $('last-updated').textContent = 'fout: ' + e.message;
  }
  refreshTimer = setTimeout(load, 30000);
}

load();
</script>
</body>
</html>
"""


# ── HTTP Handler ─────────────────────────────────────────────────────────────

class Handler(BaseHTTPRequestHandler):
    def log_message(self, fmt, *args):
        pass

    def send_json(self, data, status=200):
        body = json.dumps(data, ensure_ascii=False).encode()
        self.send_response(status)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def send_html(self, content):
        body = content.encode()
        self.send_response(200)
        self.send_header("Content-Type", "text/html; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self):
        parsed = urllib.parse.urlparse(self.path)
        path   = parsed.path
        qs     = urllib.parse.parse_qs(parsed.query)

        def qp(key, default=""):
            return qs.get(key, [default])[0]

        if path in ("/", "/index.html"):
            self.send_html(HTML)

        elif path == "/api/status":
            self.send_json(api_status())

        elif path.startswith("/api/sessions/") and path.endswith("/messages"):
            sid  = urllib.parse.unquote(path[len("/api/sessions/"):-len("/messages")])
            page = int(qp("page", "1"))
            size = int(qp("size", "40"))
            self.send_json(api_session_messages(sid, page, size))

        elif path == "/api/conclusions":
            self.send_json(api_conclusions(
                observer=qp("observer") or None,
                observed=qp("observed") or None,
                page=int(qp("page", "1")),
                size=int(qp("size", "30")),
            ))

        elif path.startswith("/api/peers/"):
            pid = urllib.parse.unquote(path[len("/api/peers/"):])
            self.send_json(api_peer_detail(pid))

        else:
            self.send_response(404)
            self.end_headers()

    def do_DELETE(self):
        parsed = urllib.parse.urlparse(self.path)
        path   = parsed.path
        if path.startswith("/api/conclusions/"):
            cid = urllib.parse.unquote(path[len("/api/conclusions/"):])
            try:
                req = urllib.request.Request(
                    f"{HONCHO_URL}/v3/workspaces/{WORKSPACE}/conclusions/{urllib.parse.quote(cid, safe='')}",
                    method="DELETE",
                )
                with urllib.request.urlopen(req, timeout=8):
                    pass
                self.send_response(204)
                self.end_headers()
            except urllib.error.HTTPError as e:
                self.send_response(e.code)
                self.end_headers()
            except Exception:
                self.send_response(500)
                self.end_headers()
        else:
            self.send_response(404)
            self.end_headers()


if __name__ == "__main__":
    server = HTTPServer(("127.0.0.1", PORT), Handler)
    print(f"Dashboard: http://localhost:{PORT}")
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\ngestopt")
