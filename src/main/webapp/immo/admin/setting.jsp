<%@ page language="java" contentType="text/html; charset=UTF-8"
	pageEncoding="UTF-8"%>
<%@ page import="java.util.*, java.text.*, java.sql.*"%>
<%@ page import="com.quickchat.model.User"%>
<%@ page import="com.quickchat.utils.TranslateUtil"%>
<%

response.setHeader("Cache-Control", "no-cache, no-store, must-revalidate");
response.setHeader("Pragma", "no-cache");
response.setHeader("Expires", "0");

// SESSION AUTOMATIQUE - Si aucun adminId en session, on le crée automatiquement
Integer adminId = (Integer) session.getAttribute("adminId");
if (adminId == null) {
    try {
        Class.forName("com.mysql.cj.jdbc.Driver");
        Connection connAuto = DriverManager.getConnection("jdbc:mysql://localhost:3306/quickchat", "root", "");
        PreparedStatement pstmtAuto = connAuto.prepareStatement("SELECT id, username FROM users WHERE role = 'admin' LIMIT 1");
        ResultSet rsAuto = pstmtAuto.executeQuery();
        if (rsAuto.next()) {
            adminId = rsAuto.getInt("id");
            session.setAttribute("adminId", adminId);
            session.setAttribute("adminUsername", rsAuto.getString("username"));
        }
        rsAuto.close();
        pstmtAuto.close();
        connAuto.close();
    } catch(Exception e) {
        e.printStackTrace();
    }
}

    String lang = "fr";
    try {
        Class.forName("com.mysql.cj.jdbc.Driver");
        Connection conn0 = DriverManager.getConnection("jdbc:mysql://localhost:3306/quickchat", "root", "");
        PreparedStatement ps0 = conn0.prepareStatement("SELECT default_language FROM settings WHERE id = 1");
        ResultSet rs0 = ps0.executeQuery();
        if (rs0.next()) lang = rs0.getString("default_language");
        rs0.close(); ps0.close(); conn0.close();
    } catch(Exception e) {}

    User admin = (User) session.getAttribute("admin");

    String DB_URL = "jdbc:mysql://localhost:3306/quickchat";
    String DB_USER = "root";
    String DB_PASSWORD = "";

    String siteName = "Fredon Immobilier";
    String siteSlogan = "Votre partenaire de confiance à Madagascar";
    String siteEmail = "contact@fredon.mg";
    String sitePhone = "+261 34 00 000 00";
    String siteAddress = "Antananarivo, Madagascar";
    String siteHours = "Lundi - Vendredi : 9h00 - 18h00";
    String defaultTheme = "light";
    String defaultLanguage = "fr";
    String currency = "Ar";
    boolean emailNotifications = true;
    boolean messageNotifications = true;
    boolean clientNotifications = true;
    boolean commentNotifications = true;
    boolean propertyNotifications = true;
    boolean soundNotifications = false;

    String adminFullName = "";
    String adminEmailAddr = "";
    String adminPhone = "";
    String adminAddress = "";
    String adminProfilePic = "";

    try {
        Class.forName("com.mysql.cj.jdbc.Driver");
        Connection conn = DriverManager.getConnection(DB_URL, DB_USER, DB_PASSWORD);
        
        try {
            Statement stmtCheck = conn.createStatement();
            stmtCheck.execute("CREATE TABLE IF NOT EXISTS settings (" +
                "id INT PRIMARY KEY DEFAULT 1," +
                "site_name VARCHAR(255) DEFAULT 'Fredon Immobilier'," +
                "site_slogan VARCHAR(255) DEFAULT 'Votre partenaire de confiance à Madagascar'," +
                "site_email VARCHAR(255) DEFAULT 'contact@fredon.mg'," +
                "site_phone VARCHAR(50) DEFAULT '+261 34 00 000 00'," +
                "site_address VARCHAR(255) DEFAULT 'Antananarivo, Madagascar'," +
                "site_hours VARCHAR(255) DEFAULT 'Lundi - Vendredi : 9h00 - 18h00'," +
                "default_theme VARCHAR(50) DEFAULT 'light'," +
                "default_language VARCHAR(10) DEFAULT 'fr'," +
                "currency VARCHAR(10) DEFAULT 'Ar'," +
                "email_notifications BOOLEAN DEFAULT TRUE," +
                "message_notifications BOOLEAN DEFAULT TRUE," +
                "client_notifications BOOLEAN DEFAULT TRUE," +
                "comment_notifications BOOLEAN DEFAULT TRUE," +
                "property_notifications BOOLEAN DEFAULT TRUE," +
                "sound_notifications BOOLEAN DEFAULT FALSE)");
            stmtCheck.close();
        } catch(Exception e) { System.out.println("Table settings déjà existante"); }
        
        PreparedStatement pstmt = conn.prepareStatement("SELECT * FROM settings WHERE id = 1");
        ResultSet rs = pstmt.executeQuery();
        if (rs.next()) {
            if (rs.getString("site_name") != null) siteName = rs.getString("site_name");
            if (rs.getString("site_slogan") != null) siteSlogan = rs.getString("site_slogan");
            if (rs.getString("site_email") != null) siteEmail = rs.getString("site_email");
            if (rs.getString("site_phone") != null) sitePhone = rs.getString("site_phone");
            if (rs.getString("site_address") != null) siteAddress = rs.getString("site_address");
            if (rs.getString("site_hours") != null) siteHours = rs.getString("site_hours");
            if (rs.getString("default_theme") != null) defaultTheme = rs.getString("default_theme");
            if (rs.getString("default_language") != null) defaultLanguage = rs.getString("default_language");
            if (rs.getString("currency") != null) currency = rs.getString("currency");
            emailNotifications = rs.getBoolean("email_notifications");
            messageNotifications = rs.getBoolean("message_notifications");
            clientNotifications = rs.getBoolean("client_notifications");
            commentNotifications = rs.getBoolean("comment_notifications");
            propertyNotifications = rs.getBoolean("property_notifications");
            soundNotifications = rs.getBoolean("sound_notifications");
        } else {
            PreparedStatement insertStmt = conn.prepareStatement("INSERT INTO settings (id) VALUES (1)");
            insertStmt.execute();
            insertStmt.close();
        }
        rs.close(); pstmt.close();
        
        pstmt = conn.prepareStatement("SELECT full_name, email, phone, address, profile_pic FROM users WHERE id = ?");
        pstmt.setInt(1, adminId);
        rs = pstmt.executeQuery();
        if (rs.next()) {
            adminFullName  = rs.getString("full_name")  != null ? rs.getString("full_name")  : "";
            adminEmailAddr = rs.getString("email")      != null ? rs.getString("email")      : "";
            adminPhone     = rs.getString("phone")      != null ? rs.getString("phone")      : "";
            adminAddress   = rs.getString("address")    != null ? rs.getString("address")    : "";
            adminProfilePic= rs.getString("profile_pic")!= null ? rs.getString("profile_pic"): "";
        }
        rs.close(); pstmt.close(); conn.close();
    } catch (Exception e) { e.printStackTrace(); }

    String adminName    = adminFullName;
    String adminInitial = adminFullName.length() > 0 ? adminFullName.substring(0,1).toUpperCase() : "A";
    String adminEmailFinal = adminEmailAddr;
    String success = request.getParameter("success");
    String error   = request.getParameter("error");
    int unreadMessages = 0;
%>
<%
// ========== SESSIONS ACTIVES (connexions des dernières 30 minutes) ==========
List<Map<String, String>> activeSessions = new ArrayList<>();
List<Map<String, String>> loginHistory = new ArrayList<>();

