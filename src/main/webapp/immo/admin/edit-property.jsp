<%@ page language="java" contentType="text/html; charset=UTF-8"
	pageEncoding="UTF-8"%>
<%@ page import="com.immobilier.model.Property"%>
<%@ page import="com.immobilier.model.PropertyImage"%>
<%@ page import="com.immobilier.dao.PropertyDAO"%>
<%@ page import="com.immobilier.dao.PropertyImageDAO"%>
<%@ page import="java.sql.Connection"%>
<%@ page import="java.sql.DriverManager"%>
<%@ page import="java.sql.PreparedStatement"%>
<%@ page import="java.sql.ResultSet"%>
<%@ page import="java.util.List"%>
<%@ page import="com.quickchat.model.User"%>
<%@ page import="com.quickchat.dao.MessageDAO"%>
<%@ page import="com.quickchat.utils.TranslateUtil"%>
<%@ include file="includes/theme.jsp" %>
<%@ include file="includes/color.jsp" %>
<%
System.out.println("=== TEST FORMULAIRE ===");
System.out.println("ID: " + request.getParameter("id"));
System.out.println("Prix reçu: " + request.getParameter("price"));
System.out.println("Prix terrain: " + request.getParameter("priceTerrain"));
%>

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

    String propertyIdStr = request.getParameter("id");
    Property property = null;
    List<PropertyImage> images = null;
    String error = request.getAttribute("error") != null ? (String) request.getAttribute("error") : request.getParameter("error");
    int unreadMessages = 0;

    // Récupération des informations terrain
    String landArea = "";
    String landType = "";
    String landDocumentation = "";
    String landAccess = "";
    String landProximities = "";
    String landNotes = "";
    boolean isLand = false;

    if (propertyIdStr != null && !propertyIdStr.trim().isEmpty()) {
        try {
            int propertyId = Integer.parseInt(propertyIdStr);
            Class.forName("com.mysql.cj.jdbc.Driver");
            Connection conn = DriverManager.getConnection(DB_URL, DB_USER, DB_PASSWORD);
            PropertyDAO propertyDAO = new PropertyDAO(conn);
            PropertyImageDAO imageDAO = new PropertyImageDAO(conn);
            property = propertyDAO.getPropertyById(propertyId);
            if (property != null) {
                images = imageDAO.getImagesByPropertyId(propertyId);
                isLand = "Terrain".equals(property.getType());
                
                // Récupération des infos terrain
                landArea = property.getLandArea() != null ? property.getLandArea() : "";
                landType = property.getLandType() != null ? property.getLandType() : "";
                landDocumentation = property.getLandDocumentation() != null ? property.getLandDocumentation() : "";
                landAccess = property.getLandAccess() != null ? property.getLandAccess() : "";
                landProximities = property.getLandProximities() != null ? property.getLandProximities() : "";
                landNotes = property.getLandNotes() != null ? property.getLandNotes() : "";
            }
            MessageDAO messageDAO = new MessageDAO();
            unreadMessages = messageDAO.countUnreadMessagesForAgent();
            conn.close();
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    if (property == null) {
        response.sendRedirect(request.getContextPath() + "/admin/dashboard?error=property_not_found");
        return;
    }

    String adminName = "Admin";
    if (session.getAttribute("adminUsername") != null) {
        adminName = session.getAttribute("adminUsername").toString();
    } else if (admin != null && admin.getDisplayName() != null) {
        adminName = admin.getDisplayName();
    }
    String adminInitial = (adminName != null && !adminName.isEmpty()) ? adminName.substring(0, 1).toUpperCase() : "A";

    // Récupérer la photo de profil admin
    String adminProfilePic = null;
    try {
        Connection conn = DriverManager.getConnection(DB_URL, DB_USER, DB_PASSWORD);
        PreparedStatement pstmt = conn.prepareStatement("SELECT profile_pic FROM users WHERE id = ?");
        pstmt.setInt(1, adminId);
        ResultSet rs = pstmt.executeQuery();
        if (rs.next()) {
            adminProfilePic = rs.getString("profile_pic");
        }
        rs.close(); pstmt.close(); conn.close();
    } catch(Exception e) {}

    int notifCount = 0;
    try {
        Class.forName("com.mysql.cj.jdbc.Driver");
        Connection connCount = DriverManager.getConnection(DB_URL, DB_USER, DB_PASSWORD);
        PreparedStatement pstmtCount = connCount.prepareStatement(
            "SELECT COUNT(*) FROM notifications WHERE user_id = ? AND is_read = 0");
        pstmtCount.setInt(1, adminId);
        ResultSet rsCount = pstmtCount.executeQuery();
        if (rsCount.next()) notifCount = rsCount.getInt(1);
        rsCount.close(); pstmtCount.close(); connCount.close();
    } catch (Exception e) {}
%>

<!DOCTYPE html>
<html lang="<%= lang %>">
<head>

<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title><%= TranslateUtil.t(lang, "edit_property") %> — Fredon
	Immobilier</title>
<link
	href="https://fonts.googleapis.com/css2?family=Syne:wght@400;600;700;800&family=DM+Sans:ital,opsz,wght@0,9..40,300;0,9..40,400;0,9..40,500;0,9..40,600;0,9..40,700&display=swap"
	rel="stylesheet">
<link rel="stylesheet"
	href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css">
<link rel="stylesheet"
	href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css" />
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
	--emerald: #059669;
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

@
keyframes pulse { 0%,100%{
	opacity: 1;
}

50
%
{
opacity
:
.65;
}
}
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
	text-decoration: none;
}

.top-btn-outline {
	background: var(--white);
	border: 1.5px solid rgba(200, 134, 10, .18);
	color: var(--mid);
}

.top-btn-outline:hover {
	border-color: var(--gold);
	color: var(--gold);
	transform: translateY(-1px);
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
	position: relative;
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

@
keyframes slideIn {
	from {opacity: 0;
	transform: translateY(-8px);
}

to {
	opacity: 1;
	transform: translateY(0);
}

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

.breadcrumb {
	display: flex;
	align-items: center;
	gap: 8px;
	margin-bottom: 20px;
	font-size: 12.5px;
	color: var(--soft);
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
	color: var(--dark);
	font-weight: 600;
}

.form-wrapper {
	display: grid;
	grid-template-columns: 1fr 340px;
	gap: 22px;
	align-items: start;
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
	background: linear-gradient(135deg, var(--gold-pale), #fde9b0);
	display: flex;
	align-items: center;
	justify-content: center;
	font-size: 19px;
	color: var(--gold);
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

.card-body {
	padding: 26px;
}

.form-grid-2 {
	display: grid;
	grid-template-columns: 1fr 1fr;
	gap: 18px;
}

.form-grid-3 {
	display: grid;
	grid-template-columns: 1fr 1fr 1fr;
	gap: 18px;
}

.full-col {
	grid-column: 1/-1;
}

.form-sep {
	grid-column: 1/-1;
	display: flex;
	align-items: center;
	gap: 12px;
	margin: 8px 0 2px;
}

.form-sep span {
	font-size: 10px;
	font-weight: 700;
	letter-spacing: 1.5px;
	text-transform: uppercase;
	color: var(--soft);
	white-space: nowrap;
}

.form-sep::before, .form-sep::after {
	content: '';
	flex: 1;
	height: 1px;
	background: rgba(200, 134, 10, .12);
}

.form-group {
	display: flex;
	flex-direction: column;
	gap: 6px;
}

.form-group label {
	font-size: 11px;
	font-weight: 700;
	letter-spacing: .8px;
	text-transform: uppercase;
	color: var(--mid);
}

.required-star {
	color: var(--rose);
}

.form-control {
	padding: 11px 14px;
	border: 1.5px solid rgba(200, 134, 10, .16);
	border-radius: 12px;
	font-family: 'DM Sans', sans-serif;
	font-size: 14px;
	color: var(--dark);
	background: var(--bg2);
	transition: all .22s;
	outline: none;
	width: 100%;
}

.form-control:hover {
	border-color: rgba(200, 134, 10, .3);
}

.form-control:focus {
	border-color: var(--gold);
	background: var(--white);
	box-shadow: 0 0 0 3px rgba(200, 134, 10, .1);
}

.form-control::placeholder {
	color: rgba(168, 152, 128, .6);
}

textarea.form-control {
	min-height: 120px;
	resize: vertical;
	line-height: 1.6;
}

select.form-control {
	cursor: pointer;
	appearance: none;
	background-image:
		url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='12' height='8' viewBox='0 0 12 8'%3E%3Cpath d='M1 1l5 5 5-5' stroke='%23a89880' stroke-width='1.8' fill='none' stroke-linecap='round'/%3E%3C/svg%3E");
	background-repeat: no-repeat;
	background-position: right 14px center;
	padding-right: 36px;
}

.input-icon-wrap {
	position: relative;
}

.input-icon-wrap .form-control {
	padding-left: 38px;
}

.input-icon {
	position: absolute;
	left: 13px;
	top: 50%;
	transform: translateY(-50%);
	color: var(--soft);
	font-size: 13px;
	pointer-events: none;
}

.map-container {
	margin-top: 15px;
	border-radius: 16px;
	overflow: hidden;
	border: 1.5px solid rgba(200, 134, 10, .15);
}

#map {
	height: 320px;
	width: 100%;
}

.location-buttons {
	display: flex;
	gap: 10px;
	margin: 12px 0;
	flex-wrap: wrap;
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

.location-btn-search {
	background: #27ae60;
}

.map-info {
	font-size: 12px;
	color: var(--soft);
	margin-top: 8px;
}

.gps-coords {
	background: var(--bg2);
	padding: 12px;
	border-radius: 12px;
	margin-top: 10px;
	display: grid;
	grid-template-columns: 1fr 1fr;
	gap: 10px;
}

.gps-coords input {
	background: var(--white);
	border: 1.5px solid rgba(200, 134, 10, .15);
	border-radius: 10px;
	padding: 10px 12px;
	font-size: 13px;
	font-family: monospace;
}

.side-stack {
	display: flex;
	flex-direction: column;
	gap: 18px;
}

.preview-card {
	background: var(--white);
	border-radius: var(--r-xl);
	border: 1.5px solid rgba(200, 134, 10, .1);
	overflow: hidden;
	box-shadow: 0 2px 16px rgba(0, 0, 0, .05);
}

.preview-thumb {
	height: 160px;
	position: relative;
	overflow: hidden;
	background: linear-gradient(135deg, #87CEEB 0%, #5BA3C9 100%);
}

.preview-thumb img {
	width: 100%;
	height: 100%;
	object-fit: cover;
}

.preview-thumb-placeholder {
	width: 100%;
	height: 100%;
	display: flex;
	align-items: center;
	justify-content: center;
}

.preview-badge-type {
	position: absolute;
	top: 10px;
	right: 10px;
	font-size: 10.5px;
	font-weight: 700;
	padding: 4px 11px;
	border-radius: 20px;
}

.badge-vente {
	background: rgba(16, 185, 129, .9);
	color: #fff;
}

.badge-location {
	background: rgba(200, 134, 10, .9);
	color: #fff;
}

.badge-terrain {
	background: rgba(5, 150, 105, .9);
	color: #fff;
}

.preview-info {
	padding: 16px 18px;
}

.preview-title {
	font-family: 'Syne', sans-serif;
	font-size: 15px;
	font-weight: 700;
	color: var(--dark);
	margin-bottom: 4px;
	white-space: nowrap;
	overflow: hidden;
	text-overflow: ellipsis;
}

.preview-loc {
	font-size: 12px;
	color: var(--soft);
	margin-bottom: 10px;
}

.preview-price {
	font-family: 'Syne', sans-serif;
	font-size: 20px;
	font-weight: 800;
	color: var(--gold);
}

.preview-meta {
	display: flex;
	gap: 12px;
	margin-top: 10px;
	padding-top: 10px;
	border-top: 1px solid rgba(200, 134, 10, .08);
	flex-wrap: wrap;
}

.pm-item {
	display: flex;
	align-items: center;
	gap: 5px;
	font-size: 11.5px;
	color: var(--mid);
}

.pm-item i {
	font-size: 10px;
	color: var(--soft);
}

.action-card {
	background: var(--white);
	border-radius: var(--r-xl);
	border: 1.5px solid rgba(200, 134, 10, .1);
	padding: 22px;
	box-shadow: 0 2px 16px rgba(0, 0, 0, .05);
}

.action-card h4 {
	font-family: 'Syne', sans-serif;
	font-size: 13.5px;
	font-weight: 700;
	color: var(--dark);
	margin-bottom: 14px;
	display: flex;
	align-items: center;
	gap: 8px;
}

.action-card h4 i {
	color: var(--gold);
}

.btn-submit {
	width: 100%;
	padding: 13px;
	border: none;
	border-radius: 13px;
	background: linear-gradient(115deg, var(--gold), var(--gold-light));
	color: white;
	font-family: 'Syne', sans-serif;
	font-size: 14px;
	font-weight: 700;
	cursor: pointer;
	transition: all .25s;
	margin-bottom: 10px;
	display: flex;
	align-items: center;
	justify-content: center;
	gap: 8px;
	box-shadow: 0 6px 18px rgba(200, 134, 10, .3);
}

.btn-submit:hover {
	transform: translateY(-2px);
	box-shadow: 0 10px 24px rgba(200, 134, 10, .4);
}

.btn-submit:active {
	transform: translateY(0);
}

.btn-cancel {
	width: 100%;
	padding: 12px;
	border: 1.5px solid rgba(200, 134, 10, .2);
	border-radius: 13px;
	background: transparent;
	color: var(--mid);
	font-family: 'DM Sans', sans-serif;
	font-size: 13.5px;
	font-weight: 600;
	cursor: pointer;
	transition: all .22s;
	text-decoration: none;
	display: flex;
	align-items: center;
	justify-content: center;
	gap: 8px;
}

.btn-cancel:hover {
	border-color: var(--gold);
	color: var(--gold);
	background: var(--gold-pale);
}

.existing-grid {
	display: grid;
	grid-template-columns: repeat(3, 1fr);
	gap: 12px;
	margin-bottom: 18px;
}

.img-item {
	position: relative;
	border-radius: 14px;
	overflow: hidden;
	border: 1.5px solid rgba(200, 134, 10, .14);
	aspect-ratio: 4/3;
	background: var(--bg);
	transition: all .22s;
}

.img-item:hover {
	border-color: var(--gold);
	box-shadow: 0 6px 20px rgba(200, 134, 10, .15);
}

.img-item img {
	width: 100%;
	height: 100%;
	object-fit: cover;
	display: block;
}

.img-item.marked-delete {
	opacity: .35;
	border-color: var(--red);
}

.img-item.marked-delete::after {
	content: '\f00d';
	font-family: 'Font Awesome 6 Free';
	font-weight: 900;
	position: absolute;
	inset: 0;
	display: flex;
	align-items: center;
	justify-content: center;
	font-size: 24px;
	color: var(--red);
	background: rgba(239, 68, 68, .12);
}

.img-primary-badge {
	position: absolute;
	top: 7px;
	left: 7px;
	background: linear-gradient(115deg, var(--gold), var(--gold-light));
	color: white;
	font-size: 9.5px;
	font-weight: 700;
	padding: 3px 9px;
	border-radius: 20px;
	display: flex;
	align-items: center;
	gap: 4px;
	box-shadow: 0 3px 10px rgba(200, 134, 10, .35);
}

.img-overlay {
	position: absolute;
	inset: 0;
	background: linear-gradient(to top, rgba(0, 0, 0, .55) 0%, transparent
		60%);
	opacity: 0;
	transition: opacity .2s;
	display: flex;
	align-items: flex-end;
	justify-content: center;
	padding-bottom: 10px;
	gap: 7px;
}

.img-item:hover .img-overlay {
	opacity: 1;
}

.img-action-btn {
	width: 30px;
	height: 30px;
	border-radius: 8px;
	border: none;
	display: flex;
	align-items: center;
	justify-content: center;
	font-size: 12px;
	cursor: pointer;
	transition: all .2s;
}

.img-star-btn {
	background: rgba(200, 134, 10, .9);
	color: white;
}

.img-del-btn {
	background: rgba(239, 68, 68, .9);
	color: white;
}

.img-star-btn:hover {
	background: var(--gold);
	transform: scale(1.1);
}

.img-del-btn:hover {
	background: var(--red);
	transform: scale(1.1);
}

.img-restore-btn {
	background: rgba(16, 185, 129, .9);
	color: white;
}

.img-restore-btn:hover {
	background: var(--teal);
	transform: scale(1.1);
}

.upload-grid {
	display: grid;
	grid-template-columns: repeat(3, 1fr);
	gap: 12px;
}

.upload-slot {
	aspect-ratio: 4/3;
	border-radius: 14px;
	border: 2px dashed rgba(200, 134, 10, .25);
	display: flex;
	flex-direction: column;
	align-items: center;
	justify-content: center;
	gap: 7px;
	cursor: pointer;
	transition: all .22s;
	background: var(--bg2);
	position: relative;
	overflow: hidden;
}

.upload-slot:hover {
	border-color: var(--gold);
	background: var(--gold-pale);
}

.upload-slot input[type="file"] {
	display: none;
}

.upload-slot i {
	font-size: 20px;
	color: rgba(200, 134, 10, .45);
	transition: all .22s;
}

.upload-slot:hover i {
	color: var(--gold);
	transform: scale(1.1);
}

.upload-slot p {
	font-size: 11px;
	color: var(--soft);
	font-weight: 500;
}

.upload-preview {
	position: absolute;
	inset: 0;
}

.upload-preview img {
	width: 100%;
	height: 100%;
	object-fit: cover;
}

.upload-clear {
	position: absolute;
	top: 6px;
	right: 6px;
	width: 22px;
	height: 22px;
	border-radius: 6px;
	border: none;
	background: rgba(239, 68, 68, .9);
	color: white;
	font-size: 10px;
	cursor: pointer;
	display: none;
	align-items: center;
	justify-content: center;
	z-index: 2;
}

.upload-preview ~ .upload-clear {
	display: flex;
}

.info-box {
	background: var(--blue-pale);
	border: 1.5px solid rgba(79, 126, 248, .2);
	border-radius: 14px;
	padding: 14px 16px;
	display: flex;
	gap: 12px;
	align-items: flex-start;
}

.info-box i {
	color: var(--blue-light);
	font-size: 15px;
	margin-top: 1px;
	flex-shrink: 0;
}

.info-box p {
	font-size: 12px;
	color: var(--blue);
	line-height: 1.5;
}

/* Section terrain */
.terrain-section {
	background: linear-gradient(135deg, rgba(5, 150, 105, .05), rgba(5, 150, 105, .02));
	border-radius: 20px;
	padding: 18px 20px;
	margin-top: 10px;
	border: 1.5px solid rgba(5, 150, 105, .15);
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

::-webkit-scrollbar {
	width: 5px;
}

::-webkit-scrollbar-thumb {
	background: rgba(200, 134, 10, .2);
	border-radius: 4px;
}

@
keyframes fadeUp {
	from {opacity: 0;
	transform: translateY(16px);
}

to {
	opacity: 1;
	transform: translateY(0);
}

}
.fade-in-1 {
	animation: fadeUp .5s .05s both;
}

.fade-in-2 {
	animation: fadeUp .5s .15s both;
}

.fade-in-3 {
	animation: fadeUp .5s .25s both;
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

@
keyframes mIn {
	from {opacity: 0;
	transform: scale(.95) translateY(-14px);
}

to {
	opacity: 1;
	transform: scale(1) translateY(0);
}

}
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

.m-actions button {
	flex: 1;
	padding: 11px;
	border-radius: 11px;
	font-weight: 600;
	cursor: pointer;
	transition: all .2s;
	font-size: 13.5px;
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

@media ( max-width : 1100px) {
	.form-wrapper {
		grid-template-columns: 1fr;
	}
}

@media ( max-width : 900px) {
	.sidebar {
		transform: translateX(-100%);
	}
	.main {
		margin-left: 0;
		padding: 20px;
	}
	.form-grid-3 {
		grid-template-columns: 1fr 1fr;
	}
}

@media ( max-width : 560px) {
	.form-grid-2, .form-grid-3 {
		grid-template-columns: 1fr;
	}
	.existing-grid, .upload-grid {
		grid-template-columns: repeat(2, 1fr);
	}
	.gps-coords {
		grid-template-columns: 1fr;
	}
}
/* Mode sombre */
body.dark-theme {
    background: #060c1a;
    color: #e0e8ff;
}
body.dark-theme .form-card,
body.dark-theme .modal-box {
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
				     style="width: 50px; height: 50px; object-fit: cover; border-radius: 12px; box-shadow: 0 4px 12px rgba(0,0,0,.35);">
				<div class="logo-text-wrap">
					<span class="logo-name">Fredon</span> <span class="logo-sub"><%= TranslateUtil.t(lang, "real_estate_agency") %></span>
				</div>
			</div>

			<nav class="nav">
				<div class="nav-section"><%= TranslateUtil.t(lang, "principal") %></div>
				<a href="${pageContext.request.contextPath}/admin/dashboard" class="nav-item"> <i class="fas fa-chart-line"></i> <%= TranslateUtil.t(lang, "dashboard") %></a>
				<a href="${pageContext.request.contextPath}/admin/add-property" class="nav-item"> <i class="fas fa-plus-circle"></i> <%= TranslateUtil.t(lang, "add_property") %></a>
				<a href="${pageContext.request.contextPath}/chat" class="nav-item">
					<i class="fas fa-comments"></i> <%= TranslateUtil.t(lang, "messages") %>
					<% if (unreadMessages > 0) { %> <span class="nav-badge"><%= unreadMessages %></span> <% } %>
				</a>
				<div class="nav-section"><%= TranslateUtil.t(lang, "management") %></div>
				<a href="${pageContext.request.contextPath}/admin/clients" class="nav-item"> <i class="fas fa-users"></i> <%= TranslateUtil.t(lang, "clients") %></a>
				<a href="${pageContext.request.contextPath}/admin/statistics" class="nav-item"> <i class="fas fa-chart-pie"></i> <%= TranslateUtil.t(lang, "statistics") %></a>
				<div class="nav-section"><%= TranslateUtil.t(lang, "system") %></div>
				<a href="${pageContext.request.contextPath}/" class="nav-item"> <i class="fas fa-globe"></i> <%= TranslateUtil.t(lang, "view_site") %></a>
				<a href="${pageContext.request.contextPath}/admin/setting" class="nav-item"> <i class="fas fa-cog"></i> <%= TranslateUtil.t(lang, "settings") %></a>
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
					<h1><%= TranslateUtil.t(lang, "edit_property") %> ✏️</h1>
					<p><i class="fas fa-map-marker-alt" style="color: var(--gold); margin-right: 5px;"></i><%= property.getLocation() %> — <strong><%= property.getTitle() %></strong></p>
				</div>
				<div class="top-right">
					<a href="${pageContext.request.contextPath}/admin/dashboard" class="top-btn top-btn-outline"><i class="fas fa-arrow-left"></i> <%= TranslateUtil.t(lang, "back") %></a>
					<a href="${pageContext.request.contextPath}/admin/notifications" class="icon-circle" style="text-decoration: none;"> <i class="fas fa-bell"></i> 
						<% if (notifCount > 0) { %><span class="notif-pip"><%= notifCount > 9 ? "9+" : notifCount %></span><% } %>
					</a>
				</div>
			</div>

			<div class="breadcrumb fade-in-1">
				<a href="${pageContext.request.contextPath}/admin/dashboard"><i class="fas fa-home"></i> <%= TranslateUtil.t(lang, "dashboard") %></a>
				<span class="sep">/</span> <a href="${pageContext.request.contextPath}/admin/dashboard"><%= TranslateUtil.t(lang, "properties_list") %></a>
				<span class="sep">/</span> <span class="current"><%= TranslateUtil.t(lang, "edit") %> : <%= property.getTitle() %></span>
			</div>

			<% if (error != null) { %>
			<div class="alert alert-error fade-in-1">
				<i class="fas fa-exclamation-triangle"></i> <span><%= error %></span>
				<button class="alert-close" onclick="this.parentElement.remove()">×</button>
			</div>
			<% } %>

			<form action="${pageContext.request.contextPath}/admin/edit-property" method="POST" enctype="multipart/form-data" id="editForm">
				<input type="hidden" name="id" value="<%= property.getId() %>">
				<input type="hidden" name="delete_images" id="deleteImages">
				<input type="hidden" name="primary_image_id" id="primaryImageId">

				<div class="form-wrapper fade-in-2">

					<div style="display: flex; flex-direction: column; gap: 20px;">

						<div class="content-card">
							<div class="card-head">
								<div class="card-head-left">
									<div class="ch-icon"><i class="fas fa-file-alt"></i></div>
									<div>
										<div class="ch-title"><%= TranslateUtil.t(lang, "general_info") %></div>
										<div class="ch-sub"><%= TranslateUtil.t(lang, "title_desc_location") %></div>
									</div>
								</div>
							</div>
							<div class="card-body">
								<div class="form-grid-2" style="margin-bottom: 18px;">
									<div class="form-group full-col">
										<label><%= TranslateUtil.t(lang, "property_title") %> <span class="required-star">*</span></label>
										<div class="input-icon-wrap">
											<i class="fas fa-home input-icon"></i> 
											<input type="text" name="title" class="form-control" value="<%= property.getTitle() %>" required placeholder="<%= TranslateUtil.t(lang, "title_placeholder") %>">
										</div>
									</div>
									<div class="form-group">
										<label><%= TranslateUtil.t(lang, "transaction_type") %> <span class="required-star">*</span></label> 
										<select name="type" class="form-control" required id="typeSelect">
											<option value="Vente" <%= "Vente".equals(property.getType()) ? "selected" : "" %>>Vente (Maison/Appartement)</option>
											<option value="Location" <%= "Location".equals(property.getType()) ? "selected" : "" %>>Location (Maison/Appartement)</option>
											<option value="Terrain" <%= "Terrain".equals(property.getType()) ? "selected" : "" %>>Terrain à vendre</option>
										</select>
									</div>
									<div class="form-group">
										<label><%= TranslateUtil.t(lang, "location") %> <span class="required-star">*</span></label>
										<div class="input-icon-wrap">
											<i class="fas fa-map-marker-alt input-icon"></i> 
											<input type="text" name="location" class="form-control" value="<%= property.getLocation() %>" required placeholder="<%= TranslateUtil.t(lang, "address_placeholder") %>">
										</div>
									</div>
									<div class="form-group full-col">
										<label><%= TranslateUtil.t(lang, "description") %> <span class="required-star">*</span></label>
										<textarea name="description" class="form-control" required placeholder="<%= TranslateUtil.t(lang, "description_placeholder") %>"><%= property.getDescription() %></textarea>
									</div>
								</div>
							</div>
						</div>

						<!-- SECTION MAISON / APPARTEMENT -->
						<div id="houseFeatures" class="content-card" style="<%= isLand ? "display: none;" : "" %>">
							<div class="card-head">
								<div class="card-head-left">
									<div class="ch-icon" style="background: linear-gradient(135deg, var(--teal-pale), #c6f7f0); color: var(--teal);"><i class="fas fa-ruler-combined"></i></div>
									<div>
										<div class="ch-title"><%= TranslateUtil.t(lang, "features") %></div>
										<div class="ch-sub"><%= TranslateUtil.t(lang, "surface_rooms_equipment") %></div>
									</div>
								</div>
							</div>
							<div class="card-body">
								<div class="form-grid-3">
									<div class="form-group">
										<label><%= TranslateUtil.t(lang, "price") %> (Ar) <span class="required-star">*</span></label>
										<div class="input-icon-wrap">
											<i class="fas fa-tag input-icon"></i> 
											<input type="text" name="price" class="form-control" value="<%= property.getPrice() %>" required placeholder="0" id="priceInput" onkeypress="return event.charCode >= 48 && event.charCode <= 57">
										</div>
									</div>
									<div class="form-group">
										<label><%= TranslateUtil.t(lang, "surface") %> (m²)</label>
										<div class="input-icon-wrap">
											<i class="fas fa-expand-arrows-alt input-icon"></i> 
											<input type="number" name="surface" class="form-control" value="<%= property.getSurface() != null ? property.getSurface() : "" %>" placeholder="0" id="surfaceInput">
										</div>
									</div>
									<div class="form-group">
										<label><%= TranslateUtil.t(lang, "rooms") %></label>
										<div class="input-icon-wrap">
											<i class="fas fa-th-large input-icon"></i> 
											<input type="number" name="rooms" class="form-control" value="<%= property.getRooms() != null ? property.getRooms() : "" %>" placeholder="0" id="roomsInput">
										</div>
									</div>
									<div class="form-group">
										<label><%= TranslateUtil.t(lang, "bedrooms") %></label>
										<div class="input-icon-wrap">
											<i class="fas fa-bed input-icon"></i> 
											<input type="number" name="bedrooms" class="form-control" value="<%= property.getBedrooms() != null ? property.getBedrooms() : "" %>" placeholder="0">
										</div>
									</div>
									<div class="form-group">
										<label><%= TranslateUtil.t(lang, "bathrooms") %></label>
										<div class="input-icon-wrap">
											<i class="fas fa-bath input-icon"></i> 
											<input type="number" name="bathrooms" class="form-control" value="<%= property.getBathrooms() != null ? property.getBathrooms() : "" %>" placeholder="0">
										</div>
									</div>
								</div>
							</div>
						</div>

						<!-- SECTION TERRAIN -->
						<div id="terrainFeatures" class="content-card" style="<%= isLand ? "" : "display: none;" %>">
							<div class="card-head">
								<div class="card-head-left">
									<div class="ch-icon" style="background: linear-gradient(135deg, var(--teal-pale), #c6f7f0); color: var(--emerald);"><i class="fas fa-map"></i></div>
									<div>
										<div class="ch-title">Caractéristiques du terrain</div>
										<div class="ch-sub">Informations spécifiques au terrain</div>
									</div>
								</div>
							</div>
							<div class="card-body">
								<div class="terrain-section">
									<div class="terrain-info"><i class="fas fa-info-circle"></i> Informations spécifiques au terrain</div>
									<div class="form-grid-3">
										<div class="form-group full-col">
											<label>Prix (Ar) <span class="required-star">*</span></label>
											<div class="input-icon-wrap">
												<i class="fas fa-tag input-icon"></i> 
												<input type="text" name="price" class="form-control" value="<%= property.getPrice() %>" required placeholder="0" id="priceInputTerrain" onkeypress="return event.charCode >= 48 && event.charCode <= 57">
											</div>
										</div>
										<div class="form-group">
											<label>Superficie du terrain</label>
											<div class="input-icon-wrap">
												<i class="fas fa-vector-square input-icon"></i> 
												<input type="text" name="landArea" class="form-control" value="<%= landArea %>" placeholder="Ex: 500 m² ou 5 ares">
											</div>
										</div>
										<div class="form-group">
											<label>Type de terrain</label>
											<select name="landType" class="form-control">
												<option value="">-- Sélectionner --</option>
												<option value="Constructible" <%= "Constructible".equals(landType) ? "selected" : "" %>>🏗️ Constructible</option>
												<option value="Non constructible" <%= "Non constructible".equals(landType) ? "selected" : "" %>>🌿 Non constructible</option>
												<option value="Agricole" <%= "Agricole".equals(landType) ? "selected" : "" %>>🌾 Agricole</option>
												<option value="Commercial" <%= "Commercial".equals(landType) ? "selected" : "" %>>🏢 Commercial</option>
											</select>
										</div>
										<div class="form-group">
											<label>Documentation</label>
											<select name="landDocumentation" class="form-control">
												<option value="">-- Sélectionner --</option>
												<option value="Titre foncier" <%= "Titre foncier".equals(landDocumentation) ? "selected" : "" %>>📜 Titre foncier</option>
												<option value="Certificat de propriété" <%= "Certificat de propriété".equals(landDocumentation) ? "selected" : "" %>>📄 Certificat de propriété</option>
												<option value="En cours" <%= "En cours".equals(landDocumentation) ? "selected" : "" %>>⏳ En cours de régularisation</option>
											</select>
										</div>
										<div class="form-group">
											<label>Accès</label>
											<select name="landAccess" class="form-control">
												<option value="">-- Sélectionner --</option>
												<option value="Route goudronnée" <%= "Route goudronnée".equals(landAccess) ? "selected" : "" %>>🛣️ Route goudronnée</option>
												<option value="Piste" <%= "Piste".equals(landAccess) ? "selected" : "" %>>🚜 Piste accessible</option>
												<option value="Voie d'accès" <%= "Voie d'accès".equals(landAccess) ? "selected" : "" %>>🚶 Voie piétonne</option>
											</select>
										</div>
										<div class="form-group full-col">
											<label>Proximités</label>
											<div class="input-icon-wrap">
												<i class="fas fa-city input-icon"></i>
												<input type="text" name="landProximities" class="form-control" value="<%= landProximities %>" placeholder="Écoles, commerces, transports, hôpitaux...">
											</div>
										</div>
										<div class="form-group full-col">
											<label>Autres informations</label>
											<textarea name="landNotes" class="form-control" rows="3" placeholder="Électricité, eau, égouts, contraintes particulières..."><%= landNotes %></textarea>
										</div>
									</div>
								</div>
							</div>
						</div>

						<div class="content-card">
							<div class="card-head">
								<div class="card-head-left">
									<div class="ch-icon" style="background: linear-gradient(135deg, var(--rose-pale), #ffe0e8); color: var(--rose);"><i class="fas fa-map-marker-alt"></i></div>
									<div>
										<div class="ch-title"><%= TranslateUtil.t(lang, "geolocation") %></div>
										<div class="ch-sub"><%= TranslateUtil.t(lang, "position_property") %></div>
									</div>
								</div>
							</div>
							<div class="card-body">
								<div class="gps-coords">
									<input type="text" id="latitude" name="latitude" value="<%= property.getLatitude() != null ? property.getLatitude() : "" %>" placeholder="<%= TranslateUtil.t(lang, "latitude") %>" readonly>
									<input type="text" id="longitude" name="longitude" value="<%= property.getLongitude() != null ? property.getLongitude() : "" %>" placeholder="<%= TranslateUtil.t(lang, "longitude") %>" readonly>
								</div>

								<div class="location-buttons">
									<button type="button" class="location-btn" onclick="getCurrentLocation()"><i class="fas fa-location-dot"></i> <%= TranslateUtil.t(lang, "use_my_location") %></button>
									<button type="button" class="location-btn location-btn-search" onclick="searchAddress()"><i class="fas fa-search"></i> <%= TranslateUtil.t(lang, "search_address") %></button>
								</div>

								<div class="map-container"><div id="map"></div></div>
								<p class="map-info"><i class="fas fa-info-circle"></i> <%= TranslateUtil.t(lang, "map_instruction") %></p>
							</div>
						</div>

						<div class="content-card">
							<div class="card-head">
								<div class="card-head-left">
									<div class="ch-icon" style="background: linear-gradient(135deg, var(--purple-pale), #ddd6fe); color: var(--purple);"><i class="fas fa-images"></i></div>
									<div>
										<div class="ch-title"><%= TranslateUtil.t(lang, "property_photos") %></div>
										<div class="ch-sub"><%= TranslateUtil.t(lang, "manage_visuals") %></div>
									</div>
								</div>
							</div>
							<div class="card-body">

								<% if (images != null && !images.isEmpty()) { %>
								<div style="margin-bottom: 20px;">
									<p style="font-size: 11px; font-weight: 700; text-transform: uppercase; letter-spacing: .8px; color: var(--soft); margin-bottom: 12px;"><%= TranslateUtil.t(lang, "current_photos") %></p>
									<div class="existing-grid">
										<% for (PropertyImage image : images) { %>
										<div class="img-item" id="imgItem_<%= image.getId() %>">
											<img src="${pageContext.request.contextPath}/<%= image.getImageUrl() %>" alt="<%= TranslateUtil.t(lang, "photo") %> <%= image.getId() %>">
											<% if (image.isPrimary()) { %>
											<div class="img-primary-badge"><i class="fas fa-star"></i> <%= TranslateUtil.t(lang, "primary") %></div>
											<% } %>
											<div class="img-overlay">
												<% if (!image.isPrimary()) { %>
												<button type="button" class="img-action-btn img-star-btn" onclick="setAsPrimary(<%= image.getId() %>)" title="<%= TranslateUtil.t(lang, "set_as_primary") %>"><i class="fas fa-star"></i></button>
												<% } %>
												<button type="button" class="img-action-btn img-del-btn" onclick="toggleDelete(<%= image.getId() %>, this)" title="<%= TranslateUtil.t(lang, "delete") %>"><i class="fas fa-trash"></i></button>
											</div>
										</div>
										<% } %>
									</div>
								</div>
								<% } %>

								<p style="font-size: 11px; font-weight: 700; text-transform: uppercase; letter-spacing: .8px; color: var(--soft); margin-bottom: 12px;"><%= TranslateUtil.t(lang, "add_new_photos") %></p>
								<div class="upload-grid">
									<% for (int i = 1; i <= 3; i++) { %>
									<div class="upload-slot" id="slot<%= i %>" onclick="document.getElementById('newImage<%= i %>').click()">
										<i class="fas fa-cloud-upload-alt"></i>
										<p><%= TranslateUtil.t(lang, "photo") %> <%= i %></p>
										<input type="file" id="newImage<%= i %>" name="newImage<%= i %>" accept="image/*" onchange="previewNewImage(this, 'preview<%= i %>', 'slot<%= i %>')">
										<div class="upload-preview" id="preview<%= i %>" style="display: none;"></div>
										<button type="button" class="upload-clear" id="clear<%= i %>" onclick="clearUpload(event, 'newImage<%= i %>', 'preview<%= i %>', 'slot<%= i %>', 'clear<%= i %>')"><i class="fas fa-times"></i></button>
									</div>
									<% } %>
								</div>

								<div class="info-box" style="margin-top: 16px;">
									<i class="fas fa-info-circle"></i>
									<p><%= TranslateUtil.t(lang, "photos_info") %></p>
								</div>
							</div>
						</div>

					</div>

					<div class="side-stack fade-in-3">

						<div class="preview-card">
							<div class="preview-thumb" id="previewThumb">
								<% String firstImg = null;
								if (images != null && !images.isEmpty()) {
									for (PropertyImage img : images) {
										if (img.isPrimary()) { firstImg = img.getImageUrl(); break; }
									}
									if (firstImg == null) firstImg = images.get(0).getImageUrl();
								}
								%>
								<% if (firstImg != null) { %>
								<img src="${pageContext.request.contextPath}/<%= firstImg %>" id="mainPreviewImg" alt="<%= TranslateUtil.t(lang, "preview") %>">
								<% } else { %>
								<div class="preview-thumb-placeholder"><svg viewBox="0 0 120 90" width="120" xmlns="http://www.w3.org/2000/svg"><defs><linearGradient id="skG" x1="0%" y1="0%" x2="0%" y2="100%"><stop offset="0%" stop-color="#87CEEB" /><stop offset="100%" stop-color="#5BA3C9" /></linearGradient></defs><rect width="120" height="90" fill="url(#skG)" /><circle cx="92" cy="18" r="13" fill="#FFD700" opacity=".85" /><rect x="18" y="50" width="84" height="40" rx="2" fill="#f5e6c8" /><polygon points="10,52 60,22 110,52" fill="#c8860a" /><rect x="46" y="64" width="28" height="26" rx="14" fill="#8B4513" /><rect x="20" y="55" width="18" height="14" rx="2" fill="#87CEEB" stroke="#c8a060" stroke-width="1" /><rect x="82" y="55" width="18" height="14" rx="2" fill="#87CEEB" stroke="#c8a060" stroke-width="1" /><rect x="4" y="68" width="7" height="22" fill="#8B6914" rx="2" /><ellipse cx="7.5" cy="60" rx="11" ry="14" fill="#22c55e" /><rect x="109" y="70" width="7" height="20" fill="#8B6914" rx="2" /><ellipse cx="112" cy="62" rx="9" ry="12" fill="#16a34a" /></svg></div>
								<% } %>
								<span class="preview-badge-type badge-vente" id="previewBadge">● <%= property.getType() %></span>
							</div>
							<div class="preview-info">
								<div class="preview-title" id="previewTitle"><%= property.getTitle() %></div>
								<div class="preview-loc"><i class="fas fa-map-marker-alt" style="color: var(--rose-light); font-size: 10px;"></i> <span id="previewLoc"><%= property.getLocation() %></span></div>
								<div class="preview-price" id="previewPrice"><%= String.format("%,.0f", property.getPrice()) %> Ar</div>
								<div class="preview-meta" id="previewMeta">
									<% if (!isLand) { %>
										<% if (property.getSurface() != null && property.getSurface() > 0) { %>
										<div class="pm-item"><i class="fas fa-expand-arrows-alt"></i> <span id="previewSurface"><%= property.getSurface() %> m²</span></div>
										<% } %>
										<% if (property.getRooms() != null && property.getRooms() > 0) { %>
										<div class="pm-item"><i class="fas fa-th-large"></i> <span id="previewRooms"><%= property.getRooms() %> pièces</span></div>
										<% } %>
										<% if (property.getBedrooms() != null && property.getBedrooms() > 0) { %>
										<div class="pm-item"><i class="fas fa-bed"></i> <span><%= property.getBedrooms() %> ch.</span></div>
										<% } %>
									<% } else { %>
										<% if (landArea != null && !landArea.isEmpty()) { %>
										<div class="pm-item"><i class="fas fa-vector-square"></i> <span><%= landArea %></span></div>
										<% } %>
										<% if (landType != null && !landType.isEmpty()) { %>
										<div class="pm-item"><i class="fas fa-tree"></i> <span><%= landType %></span></div>
										<% } %>
									<% } %>
								</div>
							</div>
						</div>

						<div class="action-card">
							<h4><i class="fas fa-save"></i> <%= TranslateUtil.t(lang, "save_changes") %></h4>
							<button type="submit" class="btn-submit" form="editForm"><i class="fas fa-check-circle"></i> <%= TranslateUtil.t(lang, "update_property") %></button>
							<a href="${pageContext.request.contextPath}/admin/dashboard" class="btn-cancel"><i class="fas fa-times"></i> <%= TranslateUtil.t(lang, "cancel") %></a>
						</div>

						<div class="action-card" style="background: var(--bg2);">
							<h4 style="color: var(--mid);"><i class="fas fa-info-circle" style="color: var(--blue-light);"></i> <%= TranslateUtil.t(lang, "information") %></h4>
							<div style="font-size: 12px; color: var(--soft); line-height: 1.7;">
								<p><i class="fas fa-calendar-alt" style="width: 14px; color: var(--gold);"></i> <%= TranslateUtil.t(lang, "added_on") %> : <strong style="color: var(--mid);"><% java.text.SimpleDateFormat sdf = new java.text.SimpleDateFormat("dd/MM/yyyy"); if (property.getCreatedAt() != null) out.print(sdf.format(property.getCreatedAt())); else out.print("—"); %></strong></p>
								<p style="margin-top: 6px;"><i class="fas fa-hashtag" style="width: 14px; color: var(--gold);"></i> <%= TranslateUtil.t(lang, "reference") %> : <strong style="color: var(--mid);">#FRED-<%= property.getId() %></strong></p>
								<p style="margin-top: 6px;"><i class="fas fa-eye" style="width: 14px; color: var(--gold);"></i> <%= TranslateUtil.t(lang, "status") %> : <strong style="color: var(--teal);"><%= TranslateUtil.t(lang, "online") %></strong></p>
							</div>
						</div>

					</div>
				</div>
			</form>

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
				<button class="btn-submit" style="width: auto; padding: 6px 14px; font-size: 11.5px; margin-bottom: 0;" onclick="document.getElementById('avatarInput').click()"><i class="fas fa-camera"></i> <%= TranslateUtil.t(lang, "change_photo") %></button>
				<input type="file" id="avatarInput" style="display: none;" accept="image/*">
			</div>
			<div class="m-field">
				<label><%= TranslateUtil.t(lang, "username") %></label> <input type="text" value="<%= adminName %>" readonly style="background: var(--bg);">
			</div>
			<div class="m-field">
				<label><%= TranslateUtil.t(lang, "email") %></label> <input type="email" placeholder="admin@fredon.com" value="admin@fredon.com">
			</div>
			<div class="m-field">
				<label><%= TranslateUtil.t(lang, "new_password") %></label> <input type="password" placeholder="<%= TranslateUtil.t(lang, "leave_empty") %>">
			</div>
			<div class="m-actions">
				<button class="m-save" onclick="alert('<%= TranslateUtil.t(lang, "profile_updated") %>'); closeModal()"><i class="fas fa-save"></i> <%= TranslateUtil.t(lang, "save") %></button>
				<button class="m-cancel" onclick="closeModal()"><%= TranslateUtil.t(lang, "cancel") %></button>
			</div>
		</div>
	</div>

	<script src="https://unpkg.com/leaflet@1.9.4/dist/leaflet.js"></script>

	<script>
(function() {
    const canvas = document.getElementById('bgCanvas');
    const ctx = canvas.getContext('2d');
    let W, H, houses = [];
    function resize() { W = canvas.width = window.innerWidth; H = canvas.height = window.innerHeight; }
    resize(); window.addEventListener('resize', resize);
    function drawHouse(ctx, x, y, s, alpha, color) {
        ctx.save(); ctx.globalAlpha = alpha; ctx.strokeStyle = color; ctx.fillStyle = color;
        ctx.lineWidth = 1.4 * s; ctx.translate(x, y);
        ctx.beginPath(); ctx.rect(-14*s,-8*s,28*s,20*s); ctx.stroke();
        ctx.beginPath(); ctx.moveTo(-17*s,-8*s); ctx.lineTo(0,-22*s); ctx.lineTo(17*s,-8*s); ctx.closePath(); ctx.stroke();
        ctx.beginPath(); ctx.arc(0,7*s,5*s,Math.PI,0); ctx.rect(-5*s,2*s,10*s,5*s); ctx.stroke();
        ctx.strokeRect(-12*s,-5*s,7*s,6*s); ctx.strokeRect(5*s,-5*s,7*s,6*s);
        ctx.fillRect(5*s,-24*s,4*s,8*s); ctx.restore();
    }
    const COLORS = ['#1f52d4','#c8860a','#0e9e8a','#e03060','#7c3aed','#0e7490','#b45309','#166534'];
    function init() {
        houses = [];
        for (let i = 0; i < 18; i++) {
            houses.push({ x: Math.random()*W, y: Math.random()*H,
                s: 0.5+Math.random()*1.4, alpha: 0.04+Math.random()*0.06,
                color: COLORS[Math.floor(Math.random()*COLORS.length)],
                vx: (Math.random()-.5)*.12, vy: (Math.random()-.5)*.10 });
        }
    }
    init();
    function animate() {
        ctx.clearRect(0,0,W,H);
        houses.forEach(h => {
            h.x += h.vx; h.y += h.vy;
            if (h.x < -100) h.x = W+60; if (h.x > W+100) h.x = -60;
            if (h.y < -100) h.y = H+60; if (h.y > H+100) h.y = -60;
            drawHouse(ctx, h.x, h.y, h.s, h.alpha, h.color);
        });
        requestAnimationFrame(animate);
    }
    animate();
})();

var map;
var marker;

var defaultLat = <%= property.getLatitude() != null ? property.getLatitude() : -18.8792 %>;
var defaultLng = <%= property.getLongitude() != null ? property.getLongitude() : 47.5079 %>;

function initMap(lat, lng) {
    if (map) { map.remove(); }
    
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
            var lat = position.coords.latitude;
            var lng = position.coords.longitude;
            initMap(lat, lng);
            marker.setLatLng([lat, lng]);
            document.getElementById('latitude').value = lat.toFixed(6);
            document.getElementById('longitude').value = lng.toFixed(6);
        }, function() {
            alert("<%= TranslateUtil.t(lang, "location_error") %>");
            initMap(defaultLat, defaultLng);
        });
    } else {
        alert("<%= TranslateUtil.t(lang, "geolocation_not_supported") %>");
        initMap(defaultLat, defaultLng);
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
    initMap(defaultLat, defaultLng);
    togglePropertyType();
});

let imagesToDelete = [];

function toggleDelete(imageId, btn) {
    const item = document.getElementById('imgItem_' + imageId);
    if (imagesToDelete.includes(imageId)) {
        imagesToDelete = imagesToDelete.filter(id => id !== imageId);
        item.classList.remove('marked-delete');
        btn.innerHTML = '<i class="fas fa-trash"></i>';
        btn.classList.remove('img-restore-btn');
        btn.classList.add('img-del-btn');
    } else {
        imagesToDelete.push(imageId);
        item.classList.add('marked-delete');
        btn.innerHTML = '<i class="fas fa-undo"></i>';
        btn.classList.remove('img-del-btn');
        btn.classList.add('img-restore-btn');
    }
    document.getElementById('deleteImages').value = imagesToDelete.join(',');
}

function setAsPrimary(imageId) {
    document.getElementById('primaryImageId').value = imageId;
    document.querySelectorAll('.img-primary-badge').forEach(b => b.remove());
    const item = document.getElementById('imgItem_' + imageId);
    const badge = document.createElement('div');
    badge.className = 'img-primary-badge';
    badge.innerHTML = '<i class="fas fa-star"></i> <%= TranslateUtil.t(lang, "primary") %>';
    item.insertBefore(badge, item.firstChild);
    item.querySelectorAll('.img-star-btn').forEach(b => b.style.display = 'none');
    const imgSrc = item.querySelector('img').src;
    document.getElementById('mainPreviewImg').src = imgSrc;
}

function previewNewImage(input, previewId, slotId) {
    if (input.files && input.files[0]) {
        const reader = new FileReader();
        reader.onload = function(e) {
            const prev = document.getElementById(previewId);
            prev.innerHTML = '<img src="' + e.target.result + '">';
            prev.style.display = 'block';
            document.getElementById(slotId).querySelector('i').style.display = 'none';
            document.getElementById(slotId).querySelector('p').style.display = 'none';
        };
        reader.readAsDataURL(input.files[0]);
    }
}

function clearUpload(evt, inputId, previewId, slotId, clearId) {
    evt.stopPropagation();
    document.getElementById(inputId).value = '';
    const prev = document.getElementById(previewId);
    prev.innerHTML = ''; prev.style.display = 'none';
    const slot = document.getElementById(slotId);
    slot.querySelector('i').style.display = 'block';
    slot.querySelector('p').style.display = 'block';
}

function fmtPrice(v) {
    if (!v) return '—';
    return Number(v).toLocaleString('fr-FR') + ' Ar';
}

function togglePropertyType() {
    var typeSelect = document.getElementById('typeSelect');
    var houseSection = document.getElementById('houseFeatures');
    var terrainSection = document.getElementById('terrainFeatures');
    var selectedType = typeSelect.value;
    
    if (selectedType === 'Terrain') {
        houseSection.style.display = 'none';
        terrainSection.style.display = 'block';
        document.getElementById('previewBadge').className = 'preview-badge-type badge-terrain';
        document.getElementById('previewBadge').innerHTML = '● Terrain';
    } else {
        houseSection.style.display = 'block';
        terrainSection.style.display = 'none';
        var badgeClass = selectedType === 'Vente' ? 'badge-vente' : 'badge-location';
        document.getElementById('previewBadge').className = 'preview-badge-type ' + badgeClass;
        document.getElementById('previewBadge').innerHTML = '● ' + selectedType;
    }
}

document.getElementById('typeSelect').addEventListener('change', togglePropertyType);

// Live preview
(function initLivePreview() {
    const titleInput   = document.querySelector('input[name="title"]');
    const locInput     = document.querySelector('input[name="location"]');
    const typeSelect   = document.getElementById('typeSelect');
    const priceInput   = document.getElementById('priceInput');
    const priceInputTerrain = document.getElementById('priceInputTerrain');
    const surfaceInput = document.getElementById('surfaceInput');
    const roomsInput   = document.getElementById('roomsInput');
    const landAreaInput = document.querySelector('input[name="landArea"]');
    const landTypeInput = document.querySelector('select[name="landType"]');

    function update() {
        if (titleInput)   document.getElementById('previewTitle').textContent = titleInput.value || '—';
        if (locInput)     document.getElementById('previewLoc').textContent   = ' ' + (locInput.value || '—');
        
        if (typeSelect && typeSelect.value === 'Terrain' && priceInputTerrain) {
            document.getElementById('previewPrice').textContent = fmtPrice(priceInputTerrain.value);
        } else if (priceInput) {
            document.getElementById('previewPrice').textContent = fmtPrice(priceInput.value);
        }
        
        const metaDiv = document.getElementById('previewMeta');
        if (typeSelect && typeSelect.value === 'Terrain') {
            var landArea = landAreaInput ? landAreaInput.value : '';
            var landType = landTypeInput ? landTypeInput.options[landTypeInput.selectedIndex]?.text : '';
            metaDiv.innerHTML = '';
            if (landArea) metaDiv.innerHTML += '<div class="pm-item"><i class="fas fa-vector-square"></i> <span>' + landArea + '</span></div>';
            if (landType) metaDiv.innerHTML += '<div class="pm-item"><i class="fas fa-tree"></i> <span>' + landType + '</span></div>';
            if (!landArea && !landType) metaDiv.innerHTML = '<div class="pm-item"><span>—</span></div>';
        } else {
            const surface = surfaceInput ? surfaceInput.value : '0';
            const rooms   = roomsInput ? roomsInput.value : '0';
            metaDiv.innerHTML = '';
            if (surface > 0) metaDiv.innerHTML += '<div class="pm-item"><i class="fas fa-expand-arrows-alt"></i> <span>' + surface + ' m²</span></div>';
            if (rooms > 0)   metaDiv.innerHTML += '<div class="pm-item"><i class="fas fa-th-large"></i> <span>' + rooms + ' pièces</span></div>';
            if (surface <= 0 && rooms <= 0) metaDiv.innerHTML = '<div class="pm-item"><span>—</span></div>';
        }
    }
    
    if (titleInput)   titleInput.addEventListener('input', update);
    if (locInput)     locInput.addEventListener('input', update);
    if (typeSelect)   typeSelect.addEventListener('change', update);
    if (priceInput)   priceInput.addEventListener('input', update);
    if (priceInputTerrain) priceInputTerrain.addEventListener('input', update);
    if (surfaceInput) surfaceInput.addEventListener('input', update);
    if (roomsInput)   roomsInput.addEventListener('input', update);
    if (landAreaInput) landAreaInput.addEventListener('input', update);
    if (landTypeInput) landTypeInput.addEventListener('change', update);
})();

function openModal()  { document.getElementById('profileModal').classList.add('open'); }
function closeModal() { document.getElementById('profileModal').classList.remove('open'); }
document.getElementById('profileModal').addEventListener('click', function(e) {
    if (e.target === this) closeModal();
});

//Empêche l'accès aux pages après déconnexion
if (performance.navigation.type === 2) {
 window.location.href = '${pageContext.request.contextPath}/login';
}

</script>
</body>
</html>