<%@ page language="java" contentType="text/html; charset=UTF-8"
	pageEncoding="UTF-8"%>
<%@ page import="java.util.*, java.text.*, java.sql.*"%>
<%@ page import="com.quickchat.model.User"%>

<%
    User currentUser = (User) session.getAttribute("user");
    if (currentUser == null) {
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    }

    String DB_URL = "jdbc:mysql://localhost:3306/quickchat";
    String DB_USER = "root";
    String DB_PASSWORD = "";

    List<Map<String, Object>> notifications = new ArrayList<>();
    int unreadCount = 0;

    try {
        Class.forName("com.mysql.cj.jdbc.Driver");
        Connection conn = DriverManager.getConnection(DB_URL, DB_USER, DB_PASSWORD);
        
        String sql = "SELECT * FROM notifications WHERE user_id = ? ORDER BY created_at DESC LIMIT 50";
        PreparedStatement pstmt = conn.prepareStatement(sql);
        pstmt.setInt(1, currentUser.getId());
        ResultSet rs = pstmt.executeQuery();
        
        while (rs.next()) {
            Map<String, Object> notif = new HashMap<>();
            notif.put("id", rs.getInt("id"));
            notif.put("type", rs.getString("type"));
            notif.put("title", rs.getString("title"));
            notif.put("message", rs.getString("message"));
            notif.put("link", rs.getString("link"));
            notif.put("is_read", rs.getBoolean("is_read"));
            notif.put("created_at", rs.getTimestamp("created_at"));
            notifications.add(notif);
            if (!rs.getBoolean("is_read")) unreadCount++;
        }
        rs.close();
        pstmt.close();
        conn.close();
        
    } catch (Exception e) {
        e.printStackTrace();
    }
    
    String userName = currentUser.getDisplayName() != null ? currentUser.getDisplayName() : currentUser.getUsername();
    String userInitial = userName.substring(0, 1).toUpperCase();
    
    // Compter les messages non lus
    int unreadMessagesCount = 0;
    try {
        com.quickchat.dao.MessageDAO messageDAO = new com.quickchat.dao.MessageDAO();
        unreadMessagesCount = messageDAO.countUnreadMessagesForUser(currentUser.getId());
    } catch (Exception e) {}
%>

<!DOCTYPE html>
<html lang="fr">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Mes notifications — Fredon Immobilier</title>
<link
	href="https://fonts.googleapis.com/css2?family=Syne:wght@400;600;700;800&family=DM+Sans:opsz,wght@9..40,300;9..40,400;9..40,500;9..40,600;9..40,700&family=Playfair+Display:ital,wght@0,700;1,600&display=swap"
	rel="stylesheet">
<link rel="stylesheet"
	href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css">
<style>
:root {
	--blue: #1f52d4;
	--blue2: #0e2d82;
	--blue3: #4f7ef8;
	--gold: #b8900e;
	--gold2: #e8a820;
	--gold3: #fff0c8;
	--teal: #0e9e8a;
	--rose: #e03060;
	--emerald: #059669;
	--bg: #f2f0ea;
	--bg2: #ebe8e0;
	--surface: #ffffff;
	--s2: #f7f5f0;
	--s3: #ede9e0;
	--border: rgba(0, 0, 0, .07);
	--bh: rgba(0, 0, 0, .13);
	--tx: #111520;
	--tx2: #4b4637;
	--tx3: #9b9080;
	--bl: rgba(31, 82, 212, .08);
	--gl: rgba(184, 144, 14, .09);
	--hh: 68px;
	--rouge: #dc2626;
}

body.dm {
	--bg: #060c1a;
	--bg2: #090f1e;
	--surface: #0d1626;
	--s2: #111e36;
	--s3: #162340;
	--border: rgba(255, 255, 255, .05);
	--bh: rgba(255, 255, 255, .1);
	--tx: #e0e8ff;
	--tx2: #6070a0;
	--tx3: #2a3555;
	--bl: rgba(31, 82, 212, .15);
	--gl: rgba(184, 144, 14, .12);
}