try {
    Class.forName("com.mysql.cj.jdbc.Driver");
    Connection conn = DriverManager.getConnection(DB_URL, DB_USER, DB_PASSWORD);
    
    PreparedStatement pstmtSessions = conn.prepareStatement(
        "SELECT id, ip_address, browser, os, device, location, login_time " +
        "FROM login_history WHERE user_id = ? AND login_status = 'success' " +
        "AND login_time > DATE_SUB(NOW(), INTERVAL 30 MINUTE) " +
        "ORDER BY login_time DESC"
    );
    pstmtSessions.setInt(1, adminId);
    ResultSet rsSessions = pstmtSessions.executeQuery();
    
    while (rsSessions.next()) {
        Map<String, String> sessionItem = new HashMap<>();
        sessionItem.put("browser", rsSessions.getString("browser") != null ? rsSessions.getString("browser") : "Inconnu");
        sessionItem.put("os", rsSessions.getString("os") != null ? rsSessions.getString("os") : "Inconnu");
        sessionItem.put("device", rsSessions.getString("device") != null ? rsSessions.getString("device") : "Inconnu");
        sessionItem.put("location", rsSessions.getString("location") != null ? rsSessions.getString("location") : "Inconnue");
        sessionItem.put("login_time", rsSessions.getString("login_time"));
        activeSessions.add(sessionItem);
    }
    rsSessions.close();
    pstmtSessions.close();
    
    PreparedStatement pstmtHistory = conn.prepareStatement(
        "SELECT id, browser, os, device, location, login_time, login_status " +
        "FROM login_history WHERE user_id = ? " +
        "ORDER BY login_time DESC LIMIT 10"
    );
    pstmtHistory.setInt(1, adminId);
    ResultSet rsHistory = pstmtHistory.executeQuery();
    
    while (rsHistory.next()) {
        Map<String, String> log = new HashMap<>();
        log.put("browser", rsHistory.getString("browser") != null ? rsHistory.getString("browser") : "Inconnu");
        log.put("os", rsHistory.getString("os") != null ? rsHistory.getString("os") : "Inconnu");
        log.put("device", rsHistory.getString("device") != null ? rsHistory.getString("device") : "Inconnu");
        log.put("location", rsHistory.getString("location") != null ? rsHistory.getString("location") : "Inconnue");
        log.put("login_time", rsHistory.getString("login_time"));
        log.put("login_status", rsHistory.getString("login_status"));
        loginHistory.add(log);
    }
    rsHistory.close();
    pstmtHistory.close();
    conn.close();
} catch (Exception e) {
    e.printStackTrace();
}
%>
<%-- TEST POUR VOIR SI LA SERVLET EXISTE --%>
<%
    String testUrl = request.getContextPath() + "/immo/admin/update-password";
    out.println("<!-- URL du formulaire: " + testUrl + " -->");
%>
<!DOCTYPE html>
<html lang="<%= lang %>">
<head>
<%@ include file="includes/theme.jsp" %>
<%@ include file="includes/color.jsp" %>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title><%= TranslateUtil.t(lang, "settings") %> — Fredon Immobilier</title>
<link
    href="https://fonts.googleapis.com/css2?family=Syne:wght@400;600;700;800&family=DM+Sans:ital,opsz,wght@0,9..40,300;0,9..40,400;0,9..40,500;0,9..40,600;0,9..40,700&display=swap"
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
    --purple-light: #a78bfa;
    --purple-pale: #f0ebff;
    --green: #10b981;
    --red: #ef4444;
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

body.dark-theme {
    --bg: #060c1a;
    --bg2: #0d1626;
    --white: #0d1626;
    --dark: #e0e8ff;
    --mid: #6070a0;
    --soft: #2a3555;
    --border: rgba(255,255,255,.05);
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
    overflow: hidden;
}

.u-avatar img {
    width: 100%;
    height: 100%;
    object-fit: cover;
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
}

