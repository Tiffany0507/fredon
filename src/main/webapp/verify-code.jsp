<%@ page language="java" contentType="text/html; charset=UTF-8"
	pageEncoding="UTF-8"%>
<%
HttpSession sess = request.getSession(false);
System.out.println("=== verify-code.jsp ===");
System.out.println("Session ID: " + (sess != null ? sess.getId() : "NULL"));

if (sess == null) {
    response.sendRedirect("forgot-password.jsp?error=Session expirée, recommencez");
    return;
}

Integer resetUserId  = (Integer) sess.getAttribute("resetUserId");
Integer resetAdminId = (Integer) sess.getAttribute("resetAdminId");
String  resetEmail   = (String)  sess.getAttribute("resetEmail");
Boolean isAdminReset = (Boolean) sess.getAttribute("isAdminReset");

if (resetUserId == null && resetAdminId == null) {
    response.sendRedirect("forgot-password.jsp?error=Session expirée, recommencez");
    return;
}
%>
<!DOCTYPE html>
<html lang="fr">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0, user-scalable=yes">
<title>Fredon Immobilier — Vérification du code</title>
<link
	href="https://fonts.googleapis.com/css2?family=Syne:wght@400;600;700;800&family=DM+Sans:ital,opsz,wght@0,9..40,300;0,9..40,400;0,9..40,500;1,9..40,300&display=swap"
	rel="stylesheet">
<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css">
<style>
*, *::before, *::after {
	box-sizing: border-box;
	margin: 0;
	padding: 0;
}

:root {
	--gold: #c8860a;
	--gold-light: #e8a220;
	--gold-pale: #fff3d4;
	--blue: #1f52d4;
	--blue-light: #4f7ef8;
	--blue-pale: #e8eeff;
	--teal: #0e9e8a;
	--teal-light: #2ecfb4;
	--teal-pale: #e0faf5;
	--rose: #e03060;
	--dark: #0d0b08;
	--mid: #6b5a3e;
	--soft: #a89880;
	--error: #ef4444;
	--success: #10b981;
	--shadow: 0 32px 100px rgba(200, 134, 10, .13), 0 4px 28px
		rgba(0, 0, 0, .07);
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
	padding: 20px;
	background: linear-gradient(135deg, #fdf8ee 0%, #fef5e0 40%, #fff9f0 70%, #fdf4e3 100%);
	position: relative;
}

/* ── ANIMATED BACKGROUND ── */
.bg-animation {
	position: fixed;
	inset: 0;
	z-index: 0;
	overflow: hidden;
}

.blob {
	position: absolute;
	border-radius: 50%;
	filter: blur(80px);
	opacity: .42;
	animation: drift 16s ease-in-out infinite alternate;
}

.blob-1 {
	width: 580px;
	height: 580px;
	background: #f5dfa0;
	top: -180px;
	left: -140px;
	animation-delay: 0s;
}

.blob-2 {
	width: 440px;
	height: 440px;
	background: #d4e8c2;
	bottom: -100px;
	right: 5%;
	animation-delay: -5s;
}

.blob-3 {
	width: 310px;
	height: 310px;
	background: #f8cda0;
	top: 25%;
	right: -70px;
	animation-delay: -10s;
}

.blob-4 {
	width: 270px;
	height: 270px;
	background: #c8d8f8;
	bottom: 8%;
	left: 18%;
	animation-delay: -3s;
}

@keyframes drift {
	0% { transform: translate(0, 0) scale(1); }
	100% { transform: translate(26px, 18px) scale(1.09); }
}

#bgCanvas {
	position: fixed;
	inset: 0;
	z-index: 0;
	pointer-events: none;
	opacity: .045;
}