*, *::before, *::after {
	box-sizing: border-box;
	margin: 0;
	padding: 0;
}

html {
	scroll-behavior: smooth;
}

body {
	font-family: 'DM Sans', sans-serif;
	background: var(--bg);
	color: var(--tx);
	overflow-x: hidden;
	transition: background .4s, color .4s;
}

::-webkit-scrollbar {
	width: 4px;
}

::-webkit-scrollbar-thumb {
	background: linear-gradient(var(--blue), var(--gold));
	border-radius: 99px;
}

.toast-container {
	position: fixed;
	top: 80px;
	right: 20px;
	z-index: 9999;
	display: flex;
	flex-direction: column;
	gap: 10px;
	pointer-events: none;
}

.toast {
	display: flex;
	align-items: center;
	gap: 12px;
	padding: 14px 18px;
	border-radius: 16px;
	min-width: 280px;
	background: var(--surface);
	border: 1.5px solid rgba(0, 0, 0, .08);
	box-shadow: 0 16px 48px rgba(0, 0, 0, .15);
	pointer-events: all;
	animation: toastIn .4s cubic-bezier(.22, .97, .45, 1) both;
	font-size: 13.5px;
	font-weight: 500;
}

.toast.exit {
	animation: toastOut .35s ease forwards;
}

.toast-icon {
	width: 34px;
	height: 34px;
	border-radius: 10px;
	flex-shrink: 0;
	display: flex;
	align-items: center;
	justify-content: center;
	font-size: 14px;
}

.toast-success .toast-icon {
	background: rgba(5, 150, 105, .12);
	color: var(--emerald);
}

.toast-info .toast-icon {
	background: rgba(31, 82, 212, .1);
	color: var(--blue);
}

.toast-msg {
	flex: 1;
}

.toast-close {
	background: none;
	border: none;
	cursor: pointer;
	color: var(--tx3);
	font-size: 16px;
	padding: 2px 4px;
}

@
keyframes toastIn {
	from {opacity: 0;
	transform: translateX(60px) scale(.92);
}

to {
	opacity: 1;
	transform: translateX(0) scale(1);
}

}
@
keyframes toastOut {
	from {opacity: 1;
	transform: translateX(0);
}

to {
	opacity: 0;
	transform: translateX(60px);
}

}
.header {
	position: sticky;
	top: 0;
	z-index: 800;
	height: var(--hh);
	background: rgba(242, 240, 234, .95);
	backdrop-filter: blur(28px);
	border-bottom: 1px solid var(--border);
	transition: background .4s, box-shadow .3s;
}

body.dm .header {
	background: rgba(6, 12, 26, .95);
}

.header.scrolled {
	box-shadow: 0 4px 32px rgba(14, 45, 130, .12);
}

.header-inner {
	max-width: 1400px;
	margin: 0 auto;
	height: 100%;
	padding: 0 36px;
	display: flex;
	align-items: center;
	gap: 16px;
	justify-content: space-between;
}

.logo {
	display: flex;
	align-items: center;
	gap: 11px;
	text-decoration: none;
	cursor: pointer;
}

.logo-svg {
	width: 40px;
	height: 40px;
	flex-shrink: 0;
	filter: drop-shadow(0 3px 12px rgba(14, 45, 130, .22));
	transition: transform .3s;
}

.logo:hover .logo-svg {
	transform: scale(1.07) rotate(-3deg);
}

.logo-name {
	font-family: 'Syne', sans-serif;
	font-weight: 800;
	font-size: 20px;
	background: linear-gradient(130deg, var(--blue2), var(--blue) 50%,
		var(--gold));
	-webkit-background-clip: text;
	background-clip: text;
	color: transparent;
}

.logo-sub {
	font-size: 8.5px;
	color: var(--tx3);
	letter-spacing: 2.2px;
	text-transform: uppercase;
	margin-top: 2px;
}

.nav {
	display: flex;
	align-items: center;
	gap: 2px;
}

.nav a {
	display: flex;
	align-items: center;
	gap: 7px;
	padding: 7px 14px;
	border-radius: 11px;
	color: var(--tx2);
	font-size: 13px;
	font-weight: 500;
	text-decoration: none;
	transition: all .2s;
	position: relative;
	cursor: pointer;
}

