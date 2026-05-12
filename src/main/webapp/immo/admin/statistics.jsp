<%@ page language="java" contentType="text/html; charset=UTF-8"
	pageEncoding="UTF-8"%>
<%@ page import="java.util.*, java.text.*, java.math.*"%>
<%@ page import="java.sql.*"%>
<%@ page import="com.quickchat.model.User"%>
<%@ page import="com.immobilier.model.Property"%>
<%@ page import="com.quickchat.utils.TranslateUtil"%>
<%@ include file="includes/theme.jsp" %>

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
    boolean isAdmin = true;
    boolean isLoggedIn = (adminId != null || admin != null);

    int totalProperties = 0;
    int totalViews = 0;
    BigDecimal totalValue = BigDecimal.ZERO;
    BigDecimal averagePrice = BigDecimal.ZERO;
    int totalMessages = 0;
    int unreadMessages = 0;
    
    int activeProperties = 0;
    long totalCash = 0;
    
    Map<String, Integer> propertiesByType = new HashMap<>();
    Map<String, BigDecimal> valueByType = new HashMap<>();
    
    Map<String, Integer> monthlyAdditions = new LinkedHashMap<>();
    Map<String, Integer> monthlyMessages = new LinkedHashMap<>();
    
    List<Map<String, Object>> topProperties = new ArrayList<>();

    try {
        Class.forName("com.mysql.cj.jdbc.Driver");
        Connection conn = DriverManager.getConnection(DB_URL, DB_USER, DB_PASSWORD);
        
        String statsSql = "SELECT COUNT(*) as total, COALESCE(SUM(views_count),0) as total_views, COALESCE(SUM(price),0) as total_value, COALESCE(AVG(price),0) as avg_price FROM properties";
        try (Statement stmt = conn.createStatement(); ResultSet rs = stmt.executeQuery(statsSql)) {
            if (rs.next()) {
                totalProperties = rs.getInt("total");
                totalViews = rs.getInt("total_views");
                totalValue = rs.getBigDecimal("total_value");
                averagePrice = rs.getBigDecimal("avg_price");
            }
        }
        String msgSql = "SELECT COUNT(*) as total, SUM(CASE WHEN is_read = 0 THEN 1 ELSE 0 END) as unread FROM messages WHERE receiver_id = ?";
        try (PreparedStatement pstmt = conn.prepareStatement(msgSql)) {
            pstmt.setInt(1, adminId);
            ResultSet rs = pstmt.executeQuery();
            if (rs.next()) {
                totalMessages = rs.getInt("total");
                unreadMessages = rs.getInt("unread");
            }
            rs.close();
            pstmt.close();
        }
        
        String typeSql = "SELECT type, COUNT(*) as count, COALESCE(SUM(price),0) as total_value FROM properties GROUP BY type";
        try (Statement stmt = conn.createStatement(); ResultSet rs = stmt.executeQuery(typeSql)) {
            while (rs.next()) {
                propertiesByType.put(rs.getString("type"), rs.getInt("count"));
                valueByType.put(rs.getString("type"), rs.getBigDecimal("total_value"));
            }
        }
        
        Calendar cal = Calendar.getInstance();
        SimpleDateFormat monthFormat = new SimpleDateFormat("MMM yyyy", Locale.FRENCH);
        List<String> last6Months = new ArrayList<>();
        for (int i = 5; i >= 0; i--) {
            Calendar c = (Calendar) cal.clone();
            c.add(Calendar.MONTH, -i);
            String monthKey = monthFormat.format(c.getTime());
            last6Months.add(monthKey);
            monthlyAdditions.put(monthKey, 0);
            monthlyMessages.put(monthKey, 0);
        }
        
        String monthlySql = "SELECT DATE_FORMAT(created_at, '%b %Y') as month, COUNT(*) as count FROM properties WHERE created_at >= DATE_SUB(NOW(), INTERVAL 6 MONTH) GROUP BY DATE_FORMAT(created_at, '%b %Y') ORDER BY created_at ASC";
        try (Statement stmt = conn.createStatement(); ResultSet rs = stmt.executeQuery(monthlySql)) {
            while (rs.next()) {
                monthlyAdditions.put(rs.getString("month"), rs.getInt("count"));
            }
        }
        
        String msgMonthlySql = "SELECT DATE_FORMAT(created_at, '%b %Y') as month, COUNT(*) as count FROM messages WHERE receiver_id = ? AND created_at >= DATE_SUB(NOW(), INTERVAL 6 MONTH) GROUP BY DATE_FORMAT(created_at, '%b %Y') ORDER BY created_at ASC";
        try (PreparedStatement pstmt = conn.prepareStatement(msgMonthlySql)) {
            pstmt.setInt(1, adminId);
            ResultSet rs = pstmt.executeQuery();
            while (rs.next()) {
                monthlyMessages.put(rs.getString("month"), rs.getInt("count"));
            }
            rs.close();
            pstmt.close();
        }
        
        String topSql = "SELECT id, title, location, type, price, views_count FROM properties ORDER BY views_count DESC LIMIT 5";
        try (Statement stmt = conn.createStatement(); ResultSet rs = stmt.executeQuery(topSql)) {
            while (rs.next()) {
                Map<String, Object> prop = new HashMap<>();
                prop.put("id", rs.getInt("id"));
                prop.put("title", rs.getString("title"));
                prop.put("location", rs.getString("location"));
                prop.put("type", rs.getString("type"));
                prop.put("price", rs.getBigDecimal("price"));
                prop.put("views", rs.getInt("views_count"));
                topProperties.add(prop);
            }
        }
        
        String activeSql = "SELECT COUNT(*) as active FROM properties WHERE created_at >= DATE_SUB(NOW(), INTERVAL 30 DAY)";
        try (Statement stmt = conn.createStatement(); ResultSet rs = stmt.executeQuery(activeSql)) {
            if (rs.next()) {
                activeProperties = rs.getInt("active");
            }
        }
        
        // Récupérer la caisse totale
        try {
            String cashSql = "SELECT total_cash FROM settings WHERE id = 1";
            Statement stmtCash = conn.createStatement();
            ResultSet rsCash = stmtCash.executeQuery(cashSql);
            if (rsCash.next()) {
                totalCash = rsCash.getLong("total_cash");
            }
            rsCash.close();
            stmtCash.close();
        } catch (Exception e) {
            totalCash = 0;
        }
        
        conn.close();
        
    } catch (Exception e) { 
        e.printStackTrace(); 
    }
    
    String adminName = session.getAttribute("adminUsername") != null ? session.getAttribute("adminUsername").toString() : "Admin";
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
    
    // Construction des données pour les graphiques
    String monthlyLabels = "";
    String monthlyData = "";
    String msgMonthlyData = "";
    String typeLabels = "";
    String typeData = "";
    
    for (String month : monthlyAdditions.keySet()) {
        monthlyLabels += "'" + month + "',";
        monthlyData += monthlyAdditions.get(month) + ",";
        msgMonthlyData += monthlyMessages.get(month) + ",";
    }
    if (monthlyLabels.length() > 0) {
        monthlyLabels = monthlyLabels.substring(0, monthlyLabels.length() - 1);
        monthlyData = monthlyData.substring(0, monthlyData.length() - 1);
        msgMonthlyData = msgMonthlyData.substring(0, msgMonthlyData.length() - 1);
    } else {
        monthlyLabels = "'Jan 2025','Fev 2025','Mar 2025','Avr 2025','Mai 2025','Juin 2025'";
        monthlyData = "0,0,0,0,0,0";
        msgMonthlyData = "0,0,0,0,0,0";
    }
    
    for (String type : propertiesByType.keySet()) {
        typeLabels += "'" + type + "',";
        typeData += propertiesByType.get(type) + ",";
    }
    if (typeLabels.length() > 0) {
        typeLabels = typeLabels.substring(0, typeLabels.length() - 1);
        typeData = typeData.substring(0, typeData.length() - 1);
    } else {
        typeLabels = "'Aucun bien'";
        typeData = "1";
    }
