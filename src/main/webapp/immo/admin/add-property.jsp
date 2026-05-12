<%@ page language="java" contentType="text/html; charset=UTF-8"
	pageEncoding="UTF-8"%>
<%@ page import="com.quickchat.utils.TranslateUtil"%>
<%@ page import="java.sql.Connection"%>
<%@ page import="java.sql.DriverManager"%>
<%@ page import="java.sql.PreparedStatement"%>
<%@ page import="java.sql.ResultSet"%>
<%@ include file="includes/color.jsp" %>

<%

response.setHeader("Cache-Control", "no-cache, no-store, must-revalidate");
response.setHeader("Pragma", "no-cache");
response.setHeader("Expires", "0");

    if (session == null || session.getAttribute("adminId") == null) {
        response.sendRedirect(request.getContextPath() + "/login");
        return;
    }
    
    // Récupération de la langue
    String lang = "fr";
    try {
        Class.forName("com.mysql.cj.jdbc.Driver");
        Connection connLang = DriverManager.getConnection("jdbc:mysql://localhost:3306/quickchat", "root", "");
        PreparedStatement pstmtLang = connLang.prepareStatement("SELECT default_language FROM settings WHERE id = 1");
        ResultSet rsLang = pstmtLang.executeQuery();
        if (rsLang.next()) lang = rsLang.getString("default_language");
        rsLang.close(); pstmtLang.close(); connLang.close();
    } catch(Exception e) {}
    
    // Récupération des messages non lus pour le badge
    int unreadMessages = 0;
    try {
        com.quickchat.dao.MessageDAO messageDAO = new com.quickchat.dao.MessageDAO();
        unreadMessages = messageDAO.countUnreadMessagesForAgent();
    } catch(Exception e) {}
    
    // Récupération des rendez-vous en attente
    int pendingAppointments = 0;
    try {
        Class.forName("com.mysql.cj.jdbc.Driver");
        Connection connCount = DriverManager.getConnection("jdbc:mysql://localhost:3306/quickchat", "root", "");
        PreparedStatement pstmtCount = connCount.prepareStatement("SELECT COUNT(*) FROM appointments WHERE status = 'pending'");
        ResultSet rsCount = pstmtCount.executeQuery();
        if (rsCount.next()) pendingAppointments = rsCount.getInt(1);
        rsCount.close();
        pstmtCount.close();
        connCount.close();
    } catch(Exception e) {}
    
    // Récupération des notifications non lues
    int notifCount = 0;
    Integer adminId = (Integer) session.getAttribute("adminId");
    try {
        Class.forName("com.mysql.cj.jdbc.Driver");
        Connection connNotif = DriverManager.getConnection("jdbc:mysql://localhost:3306/quickchat", "root", "");
        PreparedStatement pstmtNotif = connNotif.prepareStatement("SELECT COUNT(*) FROM notifications WHERE user_id = ? AND is_read = 0");
        pstmtNotif.setInt(1, adminId);
        ResultSet rsNotif = pstmtNotif.executeQuery();
        if (rsNotif.next()) notifCount = rsNotif.getInt(1);
        rsNotif.close();
        pstmtNotif.close();
        connNotif.close();
    } catch(Exception e) {}
    
    String error = request.getAttribute("error") != null ? (String) request.getAttribute("error") : request.getParameter("error");
    String adminName = session.getAttribute("adminUsername") != null ? session.getAttribute("adminUsername").toString() : "Admin";
    String adminInitial = (adminName != null && !adminName.isEmpty()) ? adminName.substring(0, 1).toUpperCase() : "A";
    
    String adminProfilePic = null;
    try {
        Class.forName("com.mysql.cj.jdbc.Driver");
        Connection conn = DriverManager.getConnection("jdbc:mysql://localhost:3306/quickchat", "root", "");
        PreparedStatement pstmt = conn.prepareStatement("SELECT profile_pic FROM users WHERE id = ?");
        pstmt.setInt(1, adminId);
        ResultSet rs = pstmt.executeQuery();
        if (rs.next()) {
            adminProfilePic = rs.getString("profile_pic");
        }
        rs.close(); pstmt.close(); conn.close();
    } catch(Exception e) {}
%>
<!DOCTYPE html>
<html lang="<%= lang %>">
<head>
<%@ include file="includes/theme.jsp" %>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title><%= TranslateUtil.t(lang, "add_property") %> — Fredon Commerce & Construction</title>
<link
	href="https://fonts.googleapis.com/css2?family=Syne:wght@400;600;700;800&family=DM+Sans:ital,opsz,wght@0,9..40,300;0,9..40,400;0,9..40,500;0,9..40,600;0,9..40,700&display=swap"
	rel="stylesheet">
<link rel="stylesheet"
	href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css">
<link rel="stylesheet"
	href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css" />
<style>
/* VOTRE STYLE RESTE IDENTIQUE - PAS DE CHANGEMENT */
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
	--rose-light: #f7547a;
	--rose-pale: #fde8ee;
	--purple: #7c3aed;
	--purple-pale: #f0ebff;
	--green: #10b981;
	--red: #ef4444;
	--emerald: #059669;
	--dark: #0d0b08;
	--mid: #6b5a3e;
	--soft: #a89880;
	--bg: #f8f4ee;
	--bg2: #fdf9f3;
	--white: #ffffff;
	--sidebar-w: 272px;
	--r-lg: 18px;
	--r-xl: 26px;
}

html, body {
	height: 100%;
	font-family: 'DM Sans', sans-serif;
	background: var(--bg);
	color: var(--dark);
	overflow-x: hidden;
}

#bgCanvas {
	position: fixed;
	inset: 0;
	z-index: 0;
	pointer-events: none;
	opacity: .06;
}

.layout {
	display: flex;
	min-height: 100vh;
	position: relative;
	z-index: 1;
}

