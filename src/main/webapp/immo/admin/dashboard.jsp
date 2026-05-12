<%@ page language="java" contentType="text/html; charset=UTF-8"
	pageEncoding="UTF-8"%>
<%@ page import="java.util.List"%>
<%@ page import="java.text.SimpleDateFormat"%>
<%@ page import="com.immobilier.model.Property"%>
<%@ page import="com.immobilier.dao.PropertyDAO"%>
<%@ page import="java.sql.Connection"%>
<%@ page import="java.sql.DriverManager"%>
<%@ page import="java.sql.PreparedStatement"%>
<%@ page import="java.sql.ResultSet"%>
<%@ page import="com.quickchat.model.User"%>
<%@ page import="java.sql.Statement"%>
<%@ page import="com.quickchat.utils.TranslateUtil"%>
<%@ page isELIgnored="false"%>

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
        response.sendRedirect(request.getContextPath() + "/login");
        return;
    }

    String DB_URL = "jdbc:mysql://localhost:3306/quickchat";
    String DB_USER = "root";
    String DB_PASSWORD = "";

    List<Property> properties = null;
    int totalProperties = 0;
    int unreadMessages = 0;
    int totalViews = 0;

    try {
        Class.forName("com.mysql.cj.jdbc.Driver");
        Connection conn = DriverManager.getConnection(DB_URL, DB_USER, DB_PASSWORD);
        PropertyDAO propertyDAO = new PropertyDAO(conn);
        properties = propertyDAO.getAllProperties();
        totalProperties = properties != null ? properties.size() : 0;
        
        Statement stmtViews = conn.createStatement();
        ResultSet rsViews = stmtViews.executeQuery("SELECT SUM(views_count) as total FROM properties");
        if (rsViews.next()) {
            totalViews = rsViews.getInt("total");
        }
        rsViews.close();
        stmtViews.close();
        
        com.quickchat.dao.MessageDAO messageDAO = new com.quickchat.dao.MessageDAO();
        unreadMessages = messageDAO.countUnreadMessagesForAgent();
        conn.close();
    } catch (Exception e) {
        e.printStackTrace();
    }

    String success = request.getParameter("success");
    String error = request.getParameter("error");
    
    String adminName = "Admin";
    if (session.getAttribute("adminUsername") != null) {
        adminName = session.getAttribute("adminUsername").toString();
    } else if (admin != null && admin.getDisplayName() != null) {
        adminName = admin.getDisplayName();
    }
    String adminInitial = (adminName != null && !adminName.isEmpty()) ? adminName.substring(0, 1).toUpperCase() : "A";

    // Récupérer la photo de profil depuis la base de données
    String adminProfilePic = null;
    try {
        Class.forName("com.mysql.cj.jdbc.Driver");
        Connection conn = DriverManager.getConnection(DB_URL, DB_USER, DB_PASSWORD);
        PreparedStatement pstmt = conn.prepareStatement("SELECT profile_pic FROM users WHERE id = ?");
        pstmt.setInt(1, adminId);
        ResultSet rs = pstmt.executeQuery();
        if (rs.next()) {
            adminProfilePic = rs.getString("profile_pic");
        }
        rs.close(); pstmt.close(); conn.close();
    } catch(Exception e) {
        e.printStackTrace();
    }
%>

<!DOCTYPE html>
<html lang="<%= lang %>">
<head>
<%@ include file="includes/theme.jsp" %>
<%@ include file="includes/color.jsp" %>

<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title><%= TranslateUtil.t(lang, "dashboard") %> — Fredon Immobilier</title>
<link href="https://fonts.googleapis.com/css2?family=Syne:wght@400;600;700;800&family=DM+Sans:ital,opsz,wght@0,9..40,300;0,9..40,400;0,9..40,500;0,9..40,600;0,9..40,700&display=swap" rel="stylesheet">
<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css">
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
	--dark: #0d0b08;
	--mid: #6b5a3e;
	--soft: #a89880;
	--bg: #f8f4ee;
	--bg2: #fdf9f3;
	--white: #ffffff;
	--sidebar-w: 272px;
	--green: #10b981;
	--red: #ef4444;
	--r-lg: 18px;
	--r-xl: 26px;
}

/* Mode sombre */
body.dark-theme {
	--bg: #060c1a;
	--bg2: #0d1626;
	--white: #0d1626;
	--dark: #e0e8ff;
	--mid: #6070a0;
	--soft: #2a3555;
}

html, body {
	height: 100%;
	font-family: 'DM Sans', sans-serif;
	background: var(--bg);
	color: var(--dark);
	overflow-x: hidden;
	transition: background 0.3s, color 0.3s;
}

#bgCanvas {
	position: fixed;
	inset: 0;
	z-index: 0;
	pointer-events: none;
	opacity: .07;
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