%>

<!DOCTYPE html>
<html lang="<%= lang %>">
<head>
<%@ include file="includes/theme.jsp" %>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title><%= TranslateUtil.t(lang, "statistics") %> — Fredon Immobilier</title>
<link href="https://fonts.googleapis.com/css2?family=Syne:wght@400;600;700;800&family=DM+Sans:ital,opsz,wght@0,9..40,300;0,9..40,400;0,9..40,500;0,9..40,600;0,9..40,700&display=swap" rel="stylesheet">
<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css">
<script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
<style>
*, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }
:root {
    --gold: #c8860a; --gold-light: #e8a220; --gold-pale: #fff3d4;
    --blue: #1f52d4; --blue-light: #4f7ef8; --blue-pale: #e8eeff;
    --teal: #0e9e8a; --teal-light: #2ecfb4; --teal-pale: #e0faf5;
    --rose: #e03060; --rose-light: #f7547a; --rose-pale: #fde8ee;
    --purple: #7c3aed; --purple-pale: #f0ebff;
    --green: #10b981; --red: #ef4444;
    --dark: #0d0b08; --mid: #6b5a3e; --soft: #a89880;
    --bg: #f8f4ee; --bg2: #fdf9f3; --white: #ffffff;
    --sidebar-w: 272px; --r-xl: 26px;
}
html, body { height: 100%; font-family: 'DM Sans', sans-serif; background: var(--bg); color: var(--dark); overflow-x: hidden; }
#bgCanvas { position: fixed; inset: 0; z-index: 0; pointer-events: none; opacity: .06; }
.layout { display: flex; min-height: 100vh; position: relative; z-index: 1; }
.sidebar {
    width: var(--sidebar-w); background: linear-gradient(160deg, #0d1f5e 0%, #1a3aaa 45%, #0e2d82 75%, #0a1d58 100%);
    display: flex; flex-direction: column; position: fixed; left: 0; top: 0; bottom: 0; z-index: 100;
    box-shadow: 8px 0 40px rgba(31, 82, 212, .18); overflow-y: auto;
overflow-x: hidden;
}
.sidebar::before {
    content: ''; position: absolute; inset: 0;
    background-image: radial-gradient(ellipse at 80% 10%, rgba(200, 134, 10, .18) 0%, transparent 60%),
                      radial-gradient(ellipse at 20% 90%, rgba(79, 126, 248, .15) 0%, transparent 50%);
    pointer-events: none;
}
.sidebar-grid {
    position: absolute; inset: 0; pointer-events: none;
    background-image: linear-gradient(rgba(255, 255, 255, .03) 1px, transparent 1px),
                      linear-gradient(90deg, rgba(255, 255, 255, .03) 1px, transparent 1px);
    background-size: 36px 36px;
}
.logo-area { padding: 26px 22px 20px; border-bottom: 1px solid rgba(255, 255, 255, .1); display: flex; align-items: center; gap: 12px; position: relative; z-index: 2; }
.logo-mark { width: 50px; height: 50px; flex-shrink: 0; filter: drop-shadow(0 6px 16px rgba(0, 0, 0, .35)); }
.logo-text-wrap { display: flex; flex-direction: column; }
.logo-name { font-family: 'Syne', sans-serif; font-weight: 800; font-size: 22px; background: linear-gradient(120deg, #fff 0%, #fde9b0 100%); -webkit-background-clip: text; background-clip: text; color: transparent; }
.logo-sub { font-size: 9px; color: rgba(255, 255, 255, .5); letter-spacing: 2.2px; text-transform: uppercase; margin-top: 2px; }
.nav { flex: 1; padding: 18px 14px; display: flex; flex-direction: column; gap: 2px; position: relative; z-index: 2; overflow-y: auto; }
.nav-section { font-size: 9.5px; font-weight: 700; letter-spacing: 1.8px; text-transform: uppercase; color: rgba(255, 255, 255, .38); padding: 14px 10px 6px; }
.nav-item { display: flex; align-items: center; gap: 11px; padding: 11px 13px; border-radius: 12px; color: rgba(255, 255, 255, .65); font-size: 13.5px; font-weight: 500; text-decoration: none; transition: all .22s; }
.nav-item i { width: 18px; font-size: 14px; text-align: center; }
.nav-item:hover { background: rgba(255, 255, 255, .1); color: #fff; }
.nav-item.active { background: rgba(255, 255, 255, .14); color: #fff; border-left: 3px solid var(--gold-light); }
.nav-item.logout { color: rgba(255, 130, 130, .7); margin-top: auto; }
.nav-item.logout:hover { background: rgba(239, 68, 68, .15); color: #fca5a5; }
.nav-badge { margin-left: auto; background: var(--rose); color: white; font-size: 9.5px; font-weight: 700; padding: 2px 7px; border-radius: 20px; }
.user-bottom { padding: 16px 14px; border-top: 1px solid rgba(255, 255, 255, .1); display: flex; align-items: center; gap: 10px; cursor: pointer; transition: all .22s; position: relative; z-index: 2; }
.user-bottom:hover { background: rgba(255, 255, 255, .08); }
.u-avatar { width: 42px; height: 42px; flex-shrink: 0; background: linear-gradient(135deg, var(--gold), var(--gold-light)); border-radius: 12px; display: flex; align-items: center; justify-content: center; font-family: 'Syne', sans-serif; font-size: 18px; font-weight: 800; color: #fff; box-shadow: 0 4px 14px rgba(200, 134, 10, .4); }
.u-info { flex: 1; }
.u-name { font-size: 13.5px; font-weight: 700; color: #fff; }
.u-role { font-size: 10.5px; color: rgba(255, 255, 255, .5); margin-top: 1px; }
.u-dot { width: 8px; height: 8px; background: var(--teal-light); border-radius: 50%; box-shadow: 0 0 8px var(--teal-light); }
.main { margin-left: var(--sidebar-w); flex: 1; padding: 28px 32px; min-height: 100vh; }
.top-bar { display: flex; justify-content: space-between; align-items: center; margin-bottom: 28px; gap: 16px; flex-wrap: wrap; }
.page-title h1 { font-family: 'Syne', sans-serif; font-size: 26px; font-weight: 800; color: var(--dark); letter-spacing: -.5px; }
.page-title p { font-size: 13px; color: var(--soft); margin-top: 3px; }
.top-right { display: flex; align-items: center; gap: 10px; }
.icon-circle { width: 40px; height: 40px; background: var(--white); border: 1.5px solid rgba(200, 134, 10, .14); border-radius: 12px; display: flex; align-items: center; justify-content: center; cursor: pointer; color: var(--mid); font-size: 15px; transition: all .22s; }
.icon-circle:hover { border-color: var(--gold); color: var(--gold); }
.stats-row { display: grid; grid-template-columns: repeat(3, 1fr); gap: 18px; margin-bottom: 28px; }
.stat-card { background: var(--white); border-radius: var(--r-xl); padding: 22px 20px; border: 1.5px solid transparent; position: relative; overflow: hidden; transition: transform .25s, box-shadow .25s; cursor: default; }
.stat-card:hover { transform: translateY(-4px); box-shadow: 0 16px 40px rgba(0, 0, 0, .1); }
.sc-blue { background: linear-gradient(135deg, #e8eeff 0%, #f8faff 100%); border-color: rgba(79, 126, 248, .2); }
.sc-gold { background: linear-gradient(135deg, #fff3d4 0%, #fffaf0 100%); border-color: rgba(200, 134, 10, .2); }
.sc-teal { background: linear-gradient(135deg, #e0faf5 0%, #f4fffe 100%); border-color: rgba(14, 158, 138, .2); }
.sc-rose { background: linear-gradient(135deg, #fde8ee 0%, #fff5f8 100%); border-color: rgba(224, 48, 96, .18); }
.stat-top { display: flex; justify-content: space-between; align-items: flex-start; margin-bottom: 14px; }
.stat-ico { width: 46px; height: 46px; border-radius: 14px; display: flex; align-items: center; justify-content: center; font-size: 20px; }
.ico-blue { background: rgba(79, 126, 248, .15); color: var(--blue-light); }
.ico-gold { background: rgba(200, 134, 10, .15); color: var(--gold); }
.ico-teal { background: rgba(14, 158, 138, .15); color: var(--teal); }
.ico-rose { background: rgba(224, 48, 96, .15); color: var(--rose); }
.stat-badge { font-size: 10.5px; font-weight: 700; padding: 3px 9px; border-radius: 20px; }
.badge-up { background: rgba(16, 185, 129, .12); color: #059669; }
.stat-val { font-family: 'Syne', sans-serif; font-size: 34px; font-weight: 800; line-height: 1; margin-bottom: 5px; }
.val-blue { color: var(--blue); }
.val-gold { color: var(--gold); }
.val-teal { color: var(--teal); }
.val-rose { color: var(--rose); }
.stat-lbl { font-size: 12px; color: var(--soft); font-weight: 500; }
.charts-grid { display: grid; grid-template-columns: repeat(2, 1fr); gap: 24px; margin-bottom: 28px; }
.chart-card { background: var(--white); border-radius: var(--r-xl); padding: 24px; border: 1.5px solid rgba(200, 134, 10, .1); }
.chart-title { font-family: 'Syne', sans-serif; font-size: 16px; font-weight: 700; margin-bottom: 20px; display: flex; align-items: center; gap: 8px; }
.full-width { grid-column: span 2; }
.top-card { background: var(--white); border-radius: var(--r-xl); padding: 24px; border: 1.5px solid rgba(200, 134, 10, .1); margin-bottom: 28px; }
.top-title { font-family: 'Syne', sans-serif; font-size: 16px; font-weight: 700; margin-bottom: 20px; display: flex; align-items: center; gap: 8px; }
.prop-list { display: flex; flex-direction: column; gap: 12px; }
.prop-item { display: flex; align-items: center; gap: 15px; padding: 12px; background: var(--bg); border-radius: 12px; transition: all .2s; }
.prop-rank { width: 36px; height: 36px; background: linear-gradient(135deg, var(--gold), var(--gold-light)); border-radius: 10px; display: flex; align-items: center; justify-content: center; font-weight: 800; color: white; }
.prop-info { flex: 1; }
.prop-title { font-weight: 700; margin-bottom: 4px; }
.prop-stats { font-size: 12px; color: var(--soft); }
.prop-views { font-weight: 800; color: var(--blue); }
.summary-card { background: var(--white); border-radius: var(--r-xl); padding: 24px; border: 1.5px solid rgba(200, 134, 10, .1); }
.summary-grid { display: grid; grid-template-columns: repeat(3, 1fr); gap: 20px; margin-top: 20px; }
.summary-item { text-align: center; padding: 15px; background: var(--bg); border-radius: 16px; }
.summary-value { font-family: 'Syne', sans-serif; font-size: 24px; font-weight: 800; }
.summary-label { font-size: 12px; color: var(--soft); margin-top: 5px; }
canvas { max-height: 300px; }
.btn-back { display: inline-flex; align-items: center; gap: 8px; padding: 8px 16px; background: white; border: 1.5px solid rgba(200, 134, 10, .2); border-radius: 10px; text-decoration: none; color: var(--mid); transition: all .2s; }
.btn-back:hover { border-color: var(--gold); color: var(--gold); }
@keyframes fadeUp { from { opacity:0; transform: translateY(16px); } to { opacity:1; transform: translateY(0); } }
.fade-1 { animation: fadeUp .5s .05s both; }
.fade-2 { animation: fadeUp .5s .15s both; }
.fade-3 { animation: fadeUp .5s .25s both; }
.fade-4 { animation: fadeUp .5s .35s both; }
@media (max-width: 1024px) { .charts-grid { grid-template-columns: 1fr; } .full-width { grid-column: span 1; } }
@media (max-width: 900px) { .sidebar { transform: translateX(-100%); } .main { margin-left: 0; padding: 20px; } .stats-row { grid-template-columns: repeat(2, 1fr); } }
@media (max-width: 560px) { .stats-row { grid-template-columns: 1fr; } .summary-grid { grid-template-columns: 1fr; } }
/* Mode sombre */
body.dark-theme {
    background: #060c1a;
    color: #e0e8ff;
}
body.dark-theme .stat-card,
body.dark-theme .chart-card,
body.dark-theme .top-card,
body.dark-theme .summary-card {
    background: #0d1626;
    border-color: rgba(255,255,255,.08);
}
body.dark-theme .page-title h1 {
    color: #e0e8ff;
}
body.dark-theme .stat-lbl {
    color: #6070a0;
}
body.dark-theme canvas {
    filter: brightness(0.9);
}
@media print {
    .sidebar, .top-right a:not(.btn-back), .icon-circle, .top-btn-primary, .quick-row {
        display: none !important;
    }
    .main {
        margin-left: 0 !important;
        padding: 0 !important;
    }
    .stat-card, .chart-card, .top-card {
        break-inside: avoid;
        page-break-inside: avoid;
    }
    body, .main, .content-card {
        background: white !important;
        color: black !important;
    }
    canvas {
        max-width: 100% !important;
    }
}
/* Style du scrollbar - identique au dashboard */
::-webkit-scrollbar {
    width: 5px;
}
::-webkit-scrollbar-track {
    background: transparent;
}
::-webkit-scrollbar-thumb {
    background: rgba(200, 134, 10, .2);
    border-radius: 4px;
}
::-webkit-scrollbar-thumb:hover {
    background: rgba(200, 134, 10, .4);
}
</style>
</head>
<body>

<canvas id="bgCanvas"></canvas>

<div class="layout">

    <aside class="sidebar">
        <div class="sidebar-grid"></div>
        <div class="logo-area" style="padding: 20px 18px 18px; gap: 14px;">
            <img src="${pageContext.request.contextPath}/immo/admin/images/Logo.jpg"
                 alt="Fredon"
                 style="width: 68px; height: 68px; object-fit: cover; border-radius: 18px; box-shadow: 0 6px 22px rgba(0,0,0,.45), 0 0 0 2px rgba(255,255,255,.2);">
            <div class="logo-text-wrap">
                <span class="logo-name" style="font-size: 26px;">Fredon</span>
                <span class="logo-sub"><%= TranslateUtil.t(lang, "real_estate_agency") %></span>
            </div>
        </div>
        <nav class="nav">
            <div class="nav-section"><%= TranslateUtil.t(lang, "principal") %></div>
            <a href="${pageContext.request.contextPath}/admin/dashboard" class="nav-item"> <i class="fas fa-chart-line"></i> <%= TranslateUtil.t(lang, "dashboard") %></a>
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
            <a href="${pageContext.request.contextPath}/admin/statistics" class="nav-item active"> <i class="fas fa-chart-pie"></i> <%= TranslateUtil.t(lang, "statistics") %></a>
            <div class="nav-section"><%= TranslateUtil.t(lang, "system") %></div>
            <a href="${pageContext.request.contextPath}/" class="nav-item"> <i class="fas fa-globe"></i> <%= TranslateUtil.t(lang, "view_site") %></a>
            <a href="${pageContext.request.contextPath}/admin/setting" class="nav-item"><i class="fas fa-cog"></i> Paramètres</a>
            <a href="${pageContext.request.contextPath}/logout" class="nav-item logout"> <i class="fas fa-sign-out-alt"></i> <%= TranslateUtil.t(lang, "logout") %></a>
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

        <div class="top-bar fade-1">
            <div class="page-title">
                <h1><i class="fas fa-chart-pie" style="color: var(--gold);"></i> <%= TranslateUtil.t(lang, "statistics_analysis") %></h1>
                <p><%= TranslateUtil.t(lang, "portfolio_performance") %></p>
            </div>
            <div class="top-right">
                <a href="${pageContext.request.contextPath}/admin/notifications" class="icon-circle" style="text-decoration: none;"><i class="fas fa-bell"></i></a>
                <a href="${pageContext.request.contextPath}/admin/setting" class="icon-circle" style="text-decoration: none;"><i class="fas fa-cog"></i></a>
                <button onclick="window.location.href='${pageContext.request.contextPath}/admin/print-stats'" 
                        style="background: #dc2626; color: white; border: none; padding: 8px 16px; border-radius: 12px; cursor: pointer;">
                    <i class="fas fa-file-pdf"></i> Export PDF
                </button>
                <a href="${pageContext.request.contextPath}/admin/dashboard" class="btn-back"><i class="fas fa-arrow-left"></i> Back</a>
            </div>
        </div>

        <div class="stats-row fade-2">
            <div class="stat-card sc-blue">
                <div class="stat-top"><div class="stat-ico ico-blue"><i class="fas fa-home"></i></div><span class="stat-badge badge-up"><%= TranslateUtil.t(lang, "total") %></span></div>
                <div class="stat-val val-blue"><%= totalProperties %></div>
                <div class="stat-lbl"><%= TranslateUtil.t(lang, "properties_online") %></div>
            </div>
            <div class="stat-card sc-gold">
                <div class="stat-top"><div class="stat-ico ico-gold"><i class="fas fa-eye"></i></div><span class="stat-badge badge-up"><%= TranslateUtil.t(lang, "views") %></span></div>
                <div class="stat-val val-gold"><%= String.format("%,d", totalViews) %></div>
                <div class="stat-lbl"><%= TranslateUtil.t(lang, "total_views") %></div>
            </div>
            <div class="stat-card sc-teal">
                <div class="stat-top"><div class="stat-ico ico-teal"><i class="fas fa-coins"></i></div><span class="stat-badge badge-up">💰 Caisse</span></div>
                <div class="stat-val val-teal" style="font-size: 28px;"><%= String.format("%,.0f", (double) totalCash) %> Ar</div>
                <div class="stat-lbl">Caisse totale (ventes)</div>
            </div>
        </div>

        <div class="charts-grid fade-3">
            <div class="chart-card">
                <div class="chart-title"><i class="fas fa-chart-line" style="color: var(--blue);"></i> <%= TranslateUtil.t(lang, "monthly_additions") %></div>
                <canvas id="monthlyChart"></canvas>
            </div>
            <div class="chart-card">
                <div class="chart-title"><i class="fas fa-chart-pie" style="color: var(--gold);"></i> <%= TranslateUtil.t(lang, "distribution_by_type") %></div>
                <canvas id="typeChart"></canvas>
            </div>
            <div class="chart-card">
                <div class="chart-title"><i class="fas fa-chart-line" style="color: var(--teal);"></i> <%= TranslateUtil.t(lang, "monthly_messages") %></div>
                <canvas id="messagesChart"></canvas>
            </div>
            <div class="chart-card">
                <div class="chart-title"><i class="fas fa-chart-bar" style="color: var(--rose);"></i> <%= TranslateUtil.t(lang, "property_performance") %></div>
                <canvas id="performanceChart"></canvas>
            </div>
        </div>

        <div class="top-card fade-4">
            <div class="top-title"><i class="fas fa-trophy" style="color: var(--gold);"></i> <%= TranslateUtil.t(lang, "top_5_most_viewed") %></div>
            <div class="prop-list">
                <% if (topProperties.isEmpty()) { %>
                <p style="text-align: center; color: var(--soft); padding: 40px;"><i class="fas fa-info-circle"></i> <%= TranslateUtil.t(lang, "no_properties_yet") %></p>
                <% } else { int rank = 1; for (Map<String, Object> prop : topProperties) { %>
                <div class="prop-item">
                    <div class="prop-rank"><%= rank++ %></div>
                    <div class="prop-info">
                        <div class="prop-title"><%= prop.get("title") %></div>
                        <div class="prop-stats"><i class="fas fa-map-marker-alt"></i> <%= prop.get("location") %> &nbsp;|&nbsp; <i class="fas fa-tag"></i> <%= prop.get("type") %></div>
                    </div>
                    <div class="prop-views"><i class="fas fa-eye"></i> <%= prop.get("views") %> <%= TranslateUtil.t(lang, "views") %></div>
                </div>
                <% } } %>
            </div>
        </div>

        <!-- SECTION RÉACTIONS DES BIENS -->
        <div class="top-card fade-4">
            <div class="top-title">
                <i class="fas fa-heart" style="color: var(--rose);"></i>
                <span>Réactions des clients sur les biens</span>
                <span id="totalReactionsBadge" style="margin-left: auto; background: var(--rose); color: white; padding: 4px 12px; border-radius: 20px; font-size: 12px;">0 réactions</span>
            </div>
            <div style="overflow-x: auto;">
                <table style="width: 100%; border-collapse: collapse;">
                    <thead>
                        <tr style="background: var(--bg); border-bottom: 2px solid var(--border);">
                            <th style="padding: 12px; text-align: left;">Bien</th>
                            <th style="padding: 12px; text-align: center;">❤️ J'adore</th>
                            <th style="padding: 12px; text-align: center;">👍 J'aime</th>
                            <th style="padding: 12px; text-align: center;">😂 Haha</th>
                            <th style="padding: 12px; text-align: center;">😡 Colère</th>
                            <th style="padding: 12px; text-align: center;">😢 Triste</th>
                            <th style="padding: 12px; text-align: center;">Total</th>
                            <th style="padding: 12px; text-align: center;">Détails</th>
                        </tr>
                    </thead>
                    <tbody id="reactionsTableBody">
                        <tr><td colspan="8" style="text-align: center; padding: 40px;"><i class="fas fa-spinner fa-spin"></i> Chargement...</td></tr>
                    </tbody>
                </table>
            </div>
        </div>

        <!-- Modal pour voir les détails des réactions -->
        <div id="reactionModal" style="display: none; position: fixed; inset: 0; background: rgba(0,0,0,0.7); backdrop-filter: blur(8px); z-index: 9999; align-items: center; justify-content: center;">
            <div style="background: var(--white); border-radius: 24px; width: 500px; max-width: 90%; padding: 24px; animation: fadeUp 0.3s ease;">
                <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 20px;">
                    <h3 style="font-family: 'Syne', sans-serif;"><i class="fas fa-users"></i> Détails des réactions</h3>
                    <button onclick="closeReactionModal()" style="background: none; border: none; font-size: 24px; cursor: pointer;">&times;</button>
                </div>
                <div id="reactionModalContent"></div>
            </div>
        </div>

        <div class="summary-card fade-4">
            <div class="top-title"><i class="fas fa-chart-simple" style="color: var(--purple);"></i> <%= TranslateUtil.t(lang, "financial_overview") %></div>
            <div class="summary-grid">
                <div class="summary-item">
                    <div class="summary-value" style="color: var(--gold);"><%= String.format("%,.0f", (double) totalCash) %> Ar</div>
                    <div class="summary-label">💰 Caisse totale (ventes réalisées)</div>
                </div>
                <div class="summary-item">
                    <div class="summary-value" style="color: var(--teal);"><%= totalProperties > 0 ? String.format("%.1f", (double) totalViews / totalProperties) : 0 %></div>
                    <div class="summary-label"><%= TranslateUtil.t(lang, "views_per_property") %></div>
                </div>
            </div>
        </div>

    </main>
</div>

<script>
// Canvas Background - Maisons flottantes
(function(){
    const canvas = document.getElementById('bgCanvas');
    const ctx = canvas.getContext('2d');
    let W, H, houses = [];
    function resize(){ W = canvas.width = window.innerWidth; H = canvas.height = window.innerHeight; }
    resize(); window.addEventListener('resize', resize);
    function drawHouse(ctx, x, y, s, alpha, color){
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

// Initialisation des graphiques Chart.js
window.addEventListener('load', function() {
    setTimeout(function() {
        if (typeof Chart !== 'undefined') {
            var monthlyCanvas = document.getElementById('monthlyChart');
            if (monthlyCanvas) {
                var monthlyLabels = [<%= monthlyLabels %>];
                var monthlyData = [<%= monthlyData %>];
                new Chart(monthlyCanvas, {
                    type: 'line',
                    data: { labels: monthlyLabels, datasets: [{ label: '<%= TranslateUtil.t(lang, "properties_added") %>', data: monthlyData, borderColor: '#1f52d4', backgroundColor: 'rgba(31, 82, 212, 0.05)', tension: 0.3, fill: true, pointBackgroundColor: '#c8860a', pointBorderColor: '#fff', pointRadius: 5, pointHoverRadius: 7 }] },
                    options: { responsive: true, maintainAspectRatio: true, plugins: { legend: { position: 'top' } }, scales: { y: { beginAtZero: true, title: { display: true, text: '<%= TranslateUtil.t(lang, "number_of_properties") %>' } } } }
                });
            }
            var typeCanvas = document.getElementById('typeChart');
            if (typeCanvas) {
                var typeLabels = [<%= typeLabels %>];
                var typeData = [<%= typeData %>];
                var typeColorsArray = ['#1f52d4', '#c8860a', '#0e9e8a', '#e03060', '#7c3aed'];
                new Chart(typeCanvas, {
                    type: 'doughnut',
                    data: { labels: typeLabels, datasets: [{ data: typeData, backgroundColor: typeColorsArray, borderWidth: 0, hoverOffset: 10 }] },
                    options: { responsive: true, maintainAspectRatio: true, plugins: { legend: { position: 'bottom' }, tooltip: { callbacks: { label: function(context) { return context.label + ': ' + context.raw + ' biens'; } } } } }
                });
            }
            var messagesCanvas = document.getElementById('messagesChart');
            if (messagesCanvas) {
                var msgLabels = [<%= monthlyLabels %>];
                var msgData = [<%= msgMonthlyData %>];
                new Chart(messagesCanvas, {
                    type: 'line',
                    data: { labels: msgLabels, datasets: [{ label: '<%= TranslateUtil.t(lang, "messages_received") %>', data: msgData, borderColor: '#0e9e8a', backgroundColor: 'rgba(14, 158, 138, 0.05)', tension: 0.3, fill: true, pointBackgroundColor: '#e03060', pointBorderColor: '#fff', pointRadius: 5, pointHoverRadius: 7 }] },
                    options: { responsive: true, maintainAspectRatio: true, plugins: { legend: { position: 'top' } }, scales: { y: { beginAtZero: true, title: { display: true, text: '<%= TranslateUtil.t(lang, "number_of_messages") %>' } } } }
                });
            }
            var perfCanvas = document.getElementById('performanceChart');
            if (perfCanvas) {
                var perfLabels = [];
                var perfData = [];
                <% for (Map<String, Object> prop : topProperties) { String title = (String) prop.get("title"); if(title != null && !title.isEmpty()) { %>
                    perfLabels.push('<%= title.replace("'", "\\'") %>');
                    perfData.push(<%= prop.get("views") %>);
                <% } } %>
                if (perfLabels.length === 0) { perfLabels.push('<%= TranslateUtil.t(lang, "no_data") %>'); perfData.push(0); }
                new Chart(perfCanvas, {
                    type: 'bar',
                    data: { labels: perfLabels, datasets: [{ label: '<%= TranslateUtil.t(lang, "number_of_views") %>', data: perfData, backgroundColor: 'rgba(200, 134, 10, 0.7)', borderRadius: 8, barPercentage: 0.6 }] },
                    options: { responsive: true, maintainAspectRatio: true, plugins: { legend: { position: 'top' } }, scales: { y: { beginAtZero: true, title: { display: true, text: '<%= TranslateUtil.t(lang, "views") %>' } } } }
                });
            }
        }
    }, 200);
});

function loadReactionsStats() {
    fetch('${pageContext.request.contextPath}/immo/admin/get-reactions-stats.jsp')
        .then(function(response) { return response.json(); })
        .then(function(data) {
            var tbody = document.getElementById('reactionsTableBody');
            var totalBadge = document.getElementById('totalReactionsBadge');
            
            if (!data || data.length === 0) {
                tbody.innerHTML = '<tr><td colspan="8" style="text-align: center; padding: 40px;">📊 Aucune réaction pour le moment</td></tr>';
                if(totalBadge) totalBadge.textContent = '0 réactions';
                return;
            }
            
            var grandTotal = 0;
            var html = '';
            
            for(var i = 0; i < data.length; i++) {
                var property = data[i];
                var total = (property.jadore || 0) + (property.jaime || 0) + (property.haha || 0) + (property.colere || 0) + (property.triste || 0);
                grandTotal += total;
                
                var imageHtml = '';
                if(property.main_image && property.main_image !== 'null' && property.main_image !== null) {
                    var imagePath = '${pageContext.request.contextPath}/' + property.main_image;
                    imageHtml = '<img src="' + imagePath + '" style="width: 48px; height: 48px; border-radius: 8px; object-fit: cover; margin-right: 12px;" onerror="this.style.display=\'none\'; this.nextSibling.style.display=\'flex\';">' +
                                '<div style="width: 48px; height: 48px; border-radius: 8px; background: linear-gradient(135deg, var(--gold), var(--gold2)); display: none; align-items: center; justify-content: center; color: white; margin-right: 12px;"><i class="fas fa-home"></i></div>';
                } else {
                    imageHtml = '<div style="width: 48px; height: 48px; border-radius: 8px; background: linear-gradient(135deg, var(--gold), var(--gold2)); display: flex; align-items: center; justify-content: center; color: white; margin-right: 12px;"><i class="fas fa-home"></i></div>';
                }
                
                html += '<tr style="border-bottom: 1px solid var(--border);">' +
                    '<td style="padding: 12px;">' +
                    '<div style="display: flex; align-items: center;">' +
                    imageHtml +
                    '<div>' +
                    '<strong>' + escapeHtml(property.title) + '</strong>' +
                    '<br><small style="color: var(--soft);">' + escapeHtml(property.location) + '</small>' +
                    '</div>' +
                    '</div>' +
                    '<\/td>' +
                    '<td style="padding: 12px; text-align: center; color: #e03060;">❤️ ' + (property.jadore || 0) + '<\/td>' +
                    '<td style="padding: 12px; text-align: center; color: #1f52d4;">👍 ' + (property.jaime || 0) + '<\/td>' +
                    '<td style="padding: 12px; text-align: center; color: #c8860a;">😂 ' + (property.haha || 0) + '<\/td>' +
                    '<td style="padding: 12px; text-align: center; color: #dc2626;">😡 ' + (property.colere || 0) + '<\/td>' +
                    '<td style="padding: 12px; text-align: center; color: #6b5a3e;">😢 ' + (property.triste || 0) + '<\/td>' +
                    '<td style="padding: 12px; text-align: center; font-weight: bold;">' + total + '<\/td>' +
                    '<td style="padding: 12px; text-align: center;"><button onclick="showReactionDetails(' + property.id + ', \'' + escapeHtml(property.title) + '\')" style="background: var(--blue); color: white; border: none; padding: 6px 12px; border-radius: 8px; cursor: pointer;"><i class="fas fa-eye"></i> Voir<\/button><\/td>' +
                '<\/tr>';
            }
            
            tbody.innerHTML = html;
            if(totalBadge) totalBadge.textContent = grandTotal + ' réaction' + (grandTotal > 1 ? 's' : '');
        })
        .catch(function(error) {
            console.error('Erreur:', error);
            document.getElementById('reactionsTableBody').innerHTML = '<tr><td colspan="8" style="text-align: center; padding: 40px; color: red;">❌ Erreur de chargement</td></tr>';
        });
}

function escapeHtml(str) {
    if(!str) return '';
    return str.replace(/[&<>]/g, function(m) {
        if(m === '&') return '&amp;';
        if(m === '<') return '&lt;';
        if(m === '>') return '&gt;';
        return m;
    });
}

function showReactionDetails(propertyId, propertyTitle) {
    fetch('${pageContext.request.contextPath}/immo/admin/get-reaction-users.jsp?propertyId=' + propertyId)
        .then(function(response) { return response.json(); })
        .then(function(data) {
            var modal = document.getElementById('reactionModal');
            var content = document.getElementById('reactionModalContent');
            
            var html = '<div style="max-height: 500px; overflow-y: auto;">';
            html += '<h4 style="margin-bottom: 15px; font-family: Syne, sans-serif;">🏠 ' + escapeHtml(propertyTitle) + '</h4>';
            
            var reactionTypes = ['jadore', 'jaime', 'haha', 'colere', 'triste'];
            var emojis = ['❤️', '👍', '😂', '😡', '😢'];
            var labels = ["J'adore", "J'aime", "Haha", "Colère", "Triste"];
            var hasData = false;
            
            for(var r = 0; r < reactionTypes.length; r++) {
                var type = reactionTypes[r];
                var reactionData = data[type];
                
                if(reactionData && reactionData.users && reactionData.users.length > 0) {
                    hasData = true;
                    html += '<div style="margin-bottom: 20px; background: var(--surface2); border-radius: 16px; overflow: hidden;">';
                    html += '<div style="padding: 12px 16px; background: var(--surface); border-bottom: 1px solid var(--border);">';
                    html += '<strong style="font-size: 16px;">' + emojis[r] + ' ' + labels[r] + '</strong>';
                    html += ' <span style="background: var(--bleu-l); padding: 2px 8px; border-radius: 20px; font-size: 12px; margin-left: 8px;">' + reactionData.users.length + '</span>';
                    html += '</div>';
                    html += '<div style="padding: 12px;">';
                    
                    for(var u = 0; u < reactionData.users.length; u++) {
                        var user = reactionData.users[u];
                        
                        html += '<div style="display: flex; align-items: center; gap: 12px; padding: 10px; border-bottom: 1px solid var(--border);">';
                        
                        if(user.type === 'registered' && user.profile_pic && user.profile_pic !== '') {
                            html += '<img src="${pageContext.request.contextPath}/uploads/' + user.profile_pic + '" style="width: 40px; height: 40px; border-radius: 50%; object-fit: cover;">';
                        } else {
                            var bgColor = user.type === 'registered' ? 'linear-gradient(135deg, var(--bleu2), var(--bleu))' : 'linear-gradient(135deg, var(--gold), var(--gold2))';
                            html += '<div style="width: 40px; height: 40px; border-radius: 50%; background: ' + bgColor + '; display: flex; align-items: center; justify-content: center; font-family: Syne, sans-serif; font-weight: 800; font-size: 16px; color: white;">' + (user.initial || '?') + '</div>';
                        }
                        
                        html += '<div style="flex: 1;">';
                        html += '<div style="font-weight: 700; color: var(--tx);">' + escapeHtml(user.name) + '</div>';
                        
                        if(user.type === 'registered') {
                            if(user.email && user.email !== '') {
                                html += '<div style="font-size: 12px; color: var(--tx3);"><i class="fas fa-envelope"></i> ' + escapeHtml(user.email) + '</div>';
                            }
                            if(user.username && user.username !== '') {
                                html += '<div style="font-size: 11px; color: var(--tx3);"><i class="fas fa-at"></i> @' + escapeHtml(user.username) + '</div>';
                            }
                        } else {
                            html += '<div style="font-size: 12px; color: var(--tx3);"><i class="fas fa-globe"></i> Visiteur non connecté</div>';
                        }
                        
                        html += '</div>';
                        
                        if(user.type === 'registered') {
                            html += '<div style="background: var(--vert); color: white; padding: 2px 8px; border-radius: 20px; font-size: 10px; font-weight: 600;"><i class="fas fa-check-circle"></i> Connecté</div>';
                        } else {
                            html += '<div style="background: var(--tx3); color: white; padding: 2px 8px; border-radius: 20px; font-size: 10px; font-weight: 600;"><i class="fas fa-user-friends"></i> Invité</div>';
                        }
                        
                        html += '</div>';
                    }
                    
                    html += '</div></div>';
                }
            }
            
            if(!hasData) {
                html += '<div style="text-align: center; padding: 60px 20px; color: var(--tx3);">';
                html += '<i class="fas fa-heart-broken" style="font-size: 48px; margin-bottom: 16px; display: block;"></i>';
                html += '<p>Aucune réaction sur ce bien pour le moment</p>';
                html += '</div>';
            }
            
            html += '</div>';
            
            content.innerHTML = html;
            modal.style.display = 'flex';
        })
        .catch(function(error) {
            console.error('Erreur:', error);
            document.getElementById('reactionModalContent').innerHTML = '<div style="text-align: center; padding: 40px; color: red;"><i class="fas fa-exclamation-triangle"></i> Erreur lors du chargement</div>';
        });
}

function closeReactionModal() {
    document.getElementById('reactionModal').style.display = 'none';
}

document.addEventListener('DOMContentLoaded', loadReactionsStats);

function addReaction(messageId, type, userId) {
    console.log('Ajout réaction:', messageId, type, userId);
    
    var form = document.createElement('form');
    form.method = 'POST';
    form.action = 'addReaction';
    form.style.display = 'none';
    
    var input1 = document.createElement('input');
    input1.type = 'hidden';
    input1.name = 'messageId';
    input1.value = messageId;
    form.appendChild(input1);
    
    var input2 = document.createElement('input');
    input2.type = 'hidden';
    input2.name = 'reactionType';
    input2.value = type;
    form.appendChild(input2);
    
    var input3 = document.createElement('input');
    input3.type = 'hidden';
    input3.name = 'receiverId';
    input3.value = userId;
    form.appendChild(input3);
    
    document.body.appendChild(form);
    form.submit();
}

function toggleReaction(messageId, type, userId) {
    addReaction(messageId, type, userId);
}

//Empêche l'accès aux pages après déconnexion
if (performance.navigation.type === 2) {
 window.location.href = '${pageContext.request.contextPath}/login';
}

</script>

</body>
</html>