.nav a i {
	font-size: 10px;
}

.nav a:hover {
	color: var(--blue);
	background: var(--bl);
}

.nav a.active {
	color: var(--blue);
	background: var(--bl);
	font-weight: 600;
}

.msg-link {
	position: relative;
}

.msg-badge-dot {
	position: absolute;
	top: -1px;
	right: -1px;
	min-width: 18px;
	height: 18px;
	padding: 0 5px;
	background: var(--rouge);
	color: #fff;
	font-size: 9.5px;
	font-weight: 800;
	border-radius: 99px;
	display: flex;
	align-items: center;
	justify-content: center;
	border: 2px solid var(--bg);
	box-shadow: 0 0 0 2px rgba(220, 38, 38, .35), 0 3px 12px
		rgba(220, 38, 38, .45);
	animation: badgePulse 1.8s ease-in-out infinite;
	line-height: 1;
}

@
keyframes badgePulse { 0%,100% {
	box-shadow: 0 0 0 2px rgba(220, 38, 38, .35), 0 3px 12px
		rgba(220, 38, 38, .45);
}

50
%
{
box-shadow
:
0
0
0
5px
rgba(
220
,
38
,
38
,
.15
)
,
0
3px
16px
rgba(
220
,
38
,
38
,
.6
);
}
}
.hright {
	display: flex;
	align-items: center;
	gap: 9px;
}

.toggle-btn {
	width: 44px;
	height: 24px;
	border-radius: 99px;
	background: var(--bg2);
	border: 1.5px solid var(--bh);
	cursor: pointer;
	position: relative;
	transition: all .3s;
	flex-shrink: 0;
}

.toggle-btn.on {
	background: linear-gradient(135deg, var(--blue2), var(--blue));
}

.toggle-thumb {
	position: absolute;
	top: 2px;
	left: 2px;
	width: 18px;
	height: 18px;
	border-radius: 50%;
	background: #fff;
	display: flex;
	align-items: center;
	justify-content: center;
	font-size: 9px;
	transition: left .3s;
	box-shadow: 0 1px 6px rgba(0, 0, 0, .2);
}

.toggle-btn.on .toggle-thumb {
	left: 22px;
}

.user-menu {
	position: relative;
}

.user-pill {
	display: flex;
	align-items: center;
	gap: 8px;
	padding: 5px 12px 5px 5px;
	border-radius: 13px;
	background: var(--surface);
	border: 1.5px solid var(--border);
	cursor: pointer;
	transition: all .2s;
}

.user-pill:hover {
	border-color: rgba(31, 82, 212, .3);
	box-shadow: 0 4px 16px rgba(31, 82, 212, .1);
}

.user-av {
	width: 30px;
	height: 30px;
	border-radius: 9px;
	background: linear-gradient(135deg, var(--blue2), var(--blue));
	display: flex;
	align-items: center;
	justify-content: center;
	font-family: 'Syne', sans-serif;
	font-size: 12px;
	font-weight: 800;
	color: #fff;
}

.user-name {
	font-size: 12.5px;
	font-weight: 600;
	color: var(--tx);
}

.ch {
	font-size: 8px;
	color: var(--tx3);
}

.dropdown {
	position: absolute;
	top: calc(100% + 10px);
	right: 0;
	background: var(--surface);
	border: 1.5px solid var(--bh);
	border-radius: 16px;
	min-width: 210px;
	box-shadow: 0 20px 60px rgba(14, 45, 130, .14);
	overflow: hidden;
	opacity: 0;
	pointer-events: none;
	transform: translateY(-8px) scale(.96);
	transition: all .28s;
	z-index: 900;
}

.user-menu:hover .dropdown {
	opacity: 1;
	pointer-events: all;
	transform: translateY(0) scale(1);
}

.dropdown a {
	display: flex;
	align-items: center;
	gap: 11px;
	padding: 12px 18px;
	color: var(--tx2);
	font-size: 13px;
	text-decoration: none;
	transition: all .2s;
	border-bottom: 1px solid var(--border);
}

