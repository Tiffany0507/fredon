<%@ page language="java" contentType="text/html; charset=UTF-8"
	pageEncoding="UTF-8"%>
<%
HttpSession sess = request.getSession(false);
System.out.println("=== reset-password.jsp ===");
if (sess == null) { response.sendRedirect("forgot-password.jsp?error=Session expirée, recommencez"); return; }
Boolean codeVerified = (Boolean) sess.getAttribute("codeVerified");
Integer resetUserId  = (Integer) sess.getAttribute("resetPasswordForUser");
Integer resetAdminId = (Integer) sess.getAttribute("resetPasswordForAdmin");
if (codeVerified == null || !codeVerified) { response.sendRedirect("verify-code.jsp?error=Veuillez d'abord vérifier votre code"); return; }
if (resetUserId == null && resetAdminId == null) { response.sendRedirect("forgot-password.jsp?error=Session expirée, recommencez"); return; }
%>
<!DOCTYPE html>
<html lang="fr">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Fredon Immobilier — Nouveau mot de passe</title>
<link
	href="https://fonts.googleapis.com/css2?family=Syne:wght@400;600;700;800&family=DM+Sans:ital,opsz,wght@0,9..40,300;0,9..40,400;0,9..40,500;1,9..40,300&display=swap"
	rel="stylesheet">
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
	overflow: hidden;
}

.bg {
	position: fixed;
	inset: 0;
	z-index: 0;
	background: linear-gradient(135deg, #fdf8ee 0%, #fef5e0 40%, #fff9f0 70%, #fdf4e3
		100%);
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

@
keyframes drift { 0%{
	transform: translate(0, 0) scale(1)
}

100
%
{
transform
:
translate(
26px
,
18px
)
scale(
1.09
)
}
}
#bgCanvas {
	position: fixed;
	inset: 0;
	z-index: 0;
	pointer-events: none;
	opacity: .055;
}

.card {
	position: relative;
	z-index: 1;
	display: flex;
	width: min(980px, 96vw);
	min-height: 560px;
	background: rgba(255, 255, 255, .72);
	backdrop-filter: blur(32px) saturate(180%);
	-webkit-backdrop-filter: blur(32px) saturate(180%);
	border-radius: 32px;
	box-shadow: var(--shadow);
	border: 1px solid rgba(255, 255, 255, .9);
	overflow: hidden;
	animation: cardIn .8s cubic-bezier(.22, .97, .45, 1) both;
}

@
keyframes cardIn {
	from {opacity: 0;
	transform: translateY(40px) scale(.96)
}

to {
	opacity: 1;
	transform: translateY(0) scale(1)
}

}

/* LEFT */
.panel-left {
	flex: 1.1;
	background: linear-gradient(148deg, #0e2d82 0%, #1f52d4 40%, #2a3fa8 70%, #c8a020
		100%);
	padding: 44px 40px 40px;
	display: flex;
	flex-direction: column;
	position: relative;
	overflow: hidden;
}

.panel-left::before {
	content: '';
	position: absolute;
	inset: 0;
	background-image: linear-gradient(rgba(255, 255, 255, .03) 1px,
		transparent 1px), linear-gradient(90deg, rgba(255, 255, 255, .03) 1px,
		transparent 1px);
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
	background: radial-gradient(circle, rgba(255, 210, 80, .16) 0%,
		transparent 70%);
	top: -70px;
	right: -60px;
}

.orb-2 {
	width: 220px;
	height: 220px;
	background: radial-gradient(circle, rgba(100, 160, 255, .2) 0%,
		transparent 70%);
	bottom: 30px;
	left: -50px;
}

.logo-wrap {
	display: flex;
	align-items: center;
	gap: 14px;
	animation: fadeUp .6s .1s both;
	position: relative;
	z-index: 2;
}

.logo-mark {
	width: 54px;
	height: 54px;
	flex-shrink: 0;
	filter: drop-shadow(0 6px 18px rgba(0, 0, 0, .35));
	transition: transform .3s;
}

.logo-mark:hover {
	transform: scale(1.05);
}

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

