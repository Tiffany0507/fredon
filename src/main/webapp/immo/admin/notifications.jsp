<%@ page language="java" contentType="text/html; charset=UTF-8"
	pageEncoding="UTF-8"%>
<%@ page import="java.util.*, java.text.*"%>
<%@ page import="java.sql.*"%>
<%@ page import="com.quickchat.model.User"%>
<%@ page import="com.quickchat.utils.TranslateUtil"%>
<%@ include file="includes/color.jsp" %>

<%

response.setHeader("Cache-Control", "no-cache, no-store, must-revalidate");
response.setHeader("Pragma", "no-cache");
response.setHeader("Expires", "0");

    String lang = "fr";
    try {
        Class.forName("com.mysql.cj.jdbc.Driver");
        Connection conn = DriverManager.getConnection("jdbc:mysql://localhost:3306/quickchat", "root", "");
        PreparedStatement pstmt = conn.prepareStatement("SELECT default_language FROM settings WHERE id = 1");
        ResultSet rs = pstmt.executeQuery();
        if (rs.next()) lang = rs.getString("default_language");
        rs.close(); pstmt.close(); conn.close();
    } catch(Exception e) {}
%>

<%
    Integer adminId = (Integer) session.getAttribute("adminId");
    User admin = (User) session.getAttribute("admin");
    
    if (adminId == null && admin == null) {
        response.sendRedirect(request.getContextPath() + "/immo/admin/login.jsp");
        return;
    }

    String DB_URL = "jdbc:mysql://localhost:3306/quickchat";
    String DB_USER = "root";
    String DB_PASSWORD = "";

    List<Map<String, Object>> notifications = new ArrayList<>();
    int unreadCount = 0;
    int unreadMessages = 0;
    try {
        com.quickchat.dao.MessageDAO messageDAO = new com.quickchat.dao.MessageDAO();
        unreadMessages = messageDAO.countUnreadMessagesForAgent();
    } catch(Exception e) {
        unreadMessages = 0;
    }

    try {
        Class.forName("com.mysql.cj.jdbc.Driver");
        Connection conn = DriverManager.getConnection(DB_URL, DB_USER, DB_PASSWORD);
        
       
        
        String sql = "SELECT * FROM notifications WHERE user_id = ? ORDER BY created_at DESC LIMIT 50";
        PreparedStatement pstmt = conn.prepareStatement(sql);
        pstmt.setInt(1, adminId);
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
    
    String adminName = session.getAttribute("adminUsername") != null ? 
        session.getAttribute("adminUsername").toString() : "Admin";
    String adminInitial = adminName.substring(0, 1).toUpperCase();
%>

<!DOCTYPE html>
<html lang="<%= lang %>">
<head>
<%@ include file="includes/theme.jsp" %>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title><%= TranslateUtil.t(lang, "notifications") %> — Fredon
	Immobilier</title>
<link
	href="https://fonts.googleapis.com/css2?family=Syne:wght@400;600;700;800&family=DM+Sans:wght@300;400;500;600;700&display=swap"
	rel="stylesheet">
<link rel="stylesheet"
	href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css">
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
	--rose-light: #f7547a;
	--rose-pale: #fde8ee;
	--purple: #7c3aed;
	--purple-pale: #f0ebff;
	--dark: #0d0b08;
	--mid: #6b5a3e;
	--soft: #a89880;
	--bg: #f8f4ee;
	--bg2: #fdf9f3;
	--white: #ffffff;
	--sidebar-w: 272px;
	--green: #10b981;
	--red: #ef4444;
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
	background: linear-gradient(160deg, #0d1f5e 0%, #1a3aaa 45%, #0e2d82 75%, #0a1d58
		100%);
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
	background-image: radial-gradient(ellipse at 80% 10%, rgba(200, 134, 10, .18)
		0%, transparent 60%),
		radial-gradient(ellipse at 20% 90%, rgba(79, 126, 248, .15) 0%,
		transparent 50%);
	pointer-events: none;
}

.sidebar-grid {
	position: absolute;
	inset: 0;
	pointer-events: none;
	background-image: linear-gradient(rgba(255, 255, 255, .03) 1px,
		transparent 1px), linear-gradient(90deg, rgba(255, 255, 255, .03) 1px,
		transparent 1px);
	background-size: 36px 36px;
}

.logo-area {
	padding: 26px 22px 20px;
	border-bottom: 1px solid rgba(255, 255, 255, .1);
	display: flex;
	align-items: center;
	gap: 12px;
	position: relative;
	z-index: 2;
}

.logo-mark {
	width: 50px;
	height: 50px;
	flex-shrink: 0;
	filter: drop-shadow(0 6px 16px rgba(0, 0, 0, .35));
}