.dropdown a:last-child {
	border-bottom: none;
}

.dropdown a:hover {
	background: var(--bl);
	color: var(--blue);
}

.dropdown a i {
	width: 15px;
	text-align: center;
	color: var(--blue);
	font-size: 11px;
}

.dropdown a.dout {
	color: var(--rouge);
}

.dropdown a.dout i {
	color: var(--rouge);
}

.dropdown a.dout:hover {
	background: rgba(220, 38, 38, .07);
}

/* Page Notifications */
.notif-page {
	max-width: 1000px;
	margin: 0 auto;
	padding: 48px 36px 80px;
}

.notif-header {
	margin-bottom: 32px;
}

.notif-header h1 {
	font-family: 'Syne', sans-serif;
	font-size: 32px;
	font-weight: 800;
	background: linear-gradient(135deg, var(--blue2), var(--blue),
		var(--gold));
	-webkit-background-clip: text;
	background-clip: text;
	color: transparent;
	display: inline-flex;
	align-items: center;
	gap: 12px;
}

.notif-header h1 i {
	background: none;
	-webkit-background-clip: unset;
	background-clip: unset;
	color: var(--gold);
	font-size: 28px;
}

.notif-sub {
	color: var(--tx2);
	margin-top: 8px;
	font-size: 14px;
}

.stats-row {
	display: flex;
	gap: 16px;
	margin-bottom: 32px;
	flex-wrap: wrap;
}

.stat-card {
	background: var(--surface);
	border: 1.5px solid var(--border);
	border-radius: 20px;
	padding: 16px 28px;
	display: flex;
	align-items: center;
	gap: 14px;
	transition: all .2s;
}

.stat-card i {
	font-size: 28px;
	color: var(--blue);
}

.stat-card .stat-info h4 {
	font-size: 11px;
	font-weight: 700;
	text-transform: uppercase;
	letter-spacing: 1px;
	color: var(--tx3);
}

.stat-card .stat-info .stat-number {
	font-family: 'Syne', sans-serif;
	font-size: 28px;
	font-weight: 800;
	color: var(--tx);
}

.actions-bar {
	display: flex;
	gap: 12px;
	margin-bottom: 32px;
	flex-wrap: wrap;
}

.btn-mark-all {
	background: linear-gradient(135deg, var(--blue2), var(--blue));
	border: none;
	padding: 12px 24px;
	border-radius: 14px;
	color: white;
	font-weight: 600;
	font-size: 13px;
	cursor: pointer;
	display: flex;
	align-items: center;
	gap: 8px;
	transition: all .2s;
	font-family: 'Syne', sans-serif;
}

.btn-mark-all:hover {
	transform: translateY(-2px);
	box-shadow: 0 6px 20px rgba(31, 82, 212, .3);
}

.btn-refresh {
	background: var(--surface);
	border: 1.5px solid var(--border);
	padding: 12px 24px;
	border-radius: 14px;
	color: var(--tx2);
	font-weight: 600;
	font-size: 13px;
	cursor: pointer;
	display: flex;
	align-items: center;
	gap: 8px;
	transition: all .2s;
}

.btn-refresh:hover {
	border-color: var(--blue);
	color: var(--blue);
	background: var(--bl);
}

.notif-list {
	display: flex;
	flex-direction: column;
	gap: 12px;
}

.notif-item {
	background: var(--surface);
	border: 1.5px solid var(--border);
	border-radius: 20px;
	padding: 20px 24px;
	display: flex;
	gap: 18px;
	align-items: flex-start;
	cursor: pointer;
	transition: all .25s;
	animation: notifIn .4s both;
}

@
keyframes notifIn {from { opacity:0;
	transform: translateY(12px);
}

to {
	opacity: 1;
	transform: translateY(0);
}

}
.notif-item:hover {
	transform: translateX(6px);
	border-color: rgba(31, 82, 212, .25);
	box-shadow: 0 8px 24px rgba(14, 45, 130, .1);
}