.scene {
	flex: 1;
	display: flex;
	align-items: center;
	justify-content: center;
	position: relative;
	z-index: 2;
	margin: 16px 0 10px;
}

.prop-card {
	width: 180px;
	background: rgba(255, 255, 255, .13);
	border: 1.5px solid rgba(255, 255, 255, .25);
	border-radius: 20px;
	overflow: hidden;
	box-shadow: 0 28px 56px rgba(0, 0, 0, .28), inset 0 1px 0
		rgba(255, 255, 255, .22);
	animation: cardFloat 4.5s ease-in-out infinite;
}

@
keyframes cardFloat { 0%,100%{
	transform: translateY(0) rotate(-1.5deg)
}

50
%
{
transform
:
translateY(
-14px
)
rotate(
-1.5deg
)
}
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

@
keyframes sunPulse { 0%,100%{
	box-shadow: 0 0 16px #FFD700
}

50
%
{
box-shadow
:
0
0
28px
#FFD700
}
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

@
keyframes cloudDrift { 0%{
	transform: translateX(0)
}

100
%
{
transform
:
translateX(
180px
);
opacity
:
0
}
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

.mini-card {
	position: absolute;
	right: -8px;
	background: rgba(255, 255, 255, .15);
	border: 1.5px solid rgba(255, 255, 255, .28);
	border-radius: 14px;
	padding: 9px 12px;
	backdrop-filter: blur(8px);
	animation: miniFloat ease-in-out infinite;
}

.mini-card-1 {
	top: 12%;
	animation-duration: 5s;
	animation-delay: -.5s;
}

.mini-card-2 {
	bottom: 16%;
	animation-duration: 6s;
	animation-delay: -2s;
}

@
keyframes miniFloat { 0%,100%{
	transform: translateY(0)
}

50
%
{
transform
:
translateY(
-8px
)
}
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

.chat-bubble {
	position: absolute;
	left: -14px;
	background: rgba(255, 255, 255, .14);
	border: 1.5px solid rgba(255, 255, 255, .25);
	border-radius: 13px;
	padding: 6px 10px;
	font-size: 9px;
	font-weight: 500;
	color: rgba(255, 255, 255, .92);
	backdrop-filter: blur(8px);
	white-space: nowrap;
	animation: chatFloat ease-in-out infinite;
}

.chat-bubble-1 {
	top: 18%;
	border-bottom-left-radius: 3px;
	animation-duration: 5.5s;
	animation-delay: -1s;
}

.chat-bubble-2 {
	bottom: 20%;
	border-bottom-left-radius: 3px;
	animation-duration: 7s;
	animation-delay: -3s;
}

@
keyframes chatFloat { 0%,100%{
	transform: translateY(0)
}

50
%
{
transform
:
translateY(
-7px
)
}
}
.chat-dot {
	display: inline-block;
	width: 5px;
	height: 5px;
	border-radius: 50%;
	background: #4ade80;
	margin-right: 4px;
	box-shadow: 0 0 5px #4ade80;
}

/* Steps gauche — étape 3 */
.steps-vertical {
	display: flex;
	flex-direction: column;
	gap: 0;
	position: relative;
	z-index: 2;
	animation: fadeUp .6s .3s both;
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
	height: 32px;
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
	padding-bottom: 28px;
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

/* RIGHT */
.panel-right {
	flex: 1;
	padding: 52px 48px;
	display: flex;
	flex-direction: column;
	justify-content: center;
	gap: 22px;
}

.steps-row {
	display: flex;
	align-items: flex-start;
	gap: 0;
	animation: fadeUp .5s .15s both;
}

.step-item {
	display: flex;
	flex-direction: column;
	align-items: center;
	gap: 5px;
}

.step-circle {
	width: 32px;
	height: 32px;
	border-radius: 50%;
	display: flex;
	align-items: center;
	justify-content: center;
	font-family: 'Syne', sans-serif;
	font-size: 12.5px;
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
	white-space: nowrap;
}

.step-name.active {
	color: var(--blue);
}

.step-name.done {
	color: var(--teal);
}

.step-line {
	width: 40px;
	height: 2px;
	background: rgba(200, 134, 10, .15);
	margin-bottom: 20px;
	flex-shrink: 0;
}

.step-line.done {
	background: var(--teal);
}

.icon-ring {
	width: 68px;
	height: 68px;
	border-radius: 20px;
	background: linear-gradient(135deg, var(--teal), var(--teal-light));
	display: flex;
	align-items: center;
	justify-content: center;
	font-size: 28px;
	box-shadow: 0 10px 28px rgba(14, 158, 138, .3);
	animation: fadeUp .5s .1s both;
}

.form-header {
	animation: fadeUp .6s .2s both;
}

.form-header h3 {
	font-family: 'Syne', sans-serif;
	font-weight: 800;
	font-size: 26px;
	color: var(--dark);
	letter-spacing: -.5px;
	margin-bottom: 7px;
}

.form-header p {
	font-size: 14px;
	color: var(--mid);
	line-height: 1.65;
}

.alert {
	padding: 12px 16px;
	border-radius: 13px;
	font-size: 14px;
	font-weight: 500;
	display: flex;
	align-items: center;
	gap: 10px;
	animation: fadeUp .4s both;
}

.alert-error {
	background: #fff1f1;
	color: var(--error);
	border: 1px solid #fccaca;
}

.alert-success {
	background: #f0fdf8;
	color: var(--success);
	border: 1px solid #a7f3d8;
}

form {
	display: flex;
	flex-direction: column;
	gap: 16px;
	animation: fadeUp .6s .3s both;
}

.field {
	position: relative;
}

.field label {
	display: block;
	font-size: 11.5px;
	font-weight: 600;
	color: var(--mid);
	margin-bottom: 7px;
	text-transform: uppercase;
	letter-spacing: .6px;
}

.field .ico {
	position: absolute;
	bottom: 13px;
	left: 15px;
	font-size: 15px;
	color: #c8ad82;
	pointer-events: none;
	transition: color .2s;
}

.field .toggle-pw {
	position: absolute;
	bottom: 13px;
	right: 14px;
	font-size: 14px;
	cursor: pointer;
	color: #c8ad82;
	user-select: none;
	transition: color .2s;
}

.field .toggle-pw:hover {
	color: var(--blue-light);
}

.field input {
	width: 100%;
	padding: 13px 42px 13px 43px;
	border: 1.5px solid #edd9b0;
	border-radius: 13px;
	font-size: 15px;
	font-family: 'DM Sans', sans-serif;
	color: var(--dark);
	background: rgba(255, 248, 230, .5);
	outline: none;
	transition: border-color .22s, box-shadow .22s, background .22s;
}

.field input::placeholder {
	color: #c8b48a;
}

.field input:focus {
	border-color: var(--blue-light);
	background: #fff;
	box-shadow: 0 0 0 4px rgba(79, 126, 248, .12);
}

.field:has(input:focus) .ico {
	color: var(--blue-light);
}

/* Strength bar */
.strength-bar {
	display: flex;
	gap: 4px;
	margin-top: 8px;
}

.strength-bar span {
	flex: 1;
	height: 4px;
	border-radius: 99px;
	background: rgba(200, 134, 10, .12);
	transition: background .3s;
}

.strength-label {
	font-size: 11.5px;
	color: var(--soft);
	margin-top: 5px;
	min-height: 16px;
	transition: color .3s;
	font-weight: 500;
}

.match-msg {
	font-size: 12px;
	margin-top: 6px;
	min-height: 16px;
	transition: color .3s;
	font-weight: 500;
}

.match-ok {
	color: var(--success);
}

.match-fail {
	color: var(--error);
}

/* Règles mot de passe */
.pw-rules {
	background: var(--gold-pale);
	border: 1px solid rgba(200, 134, 10, .18);
	border-radius: 13px;
	padding: 12px 15px;
	animation: fadeUp .6s .38s both;
}

.pw-rules p {
	font-size: 11.5px;
	font-weight: 700;
	color: var(--gold);
	margin-bottom: 8px;
	text-transform: uppercase;
	letter-spacing: .5px;
}

.rule {
	display: flex;
	align-items: center;
	gap: 8px;
	font-size: 12.5px;
	color: var(--mid);
	margin-bottom: 4px;
	transition: color .2s;
}

.rule:last-child {
	margin-bottom: 0;
}

.rule-dot {
	width: 7px;
	height: 7px;
	border-radius: 50%;
	background: rgba(200, 134, 10, .3);
	flex-shrink: 0;
	transition: background .3s;
}

.rule.ok .rule-dot {
	background: var(--success);
}

.rule.ok {
	color: var(--success);
}

.btn-submit {
	padding: 15px;
	border: none;
	border-radius: 13px;
	font-family: 'Syne', sans-serif;
	font-size: 16px;
	font-weight: 700;
	color: #fff;
	background: linear-gradient(115deg, var(--teal), var(--teal-light));
	cursor: pointer;
	transition: transform .15s, box-shadow .22s;
	box-shadow: 0 8px 28px rgba(14, 158, 138, .3);
	position: relative;
	overflow: hidden;
}

.btn-submit::before {
	content: '';
	position: absolute;
	inset: 0;
	background: linear-gradient(115deg, transparent, rgba(255, 255, 255, .1));
	opacity: 0;
	transition: opacity .2s;
}

.btn-submit:hover {
	transform: translateY(-2px);
	box-shadow: 0 12px 36px rgba(14, 158, 138, .4);
}

.btn-submit:hover::before {
	opacity: 1;
}

.btn-submit:active {
	transform: translateY(0);
}

.back-link {
	text-align: center;
	animation: fadeUp .6s .5s both;
}

.back-link a {
	font-size: 13.5px;
	color: var(--mid);
	text-decoration: none;
	display: inline-flex;
	align-items: center;
	gap: 6px;
	transition: color .2s;
}

.back-link a:hover {
	color: var(--gold);
}

@
keyframes fadeUp {
	from {opacity: 0;
	transform: translateY(16px)
}

to {
	opacity: 1;
	transform: translateY(0)
}

}
@media ( max-width :700px) {
	.panel-left {
		display: none;
	}
	.panel-right {
		padding: 40px 28px;
	}
	.card {
		min-height: unset;
	}
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
	<canvas id="bgCanvas"></canvas>

	<div class="card">

		<!-- ══ LEFT ══ -->
		<div class="panel-left">
			<div class="orb orb-1"></div>
			<div class="orb orb-2"></div>

			<div class="logo-wrap">
				<svg class="logo-mark" viewBox="0 0 54 54" fill="none"
					xmlns="http://www.w3.org/2000/svg">
                <defs>
                    <linearGradient id="hG2" x1="0%" y1="0%" x2="100%"
						y2="100%">
					<stop offset="0%" stop-color="#FFD060" />
					<stop offset="50%" stop-color="#F59E0B" />
					<stop offset="100%" stop-color="#B45309" /></linearGradient>
                    <linearGradient id="rG2" x1="0%" y1="0%" x2="100%"
						y2="100%">
					<stop offset="0%" stop-color="#FDE68A" />
					<stop offset="100%" stop-color="#D97706" /></linearGradient>
                </defs>
                <circle cx="27" cy="27" r="25"
						fill="rgba(255,255,255,.12)" stroke="rgba(255,255,255,.3)"
						stroke-width="1.5" />
                <rect x="13" y="28" width="28" height="18" rx="2"
						fill="url(#hG2)" />
                <polygon points="10,29 27,12 44,29" fill="url(#rG2)" />
                <rect x="22" y="35" width="10" height="11" rx="5"
						fill="rgba(90,40,5,.75)" />
                <rect x="14" y="31" width="7" height="6" rx="1.5"
						fill="rgba(180,220,255,.8)" />
                <rect x="33" y="31" width="7" height="6" rx="1.5"
						fill="rgba(180,220,255,.8)" />
                <circle cx="39" cy="16" r="1.4" fill="#FDE68A"
						opacity=".9">
					<animate attributeName="opacity" values="0.9;0.3;0.9" dur="1.6s"
						repeatCount="indefinite" /></circle>
                <g opacity=".88">
					<rect x="35" y="7" width="14" height="9" rx="3" fill="#10B981" />
					<polygon points="37,16 36,19 40,16" fill="#10B981" />
					<rect x="37" y="9.5" width="4" height="1.5" rx=".7" fill="white"
						opacity=".9" />
					<rect x="37" y="12" width="7" height="1.5" rx=".7" fill="white"
						opacity=".7" /></g>
            </svg>
				<div class="logo-text">
					<span class="logo-name">Fredon</span> <span class="logo-tagline">Agence
						Immobilière</span>
				</div>
			</div>

			<div class="scene">
				<div class="chat-bubble chat-bubble-1">
					<span class="chat-dot"></span>Presque terminé !
				</div>
				<div class="chat-bubble chat-bubble-2">
					<span class="chat-dot"></span>Compte sécurisé 🛡️
				</div>
				<div class="mini-card mini-card-1">
					<div class="mini-label">Biens en ligne</div>
					<div class="mini-value">248</div>
					<div class="mini-sub">↑ 12 cette semaine</div>
				</div>
				<div class="mini-card mini-card-2">
					<div class="mini-label">Ventes ce mois</div>
					<div class="mini-value">34</div>
					<div class="mini-sub">↑ +8% vs dernier mois</div>
				</div>
				<div class="prop-card">
					<div class="house-thumb">
						<div class="sun"></div>
						<div class="cloud cloud-1"></div>
						<div class="cloud cloud-2"></div>
						<svg class="house-svg" viewBox="0 0 130 88"
							xmlns="http://www.w3.org/2000/svg">
                        <rect x="0" y="76" width="130" height="12"
								fill="#4ade80" opacity=".7" rx="2" />
                        <polygon points="53,76 77,76 70,88 60,88"
								fill="#d4c4a0" opacity=".8" />
                        <rect x="25" y="44" width="80" height="36"
								rx="2" fill="#f5e6c8" />
                        <polygon points="15,46 65,14 115,46"
								fill="#c8860a" />
                        <rect x="80" y="18" width="10" height="16"
								rx="1" fill="#a06020" />
                        <rect x="78" y="16" width="14" height="4" rx="1"
								fill="#8a5018" />
                        <rect x="52" y="55" width="26" height="25"
								rx="13" fill="#8B4513" />
                        <circle cx="74" cy="68" r="2" fill="#FFD700" />
                        <rect x="28" y="50" width="18" height="14"
								rx="2" fill="#87CEEB" stroke="#c8a060" stroke-width="1.5" />
                        <line x1="37" y1="50" x2="37" y2="64"
								stroke="#c8a060" stroke-width="1" />
                        <line x1="28" y1="57" x2="46" y2="57"
								stroke="#c8a060" stroke-width="1" />
                        <rect x="84" y="50" width="18" height="14"
								rx="2" fill="#87CEEB" stroke="#c8a060" stroke-width="1.5" />
                        <line x1="93" y1="50" x2="93" y2="64"
								stroke="#c8a060" stroke-width="1" />
                        <line x1="84" y1="57" x2="102" y2="57"
								stroke="#c8a060" stroke-width="1" />
                        <rect x="5" y="60" width="5" height="18"
								fill="#8B6914" rx="1" />
                        <ellipse cx="7" cy="52" rx="10" ry="14"
								fill="#22c55e" />
                        <rect x="120" y="62" width="5" height="16"
								fill="#8B6914" rx="1" />
                        <ellipse cx="122" cy="54" rx="9" ry="12"
								fill="#16a34a" />
                    </svg>
					</div>
					<div class="prop-info">
						<div class="prop-price">Prix abordable</div>
						<div class="prop-title">Villa F4 • Mahajanga-Amborovy</div>
						<div class="prop-tags">
							<span class="tag">4 pièces</span><span class="tag">220 m²</span><span
								class="tag">Piscine</span>
						</div>
					</div>
				</div>
			</div>

			<!-- Steps gauche — étape 3 -->
			<div class="steps-vertical">
				<div class="step-v">
					<div class="step-v-circle done">✓</div>
					<div class="step-v-info">
						<div class="step-v-title">Email envoyé</div>
						<div class="step-v-desc">Adresse email vérifiée</div>
					</div>
				</div>
				<div class="step-v">
					<div class="step-v-circle done">✓</div>
					<div class="step-v-info">
						<div class="step-v-title">Code vérifié</div>
						<div class="step-v-desc">Code à 6 chiffres confirmé</div>
					</div>
				</div>
				<div class="step-v">
					<div class="step-v-circle active">3</div>
					<div class="step-v-info" style="padding-bottom: 0;">
						<div class="step-v-title">Nouveau mot de passe</div>
						<div class="step-v-desc">Choisissez un mot de passe sécurisé</div>
					</div>
				</div>
			</div>
		</div>

		<!-- ══ RIGHT ══ -->
		<div class="panel-right">

			<div class="steps-row">
				<div class="step-item">
					<div class="step-circle done">✓</div>
					<span class="step-name done">Email</span>
				</div>
				<div class="step-line done"></div>
				<div class="step-item">
					<div class="step-circle done">✓</div>
					<span class="step-name done">Code</span>
				</div>
				<div class="step-line done"></div>
				<div class="step-item">
					<div class="step-circle active">3</div>
					<span class="step-name active">Nouveau MDP</span>
				</div>
			</div>

			<div class="icon-ring">🛡️</div>

			<div class="form-header">
				<h3>Nouveau mot de passe</h3>
				<p>Choisissez un mot de passe sécurisé pour protéger votre
					compte Fredon.</p>
			</div>

			<% if (request.getParameter("error") != null) { %>
			<div class="alert alert-error">
				⚠️
				<%= request.getParameter("error") %></div>
			<% } %>
			<% if (request.getParameter("success") != null) { %>
			<div class="alert alert-success">
				✅
				<%= request.getParameter("success") %></div>
			<% } %>

			<form action="resetPassword" method="post">
				<div class="field">
					<label for="newPassword">Nouveau mot de passe</label>
					<div class="field-icon-wrap" style="position: relative;">
						<input type="password" id="newPassword" name="newPassword"
							placeholder="Min. 8 caractères" required
							oninput="checkStrength(this.value);checkMatch();"> <span
							class="ico">🔒</span> <span class="toggle-pw"
							onclick="togglePw('newPassword',this)">👁️</span>
					</div>
					<div class="strength-bar">
						<span id="s1"></span><span id="s2"></span><span id="s3"></span><span
							id="s4"></span>
					</div>
					<div class="strength-label" id="strengthLabel"></div>
				</div>

				<div class="field">
					<label for="confirmPassword">Confirmer le mot de passe</label>
					<div style="position: relative;">
						<input type="password" id="confirmPassword" name="confirmPassword"
							placeholder="Répétez votre mot de passe" required
							oninput="checkMatch()"> <span class="ico">🔐</span> <span
							class="toggle-pw" onclick="togglePw('confirmPassword',this)">👁️</span>
					</div>
					<div class="match-msg" id="matchMsg"></div>
				</div>

				<!-- Règles -->
				<div class="pw-rules">
					<p>🛡️ Votre mot de passe doit contenir</p>
					<div class="rule" id="rule-len">
						<div class="rule-dot"></div>
						8 caractères minimum
					</div>
					<div class="rule" id="rule-upp">
						<div class="rule-dot"></div>
						Une lettre majuscule
					</div>
					<div class="rule" id="rule-num">
						<div class="rule-dot"></div>
						Un chiffre
					</div>
					<div class="rule" id="rule-spe">
						<div class="rule-dot"></div>
						Un caractère spécial (!@#...)
					</div>
				</div>

				<button type="submit" class="btn-submit">Réinitialiser le
					mot de passe →</button>
			</form>

			<div class="back-link">
				<a href="login.jsp">← Retour à la connexion</a>
			</div>
		</div>
	</div>

	<script>
/* Canvas maisons */
(function(){
    var c=document.getElementById('bgCanvas'),ctx=c.getContext('2d');
    var W,H,h=[];
    function r(){W=c.width=innerWidth;H=c.height=innerHeight;} r(); window.addEventListener('resize',r);
    function dh(x,y,s,a,col){ctx.save();ctx.globalAlpha=a;ctx.strokeStyle=col;ctx.fillStyle=col;ctx.lineWidth=1.4*s;ctx.translate(x,y);ctx.beginPath();ctx.rect(-14*s,-8*s,28*s,20*s);ctx.stroke();ctx.beginPath();ctx.moveTo(-17*s,-8*s);ctx.lineTo(0,-22*s);ctx.lineTo(17*s,-8*s);ctx.closePath();ctx.stroke();ctx.beginPath();ctx.arc(0,7*s,5*s,Math.PI,0);ctx.rect(-5*s,2*s,10*s,5*s);ctx.stroke();ctx.strokeRect(-12*s,-5*s,7*s,6*s);ctx.strokeRect(5*s,-5*s,7*s,6*s);ctx.fillRect(5*s,-24*s,4*s,8*s);ctx.restore();}
    var CL=['#1f52d4','#c8860a','#0e9e8a','#e03060','#7c3aed','#0e7490','#b45309','#166534'];
    for(var i=0;i<18;i++) h.push({x:Math.random()*1600,y:Math.random()*900,s:.5+Math.random()*1.4,alpha:.04+Math.random()*.06,color:CL[i%CL.length],vx:(Math.random()-.5)*.12,vy:(Math.random()-.5)*.10});
    function an(){ctx.clearRect(0,0,W,H);h.forEach(function(o){o.x+=o.vx;o.y+=o.vy;if(o.x<-100)o.x=W+60;if(o.x>W+100)o.x=-60;if(o.y<-100)o.y=H+60;if(o.y>H+100)o.y=-60;dh(o.x,o.y,o.s,o.alpha,o.color);});requestAnimationFrame(an);}
    an();
})();

/* Strength */
var strengthColors = ['#ef4444','#f59e0b','#3b82f6','#10b981'];
var strengthLabels = ['Très faible','Moyen','Fort','Très fort'];

function checkStrength(val) {
    var bars  = [document.getElementById('s1'),document.getElementById('s2'),document.getElementById('s3'),document.getElementById('s4')];
    var label = document.getElementById('strengthLabel');
    var score = 0;
    var len = val.length >= 8;
    var upp = /[A-Z]/.test(val);
    var num = /[0-9]/.test(val);
    var spe = /[^A-Za-z0-9]/.test(val);
    if (len) score++; if (upp) score++; if (num) score++; if (spe) score++;
    bars.forEach(function(b,i){ b.style.background = i<score ? strengthColors[score-1] : 'rgba(200,134,10,.12)'; });
    label.textContent = val.length ? (strengthLabels[score-1]||'') : '';
    label.style.color = score ? strengthColors[score-1] : 'var(--soft)';
    // Rules
    toggleRule('rule-len', len);
    toggleRule('rule-upp', upp);
    toggleRule('rule-num', num);
    toggleRule('rule-spe', spe);
}
function toggleRule(id, ok) {
    var el = document.getElementById(id);
    if (!el) return;
    if (ok) el.classList.add('ok'); else el.classList.remove('ok');
}

function checkMatch() {
    var pw  = document.getElementById('newPassword').value;
    var cpw = document.getElementById('confirmPassword').value;
    var msg = document.getElementById('matchMsg');
    if (!cpw) { msg.textContent=''; return; }
    if (pw===cpw) { msg.textContent='✓ Les mots de passe correspondent'; msg.className='match-msg match-ok'; }
    else          { msg.textContent='✗ Les mots de passe ne correspondent pas'; msg.className='match-msg match-fail'; }
}

function togglePw(id, btn) {
    var inp = document.getElementById(id);
    if (inp.type==='password') { inp.type='text'; btn.textContent='🙈'; }
    else { inp.type='password'; btn.textContent='👁️'; }
}
</script>
</body>
</html>