.icon-circle:hover {
    border-color: var(--gold);
    color: var(--gold);
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

@keyframes slideIn {
    from { opacity:0; transform: translateY(-8px); }
    to { opacity:1; transform: translateY(0); }
}

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

.settings-layout {
    display: flex;
    gap: 24px;
    align-items: flex-start;
}

.tabs-nav {
    width: 230px;
    flex-shrink: 0;
    background: var(--white);
    border-radius: var(--r-xl);
    border: 1.5px solid rgba(200, 134, 10, .1);
    overflow: hidden;
    box-shadow: 0 2px 16px rgba(0, 0, 0, .05);
    position: sticky;
    top: 24px;
}

.tabs-nav-head {
    padding: 18px 18px 14px;
    border-bottom: 1.5px solid rgba(200, 134, 10, .08);
    background: linear-gradient(135deg, rgba(31, 82, 212, .06), rgba(200, 134, 10, .04));
}

.tabs-nav-head span {
    font-family: 'Syne', sans-serif;
    font-size: 11px;
    font-weight: 700;
    text-transform: uppercase;
    letter-spacing: 1.5px;
    color: var(--soft);
}

.tab-btn {
    display: flex;
    align-items: center;
    gap: 11px;
    width: 100%;
    padding: 13px 18px;
    background: transparent;
    border: none;
    cursor: pointer;
    font-family: 'DM Sans', sans-serif;
    font-size: 13.5px;
    font-weight: 500;
    color: var(--mid);
    text-align: left;
    transition: all .2s;
    border-left: 3px solid transparent;
}

.tab-btn .tb-ico {
    width: 32px;
    height: 32px;
    border-radius: 9px;
    flex-shrink: 0;
    display: flex;
    align-items: center;
    justify-content: center;
    font-size: 13px;
    transition: all .2s;
}

.tab-btn:hover {
    background: rgba(200, 134, 10, .05);
    color: var(--dark);
}

.tab-btn.active {
    background: rgba(79, 126, 248, .07);
    color: var(--blue);
    border-left-color: var(--blue-light);
    font-weight: 600;
}

.tab-btn.active .tb-ico {
    background: var(--blue-pale) !important;
    color: var(--blue) !important;
}

.tab-btn .tb-arrow {
    margin-left: auto;
    font-size: 10px;
    opacity: .4;
    transition: opacity .2s;
}

.tab-btn.active .tb-arrow {
    opacity: 1;
    color: var(--blue-light);
}

.tabs-content {
    flex: 1;
    min-width: 0;
}

.tab-panel {
    display: none;
}

.tab-panel.active {
    display: block;
}

.s-card {
    background: var(--white);
    border-radius: var(--r-xl);
    border: 1.5px solid rgba(200, 134, 10, .1);
    overflow: hidden;
    margin-bottom: 20px;
    box-shadow: 0 2px 16px rgba(0, 0, 0, .04);
}

.s-card-head {
    padding: 18px 24px;
    border-bottom: 1.5px solid rgba(200, 134, 10, .08);
    display: flex;
    align-items: center;
    gap: 13px;
}

.sch-ico {
    width: 42px;
    height: 42px;
    border-radius: 12px;
    display: flex;
    align-items: center;
    justify-content: center;
    font-size: 18px;
    flex-shrink: 0;
}

.sch-title {
    font-family: 'Syne', sans-serif;
    font-size: 16px;
    font-weight: 700;
    color: var(--dark);
}

.sch-sub {
    font-size: 11.5px;
    color: var(--soft);
    margin-top: 2px;
}

.s-card-body {
    padding: 24px;
}

.f-grid {
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
    font-size: 11px;
    font-weight: 700;
    color: var(--mid);
    text-transform: uppercase;
    letter-spacing: .7px;
}

.field-icon {
    position: relative;
}

.field-icon input, .field-icon select {
    padding-left: 40px;
}

.field-icon .fi {
    position: absolute;
    left: 13px;
    top: 50%;
    transform: translateY(-50%);
    color: #c8ad82;
    font-size: 13px;
    pointer-events: none;
}

.f-input, .f-select, .f-textarea {
    padding: 12px 14px;
    border: 1.5px solid rgba(200, 134, 10, .15);
    border-radius: 13px;
    font-family: 'DM Sans', sans-serif;
    font-size: 14px;
    color: var(--dark);
    background: var(--bg2);
    transition: all .22s;
    outline: none;
    width: 100%;
}

.f-input:focus, .f-select:focus, .f-textarea:focus {
    border-color: var(--blue-light);
    background: var(--white);
    box-shadow: 0 0 0 4px rgba(79, 126, 248, .1);
}

.f-select {
    cursor: pointer;
    appearance: none;
    background-image: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='16' height='16' viewBox='0 0 24 24' fill='none' stroke='%23a89880' stroke-width='2'%3E%3Cpolyline points='6 9 12 15 18 9'/%3E%3C/svg%3E");
    background-repeat: no-repeat;
    background-position: right 12px center;
    padding-right: 36px;
}

.f-textarea {
    min-height: 100px;
    resize: vertical;
}

.f-divider {
    height: 1.5px;
    background: linear-gradient(90deg, transparent, rgba(200, 134, 10, .1), transparent);
    margin: 20px 0;
}

.avatar-zone {
    display: flex;
    align-items: center;
    gap: 22px;
    padding: 20px;
    background: var(--bg2);
    border-radius: 16px;
    border: 1.5px solid rgba(200, 134, 10, .1);
    margin-bottom: 24px;
}

.av-big {
    width: 88px;
    height: 88px;
    border-radius: 22px;
    flex-shrink: 0;
    background: linear-gradient(135deg, var(--gold), var(--gold-light));
    display: flex;
    align-items: center;
    justify-content: center;
    font-family: 'Syne', sans-serif;
    font-size: 34px;
    font-weight: 800;
    color: #fff;
    box-shadow: 0 8px 24px rgba(200, 134, 10, .35);
    overflow: hidden;
}

.av-big img {
    width: 100%;
    height: 100%;
    object-fit: cover;
}

.av-info h4 {
    font-family: 'Syne', sans-serif;
    font-size: 15px;
    font-weight: 700;
    margin-bottom: 4px;
}

.av-info p {
    font-size: 12px;
    color: var(--soft);
    margin-bottom: 12px;
}

.av-btns {
    display: flex;
    gap: 8px;
    flex-wrap: wrap;
}

.toggle-row {
    display: flex;
    align-items: center;
    justify-content: space-between;
    padding: 14px 0;
    border-bottom: 1px solid rgba(200, 134, 10, .06);
}

.toggle-row:last-child {
    border-bottom: none;
    padding-bottom: 0;
}

.tr-info {
    display: flex;
    align-items: center;
    gap: 12px;
    flex: 1;
}

.tr-ico {
    width: 36px;
    height: 36px;
    border-radius: 10px;
    display: flex;
    align-items: center;
    justify-content: center;
    font-size: 14px;
    flex-shrink: 0;
}

.tr-text h4 {
    font-size: 13.5px;
    font-weight: 600;
    color: var(--dark);
    margin-bottom: 2px;
}

.tr-text p {
    font-size: 11.5px;
    color: var(--soft);
}

.toggle-sw {
    width: 48px;
    height: 26px;
    border-radius: 30px;
    background: rgba(168, 152, 128, .2);
    position: relative;
    cursor: pointer;
    transition: all .3s;
    flex-shrink: 0;
}

.toggle-sw.on {
    background: linear-gradient(115deg, var(--teal), var(--teal-light));
}

.toggle-sw .knob {
    position: absolute;
    top: 3px;
    left: 3px;
    width: 20px;
    height: 20px;
    background: white;
    border-radius: 50%;
    transition: all .3s;
    box-shadow: 0 2px 6px rgba(0, 0, 0, .15);
}

.toggle-sw.on .knob {
    left: 25px;
}

.theme-cards {
    display: flex;
    gap: 14px;
    flex-wrap: wrap;
}

.theme-card {
    flex: 1;
    min-width: 100px;
    border-radius: 14px;
    overflow: hidden;
    border: 2px solid rgba(200, 134, 10, .12);
    cursor: pointer;
    transition: all .25s;
}

.theme-card:hover {
    transform: translateY(-3px);
    box-shadow: 0 8px 20px rgba(0, 0, 0, .1);
}

.theme-card.picked {
    border-color: var(--blue-light);
    box-shadow: 0 0 0 4px rgba(79, 126, 248, .12);
}

.theme-preview {
    height: 70px;
    position: relative;
}

.theme-label {
    padding: 8px 12px;
    font-size: 12px;
    font-weight: 700;
    text-align: center;
    background: var(--bg2);
    color: var(--mid);
}

.theme-card.picked .theme-label {
    color: var(--blue);
    background: var(--blue-pale);
}

.tc-light .theme-preview {
    background: linear-gradient(135deg, #fdf9f3 0%, #f8f4ee 100%);
}

.tc-dark .theme-preview {
    background: linear-gradient(135deg, #0d0b08 0%, #1c1408 100%);
}

.theme-preview-dots {
    position: absolute;
    top: 50%;
    left: 50%;
    transform: translate(-50%, -50%);
    display: flex;
    gap: 6px;
}

.theme-preview-dots span {
    width: 8px;
    height: 8px;
    border-radius: 50%;
}

.locale-card {
    padding: 16px;
    background: var(--bg2);
    border-radius: 14px;
    border: 1.5px solid rgba(200, 134, 10, .1);
    transition: all .22s;
    cursor: pointer;
}

.locale-card:hover {
    border-color: var(--gold);
    transform: translateY(-2px);
}

.form-foot {
    display: flex;
    gap: 10px;
    justify-content: flex-end;
    margin-top: 6px;
}

.btn-save {
    display: inline-flex;
    align-items: center;
    gap: 8px;
    padding: 12px 24px;
    border-radius: 13px;
    border: none;
    cursor: pointer;
    font-family: 'Syne', sans-serif;
    font-weight: 700;
    font-size: 14px;
    background: linear-gradient(115deg, var(--gold), var(--gold-light));
    color: white;
    transition: all .25s;
    box-shadow: 0 5px 16px rgba(200, 134, 10, .28);
}

.btn-save:hover {
    transform: translateY(-2px);
    box-shadow: 0 8px 22px rgba(200, 134, 10, .38);
}

.btn-cancel {
    display: inline-flex;
    align-items: center;
    gap: 8px;
    padding: 12px 20px;
    border-radius: 13px;
    cursor: pointer;
    font-family: 'DM Sans', sans-serif;
    font-weight: 600;
    font-size: 13.5px;
    background: var(--white);
    border: 1.5px solid rgba(200, 134, 10, .18);
    color: var(--mid);
    transition: all .22s;
}

.btn-outline-blue {
    display: inline-flex;
    align-items: center;
    gap: 8px;
    padding: 10px 16px;
    border-radius: 12px;
    cursor: pointer;
    font-family: 'DM Sans', sans-serif;
    font-weight: 600;
    font-size: 12px;
    background: var(--white);
    border: 1.5px solid rgba(31, 82, 212, .25);
    color: var(--blue);
    transition: all .22s;
}

.btn-outline-blue:hover {
    background: var(--blue-pale);
    border-color: var(--blue);
}

.si-terminate {
    width: 32px;
    height: 32px;
    border-radius: 9px;
    background: var(--rose-pale);
    border: none;
    color: var(--rose);
    cursor: pointer;
    font-size: 13px;
    transition: all .2s;
    flex-shrink: 0;
}

.si-terminate:hover {
    background: var(--rose);
    color: white;
    transform: scale(1.05);
}

.session-item, .log-item {
    display: flex;
    align-items: center;
    gap: 15px;
    padding: 15px;
    background: var(--bg2);
    border-radius: 14px;
    margin-bottom: 12px;
}

.si-ico {
    width: 42px;
    height: 42px;
    border-radius: 12px;
    display: flex;
    align-items: center;
    justify-content: center;
    font-size: 18px;
    flex-shrink: 0;
}

.si-info {
    flex: 1;
}

.si-name {
    font-weight: 700;
    font-size: 14px;
    color: var(--dark);
}

.si-sub {
    font-size: 11px;
    color: var(--soft);
    margin-top: 3px;
}

.si-badge {
    padding: 4px 12px;
    border-radius: 30px;
    font-size: 11px;
    font-weight: 600;
}

.sib-active {
    background: rgba(16, 185, 129, .15);
    color: #10b981;
}

.log-item span {
    flex: 1;
    font-size: 13px;
}

.log-date {
    font-size: 11px;
    color: var(--soft);
}

::-webkit-scrollbar {
    width: 5px;
}

::-webkit-scrollbar-thumb {
    background: rgba(200, 134, 10, .2);
    border-radius: 4px;
}

@media (max-width: 1100px) {
    .settings-layout { flex-direction: column; }
    .tabs-nav { width: 100%; position: static; display: flex; flex-wrap: wrap; padding: 12px; gap: 6px; }
    .tab-btn { width: auto; padding: 10px 14px; flex-direction: row; border-left: none; border-radius: 10px; border-bottom: 2px solid transparent; }
    .tab-btn.active { border-left: none; border-bottom-color: var(--blue-light); }
    .tabs-nav-head { display: none; }
}

@media (max-width: 900px) {
    .sidebar { transform: translateX(-100%); }
    .main { margin-left: 0; padding: 20px; }
    .f-grid { grid-template-columns: 1fr; }
    .span2 { grid-column: span 1; }
}

@media (max-width: 560px) {
    .theme-cards { flex-direction: column; }
}
</style>
</head>
<body>

<script>
// Gestion automatique du thème (système + localStorage)
(function() {
    var savedTheme = localStorage.getItem('fredon_theme');
    var systemDark = window.matchMedia('(prefers-color-scheme: dark)').matches;
    
    if (!savedTheme) {
        if (systemDark) {
            document.body.classList.add('dark-theme', 'dm');
        } else {
            document.body.classList.add('light-theme');
        }
    } else {
        if (savedTheme === 'dark') {
            document.body.classList.add('dark-theme', 'dm');
        } else {
            document.body.classList.add('light-theme');
        }
    }
})();
</script>

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
            <a href="<%= request.getContextPath() %>/admin/dashboard" class="nav-item"><i class="fas fa-chart-line"></i> <%= TranslateUtil.t(lang, "dashboard") %></a>
            <a href="<%= request.getContextPath() %>/admin/add-property" class="nav-item">
            <i class="fas fa-plus-circle"></i> <%= TranslateUtil.t(lang, "add") %> <%= TranslateUtil.t(lang, "property") %></a>
            <a href="<%= request.getContextPath() %>/chat" class="nav-item"><i class="fas fa-comments"></i> <%= TranslateUtil.t(lang, "messages") %> 
            <% if(unreadMessages > 0){ %><span class="nav-badge"><%= unreadMessages %></span><% } %>
            </a>
            <div class="nav-section"><%= TranslateUtil.t(lang, "management") %></div>
            <a href="<%= request.getContextPath() %>/admin/clients" class="nav-item">
            <i class="fas fa-users"></i> <%= TranslateUtil.t(lang, "clients") %></a>
            <a href="<%= request.getContextPath() %>/admin/appointments" class="nav-item"><i class="fas fa-calendar-check"></i> <%= TranslateUtil.t(lang, "appointments") %></a>
            <a href="statistics.jsp" class="nav-item"><i class="fas fa-chart-pie"></i> <%= TranslateUtil.t(lang, "statistics") %></a>
            <div class="nav-section"><%= TranslateUtil.t(lang, "system") %></div>
            <a href="<%= request.getContextPath() %>/admin/setting" class="nav-item active"><i class="fas fa-cog"></i> <%= TranslateUtil.t(lang, "settings") %></a>
            <a href="<%= request.getContextPath() %>/home" class="nav-item"><i class="fas fa-globe"></i> <%= TranslateUtil.t(lang, "view_site") %></a>
            <a href="<%= request.getContextPath() %>/logout" class="nav-item logout"><i class="fas fa-sign-out-alt"></i> <%= TranslateUtil.t(lang, "logout") %></a>
        </nav>
        <div class="user-bottom">
            <div class="u-avatar">
                <% if (adminProfilePic != null && !adminProfilePic.isEmpty()) { %>
                    <img src="<%= request.getContextPath() %>/uploads/<%= adminProfilePic %>" style="width:100%;height:100%;object-fit:cover;border-radius:12px;">
                <% } else { %>
                    <%= adminInitial %>
                <% } %>
            </div>
            <div class="u-info">
                <div class="u-name"><%= adminName.isEmpty() ? "Admin" : adminName %></div>
                <div class="u-role"><%= TranslateUtil.t(lang, "admin") %></div>
            </div>
            <div class="u-dot"></div>
        </div>
    </aside>

    <main class="main">

        <div class="top-bar">
            <div class="page-title">
                <h1>⚙️ <%= TranslateUtil.t(lang, "settings") %></h1>
                <p><%= TranslateUtil.t(lang, "manage_config") %></p>
            </div>
            <div style="display: flex; gap: 10px;">
                <div class="icon-circle"><i class="fas fa-bell"></i></div>
                <div class="icon-circle"><i class="fas fa-question-circle"></i></div>
            </div>
        </div>

        <% if (success != null) { %>
        <div class="alert alert-success"><i class="fas fa-check-circle"></i><span><%= success %></span><button class="alert-close" onclick="this.parentElement.remove()">×</button></div>
        <% } %>
        <% if (error != null) { %>
        <div class="alert alert-error"><i class="fas fa-exclamation-triangle"></i><span><%= error %></span><button class="alert-close" onclick="this.parentElement.remove()">×</button></div>
        <% } %>

        <div class="settings-layout">

            <div class="tabs-nav">
                <div class="tabs-nav-head"><span><%= TranslateUtil.t(lang, "navigation") %></span></div>
                <button class="tab-btn active" onclick="showTab('profile', this)"><div class="tb-ico" style="background: var(--gold-pale); color: var(--gold)"><i class="fas fa-user-circle"></i></div><span><%= TranslateUtil.t(lang, "my_profile") %></span><i class="fas fa-chevron-right tb-arrow"></i></button>
                <button class="tab-btn" onclick="showTab('historique', this)"><div class="tb-ico" style="background: var(--teal-pale); color: var(--teal)"><i class="fas fa-landmark"></i></div><span>Historique</span><i class="fas fa-chevron-right tb-arrow"></i></button>
                <button class="tab-btn" onclick="showTab('apparence', this)"><div class="tb-ico" style="background: var(--purple-pale); color: var(--purple)"><i class="fas fa-palette"></i></div><span><%= TranslateUtil.t(lang, "appearance") %></span><i class="fas fa-chevron-right tb-arrow"></i></button>
                <button class="tab-btn" onclick="showTab('notifications', this)"><div class="tb-ico" style="background: var(--rose-pale); color: var(--rose)"><i class="fas fa-bell"></i></div><span><%= TranslateUtil.t(lang, "notifications") %></span><i class="fas fa-chevron-right tb-arrow"></i></button>
                <button class="tab-btn" onclick="showTab('securite', this)"><div class="tb-ico" style="background: var(--teal-pale); color: var(--teal)"><i class="fas fa-shield-alt"></i></div><span><%= TranslateUtil.t(lang, "security") %></span><i class="fas fa-chevron-right tb-arrow"></i></button>
                <button class="tab-btn" onclick="showTab('langue', this)"><div class="tb-ico" style="background: rgba(245, 158, 11, .1); color: #d97706"><i class="fas fa-language"></i></div><span>Langue</span><i class="fas fa-chevron-right tb-arrow"></i></button>
            </div>

            <div class="tabs-content">

                <!-- PROFIL -->
                <div id="tab-profile" class="tab-panel active">
                   <form action="<%= request.getContextPath() %>/immo/admin/update-password" method="post" id="passwordForm">
                         <div class="s-card">
                            <div class="s-card-head">
                                <div class="sch-ico" style="background: var(--gold-pale); color: var(--gold)"><i class="fas fa-id-badge"></i></div>
                                <div><div class="sch-title"><%= TranslateUtil.t(lang, "my_profile") %></div><div class="sch-sub"><%= TranslateUtil.t(lang, "personal_info") %></div></div>
                            </div>
                            <div class="s-card-body">
                                <div class="avatar-zone">
                                    <div class="av-big" id="avPreview">
                                        <% if (adminProfilePic != null && !adminProfilePic.isEmpty()) { %>
                                            <img src="<%= request.getContextPath() %>/uploads/<%= adminProfilePic %>" style="width:100%;height:100%;object-fit:cover;">
                                        <% } else { %>
                                            <%= adminInitial %>
                                        <% } %>
                                    </div>
                                    <div class="av-info">
                                        <h4><%= adminName.isEmpty() ? "Administrateur" : adminName %></h4>
                                        <p><%= TranslateUtil.t(lang, "change_photo") %></p>
                                        <div class="av-btns">
                                            <button type="button" class="btn-outline-blue" onclick="document.getElementById('avatarInput').click()"><i class="fas fa-camera"></i> <%= TranslateUtil.t(lang, "change_photo") %></button>
                                            <button type="button" class="btn-cancel" style="padding: 10px 14px; font-size: 12px;" onclick="resetAvatar()"><i class="fas fa-undo"></i> <%= TranslateUtil.t(lang, "reset") %></button>
                                        </div>
                                    </div>
                                    <input type="file" id="avatarInput" name="avatar" accept="image/*" style="display: none" onchange="previewAvatar(this)">
                                </div>
                                <div class="f-grid">
                                    <div class="field"><label><i class="fas fa-user" style="color: var(--gold)"></i><%= TranslateUtil.t(lang, "full_name") %></label><div class="field-icon"><i class="fas fa-user fi"></i><input type="text" class="f-input" name="fullName" value="<%= adminFullName %>" placeholder="<%= TranslateUtil.t(lang, "full_name") %>"></div></div>
                                    <div class="field"><label><i class="fas fa-envelope" style="color: var(--blue)"></i><%= TranslateUtil.t(lang, "email") %></label><div class="field-icon"><i class="fas fa-envelope fi"></i><input type="email" class="f-input" name="email" value="<%= adminEmailAddr %>" placeholder="<%= TranslateUtil.t(lang, "email") %>"></div></div>
                                    <div class="field"><label><i class="fas fa-phone" style="color: var(--teal)"></i><%= TranslateUtil.t(lang, "phone") %></label><div class="field-icon"><i class="fas fa-phone fi"></i><input type="tel" class="f-input" name="phone" value="<%= adminPhone %>" placeholder="<%= TranslateUtil.t(lang, "phone") %>"></div></div>
                                    <div class="field"><label><i class="fas fa-map-marker-alt" style="color: var(--rose)"></i><%= TranslateUtil.t(lang, "address") %></label><div class="field-icon"><i class="fas fa-map-marker-alt fi"></i><input type="text" class="f-input" name="address" value="<%= adminAddress %>" placeholder="<%= TranslateUtil.t(lang, "address") %>"></div></div>
                                </div>
                            </div>
                        </div>
                        <div class="form-foot">
                            <button type="submit" class="btn-save"><i class="fas fa-save"></i> <%= TranslateUtil.t(lang, "save") %></button>
                        </div>
                    </form>
                </div>

                <!-- HISTORIQUE -->
                <div id="tab-historique" class="tab-panel">
                    <div class="s-card">
                        <div class="s-card-head">
                            <div class="sch-ico" style="background: var(--teal-pale); color: var(--teal)"><i class="fas fa-landmark"></i></div>
                            <div><div class="sch-title">Informations de l'agence</div><div class="sch-sub">Date de création, siège, contact</div></div>
                        </div>
                        <div class="s-card-body">
                            <div class="f-grid">
                                <div class="field span2"><label><i class="fas fa-building" style="color: var(--teal)"></i> Nom de l'agence</label><div class="field-icon"><i class="fas fa-building fi"></i><input type="text" class="f-input" id="h-nom" placeholder="Nom de l'agence"></div></div>
                                <div class="field span2"><label><i class="fas fa-align-left" style="color: var(--blue)"></i> Description</label><textarea class="f-textarea" id="h-desc" placeholder="Description de l'agence"></textarea></div>
                                <div class="field"><label><i class="fas fa-calendar-alt" style="color: var(--gold)"></i> Année de création</label><div class="field-icon"><i class="fas fa-calendar fi"></i><input type="number" class="f-input" id="h-annee" placeholder="2020"></div></div>
                                <div class="field"><label><i class="fas fa-map-marker-alt" style="color: var(--rose)"></i> Siège social</label><div class="field-icon"><i class="fas fa-map-marker-alt fi"></i><input type="text" class="f-input" id="h-siege" placeholder="Mahajanga, Madagascar"></div></div>
                                <div class="field"><label><i class="fas fa-phone" style="color: var(--teal)"></i> Téléphone</label><div class="field-icon"><i class="fas fa-phone fi"></i><input type="text" class="f-input" id="h-tel" placeholder="+261 XX XX XXX XX"></div></div>
                                <div class="field"><label><i class="fas fa-envelope" style="color: var(--blue)"></i> Email</label><div class="field-icon"><i class="fas fa-envelope fi"></i><input type="email" class="f-input" id="h-email" placeholder="contact@agence.mg"></div></div>
                                <div class="field span2"><label><i class="fas fa-globe" style="color: var(--purple)"></i> Site web</label><div class="field-icon"><i class="fas fa-globe fi"></i><input type="text" class="f-input" id="h-web" placeholder="www.agence.mg"></div></div>
                            </div>
                            <div class="form-foot">
                                <button type="button" class="btn-save" onclick="saveHistoriqueInfos()"><i class="fas fa-save"></i> Enregistrer</button>
                            </div>
                        </div>
                    </div>

                    <div class="s-card">
                        <div class="s-card-head">
                            <div class="sch-ico" style="background: var(--blue-pale); color: var(--blue)"><i class="fas fa-history"></i></div>
                            <div><div class="sch-title">Timeline — Notre parcours</div><div class="sch-sub">Événements marquants de l'agence</div></div>
                        </div>
                        <div class="s-card-body">
                            <div id="timeline-list" style="display:flex;flex-direction:column;gap:14px;margin-bottom:20px;"></div>
                            <div style="background:var(--bg2);border:1.5px dashed rgba(200,134,10,.25);border-radius:16px;padding:20px;">
                                <p style="font-size:11px;font-weight:700;text-transform:uppercase;letter-spacing:1px;color:var(--soft);margin-bottom:14px;"><i class="fas fa-plus-circle" style="color:var(--teal);margin-right:6px;"></i> Ajouter un événement</p>
                                <div class="f-grid">
                                    <div class="field"><label>Année</label><input type="number" class="f-input" id="tl-annee" placeholder="2020"></div>
                                    <div class="field"><label>Titre</label><input type="text" class="f-input" id="tl-titre" placeholder="Fondation de l'agence"></div>
                                    <div class="field span2"><label>Description</label><textarea class="f-textarea" id="tl-desc" placeholder="Décrivez cet événement..." style="min-height:70px;"></textarea></div>
                                </div>
                                <div class="form-foot" style="margin-top:14px;">
                                    <button type="button" class="btn-save" style="background:linear-gradient(115deg,var(--teal),var(--teal-light));" onclick="addTimelineEvent()"><i class="fas fa-plus"></i> Ajouter</button>
                                </div>
                            </div>
                        </div>
                    </div>

                    <div class="s-card">
                        <div class="s-card-head">
                            <div class="sch-ico" style="background: var(--gold-pale); color: var(--gold)"><i class="fas fa-concierge-bell"></i></div>
                            <div><div class="sch-title">Nos services</div><div class="sch-sub">Services proposés par l'agence</div></div>
                        </div>
                        <div class="s-card-body">
                            <div id="services-list" style="display:flex;flex-direction:column;gap:10px;margin-bottom:20px;"></div>
                            <div style="display:flex;gap:10px;">
                                <input type="text" class="f-input" id="new-service" placeholder="Ex: Gestion locative">
                                <button type="button" class="btn-save" style="white-space:nowrap;" onclick="addService()"><i class="fas fa-plus"></i> Ajouter</button>
                            </div>
                        </div>
                    </div>
                </div>
                
                <!-- APPARENCE -->
                <div id="tab-apparence" class="tab-panel">
                    <form action="<%= request.getContextPath() %>/immo/admin/update-apparence" method="post">
                        <div class="s-card">
                            <div class="s-card-head">
                                <div class="sch-ico" style="background: var(--purple-pale); color: var(--purple)"><i class="fas fa-moon"></i></div>
                                <div><div class="sch-title"><%= TranslateUtil.t(lang, "theme") %></div><div class="sch-sub"><%= TranslateUtil.t(lang, "theme_colors") %></div></div>
                            </div>
                            <div class="s-card-body">
                                <div class="theme-cards">
                                    <div class="theme-card tc-light <%= "light".equals(defaultTheme) ? "picked" : "" %>" id="tc-light" onclick="pickTheme('light',this)">
                                        <div class="theme-preview"><div class="theme-preview-dots"><span style="background: #c8860a"></span><span style="background: #1f52d4"></span><span style="background: #10b981"></span></div></div>
                                        <div class="theme-label">☀️ <%= TranslateUtil.t(lang, "light") %></div>
                                        <input type="radio" name="theme" value="light" style="display: none" <%= "light".equals(defaultTheme)?"checked":"" %>>
                                    </div>
                                    <div class="theme-card tc-dark <%= "dark".equals(defaultTheme) ? "picked" : "" %>" id="tc-dark" onclick="pickTheme('dark',this)">
                                        <div class="theme-preview"><div class="theme-preview-dots"><span style="background: #ffd060"></span><span style="background: #4f7ef8"></span><span style="background: #2ecfb4"></span></div></div>
                                        <div class="theme-label">🌙 <%= TranslateUtil.t(lang, "dark") %></div>
                                        <input type="radio" name="theme" value="dark" style="display: none" <%= "dark".equals(defaultTheme)?"checked":"" %>>
                                    </div>
                                </div>
                                <input type="hidden" name="font" value="dm-sans">
                            </div>
                        </div>
                        <div class="form-foot"><button type="submit" class="btn-save"><i class="fas fa-save"></i> <%= TranslateUtil.t(lang, "save") %></button></div>
                    </form>
                </div>

                <!-- NOTIFICATIONS -->
                <div id="tab-notifications" class="tab-panel">
                    <form action="<%= request.getContextPath() %>/immo/admin/update-notifications" method="post">
                        <div class="s-card">
                            <div class="s-card-head">
                                <div class="sch-ico" style="background: var(--rose-pale); color: var(--rose)"><i class="fas fa-bell"></i></div>
                                <div><div class="sch-title"><%= TranslateUtil.t(lang, "notifications") %></div><div class="sch-sub"><%= TranslateUtil.t(lang, "notification_prefs") %></div></div>
                            </div>
                            <div class="s-card-body">
                                <div class="toggle-row"><div class="tr-info"><div class="tr-ico" style="background: var(--blue-pale); color: var(--blue)"><i class="fas fa-envelope"></i></div><div class="tr-text"><h4><%= TranslateUtil.t(lang, "email_notifications") %></h4><p><%= TranslateUtil.t(lang, "email_notifications_desc") %></p></div></div><div class="toggle-sw <%= emailNotifications ? "on" : "" %>" onclick="this.classList.toggle('on')"><div class="knob"></div></div></div>
                                <div class="toggle-row"><div class="tr-info"><div class="tr-ico" style="background: var(--teal-pale); color: var(--teal)"><i class="fas fa-comment-dots"></i></div><div class="tr-text"><h4><%= TranslateUtil.t(lang, "new_message") %></h4><p><%= TranslateUtil.t(lang, "new_message_desc") %></p></div></div><div class="toggle-sw <%= messageNotifications ? "on" : "" %>" onclick="this.classList.toggle('on')"><div class="knob"></div></div></div>
                                <div class="toggle-row"><div class="tr-info"><div class="tr-ico" style="background: var(--purple-pale); color: var(--purple)"><i class="fas fa-user-plus"></i></div><div class="tr-text"><h4><%= TranslateUtil.t(lang, "new_client") %></h4><p><%= TranslateUtil.t(lang, "new_client_desc") %></p></div></div><div class="toggle-sw <%= clientNotifications ? "on" : "" %>" onclick="this.classList.toggle('on')"><div class="knob"></div></div></div>
                                <div class="toggle-row"><div class="tr-info"><div class="tr-ico" style="background: var(--gold-pale); color: var(--gold)"><i class="fas fa-comment"></i></div><div class="tr-text"><h4><%= TranslateUtil.t(lang, "new_comment") %></h4><p><%= TranslateUtil.t(lang, "new_comment_desc") %></p></div></div><div class="toggle-sw <%= commentNotifications ? "on" : "" %>" onclick="this.classList.toggle('on')"><div class="knob"></div></div></div>
                                <div class="toggle-row"><div class="tr-info"><div class="tr-ico" style="background: var(--blue-pale); color: var(--blue-light)"><i class="fas fa-home"></i></div><div class="tr-text"><h4><%= TranslateUtil.t(lang, "new_property") %></h4><p><%= TranslateUtil.t(lang, "new_property_desc") %></p></div></div><div class="toggle-sw <%= propertyNotifications ? "on" : "" %>" onclick="this.classList.toggle('on')"><div class="knob"></div></div></div>
                                <div class="toggle-row"><div class="tr-info"><div class="tr-ico" style="background: var(--rose-pale); color: var(--rose)"><i class="fas fa-volume-up"></i></div><div class="tr-text"><h4><%= TranslateUtil.t(lang, "sound_notifications") %></h4><p><%= TranslateUtil.t(lang, "sound_notifications_desc") %></p></div></div><div class="toggle-sw <%= soundNotifications ? "on" : "" %>" onclick="this.classList.toggle('on')"><div class="knob"></div></div></div>
                            </div>
                        </div>
                        <div class="form-foot"><button type="submit" class="btn-save"><i class="fas fa-save"></i> <%= TranslateUtil.t(lang, "save") %></button></div>
                    </form>
                </div>

                <!-- SECURITE -->
                <div id="tab-securite" class="tab-panel">
                    <div class="s-card">
                        <div class="s-card-head">
                            <div class="sch-ico" style="background: var(--blue-pale); color: var(--blue)"><i class="fas fa-key"></i></div>
                            <div><div class="sch-title">Mot de passe et sécurité</div><div class="sch-sub">Modifiez votre mot de passe</div></div>
                        </div>
                        <div class="s-card-body">
                            <form action="update-password" method="post" id="passwordForm">
                                <div class="f-grid">
                                    <div class="field span2"><label><i class="fas fa-lock" style="color: var(--gold)"></i> Mot de passe actuel</label><div class="field-icon"><i class="fas fa-key fi"></i><input type="password" class="f-input" name="currentPassword" id="currentPassword" placeholder="Votre mot de passe actuel" required></div></div>
                                    <div class="field"><label><i class="fas fa-lock" style="color: var(--blue)"></i> Nouveau mot de passe</label><div class="field-icon"><i class="fas fa-key fi"></i><input type="password" class="f-input" name="newPassword" id="newPassword" placeholder="Nouveau mot de passe"></div></div>
                                    <div class="field"><label><i class="fas fa-check-circle" style="color: var(--teal)"></i> Confirmer le mot de passe</label><div class="field-icon"><i class="fas fa-key fi"></i><input type="password" class="f-input" name="confirmPassword" id="confirmPassword" placeholder="Confirmez le nouveau mot de passe"></div></div>
                                </div>
                                <div class="form-foot">
                                    <button type="submit" class="btn-save"><i class="fas fa-save"></i> Changer le mot de passe</button>
                                </div>
                            </form>
                        </div>
                    </div>

                    <div class="s-card">
                        <div class="s-card-head">
                            <div class="sch-ico" style="background: var(--teal-pale); color: var(--teal)"><i class="fas fa-laptop"></i></div>
                            <div><div class="sch-title"><%= TranslateUtil.t(lang, "active_sessions") %></div><div class="sch-sub">Connexions actives (dernières 30 minutes)</div></div>
                        </div>
                        <div class="s-card-body">
                            <% if (activeSessions.isEmpty()) { %>
                                <div style="text-align:center; padding:30px; color:var(--soft);">
                                    <i class="fas fa-laptop" style="font-size:40px; opacity:0.3; margin-bottom:10px; display:block;"></i>
                                    Aucune session active
                                </div>
                            <% } else { %>
                                <% for (Map<String, String> sessionItem : activeSessions) { %>
                                <div class="session-item">
                                    <div class="si-ico" style="background: var(--blue-pale); color: var(--blue)">
                                        <i class="fas fa-<%= "mobile".equals(sessionItem.get("device")) ? "mobile-alt" : "desktop" %>"></i>
                                    </div>
                                    <div class="si-info">
                                        <div class="si-name"><%= sessionItem.get("browser") %> - <%= sessionItem.get("os") %></div>
                                        <div class="si-sub">
                                            <i class="fas fa-map-marker-alt" style="font-size:9px;"></i> <%= sessionItem.get("location") %> &nbsp;|&nbsp;
                                            <i class="fas fa-clock"></i> <%= sessionItem.get("login_time") %>
                                        </div>
                                    </div>
                                    <span class="si-badge sib-active">🟢 Actif</span>
                                    <button class="si-terminate" onclick="terminateSession('<%= sessionItem.get("login_time") %>')" title="Déconnecter cette session"><i class="fas fa-sign-out-alt"></i></button>
                                </div>
                                <% } %>
                            <% } %>
                        </div>
                    </div>

                    <div class="s-card">
                        <div class="s-card-head">
                            <div class="sch-ico" style="background: var(--gold-pale); color: var(--gold)"><i class="fas fa-history"></i></div>
                            <div><div class="sch-title"><%= TranslateUtil.t(lang, "connection_log") %></div><div class="sch-sub">Historique des 10 dernières connexions</div></div>
                        </div>
                        <div class="s-card-body">
                            <% if (loginHistory.isEmpty()) { %>
                                <div style="text-align:center; padding:30px; color:var(--soft);">
                                    <i class="fas fa-history" style="font-size:40px; opacity:0.3; margin-bottom:10px; display:block;"></i>
                                    Aucun historique de connexion
                                </div>
                            <% } else { %>
                                <% for (Map<String, String> log : loginHistory) { %>
                                <div class="log-item">
                                    <i class="fas fa-<%= "success".equals(log.get("login_status")) ? "check-circle" : "times-circle" %>" 
                                       style="color: <%= "success".equals(log.get("login_status")) ? "#10b981" : "#ef4444" %>;"></i>
                                    <span>
                                        <%= "success".equals(log.get("login_status")) ? "Connexion réussie" : "Échec de connexion" %>
                                        <span style="font-size:11px; color:var(--soft); display:block;">
                                            <i class="fas fa-globe"></i> <%= log.get("browser") %> - <%= log.get("os") %>
                                            <% if (log.get("location") != null && !log.get("location").isEmpty()) { %>
                                            | <i class="fas fa-map-marker-alt"></i> <%= log.get("location") %>
                                            <% } %>
                                        </span>
                                    </span>
                                    <span class="log-date"><%= log.get("login_time") %></span>
                                </div>
                                <% } %>
                            <% } %>
                        </div>
                    </div>
                </div>

                <!-- LANGUE -->
                <div id="tab-langue" class="tab-panel">
                    <form action="<%= request.getContextPath() %>/immo/admin/update-language" method="post">
                        <div class="s-card">
                            <div class="s-card-head">
                                <div class="sch-ico" style="background: rgba(245, 158, 11, .1); color: #d97706"><i class="fas fa-language"></i></div>
                                <div><div class="sch-title">Langue</div><div class="sch-sub">Choisissez votre langue préférée</div></div>
                            </div>
                            <div class="s-card-body">
                                <div>
                                    <div class="f-divider" style="margin-top: 0;"></div>
                                    <p style="font-size: 11px; font-weight: 700; text-transform: uppercase; letter-spacing: .8px; color: var(--soft); margin-bottom: 14px;"><i class="fas fa-globe" style="color: var(--gold); margin-right: 5px;"></i> Langue d'affichage</p>
                                    <div style="display: flex; gap: 12px; flex-wrap: wrap;">
                                        <label style="flex: 1; min-width: 100px; cursor: pointer;">
                                            <input type="radio" name="language" value="fr" <%= "fr".equals(defaultLanguage)?"checked":"" %> style="display: none" onchange="highlightLang(this)">
                                            <div class="locale-card" id="lang-fr" style="<%= "fr".equals(defaultLanguage)?"border-color:var(--gold);background:var(--gold-pale);":"" %>text-align:center;padding:18px 14px;">
                                                <div style="font-size: 28px; margin-bottom: 6px;">🇫🇷</div><div style="font-family: 'Syne', sans-serif; font-weight: 700; font-size: 13px; color: var(--dark);">Français</div>
                                            </div>
                                        </label>
                                        <label style="flex: 1; min-width: 100px; cursor: pointer;">
                                            <input type="radio" name="language" value="en" <%= "en".equals(defaultLanguage)?"checked":"" %> style="display: none" onchange="highlightLang(this)">
                                            <div class="locale-card" id="lang-en" style="<%= "en".equals(defaultLanguage)?"border-color:var(--gold);background:var(--gold-pale);":"" %>text-align:center;padding:18px 14px;">
                                                <div style="font-size: 28px; margin-bottom: 6px;">🇬🇧</div><div style="font-family: 'Syne', sans-serif; font-weight: 700; font-size: 13px; color: var(--dark);">English</div>
                                            </div>
                                        </label>
                                        <label style="flex: 1; min-width: 100px; cursor: pointer;">
                                            <input type="radio" name="language" value="mg" <%= "mg".equals(defaultLanguage)?"checked":"" %> style="display: none" onchange="highlightLang(this)">
                                            <div class="locale-card" id="lang-mg" style="<%= "mg".equals(defaultLanguage)?"border-color:var(--gold);background:var(--gold-pale);":"" %>text-align:center;padding:18px 14px;">
                                                <div style="font-size: 28px; margin-bottom: 6px;">🇲🇬</div><div style="font-family: 'Syne', sans-serif; font-weight: 700; font-size: 13px; color: var(--dark);">Malagasy</div>
                                            </div>
                                        </label>
                                    </div>
                                </div>
                            </div>
                        </div>
                        <div class="form-foot"><button type="submit" class="btn-save"><i class="fas fa-save"></i> Enregistrer</button></div>
                    </form>
                </div>

            </div>
        </div>

    </main>
</div>

<script>

//===== HISTORIQUE ADMIN =====
let timelineData = [];
let servicesData = [];

function loadHistoriqueAdmin() {
    fetch('<%= request.getContextPath() %>/historique-agence')
        .then(r => r.json())
        .then(data => {
            if (!data) return;
            document.getElementById('h-nom').value   = data.nom            || '';
            document.getElementById('h-desc').value  = data.description    || '';
            document.getElementById('h-annee').value = data.annee_creation || '';
            document.getElementById('h-siege').value = data.siege          || '';
            document.getElementById('h-tel').value   = data.telephone      || '';
            document.getElementById('h-email').value = data.email          || '';
            document.getElementById('h-web').value   = data.site_web       || '';
            timelineData  = data.timeline  || [];
            servicesData  = data.services  || [];
            renderTimeline();
            renderServices();
        })
        .catch(e => console.error('Erreur chargement historique:', e));
}

function renderTimeline() {
    const list = document.getElementById('timeline-list');
    if (!list) return;
    if (timelineData.length === 0) {
        list.innerHTML = '<p style="color:var(--soft);font-size:13px;text-align:center;padding:20px;">Aucun événement. Ajoutez-en un ci-dessous.</p>';
        return;
    }
    var html = '';
    for (var i = 0; i < timelineData.length; i++) {
        var item = timelineData[i];
        html += '<div style="display:flex;align-items:flex-start;gap:14px;background:var(--bg2);border:1.5px solid rgba(200,134,10,.1);border-radius:14px;padding:16px;">'
            + '<div style="width:48px;height:48px;border-radius:12px;background:var(--blue-pale);color:var(--blue);display:flex;align-items:center;justify-content:center;font-family:Syne,sans-serif;font-weight:800;font-size:13px;flex-shrink:0;">' + item.annee + '</div>'
            + '<div style="flex:1;">'
            + '<div style="font-weight:700;font-size:14px;color:var(--dark);margin-bottom:4px;">' + item.titre + '</div>'
            + '<div style="font-size:12.5px;color:var(--soft);line-height:1.6;">' + item.description + '</div>'
            + '</div>'
            + '<button onclick="deleteTimelineEvent(' + i + ')" style="background:var(--rose-pale);border:none;color:var(--rose);width:32px;height:32px;border-radius:9px;cursor:pointer;font-size:13px;flex-shrink:0;"><i class="fas fa-trash"></i></button>'
            + '</div>';
    }
    list.innerHTML = html;
}

function renderServices() {
    const list = document.getElementById('services-list');
    if (!list) return;
    if (servicesData.length === 0) {
        list.innerHTML = '<p style="color:var(--soft);font-size:13px;text-align:center;padding:20px;">Aucun service enregistré.</p>';
        return;
    }
    var html2 = '';
    for (var i = 0; i < servicesData.length; i++) {
        var s = servicesData[i];
        html2 += '<div style="display:flex;align-items:center;gap:12px;background:var(--bg2);border:1.5px solid rgba(200,134,10,.1);border-radius:12px;padding:13px 16px;">'
            + '<div style="width:34px;height:34px;border-radius:9px;background:var(--gold-pale);color:var(--gold);display:flex;align-items:center;justify-content:center;font-size:13px;flex-shrink:0;"><i class="fas fa-concierge-bell"></i></div>'
            + '<span style="flex:1;font-size:13.5px;font-weight:500;color:var(--dark);">' + s + '</span>'
            + '<button onclick="deleteService(' + i + ')" style="background:var(--rose-pale);border:none;color:var(--rose);width:30px;height:30px;border-radius:8px;cursor:pointer;font-size:12px;"><i class="fas fa-trash"></i></button>'
            + '</div>';
    }
    list.innerHTML = html2;
}

function saveHistoriqueInfos() {
    const body = new URLSearchParams({
        action:         'update_infos',
        nom:            document.getElementById('h-nom').value,
        description:    document.getElementById('h-desc').value,
        annee_creation: document.getElementById('h-annee').value,
        siege:          document.getElementById('h-siege').value,
        telephone:      document.getElementById('h-tel').value,
        email:          document.getElementById('h-email').value,
        site_web:       document.getElementById('h-web').value
    });
    fetch('<%= request.getContextPath() %>/update-historique-agence', {
        method: 'POST', headers: {'Content-Type': 'application/x-www-form-urlencoded'}, body
    })
    .then(r => r.json())
    .then(d => {
        if (d.success) showAdminToast('success', '✅ Informations enregistrées !');
        else showAdminToast('error', '❌ Erreur : ' + (d.error || 'inconnue'));
    })
    .catch(() => showAdminToast('error', '❌ Erreur de connexion'));
}

function addTimelineEvent() {
    const annee = document.getElementById('tl-annee').value.trim();
    const titre = document.getElementById('tl-titre').value.trim();
    const desc  = document.getElementById('tl-desc').value.trim();
    if (!annee || !titre || !desc) { showAdminToast('error', '⚠️ Remplissez tous les champs'); return; }
    fetch('<%= request.getContextPath() %>/update-historique-agence', {
        method: 'POST',
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: new URLSearchParams({ action: 'add_timeline', annee, titre, description: desc })
    })
    .then(r => r.json())
    .then(d => {
        if (d.success) {
            timelineData.push({ annee, titre, description: desc });
            renderTimeline();
            document.getElementById('tl-annee').value = '';
            document.getElementById('tl-titre').value = '';
            document.getElementById('tl-desc').value  = '';
            showAdminToast('success', '✅ Événement ajouté !');
        } else showAdminToast('error', '❌ ' + (d.error || 'Erreur'));
    })
    .catch(() => showAdminToast('error', '❌ Erreur de connexion'));
}

function deleteTimelineEvent(index) {
    if (!confirm('Supprimer cet événement ?')) return;
    const item = timelineData[index];
    fetch('<%= request.getContextPath() %>/update-historique-agence', {
        method: 'POST',
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: new URLSearchParams({ action: 'delete_timeline', annee: item.annee, titre: item.titre })
    })
    .then(r => r.json())
    .then(d => {
        if (d.success) {
            timelineData.splice(index, 1);
            renderTimeline();
            showAdminToast('success', '🗑️ Événement supprimé');
        } else showAdminToast('error', '❌ ' + (d.error || 'Erreur'));
    })
    .catch(() => showAdminToast('error', '❌ Erreur de connexion'));
}

function addService() {
    const nom = document.getElementById('new-service').value.trim();
    if (!nom) { showAdminToast('error', '⚠️ Entrez un nom de service'); return; }
    fetch('<%= request.getContextPath() %>/update-historique-agence', {
        method: 'POST',
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: new URLSearchParams({ action: 'add_service', nom_service: nom })
    })
    .then(r => r.json())
    .then(d => {
        if (d.success) {
            servicesData.push(nom);
            renderServices();
            document.getElementById('new-service').value = '';
            showAdminToast('success', '✅ Service ajouté !');
        } else showAdminToast('error', '❌ ' + (d.error || 'Erreur'));
    })
    .catch(() => showAdminToast('error', '❌ Erreur de connexion'));
}

function deleteService(index) {
    if (!confirm('Supprimer ce service ?')) return;
    const nom = servicesData[index];
    fetch('<%= request.getContextPath() %>/update-historique-agence', {
        method: 'POST',
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: new URLSearchParams({ action: 'delete_service', nom_service: nom })
    })
    .then(r => r.json())
    .then(d => {
        if (d.success) {
            servicesData.splice(index, 1);
            renderServices();
            showAdminToast('success', '🗑️ Service supprimé');
        } else showAdminToast('error', '❌ ' + (d.error || 'Erreur'));
    })
    .catch(() => showAdminToast('error', '❌ Erreur de connexion'));
}

function showAdminToast(type, msg) {
    let toast = document.createElement('div');
    toast.className = 'alert alert-' + (type === 'success' ? 'success' : 'error');
    toast.style.cssText = 'position:fixed;top:20px;right:20px;z-index:9999;min-width:280px;animation:slideIn .35s ease;';
    var icon = (type == 'success') ? 'check-circle' : 'exclamation-triangle';
    toast.innerHTML = '<i class="fas fa-' + icon + '"></i><span>' + msg + '</span>';
    document.body.appendChild(toast);
    setTimeout(() => { toast.style.opacity = '0'; toast.style.transition = 'opacity .4s'; setTimeout(() => toast.remove(), 400); }, 3500);
}

function terminateSession(loginTime) {
    if (!confirm('Voulez-vous vraiment déconnecter cette session ?')) return;
    
    fetch('<%= request.getContextPath() %>/immo/admin/terminate-session', {
        method: 'POST',
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: 'loginTime=' + encodeURIComponent(loginTime)
    })
    .then(r => r.json())
    .then(d => {
        if (d.success) {
            showAdminToast('success', '✅ Session déconnectée');
            setTimeout(() => location.reload(), 1500);
        } else {
            showAdminToast('error', '❌ ' + (d.error || 'Erreur'));
        }
    })
    .catch(() => showAdminToast('error', '❌ Erreur de connexion'));
}

document.addEventListener('DOMContentLoaded', function() {
    document.querySelectorAll('.tab-btn').forEach(btn => {
        btn.addEventListener('click', function() {
            if (this.getAttribute('onclick') && this.getAttribute('onclick').includes('historique')) {
                loadHistoriqueAdmin();
            }
        });
    });
});

function showTab(name, btn) {
    document.querySelectorAll('.tab-panel').forEach(p => p.classList.remove('active'));
    document.querySelectorAll('.tab-btn').forEach(b => b.classList.remove('active'));
    document.getElementById('tab-' + name).classList.add('active');
    btn.classList.add('active');
}

function pickTheme(val, el) {
    document.querySelectorAll('.theme-card').forEach(c => c.classList.remove('picked'));
    el.classList.add('picked');
    el.querySelector('input[type=radio]').checked = true;
    setTheme(val);
}

function previewAvatar(input) {
    if (input.files && input.files[0]) {
        const rd = new FileReader();
        rd.onload = e => {
            const av = document.getElementById('avPreview');
            av.innerHTML = '<img src="'+e.target.result+'" alt="avatar" style="width:100%;height:100%;object-fit:cover;">';
        };
        rd.readAsDataURL(input.files[0]);
    }
}

function resetAvatar() {
    const av = document.getElementById('avPreview');
    av.style.background = 'linear-gradient(135deg, var(--gold), var(--gold-light))';
    av.innerHTML = '<%= adminInitial %>';
}

function highlightLang(input) {
    document.querySelectorAll('[id^="lang-"]').forEach(c => {
        c.style.borderColor = '';
        c.style.background = '';
    });
    const card = document.getElementById('lang-' + input.value);
    if (card) {
        card.style.borderColor = 'var(--gold)';
        card.style.background = 'var(--gold-pale)';
    }
}

document.querySelectorAll('.alert').forEach(a => {
    setTimeout(() => {
        a.style.opacity = '0';
        a.style.transition = 'opacity .4s';
        setTimeout(() => a.remove(), 400);
    }, 5000);
});

document.querySelectorAll('input[name="language"]').forEach(radio => {
    radio.addEventListener('change', function() {
        if (this.checked) {
            localStorage.setItem('user_language', this.value);
        }
    });
});

document.addEventListener('DOMContentLoaded', function() {
    const savedLang = localStorage.getItem('user_language');
    if (savedLang) {
        const radio = document.querySelector('input[name="language"][value="' + savedLang + '"]');
        if (radio) radio.checked = true;
        highlightLang(radio);
    }
});

window.setTheme = function(theme) {
    localStorage.setItem('fredon_theme', theme);
    document.body.classList.remove('light-theme', 'dark-theme', 'dm');
    if (theme === 'dark') {
        document.body.classList.add('dark-theme', 'dm');
    } else {
        document.body.classList.add('light-theme');
    }
};
</script>

<script>
if (performance.navigation.type === 2) {
    window.location.href = '${pageContext.request.contextPath}/login';
}
</script>
</body>
</html>