.notif-item.unread {
	background: linear-gradient(135deg, var(--surface),
		rgba(31, 82, 212, .02));
	border-left: 4px solid var(--blue);
}

.notif-item.read {
	opacity: 0.75;
}

.notif-icon {
	width: 48px;
	height: 48px;
	border-radius: 14px;
	display: flex;
	align-items: center;
	justify-content: center;
	flex-shrink: 0;
	font-size: 20px;
}

.notif-content {
	flex: 1;
}

.notif-title {
	font-family: 'Syne', sans-serif;
	font-weight: 700;
	font-size: 15px;
	margin-bottom: 6px;
	display: flex;
	align-items: center;
	gap: 10px;
	flex-wrap: wrap;
}

.notif-badge {
	background: var(--blue);
	color: white;
	font-size: 9px;
	font-weight: 800;
	padding: 3px 10px;
	border-radius: 99px;
	letter-spacing: 0.5px;
}

.notif-message {
	font-size: 13px;
	color: var(--tx2);
	line-height: 1.5;
	margin-bottom: 8px;
}

.notif-date {
	font-size: 11px;
	color: var(--tx3);
	display: flex;
	align-items: center;
	gap: 5px;
}

.empty-state {
	text-align: center;
	padding: 80px 20px;
	background: var(--surface);
	border: 1.5px solid var(--border);
	border-radius: 24px;
}

.empty-state i {
	font-size: 64px;
	color: var(--tx3);
	opacity: 0.3;
	margin-bottom: 20px;
	display: block;
}

.empty-state h3 {
	font-family: 'Syne', sans-serif;
	font-size: 20px;
	font-weight: 700;
	margin-bottom: 8px;
	color: var(--tx2);
}

.empty-state p {
	color: var(--tx3);
	font-size: 13px;
}

footer {
	background: var(--surface);
	border-top: 1.5px solid var(--border);
	margin-top: 20px;
}

.footer-inner {
	max-width: 1400px;
	margin: 0 auto;
	padding: 56px 36px 36px;
	display: grid;
	grid-template-columns: 2.2fr 1fr 1fr;
	gap: 52px;
}

.footer-brand-name {
	font-family: 'Syne', sans-serif;
	font-weight: 800;
	font-size: 18px;
	color: var(--tx);
}

.footer-brand-tag {
	font-size: 9px;
	color: var(--tx3);
	letter-spacing: 2px;
	text-transform: uppercase;
	margin-top: 2px;
}

.footer-desc {
	font-size: 13px;
	color: var(--tx2);
	line-height: 1.85;
	max-width: 290px;
	margin-top: 14px;
}

.footer-col h4 {
	font-size: 10px;
	font-weight: 800;
	letter-spacing: 2.5px;
	text-transform: uppercase;
	color: var(--tx);
	margin-bottom: 18px;
}

.footer-col ul {
	list-style: none;
}

.footer-col li {
	margin-bottom: 10px;
}

.footer-col a {
	display: flex;
	align-items: center;
	gap: 8px;
	color: var(--tx2);
	text-decoration: none;
	font-size: 13px;
	transition: all .2s;
	cursor: pointer;
}

.footer-col a:hover {
	color: var(--blue);
	transform: translateX(4px);
}

.footer-bottom {
	max-width: 1400px;
	margin: 0 auto;
	padding: 18px 36px;
	border-top: 1px solid var(--border);
	display: flex;
	justify-content: space-between;
	align-items: center;
	flex-wrap: wrap;
	gap: 10px;
}

.footer-bottom p {
	font-size: 12px;
	color: var(--tx3);
}

.heart {
	color: var(--rouge);
}

