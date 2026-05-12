<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>Fredon Immobilier — Connexion</title>
<link href="https://fonts.googleapis.com/css2?family=Syne:wght@400;600;700;800&family=DM+Sans:ital,opsz,wght@0,9..40,300;0,9..40,400;0,9..40,500;1,9..40,300&display=swap" rel="stylesheet">
<style>
*, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }

:root {
  --gold:    #c8860a;
  --gold2:   #e8a220;
  --dark:    #1a1208;
  --mid:     #6b5a3e;
  --error:   #f04040;
  --success: #15b87a;
  --shadow:  0 32px 100px rgba(180,110,20,.18), 0 4px 24px rgba(0,0,0,.08);
}

html, body {
  height: 100%;
  font-family: 'DM Sans', sans-serif;
}

body {
  display: flex;
  align-items: center;
  justify-content: center;
  min-height: 100vh;
  padding: 24px 16px;
}

/* ── BACKGROUND ── */
.bg {
  position: fixed; inset: 0; z-index: 0;
  background: linear-gradient(135deg, #fdf8ee 0%, #fef5e0 40%, #fff9f0 70%, #fdf4e3 100%);
}
.blob {
  position: absolute; border-radius: 50%;
  filter: blur(80px); opacity: .45;
  animation: drift 16s ease-in-out infinite alternate;
}
.blob-1 { width:600px; height:600px; background:#f5dfa0; top:-180px; left:-140px; animation-delay:0s; }
.blob-2 { width:450px; height:450px; background:#d4e8c2; bottom:-120px; right:5%; animation-delay:-5s; }
.blob-3 { width:320px; height:320px; background:#f8cda0; top:25%; right:-80px; animation-delay:-10s; }
.blob-4 { width:280px; height:280px; background:#e8d5b0; bottom:5%; left:15%; animation-delay:-3s; }
@keyframes drift {
  0%   { transform: translate(0,0) scale(1); }
  100% { transform: translate(28px,18px) scale(1.1); }
}

/* ── CARD ── */
.card {
  position: relative; z-index: 1;
  display: flex;
  width: min(1000px, 100%);
  background: rgba(255,255,255,.74);
  backdrop-filter: blur(32px) saturate(180%);
  -webkit-backdrop-filter: blur(32px) saturate(180%);
  border-radius: 32px;
  box-shadow: var(--shadow);
  border: 1px solid rgba(255,255,255,.92);
  overflow: hidden;
  animation: cardIn .8s cubic-bezier(.22,.97,.45,1) both;
}
@keyframes cardIn {
  from { opacity:0; transform: translateY(40px) scale(.96); }
  to   { opacity:1; transform: translateY(0) scale(1); }
}

/* ════════════════ LEFT PANEL ════════════════ */
.panel-left {
  flex: 1.2;
  background: linear-gradient(148deg, #0b2472 0%, #1a46c0 38%, #2547a0 68%, #b87a10 100%);
  padding: 36px 36px 32px;
  display: flex;
  flex-direction: column;
  position: relative;
  overflow: hidden;
  min-height: 0;
}
.panel-left::before {
  content:''; position:absolute; inset:0; pointer-events:none;
  background-image:
    linear-gradient(rgba(255,255,255,.04) 1px, transparent 1px),
    linear-gradient(90deg, rgba(255,255,255,.04) 1px, transparent 1px);
  background-size: 44px 44px;
}
.orb { position:absolute; border-radius:50%; pointer-events:none; }
.orb-1 {
  width:320px; height:320px;
  background: radial-gradient(circle, rgba(255,210,80,.18) 0%, transparent 70%);
  top:-80px; right:-70px;
}
.orb-2 {
  width:240px; height:240px;
  background: radial-gradient(circle, rgba(100,160,255,.22) 0%, transparent 70%);
  bottom:20px; left:-60px;
}

/* ── LOGO ── */
.logo-wrap {
  display:flex; align-items:center; gap:14px;
  animation: fadeUp .6s .1s both;
  position:relative; z-index:2;
  flex-shrink: 0;
}
.logo-mark {
  width:54px; height:54px; flex-shrink:0;
  object-fit:cover; border-radius:14px;
  box-shadow: 0 6px 20px rgba(0,0,0,.35);
  transition: transform .3s ease;
  background: rgba(255,255,255,.15);
}
.logo-mark:hover { transform: scale(1.05); }
.logo-text { display:flex; flex-direction:column; line-height:1; }
.logo-name {
  font-family:'Syne',sans-serif; font-weight:800; font-size:26px;
  background: linear-gradient(135deg,#fff 0%,#fde9b0 100%);
  -webkit-background-clip:text; background-clip:text; color:transparent;
  letter-spacing:-.3px;
}
.logo-sub {
  font-size:10px; font-weight:400; color:rgba(255,255,255,.6);
  letter-spacing:2px; text-transform:uppercase; margin-top:3px;
}

/* ── HERO IMAGE ── */
.hero-img-wrap {
  position: relative; z-index: 2;
  margin: 22px 0 0;
  border-radius: 22px;
  overflow: hidden;
  flex-shrink: 0;
  animation: fadeUp .6s .2s both;
  box-shadow:
    0 0 0 1px rgba(255,215,0,.25),
    0 0 0 3px rgba(200,134,10,.15),
    0 28px 70px rgba(0,0,0,.55);
}

.hero-img-wrap img {
  width: 100%; height: 210px;
  object-fit: cover;
  object-position: center 60%;
  display: block;
  transition: transform 1s cubic-bezier(.25,.46,.45,.94);
  filter: brightness(.80) contrast(1.08) saturate(1.15);
}
.hero-img-wrap:hover img { transform: scale(1.07); }

.hero-overlay {
  position: absolute; inset: 0; pointer-events: none;
  background:
    linear-gradient(180deg,
      rgba(8,20,80,.55) 0%,
      rgba(11,36,114,.15) 30%,
      transparent 55%,
      rgba(0,0,0,.72) 100%);
}

.hero-shine {
  position: absolute; top: 0; left: 0; right: 0; height: 2px;
  background: linear-gradient(90deg, transparent, rgba(255,215,0,.7), transparent);
  pointer-events: none;
}

.hero-title {
  position: absolute; top: 14px; left: 16px;
  font-family: 'Syne', sans-serif; font-weight: 800;
  font-size: 15px; color: #fff;
  text-shadow: 0 2px 12px rgba(0,0,0,.6);
  line-height: 1.2; pointer-events: none;
}
.hero-title small {
  display: block; font-family: 'DM Sans', sans-serif;
  font-size: 9.5px; font-weight: 400;
  color: rgba(255,255,255,.65); letter-spacing: 1.5px;
  text-transform: uppercase; margin-bottom: 2px;
}

.hero-tag {
  position: absolute; top: 14px; right: 14px;
  background: linear-gradient(135deg, #FFD700 0%, #c8860a 100%);
  border-radius: 6px; padding: 4px 10px;
  font-family: 'Syne', sans-serif; font-size: 9px; font-weight: 800;
  color: #1a0a00; letter-spacing: 1.2px; text-transform: uppercase;
  box-shadow: 0 4px 16px rgba(200,134,10,.55);
  pointer-events: none;
}

.hero-bottom {
  position: absolute; bottom: 0; left: 0; right: 0;
  padding: 10px 14px 12px;
  display: flex; align-items: flex-end; justify-content: space-between; gap: 8px;
}
.img-badge {
  background: rgba(0,0,0,.5);
  backdrop-filter: blur(12px);
  border: 1px solid rgba(255,255,255,.18);
  border-radius: 40px; padding: 5px 12px 5px 9px;
  display: flex; align-items: center; gap: 7px;
}
.badge-dot {
  width: 7px; height: 7px; border-radius: 50%;
  background: #4ade80; box-shadow: 0 0 10px #4ade80;
  animation: pulse 2s ease-in-out infinite;
}
@keyframes pulse {
  0%,100%{ transform:scale(1); opacity:1; }
  50%    { transform:scale(1.6); opacity:.55; }
}
.badge-txt { font-size: 10.5px; font-weight: 500; color: rgba(255,255,255,.95); }

.hero-stats {
  display: flex; gap: 6px;
}
.hero-stat {
  background: rgba(255,255,255,.12);
  backdrop-filter: blur(10px);
  border: 1px solid rgba(255,215,0,.3);
  border-radius: 10px; padding: 5px 10px; text-align: center;
  min-width: 48px;
}
.hero-stat-num {
  font-family: 'Syne', sans-serif; font-weight: 800;
  font-size: 13px; color: #FFD700; line-height: 1;
}
.hero-stat-lbl { font-size: 8.5px; color: rgba(255,255,255,.6); margin-top: 1px; letter-spacing: .4px; }

.panel-divider {
  position: relative; z-index: 2;
  display: flex; align-items: center; gap: 10px;
  margin: 18px 0 12px;
}
.panel-divider span {
  font-size: 10px; font-weight: 600; letter-spacing: 2px;
  text-transform: uppercase; color: rgba(255,255,255,.4);
  white-space: nowrap;
}
.panel-divider::before, .panel-divider::after {
  content: ''; flex: 1; height: 1px;
  background: linear-gradient(90deg, transparent, rgba(255,255,255,.18), transparent);
}

.services-list {
  position: relative; z-index: 2;
  display: flex; flex-direction: column; gap: 8px;
  animation: fadeUp .6s .32s both;
  flex: 1; min-height: 0; overflow: visible;
}
.service-item {
  display: flex; align-items: center; gap: 13px;
  background: rgba(255,255,255,.07);
  border: 1px solid rgba(255,255,255,.11);
  border-radius: 16px; padding: 11px 14px;
  transition: all .3s cubic-bezier(.34,1.56,.64,1);
  cursor: default; position: relative; overflow: hidden;
}
.service-item::before {
  content: ''; position: absolute; left: 0; top: 0; bottom: 0;
  width: 3px; border-radius: 3px 0 0 3px;
  background: linear-gradient(180deg, #FFD700, #c8860a);
  transform: scaleY(0); transform-origin: center;
  transition: transform .25s ease;
}
.service-item:hover {
  background: rgba(255,255,255,.14);
  border-color: rgba(255,215,0,.28);
  transform: translateX(5px);
}
.service-item:hover::before { transform: scaleY(1); }
.service-icon {
  width: 38px; height: 38px; flex-shrink: 0;
  background: linear-gradient(135deg, rgba(255,255,255,.18), rgba(255,255,255,.06));
  border: 1px solid rgba(255,255,255,.18);
  border-radius: 12px;
  display: flex; align-items: center; justify-content: center;
  font-size: 17px;
}
.service-body { flex: 1; min-width: 0; }
.service-name {
  font-family: 'Syne', sans-serif; font-size: 12.5px; font-weight: 700;
  color: #fff; margin-bottom: 2px; letter-spacing: .1px;
}
.service-desc { font-size: 10px; color: rgba(255,255,255,.55); line-height: 1.3; }
.service-arrow {
  font-size: 16px; color: rgba(255,255,255,.25);
  transition: color .2s, transform .22s;
}
.service-item:hover .service-arrow { color: #FFD700; transform: translateX(4px); }

.trust-strip {
  position:relative; z-index:2;
  margin-top:12px;
  background: rgba(255,255,255,.08);
  border:1px solid rgba(255,255,255,.16);
  border-radius:40px;
  padding:8px 14px;
  display:flex; align-items:center; justify-content:center; gap:14px;
  animation: fadeUp .6s .44s both;
  flex-shrink:0;
  flex-wrap: wrap;
}
.trust-item {
  display:flex; align-items:center; gap:5px;
  font-size:10px; color:rgba(255,255,255,.8);
  font-weight:500;
}
.trust-item strong { color:#FFD700; }
.trust-sep { width:1px; height:16px; background:rgba(255,255,255,.2); }

/* ════════════════ RIGHT PANEL ════════════════ */
.panel-right {
  flex:1;
  padding:52px 44px;
  display:flex; flex-direction:column;
  justify-content:center; gap:24px;
}
.form-header { animation: fadeUp .6s .2s both; }
.form-header h3 {
  font-family:'Syne',sans-serif; font-weight:700;
  font-size:28px; color:var(--dark);
  margin-bottom:6px; letter-spacing:-.5px;
}
.form-header p { font-size:14px; color:var(--mid); }

.alert {
  padding:12px 16px; border-radius:13px;
  font-size:14px; font-weight:500;
  display:flex; align-items:center; gap:10px;
  animation: fadeUp .4s both;
}
.alert-error   { background:#fff1f1; color:var(--error);   border:1px solid #fccaca; }
.alert-success { background:#f0fdf8; color:var(--success); border:1px solid #a7f3d8; }

form { display:flex; flex-direction:column; gap:16px; animation: fadeUp .6s .35s both; }

.field { position:relative; }
.field label {
  display:block; font-size:11.5px; font-weight:500;
  color:var(--mid); margin-bottom:7px;
  text-transform:uppercase; letter-spacing:.7px;
}
.field .icon {
  position:absolute; bottom:13px; left:15px;
  font-size:16px; color:#c8ad82; pointer-events:none; transition:color .2s;
}
.field input {
  width:100%; padding:14px 16px 14px 44px;
  border:1.5px solid #edd9b0; border-radius:13px;
  font-size:15px; font-family:'DM Sans',sans-serif;
  color:var(--dark); background:rgba(255,248,230,.5);
  outline:none;
  transition:border-color .22s, box-shadow .22s, background .22s;
}
.field input::placeholder { color:#c8b48a; }
.field input:focus {
  border-color:var(--gold); background:#fff;
  box-shadow:0 0 0 4px rgba(200,134,10,.12);
}
.field:has(input:focus) .icon { color:var(--gold); }

.forgot-inline {
  position:absolute; bottom:14px; right:15px;
  font-size:12px; color:var(--gold); font-weight:500;
  text-decoration:none; transition:opacity .2s;
}
.forgot-inline:hover { opacity:.7; }
.field input[type="password"] { padding-right:80px; }

.btn-submit {
  padding:15px; border:none; border-radius:13px;
  font-family:'Syne',sans-serif; font-size:16px; font-weight:700;
  color:#fff;
  background: linear-gradient(115deg, #3d1f02 0%, #c8860a 60%, #e8a220 100%);
  cursor:pointer; letter-spacing:.2px; margin-top:2px;
  transition:transform .15s, box-shadow .22s;
  box-shadow:0 8px 28px rgba(200,134,10,.38);
  position:relative; overflow:hidden;
}
.btn-submit::before {
  content:''; position:absolute; inset:0;
  background: linear-gradient(115deg, transparent, rgba(255,255,255,.14));
  opacity:0; transition:opacity .2s;
}
.btn-submit:hover { transform:translateY(-2px); box-shadow:0 12px 36px rgba(200,134,10,.48); }
.btn-submit:hover::before { opacity:1; }
.btn-submit:active { transform:translateY(0); }

.or-row { display:flex; align-items:center; gap:12px; animation: fadeUp .6s .45s both; }
.or-row span { font-size:12px; color:#c8ad82; white-space:nowrap; }
.or-line { flex:1; height:1px; background:linear-gradient(90deg,transparent,#edd9b0,transparent); }

.register-cta { text-align:center; animation: fadeUp .6s .5s both; }
.register-cta a {
  font-size:13.5px; color:var(--mid); text-decoration:none; transition:color .2s;
}
.register-cta a span { color:var(--gold); font-weight:600; }
.register-cta a:hover { color:var(--gold); }

/* Bouton retour accueil */
.back-home-btn {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  background: rgba(200,134,10,0.1);
  padding: 10px 18px;
  border-radius: 40px;
  text-decoration: none;
  color: #c8860a;
  font-size: 13px;
  font-weight: 600;
  transition: all 0.2s ease;
  width: fit-content;
  margin-bottom: 10px;
}
.back-home-btn:hover {
  background: rgba(200,134,10,0.2);
  transform: translateX(-3px);
}

@keyframes fadeUp {
  from { opacity:0; transform:translateY(18px); }
  to   { opacity:1; transform:translateY(0); }
}

@media (max-width:720px) {
  body { padding: 16px; align-items: flex-start; }
  .panel-left { display:none; }
  .panel-right { padding:40px 28px; }
}

@media (max-height:700px) {
  .panel-left { padding: 24px 30px; }
  .hero-img-wrap img { height: 130px; }
  .services-list { gap: 7px; }
  .service-item { padding: 8px 12px; }
  .trust-strip { margin-top: 8px; padding: 6px 12px; }
}
</style>
</head>
<body>

<div class="bg">
  <div class="blob blob-1"></div>
  <div class="blob blob-2"></div>
  <div class="blob blob-3"></div>
  <div class="blob blob-4"></div>
</div>

<div class="card">

  <!-- ══════════ LEFT PANEL ══════════ -->
  <div class="panel-left">
    <div class="orb orb-1"></div>
    <div class="orb orb-2"></div>

    <!-- LOGO -->
    <div class="logo-wrap">
      <img src="${pageContext.request.contextPath}/immo/admin/images/Logo.jpg"
           alt="Fredon Immobilier"
           class="logo-mark"
           onerror="this.style.display='none'">
      <div class="logo-text">
        <span class="logo-name">Fredon</span>
        <span class="logo-sub">Agence Immobilière</span>
      </div>
    </div>

    <!-- IMAGE HERO PREMIUM -->
    <div class="hero-img-wrap">
      <img src="${pageContext.request.contextPath}/immo/admin/images/maison.png"
           alt="Fredon Immobilier — biens à Mahajanga"
           onerror="this.src='https://placehold.co/520x210/0b2472/ffffff?text=Fredon+Immobilier'">
      <div class="hero-overlay"></div>
      <div class="hero-shine"></div>
      <div class="hero-bottom">
        <div class="img-badge">
          <div class="badge-dot"></div>
          <span class="badge-txt">De nombreux biens disponibles</span>
        </div>
      </div>
    </div>

    <!-- SERVICES -->
    <div class="services-list">

      <div class="service-item">
        <div class="service-icon">🏗️</div>
        <div class="service-body">
          <div class="service-name">Vente de terrains et maisons</div>
        </div>
        <span class="service-arrow">›</span>
      </div>

      <div class="service-item">
        <div class="service-icon">🔑</div>
        <div class="service-body">
          <div class="service-name">Location des maisons</div>
        </div>
        <span class="service-arrow">›</span>
      </div>

      <div class="service-item">
        <div class="service-icon">⚖️</div>
        <div class="service-body">
          <div class="service-name">Conseils juridiques</div>
        </div>
        <span class="service-arrow">›</span>
      </div>

      <div class="service-item">
        <div class="service-icon">📋</div>
        <div class="service-body">
          <div class="service-name">Suivi des dossiers</div>
        </div>
        <span class="service-arrow">›</span>
      </div>

    </div>

    <!-- TRUST STRIP -->
    <div class="trust-strip">
      <div class="trust-item">🛡️ <strong>Agréé</strong> depuis 2010</div>
      <div class="trust-sep"></div>
      <div class="trust-item">🏆 <strong>+500</strong> transactions</div>
      <div class="trust-sep"></div>
      <div class="trust-item">⭐ <strong>1000+</strong> clients</div>
    </div>
  </div>

  <!-- ══════════ RIGHT PANEL ══════════ -->
  <div class="panel-right">

    <!-- BOUTON RETOUR ACCUEIL (AJOUTÉ) -->
    <a href="${pageContext.request.contextPath}/home" class="back-home-btn">
        ← Retour à l'accueil
    </a>

    <div class="form-header">
      <h3>Bon retour 👋</h3>
      <p>Connectez-vous avec votre email pour accéder à votre espace</p>
    </div>

    <% if (request.getParameter("error") != null) { %>
    <div class="alert alert-error">⚠️ <%= request.getParameter("error") %></div>
    <% } %>
    <% if (request.getParameter("success") != null) { %>
    <div class="alert alert-success">✅ <%= request.getParameter("success") %></div>
    <% } %>

    <form action="${pageContext.request.contextPath}/login" method="post">
      <div class="field">
        <label for="email">Adresse email</label>
        <input type="email" id="email" name="email"
               placeholder="ex : jean.dupont@email.com" required>
        <span class="icon">✉️</span>
      </div>

      <div class="field">
        <label for="password">Mot de passe</label>
        <input type="password" id="password" name="password"
               placeholder="••••••••" required>
        <span class="icon">🔒</span>
        <a href="${pageContext.request.contextPath}/forgot-password" class="forgot-inline">Oublié ?</a>
      </div>

      <button type="submit" class="btn-submit">Se connecter →</button>
    </form>

    <div class="or-row">
      <div class="or-line"></div>
      <span>Pas encore membre ?</span>
      <div class="or-line"></div>
    </div>

    <div class="register-cta">
      <a href="${pageContext.request.contextPath}/register">Créer un compte gratuitement <span>→</span></a>
    </div>

  </div>
</div>

</body>
</html>