body.dark-theme .sidebar {
	background: linear-gradient(160deg, #050a18 0%, #0d1626 45%, #0a1030 75%, #040818 100%);
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
	background-image: linear-gradient(rgba(255, 255, 255, .03) 1px, transparent 1px), linear-gradient(90deg, rgba(255, 255, 255, .03) 1px, transparent 1px);
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

.nav-item.logout {
	color: rgba(255, 130, 130, .7);
	margin-top: auto;
}

.nav-item.logout:hover {
	background: rgba(239, 68, 68, .15);
	color: #fca5a5;
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

.top-btn {
	display: inline-flex;
	align-items: center;
	gap: 7px;
	padding: 9px 18px;
	border-radius: 12px;
	border: none;
	cursor: pointer;
	font-family: 'DM Sans', sans-serif;
	font-size: 13px;
	font-weight: 600;
	transition: all .22s;
}

.top-btn-primary {
	background: linear-gradient(115deg, #0e2d82, var(--blue-light));
	color: white;
	box-shadow: 0 6px 18px rgba(31, 82, 212, .3);
}

.top-btn-primary:hover {
	transform: translateY(-2px);
	box-shadow: 0 10px 24px rgba(31, 82, 212, .4);
}

.notif-wrap {
	position: relative;
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
	font-size: 16px;
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

@keyframes slideIn { from { opacity:0; transform: translateY(-8px); } to { opacity:1; transform: translateY(0); } }

.alert-success {
	background: rgba(16, 185, 129, .1);
	border: 1px solid rgba(16, 185, 129, .25);
	color: #059669;
}

.alert-error {
	background: rgba(239, 68, 68, .1);
	border: 1px solid rgba(239, 68, 68, .25);
	color: var(--red);
}

.alert-close {
	margin-left: auto;
	background: none;
	border: none;
	cursor: pointer;
	font-size: 18px;
	color: inherit;
	opacity: .5;
}

.alert-close:hover {
	opacity: 1;
}

.stats-row {
	display: grid;
	grid-template-columns: repeat(4, 1fr);
	gap: 18px;
	margin-bottom: 28px;
}

.stat-card {
	background: var(--white);
	border-radius: var(--r-xl);
	padding: 22px 20px;
	border: 1.5px solid transparent;
	position: relative;
	overflow: hidden;
	transition: transform .25s, box-shadow .25s;
	cursor: default;
}

.stat-card:hover {
	transform: translateY(-4px);
	box-shadow: 0 16px 40px rgba(0, 0, 0, .1);
}

.sc-blue {
	background: linear-gradient(135deg, #e8eeff 0%, #f8faff 100%);
	border-color: rgba(79, 126, 248, .2);
}

.sc-gold {
	background: linear-gradient(135deg, #fff3d4 0%, #fffaf0 100%);
	border-color: rgba(200, 134, 10, .2);
}

.sc-teal {
	background: linear-gradient(135deg, #e0faf5 0%, #f4fffe 100%);
	border-color: rgba(14, 158, 138, .2);
}

.sc-rose {
	background: linear-gradient(135deg, #fde8ee 0%, #fff5f8 100%);
	border-color: rgba(224, 48, 96, .18);
}

.stat-top {
	display: flex;
	justify-content: space-between;
	align-items: flex-start;
	margin-bottom: 14px;
}

.stat-ico {
	width: 46px;
	height: 46px;
	border-radius: 14px;
	display: flex;
	align-items: center;
	justify-content: center;
	font-size: 20px;
}

.ico-blue {
	background: rgba(79, 126, 248, .15);
	color: var(--blue-light);
}

.ico-gold {
	background: rgba(200, 134, 10, .15);
	color: var(--gold);
}

.ico-teal {
	background: rgba(14, 158, 138, .15);
	color: var(--teal);
}

.ico-rose {
	background: rgba(224, 48, 96, .15);
	color: var(--rose);
}

.stat-badge {
	font-size: 10.5px;
	font-weight: 700;
	padding: 3px 9px;
	border-radius: 20px;
}

.badge-up-blue {
	background: rgba(79, 126, 248, .14);
	color: var(--blue-light);
}

.badge-up-gold {
	background: rgba(200, 134, 10, .14);
	color: var(--gold);
}

.badge-up-teal {
	background: rgba(14, 158, 138, .14);
	color: var(--teal);
}

.badge-up-rose {
	background: rgba(224, 48, 96, .14);
	color: var(--rose);
}

.stat-val {
	font-family: 'Syne', sans-serif;
	font-size: 34px;
	font-weight: 800;
	line-height: 1;
	margin-bottom: 5px;
}

.val-blue {
	color: var(--blue);
}

.val-gold {
	color: var(--gold);
}

.val-teal {
	color: var(--teal);
}

.val-rose {
	color: var(--rose);
}

.stat-lbl {
	font-size: 12px;
	color: var(--soft);
	font-weight: 500;
}

.stat-bar {
	margin-top: 14px;
	height: 3px;
	background: rgba(0, 0, 0, .06);
	border-radius: 4px;
	overflow: hidden;
}

.stat-fill {
	height: 100%;
	border-radius: 4px;
	width: 0;
	transition: width 1s ease;
}

.fill-blue {
	background: linear-gradient(90deg, var(--blue), var(--blue-light));
}

.fill-gold {
	background: linear-gradient(90deg, var(--gold), var(--gold-light));
}

.fill-teal {
	background: linear-gradient(90deg, var(--teal), var(--teal-light));
}

.fill-rose {
	background: linear-gradient(90deg, var(--rose), var(--rose-light));
}

.quick-row {
	display: grid;
	grid-template-columns: repeat(3, 1fr);
	gap: 14px;
	margin-bottom: 28px;
}

.quick-action {
	background: var(--white);
	border-radius: var(--r-lg);
	padding: 18px 20px;
	display: flex;
	align-items: center;
	gap: 14px;
	border: 1.5px solid rgba(200, 134, 10, .1);
	cursor: pointer;
	text-decoration: none;
	transition: all .22s;
	position: relative;
	overflow: hidden;
}

.quick-action::after {
	content: '';
	position: absolute;
	inset: 0;
	background: linear-gradient(135deg, transparent, rgba(255, 255, 255, .5));
	opacity: 0;
	transition: opacity .25s;
}

.quick-action:hover {
	transform: translateY(-3px);
	box-shadow: 0 10px 28px rgba(0, 0, 0, .1);
}

.quick-action:hover::after {
	opacity: 1;
}

.qa-icon {
	width: 46px;
	height: 46px;
	border-radius: 14px;
	flex-shrink: 0;
	display: flex;
	align-items: center;
	justify-content: center;
	font-size: 20px;
}

.qa-text h4 {
	font-family: 'Syne', sans-serif;
	font-size: 14px;
	font-weight: 700;
	color: var(--dark);
}

.qa-text p {
	font-size: 11.5px;
	color: var(--soft);
	margin-top: 2px;
}

.content-card {
	background: var(--white);
	border-radius: var(--r-xl);
	border: 1.5px solid rgba(200, 134, 10, .1);
	overflow: hidden;
	box-shadow: 0 2px 16px rgba(0, 0, 0, .05);
}

.card-head {
	display: flex;
	justify-content: space-between;
	align-items: center;
	padding: 20px 26px;
	border-bottom: 1.5px solid rgba(200, 134, 10, .08);
	flex-wrap: wrap;
	gap: 14px;
}

.card-head-left {
	display: flex;
	align-items: center;
	gap: 14px;
}

.ch-icon {
	width: 44px;
	height: 44px;
	border-radius: 13px;
	background: linear-gradient(135deg, var(--blue-pale), #d0dcff);
	display: flex;
	align-items: center;
	justify-content: center;
	font-size: 19px;
	color: var(--blue);
}

.ch-title {
	font-family: 'Syne', sans-serif;
	font-size: 17px;
	font-weight: 700;
	color: var(--dark);
}

.ch-sub {
	font-size: 11.5px;
	color: var(--soft);
	margin-top: 2px;
}

.btn-add {
	display: inline-flex;
	align-items: center;
	gap: 7px;
	padding: 10px 20px;
	border-radius: 12px;
	border: none;
	background: linear-gradient(115deg, #0e2d82, var(--blue-light));
	color: white;
	font-family: 'Syne', sans-serif;
	font-weight: 700;
	font-size: 13px;
	cursor: pointer;
	text-decoration: none;
	transition: all .22s;
	box-shadow: 0 5px 16px rgba(31, 82, 212, .28);
}

.btn-add:hover {
	transform: translateY(-2px);
	box-shadow: 0 9px 24px rgba(31, 82, 212, .38);
}

.tbl-wrap {
	overflow-x: auto;
}

table {
	width: 100%;
	border-collapse: collapse;
}

thead tr {
	background: rgba(248, 244, 238, .7);
}

th {
	padding: 13px 18px;
	text-align: left;
	font-size: 10.5px;
	font-weight: 700;
	letter-spacing: 1.1px;
	text-transform: uppercase;
	color: var(--soft);
	border-bottom: 1.5px solid rgba(200, 134, 10, .08);
}

td {
	padding: 14px 18px;
	font-size: 13.5px;
	color: var(--dark);
	border-bottom: 1px solid rgba(200, 134, 10, .06);
	vertical-align: middle;
}

tr:last-child td {
	border-bottom: none;
}

tr:hover td {
	background: rgba(248, 244, 238, .5);
}

.prop-thumb {
	width: 52px;
	height: 40px;
	border-radius: 10px;
	overflow: hidden;
	flex-shrink: 0;
	position: relative;
	background: linear-gradient(135deg, #87CEEB 0%, #5BA3C9 100%);
	border: 1.5px solid rgba(200, 134, 10, .12);
}

.prop-thumb img {
	width: 100%;
	height: 100%;
	object-fit: cover;
}

.prop-thumb-placeholder {
	width: 100%;
	height: 100%;
	display: flex;
	align-items: center;
	justify-content: center;
}

.prop-cell {
	display: flex;
	align-items: center;
	gap: 12px;
}

.prop-meta h4 {
	font-weight: 700;
	font-size: 13.5px;
	color: var(--dark);
}

.prop-meta span {
	font-size: 11px;
	color: var(--soft);
}

.prop-price {
	font-weight: 800;
	font-size: 14px;
	color: var(--gold);
}

.badge-type {
	display: inline-flex;
	align-items: center;
	gap: 5px;
	padding: 4px 11px;
	border-radius: 20px;
	font-size: 11px;
	font-weight: 700;
}

.badge-vente {
	background: rgba(16, 185, 129, .12);
	color: #059669;
}

.badge-location {
	background: rgba(200, 134, 10, .12);
	color: var(--gold);
}

.actions-cell {
	display: flex;
	gap: 6px;
}

.act-btn {
	width: 32px;
	height: 32px;
	border-radius: 9px;
	border: 1.5px solid rgba(200, 134, 10, .15);
	background: transparent;
	display: flex;
	align-items: center;
	justify-content: center;
	cursor: pointer;
	transition: all .2s;
	color: var(--soft);
	text-decoration: none;
	font-size: 13px;
}

.act-btn:hover {
	border-color: var(--blue);
	color: var(--blue);
	transform: scale(1.08);
}

.act-btn.del:hover {
	border-color: var(--red);
	color: var(--red);
}

.empty {
	text-align: center;
	padding: 60px 20px;
	color: var(--soft);
}

.empty i {
	font-size: 52px;
	opacity: .25;
	margin-bottom: 16px;
	display: block;
}

.empty h3 {
	font-size: 16px;
	font-weight: 600;
	color: var(--dark);
	margin-bottom: 6px;
}

.empty p {
	font-size: 13px;
}

.modal {
	display: none;
	position: fixed;
	inset: 0;
	background: rgba(13, 11, 8, .75);
	backdrop-filter: blur(10px);
	z-index: 1000;
	align-items: center;
	justify-content: center;
}

.modal.open {
	display: flex;
}

.modal-box {
	background: var(--white);
	border-radius: 24px;
	width: 460px;
	max-width: 92%;
	padding: 28px;
	animation: mIn .3s cubic-bezier(.22, .97, .45, 1);
}

@keyframes mIn { from { opacity:0; transform: scale(.95) translateY(-14px); } to { opacity:1; transform: scale(1) translateY(0); } }

.modal-top {
	display: flex;
	justify-content: space-between;
	align-items: center;
	margin-bottom: 22px;
}

.modal-top h3 {
	font-family: 'Syne', sans-serif;
	font-size: 20px;
	font-weight: 700;
}

.modal-x {
	width: 34px;
	height: 34px;
	border-radius: 10px;
	border: 1.5px solid rgba(200, 134, 10, .15);
	background: none;
	cursor: pointer;
	font-size: 18px;
	transition: all .2s;
}

.modal-x:hover {
	border-color: var(--red);
	color: var(--red);
}

.m-avatar {
	text-align: center;
	margin-bottom: 20px;
}

.big-av {
	width: 90px;
	height: 90px;
	background: linear-gradient(135deg, var(--gold), var(--gold-light));
	border-radius: 22px;
	margin: 0 auto 10px;
	display: flex;
	align-items: center;
	justify-content: center;
	font-family: 'Syne', sans-serif;
	font-size: 36px;
	font-weight: 800;
	color: #fff;
	box-shadow: 0 10px 28px rgba(200, 134, 10, .35);
}

.m-field {
	margin-bottom: 14px;
}

.m-field label {
	display: block;
	font-size: 11.5px;
	font-weight: 600;
	color: var(--mid);
	margin-bottom: 5px;
	text-transform: uppercase;
	letter-spacing: .5px;
}

.m-field input {
	width: 100%;
	padding: 11px 13px;
	border: 1.5px solid rgba(200, 134, 10, .15);
	border-radius: 11px;
	font-family: 'DM Sans', sans-serif;
	font-size: 14px;
	transition: all .2s;
}

.m-field input:focus {
	outline: none;
	border-color: var(--gold);
	box-shadow: 0 0 0 3px rgba(200, 134, 10, .1);
}

.m-actions {
	display: flex;
	gap: 10px;
	margin-top: 20px;
}

.m-save {
	background: linear-gradient(115deg, var(--gold), var(--gold-light));
	border: none;
	color: white;
}

.m-save:hover {
	transform: translateY(-1px);
	box-shadow: 0 6px 16px rgba(200, 134, 10, .3);
}

.m-cancel {
	background: none;
	border: 1.5px solid rgba(200, 134, 10, .2);
	color: var(--mid);
}

.m-cancel:hover {
	border-color: var(--gold);
	color: var(--gold);
}

.house-mini-svg {
	width: 52px;
	height: 40px;
}

::-webkit-scrollbar {
	width: 5px;
}

::-webkit-scrollbar-thumb {
	background: rgba(200, 134, 10, .2);
	border-radius: 4px;
}

@keyframes fadeUp { from { opacity:0; transform: translateY(16px); } to { opacity:1; transform: translateY(0); } }
.fade-in-1 { animation: fadeUp .5s .05s both; }
.fade-in-2 { animation: fadeUp .5s .15s both; }
.fade-in-3 { animation: fadeUp .5s .25s both; }
.fade-in-4 { animation: fadeUp .5s .35s both; }

@media (max-width: 900px) {
	.sidebar { transform: translateX(-100%); }
	.main { margin-left: 0; padding: 20px; }
	.stats-row { grid-template-columns: repeat(2, 1fr); }
	.quick-row { grid-template-columns: 1fr 1fr; }
}

@media (max-width: 560px) {
	.stats-row { grid-template-columns: 1fr; }
	.quick-row { grid-template-columns: 1fr; }
}

.sell-btn i { color: var(--gold); }
.sell-btn:hover { border-color: var(--teal); }
.sell-btn:hover i { color: var(--teal); }

.overlay-modal {
	display: none;
	position: fixed;
	top: 0;
	left: 0;
	width: 100%;
	height: 100%;
	background: rgba(0, 0, 0, 0.7);
	backdrop-filter: blur(8px);
	z-index: 2000;
	align-items: center;
	justify-content: center;
}

.overlay-modal.active { display: flex; }

.overlay-content {
	background: var(--white);
	border-radius: 28px;
	width: 450px;
	max-width: 90%;
	padding: 32px;
	text-align: center;
	animation: fadeUp 0.3s ease;
	box-shadow: 0 25px 50px rgba(0, 0, 0, 0.3);
}

.overlay-content h3 {
	font-family: 'Syne', sans-serif;
	font-size: 22px;
	margin-bottom: 20px;
}

.overlay-content p {
	margin-bottom: 25px;
	color: var(--mid);
}

.overlay-buttons {
	display: flex;
	gap: 12px;
	justify-content: center;
	margin-top: 10px;
}

.overlay-btn {
	padding: 12px 24px;
	border-radius: 40px;
	border: none;
	font-weight: 600;
	cursor: pointer;
	transition: all 0.2s;
}

.overlay-btn-yes {
	background: linear-gradient(135deg, var(--teal), var(--teal-light));
	color: white;
}

.overlay-btn-no {
	background: var(--bg2);
	border: 1.5px solid rgba(200, 134, 10, 0.2);
	color: var(--mid);
}

.overlay-btn-close {
	background: transparent;
	border: 1.5px solid var(--soft);
	color: var(--soft);
}

.overlay-btn-yes:hover { transform: scale(1.05); }
.overlay-btn-no:hover { border-color: var(--gold); color: var(--gold); }

.overlay-select {
	width: 100%;
	padding: 12px 15px;
	border-radius: 14px;
	border: 1.5px solid rgba(200, 134, 10, 0.2);
	font-family: 'DM Sans', sans-serif;
	font-size: 14px;
	margin: 15px 0;
	background: var(--bg2);
	cursor: pointer;
}

/* Mode sombre corrections */
body.dark-theme .stat-card,
body.dark-theme .content-card,
body.dark-theme .quick-action,
body.dark-theme .modal-box,
body.dark-theme .overlay-content {
	background: var(--white);
	border-color: rgba(255,255,255,.08);
}
body.dark-theme .stat-lbl,
body.dark-theme .qa-text p,
body.dark-theme .ch-sub,
body.dark-theme .prop-meta span {
	color: var(--soft);
}
body.dark-theme td,
body.dark-theme .prop-meta h4,
body.dark-theme .qa-text h4,
body.dark-theme .ch-title {
	color: var(--dark);
}
body.dark-theme thead tr {
	background: rgba(255,255,255,.05);
}
body.dark-theme tr:hover td {
	background: rgba(255,255,255,.03);
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
/* Pour que la sidebar accepte les modifications JS */
.sidebar {
    transition: background 0.3s ease;
}
/* Styles pour la sélection des clients */
.client-card {
	display: flex;
	align-items: center;
	gap: 15px;
	padding: 12px 15px;
	margin: 8px 10px;
	background: var(--white);
	border: 1.5px solid rgba(200, 134, 10, .12);
	border-radius: 16px;
	cursor: pointer;
	transition: all 0.25s ease;
}

.client-card:hover {
	background: var(--bg2);
	border-color: var(--gold);
	transform: translateX(5px);
}

.client-card.selected {
	background: var(--gold-pale);
	border-color: var(--gold);
	border-width: 2px;
}

.client-card-avatar {
	width: 50px;
	height: 50px;
	border-radius: 50%;
	overflow: hidden;
	flex-shrink: 0;
	background: linear-gradient(135deg, var(--gold), var(--gold-light));
	display: flex;
	align-items: center;
	justify-content: center;
}

.client-card-avatar img {
	width: 100%;
	height: 100%;
	object-fit: cover;
}

.client-card-initial {
	width: 50px;
	height: 50px;
	display: flex;
	align-items: center;
	justify-content: center;
	font-family: 'Syne', sans-serif;
	font-size: 22px;
	font-weight: 800;
	color: white;
}

.client-card-info {
	flex: 1;
}

.client-card-name {
	font-weight: 700;
	font-size: 15px;
	color: var(--dark);
	margin-bottom: 4px;
}

.client-card-email {
	font-size: 12px;
	color: var(--soft);
}

.client-card-email i {
	font-size: 10px;
	margin-right: 4px;
	color: var(--gold);
}

.client-card-check {
	width: 32px;
	height: 32px;
	border-radius: 50%;
	background: var(--teal);
	display: flex;
	align-items: center;
	justify-content: center;
	color: white;
	font-size: 16px;
	flex-shrink: 0;
}

/* Mode sombre */
body.dark-theme .client-card {
	background: var(--white);
	border-color: rgba(255,255,255,.08);
}

body.dark-theme .client-card:hover {
	background: rgba(255,255,255,.05);
}

body.dark-theme .client-card.selected {
	background: rgba(200, 134, 10, .15);
	
}
.badge-terrain {
	background: rgba(5, 150, 105, .12);
	color: #059669;
}
</style>
</head>
<body>

<script>
// FORCER la couleur de la sidebar immédiatement au chargement
(function() {
    var savedColor = localStorage.getItem('fredon_primary_color');
    if (savedColor) {
        var colorValue = '';
        switch(savedColor) {
            case 'gold': colorValue = '#c8860a'; break;
            case 'blue': colorValue = '#1f52d4'; break;
            case 'green': colorValue = '#10b981'; break;
            case 'purple': colorValue = '#7c3aed'; break;
            case 'rose': colorValue = '#e03060'; break;
            case 'teal': colorValue = '#0e9e8a'; break;
            default: colorValue = '#c8860a';
        }
        var sidebar = document.querySelector('.sidebar');
        if (sidebar) {
            sidebar.style.background = 'linear-gradient(160deg, #0d1f5e 0%, ' + colorValue + ' 45%, #0e2d82 75%, #0a1d58 100%)';
        }
    }
})();
</script>

<canvas id="bgCanvas"></canvas>

<div class="layout">

	<aside class="sidebar">
		<div class="sidebar-grid"></div>
		<div class="logo-area" style="padding: 20px 18px 18px; gap: 14px;">
		  <img src="${pageContext.request.contextPath}/immo/admin/images/Logo.jpg"
		       alt="Fredon"
		       style="width: 68px; height: 68px; object-fit: cover; border-radius: 18px; box-shadow: 0 6px 22px rgba(0,0,0,.45), 0 0 0 2px rgba(255,255,255,.2); transition: transform .25s;"
		       onmouseover="this.style.transform='scale(1.05)'" onmouseout="this.style.transform='scale(1)'">
		  <div class="logo-text-wrap">
		    <span style="font-family:'Syne',sans-serif; font-weight:800; font-size:26px; letter-spacing:-.5px; background: linear-gradient(120deg,#ffffff 0%,#cce8ff 50%,#fde9b0 100%); -webkit-background-clip:text; background-clip:text; color:transparent; display:block; line-height:1.1;">Fredon</span>
		    <span style="font-size:10px; color:rgba(255,255,255,.6); letter-spacing:2.8px; text-transform:uppercase; margin-top:4px; display:block; font-weight:400;"><%= TranslateUtil.t(lang,"real_estate_agency") %></span>
		  </div>
		</div>
		<nav class="nav">
			<div class="nav-section"><%= TranslateUtil.t(lang, "principal") %></div>
			<a href="${pageContext.request.contextPath}/admin/dashboard" class="nav-item active"> <i class="fas fa-chart-line"></i> <%= TranslateUtil.t(lang, "dashboard") %></a>
			<a href="${pageContext.request.contextPath}/admin/add-property" class="nav-item"> <i class="fas fa-plus-circle"></i> <%= TranslateUtil.t(lang, "add") %> <%= TranslateUtil.t(lang, "property") %></a>
			<a href="${pageContext.request.contextPath}/chat" class="nav-item">
				<i class="fas fa-comments"></i> <%= TranslateUtil.t(lang, "messages") %>
				<% if (unreadMessages > 0) { %> <span class="nav-badge"><%= unreadMessages %></span> <% } %>
			</a>
			<div class="nav-section"><%= TranslateUtil.t(lang, "management") %></div>
			<a href="${pageContext.request.contextPath}/admin/clients" class="nav-item"> <i class="fas fa-users"></i> <%= TranslateUtil.t(lang, "clients") %></a>
			
			<a href="${pageContext.request.contextPath}/admin/appointments" class="nav-item"> 
				<i class="fas fa-calendar-check"></i> <%= TranslateUtil.t(lang, "appointments") %>
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
				<span class="nav-badge" style="background: var(--gold);"><%= pendingAppointments %></span> 
				<% } %>
			</a>
			
			<a href="${pageContext.request.contextPath}/admin/statistics" class="nav-item"> <i class="fas fa-chart-pie"></i> <%= TranslateUtil.t(lang, "statistics") %></a>
			<div class="nav-section"><%= TranslateUtil.t(lang, "system") %></div>
			<a href="${pageContext.request.contextPath}/" class="nav-item"> <i class="fas fa-globe"></i> <%= TranslateUtil.t(lang, "view_site") %></a>
			<a href="${pageContext.request.contextPath}/admin/setting" class="nav-item"><i class="fas fa-cog"></i> Paramètres</a>
			<a href="${pageContext.request.contextPath}/logout" class="nav-item logout"> <i class="fas fa-sign-out-alt"></i> <%= TranslateUtil.t(lang, "logout") %></a>
		</nav>
		<div class="user-bottom" onclick="openModal()">
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

		<div class="top-bar fade-in-1">
			<div class="page-title">
				<h1><%= TranslateUtil.t(lang, "dashboard") %> 🏡</h1>
				<p><i class="fas fa-calendar-alt" style="color: var(--gold); margin-right: 5px;"></i><%= TranslateUtil.t(lang, "welcome") %>, <strong><%= adminName %></strong> !</p>
			</div>
			<div class="top-right">
				<a href="${pageContext.request.contextPath}/admin/add-property" class="top-btn top-btn-primary"> <i class="fas fa-plus"></i> <%= TranslateUtil.t(lang, "new_property") %></a>
				<a href="${pageContext.request.contextPath}/admin/notifications" class="notif-wrap" style="text-decoration: none;">
					<div class="icon-circle" style="position: relative;">
						<i class="fas fa-bell"></i>
						<% 
                        int notifCount = 0;
                        try {
                            Class.forName("com.mysql.cj.jdbc.Driver");
                            Connection connCount = DriverManager.getConnection("jdbc:mysql://localhost:3306/quickchat", "root", "");
                            PreparedStatement pstmtCount = connCount.prepareStatement("SELECT COUNT(*) FROM notifications WHERE user_id = ? AND is_read = 0");
                            pstmtCount.setInt(1, adminId);
                            ResultSet rsCount = pstmtCount.executeQuery();
                            if (rsCount.next()) notifCount = rsCount.getInt(1);
                            rsCount.close();
                            pstmtCount.close();
                            connCount.close();
                        } catch(Exception e) {}
                        %>
						<% if (notifCount > 0) { %> 
						<span class="notif-pip"><%= notifCount > 9 ? "9+" : notifCount %></span>
						<% } %>
					</div>
				</a>
				<a href="${pageContext.request.contextPath}/admin/setting" class="icon-circle" style="text-decoration: none;"> <i class="fas fa-cog"></i></a>
			</div>
		</div>

		<% if (success != null) { %>
		<div class="alert alert-success fade-in-1">
			<i class="fas fa-check-circle"></i> <span> 
				<% if ("property_added".equals(success)) { %><%= TranslateUtil.t(lang, "property_added_success") %>
				<% } else if ("property_updated".equals(success)) { %><%= TranslateUtil.t(lang, "property_updated_success") %>
				<% } else if ("property_deleted".equals(success)) { %><%= TranslateUtil.t(lang, "property_deleted_success") %>
				<% } %>
			</span>
			<button class="alert-close" onclick="this.parentElement.remove()">×</button>
		</div>
		<% } %>
		<% if (error != null) { %>
		<div class="alert alert-error fade-in-1">
			<i class="fas fa-exclamation-triangle"></i> <span><%= TranslateUtil.t(lang, "error_occurred") %></span>
			<button class="alert-close" onclick="this.parentElement.remove()">×</button>
		</div>
		<% } %>

		<div class="stats-row fade-in-2">
			<div class="stat-card sc-blue">
				<div class="stat-top">
					<div class="stat-ico ico-blue"><i class="fas fa-home"></i></div>
					<span class="stat-badge badge-up-blue">↑ +12%</span>
				</div>
				<div class="stat-val val-blue"><%= totalProperties %></div>
				<div class="stat-lbl"><%= TranslateUtil.t(lang, "properties_online") %></div>
				<div class="stat-bar"><div class="stat-fill fill-blue" style="width:<%= Math.min(100, totalProperties * 2) %>%"></div></div>
			</div>
			<div class="stat-card sc-rose">
				<div class="stat-top">
					<div class="stat-ico ico-rose"><i class="fas fa-comment-dots"></i></div>
					<span class="stat-badge badge-up-rose"><% if(unreadMessages>0){%>+<%= unreadMessages %><%}else{%>→ 0<%}%></span>
				</div>
				<div class="stat-val val-rose"><%= unreadMessages %></div>
				<div class="stat-lbl"><%= TranslateUtil.t(lang, "unread_messages") %></div>
				<div class="stat-bar"><div class="stat-fill fill-rose" style="width:<%= Math.min(100, unreadMessages*8) %>%"></div></div>
			</div>
			<div class="stat-card sc-teal">
				<div class="stat-top">
					<div class="stat-ico ico-teal"><i class="fas fa-handshake"></i></div>
					<span class="stat-badge badge-up-teal">↑ +8%</span>
				</div>
				<%
int totalSold = 0;
try {
    Class.forName("com.mysql.cj.jdbc.Driver");
    Connection connSold = DriverManager.getConnection(DB_URL, DB_USER, DB_PASSWORD);
    Statement stmtSold = connSold.createStatement();
    ResultSet rsSold = stmtSold.executeQuery("SELECT COUNT(*) as total FROM properties WHERE status = 'sold'");
    if (rsSold.next()) totalSold = rsSold.getInt("total");
    rsSold.close(); stmtSold.close(); connSold.close();
} catch(Exception e) { totalSold = 0; }
%>
			<div class="stat-val val-teal"><%= totalSold %></div>
				<div class="stat-lbl"><%= TranslateUtil.t(lang, "total_sales") %></div>
					<div class="stat-bar"><div class="stat-fill fill-teal" style="width: 68%"></div></div>
			</div>
			<div class="stat-card sc-gold">
				<div class="stat-top">
					<div class="stat-ico ico-gold"><i class="fas fa-eye"></i></div>
					<span class="stat-badge badge-up-gold"><%= TranslateUtil.t(lang, "stat") %> Vue</span>
				</div>
				<div class="stat-val val-gold"><%= totalViews %></div>
				<div class="stat-lbl"><%= TranslateUtil.t(lang, "total_views") %></div>
				<div class="stat-bar"><div class="stat-fill fill-gold" style="width:<%= totalViews > 0 ? 65 : 0 %>%"></div></div>
			</div>
		</div>

		<div class="quick-row fade-in-3">
			<a href="${pageContext.request.contextPath}/admin/add-property" class="quick-action">
				<div class="qa-icon" style="background: var(--blue-pale); color: var(--blue)"><i class="fas fa-plus-circle"></i></div>
				<div class="qa-text"><h4><%= TranslateUtil.t(lang, "add_property") %></h4><p><%= TranslateUtil.t(lang, "publish_announcement") %></p></div>
			</a>
			<a href="${pageContext.request.contextPath}/chat" class="quick-action">
				<div class="qa-icon" style="background: var(--rose-pale); color: var(--rose)"><i class="fas fa-comments"></i></div>
				<div class="qa-text"><h4><%= TranslateUtil.t(lang, "messaging") %></h4><p><%= unreadMessages %> <%= TranslateUtil.t(lang, "unread_messages_lower") %></p></div>
			</a>
			<a href="${pageContext.request.contextPath}/admin/clients" class="quick-action">
				<div class="qa-icon" style="background: var(--teal-pale); color: var(--teal)"><i class="fas fa-users"></i></div>
				<div class="qa-text"><h4><%= TranslateUtil.t(lang, "clients") %></h4><p><%= TranslateUtil.t(lang, "manage_contacts") %></p></div>
			</a>
		</div>

		<div class="content-card fade-in-4">
			<div class="card-head">
				<div class="card-head-left">
					<div class="ch-icon"><i class="fas fa-list-ul"></i></div>
					<div><div class="ch-title"><%= TranslateUtil.t(lang, "properties_list") %></div><div class="ch-sub"><%= TranslateUtil.t(lang, "manage_portfolio") %></div></div>
				</div>
				<a href="${pageContext.request.contextPath}/admin/add-property" class="btn-add"><i class="fas fa-plus"></i> <%= TranslateUtil.t(lang, "add") %></a>
			</div>
			
			<div style="padding: 0 26px 15px 26px;">
			    <div style="display: flex; gap: 10px; align-items: center; background: var(--bg2); border-radius: 40px; padding: 5px 15px; border: 1.5px solid rgba(200, 134, 10, .1);">
			        <i class="fas fa-search" style="color: var(--soft);"></i>
			        <input type="text" id="searchPropertyInput" placeholder="<%= TranslateUtil.t(lang, "search_by_title") %>" 
			               autocomplete="off" readonly style="width: 100%; padding: 10px 0; border: none; background: transparent; outline: none; font-size: 13px; color: var(--dark);"
			               onfocus="this.removeAttribute('readonly')">
			        <button id="clearSearchBtn" style="background: none; border: none; cursor: pointer; color: var(--soft); display: none;">✕</button>
			    </div>
			</div>

			<% if (properties == null || properties.isEmpty()) { %>
			<div class="empty">
				<i class="fas fa-home"></i>
				<h3><%= TranslateUtil.t(lang, "no_properties") %></h3>
				<p><%= TranslateUtil.t(lang, "add_first_property") %></p>
				<a href="${pageContext.request.contextPath}/admin/add-property" class="btn-add" style="margin-top: 18px; display: inline-flex;"><i class="fas fa-plus"></i> <%= TranslateUtil.t(lang, "add_property") %></a>
			</div>
			<% } else { %>
			<div class="tbl-wrap">
				<table id="propertiesTable">
					<thead>
						<tr>
							<th><%= TranslateUtil.t(lang, "property") %></th>
							<th><%= TranslateUtil.t(lang, "price") %></th>
							<th><%= TranslateUtil.t(lang, "location") %></th>
							<th><%= TranslateUtil.t(lang, "type") %></th>
							<th><%= TranslateUtil.t(lang, "date") %></th>
							<th><%= TranslateUtil.t(lang, "actions") %></th>
						</td>
					</thead>
					<tbody>
						<% for (Property property : properties) { %>
						<tr>
							<td>
								<div class="prop-cell">
									<div class="prop-thumb">
									    <% 
									    String mainImage = null;
									    try {
									        Connection connImg = DriverManager.getConnection("jdbc:mysql://localhost:3306/quickchat", "root", "");
									        PreparedStatement pstmtImg = connImg.prepareStatement("SELECT image_url FROM property_images WHERE property_id = ? AND is_primary = 1 LIMIT 1");
									        pstmtImg.setInt(1, property.getId());
									        ResultSet rsImg = pstmtImg.executeQuery();
									        if (rsImg.next()) {
									            mainImage = rsImg.getString("image_url");
									        }
									        rsImg.close();
									        pstmtImg.close();
									        connImg.close();
									    } catch(Exception e) { }
									    %>
									    <% if (mainImage != null && !mainImage.isEmpty()) { %>
									    <img src="${pageContext.request.contextPath}/<%= mainImage %>" alt="<%= property.getTitle() %>" style="width: 100%; height: 100%; object-fit: cover;">
									    <% } else { %>
									    <svg class="house-mini-svg" viewBox="0 0 52 40"><!-- SVG --></svg>
									    <% } %>
									</div>
									<div class="prop-meta">
									    <h4><%= property.getTitle() %></h4>
									    <span>
									        <% if ("Terrain".equals(property.getType())) { 
									            String landArea = property.getLandArea();
									            if (landArea != null && !landArea.trim().isEmpty()) { out.print(landArea); } else { out.print("—"); }
									        } else { 
									            Integer surface = property.getSurface();
									            if (surface != null && surface > 0) { out.print(surface + " m²"); } else { out.print("—"); }
									        } %>
									    </span>
									    <% if ("sold".equals(property.getStatus())) { %>
									    <span style="display: inline-block; background: #ef4444; color: white; font-size: 10px; font-weight: bold; padding: 2px 8px; border-radius: 20px; margin-left: 8px;"><%= TranslateUtil.t(lang, "sold") %></span>
									    <% } %>
									</div>
								</div>
							</div>
							
							<td class="prop-price"><%= String.format("%,.0f", property.getPrice()) %> Ar</td>
							<td style="color: var(--mid); font-size: 13px;"><i class="fas fa-map-marker-alt" style="color: var(--rose-light); font-size: 10px; margin-right: 4px;"></i> <%= property.getLocation() %></td>
							<td>
							    <% 
							        String typeValue = property.getType();
							        String badgeClass = "badge-type badge-";
							        String displayText = "";
							        if ("Vente".equals(typeValue)) { badgeClass += "vente"; displayText = TranslateUtil.t(lang, "sale");
							        } else if ("Location".equals(typeValue)) { badgeClass += "location"; displayText = TranslateUtil.t(lang, "rent");
							        } else if ("Terrain".equals(typeValue)) { badgeClass += "terrain"; displayText = "🌾 Terrain";
							        } else { badgeClass += "vente"; displayText = typeValue; }
							    %>
							    <span class="<%= badgeClass %>"><%= displayText %></span>
							</td>
							<td style="color: var(--soft); font-size: 12px;">
								<%
                                SimpleDateFormat sdf = new SimpleDateFormat("dd/MM/yyyy");
                                if (property.getCreatedAt() != null) out.print(sdf.format(property.getCreatedAt()));
                                else out.print("—");
                                %>
							</td>
							<td>
								<div class="actions-cell">
								    <% if (!"sold".equals(property.getStatus())) { %>
								    <button class="act-btn sell-btn" title="<%= TranslateUtil.t(lang, "mark_as_sold") %>" onclick="openSellOverlay(<%= property.getId() %>, '<%= property.getTitle().replace("'", "\\'") %>')">
								        <i class="fas fa-hand-holding-usd"></i>
								    </button>
								    <a href="${pageContext.request.contextPath}/admin/edit-property?id=<%= property.getId() %>" class="act-btn" title="<%= TranslateUtil.t(lang, "edit") %>"><i class="fas fa-pen"></i></a>
								    <form action="${pageContext.request.contextPath}/admin/delete-property" method="POST" style="display: inline;" onsubmit="return confirm('<%= TranslateUtil.t(lang, "confirm_delete") %>')">
								        <input type="hidden" name="id" value="<%= property.getId() %>">
								        <button type="submit" class="act-btn del" title="<%= TranslateUtil.t(lang, "delete") %>"><i class="fas fa-trash"></i></button>
								    </form>
								    <% } else { %>
								    <span style="background: #ef4444; color: white; padding: 5px 10px; border-radius: 8px; font-size: 11px; font-weight: bold;"><i class="fas fa-check-circle"></i> <%= TranslateUtil.t(lang, "sold") %></span>
								    <% } %>
								</div>
							</td>
						</tr>
						<% } %>
					</tbody>
				</table>
			</div>
			<% } %>
		</div>

	</main>
</div>

<div class="modal" id="profileModal">
	<div class="modal-box">
		<div class="modal-top">
			<h3><%= TranslateUtil.t(lang, "my_profile") %></h3>
			<button class="modal-x" onclick="closeModal()">×</button>
		</div>
		<div class="m-avatar">
			<div class="big-av"><%= adminInitial %></div>
			<button class="btn-add" style="padding: 6px 14px; font-size: 11.5px;" onclick="document.getElementById('avatarInput').click()"><i class="fas fa-camera"></i> <%= TranslateUtil.t(lang, "change_photo") %></button>
			<input type="file" id="avatarInput" style="display: none;" accept="image/*">
		</div>
		<div class="m-field">
			<label><%= TranslateUtil.t(lang, "username") %></label>
			<input type="text" value="<%= adminName %>" readonly style="background: var(--bg);">
		</div>
		<div class="m-field">
			<label><%= TranslateUtil.t(lang, "email") %></label>
			<input type="email" placeholder="admin@fredon.com" value="admin@fredon.com">
		</div>
		<div class="m-field">
			<label><%= TranslateUtil.t(lang, "new_password") %></label>
			<input type="password" placeholder="<%= TranslateUtil.t(lang, "leave_empty") %>">
		</div>
		<div class="m-actions">
			<button class="m-save" onclick="alert('<%= TranslateUtil.t(lang, "profile_updated") %>'); closeModal()"><i class="fas fa-save"></i> <%= TranslateUtil.t(lang, "save") %></button>
			<button class="m-cancel" onclick="closeModal()"><%= TranslateUtil.t(lang, "cancel") %></button>
		</div>
	</div>
</div>

<script>
(function() {
    const canvas = document.getElementById('bgCanvas');
    const ctx = canvas.getContext('2d');
    let W, H, houses = [];

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

document.querySelectorAll('.stat-fill').forEach(bar => {
    const w = bar.style.width;
    bar.style.width = '0';
    setTimeout(() => { bar.style.width = w; }, 300);
});

function openModal()  { document.getElementById('profileModal').classList.add('open'); }
function closeModal() { document.getElementById('profileModal').classList.remove('open'); }
document.getElementById('profileModal').addEventListener('click', function(e) {
    if (e.target === this) closeModal();
});

const alertEl = document.querySelector('.alert');
if (alertEl) {
    setTimeout(() => {
        alertEl.style.transition = 'opacity .4s';
        alertEl.style.opacity = '0';
        setTimeout(() => alertEl.remove(), 400);
    }, 5000);
}

let currentPropertyId = null;
let currentPropertyTitle = '';
let selectedClientIdCard = null;
let selectedClientNameCard = '';

function openSellOverlay(propertyId, propertyTitle) {
    currentPropertyId = propertyId;
    currentPropertyTitle = propertyTitle;
    document.getElementById('overlayConfirm').classList.add('active');
}

function closeOverlay() {
    document.getElementById('overlayConfirm').classList.remove('active');
    selectedClientIdCard = null;
    selectedClientNameCard = '';
    document.querySelectorAll('.client-card').forEach(card => {
        card.classList.remove('selected');
        card.querySelector('.client-card-check').style.display = 'none';
    });
}

function showClientSelection() {
    document.getElementById('overlayConfirm').classList.remove('active');
    document.getElementById('overlayClientSelect').classList.add('active');
}

function closeClientSelection() {
    document.getElementById('overlayClientSelect').classList.remove('active');
    selectedClientIdCard = null;
    selectedClientNameCard = '';
    document.querySelectorAll('.client-card').forEach(card => {
        card.classList.remove('selected');
        card.querySelector('.client-card-check').style.display = 'none';
    });
}

function selectClientCard(element, clientId, clientName) {
    document.querySelectorAll('.client-card').forEach(card => {
        card.classList.remove('selected');
        card.querySelector('.client-card-check').style.display = 'none';
    });
    element.classList.add('selected');
    element.querySelector('.client-card-check').style.display = 'flex';
    selectedClientIdCard = clientId;
    selectedClientNameCard = clientName;
}

function confirmMarkAsSold() {
    if (!selectedClientIdCard) {
        alert('Veuillez sélectionner un client');
        return;
    }
    const btn = event.target;
    btn.innerHTML = '<i class="fas fa-spinner fa-spin"></i> Traitement...';
    btn.disabled = true;
    
    fetch('${pageContext.request.contextPath}/admin/mark-property-sold', {
        method: 'POST',
        headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
        body: 'propertyId=' + currentPropertyId + '&clientId=' + selectedClientIdCard
    })
    .then(response => response.json())
    .then(data => {
        if (data.success) {
            alert('✓ Bien vendu à ' + selectedClientNameCard + ' !');
            location.reload();
        } else {
            alert('Erreur: ' + data.error);
            btn.innerHTML = '<%= TranslateUtil.t(lang, "confirm_sale") %>';
            btn.disabled = false;
        }
    })
    .catch(error => {
        console.error('Erreur:', error);
        alert('Une erreur est survenue');
        btn.innerHTML = '<%= TranslateUtil.t(lang, "confirm_sale") %>';
        btn.disabled = false;
    });
}

function markAsSold() {
    confirmMarkAsSold();
}
</script>

<script>
(function() {
    var theme = localStorage.getItem('fredon_theme') || 'light';
    if (theme === 'dark') {
        document.body.classList.add('dark-theme', 'dm');
    } else {
        document.body.classList.add('light-theme');
    }
})();

const searchInput = document.getElementById('searchPropertyInput');
const clearBtn = document.getElementById('clearSearchBtn');
const tableRows = document.querySelectorAll('#propertiesTable tbody tr');

if(searchInput) {
    searchInput.addEventListener('keyup', function() {
        const searchTerm = this.value.toLowerCase().trim();
        if(searchTerm.length > 0) { clearBtn.style.display = 'block'; } else { clearBtn.style.display = 'none'; }
        let visibleCount = 0;
        tableRows.forEach(row => {
            const title = row.querySelector('.prop-meta h4')?.innerText.toLowerCase() || '';
            const location = row.querySelector('td:nth-child(3)')?.innerText.toLowerCase() || '';
            const type = row.querySelector('.badge-type')?.innerText.toLowerCase() || '';
            if(title.includes(searchTerm) || location.includes(searchTerm) || type.includes(searchTerm)) {
                row.style.display = '';
                visibleCount++;
            } else {
                row.style.display = 'none';
            }
        });
        let noResultMsg = document.getElementById('noSearchResult');
        if(visibleCount === 0 && tableRows.length > 0) {
            if(!noResultMsg) {
                noResultMsg = document.createElement('tr');
                noResultMsg.id = 'noSearchResult';
                noResultMsg.innerHTML = '<td colspan="6" style="text-align: center; padding: 40px;"><i class="fas fa-search"></i> Aucun bien trouvé<\/td>';
                document.querySelector('#propertiesTable tbody').appendChild(noResultMsg);
            }
        } else if(noResultMsg) {
            noResultMsg.remove();
        }
    });
    
    clearBtn.addEventListener('click', function() {
        searchInput.value = '';
        searchInput.dispatchEvent(new Event('keyup'));
    });
}
</script>

<div id="overlayConfirm" class="overlay-modal">
	<div class="overlay-content">
		<i class="fas fa-tag" style="font-size: 48px; color: var(--gold); margin-bottom: 15px;"></i>
		<h3><%= TranslateUtil.t(lang, "mark_as_sold") %></h3>
		<p><%= TranslateUtil.t(lang, "confirm_sale") %></p>
		<div class="overlay-buttons">
			<button class="overlay-btn overlay-btn-yes" onclick="showClientSelection()"><%= TranslateUtil.t(lang, "yes") %></button>
			<button class="overlay-btn overlay-btn-no" onclick="closeOverlay()"><%= TranslateUtil.t(lang, "no") %></button>
			<button class="overlay-btn overlay-btn-close" onclick="closeOverlay()"><%= TranslateUtil.t(lang, "close") %></button>
		</div>
	</div>
</div>

<div id="overlayClientSelect" class="overlay-modal">
	<div class="overlay-content" style="width: 500px; max-width: 90%;">
		<i class="fas fa-user-check" style="font-size: 48px; color: var(--teal); margin-bottom: 15px;"></i>
		<h3><%= TranslateUtil.t(lang, "select_buyer") %></h3>
		<p><%= TranslateUtil.t(lang, "choose_client") %></p>
		
		<div style="max-height: 400px; overflow-y: auto; margin-bottom: 20px; border-radius: 16px;">
			<% 
            try {
                Connection conn = DriverManager.getConnection("jdbc:mysql://localhost:3306/quickchat", "root", "");
                Statement st = conn.createStatement();
                ResultSet rs = st.executeQuery("SELECT id, username, display_name, email, profile_pic FROM users WHERE role = 'user' ORDER BY display_name");
                while(rs.next()) {
                    String clientName = rs.getString("display_name") != null ? rs.getString("display_name") : rs.getString("username");
                    String clientEmail = rs.getString("email");
                    String profilePic = rs.getString("profile_pic");
                    String initial = clientName.substring(0, 1).toUpperCase();
            %>
            <div class="client-card" data-client-id="<%= rs.getInt("id") %>" data-client-name="<%= clientName %>" onclick="selectClientCard(this, <%= rs.getInt("id") %>, '<%= clientName %>')">
                <div class="client-card-avatar">
                    <% if (profilePic != null && !profilePic.isEmpty()) { %>
                    <img src="${pageContext.request.contextPath}/uploads/<%= profilePic %>" alt="<%= initial %>">
                    <% } else { %>
                    <div class="client-card-initial"><%= initial %></div>
                    <% } %>
                </div>
                <div class="client-card-info">
                    <div class="client-card-name"><%= clientName %></div>
                    <div class="client-card-email"><i class="fas fa-envelope"></i> <%= clientEmail %></div>
                </div>
                <div class="client-card-check" style="display: none;">
                    <i class="fas fa-check-circle"></i>
                </div>
            </div>
            <% 
                }
                rs.close(); st.close(); conn.close();
            } catch(Exception e) { e.printStackTrace(); }
            %>
		</div>
		
		<input type="hidden" id="selectedClientId" value="">
		<input type="hidden" id="selectedClientName" value="">
		
		<div class="overlay-buttons">
			<button class="overlay-btn overlay-btn-yes" onclick="confirmMarkAsSold()"><%= TranslateUtil.t(lang, "confirm_sale") %></button>
			<button class="overlay-btn overlay-btn-close" onclick="closeClientSelection()"><%= TranslateUtil.t(lang, "cancel") %></button>
		</div>
	</div>
</div>
<script>
// Empêche l'accès aux pages après déconnexion
if (performance.navigation.type === 2) {
    window.location.href = '${pageContext.request.contextPath}/login';
}
</script>

</body>
</html>