.sidebar {
	width: var(--sidebar-w);
	background: linear-gradient(160deg, #0d1f5e 0%, #1a3aaa 45%, #0e2d82 75%, #0a1d58 100%);
	display: flex;
	flex-direction: column;
	position: fixed;
	left: 0;
	top: 0;
	bottom: 0;
	z-index: 100;
	box-shadow: 8px 0 40px rgba(31, 82, 212, .18);
	overflow: hidden;
}

.sidebar::before {
	content: '';
	position: absolute;
	inset: 0;
	background-image: radial-gradient(ellipse at 80% 10%, rgba(200, 134, 10, .18) 0%, transparent 60%),
		radial-gradient(ellipse at 20% 90%, rgba(79, 126, 248, .15) 0%, transparent 50%);
	pointer-events: none;
}

.sidebar-grid {
	position: absolute;
	inset: 0;
	pointer-events: none;
	background-image: linear-gradient(rgba(255, 255, 255, .03) 1px, transparent 1px),
		linear-gradient(90deg, rgba(255, 255, 255, .03) 1px, transparent 1px);
	background-size: 36px 36px;
}

.logo-area {
	padding: 20px 18px 18px;
	border-bottom: 1px solid rgba(255, 255, 255, .1);
	display: flex;
	align-items: center;
	gap: 14px;
	position: relative;
	z-index: 2;
}

.logo-mark {
	width: 68px;
	height: 68px;
	flex-shrink: 0;
	object-fit: cover;
	border-radius: 18px;
	box-shadow: 0 6px 22px rgba(0,0,0,.45), 0 0 0 2px rgba(255,255,255,.2);
	transition: transform .25s;
}

.logo-text-wrap {
	display: flex;
	flex-direction: column;
}

.logo-name {
	font-family: 'Syne', sans-serif;
	font-weight: 800;
	font-size: 26px;
	background: linear-gradient(120deg, #fff 0%, #cce8ff 50%, #fde9b0 100%);
	-webkit-background-clip: text;
	background-clip: text;
	color: transparent;
	display: block;
	line-height: 1.1;
}

.logo-sub {
	font-size: 10px;
	color: rgba(255, 255, 255, .6);
	letter-spacing: 2.8px;
	text-transform: uppercase;
	margin-top: 4px;
	display: block;
	font-weight: 400;
}

.nav {
	flex: 1;
	padding: 18px 14px;
	display: flex;
	flex-direction: column;
	gap: 2px;
	position: relative;
	z-index: 2;
	overflow-y: auto;
}

.nav-section {
	font-size: 9.5px;
	font-weight: 700;
	letter-spacing: 1.8px;
	text-transform: uppercase;
	color: rgba(255, 255, 255, .38);
	padding: 14px 10px 6px;
}

.nav-item {
	display: flex;
	align-items: center;
	gap: 11px;
	padding: 11px 13px;
	border-radius: 12px;
	color: rgba(255, 255, 255, .65);
	font-size: 13.5px;
	font-weight: 500;
	text-decoration: none;
	transition: all .22s;
	position: relative;
}

.nav-item i {
	width: 18px;
	font-size: 14px;
	text-align: center;
}

.nav-item:hover {
	background: rgba(255, 255, 255, .1);
	color: #fff;
}

.nav-item.active {
	background: rgba(255, 255, 255, .14);
	color: #fff;
	border-left: 3px solid var(--gold-light);
}

.nav-item.logout {
	color: rgba(255, 130, 130, .7);
	margin-top: auto;
}

.nav-item.logout:hover {
	background: rgba(239, 68, 68, .15);
	color: #fca5a5;
}

.nav-badge {
	margin-left: auto;
	background: var(--rose);
	color: white;
	font-size: 9.5px;
	font-weight: 700;
	padding: 2px 7px;
	border-radius: 20px;
	animation: pulse 2s ease-in-out infinite;
}

@keyframes pulse { 0%,100% { opacity: 1; } 50% { opacity: .65; } }

.user-bottom {
	padding: 16px 14px;
	border-top: 1px solid rgba(255, 255, 255, .1);
	display: flex;
	align-items: center;
	gap: 10px;
	cursor: pointer;
	transition: all .22s;
	position: relative;
	z-index: 2;
}

.user-bottom:hover {
	background: rgba(255, 255, 255, .08);
}

.u-avatar {
	width: 42px;
	height: 42px;
	flex-shrink: 0;
	background: linear-gradient(135deg, var(--gold), var(--gold-light));
	border-radius: 12px;
	display: flex;
	align-items: center;
	justify-content: center;
	font-family: 'Syne', sans-serif;
	font-size: 18px;
	font-weight: 800;
	color: #fff;
	box-shadow: 0 4px 14px rgba(200, 134, 10, .4);
	overflow: hidden;
}

.u-info {
	flex: 1;
}

.u-name {
	font-size: 13.5px;
	font-weight: 700;
	color: #fff;
}

.u-role {
	font-size: 10.5px;
	color: rgba(255, 255, 255, .5);
	margin-top: 1px;
}

.u-dot {
	width: 8px;
	height: 8px;
	background: var(--teal-light);
	border-radius: 50%;
	box-shadow: 0 0 8px var(--teal-light);
}

.main {
	margin-left: var(--sidebar-w);
	flex: 1;
	padding: 28px 32px;
	min-height: 100vh;
}

.top-bar {
	display: flex;
	justify-content: space-between;
	align-items: center;
	margin-bottom: 28px;
	gap: 16px;
	flex-wrap: wrap;
}

.page-title h1 {
	font-family: 'Syne', sans-serif;
	font-size: 26px;
	font-weight: 800;
	color: var(--dark);
	letter-spacing: -.5px;
}

.page-title p {
	font-size: 13px;
	color: var(--soft);
	margin-top: 3px;
}

.top-right {
	display: flex;
	align-items: center;
	gap: 10px;
}

.notif-wrap {
	position: relative;
	text-decoration: none;
}

.icon-circle {
	width: 40px;
	height: 40px;
	background: var(--white);
	border: 1.5px solid rgba(200, 134, 10, .14);
	border-radius: 12px;
	display: flex;
	align-items: center;
	justify-content: center;
	cursor: pointer;
	color: var(--mid);
	font-size: 15px;
	transition: all .22s;
	text-decoration: none;
}

.icon-circle:hover {
	border-color: var(--gold);
	color: var(--gold);
}

.notif-pip {
	position: absolute;
	top: -2px;
	right: -2px;
	background: var(--red);
	color: white;
	font-size: 10px;
	width: 18px;
	height: 18px;
	border-radius: 50%;
	display: flex;
	align-items: center;
	justify-content: center;
	font-weight: bold;
}

.breadcrumb {
	display: flex;
	align-items: center;
	gap: 8px;
	font-size: 13px;
	color: var(--soft);
	margin-bottom: 22px;
}

.breadcrumb a {
	color: var(--soft);
	text-decoration: none;
	transition: color .2s;
}

.breadcrumb a:hover {
	color: var(--gold);
}

.breadcrumb .sep {
	color: rgba(168, 152, 128, .4);
}

.breadcrumb .current {
	color: var(--teal);
	font-weight: 600;
}

.alert {
	display: flex;
	align-items: center;
	gap: 10px;
	padding: 13px 18px;
	border-radius: 14px;
	margin-bottom: 22px;
	font-size: 13.5px;
	font-weight: 500;
	animation: slideIn .35s ease;
}

@keyframes slideIn {from { opacity:0; transform: translateY(-8px); }
to { opacity: 1; transform: translateY(0); }
}

.alert-error {
	background: rgba(239, 68, 68, .1);
	border: 1px solid rgba(239, 68, 68, .25);
	color: var(--red);
}

.form-card {
	background: var(--white);
	border-radius: var(--r-xl);
	border: 1.5px solid rgba(200, 134, 10, .1);
	overflow: hidden;
	box-shadow: 0 2px 20px rgba(0, 0, 0, .06);
	animation: fadeUp .5s .1s both;
}

@keyframes fadeUp {from { opacity:0; transform: translateY(16px); }
to { opacity: 1; transform: translateY(0); }
}

.form-header {
	padding: 22px 28px;
	border-bottom: 1.5px solid rgba(200, 134, 10, .08);
	display: flex;
	align-items: center;
	gap: 14px;
}

.fh-icon {
	width: 46px;
	height: 46px;
	border-radius: 13px;
	flex-shrink: 0;
	display: flex;
	align-items: center;
	justify-content: center;
	font-size: 20px;
}

.fh-title {
	font-family: 'Syne', sans-serif;
	font-size: 17px;
	font-weight: 700;
	color: var(--dark);
}

.fh-sub {
	font-size: 11.5px;
	color: var(--soft);
	margin-top: 2px;
}

.form-body {
	padding: 28px;
}

.section-label {
	display: flex;
	align-items: center;
	gap: 10px;
	margin-bottom: 18px;
	margin-top: 8px;
}

.section-label .sl-bar {
	width: 4px;
	height: 22px;
	border-radius: 4px;
}

.section-label h3 {
	font-family: 'Syne', sans-serif;
	font-size: 14.5px;
	font-weight: 700;
	color: var(--dark);
}

.sl-blue {
	background: var(--blue-light);
}

.sl-teal {
	background: var(--teal-light);
}

.sl-gold {
	background: var(--gold-light);
}

.sl-rose {
	background: var(--rose-light);
}

.form-grid {
	display: grid;
	grid-template-columns: 1fr 1fr;
	gap: 18px;
}

.span2 {
	grid-column: span 2;
}

.field {
	display: flex;
	flex-direction: column;
	gap: 7px;
}

.field label {
	font-size: 11.5px;
	font-weight: 600;
	color: var(--mid);
	text-transform: uppercase;
	letter-spacing: .6px;
}

.field label .req {
	color: var(--rose);
}

.field input, .field select, .field textarea {
	padding: 12px 14px;
	border: 1.5px solid rgba(200, 134, 10, .15);
	border-radius: 13px;
	font-size: 14px;
	font-family: 'DM Sans', sans-serif;
	color: var(--dark);
	background: var(--bg2);
	transition: all .22s;
	outline: none;
	width: 100%;
}

.field input::placeholder, .field textarea::placeholder {
	color: #c8b48a;
}

.field input:focus, .field select:focus, .field textarea:focus {
	border-color: var(--blue-light);
	background: var(--white);
	box-shadow: 0 0 0 4px rgba(79, 126, 248, .1);
}

.field select {
	cursor: pointer;
	appearance: none;
	background-image: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='16' height='16' viewBox='0 0 24 24' fill='none' stroke='%23a89880' stroke-width='2'%3E%3Cpolyline points='6 9 12 15 18 9'/%3E%3C/svg%3E");
	background-repeat: no-repeat;
	background-position: right 14px center;
	padding-right: 40px;
}

.field textarea {
	min-height: 130px;
	resize: vertical;
}

.field-icon {
	position: relative;
}

.field-icon input {
	padding-left: 42px;
}

.field-icon .f-ico {
	position: absolute;
	left: 14px;
	top: 50%;
	transform: translateY(-50%);
	color: #c8ad82;
	font-size: 14px;
	pointer-events: none;
	transition: color .2s;
}

.field-icon:focus-within .f-ico {
	color: var(--blue-light);
}

.terrain-section {
	background: linear-gradient(135deg, rgba(5, 150, 105, .05), rgba(5, 150, 105, .02));
	border-radius: 20px;
	padding: 18px 20px;
	margin-top: 10px;
	border: 1.5px solid rgba(5, 150, 105, .15);
}

.terrain-section .section-label h3 i {
	color: var(--emerald);
}

.terrain-info {
	font-size: 12px;
	color: var(--emerald);
	background: rgba(5, 150, 105, .1);
	padding: 8px 12px;
	border-radius: 10px;
	margin-bottom: 15px;
	display: flex;
	align-items: center;
	gap: 8px;
}

.form-divider {
	height: 1.5px;
	background: linear-gradient(90deg, transparent, rgba(200, 134, 10, .1), transparent);
	margin: 26px 0;
}

.location-btn {
	display: inline-flex;
	align-items: center;
	gap: 8px;
	padding: 10px 18px;
	border-radius: 12px;
	border: none;
	cursor: pointer;
	background: linear-gradient(115deg, #0e2d82, var(--blue-light));
	color: white;
	font-family: 'DM Sans', sans-serif;
	font-size: 13px;
	font-weight: 600;
	transition: all .22s;
	box-shadow: 0 5px 14px rgba(31, 82, 212, .25);
}

.location-btn:hover {
	transform: translateY(-2px);
	box-shadow: 0 8px 20px rgba(31, 82, 212, .35);
}

.location-btn:nth-child(2) {
	background: #27ae60;
}

#map {
	height: 400px;
	border-radius: 15px;
	margin-top: 15px;
	z-index: 1;
}

.map-info {
	font-size: 12px;
	color: var(--soft);
	margin-top: 8px;
}

.custom-marker {
	background: none;
	border: none;
}

#addressInput {
	width: 100%;
	padding: 12px 14px;
	border-radius: 13px;
	border: 1.5px solid rgba(200, 134, 10, .15);
	font-family: 'DM Sans', sans-serif;
	font-size: 14px;
	margin-top: 10px;
	display: none;
}

.images-grid {
	display: grid;
	grid-template-columns: repeat(3, 1fr);
	gap: 16px;
}

.upload-box {
	border: 2px dashed rgba(200, 134, 10, .22);
	border-radius: 16px;
	padding: 22px 14px;
	text-align: center;
	cursor: pointer;
	background: var(--bg2);
	transition: all .25s;
	position: relative;
	overflow: hidden;
}

.upload-box:hover {
	border-color: var(--blue-light);
	background: var(--blue-pale);
	transform: translateY(-2px);
}

.upload-box.has-image {
	border-style: solid;
	border-color: var(--teal);
	background: var(--teal-pale);
}

.ub-icon {
	font-size: 30px;
	margin-bottom: 8px;
	display: block;
}

.ub-main {
	font-size: 13px;
	font-weight: 600;
	color: var(--dark);
	margin-bottom: 4px;
}

.ub-sub {
	font-size: 11px;
	color: var(--soft);
}

.req-dot {
	color: var(--rose);
}

.img-preview {
	margin-top: 12px;
}

.img-preview img {
	max-width: 100%;
	max-height: 90px;
	border-radius: 10px;
	object-fit: cover;
	border: 2px solid var(--teal);
}

.upload-badge {
	position: absolute;
	top: 10px;
	right: 10px;
	font-size: 9.5px;
	font-weight: 700;
	padding: 2px 8px;
	border-radius: 20px;
}

.ub-req {
	background: var(--rose-pale);
	color: var(--rose);
}

.ub-opt {
	background: var(--blue-pale);
	color: var(--blue-light);
}

.form-actions {
	display: flex;
	gap: 12px;
	margin-top: 32px;
	padding-top: 24px;
	border-top: 1.5px solid rgba(200, 134, 10, .08);
}

.btn-submit {
	display: inline-flex;
	align-items: center;
	gap: 9px;
	padding: 13px 28px;
	border-radius: 13px;
	border: none;
	cursor: pointer;
	font-family: 'Syne', sans-serif;
	font-weight: 700;
	font-size: 14.5px;
	background: linear-gradient(115deg, var(--teal), var(--teal-light));
	color: white;
	transition: all .25s;
	box-shadow: 0 6px 20px rgba(14, 158, 138, .3);
}

.btn-submit:hover {
	transform: translateY(-2px);
	box-shadow: 0 10px 28px rgba(14, 158, 138, .4);
}

.btn-cancel {
	display: inline-flex;
	align-items: center;
	gap: 8px;
	padding: 13px 22px;
	border-radius: 13px;
	cursor: pointer;
	font-family: 'DM Sans', sans-serif;
	font-weight: 600;
	font-size: 14px;
	background: var(--white);
	border: 1.5px solid rgba(200, 134, 10, .2);
	color: var(--mid);
	text-decoration: none;
	transition: all .22s;
}

.btn-cancel:hover {
	border-color: var(--rose);
	color: var(--rose);
}

::-webkit-scrollbar {
	width: 5px;
}

::-webkit-scrollbar-thumb {
	background: rgba(200, 134, 10, .2);
	border-radius: 4px;
}

@media ( max-width : 900px) {
	.sidebar {
		transform: translateX(-100%);
	}
	.main {
		margin-left: 0;
		padding: 20px;
	}
	.form-grid {
		grid-template-columns: 1fr;
	}
	.span2 {
		grid-column: span 1;
	}
	.images-grid {
		grid-template-columns: 1fr;
	}
}

/* Mode sombre */
body.dark-theme {
    background: #060c1a;
    color: #e0e8ff;
}
body.dark-theme .sidebar {
    background: linear-gradient(160deg, #050a18 0%, #0d1626 45%, #0a1030 75%, #040818 100%);
}
body.dark-theme .form-card {
    background: #0d1626;
    border-color: rgba(255,255,255,.08);
}
body.dark-theme .field input,
body.dark-theme .field select,
body.dark-theme .field textarea {
    background: #111e36;
    border-color: rgba(255,255,255,.1);
    color: #e0e8ff;
}
body.dark-theme .page-title h1 {
    color: #e0e8ff;
}
body.dark-theme .breadcrumb,
body.dark-theme .breadcrumb a {
    color: #6070a0;
}
body.dark-theme .upload-box {
    background: #111e36;
    border-color: rgba(255,255,255,.1);
}
body.dark-theme .btn-cancel {
    background: #0d1626;
    border-color: rgba(255,255,255,.15);
    color: #6070a0;
}
body.dark-theme .icon-circle {
    background: #0d1626;
    border-color: rgba(255,255,255,.1);
    color: #6070a0;
}
body.dark-theme .location-btn {
    background: #0e2d82;
}

/* Transition pour la couleur principale */
:root {
    --gold: #c8860a;
    --gold-light: #e8a220;
    transition: --gold 0.3s ease;
}

button, .btn, .nav-item.active, .stat-card, .btn-submit {
    transition: background 0.3s ease, border-color 0.3s ease;
}
</style>
</head>
<body>

	<canvas id="bgCanvas"></canvas>

	<div class="layout">

		<aside class="sidebar">
			<div class="sidebar-grid"></div>

			<div class="logo-area">
				<img src="${pageContext.request.contextPath}/immo/admin/images/Logo.jpg"
				     alt="Fredon"
				     class="logo-mark"
				     onmouseover="this.style.transform='scale(1.05)'"
				     onmouseout="this.style.transform='scale(1)'">
				<div class="logo-text-wrap">
					<span class="logo-name">Fredon</span>
					<span class="logo-sub">Commerce & Construction</span>
				</div>
			</div>

			<nav class="nav">
				<div class="nav-section"><%= TranslateUtil.t(lang, "principal") %></div>
				<a href="${pageContext.request.contextPath}/admin/dashboard" class="nav-item"> 
					<i class="fas fa-chart-line"></i> <%= TranslateUtil.t(lang, "dashboard") %>
				</a>
				<a href="${pageContext.request.contextPath}/admin/add-property" class="nav-item active"> 
					<i class="fas fa-plus-circle"></i> <%= TranslateUtil.t(lang, "add") %> <%= TranslateUtil.t(lang, "property") %>
				</a>
				<a href="${pageContext.request.contextPath}/chat" class="nav-item">
					<i class="fas fa-comments"></i> <%= TranslateUtil.t(lang, "messages") %>
					<% if (unreadMessages > 0) { %> 
					<span class="nav-badge"><%= unreadMessages %></span> 
					<% } %>
				</a>

				<div class="nav-section"><%= TranslateUtil.t(lang, "management") %></div>
				<a href="${pageContext.request.contextPath}/admin/clients" class="nav-item"> 
					<i class="fas fa-users"></i> <%= TranslateUtil.t(lang, "clients") %>
				</a>
				
				<a href="${pageContext.request.contextPath}/admin/appointments" class="nav-item"> 
					<i class="fas fa-calendar-check"></i> <%= TranslateUtil.t(lang, "appointments") %>
					<% if (pendingAppointments > 0) { %> 
					<span class="nav-badge" style="background: var(--gold);"><%= pendingAppointments %></span>
					<% } %>
				</a>
				
				<a href="${pageContext.request.contextPath}/admin/statistics" class="nav-item"> 
					<i class="fas fa-chart-pie"></i> <%= TranslateUtil.t(lang, "statistics") %>
				</a>

				<div class="nav-section"><%= TranslateUtil.t(lang, "system") %></div>
				<a href="${pageContext.request.contextPath}/" class="nav-item"> 
					<i class="fas fa-globe"></i> <%= TranslateUtil.t(lang, "view_site") %>
				</a>
				<a href="${pageContext.request.contextPath}/admin/setting" class="nav-item"> 
					<i class="fas fa-cog"></i> <%= TranslateUtil.t(lang, "settings") %>
				</a>
				<a href="${pageContext.request.contextPath}/logout" class="nav-item logout"> 
					<i class="fas fa-sign-out-alt"></i> <%= TranslateUtil.t(lang, "logout") %>
				</a>
			</nav>

			<div class="user-bottom">
				<div class="u-avatar">
				    <% if (adminProfilePic != null && !adminProfilePic.isEmpty()) { %>
				        <img src="${pageContext.request.contextPath}/avatars/<%= adminProfilePic %>" style="width:100%;height:100%;object-fit:cover;border-radius:12px;">
				    <% } else { %>
				        <%= adminInitial %>
				    <% } %>
				</div>
				<div class="u-info">
					<div class="u-name"><%= adminName %></div>
					<div class="u-role"><%= TranslateUtil.t(lang, "admin") %></div>
				</div>
				<div class="u-dot"></div>
			</div>
		</aside>

		<main class="main">

			<div class="top-bar">
				<div class="page-title">
					<h1><%= TranslateUtil.t(lang, "publish_property") %> 🏠</h1>
					<p><%= TranslateUtil.t(lang, "fill_form_to_publish") %></p>
				</div>
				<div class="top-right">
					<a href="${pageContext.request.contextPath}/admin/dashboard" class="icon-circle" title="<%= TranslateUtil.t(lang, "back_to_dashboard") %>">
						<i class="fas fa-arrow-left"></i>
					</a>
					<a href="${pageContext.request.contextPath}/admin/notifications" class="notif-wrap">
						<div class="icon-circle">
							<i class="fas fa-bell"></i>
							<% if (notifCount > 0) { %>
							<span class="notif-pip"><%= notifCount > 9 ? "9+" : notifCount %></span>
							<% } %>
						</div>
					</a>
					<a href="${pageContext.request.contextPath}/admin/setting" class="icon-circle">
						<i class="fas fa-cog"></i>
					</a>
				</div>
			</div>

			<div class="breadcrumb">
				<i class="fas fa-home" style="color: var(--gold); font-size: 11px;"></i>
				<a href="${pageContext.request.contextPath}/admin/dashboard"><%= TranslateUtil.t(lang, "dashboard") %></a>
				<span class="sep">›</span> 
				<span class="current"><%= TranslateUtil.t(lang, "add_property") %></span>
			</div>

			<% if (error != null) { %>
			<div class="alert alert-error">
				<i class="fas fa-exclamation-circle"></i> <span><%= error %></span>
			</div>
			<% } %>

			<div class="form-card">
				<div class="form-header">
					<div class="fh-icon" style="background: var(--teal-pale); color: var(--teal);">
						<i class="fas fa-home"></i>
					</div>
					<div>
						<div class="fh-title"><%= TranslateUtil.t(lang, "property_information") %></div>
						<div class="fh-sub"><%= TranslateUtil.t(lang, "required_fields_marked") %> <span style="color: var(--rose);">*</span> <%= TranslateUtil.t(lang, "are_required") %></div>
					</div>
				</div>

				<div class="form-body">
					<form action="${pageContext.request.contextPath}/admin/add-property" method="POST" enctype="multipart/form-data">

						<div class="section-label">
							<div class="sl-bar sl-blue"></div>
							<h3>
								<i class="fas fa-info-circle" style="color: var(--blue-light); margin-right: 7px;"></i>
								<%= TranslateUtil.t(lang, "general_information") %>
							</h3>
						</div>

						<div class="form-grid">
							<div class="field span2">
								<label><%= TranslateUtil.t(lang, "property_title") %> *</label>
								<div class="field-icon">
									<i class="fas fa-tag f-ico"></i> 
									<input type="text" name="title" placeholder="<%= TranslateUtil.t(lang, "title_placeholder") %>" required>
								</div>
							</div>
							<div class="field">
							    <label><%= TranslateUtil.t(lang, "price") %> (Ar) *</label>
							    <div class="field-icon">
							        <i class="fas fa-coins f-ico"></i> 
							        <input type="text" name="price" id="priceInput" placeholder="<%= TranslateUtil.t(lang, "price_placeholder") %>" required onkeypress="return event.charCode >= 48 && event.charCode <= 57">
							    </div>
							</div>

							<div class="field">
								<label><%= TranslateUtil.t(lang, "offer_type") %> *</label> 
								<select name="type" id="propertyTypeSelect" required>
									<option value="">-- <%= TranslateUtil.t(lang, "select_type") %> --</option>
									<option value="Vente">🏠 <%= TranslateUtil.t(lang, "sale") %> (Maison/Appartement)</option>
									<option value="Location">🔑 <%= TranslateUtil.t(lang, "rent") %> (Maison/Appartement)</option>
									<option value="Terrain">🌾 <%= TranslateUtil.t(lang, "land") %> à vendre</option>
								</select>
							</div>
						</div>

						<div id="houseFeatures" class="dynamic-section">
							<div class="form-divider"></div>
							<div class="section-label">
								<div class="sl-bar sl-teal"></div>
								<h3>
									<i class="fas fa-ruler-combined" style="color: var(--teal); margin-right: 7px;"></i>
									<%= TranslateUtil.t(lang, "property_features") %>
								</h3>
							</div>

							<div class="form-grid">
								<div class="field">
									<label><%= TranslateUtil.t(lang, "surface") %> (m²)</label>
									<div class="field-icon">
										<i class="fas fa-expand f-ico"></i> 
										<input type="number" name="surface" min="0" id="surfaceInput" placeholder="<%= TranslateUtil.t(lang, "surface_placeholder") %>">
									</div>
								</div>

								<div class="field">
									<label><%= TranslateUtil.t(lang, "rooms") %></label>
									<div class="field-icon">
										<i class="fas fa-door-open f-ico"></i> 
										<input type="number" name="rooms" min="0" id="roomsInput" placeholder="<%= TranslateUtil.t(lang, "rooms_placeholder") %>">
									</div>
								</div>

								<div class="field">
									<label><%= TranslateUtil.t(lang, "bedrooms") %></label>
									<div class="field-icon">
										<i class="fas fa-bed f-ico"></i> 
										<input type="number" name="bedrooms" min="0" id="bedroomsInput" placeholder="<%= TranslateUtil.t(lang, "bedrooms_placeholder") %>">
									</div>
								</div>

								<div class="field">
									<label><%= TranslateUtil.t(lang, "bathrooms") %></label>
									<div class="field-icon">
										<i class="fas fa-bath f-ico"></i> 
										<input type="number" name="bathrooms" min="0" id="bathroomsInput" placeholder="<%= TranslateUtil.t(lang, "bathrooms_placeholder") %>">
									</div>
								</div>
							</div>
						</div>

						<div id="terrainFeatures" class="dynamic-section" style="display: none;">
							<div class="form-divider"></div>
							<div class="section-label">
								<div class="sl-bar" style="background: var(--emerald);"></div>
								<h3>
									<i class="fas fa-map" style="color: var(--emerald); margin-right: 7px;"></i>
									<%= TranslateUtil.t(lang, "land_features") %>
								</h3>
							</div>

							<div class="terrain-section">
								<div class="terrain-info">
									<i class="fas fa-info-circle"></i> 
									<%= TranslateUtil.t(lang, "land_info") %>
								</div>

								<div class="form-grid">
									<div class="field">
										<label><%= TranslateUtil.t(lang, "land_area") %></label>
										<div class="field-icon">
											<i class="fas fa-vector-square f-ico"></i> 
											<input type="text" name="landArea" id="landArea" placeholder="<%= TranslateUtil.t(lang, "land_area_placeholder") %>">
										</div>
									</div>

									<div class="field">
										<label><%= TranslateUtil.t(lang, "land_type") %></label>
										<select name="landType" id="landType">
											<option value="">-- <%= TranslateUtil.t(lang, "select_land_type") %> --</option>
											<option value="Constructible">🏗️ <%= TranslateUtil.t(lang, "buildable") %></option>
											<option value="Non constructible">🌿 <%= TranslateUtil.t(lang, "non_buildable") %></option>
											<option value="Agricole">🌾 <%= TranslateUtil.t(lang, "agricultural") %></option>
											<option value="Commercial">🏢 <%= TranslateUtil.t(lang, "commercial") %></option>
										</select>
									</div>

									<div class="field">
										<label><%= TranslateUtil.t(lang, "documentation") %></label>
										<select name="landDocumentation" id="landDocumentation">
											<option value="">-- <%= TranslateUtil.t(lang, "select_documentation") %> --</option>
											<option value="Titre foncier">📜 <%= TranslateUtil.t(lang, "land_title") %></option>
											<option value="Certificat de propriété">📄 <%= TranslateUtil.t(lang, "property_certificate") %></option>
											<option value="En cours">⏳ <%= TranslateUtil.t(lang, "in_progress") %></option>
										</select>
									</div>

									<div class="field">
										<label><%= TranslateUtil.t(lang, "access") %></label>
										<select name="landAccess" id="landAccess">
											<option value="">-- <%= TranslateUtil.t(lang, "select_access") %> --</option>
											<option value="Route goudronnée">🛣️ <%= TranslateUtil.t(lang, "paved_road") %></option>
											<option value="Piste">🚜 <%= TranslateUtil.t(lang, "dirt_road") %></option>
											<option value="Voie d'accès">🚶 <%= TranslateUtil.t(lang, "foot_path") %></option>
										</select>
									</div>

									<div class="field span2">
										<label><%= TranslateUtil.t(lang, "proximities") %></label>
										<div class="field-icon">
											<i class="fas fa-city f-ico"></i>
											<input type="text" name="landProximities" id="landProximities" placeholder="<%= TranslateUtil.t(lang, "proximities_placeholder") %>">
										</div>
									</div>

									<div class="field span2">
										<label><%= TranslateUtil.t(lang, "other_info") %></label>
										<textarea name="landNotes" id="landNotes" rows="3" placeholder="<%= TranslateUtil.t(lang, "land_notes_placeholder") %>"></textarea>
									</div>
								</div>
							</div>
						</div>

						<div class="form-divider"></div>

						<div class="field span2">
							<label><%= TranslateUtil.t(lang, "description") %> *</label>
							<textarea name="description" id="description" placeholder="<%= TranslateUtil.t(lang, "description_placeholder") %>" required></textarea>
						</div>

						<div class="form-divider"></div>

						<div class="section-label">
							<div class="sl-bar sl-rose"></div>
							<h3>
								<i class="fas fa-map-marker-alt" style="color: var(--rose); margin-right: 7px;"></i>
								<%= TranslateUtil.t(lang, "gps_location") %>
							</h3>
						</div>

						<div class="form-grid">
							<div class="field span2">
								<label><%= TranslateUtil.t(lang, "address_neighborhood") %> *</label>
								<div class="field-icon">
									<i class="fas fa-map-marker-alt f-ico"></i> 
									<input type="text" name="location" placeholder="<%= TranslateUtil.t(lang, "address_placeholder") %>" required>
								</div>
							</div>

							<div class="field span2">
								<label><%= TranslateUtil.t(lang, "gps_coordinates") %> (<%= TranslateUtil.t(lang, "optional") %>)</label>
								<div style="display: grid; grid-template-columns: 1fr 1fr; gap: 15px;">
									<input type="text" id="latitude" name="latitude" placeholder="<%= TranslateUtil.t(lang, "latitude") %>" readonly style="background: #f0f0f0; padding: 12px 14px; border-radius: 13px; border: 1.5px solid rgba(200, 134, 10, .15);">
									<input type="text" id="longitude" name="longitude" placeholder="<%= TranslateUtil.t(lang, "longitude") %>" readonly style="background: #f0f0f0; padding: 12px 14px; border-radius: 13px; border: 1.5px solid rgba(200, 134, 10, .15);">
								</div>

								<div style="margin: 15px 0; display: flex; gap: 10px; flex-wrap: wrap;">
									<button type="button" class="location-btn" onclick="getCurrentLocation()">
										<i class="fas fa-location-dot"></i> <%= TranslateUtil.t(lang, "use_my_location") %>
									</button>
									<button type="button" class="location-btn" onclick="searchAddress()" style="background: #27ae60;">
										<i class="fas fa-search"></i> <%= TranslateUtil.t(lang, "search_address") %>
									</button>
								</div>

								<div id="map"></div>
								<p class="map-info">
									<i class="fas fa-info-circle"></i> <%= TranslateUtil.t(lang, "map_instruction") %>
								</p>
								<input type="text" id="addressInput" placeholder="<%= TranslateUtil.t(lang, "enter_address") %>">
							</div>
						</div>

						<div class="form-divider"></div>

						<div class="section-label">
							<div class="sl-bar sl-gold"></div>
							<h3>
								<i class="fas fa-images" style="color: var(--gold); margin-right: 7px;"></i>
								<%= TranslateUtil.t(lang, "property_photos") %>
							</h3>
						</div>

						<div class="images-grid">
							<div class="upload-box" id="box1" onclick="document.getElementById('image1').click()">
								<span class="upload-badge ub-req"><%= TranslateUtil.t(lang, "required") %></span>
								<span class="ub-icon">🖼️</span>
								<div class="ub-main"><%= TranslateUtil.t(lang, "main_image") %> <span class="req-dot">*</span></div>
								<div class="ub-sub"><%= TranslateUtil.t(lang, "click_to_select") %></div>
								<input type="file" id="image1" name="image1" accept="image/*" style="display: none;" required onchange="previewImage(this,'preview1','box1')">
								<div id="preview1" class="img-preview"></div>
							</div>

							<div class="upload-box" id="box2" onclick="document.getElementById('image2').click()">
								<span class="upload-badge ub-opt"><%= TranslateUtil.t(lang, "optional") %></span>
								<span class="ub-icon">📷</span>
								<div class="ub-main"><%= TranslateUtil.t(lang, "image") %> 2</div>
								<div class="ub-sub"><%= TranslateUtil.t(lang, "click_to_select") %></div>
								<input type="file" id="image2" name="image2" accept="image/*" style="display: none;" onchange="previewImage(this,'preview2','box2')">
								<div id="preview2" class="img-preview"></div>
							</div>

							<div class="upload-box" id="box3" onclick="document.getElementById('image3').click()">
								<span class="upload-badge ub-opt"><%= TranslateUtil.t(lang, "optional") %></span>
								<span class="ub-icon">📸</span>
								<div class="ub-main"><%= TranslateUtil.t(lang, "image") %> 3</div>
								<div class="ub-sub"><%= TranslateUtil.t(lang, "click_to_select") %></div>
								<input type="file" id="image3" name="image3" accept="image/*" style="display: none;" onchange="previewImage(this,'preview3','box3')">
								<div id="preview3" class="img-preview"></div>
							</div>
						</div>

						<div class="form-actions">
							<button type="submit" class="btn-submit">
								<i class="fas fa-paper-plane"></i> <%= TranslateUtil.t(lang, "publish_property") %>
							</button>
							<a href="${pageContext.request.contextPath}/admin/dashboard" class="btn-cancel">
								<i class="fas fa-times"></i> <%= TranslateUtil.t(lang, "cancel") %>
							</a>
						</div>

					</form>
				</div>
			</div>

		</main>
	</div>

	<script src="https://unpkg.com/leaflet@1.9.4/dist/leaflet.js"></script>

	<script>
/* ══ CANVAS BACKGROUND ══ */
(function() {
    const canvas = document.getElementById('bgCanvas');
    const ctx = canvas.getContext('2d');
    let W, H, houses = [];

    function resize() { W = canvas.width = window.innerWidth; H = canvas.height = window.innerHeight; }
    resize();
    window.addEventListener('resize', resize);

    function drawHouse(ctx, x, y, s, alpha, color) {
        ctx.save();
        ctx.globalAlpha = alpha;
        ctx.strokeStyle = color;
        ctx.fillStyle   = color;
        ctx.lineWidth   = 1.4 * s;
        ctx.translate(x, y);
        ctx.beginPath(); ctx.rect(-14*s, -8*s, 28*s, 20*s); ctx.stroke();
        ctx.beginPath(); ctx.moveTo(-17*s, -8*s); ctx.lineTo(0, -22*s); ctx.lineTo(17*s, -8*s); ctx.closePath(); ctx.stroke();
        ctx.beginPath(); ctx.arc(0, 7*s, 5*s, Math.PI, 0); ctx.rect(-5*s, 2*s, 10*s, 5*s); ctx.stroke();
        ctx.strokeRect(-12*s, -5*s, 7*s, 6*s);
        ctx.strokeRect(5*s, -5*s, 7*s, 6*s);
        ctx.fillRect(5*s, -24*s, 4*s, 8*s);
        ctx.restore();
    }

    const COLORS = ['#1f52d4','#c8860a','#0e9e8a','#e03060','#7c3aed','#0e7490','#b45309','#166534'];

    for (let i = 0; i < 16; i++) {
        houses.push({
            x: Math.random() * 1600, y: Math.random() * 900,
            s: 0.5 + Math.random() * 1.3,
            alpha: 0.04 + Math.random() * 0.055,
            color: COLORS[Math.floor(Math.random() * COLORS.length)],
            vx: (Math.random() - 0.5) * 0.11,
            vy: (Math.random() - 0.5) * 0.09,
        });
    }

    function animate() {
        ctx.clearRect(0, 0, W, H);
        houses.forEach(h => {
            h.x += h.vx; h.y += h.vy;
            if (h.x < -100) h.x = W + 60;
            if (h.x > W+100) h.x = -60;
            if (h.y < -100) h.y = H + 60;
            if (h.y > H+100) h.y = -60;
            drawHouse(ctx, h.x, h.y, h.s, h.alpha, h.color);
        });
        requestAnimationFrame(animate);
    }
    animate();
})();

function previewImage(input, previewId, boxId) {
    if (input.files && input.files[0]) {
        var reader = new FileReader();
        reader.onload = function(e) {
            document.getElementById(previewId).innerHTML = '<img src="' + e.target.result + '" alt="Aperçu">';
            document.getElementById(boxId).classList.add('has-image');
        };
        reader.readAsDataURL(input.files[0]);
    }
}

/* ══ FORMULAIRE DYNAMIQUE : MAISON vs TERRAIN ══ */
function togglePropertyType() {
    var typeSelect = document.getElementById('propertyTypeSelect');
    var houseSection = document.getElementById('houseFeatures');
    var terrainSection = document.getElementById('terrainFeatures');
    var selectedType = typeSelect.value;
    
    var surfaceInput = document.getElementById('surfaceInput');
    var roomsInput = document.getElementById('roomsInput');
    var bedroomsInput = document.getElementById('bedroomsInput');
    var bathroomsInput = document.getElementById('bathroomsInput');
    
    var landArea = document.getElementById('landArea');
    var landType = document.getElementById('landType');
    var landDocumentation = document.getElementById('landDocumentation');
    var landAccess = document.getElementById('landAccess');
    var landProximities = document.getElementById('landProximities');
    var landNotes = document.getElementById('landNotes');
    
    if (selectedType === 'Terrain') {
        houseSection.style.display = 'none';
        terrainSection.style.display = 'block';
        
        if(surfaceInput) surfaceInput.disabled = true;
        if(roomsInput) roomsInput.disabled = true;
        if(bedroomsInput) bedroomsInput.disabled = true;
        if(bathroomsInput) bathroomsInput.disabled = true;
        
        if(landArea) landArea.disabled = false;
        if(landType) landType.disabled = false;
        if(landDocumentation) landDocumentation.disabled = false;
        if(landAccess) landAccess.disabled = false;
        if(landProximities) landProximities.disabled = false;
        if(landNotes) landNotes.disabled = false;
        
        var desc = document.getElementById('description');
        if(desc) desc.placeholder = "<%= TranslateUtil.t(lang, "land_description_placeholder") %>";
        
    } else {
        houseSection.style.display = 'block';
        terrainSection.style.display = 'none';
        
        if(surfaceInput) surfaceInput.disabled = false;
        if(roomsInput) roomsInput.disabled = false;
        if(bedroomsInput) bedroomsInput.disabled = false;
        if(bathroomsInput) bathroomsInput.disabled = false;
        
        if(landArea) landArea.disabled = true;
        if(landType) landType.disabled = true;
        if(landDocumentation) landDocumentation.disabled = true;
        if(landAccess) landAccess.disabled = true;
        if(landProximities) landProximities.disabled = true;
        if(landNotes) landNotes.disabled = true;
        
        var desc = document.getElementById('description');
        if(desc) desc.placeholder = "<%= TranslateUtil.t(lang, "description_placeholder") %>";
    }
}

var typeSelect = document.getElementById('propertyTypeSelect');
if(typeSelect) {
    typeSelect.addEventListener('change', togglePropertyType);
    togglePropertyType();
}

/* ══ CARTE ══ */
var map;
var marker;
var currentLat = -18.8792;
var currentLng = 47.5079;

function initMap(lat, lng) {
    if (map) {
        map.remove();
    }
    
    map = L.map('map').setView([lat, lng], 15);
    
    L.tileLayer('https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png', {
        attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OSM</a> &copy; CartoDB',
        subdomains: 'abcd',
        maxZoom: 19,
        minZoom: 3
    }).addTo(map);
    
    var customIcon = L.divIcon({
        html: '<i class="fas fa-map-marker-alt" style="font-size: 32px; color: #e74c3c; text-shadow: 0 2px 4px rgba(0,0,0,0.3);"></i>',
        iconSize: [32, 32],
        className: 'custom-marker'
    });
    
    marker = L.marker([lat, lng], { draggable: true, icon: customIcon }).addTo(map);
    
    marker.on('dragend', function(e) {
        var pos = marker.getLatLng();
        document.getElementById('latitude').value = pos.lat.toFixed(6);
        document.getElementById('longitude').value = pos.lng.toFixed(6);
    });
    
    map.on('click', function(e) {
        marker.setLatLng(e.latlng);
        document.getElementById('latitude').value = e.latlng.lat.toFixed(6);
        document.getElementById('longitude').value = e.latlng.lng.toFixed(6);
    });
}

function getCurrentLocation() {
    if (navigator.geolocation) {
        navigator.geolocation.getCurrentPosition(function(position) {
            currentLat = position.coords.latitude;
            currentLng = position.coords.longitude;
            initMap(currentLat, currentLng);
            marker.setLatLng([currentLat, currentLng]);
            document.getElementById('latitude').value = currentLat.toFixed(6);
            document.getElementById('longitude').value = currentLng.toFixed(6);
        }, function() {
            alert("<%= TranslateUtil.t(lang, "location_error") %>");
            initMap(currentLat, currentLng);
        });
    } else {
        alert("<%= TranslateUtil.t(lang, "geolocation_not_supported") %>");
        initMap(currentLat, currentLng);
    }
}

function searchAddress() {
    var address = prompt("<%= TranslateUtil.t(lang, "enter_address_prompt") %>");
    if (address && address.trim()) {
        fetch('https://nominatim.openstreetmap.org/search?format=json&q=' + encodeURIComponent(address) + '&limit=1')
            .then(response => response.json())
            .then(data => {
                if (data && data.length > 0) {
                    var lat = parseFloat(data[0].lat);
                    var lng = parseFloat(data[0].lon);
                    initMap(lat, lng);
                    marker.setLatLng([lat, lng]);
                    document.getElementById('latitude').value = lat.toFixed(6);
                    document.getElementById('longitude').value = lng.toFixed(6);
                } else {
                    alert("<%= TranslateUtil.t(lang, "address_not_found") %>");
                }
            })
            .catch(error => {
                console.error("Erreur:", error);
                alert("<%= TranslateUtil.t(lang, "address_search_error") %>");
            });
    }
}

document.addEventListener('DOMContentLoaded', function() {
    var latInput = document.getElementById('latitude');
    var lngInput = document.getElementById('longitude');
    
    if (latInput && latInput.value && lngInput && lngInput.value) {
        currentLat = parseFloat(latInput.value);
        currentLng = parseFloat(lngInput.value);
    }
    
    initMap(currentLat, currentLng);
    
    if (latInput && latInput.value) {
        marker.setLatLng([currentLat, currentLng]);
    }
});

(function() {
    var theme = localStorage.getItem('fredon_theme');
    if (theme === 'dark') {
        document.body.classList.add('dark-theme');
        document.body.classList.add('dm');
    } else {
        document.body.classList.add('light-theme');
    }
})();

//Empêche l'accès aux pages après déconnexion
if (performance.navigation.type === 2) {
 window.location.href = '${pageContext.request.contextPath}/login';
}

</script>
</body>
</html>