@media ( max-width :768px) {
	.notif-page {
		padding: 32px 20px;
	}
	.notif-header h1 {
		font-size: 26px;
	}
	.stats-row {
		flex-direction: column;
	}
	.actions-bar {
		flex-direction: column;
	}
	.notif-item {
		flex-direction: column;
	}
	.footer-inner {
		grid-template-columns: 1fr;
		gap: 32px;
	}
	.header-inner {
		padding: 0 18px;
	}
	.nav {
		display: none;
	}
}
</style>
</head>
<body id="body">

	<div class="toast-container" id="toastContainer"></div>

	<header class="header" id="header">
		<div class="header-inner">
			<a href="<%= request.getContextPath() %>/" class="logo" style="gap: 12px;">
    <img src="<%= request.getContextPath() %>/immo/admin/images/Logo.jpg"
         alt="Fredon"
         style="width: 44px; height: 44px; object-fit: cover; border-radius: 12px; box-shadow: 0 4px 12px rgba(0,0,0,.15);">
    <div>
        <div class="logo-name">Fredon</div>
        <div class="logo-sub">Agence Immobilière</div>
    </div>
</a>
			<nav class="nav">
				<a href="<%= request.getContextPath() %>/"><i
					class="fas fa-home"></i> Accueil</a> <a
					href="<%= request.getContextPath() %>/?page=biens"><i
					class="fas fa-building"></i> Nos biens</a> <a
					href="<%= request.getContextPath() %>/?page=favoris"
					class="favorites-tab"><i class="fas fa-heart"></i> Favoris</a> <a
			href="<%= request.getContextPath() %>/notifications"
					class="msg-link active"> <i class="fas fa-bell"></i>
					Notifications <% if (unreadCount > 0) { %> <span
					class="msg-badge-dot"><%= unreadCount > 9 ? "9+" : unreadCount %></span>
					<% } %>
				</a> <a href="<%= request.getContextPath() %>/chat" class="msg-link">
					<i class="fas fa-comments"></i> Messages <% if (unreadMessagesCount > 0) { %>
					<span class="msg-badge-dot"><%= unreadMessagesCount > 9 ? "9+" : unreadMessagesCount %></span>
					<% } %>
				</a>
			</nav>
			<div class="hright">
				<div class="toggle-btn" id="toggleTheme" onclick="switchTheme()">
					<div class="toggle-thumb" id="tThumb">☀️</div>
				</div>
				<div class="user-menu">
					<div class="user-pill">
						<div class="user-av"><%= userInitial %></div>
						<span class="user-name"><%= userName %></span> <i
							class="fas fa-chevron-down ch"></i>
					</div>
					<div class="dropdown">
						<a href="<%= request.getContextPath() %>/notifications"><i
							class="fas fa-bell"></i> Mes notifications</a> <a
						href="<%= request.getContextPath() %>/chat"><i
							class="fas fa-comments"></i> Mes messages</a> <a
							href="<%= request.getContextPath() %>/profile.jsp"><i
							class="fas fa-user-cog"></i> Mon profil</a> <a
							href="<%= request.getContextPath() %>/logout" class="dout"><i
							class="fas fa-sign-out-alt"></i> Déconnexion</a>
					</div>
				</div>
			</div>
		</div>
	</header>

	<main class="notif-page">
		<div class="notif-header">
			<h1>
				<i class="fas fa-bell"></i> Mes notifications
			</h1>
			<p class="notif-sub">Restez informé de l'activité sur la
				plateforme</p>
		</div>

		<div class="stats-row">
			<div class="stat-card">
				<i class="fas fa-envelope-open"></i>
				<div class="stat-info">
					<h4>Non lues</h4>
					<div class="stat-number"><%= unreadCount %></div>
				</div>
			</div>
			<div class="stat-card">
				<i class="fas fa-list"></i>
				<div class="stat-info">
					<h4>Total</h4>
					<div class="stat-number"><%= notifications.size() %></div>
				</div>
			</div>
		</div>

		<div class="actions-bar">
			<button class="btn-mark-all" onclick="markAllAsRead()">
				<i class="fas fa-check-double"></i> Tout marquer comme lu
			</button>
			<button class="btn-refresh" onclick="location.reload()">
				<i class="fas fa-sync-alt"></i> Rafraîchir
			</button>
		</div>

		<div class="notif-list">
			<% if (notifications.isEmpty()) { %>
			<div class="empty-state">
				<i class="fas fa-bell-slash"></i>
				<h3>Aucune notification</h3>
				<p>Vous serez informé des nouvelles activités ici.</p>
			</div>
			<% } else { 
        SimpleDateFormat sdf = new SimpleDateFormat("dd/MM/yyyy à HH:mm");
        for (Map<String, Object> notif : notifications) {
            boolean isRead = (Boolean) notif.get("is_read");
            String type = (String) notif.get("type");
            String icon = "fa-bell";
            String iconColor = "var(--blue)";
            String iconBg = "var(--bl)";
            if ("welcome".equals(type)) { icon = "fa-hand-peace"; iconColor = "var(--teal)"; iconBg = "rgba(14,158,138,.1)"; }
            else if ("new_property".equals(type)) { icon = "fa-home"; iconColor = "var(--blue)"; iconBg = "var(--bl)"; }
            else if ("property_sold".equals(type)) { icon = "fa-tag"; iconColor = "var(--rose)"; iconBg = "rgba(224,48,96,.1)"; }
            else if ("message".equals(type)) { icon = "fa-comment-dots"; iconColor = "var(--gold)"; iconBg = "var(--gl)"; }
    %>
			<div class="notif-item <%= isRead ? "read" : "unread" %>"
				data-id="<%= notif.get("id") %>"
				onclick="markAsRead(<%= notif.get("id") %>, this, '<%= notif.get("link") != null ? notif.get("link") : "" %>')">
				<div class="notif-icon"
					style="background: <%= iconBg %>; color: <%= iconColor %>;">
					<i class="fas <%= icon %>"></i>
				</div>
				<div class="notif-content">
					<div class="notif-title">
						<%= notif.get("title") %>
						<% if (!isRead) { %>
						<span class="notif-badge">Nouveau</span>
						<% } %>
					</div>
					<div class="notif-message"><%= notif.get("message") %></div>
					<div class="notif-date">
						<i class="far fa-clock"></i>
						<%= sdf.format((Timestamp) notif.get("created_at")) %></div>
				</div>
			</div>
			<% } } %>
		</div>
	</main>

	<footer>
		<div class="footer-inner">
			<div>
				<div
					style="display: flex; align-items: center; gap: 11px; margin-bottom: 14px;">
					<svg viewBox="0 0 54 54" fill="none" width="36" height="36"
						xmlns="http://www.w3.org/2000/svg">
						<defs>
						<linearGradient id="fhg" x1="0%" y1="0%" x2="100%" y2="100%">
						<stop offset="0%" stop-color="#FFD060" />
						<stop offset="50%" stop-color="#F59E0B" />
						<stop offset="100%" stop-color="#B45309" /></linearGradient>
						<linearGradient id="frg" x1="0%" y1="0%" x2="100%" y2="100%">
						<stop offset="0%" stop-color="#FDE68A" />
						<stop offset="100%" stop-color="#D97706" /></linearGradient></defs>
						<circle cx="27" cy="27" r="25" fill="rgba(31,82,212,.1)"
							stroke="rgba(31,82,212,.2)" stroke-width="1.5" />
						<rect x="13" y="28" width="28" height="18" rx="2" fill="url(#fhg)" />
						<polygon points="10,29 27,12 44,29" fill="url(#frg)" />
						<rect x="22" y="35" width="10" height="11" rx="5"
							fill="rgba(14,45,130,.55)" />
						<rect x="14" y="31" width="7" height="6" rx="1.5"
							fill="rgba(180,220,255,.8)" />
						<rect x="33" y="31" width="7" height="6" rx="1.5"
							fill="rgba(180,220,255,.8)" />
						<g opacity=".88">
						<rect x="35" y="7" width="14" height="9" rx="3" fill="#10B981" />
						<polygon points="37,16 36,19 40,16" fill="#10B981" />
						<rect x="37" y="9.5" width="4" height="1.5" rx=".7" fill="white"
							opacity=".9" />
						<rect x="37" y="12" width="7" height="1.5" rx=".7" fill="white"
							opacity=".7" /></g></svg>
					<div>
						<div class="footer-brand-name">Fredon</div>
						<div class="footer-brand-tag">Agence Immobilière Madagascar</div>
					</div>
				</div>
				<p class="footer-desc">Votre partenaire de confiance pour
					vendre, louer ou investir dans l'immobilier à Madagascar. Des
					professionnels à votre écoute, chaque jour.</p>
			</div>
			<div class="footer-col">
				<h4>Navigation</h4>
				<ul>
					<li><a href="<%= request.getContextPath() %>/"><i
							class="fas fa-home"></i> Accueil</a></li>
					<li><a
						href="<%= request.getContextPath() %>/?page=biens"><i
							class="fas fa-building"></i> Nos biens</a></li>
					<li><a
							class="fas fa-heart"></i> Mes favoris</a></li>
					<li><a href="<%= request.getContextPath() %>/chat"><i
							class="fas fa-comments"></i> Messages</a></li>
				</ul>
			</div>
			<div class="footer-col">
				<h4>Contact</h4>
				<ul>
					<li><a href="mailto:contact@fredon.mg"><i
							class="fas fa-envelope"></i> contact@fredon.mg</a></li>
					<li><a href="#"><i class="fas fa-map-marker-alt"></i>
							Mahajanga, Madagascar</a></li>
				</ul>
			</div>
		</div>
		<div class="footer-bottom">
			<p>© 2026 Fredon Immobilier — Madagascar</p>
			<p>
				Fait avec <i class="fas fa-heart heart"></i> à Madagascar
			</p>
		</div>
	</footer>

	<script>