/* ── CARD ── */
.card {
	position: relative;
	z-index: 1;
	display: flex;
	max-width: 1100px;
	width: 100%;
	background: rgba(255, 255, 255, .85);
	backdrop-filter: blur(28px) saturate(180%);
	border-radius: 48px;
	box-shadow: var(--shadow);
	border: 1px solid rgba(255, 255, 255, .9);
	overflow: hidden;
	animation: cardIn .7s cubic-bezier(.22, .97, .45, 1) both;
}

@keyframes cardIn {
	from { opacity: 0; transform: translateY(40px) scale(.96); }
	to { opacity: 1; transform: translateY(0) scale(1); }
}

/* ════════════════ LEFT PANEL ════════════════ */
.panel-left {
	flex: 1.1;
	background: linear-gradient(148deg, #0e2d82 0%, #1f52d4 40%, #2a3fa8 70%, #c8a020 100%);
	padding: 40px 36px;
	display: flex;
	flex-direction: column;
	position: relative;
	overflow-y: auto;
	max-height: 90vh;
}

.panel-left::-webkit-scrollbar { width: 3px; }
.panel-left::-webkit-scrollbar-thumb { background: rgba(255,255,255,0.3); border-radius: 10px; }

.panel-left::before {
	content: '';
	position: absolute;
	inset: 0;
	background-image: linear-gradient(rgba(255, 255, 255, .03) 1px, transparent 1px),
	                  linear-gradient(90deg, rgba(255, 255, 255, .03) 1px, transparent 1px);
	background-size: 44px 44px;
	pointer-events: none;
}

.orb {
	position: absolute;
	border-radius: 50%;
	pointer-events: none;
}

.orb-1 {
	width: 300px;
	height: 300px;
	background: radial-gradient(circle, rgba(255, 210, 80, .16) 0%, transparent 70%);
	top: -70px;
	right: -60px;
}

.orb-2 {
	width: 220px;
	height: 220px;
	background: radial-gradient(circle, rgba(100, 160, 255, .2) 0%, transparent 70%);
	bottom: 30px;
	left: -50px;
}

/* ── LOGO AVEC IMAGE REELLE ── */
.logo-wrap {
	display: flex;
	align-items: center;
	gap: 14px;
	animation: fadeUp .6s .1s both;
	position: relative;
	z-index: 2;
	margin-bottom: 20px;
	flex-shrink: 0;
}

.logo-img {
	width: 56px;
	height: 56px;
	object-fit: cover;
	border-radius: 14px;
	filter: drop-shadow(0 6px 18px rgba(0, 0, 0, .35));
	transition: transform .3s;
	border: 2px solid rgba(255,255,255,0.2);
}

.logo-img:hover { transform: scale(1.05); }

.logo-text {
	display: flex;
	flex-direction: column;
	line-height: 1;
}

.logo-name {
	font-family: 'Syne', sans-serif;
	font-weight: 800;
	font-size: 26px;
	background: linear-gradient(135deg, #fff 0%, #fde9b0 100%);
	-webkit-background-clip: text;
	background-clip: text;
	color: transparent;
	letter-spacing: -.3px;
}

.logo-tagline {
	font-size: 10px;
	font-weight: 400;
	color: rgba(255, 255, 255, .5);
	letter-spacing: 2px;
	text-transform: uppercase;
	margin-top: 3px;
}

/* ── SCENE ── */
.scene {
	flex: 0 0 auto;
	display: flex;
	align-items: center;
	justify-content: center;
	position: relative;
	z-index: 2;
	margin: 20px 0;
}

.prop-card {
	width: 190px;
	background: rgba(255, 255, 255, .13);
	border: 1.5px solid rgba(255, 255, 255, .25);
	border-radius: 20px;
	overflow: hidden;
	box-shadow: 0 28px 56px rgba(0, 0, 0, .28);
	animation: cardFloat 4.5s ease-in-out infinite;
}

@keyframes cardFloat {
	0%,100% { transform: translateY(0) rotate(-1.5deg); }
	50% { transform: translateY(-12px) rotate(-1.5deg); }
}

.house-thumb {
	width: 100%;
	height: 110px;
	background: linear-gradient(160deg, #87CEEB 0%, #5BA3C9 60%, #3d8aa8 100%);
	position: relative;
	overflow: hidden;
}

.sun {
	position: absolute;
	top: 10px;
	right: 16px;
	width: 26px;
	height: 26px;
	background: #FFD700;
	border-radius: 50%;
	box-shadow: 0 0 16px #FFD700;
	animation: sunPulse 3s ease-in-out infinite;
}

@keyframes sunPulse {
	0%,100% { box-shadow: 0 0 16px #FFD700; }
	50% { box-shadow: 0 0 28px #FFD700; }
}

.cloud {
	position: absolute;
	background: rgba(255, 255, 255, .7);
	border-radius: 50px;
	animation: cloudDrift linear infinite;
}

.cloud::before, .cloud::after {
	content: '';
	position: absolute;
	background: rgba(255, 255, 255, .7);
	border-radius: 50%;
}

.cloud-1 {
	width: 36px;
	height: 11px;
	top: 20px;
	left: 10px;
	animation-duration: 12s;
}

.cloud-1::before {
	width: 18px;
	height: 18px;
	top: -9px;
	left: 4px;
}

.cloud-1::after {
	width: 13px;
	height: 13px;
	top: -6px;
	left: 14px;
}

.cloud-2 {
	width: 25px;
	height: 8px;
	top: 12px;
	left: 60px;
	opacity: .55;
	animation-duration: 18s;
	animation-delay: -6s;
}

.cloud-2::before {
	width: 13px;
	height: 13px;
	top: -6px;
	left: 3px;
}

@keyframes cloudDrift {
	0% { transform: translateX(0); }
	100% { transform: translateX(180px); opacity: 0; }
}

.house-svg {
	position: absolute;
	bottom: 0;
	left: 50%;
	transform: translateX(-50%);
	width: 124px;
	height: 84px;
}

.prop-info {
	padding: 12px 13px 13px;
}

.prop-price {
	font-family: 'Syne', sans-serif;
	font-size: 15px;
	font-weight: 700;
	color: #FFD700;
	margin-bottom: 3px;
}

.prop-title {
	font-size: 10px;
	font-weight: 500;
	color: rgba(255, 255, 255, .9);
	margin-bottom: 5px;
}

.prop-tags {
	display: flex;
	gap: 4px;
	flex-wrap: wrap;
}

.tag {
	font-size: 8.5px;
	font-weight: 500;
	padding: 2px 6px;
	border-radius: 99px;
	color: rgba(255, 255, 255, .85);
	border: 1px solid rgba(255, 255, 255, .2);
	background: rgba(255, 255, 255, .1);
}

/* ── MINI CARDS ── */
.mini-card {
	position: absolute;
	background: rgba(255, 255, 255, .15);
	border: 1.5px solid rgba(255, 255, 255, .28);
	border-radius: 14px;
	padding: 9px 12px;
	backdrop-filter: blur(8px);
	animation: miniFloat ease-in-out infinite;
}

.mini-card-1 {
	top: 8%;
	right: -8px;
	animation-duration: 5s;
	animation-delay: -.5s;
}

.mini-card-2 {
	bottom: 12%;
	left: -8px;
	animation-duration: 6s;
	animation-delay: -2s;
}

@keyframes miniFloat {
	0%,100% { transform: translateY(0); }
	50% { transform: translateY(-8px); }
}

.mini-label {
	font-size: 8.5px;
	color: rgba(255, 255, 255, .55);
	margin-bottom: 2px;
	text-transform: uppercase;
	letter-spacing: 1px;
}

.mini-value {
	font-family: 'Syne', sans-serif;
	font-size: 13px;
	font-weight: 700;
	color: #fff;
}

.mini-sub {
	font-size: 8.5px;
	color: rgba(255, 255, 255, .55);
	margin-top: 1px;
}

/* ── STEPS VERTICAUX ── */
.steps-vertical {
	display: flex;
	flex-direction: column;
	gap: 0;
	position: relative;
	z-index: 2;
	animation: fadeUp .6s .3s both;
	margin-top: 15px;
	flex-shrink: 0;
}

.step-v {
	display: flex;
	align-items: flex-start;
	gap: 14px;
	position: relative;
}

.step-v:not(:last-child)::after {
	content: '';
	position: absolute;
	left: 16px;
	top: 38px;
	width: 2px;
	height: 30px;
	background: rgba(255, 255, 255, .18);
}

.step-v-circle {
	width: 34px;
	height: 34px;
	border-radius: 50%;
	flex-shrink: 0;
	display: flex;
	align-items: center;
	justify-content: center;
	font-family: 'Syne', sans-serif;
	font-size: 13px;
	font-weight: 800;
	border: 2px solid rgba(255, 255, 255, .2);
	color: rgba(255, 255, 255, .5);
	background: rgba(255, 255, 255, .08);
	transition: all .3s;
}

.step-v-circle.active {
	background: linear-gradient(135deg, var(--gold), var(--gold-light));
	border-color: transparent;
	color: #fff;
	box-shadow: 0 4px 14px rgba(200, 134, 10, .45);
}

.step-v-circle.done {
	background: rgba(46, 207, 180, .2);
	border-color: var(--teal-light);
	color: var(--teal-light);
}

.step-v-info {
	padding-top: 6px;
	padding-bottom: 25px;
}

.step-v-title {
	font-family: 'Syne', sans-serif;
	font-size: 13px;
	font-weight: 700;
	color: rgba(255, 255, 255, .9);
}

.step-v-title.inactive {
	color: rgba(255, 255, 255, .4);
	font-weight: 500;
}

.step-v-desc {
	font-size: 11px;
	color: rgba(255, 255, 255, .45);
	margin-top: 2px;
}

/* ════════════════ RIGHT PANEL ════════════════ */
.panel-right {
	flex: 1;
	padding: 48px 44px;
	display: flex;
	flex-direction: column;
	justify-content: center;
	overflow-y: auto;
	max-height: 90vh;
}

/* Steps horizontaux */
.steps-row {
	display: flex;
	align-items: center;
	justify-content: center;
	gap: 0;
	margin-bottom: 25px;
	flex-wrap: wrap;
}

.step-item {
	display: flex;
	flex-direction: column;
	align-items: center;
	gap: 5px;
}

.step-circle {
	width: 36px;
	height: 36px;
	border-radius: 50%;
	display: flex;
	align-items: center;
	justify-content: center;
	font-family: 'Syne', sans-serif;
	font-size: 14px;
	font-weight: 800;
	border: 2px solid rgba(200, 134, 10, .2);
	color: var(--soft);
	background: var(--gold-pale);
	transition: all .3s;
}

.step-circle.active {
	background: linear-gradient(135deg, var(--blue), var(--blue-light));
	border-color: transparent;
	color: #fff;
	box-shadow: 0 4px 14px rgba(31, 82, 212, .3);
}

.step-circle.done {
	background: rgba(14, 158, 138, .1);
	border-color: var(--teal);
	color: var(--teal);
}

.step-name {
	font-size: 10px;
	color: var(--soft);
	font-weight: 600;
	letter-spacing: .5px;
	text-transform: uppercase;
}

.step-name.active { color: var(--blue); }
.step-name.done { color: var(--teal); }

.step-line {
	width: 50px;
	height: 2px;
	background: rgba(200, 134, 10, .15);
	margin: 0 5px 20px 5px;
}

.step-line.done { background: var(--teal); }

.icon-ring {
	width: 70px;
	height: 70px;
	border-radius: 24px;
	background: linear-gradient(135deg, #0e2d82, var(--blue-light));
	display: flex;
	align-items: center;
	justify-content: center;
	font-size: 32px;
	box-shadow: 0 10px 28px rgba(31, 82, 212, .3);
	margin: 0 auto 20px;
}

.form-header {
	text-align: center;
	margin-bottom: 25px;
}

.form-header h3 {
	font-family: 'Syne', sans-serif;
	font-weight: 800;
	font-size: 26px;
	color: var(--dark);
	letter-spacing: -.5px;
	margin-bottom: 8px;
}

.form-header p {
	font-size: 14px;
	color: var(--mid);
	line-height: 1.65;
}

.form-header p strong { color: var(--dark); }

.alert {
	padding: 12px 16px;
	border-radius: 16px;
	font-size: 13px;
	font-weight: 500;
	display: flex;
	align-items: center;
	gap: 10px;
	margin-bottom: 20px;
}

.alert-error {
	background: #fff1f1;
	color: var(--error);
	border-left: 3px solid var(--error);
}

.alert-success {
	background: #f0fdf8;
	color: var(--success);
	border-left: 3px solid var(--success);
}

/* OTP boxes */
.otp-group {
	display: flex;
	gap: 12px;
	justify-content: center;
	margin: 20px 0;
	flex-wrap: wrap;
}

.otp-group input {
	width: 58px;
	height: 66px;
	text-align: center;
	font-family: 'Syne', sans-serif;
	font-size: 24px;
	font-weight: 800;
	color: var(--dark);
	border: 2px solid #edd9b0;
	border-radius: 16px;
	background: rgba(255, 248, 230, .6);
	outline: none;
	transition: all .22s;
	caret-color: var(--blue-light);
}

.otp-group input:focus {
	border-color: var(--blue-light);
	background: #fff;
	box-shadow: 0 0 0 4px rgba(79, 126, 248, .12);
	transform: scale(1.05);
}

.otp-group input.filled {
	border-color: var(--teal);
	background: var(--teal-pale);
	color: var(--teal);
}

.btn-submit {
	padding: 15px;
	border: none;
	border-radius: 40px;
	font-family: 'Syne', sans-serif;
	font-size: 16px;
	font-weight: 700;
	color: #fff;
	background: linear-gradient(115deg, #0e2d82, var(--blue-light));
	cursor: pointer;
	transition: all .25s;
	box-shadow: 0 8px 28px rgba(31, 82, 212, .32);
	width: 100%;
}

.btn-submit:hover {
	transform: translateY(-2px);
	box-shadow: 0 12px 36px rgba(31, 82, 212, .42);
}

.info-box {
	display: flex;
	align-items: flex-start;
	gap: 12px;
	padding: 15px 18px;
	border-radius: 20px;
	background: var(--teal-pale);
	border: 1px solid rgba(14, 158, 138, .2);
	margin: 20px 0 15px;
}

.info-box i { color: var(--teal); font-size: 18px; flex-shrink: 0; }
.info-box p { font-size: 13px; color: var(--teal); line-height: 1.6; }

.resend-row, .back-link {
	text-align: center;
	font-size: 13px;
	color: var(--mid);
}

.resend-row a, .back-link a {
	color: var(--gold);
	font-weight: 600;
	text-decoration: none;
	transition: color .2s;
}

.resend-row a:hover, .back-link a:hover { color: var(--gold-light); }

.back-link { margin-top: 12px; }

@keyframes fadeUp {
	from { opacity: 0; transform: translateY(16px); }
	to { opacity: 1; transform: translateY(0); }
}

/* Responsive */
@media (max-width: 850px) {
	.card { flex-direction: column; max-width: 550px; }
	.panel-left { padding: 30px; max-height: none; }
	.panel-right { padding: 35px 30px; }
	.steps-vertical { display: none; }
	.scene { margin: 10px 0; }
}

@media (max-width: 500px) {
	body { padding: 15px; }
	.otp-group input { width: 48px; height: 56px; font-size: 20px; }
	.panel-right { padding: 30px 20px; }
	.icon-ring { width: 55px; height: 55px; font-size: 26px; }
	.form-header h3 { font-size: 22px; }
}
</style>
</head>
<body>

<div class="bg-animation">
	<div class="blob blob-1"></div>
	<div class="blob blob-2"></div>
	<div class="blob blob-3"></div>
	<div class="blob blob-4"></div>
</div>
<canvas id="bgCanvas"></canvas>

<div class="card">

	<!-- ══ LEFT PANEL ══ -->
	<div class="panel-left">
		<div class="orb orb-1"></div>
		<div class="orb orb-2"></div>

		<!-- LOGO AVEC IMAGE REELLE -->
		<div class="logo-wrap">
			<img src="<%= request.getContextPath() %>/immo/admin/images/Logo.jpg" 
			     alt="Fredon Immobilier" 
			     class="logo-img"
			     onerror="this.style.backgroundColor='var(--gold)'; this.style.padding='12px'; this.src=''">
			<div class="logo-text">
				<span class="logo-name">Fredon</span>
				<span class="logo-tagline">Agence Immobilière</span>
			</div>
		</div>

		<!-- SCENE DECORATIVE -->
		<div class="scene">
			<div class="mini-card mini-card-1">
				<div class="mini-label">Biens en ligne</div>
				<div class="mini-value">248</div>
				<div class="mini-sub">↑ 12 cette semaine</div>
			</div>
			<div class="mini-card mini-card-2">
				<div class="mini-label">Ventes ce mois</div>
				<div class="mini-value">34</div>
				<div class="mini-sub">↑ +8%</div>
			</div>
			<div class="prop-card">
				<div class="house-thumb">
					<div class="sun"></div>
					<div class="cloud cloud-1"></div>
					<div class="cloud cloud-2"></div>
					<svg class="house-svg" viewBox="0 0 130 88" xmlns="http://www.w3.org/2000/svg">
						<rect x="0" y="76" width="130" height="12" fill="#4ade80" opacity=".7" rx="2" />
						<polygon points="53,76 77,76 70,88 60,88" fill="#d4c4a0" opacity=".8" />
						<rect x="25" y="44" width="80" height="36" rx="2" fill="#f5e6c8" />
						<polygon points="15,46 65,14 115,46" fill="#c8860a" />
						<rect x="80" y="18" width="10" height="16" rx="1" fill="#a06020" />
						<rect x="78" y="16" width="14" height="4" rx="1" fill="#8a5018" />
						<rect x="52" y="55" width="26" height="25" rx="13" fill="#8B4513" />
						<circle cx="74" cy="68" r="2" fill="#FFD700" />
						<rect x="28" y="50" width="18" height="14" rx="2" fill="#87CEEB" stroke="#c8a060" stroke-width="1.5" />
						<rect x="84" y="50" width="18" height="14" rx="2" fill="#87CEEB" stroke="#c8a060" stroke-width="1.5" />
						<rect x="5" y="60" width="5" height="18" fill="#8B6914" rx="1" />
						<ellipse cx="7" cy="52" rx="10" ry="14" fill="#22c55e" />
						<rect x="120" y="62" width="5" height="16" fill="#8B6914" rx="1" />
						<ellipse cx="122" cy="54" rx="9" ry="12" fill="#16a34a" />
					</svg>
				</div>
				<div class="prop-info">
					<div class="prop-price">Prix abordable</div>
					<div class="prop-title">Villa F4 • Mahajanga</div>
					<div class="prop-tags">
						<span class="tag">4 pièces</span>
						<span class="tag">220 m²</span>
						<span class="tag">Piscine</span>
					</div>
				</div>
			</div>
		</div>

		<!-- Steps verticaux -->
		<div class="steps-vertical">
			<div class="step-v">
				<div class="step-v-circle done"><i class="fas fa-check" style="font-size:12px;"></i></div>
				<div class="step-v-info">
					<div class="step-v-title">Email envoyé</div>
					<div class="step-v-desc">Code de vérification envoyé</div>
				</div>
			</div>
			<div class="step-v">
				<div class="step-v-circle active">2</div>
				<div class="step-v-info">
					<div class="step-v-title">Vérifier le code</div>
					<div class="step-v-desc">Code à 6 chiffres reçu par email</div>
				</div>
			</div>
			<div class="step-v">
				<div class="step-v-circle">3</div>
				<div class="step-v-info" style="padding-bottom: 0;">
					<div class="step-v-title inactive">Nouveau mot de passe</div>
					<div class="step-v-desc">Choisissez un mot de passe sécurisé</div>
				</div>
			</div>
		</div>
	</div>

	<!-- ══ RIGHT PANEL ══ -->
	<div class="panel-right">

		<!-- Steps horizontaux -->
		<div class="steps-row">
			<div class="step-item">
				<div class="step-circle done"><i class="fas fa-check"></i></div>
				<span class="step-name done">Email</span>
			</div>
			<div class="step-line done"></div>
			<div class="step-item">
				<div class="step-circle active">2</div>
				<span class="step-name active">Code</span>
			</div>
			<div class="step-line"></div>
			<div class="step-item">
				<div class="step-circle">3</div>
				<span class="step-name">Nouveau MDP</span>
			</div>
		</div>

		<div class="icon-ring"><i class="fas fa-envelope-open-text"></i></div>

		<div class="form-header">
			<h3>Vérification du code</h3>
			<p>Entrez le code à <strong>6 chiffres</strong> envoyé à <strong><%= resetEmail != null ? resetEmail : "votre email" %></strong></p>
		</div>

		<% if (request.getParameter("error") != null) { %>
		<div class="alert alert-error">
			<i class="fas fa-exclamation-triangle"></i> <%= request.getParameter("error") %>
		</div>
		<% } %>
		<% if (request.getParameter("success") != null) { %>
		<div class="alert alert-success">
			<i class="fas fa-check-circle"></i> <%= request.getParameter("success") %>
		</div>
		<% } %>

		<!-- OTP Inputs -->
		<div class="otp-group" id="otpGroup">
			<input type="text" maxlength="1" inputmode="numeric" pattern="[0-9]" class="otp-box" autocomplete="one-time-code">
			<input type="text" maxlength="1" inputmode="numeric" pattern="[0-9]" class="otp-box">
			<input type="text" maxlength="1" inputmode="numeric" pattern="[0-9]" class="otp-box">
			<input type="text" maxlength="1" inputmode="numeric" pattern="[0-9]" class="otp-box">
			<input type="text" maxlength="1" inputmode="numeric" pattern="[0-9]" class="otp-box">
			<input type="text" maxlength="1" inputmode="numeric" pattern="[0-9]" class="otp-box">
		</div>

		<form action="verifyCode" method="post" id="otpForm">
			<input type="hidden" name="code" id="codeInput">
			<button type="submit" class="btn-submit">Vérifier le code <i class="fas fa-arrow-right" style="margin-left: 8px;"></i></button>
		</form>

		<div class="info-box">
			<i class="fas fa-lightbulb"></i>
			<p>Le code est valable <strong>15 minutes</strong>. Vérifiez aussi votre dossier <strong>Spam</strong>.</p>
		</div>

		<div class="resend-row">
			Code non reçu ? <a href="forgot-password.jsp">Renvoyer le code</a>
		</div>

		<div class="back-link">
			<a href="forgot-password.jsp"><i class="fas fa-arrow-left"></i> Retour</a>
		</div>
	</div>
</div>

<script>
/* Canvas maisons */
(function() {
    var canvas = document.getElementById('bgCanvas');
    if (!canvas) return;
    var ctx = canvas.getContext('2d');
    var W, H, houses = [];
    
    function resize() {
        W = canvas.width = window.innerWidth;
        H = canvas.height = window.innerHeight;
    }
    resize();
    window.addEventListener('resize', resize);
    
    function drawHouse(ctx, x, y, s, alpha, color) {
        ctx.save();
        ctx.globalAlpha = alpha;
        ctx.strokeStyle = color;
        ctx.fillStyle = color;
        ctx.lineWidth = 1.2 * s;
        ctx.translate(x, y);
        ctx.beginPath();
        ctx.rect(-12 * s, -7 * s, 24 * s, 18 * s);
        ctx.stroke();
        ctx.beginPath();
        ctx.moveTo(-15 * s, -7 * s);
        ctx.lineTo(0, -20 * s);
        ctx.lineTo(15 * s, -7 * s);
        ctx.closePath();
        ctx.stroke();
        ctx.beginPath();
        ctx.arc(0, 6 * s, 4 * s, Math.PI, 0);
        ctx.rect(-4 * s, 1 * s, 8 * s, 5 * s);
        ctx.stroke();
        ctx.strokeRect(-10 * s, -4 * s, 6 * s, 5 * s);
        ctx.strokeRect(4 * s, -4 * s, 6 * s, 5 * s);
        ctx.fillRect(4 * s, -21 * s, 3 * s, 7 * s);
        ctx.restore();
    }
    
    var COLORS = ['#1f52d4', '#c8860a', '#0e9e8a', '#e03060', '#7c3aed'];
    for (var i = 0; i < 16; i++) {
        houses.push({
            x: Math.random() * 1600, y: Math.random() * 1200,
            s: 0.5 + Math.random() * 1.2,
            alpha: 0.04 + Math.random() * 0.05,
            color: COLORS[i % COLORS.length],
            vx: (Math.random() - 0.5) * 0.1,
            vy: (Math.random() - 0.5) * 0.08
        });
    }
    
    function animate() {
        if (!ctx) return;
        ctx.clearRect(0, 0, W, H);
        houses.forEach(function(h) {
            h.x += h.vx;
            h.y += h.vy;
            if (h.x < -100) h.x = W + 60;
            if (h.x > W + 100) h.x = -60;
            if (h.y < -100) h.y = H + 60;
            if (h.y > H + 100) h.y = -60;
            drawHouse(ctx, h.x, h.y, h.s, h.alpha, h.color);
        });
        requestAnimationFrame(animate);
    }
    animate();
})();

/* OTP Logic */
var boxes = document.querySelectorAll('.otp-box');
var codeInput = document.getElementById('codeInput');

boxes.forEach(function(box, i) {
    box.addEventListener('input', function(e) {
        var val = e.target.value.replace(/\D/g, '');
        e.target.value = val;
        if (val) {
            box.classList.add('filled');
            if (i < boxes.length - 1) boxes[i + 1].focus();
        } else {
            box.classList.remove('filled');
        }
        syncCode();
    });
    
    box.addEventListener('keydown', function(e) {
        if (e.key === 'Backspace' && !box.value && i > 0) {
            boxes[i - 1].focus();
            boxes[i - 1].value = '';
            boxes[i - 1].classList.remove('filled');
            syncCode();
        }
    });
    
    box.addEventListener('paste', function(e) {
        e.preventDefault();
        var paste = (e.clipboardData || window.clipboardData).getData('text').replace(/\D/g, '').slice(0, 6);
        paste.split('').forEach(function(ch, j) {
            if (boxes[j]) {
                boxes[j].value = ch;
                boxes[j].classList.add('filled');
            }
        });
        if (boxes[Math.min(paste.length, 5)]) boxes[Math.min(paste.length, 5)].focus();
        syncCode();
    });
});

function syncCode() {
    codeInput.value = Array.from(boxes).map(function(b) { return b.value; }).join('');
}

document.getElementById('otpForm').addEventListener('submit', function(e) {
    syncCode();
    if (codeInput.value.length < 6) {
        e.preventDefault();
        boxes[0].focus();
    }
});

boxes[0].focus();
</script>
</body>
</html>