.logo-text-wrap {
	display: flex;
	flex-direction: column;
}

.logo-name {
	font-family: 'Syne', sans-serif;
	font-weight: 800;
	font-size: 22px;
	background: linear-gradient(120deg, #fff 0%, #fde9b0 100%);
	-webkit-background-clip: text;
	background-clip: text;
	color: transparent;
}

.logo-sub {
	font-size: 9px;
	color: rgba(255, 255, 255, .5);
	letter-spacing: 2.2px;
	text-transform: uppercase;
	margin-top: 2px;
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
}

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

.btn-back {
	display: inline-flex;
	align-items: center;
	gap: 8px;
	padding: 8px 16px;
	background: white;
	border: 1.5px solid rgba(200, 134, 10, .2);
	border-radius: 10px;
	text-decoration: none;
	color: var(--mid);
	transition: all .2s;
}

.btn-back:hover {
	border-color: var(--gold);
	color: var(--gold);
}

.notif-stats {
	display: flex;
	gap: 16px;
	margin-bottom: 24px;
	flex-wrap: wrap;
}

.stat-pill {
	background: var(--white);
	padding: 12px 24px;
	border-radius: 30px;
	border: 1.5px solid rgba(200, 134, 10, .1);
	font-weight: 500;
}

.stat-pill span {
	font-weight: 800;
	font-size: 20px;
	color: var(--gold);
	margin-left: 8px;
}

.notif-actions {
	display: flex;
	gap: 12px;
	margin-bottom: 24px;
}

.btn-mark-read {
	background: linear-gradient(135deg, var(--gold), var(--gold-light));
	border: none;
	padding: 10px 20px;
	border-radius: 12px;
	color: white;
	font-weight: 600;
	cursor: pointer;
	transition: all .2s;
}

.btn-mark-read:hover {
	transform: translateY(-2px);
	box-shadow: 0 6px 16px rgba(200, 134, 10, .3);
}

.btn-mark-all {
	background: transparent;
	border: 1.5px solid rgba(200, 134, 10, .2);
	padding: 10px 20px;
	border-radius: 12px;
	cursor: pointer;
	transition: all .2s;
}

.btn-mark-all:hover {
	border-color: var(--gold);
	color: var(--gold);
}

.notif-list {
	display: flex;
	flex-direction: column;
	gap: 12px;
}

.notif-item {
	background: var(--white);
	border-radius: 20px;
	padding: 18px 24px;
	border-left: 4px solid var(--gold);
	transition: all 0.2s;
	cursor: pointer;
	box-shadow: 0 2px 8px rgba(0, 0, 0, .04);
}

.notif-item.unread {
	background: linear-gradient(135deg, var(--white),
		rgba(200, 134, 10, 0.02));
	border-left-color: var(--gold);
}

.notif-item.read {
	opacity: 0.7;
	border-left-color: var(--mid);
}

.notif-item:hover {
	transform: translateX(4px);
	box-shadow: 0 4px 12px rgba(0, 0, 0, 0.08);
}

.notif-icon {
	width: 44px;
	height: 44px;
	border-radius: 14px;
	display: flex;
	align-items: center;
	justify-content: center;
	flex-shrink: 0;
}

.notif-content {
	flex: 1;
}

.notif-title {
	font-weight: 700;
	font-size: 15px;
	margin-bottom: 5px;
}

.notif-message {
	font-size: 13px;
	color: var(--mid);
	margin-bottom: 6px;
}

.notif-date {
	font-size: 11px;
	color: var(--soft);
}

.notif-badge {
	font-size: 10px;
	padding: 2px 10px;
	border-radius: 20px;
	background: rgba(200, 134, 10, 0.12);
	color: var(--gold);
	margin-left: 10px;
}

.empty-state {
	text-align: center;
	padding: 60px 20px;
	color: var(--mid);
}

.empty-state i {
	font-size: 52px;
	margin-bottom: 16px;
	opacity: 0.3;
}

.empty-state h3 {
	font-size: 18px;
	margin-bottom: 6px;
	color: var(--dark);
}

@
keyframes fadeUp {from { opacity:0;
	transform: translateY(16px);
}

to {
	opacity: 1;
	transform: translateY(0);
}

}
.fade-1 {
	animation: fadeUp .5s .05s both;
}

@media ( max-width : 900px) {
	.sidebar {
		transform: translateX(-100%);
	}
	.main {
		margin-left: 0;
		padding: 20px;
	}
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
		<div class="logo-area" style="padding: 20px 18px 18px; gap: 14px;">
    <img src="<%= request.getContextPath() %>/immo/admin/images/Logo.jpg"
         alt="Fredon"
         style="width: 68px; height: 68px; object-fit: cover; border-radius: 18px; box-shadow: 0 6px 22px rgba(0,0,0,.45), 0 0 0 2px rgba(255,255,255,.2);">
    <div class="logo-text-wrap">
        <span class="logo-name" style="font-size: 24px;">Fredon</span>
        <span class="logo-sub"><%= TranslateUtil.t(lang, "real_estate_agency") %></span>
    </div>
</div>

			<nav class="nav">
    <div class="nav-section"><%= TranslateUtil.t(lang, "principal") %></div>
    <a href="dashboard.jsp" class="nav-item"><i class="fas fa-chart-line"></i> <%= TranslateUtil.t(lang, "dashboard") %></a>
    <a href="add-property.jsp" class="nav-item"><i class="fas fa-plus-circle"></i> <%= TranslateUtil.t(lang, "add_property") %></a>
    <a href="<%= request.getContextPath() %>/chat.jsp" class="nav-item">
        <i class="fas fa-comments"></i> <%= TranslateUtil.t(lang, "messages") %>
        <% if(unreadMessages > 0){ %><span class="nav-badge"><%= unreadMessages %></span><% } %>
    </a>
    
    <div class="nav-section"><%= TranslateUtil.t(lang, "management") %></div>
    <a href="clients.jsp" class="nav-item"><i class="fas fa-users"></i> <%= TranslateUtil.t(lang, "clients") %></a>
    
    <!-- ⭐ AJOUTER VISITES ⭐ -->
    <a href="appointments.jsp" class="nav-item">
        <i class="fas fa-calendar-check"></i> Visites
        <% 
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
        %>
        <% if (pendingAppointments > 0) { %> 
        <span class="nav-badge"><%= pendingAppointments %></span> 
        <% } %>
    </a>
    
    <a href="statistics.jsp" class="nav-item"><i class="fas fa-chart-pie"></i> <%= TranslateUtil.t(lang, "statistics") %></a>
    
    <div class="nav-section"><%= TranslateUtil.t(lang, "system") %></div>
    <a href="settings.jsp" class="nav-item"><i class="fas fa-cog"></i> Paramètres</a>
    <a href="<%= request.getContextPath() %>/immo/index.jsp" class="nav-item"><i class="fas fa-globe"></i> <%= TranslateUtil.t(lang, "view_site") %></a>
    <a href="<%= request.getContextPath() %>/admin/logout" class="nav-item logout"><i class="fas fa-sign-out-alt"></i> <%= TranslateUtil.t(lang, "logout") %></a>
</nav>

			<div class="user-bottom">
				<div class="u-avatar"><%= adminInitial %></div>
				<div class="u-info">
					<div class="u-name"><%= adminName %></div>
					<div class="u-role"><%= TranslateUtil.t(lang, "admin") %></div>
				</div>
				<div class="u-dot"></div>
			</div>
		</aside>

		<main class="main">

			<div class="top-bar fade-1">
				<div class="page-title">
					<h1>
						<i class="fas fa-bell"
							style="color: var(--gold); margin-right: 10px;"></i><%= TranslateUtil.t(lang, "notifications") %></h1>
					<p><%= TranslateUtil.t(lang, "stay_informed") %></p>
				</div>
				<div class="top-right">
					
					<div class="icon-circle">
						<i class="fas fa-cog"></i>
					</div>
					<a href="dashboard.jsp" class="btn-back"><i
						class="fas fa-arrow-left"></i> <%= TranslateUtil.t(lang, "back") %></a>
				</div>
			</div>

			<div class="notif-stats">
				<div class="stat-pill">
					<i class="fas fa-envelope-open"></i>
					<%= TranslateUtil.t(lang, "unread") %>
					: <span><%= unreadCount %></span>
				</div>
				<div class="stat-pill">
					<i class="fas fa-list"></i>
					<%= TranslateUtil.t(lang, "total") %>
					: <span><%= notifications.size() %></span>
				</div>
			</div>

			<div class="notif-actions">
				<button class="btn-mark-read" onclick="markAllAsRead()">
					<i class="fas fa-check-double"></i>
					<%= TranslateUtil.t(lang, "mark_all_read") %></button>
				<button class="btn-mark-all" onclick="location.reload()">
					<i class="fas fa-sync-alt"></i>
					<%= TranslateUtil.t(lang, "refresh") %></button>
			</div>

			<div class="notif-list">
				<% if (notifications.isEmpty()) { %>
				<div class="empty-state">
					<i class="fas fa-bell-slash"></i>
					<h3><%= TranslateUtil.t(lang, "no_notifications") %></h3>
					<p><%= TranslateUtil.t(lang, "no_notifications_desc") %></p>
				</div>
				<% } else { 
                SimpleDateFormat sdf = new SimpleDateFormat("dd/MM/yyyy 'à' HH:mm");
                for (Map<String, Object> notif : notifications) {
                    boolean isRead = (Boolean) notif.get("is_read");
                    String type = (String) notif.get("type");
                    String icon = "fa-bell";
                    String iconColor = "var(--gold)";
                    if ("message".equals(type)) { icon = "fa-comment-dots"; iconColor = "var(--blue)"; }
                    else if ("client".equals(type)) { icon = "fa-user-plus"; iconColor = "var(--green)"; }
                    else if ("comment".equals(type)) { icon = "fa-comment"; iconColor = "var(--purple)"; }
                    else if ("property".equals(type)) { icon = "fa-home"; iconColor = "var(--gold)"; }
            %>
				<div class="notif-item <%= isRead ? "read" : "unread" %>"
					data-id="<%= notif.get("id") %>"
					onclick="markAsRead(<%= notif.get("id") %>, this)">
					<div style="display: flex; gap: 15px; align-items: flex-start;">
						<div class="notif-icon"
							style="background: rgba(200,134,10,0.1); color: <%= iconColor %>;">
							<i class="fas <%= icon %>"></i>
						</div>
						<div class="notif-content">
							<div class="notif-title"><%= notif.get("title") %>
								<% if (!isRead) { %><span class="notif-badge"><%= TranslateUtil.t(lang, "new") %></span>
								<% } %>
							</div>
							<div class="notif-message"><%= notif.get("message") %></div>
							<div class="notif-date">
								<i class="far fa-clock"></i>
								<%= sdf.format((Timestamp) notif.get("created_at")) %></div>
						</div>
					</div>
				</div>
				<% } } %>
			</div>

		</main>
	</div>

	<script>
(function(){
    const canvas = document.getElementById('bgCanvas');
    const ctx = canvas.getContext('2d');
    let W, H, houses = [];
    function resize(){ W = canvas.width = window.innerWidth; H = canvas.height = window.innerHeight; }
    resize(); window.addEventListener('resize', resize);
    function drawHouse(ctx,x,y,s,alpha,color){
        ctx.save(); ctx.globalAlpha=alpha; ctx.strokeStyle=color; ctx.fillStyle=color; ctx.lineWidth=1.4*s; ctx.translate(x,y);
        ctx.beginPath(); ctx.rect(-14*s,-8*s,28*s,20*s); ctx.stroke();
        ctx.beginPath(); ctx.moveTo(-17*s,-8*s); ctx.lineTo(0,-22*s); ctx.lineTo(17*s,-8*s); ctx.closePath(); ctx.stroke();
        ctx.beginPath(); ctx.arc(0,7*s,5*s,Math.PI,0); ctx.rect(-5*s,2*s,10*s,5*s); ctx.stroke();
        ctx.strokeRect(-12*s,-5*s,7*s,6*s); ctx.strokeRect(5*s,-5*s,7*s,6*s);
        ctx.fillRect(5*s,-24*s,4*s,8*s); ctx.restore();
    }
    const COLORS=['#1f52d4','#c8860a','#0e9e8a','#e03060','#7c3aed','#0e7490','#b45309','#166534'];
    for(let i=0;i<16;i++) houses.push({x:Math.random()*1600,y:Math.random()*900,s:.5+Math.random()*1.3,alpha:.04+Math.random()*.055,color:COLORS[Math.floor(Math.random()*COLORS.length)],vx:(Math.random()-.5)*.11,vy:(Math.random()-.5)*.09});
    function animate(){ ctx.clearRect(0,0,W,H); houses.forEach(h=>{ h.x+=h.vx; h.y+=h.vy; if(h.x<-100)h.x=W+60; if(h.x>W+100)h.x=-60; if(h.y<-100)h.y=H+60; if(h.y>H+100)h.y=-60; drawHouse(ctx,h.x,h.y,h.s,h.alpha,h.color); }); requestAnimationFrame(animate); }
    animate();
})();

function markAsRead(id, element) {
    fetch('<%= request.getContextPath() %>/admin/mark-notification-read', {
        method: 'POST',
        headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
        body: 'id=' + id
    }).then(() => {
        element.classList.remove('unread');
        element.classList.add('read');
        const badge = element.querySelector('.notif-badge');
        if (badge) badge.remove();
        location.reload();
    });
}

function markAllAsRead() {
    fetch('<%= request.getContextPath() %>/admin/mark-all-notifications-read', {
        method: 'POST'
    }).then(() => location.reload());
}

//Empêche l'accès aux pages après déconnexion
if (performance.navigation.type === 2) {
 window.location.href = '${pageContext.request.contextPath}/login';
}

</script>

</body>
</html>