// Theme
const KEY = 'fredon_theme';
let dark = localStorage.getItem(KEY) === 'dark';
function applyTheme() {
  const b = document.getElementById('body');
  const t = document.getElementById('toggleTheme');
  const th = document.getElementById('tThumb');
  if (dark) { b.classList.add('dm'); t.classList.add('on'); th.textContent = '🌙'; }
  else { b.classList.remove('dm'); t.classList.remove('on'); th.textContent = '☀️'; }
}
function switchTheme() {
  dark = !dark;
  localStorage.setItem(KEY, dark ? 'dark' : 'light');
  applyTheme();
  showToast('info', dark ? '🌙 Mode sombre activé' : '☀️ Mode clair activé');
}
applyTheme();

// Header scroll
const hdr = document.getElementById('header');
window.addEventListener('scroll', () => hdr.classList.toggle('scrolled', scrollY > 10), { passive: true });

// Toast
function showToast(type, message, duration = 3500) {
  const container = document.getElementById('toastContainer');
  const toast = document.createElement('div');
  toast.className = `toast toast-${type}`;
  const icons = { success: 'fas fa-check-circle', info: 'fas fa-info-circle', error: 'fas fa-times-circle' };
  const icon = icons[type] || icons.info;
  toast.innerHTML = `<div class="toast-icon"><i class="${icon}"></i></div><div class="toast-msg">${message}</div><button class="toast-close" onclick="closeToast(this.closest('.toast'))">×</button>`;
  container.appendChild(toast);
  setTimeout(() => closeToast(toast), duration);
}
function closeToast(el) { if (!el || el.classList.contains('exit')) return; el.classList.add('exit'); setTimeout(() => el.remove(), 380); }

// Notifications
function markAsRead(id, element, link) {
  fetch('<%= request.getContextPath() %>/api/mark-notification-read', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: 'id=' + id
  }).then(() => {
    element.classList.remove('unread');
    element.classList.add('read');
    const badge = element.querySelector('.notif-badge');
    if (badge) badge.remove();
    showToast('success', 'Notification marquée comme lue');
    if (link && link !== '') {
      setTimeout(() => { window.location.href = link; }, 300);
    }
  }).catch(() => showToast('error', 'Erreur lors du marquage'));
}

function markAllAsRead() {
  fetch('<%= request.getContextPath() %>/api/mark-all-notifications-read', {
    method: 'POST'
  }).then(() => {
    location.reload();
  }).catch(() => showToast('error', 'Erreur lors du marquage'));
}

//Empêche l'accès aux pages après déconnexion
if (performance.navigation.type === 2) {
 window.location.href = '${pageContext.request.contextPath}/login';
}


</script>
</body>
</html>