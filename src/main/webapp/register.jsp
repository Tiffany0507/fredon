<%@ page language="java" contentType="text/html; charset=UTF-8"
	pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>Fredon Immobilier — Inscription</title>
<link
	href="https://fonts.googleapis.com/css2?family=Syne:wght@400;600;700;800&family=DM+Sans:ital,wght@0,300;0,400;0,500;1,300&display=swap"
	rel="stylesheet">
<style>
*, *::before, *::after {
	box-sizing: border-box;
	margin: 0;
	padding: 0;
}

:root {
	--accent: #c8860a;
	--accent2: #e8a220;
	--dark: #1a1208;
	--mid: #6b5a3e;
	--light: #fdf8ee;
	--white: #ffffff;
	--error: #f04040;
	--success: #15b87a;
	--shadow: 0 24px 80px rgba(200, 134, 10, .15), 0 4px 24px rgba(0, 0, 0, .07);
}

html, body {
	font-family: 'DM Sans', sans-serif;
}

body {
	display: flex;
	align-items: center;
	justify-content: center;
	min-height: 100vh;
	padding: 24px 16px;
	position: relative;
}

/* ── Background blobs ── */
.bg {
	position: fixed;
	inset: 0;
	z-index: 0;
	background: linear-gradient(135deg, #fdf8ee 0%, #fef5e0 40%, #fff9f0 70%, #fdf4e3 100%);
}

.blob {
	position: absolute;
	border-radius: 50%;
	filter: blur(72px);
	opacity: .45;
	animation: drift 14s ease-in-out infinite alternate;
}

.blob-1 { width:520px; height:520px; background:#f5dfa0; top:-120px; left:-100px; animation-delay:0s; }
.blob-2 { width:400px; height:400px; background:#d4e8c2; bottom:-80px; right:10%; animation-delay:-4s; }
.blob-3 { width:300px; height:300px; background:#f8cda0; top:30%; right:-60px; animation-delay:-8s; }
.blob-4 { width:250px; height:250px; background:#e8d5b0; bottom:10%; left:20%; animation-delay:-2s; }

@keyframes drift {
	0%   { transform: translate(0,0) scale(1); }
	100% { transform: translate(30px,20px) scale(1.08); }
}

/* ── Card ── */
.card {
	position: relative;
	z-index: 1;
	display: flex;
	width: min(960px, 95vw);
	background: rgba(255,255,255,.72);
	backdrop-filter: blur(28px) saturate(160%);
	-webkit-backdrop-filter: blur(28px) saturate(160%);
	border-radius: 28px;
	box-shadow: var(--shadow);
	border: 1px solid rgba(255,255,255,.88);
	overflow: hidden;
	animation: cardIn .7s cubic-bezier(.22,.97,.48,1) both;
}

@keyframes cardIn {
	from { opacity:0; transform: translateY(32px) scale(.97); }
	to   { opacity:1; transform: translateY(0) scale(1); }
}

/* ── Left panel ── */
.panel-left {
	flex: 0 0 300px;
	background: linear-gradient(160deg, #0e2d82 0%, #1f52d4 40%, #2a3fa8 70%, #c8a020 100%);
	padding: 52px 40px;
	display: flex;
	flex-direction: column;
	justify-content: space-between;
	position: relative;
	overflow: hidden;
}

.panel-left::before {
	content: '';
	position: absolute;
	width: 340px; height: 340px;
	background: rgba(255,210,80,.08);
	border-radius: 50%;
	top: -100px; right: -100px;
}

.panel-left::after {
	content: '';
	position: absolute;
	width: 200px; height: 200px;
	background: rgba(100,160,255,.1);
	border-radius: 50%;
	bottom: -50px; left: -50px;
}

/* ── LOGO ── */
.brand {
	display: flex;
	align-items: center;
	gap: 14px;
	position: relative;
	z-index: 2;
	animation: fadeUp .6s .1s both;
}

.logo-mark-small {
	width: 54px; height: 54px;
	flex-shrink: 0;
	object-fit: cover;
	border-radius: 14px;
	box-shadow: 0 6px 20px rgba(0,0,0,.35);
	transition: transform .3s ease;
	background: rgba(255,255,255,.15);
}

.logo-mark-small:hover { transform: scale(1.05); }

.brand-text {
	display: flex;
	flex-direction: column;
	line-height: 1.1;
}

.brand-name {
	font-family: 'Syne', sans-serif;
	font-weight: 800;
	font-size: 26px;
	background: linear-gradient(135deg, #ffffff 0%, #fde9b0 100%);
	-webkit-background-clip: text;
	background-clip: text;
	color: transparent;
	letter-spacing: -.5px;
	line-height: 1.2;
	padding: 2px 0;
}

.brand-tagline {
	font-size: 9px;
	font-weight: 500;
	color: rgba(255,255,255,.6);
	letter-spacing: 1.5px;
	text-transform: uppercase;
	margin-top: 2px;
}

.panel-tagline {
	animation: fadeUp .6s .3s both;
	margin-top: auto;
}

.panel-tagline h2 {
	font-family: 'Syne', sans-serif;
	font-weight: 700;
	font-size: clamp(20px, 2.4vw, 25px);
	color: #fff;
	line-height: 1.28;
	margin-bottom: 14px;
}

.panel-tagline p {
	font-size: 14px;
	color: rgba(255,255,255,.7);
	line-height: 1.65;
	font-weight: 300;
}

/* Steps indicator */
.steps {
	display: flex;
	flex-direction: column;
	gap: 14px;
	margin-top: 40px;
	animation: fadeUp .6s .45s both;
}

.step {
	display: flex;
	align-items: center;
	gap: 12px;
}

.step-dot {
	width: 28px; height: 28px;
	border-radius: 50%;
	background: rgba(255,255,255,.12);
	border: 1.5px solid rgba(255,255,255,.25);
	display: flex; align-items: center; justify-content: center;
	font-size: 12px;
	color: rgba(255,255,255,.75);
	font-family: 'Syne', sans-serif;
	font-weight: 700;
	flex-shrink: 0;
}

.step-dot.active {
	background: rgba(255,255,255,.95);
	color: #c8860a;
	border-color: transparent;
	box-shadow: 0 0 0 4px rgba(255,255,255,.18);
}

.step-label { font-size: 13px; color: rgba(255,255,255,.6); font-weight: 400; }
.step-label.active { color: #fff; font-weight: 500; }

/* ── Right panel ── */
.panel-right {
	flex: 1;
	padding: 44px 48px;
	display: flex;
	flex-direction: column;
	justify-content: center;
	gap: 20px;
}

.form-header { animation: fadeUp .6s .2s both; }
.form-header h3 {
	font-family: 'Syne', sans-serif;
	font-weight: 700;
	font-size: 26px;
	color: var(--dark);
	margin-bottom: 5px;
	letter-spacing: -.4px;
}
.form-header p { font-size: 14px; color: var(--mid); }

/* ── Alert ── */
.alert {
	padding: 12px 16px;
	border-radius: 12px;
	font-size: 14px;
	font-weight: 500;
	display: flex;
	align-items: center;
	gap: 10px;
	animation: fadeUp .4s both;
}
.alert-error { background: #fff1f1; color: var(--error); border: 1px solid #fccaca; }

/* ── Form grid ── */
form { animation: fadeUp .6s .35s both; }

.form-grid {
	display: grid;
	grid-template-columns: 1fr 1fr;
	gap: 14px 18px;
	margin-bottom: 14px;
}

.field { position: relative; }
.field.full { grid-column: 1/-1; }

.field label {
	display: block;
	font-size: 11.5px;
	font-weight: 500;
	color: var(--mid);
	margin-bottom: 7px;
	text-transform: uppercase;
	letter-spacing: .6px;
}

.field .icon {
	position: absolute;
	bottom: 13px; left: 15px;
	font-size: 15px;
	color: #c8ad82;
	pointer-events: none;
	transition: color .2s;
}

.field input {
	width: 100%;
	padding: 13px 16px 13px 42px;
	border: 1.5px solid #edd9b0;
	border-radius: 12px;
	font-size: 14.5px;
	font-family: 'DM Sans', sans-serif;
	color: var(--dark);
	background: rgba(255,248,230,.5);
	outline: none;
	transition: border-color .2s, box-shadow .2s, background .2s;
}
.field input::placeholder { color: #c8b48a; }
.field input:focus {
	border-color: var(--accent);
	background: #fff;
	box-shadow: 0 0 0 4px rgba(200,134,10,.12);
}
.field:has(input:focus) .icon { color: var(--accent); }

/* Password strength */
.strength-bar {
	display: flex;
	gap: 4px;
	margin-top: 8px;
}
.strength-bar span {
	flex: 1; height: 3px;
	border-radius: 99px;
	background: #edd9b0;
	transition: background .3s;
}
.strength-label {
	font-size: 11px;
	color: var(--mid);
	margin-top: 5px;
	min-height: 15px;
	transition: color .3s;
}

/* ── Confirm password feedback ── */
.confirm-msg {
	font-size: 11px;
	margin-top: 6px;
	min-height: 15px;
	display: flex;
	align-items: center;
	gap: 5px;
	transition: color .25s;
}
.confirm-msg.ok    { color: #15b87a; }
.confirm-msg.error { color: #f04040; }

.field input.input-ok    { border-color: #15b87a; box-shadow: 0 0 0 3px rgba(21,184,122,.12); }
.field input.input-error { border-color: #f04040; box-shadow: 0 0 0 3px rgba(240,64,64,.10); }

/* ── Submit ── */
.btn-submit {
	width: 100%;
	padding: 15px;
	border: none;
	border-radius: 12px;
	font-family: 'Syne', sans-serif;
	font-size: 16px;
	font-weight: 700;
	color: #fff;
	background: linear-gradient(120deg, #3d1f02 0%, #c8860a 60%, #e8a220 100%);
	cursor: pointer;
	letter-spacing: .2px;
	transition: transform .15s, box-shadow .2s, filter .2s, opacity .25s, background .25s;
	box-shadow: 0 6px 24px rgba(200,134,10,.38);
	position: relative;
	overflow: hidden;
	margin-top: 2px;
}
.btn-submit::after {
	content: '';
	position: absolute; inset: 0;
	background: linear-gradient(120deg, rgba(255,255,255,.15), transparent);
	opacity: 0;
	transition: opacity .2s;
}
.btn-submit:not(:disabled):hover { transform: translateY(-2px); box-shadow: 0 10px 32px rgba(200,134,10,.48); filter: brightness(1.07); }
.btn-submit:not(:disabled):hover::after { opacity: 1; }
.btn-submit:not(:disabled):active { transform: translateY(0); }

/* État désactivé */
.btn-submit:disabled {
	background: linear-gradient(120deg, #c8b89a, #d4c4a0);
	box-shadow: none;
	cursor: not-allowed;
	opacity: .65;
	transform: none !important;
	filter: none !important;
}

/* ── Links ── */
.links { text-align: center; animation: fadeUp .6s .5s both; }
.links a { font-size: 13.5px; color: var(--mid); text-decoration: none; transition: color .2s; }
.links a span { color: var(--accent); font-weight: 500; }
.links a:hover { color: var(--accent); }

/* ── Terms ── */
.terms { font-size: 12px; color: #b0956a; text-align: center; animation: fadeUp .6s .55s both; }
.terms a { color: var(--accent); text-decoration: none; }

@keyframes fadeUp {
	from { opacity:0; transform: translateY(16px); }
	to   { opacity:1; transform: translateY(0); }
}

/* ── Responsive ── */
@media (max-width: 700px) {
	.panel-left { display: none; }
	.panel-right { padding: 40px 28px; }
	.form-grid { grid-template-columns: 1fr; }
	.field.full { grid-column: 1; }
}

@media (max-height: 750px) {
	.panel-right { padding: 28px 40px; gap: 14px; }
	.panel-left  { padding: 32px 36px; }
	.form-grid   { gap: 10px 18px; margin-bottom: 10px; }
	.field input { padding-top: 10px; padding-bottom: 10px; }
	.btn-submit  { padding: 12px; }
	.panel-tagline h2 { font-size: 18px; }
	.steps { margin-top: 24px; gap: 10px; }
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

  <!-- ════ LEFT PANEL ════ -->
  <div class="panel-left">

    <!-- LOGO FREDON — même image que login.jsp -->
    <div class="brand">
      <img src="<%= request.getContextPath() %>/immo/admin/images/Logo.jpg"
           alt="Fredon Immobilier"
           class="logo-mark-small"
           onerror="this.style.display='none'">
      <div class="brand-text">
        <span class="brand-name">Fredon</span>
        <span class="brand-tagline">Agence Immobilière</span>
      </div>
    </div>

    <div class="panel-tagline">
      <h2>Trouvez votre<br>bien idéal.</h2>
      <p>Créez votre espace client et accédez à nos 248 biens disponibles, nos agents et nos visites en ligne.</p>
    </div>

    <div class="steps">
      <div class="step">
        <div class="step-dot active">1</div>
        <span class="step-label active">Créer votre compte</span>
      </div>
      <div class="step">
        <div class="step-dot">2</div>
        <span class="step-label">Définir vos critères</span>
      </div>
      <div class="step">
        <div class="step-dot">3</div>
        <span class="step-label">Contacter un agent</span>
      </div>
    </div>
  </div>

  <!-- ════ RIGHT PANEL ════ -->
  <div class="panel-right">

    <div class="form-header">
      <h3>Créer un compte 🏠</h3>
      <p>Remplissez les champs ci-dessous pour commencer</p>
    </div>

    <% if (request.getParameter("error") != null) { %>
    <div class="alert alert-error">⚠️ <%= request.getParameter("error") %></div>
    <% } %>

    <form action="register" method="post">
      <div class="form-grid">

        <div class="field">
          <label for="username">Nom d'utilisateur</label>
          <input type="text" id="username" name="username" placeholder="jean_dupont" required>
          <span class="icon">👤</span>
        </div>

        <div class="field">
          <label for="fullName">Nom complet</label>
          <input type="text" id="fullName" name="fullName" placeholder="Jean Dupont" required>
          <span class="icon">🪪</span>
        </div>

        <div class="field full">
          <label for="email">Adresse e-mail</label>
          <input type="email" id="email" name="email" placeholder="jean@exemple.com" required>
          <span class="icon">✉️</span>
        </div>

        <div class="field full">
          <label for="password">Mot de passe</label>
          <input type="password" id="password" name="password"
                 placeholder="Min. 8 caractères" required
                 oninput="checkStrength(this.value); checkMatch()">
          <span class="icon">🔒</span>
          <div class="strength-bar">
            <span id="s1"></span>
            <span id="s2"></span>
            <span id="s3"></span>
            <span id="s4"></span>
          </div>
          <div class="strength-label" id="strength-label"></div>
        </div>

        <div class="field full">
          <label for="confirm">Confirmer le mot de passe</label>
          <input type="password" id="confirm" name="confirm"
                 placeholder="Répétez votre mot de passe" required
                 oninput="checkMatch()">
          <span class="icon">🔐</span>
          <div class="confirm-msg" id="confirm-msg"></div>
        </div>

      </div>

      <button type="submit" class="btn-submit" id="submitBtn" disabled>Créer mon compte →</button>
    </form>

    <div class="links">
      <a href="login.jsp">Déjà un compte ? <span>Se connecter</span></a>
    </div>

    <div class="terms">
      En vous inscrivant, vous acceptez nos <a href="#">Conditions d'utilisation</a>
      et notre <a href="#">Politique de confidentialité</a>.
    </div>

  </div>
</div>

<script>
  const fields = ['username', 'fullName', 'email', 'password', 'confirm'];

  /* Écoute tous les champs pour activer/désactiver le bouton */
  fields.forEach(id => {
    document.getElementById(id).addEventListener('input', updateBtn);
  });

  function checkStrength(val) {
    const bars   = ['s1','s2','s3','s4'].map(id => document.getElementById(id));
    const label  = document.getElementById('strength-label');
    const colors = ['#f04040','#f59e0b','#c8860a','#15b87a'];
    const labels = ['Très faible','Moyen','Fort','Très fort'];

    let score = 0;
    if (val.length >= 8)           score++;
    if (/[A-Z]/.test(val))         score++;
    if (/[0-9]/.test(val))         score++;
    if (/[^A-Za-z0-9]/.test(val))  score++;

    bars.forEach((b, i) => {
      b.style.background = i < score ? colors[score - 1] : '#edd9b0';
    });

    label.textContent = val.length ? (labels[score - 1] || '') : '';
    label.style.color = score ? colors[score - 1] : '#b0956a';
  }

  function checkMatch() {
    const pwd     = document.getElementById('password').value;
    const conf    = document.getElementById('confirm').value;
    const confInput = document.getElementById('confirm');
    const msg     = document.getElementById('confirm-msg');

    confInput.classList.remove('input-ok', 'input-error');
    msg.classList.remove('ok', 'error');

    if (!conf) {
      msg.textContent = '';
      updateBtn();
      return;
    }

    if (pwd === conf) {
      confInput.classList.add('input-ok');
      msg.classList.add('ok');
      msg.textContent = '✓ Les mots de passe correspondent';
    } else {
      confInput.classList.add('input-error');
      msg.classList.add('error');
      msg.textContent = '✗ Les mots de passe ne correspondent pas';
    }
    updateBtn();
  }

  function updateBtn() {
    const pwd  = document.getElementById('password').value;
    const conf = document.getElementById('confirm').value;
    const allFilled = fields.every(id => document.getElementById(id).value.trim() !== '');
    const match = pwd === conf && conf !== '';

    document.getElementById('submitBtn').disabled = !(allFilled && match);
  }

  /* Bloquer la soumission si les mots de passe diffèrent (sécurité supplémentaire) */
  document.querySelector('form').addEventListener('submit', function(e) {
    const pwd  = document.getElementById('password').value;
    const conf = document.getElementById('confirm').value;
    if (pwd !== conf) { e.preventDefault(); }
  });
</script>

</body>
</html>
