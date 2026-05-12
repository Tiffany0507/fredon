<%@ page language="java" contentType="text/html; charset=UTF-8"
	pageEncoding="UTF-8"%>
<%@ page import="java.util.*, java.text.*, java.sql.*" %>
<%@ page import="com.quickchat.model.User" %>
<%@ page import="com.quickchat.utils.TranslateUtil" %>

<%

response.setHeader("Cache-Control", "no-cache, no-store, must-revalidate");
response.setHeader("Pragma", "no-cache");
response.setHeader("Expires", "0");

    String lang = "fr";
    try {
        Class.forName("com.mysql.cj.jdbc.Driver");
        Connection langConn = DriverManager.getConnection("jdbc:mysql://localhost:3306/quickchat", "root", "");
        PreparedStatement langPs = langConn.prepareStatement("SELECT default_language FROM settings WHERE id=1");
        ResultSet langRs = langPs.executeQuery();
        if (langRs.next()) lang = langRs.getString("default_language");
        langRs.close(); langPs.close(); langConn.close();
    } catch(Exception e) {}

    Integer adminId = (Integer) session.getAttribute("adminId");
    User admin = (User) session.getAttribute("admin");

    if (adminId == null && admin == null) {
        response.sendRedirect(request.getContextPath() + "/login");
        return;
    }

    String DB_URL      = "jdbc:mysql://localhost:3306/quickchat";
    String DB_USER     = "root";
    String DB_PASSWORD = "";

    String statusFilter = request.getParameter("status");
    if (statusFilter == null) statusFilter = "all";

    List<Map<String, Object>> appointments = new ArrayList<>();
    int pendingCount   = 0;
    int confirmedCount = 0;
    int completedCount = 0;
    int cancelledCount = 0;
    
    int notifCount = 0;
    try {
        Class.forName("com.mysql.cj.jdbc.Driver");
        Connection connNotif = DriverManager.getConnection(DB_URL, DB_USER, DB_PASSWORD);
        PreparedStatement pstmtNotif = connNotif.prepareStatement("SELECT COUNT(*) FROM notifications WHERE user_id = ? AND is_read = 0");
        pstmtNotif.setInt(1, adminId);
        ResultSet rsNotif = pstmtNotif.executeQuery();
        if (rsNotif.next()) notifCount = rsNotif.getInt(1);
        rsNotif.close(); pstmtNotif.close(); connNotif.close();
    } catch(Exception e) {}

    try {
        Class.forName("com.mysql.cj.jdbc.Driver");
        Connection conn = DriverManager.getConnection(DB_URL, DB_USER, DB_PASSWORD);

        Statement stmtCount = conn.createStatement();
        ResultSet rsCount = stmtCount.executeQuery(
            "SELECT status, COUNT(*) AS cnt FROM appointments GROUP BY status");
        while (rsCount.next()) {
            String s = rsCount.getString("status");
            int    c = rsCount.getInt("cnt");
            if      ("pending".equals(s))   pendingCount   = c;
            else if ("confirmed".equals(s)) confirmedCount = c;
            else if ("completed".equals(s)) completedCount = c;
            else if ("cancelled".equals(s)) cancelledCount = c;
        }
        rsCount.close(); stmtCount.close();

        String baseSql =
            "SELECT a.*, " +
            "  p.title    AS property_title, " +
            "  p.location AS property_location, " +
            "  (SELECT pi.image_url FROM property_images pi " +
            "   WHERE pi.property_id = p.id AND pi.is_primary = 1 LIMIT 1) AS property_image, " +
            "  u.profile_pic AS client_pic " +
            "FROM appointments a " +
            "LEFT JOIN properties p ON a.property_id = p.id " +
            "LEFT JOIN users u ON u.email = a.client_email ";

        String sql = baseSql + "ORDER BY a.appointment_date DESC, a.appointment_time DESC";
        if (!statusFilter.equals("all")) {
            sql = baseSql + "WHERE a.status = ? ORDER BY a.appointment_date DESC, a.appointment_time DESC";
        }

        PreparedStatement pstmt = conn.prepareStatement(sql);
        if (!statusFilter.equals("all")) pstmt.setString(1, statusFilter);

        ResultSet rs = pstmt.executeQuery();
        while (rs.next()) {
            Map<String, Object> ap = new HashMap<>();
            ap.put("id",                rs.getInt("id"));
            ap.put("property_id",       rs.getInt("property_id"));
            ap.put("property_title",    rs.getString("property_title")    != null ? rs.getString("property_title")    : "Bien inconnu");
            ap.put("property_location", rs.getString("property_location") != null ? rs.getString("property_location") : "");
            ap.put("property_image",    rs.getString("property_image")    != null ? rs.getString("property_image")    : "");
            ap.put("client_name",       rs.getString("client_name")       != null ? rs.getString("client_name")       : "");
            ap.put("client_email",      rs.getString("client_email")      != null ? rs.getString("client_email")      : "");
            ap.put("client_phone",      rs.getString("client_phone")      != null ? rs.getString("client_phone")      : "");
            ap.put("client_pic",        rs.getString("client_pic")        != null ? rs.getString("client_pic")        : "");
            ap.put("appointment_date",  rs.getDate("appointment_date"));
            ap.put("appointment_time",  rs.getTime("appointment_time"));
            ap.put("status",            rs.getString("status"));
            ap.put("message",           rs.getString("message")    != null ? rs.getString("message")    : "");
            ap.put("admin_note",        rs.getString("admin_note") != null ? rs.getString("admin_note") : "");
            ap.put("created_at",        rs.getTimestamp("created_at"));
            appointments.add(ap);
        }
        rs.close(); pstmt.close(); conn.close();

    } catch (Exception e) {
        e.printStackTrace();
    }

    String adminName = session.getAttribute("adminUsername") != null
                        ? session.getAttribute("adminUsername").toString() : "Admin";
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
    
    SimpleDateFormat sdf2     = new SimpleDateFormat("dd/MM/yyyy");
    SimpleDateFormat sdfTime2 = new SimpleDateFormat("HH:mm");
%>
<!DOCTYPE html>
<html lang="<%= lang %>">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title><%= TranslateUtil.t(lang, "appointments") %> — Fredon Immobilier</title>
<link href="https://fonts.googleapis.com/css2?family=Syne:wght@400;600;700;800&family=DM+Sans:opsz,wght@9..40,300;9..40,400;9..40,500;9..40,600&display=swap" rel="stylesheet">
<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
<script src="https://cdnjs.cloudflare.com/ajax/libs/jspdf/2.5.1/jspdf.umd.min.js"></script>
<script src="https://cdnjs.cloudflare.com/ajax/libs/html2canvas/1.4.1/html2canvas.min.js"></script>
<style>
/* VOTRE STYLE RESTE IDENTIQUE - AUCUN CHANGEMENT */
*,*::before,*::after{box-sizing:border-box;margin:0;padding:0}
:root{
  --gold:#c8860a;--gold-l:#e8a220;--gold-pale:rgba(200,134,10,.08);
  --bleu:#1f52d4;--bleu2:#0e2d82;--bleu-l:rgba(31,82,212,.08);
  --vert:#059669;--rouge:#dc2626;--orange:#d97706;--violet:#7c3aed;
  --bg:#f8f4ee;--surface:#ffffff;--surface2:#f7f6f2;
  --border:rgba(0,0,0,.065);--border-h:rgba(0,0,0,.12);
  --tx:#0d0b08;--tx2:#6b5a3e;--tx3:#a89880;
  --sidebar-w:272px;
  --shadow:0 4px 24px rgba(14,45,130,.08);
  --shadow-md:0 8px 40px rgba(14,45,130,.12);
  --shadow-lg:0 20px 60px rgba(14,45,130,.16);
  --grad-brand:linear-gradient(135deg,#0e2d82,#1f52d4);
  --r-sm:8px;--r-md:14px;--r-lg:20px;--r-xl:26px;
}
body.dark-theme{
  --bg:#060c1a;--surface:#0d1626;--surface2:#111e35;
  --border:rgba(255,255,255,.06);--border-h:rgba(255,255,255,.12);
  --tx:#e0e8ff;--tx2:#6070a0;--tx3:#2a3555;
}
html,body{height:100%;font-family:'DM Sans',sans-serif;background:var(--bg);color:var(--tx);overflow-x:hidden;transition:background .3s,color .3s}
::-webkit-scrollbar{width:4px}
::-webkit-scrollbar-thumb{background:linear-gradient(var(--bleu),var(--gold));border-radius:99px}
.layout{display:flex;min-height:100vh}

.sidebar{width:var(--sidebar-w);min-width:var(--sidebar-w);background:linear-gradient(160deg,#0d1f5e 0%,#1a3aaa 45%,#0e2d82 75%,#0a1d58 100%);display:flex;flex-direction:column;position:fixed;left:0;top:0;bottom:0;z-index:100;box-shadow:8px 0 40px rgba(31,82,212,.18);overflow:hidden}
.sidebar-grid{position:absolute;inset:0;pointer-events:none;background-image:linear-gradient(rgba(255,255,255,.03) 1px,transparent 1px),linear-gradient(90deg,rgba(255,255,255,.03) 1px,transparent 1px);background-size:36px 36px}
.logo-area{padding:20px 18px 18px;border-bottom:1px solid rgba(255,255,255,.1);display:flex;align-items:center;gap:14px;position:relative;z-index:2}
.logo-img{width:68px;height:68px;object-fit:cover;border-radius:18px;box-shadow:0 6px 22px rgba(0,0,0,.45),0 0 0 2px rgba(255,255,255,.2);transition:transform .25s}
.logo-img:hover{transform:scale(1.05)}
.logo-name{font-family:'Syne',sans-serif;font-weight:800;font-size:24px;background:linear-gradient(120deg,#fff 0%,#cce8ff 50%,#fde9b0 100%);-webkit-background-clip:text;background-clip:text;color:transparent;display:block;line-height:1.1}
.logo-sub{font-size:10px;color:rgba(255,255,255,.6);letter-spacing:2.8px;text-transform:uppercase;margin-top:4px;display:block;font-weight:400}
.nav{flex:1;padding:18px 14px;display:flex;flex-direction:column;gap:2px;overflow-y:auto;position:relative;z-index:2}
.nav-section{font-size:9.5px;font-weight:700;letter-spacing:1.8px;text-transform:uppercase;color:rgba(255,255,255,.38);padding:14px 10px 6px}
.nav-item{display:flex;align-items:center;gap:11px;padding:11px 13px;border-radius:12px;color:rgba(255,255,255,.65);font-size:13.5px;font-weight:500;text-decoration:none;transition:all .22s}
.nav-item i{width:18px;font-size:14px;text-align:center}
.nav-item:hover{background:rgba(255,255,255,.1);color:#fff}
.nav-item.active{background:rgba(255,255,255,.14);color:#fff;border-left:3px solid var(--gold-l)}
.nav-item.logout{color:rgba(255,130,130,.7)}
.nav-item.logout:hover{background:rgba(239,68,68,.15);color:#fca5a5}
.user-bottom{padding:16px 14px;border-top:1px solid rgba(255,255,255,.1);display:flex;align-items:center;gap:10px;cursor:pointer;transition:all .22s;position:relative;z-index:2}
.user-bottom:hover{background:rgba(255,255,255,.08)}
.u-avatar{width:42px;height:42px;background:linear-gradient(135deg,var(--gold),var(--gold-l));border-radius:12px;display:flex;align-items:center;justify-content:center;font-weight:800;color:#fff;font-family:'Syne',sans-serif;font-size:16px;flex-shrink:0;overflow:hidden}
.u-avatar img{width:100%;height:100%;object-fit:cover}
.u-name{font-size:13.5px;font-weight:700;color:#fff}
.u-role{font-size:10.5px;color:rgba(255,255,255,.5);margin-top:1px}
.u-dot{width:8px;height:8px;background:#2ecfb4;border-radius:50%;box-shadow:0 0 8px #2ecfb4;margin-left:auto;flex-shrink:0}

.main{margin-left:var(--sidebar-w);flex:1;padding:32px 36px;min-height:100vh}
.top-bar{display:flex;justify-content:space-between;align-items:flex-start;margin-bottom:32px;flex-wrap:wrap;gap:16px}
.page-title h1{font-family:'Syne',sans-serif;font-size:28px;font-weight:800;color:var(--tx);letter-spacing:-.5px;display:flex;align-items:center;gap:10px}
.page-title h1 .title-icon{width:38px;height:38px;background:linear-gradient(135deg,var(--gold),var(--gold-l));border-radius:11px;display:flex;align-items:center;justify-content:center;color:#fff;font-size:16px;box-shadow:0 4px 14px rgba(200,134,10,.3);flex-shrink:0}
.page-title p{font-size:13px;color:var(--tx3);margin-top:5px;margin-left:48px}
.top-right{display:flex;align-items:center;gap:10px}
.notif-wrap{position:relative;text-decoration:none}
.icon-circle{width:40px;height:40px;background:var(--surface);border:1.5px solid rgba(200,134,10,.14);border-radius:12px;display:flex;align-items:center;justify-content:center;cursor:pointer;color:var(--tx2);font-size:16px;transition:all .22s;text-decoration:none}
.icon-circle:hover{border-color:var(--gold);color:var(--gold)}
.notif-pip{position:absolute;top:-2px;right:-2px;background:var(--rouge);color:white;font-size:10px;width:18px;height:18px;border-radius:50%;display:flex;align-items:center;justify-content:center;font-weight:bold}
.export-group{display:flex;gap:8px}
.export-btn{display:flex;align-items:center;gap:8px;padding:11px 20px;background:var(--grad-brand);color:#fff;border:none;border-radius:12px;font-family:'DM Sans',sans-serif;font-size:13px;font-weight:600;cursor:pointer;transition:all .2s;box-shadow:0 4px 14px rgba(31,82,212,.28)}
.export-btn:hover{transform:translateY(-2px);box-shadow:0 6px 20px rgba(31,82,212,.35)}
.export-pdf{background:linear-gradient(135deg,#dc2626,#b91c1c);box-shadow:0 4px 14px rgba(220,38,38,.25)}
.export-pdf:hover{box-shadow:0 6px 20px rgba(220,38,38,.35)}

.stats-row{display:grid;grid-template-columns:repeat(4,1fr);gap:18px;margin-bottom:28px}
.stat-card{background:var(--surface);border-radius:var(--r-xl);padding:22px 24px;border:1.5px solid var(--border);position:relative;overflow:hidden;cursor:pointer;transition:all .25s}
.stat-card::before{content:'';position:absolute;top:0;right:0;width:80px;height:80px;border-radius:0 var(--r-xl) 0 80px;opacity:.06}
.stat-card:hover{transform:translateY(-4px);box-shadow:var(--shadow-md)}
.stat-card.s-pending::before{background:var(--orange)}
.stat-card.s-confirmed::before{background:var(--vert)}
.stat-card.s-completed::before{background:var(--bleu)}
.stat-card.s-cancelled::before{background:var(--rouge)}
.stat-icon{width:44px;height:44px;border-radius:12px;display:flex;align-items:center;justify-content:center;font-size:18px;margin-bottom:14px}
.stat-icon.i-pending{background:rgba(217,119,6,.12);color:var(--orange)}
.stat-icon.i-confirmed{background:rgba(5,150,105,.12);color:var(--vert)}
.stat-icon.i-completed{background:rgba(31,82,212,.12);color:var(--bleu)}
.stat-icon.i-cancelled{background:rgba(220,38,38,.12);color:var(--rouge)}
.stat-num{font-family:'Syne',sans-serif;font-size:32px;font-weight:800;line-height:1}
.stat-num.c-pending{color:var(--orange)}
.stat-num.c-confirmed{color:var(--vert)}
.stat-num.c-completed{color:var(--bleu)}
.stat-num.c-cancelled{color:var(--rouge)}
.stat-lbl{font-size:12px;color:var(--tx3);margin-top:6px;font-weight:500}

.toolbar{background:var(--surface);border-radius:var(--r-xl);padding:18px 22px;margin-bottom:22px;display:flex;gap:14px;flex-wrap:wrap;align-items:center;border:1.5px solid var(--border);box-shadow:var(--shadow)}
.search-wrap{flex:1;min-width:220px;display:flex;align-items:center;gap:9px;background:var(--surface2);border:1.5px solid var(--border);border-radius:12px;padding:10px 14px}
.search-wrap:focus-within{border-color:rgba(31,82,212,.35);box-shadow:0 0 0 3px rgba(31,82,212,.08)}
.search-wrap i{color:var(--tx3);font-size:13px}
.search-wrap input{flex:1;border:none;background:transparent;color:var(--tx);font-family:'DM Sans',sans-serif;font-size:13px;outline:none}
.filter-select{padding:10px 14px;border:1.5px solid var(--border);border-radius:12px;font-size:13px;background:var(--surface2);color:var(--tx);cursor:pointer;font-family:'DM Sans',sans-serif;outline:none;appearance:none;background-image:url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='10' height='6' fill='none'%3E%3Cpath d='M1 1l4 4 4-4' stroke='%23a89880' stroke-width='1.5' stroke-linecap='round'/%3E%3C/svg%3E");background-repeat:no-repeat;background-position:right 12px center;padding-right:32px}
.toolbar-right{display:flex;align-items:center;gap:10px}
.view-toggle{display:flex;background:var(--surface2);border:1.5px solid var(--border);border-radius:10px;overflow:hidden}
.view-btn{padding:8px 12px;border:none;background:transparent;cursor:pointer;color:var(--tx3);font-size:13px}
.view-btn.active{background:var(--bleu);color:#fff}
.results-count{font-size:12px;color:var(--tx3);font-weight:500;white-space:nowrap}

.table-card{background:var(--surface);border-radius:var(--r-xl);border:1.5px solid var(--border);overflow:hidden;box-shadow:var(--shadow)}
.tbl-head{display:grid;grid-template-columns:2.5fr 2fr 1.4fr 1.2fr 1fr;background:var(--surface2);border-bottom:1.5px solid var(--border);padding:0 22px}
.tbl-th{padding:13px 10px;font-size:10.5px;font-weight:700;text-transform:uppercase;letter-spacing:1px;color:var(--tx3);cursor:pointer;display:flex;align-items:center;gap:5px}
.tbl-th:hover{color:var(--bleu)}
.tbl-body{display:flex;flex-direction:column}
.tbl-row{display:grid;grid-template-columns:2.5fr 2fr 1.4fr 1.2fr 1fr;padding:14px 22px;border-bottom:1px solid var(--border);align-items:center;cursor:pointer;transition:background .15s}
.tbl-row:hover{background:var(--gold-pale)}
.tbl-cell{padding:0 10px;font-size:13px;color:var(--tx)}
.prop-cell{display:flex;align-items:center;gap:11px}
.prop-img{width:42px;height:42px;border-radius:10px;object-fit:cover;flex-shrink:0}
.prop-img-placeholder{width:42px;height:42px;border-radius:10px;background:linear-gradient(135deg,var(--bleu2),var(--bleu));display:flex;align-items:center;justify-content:center;color:#fff;font-size:16px}
.prop-title{font-weight:600;font-size:13px}
.prop-loc{font-size:11px;color:var(--tx3);margin-top:2px;display:flex;align-items:center;gap:4px}
.client-cell{display:flex;align-items:center;gap:10px}
.client-avatar{width:36px;height:36px;border-radius:10px;display:flex;align-items:center;justify-content:center;font-family:'Syne',sans-serif;font-weight:800;font-size:13px;color:#fff;flex-shrink:0;overflow:hidden}
.client-avatar img{width:100%;height:100%;object-fit:cover}
.client-name{font-weight:600;font-size:13px}
.client-email{font-size:11px;color:var(--tx3);margin-top:1px}
.date-cell{display:flex;flex-direction:column;gap:2px}
.date-main{font-weight:700;font-size:13px}
.date-time{display:flex;align-items:center;gap:4px;font-size:11px;color:var(--tx3)}
.status-badge{display:inline-flex;align-items:center;gap:5px;padding:5px 11px;border-radius:20px;font-size:11px;font-weight:700}
.s-pending{background:rgba(217,119,6,.1);color:var(--orange)}
.s-confirmed{background:rgba(5,150,105,.1);color:var(--vert)}
.s-completed{background:rgba(31,82,212,.1);color:var(--bleu)}
.s-cancelled{background:rgba(220,38,38,.1);color:var(--rouge)}
.status-dot{width:6px;height:6px;border-radius:50%;display:inline-block}
.s-pending .status-dot{background:var(--orange);animation:blink 1.5s ease infinite}
.s-confirmed .status-dot{background:var(--vert)}
.s-completed .status-dot{background:var(--bleu)}
.s-cancelled .status-dot{background:var(--rouge)}
@keyframes blink{0%,100%{opacity:1}50%{opacity:.3}}
.actions-cell{display:flex;gap:5px;align-items:center}
.act-icon{width:30px;height:30px;border-radius:8px;border:none;cursor:pointer;display:flex;align-items:center;justify-content:center;font-size:12px}
.act-confirm{background:rgba(5,150,105,.1);color:var(--vert)}
.act-confirm:hover{background:var(--vert);color:#fff}
.act-complete{background:rgba(31,82,212,.1);color:var(--bleu)}
.act-complete:hover{background:var(--bleu);color:#fff}
.act-cancel{background:rgba(220,38,38,.1);color:var(--rouge)}
.act-cancel:hover{background:var(--rouge);color:#fff}
.act-view{background:rgba(200,134,10,.1);color:var(--gold)}
.act-view:hover{background:var(--gold);color:#fff}

#cardView{display:none}
.cards-grid{display:grid;grid-template-columns:repeat(auto-fill,minmax(320px,1fr));gap:20px}
.appt-card{background:var(--surface);border-radius:var(--r-xl);border:1.5px solid var(--border);overflow:hidden;cursor:pointer;transition:all .25s}
.appt-card:hover{transform:translateY(-4px);box-shadow:var(--shadow-md);border-color:rgba(200,134,10,.2)}
.card-top{padding:18px 18px 14px;border-bottom:1px solid var(--border);display:flex;gap:12px;align-items:flex-start}
.card-prop-img{width:52px;height:52px;border-radius:12px;object-fit:cover;flex-shrink:0}
.card-prop-img-ph{width:52px;height:52px;border-radius:12px;background:var(--grad-brand);display:flex;align-items:center;justify-content:center;color:#fff;font-size:20px}
.card-title{font-family:'Syne',sans-serif;font-weight:700;font-size:14px}
.card-loc{font-size:11.5px;color:var(--tx3);margin-top:3px;display:flex;align-items:center;gap:4px}
.card-status-wrap{margin-left:auto}
.card-body{padding:14px 18px}
.card-client-row{display:flex;align-items:center;gap:10px;margin-bottom:12px}
.card-client-av{width:38px;height:38px;border-radius:10px;display:flex;align-items:center;justify-content:center;font-family:'Syne',sans-serif;font-weight:800;font-size:13px;color:#fff;flex-shrink:0;overflow:hidden}
.card-client-av img{width:100%;height:100%;object-fit:cover}
.card-client-name{font-weight:600;font-size:13px}
.card-client-email{font-size:11px;color:var(--tx3);margin-top:1px}
.card-datetime{display:flex;align-items:center;gap:8px;padding:10px 12px;background:var(--surface2);border-radius:11px;margin-bottom:12px}
.card-datetime i{color:var(--gold);font-size:13px}
.card-datetime-val{font-weight:600;font-size:13px}
.card-datetime-sub{font-size:11px;color:var(--tx3)}
.card-actions{display:flex;gap:8px;padding-top:12px;border-top:1px solid var(--border)}
.card-btn{flex:1;padding:9px;border-radius:10px;border:none;cursor:pointer;font-size:12px;font-weight:700}
.cb-confirm{background:rgba(5,150,105,.1);color:var(--vert)}
.cb-confirm:hover{background:var(--vert);color:#fff}
.cb-complete{background:rgba(31,82,212,.1);color:var(--bleu)}
.cb-complete:hover{background:var(--bleu);color:#fff}
.cb-cancel{background:rgba(220,38,38,.1);color:var(--rouge)}
.cb-cancel:hover{background:var(--rouge);color:#fff}
.cb-view{background:rgba(200,134,10,.1);color:var(--gold)}
.cb-view:hover{background:var(--gold);color:#fff}

.empty-state{padding:70px 40px;text-align:center;color:var(--tx3)}
.empty-icon{font-size:52px;opacity:.2;display:block;margin-bottom:16px}
.empty-title{font-family:'Syne',sans-serif;font-size:18px;font-weight:700;color:var(--tx2);margin-bottom:8px}

.modal-overlay{display:none;position:fixed;inset:0;background:rgba(0,0,0,.6);backdrop-filter:blur(10px);z-index:5000;align-items:center;justify-content:center;padding:20px}
.modal-overlay.open{display:flex}
.modal-box{background:var(--surface);border-radius:var(--r-xl);width:520px;max-width:100%;max-height:88vh;overflow-y:auto;box-shadow:var(--shadow-lg);border:1.5px solid var(--border-h)}
.modal-header{padding:22px 24px 18px;border-bottom:1px solid var(--border);display:flex;justify-content:space-between;align-items:center;position:sticky;top:0;background:var(--surface);z-index:1}
.modal-header h3{font-family:'Syne',sans-serif;font-size:17px;font-weight:700;display:flex;align-items:center;gap:9px}
.modal-close{width:32px;height:32px;border-radius:50%;background:var(--surface2);border:1px solid var(--border);cursor:pointer;display:flex;align-items:center;justify-content:center;color:var(--tx3);font-size:14px}
.modal-close:hover{background:rgba(220,38,38,.1);color:var(--rouge)}
.modal-body{padding:22px 24px}
.client-profile-header{display:flex;align-items:center;gap:16px;padding:18px;background:var(--surface2);border-radius:var(--r-lg);margin-bottom:20px;border:1px solid var(--border)}
.client-profile-av{width:72px;height:72px;border-radius:18px;background:linear-gradient(135deg,#7c3aed,#2563eb);display:flex;align-items:center;justify-content:center;font-family:'Syne',sans-serif;font-weight:800;font-size:26px;color:#fff;flex-shrink:0;overflow:hidden}
.client-profile-av img{width:100%;height:100%;object-fit:cover}
.client-profile-name{font-family:'Syne',sans-serif;font-size:18px;font-weight:700}
.client-profile-email{font-size:13px;color:var(--tx3);margin-top:3px}
.modal-section{margin-bottom:18px}
.modal-section-title{font-size:10px;font-weight:700;letter-spacing:1.5px;text-transform:uppercase;color:var(--tx3);margin-bottom:10px}
.info-row{display:flex;align-items:flex-start;gap:11px;padding:11px 0;border-bottom:1px solid var(--border)}
.info-row:last-child{border-bottom:none}
.info-icon{width:32px;height:32px;border-radius:9px;background:var(--surface2);border:1px solid var(--border);display:flex;align-items:center;justify-content:center;color:var(--bleu);font-size:13px}
.info-label{font-size:11px;color:var(--tx3);font-weight:600;text-transform:uppercase;letter-spacing:.5px}
.info-value{font-size:13.5px;color:var(--tx);font-weight:500;margin-top:2px}
.message-box{background:var(--surface2);border:1px solid var(--border);border-radius:12px;padding:13px 15px;font-size:13px;color:var(--tx2);line-height:1.6;font-style:italic}
.modal-footer{padding:16px 24px 20px;display:flex;gap:10px;justify-content:flex-end;border-top:1px solid var(--border)}
.mf-btn{padding:10px 20px;border-radius:11px;border:none;font-weight:700;font-size:13px;cursor:pointer}
.mf-primary{background:var(--grad-brand);color:#fff;box-shadow:0 4px 14px rgba(31,82,212,.25)}
.mf-secondary{background:var(--surface2);color:var(--tx2);border:1px solid var(--border)}
.mf-danger{background:rgba(220,38,38,.1);color:var(--rouge);border:1px solid rgba(220,38,38,.15)}
.mf-danger:hover{background:var(--rouge);color:#fff}
.mf-success{background:rgba(5,150,105,.1);color:var(--vert);border:1px solid rgba(5,150,105,.15)}
.mf-success:hover{background:var(--vert);color:#fff}

.toast{position:fixed;bottom:22px;right:22px;background:var(--surface);border:1.5px solid var(--border-h);border-left:3px solid var(--bleu);border-radius:12px;padding:11px 18px;font-size:13px;font-weight:500;color:var(--tx2);box-shadow:var(--shadow-md);z-index:9999;display:flex;align-items:center;gap:9px;transform:translateY(80px);opacity:0;transition:all .3s cubic-bezier(.34,1.56,.64,1)}
.toast.show{transform:translateY(0);opacity:1}
.toast i{color:var(--bleu)}
.toast.t-error{border-left-color:var(--rouge)}.toast.t-error i{color:var(--rouge)}
.toast.t-success{border-left-color:var(--vert)}.toast.t-success i{color:var(--vert)}

/* MODAL PROFIL AMÉLIORÉ */
.profile-modal{max-width:520px;width:100%;background:var(--surface);border-radius:28px;overflow:hidden}
.pm-header{background:linear-gradient(135deg,#0d1f5e,#1a3aaa);padding:24px 28px;display:flex;justify-content:space-between;align-items:flex-start}
.pm-header h2{color:white;font-family:'Syne',sans-serif;font-size:20px;margin:0}
.pm-header p{color:rgba(255,255,255,0.6);font-size:12px;margin:4px 0 0}
.pm-close{width:32px;height:32px;background:rgba(255,255,255,0.1);border-radius:10px;display:flex;align-items:center;justify-content:center;cursor:pointer;color:white;border:none;transition:all 0.2s}
.pm-close:hover{background:rgba(239,68,68,0.4)}
.pm-body{padding:28px}
.pm-avatar-area{display:flex;align-items:center;gap:18px;margin-bottom:28px;padding-bottom:20px;border-bottom:1px solid rgba(200,134,10,0.1)}
.pm-avatar{width:70px;height:70px;border-radius:20px;background:linear-gradient(135deg,var(--gold),var(--gold-l));display:flex;align-items:center;justify-content:center;font-size:28px;font-weight:800;color:white;position:relative;overflow:hidden}
.pm-avatar img{width:100%;height:100%;object-fit:cover}
.pm-avatar-edit{position:absolute;bottom:-4px;right:-4px;width:28px;height:28px;background:var(--gold);border-radius:10px;display:flex;align-items:center;justify-content:center;cursor:pointer;border:2px solid white;font-size:12px;color:white;transition:all 0.2s}
.pm-avatar-edit:hover{transform:scale(1.05);background:var(--gold-l)}
.pm-avatar-info h4{font-size:16px;font-weight:700;color:var(--tx);margin:0}
.pm-avatar-info span{font-size:11px;color:var(--tx3);background:rgba(200,134,10,0.1);padding:3px 10px;border-radius:20px}
.pm-field{margin-bottom:18px}
.pm-field label{display:flex;align-items:center;gap:6px;font-size:11px;font-weight:700;color:var(--tx2);text-transform:uppercase;margin-bottom:6px}
.pm-field label i{color:var(--gold);font-size:11px}
.pm-field input,.pm-field select{width:100%;padding:11px 14px;border:1.5px solid rgba(200,134,10,0.15);border-radius:14px;font-size:13px;background:var(--surface2);color:var(--tx);outline:none;transition:all 0.2s}
.pm-field input:focus,.pm-field select:focus{border-color:var(--bleu);box-shadow:0 0 0 3px rgba(31,82,212,0.1)}
.pm-field input:read-only{background:var(--bg);cursor:not-allowed;opacity:0.7}
.pm-pw-wrapper{position:relative}
.pm-pw-wrapper input{padding-right:42px}
.pm-pw-toggle{position:absolute;right:12px;top:50%;transform:translateY(-50%);background:none;border:none;color:var(--tx3);cursor:pointer;font-size:14px}
.pm-pw-toggle:hover{color:var(--gold)}
.pm-divider{margin:24px 0 18px;text-align:center;position:relative}
.pm-divider::before{content:'';position:absolute;left:0;top:50%;width:100%;height:1px;background:linear-gradient(90deg,transparent,rgba(200,134,10,0.2),transparent)}
.pm-divider span{background:var(--surface);padding:0 12px;font-size:10px;font-weight:700;color:var(--tx2);position:relative}
.pm-footer{padding:18px 28px 24px;border-top:1px solid rgba(200,134,10,0.08);display:flex;justify-content:flex-end;gap:12px;background:var(--surface2)}
.pm-btn{padding:10px 20px;border-radius:14px;font-size:13px;font-weight:600;cursor:pointer;border:none;transition:all 0.2s;display:inline-flex;align-items:center;gap:6px}
.pm-save{background:linear-gradient(115deg,var(--gold),var(--gold-l));color:white;box-shadow:0 4px 12px rgba(200,134,10,0.3)}
.pm-save:hover{transform:translateY(-1px);box-shadow:0 6px 16px rgba(200,134,10,0.4)}
.pm-cancel{background:var(--bg);color:var(--tx2);border:1.5px solid rgba(200,134,10,0.15)}
.pm-cancel:hover{border-color:var(--rouge);color:var(--rouge)}

@media(max-width:1024px){.tbl-head,.tbl-row{grid-template-columns:2fr 1.8fr 1.3fr 1.2fr 1fr}}
@media(max-width:768px){.sidebar{transform:translateX(-100%)}.main{margin-left:0;padding:20px}.stats-row{grid-template-columns:repeat(2,1fr)}}
@media(max-width:520px){.stats-row{grid-template-columns:1fr}}
</style>
</head>
<body>
<script>
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

(function() {
    var theme = localStorage.getItem('fredon_theme') || 'light';
    if (theme === 'dark') {
        document.body.classList.add('dark-theme');
    }
})();
</script>
<div class="layout">

  <aside class="sidebar">
    <div class="sidebar-grid"></div>
    <div class="logo-area">
      <img src="${pageContext.request.contextPath}/immo/admin/images/Logo.jpg" alt="Fredon" class="logo-img" onmouseover="this.style.transform='scale(1.05)'" onmouseout="this.style.transform='scale(1)'">
      <div>
        <span class="logo-name">Fredon</span>
        <div class="logo-sub">Agence Immobilière</div>
      </div>
    </div>
    <nav class="nav">
      <div class="nav-section"><%= TranslateUtil.t(lang, "principal") %></div>
      <a href="${pageContext.request.contextPath}/admin/dashboard" class="nav-item"><i class="fas fa-chart-line"></i> <%= TranslateUtil.t(lang, "dashboard") %></a>
      <a href="${pageContext.request.contextPath}/admin/add-property" class="nav-item"><i class="fas fa-plus-circle"></i> <%= TranslateUtil.t(lang, "add_property") %></a>
      <a href="${pageContext.request.contextPath}/chat" class="nav-item"><i class="fas fa-comments"></i> <%= TranslateUtil.t(lang, "messages") %></a>
      <div class="nav-section"><%= TranslateUtil.t(lang, "management") %></div>
      <a href="${pageContext.request.contextPath}/admin/clients" class="nav-item"><i class="fas fa-users"></i> <%= TranslateUtil.t(lang, "clients") %></a>
      <a href="${pageContext.request.contextPath}/admin/appointments" class="nav-item active"><i class="fas fa-calendar-check"></i> <%= TranslateUtil.t(lang, "appointments") %></a>
      <a href="${pageContext.request.contextPath}/admin/statistics" class="nav-item"><i class="fas fa-chart-pie"></i> <%= TranslateUtil.t(lang, "statistics") %></a>
      <div class="nav-section"><%= TranslateUtil.t(lang, "system") %></div>
      <a href="${pageContext.request.contextPath}/admin/setting" class="nav-item"><i class="fas fa-cog"></i> <%= TranslateUtil.t(lang, "settings") %></a>
      <a href="${pageContext.request.contextPath}/" class="nav-item"><i class="fas fa-globe"></i> <%= TranslateUtil.t(lang, "view_site") %></a>
      <a href="${pageContext.request.contextPath}/logout" class="nav-item logout"><i class="fas fa-sign-out-alt"></i> <%= TranslateUtil.t(lang, "logout") %></a>
    </nav>
    <div class="user-bottom" onclick="openProfileModal()">
      <div class="u-avatar">
        <% if (adminProfilePic != null && !adminProfilePic.isEmpty()) { %>
          <img src="${pageContext.request.contextPath}/avatars/<%= adminProfilePic %>" style="width:100%;height:100%;object-fit:cover;border-radius:12px;">
        <% } else { %>
          <%= adminInitial %>
        <% } %>
      </div>
      <div class="u-info"><div class="u-name"><%= adminName %></div><div class="u-role"><%= TranslateUtil.t(lang, "admin") %></div></div>
      <div class="u-dot"></div>
    </div>
  </aside>

  <main class="main">
    <div class="top-bar">
      <div class="page-title">
        <h1><div class="title-icon"><i class="fas fa-calendar-check"></i></div> <%= TranslateUtil.t(lang, "appointments_management") %></h1>
        <p><%= TranslateUtil.t(lang, "track_appointments") %></p>
      </div>
      <div class="top-right">
        <a href="${pageContext.request.contextPath}/admin/notifications" class="notif-wrap">
          <div class="icon-circle" style="position: relative;">
            <i class="fas fa-bell"></i>
            <% if (notifCount > 0) { %>
            <span class="notif-pip"><%= notifCount > 9 ? "9+" : notifCount %></span>
            <% } %>
          </div>
        </a>
        <div class="export-group">
          <button class="export-btn" onclick="exportCSV()"><i class="fas fa-download"></i> CSV</button>
          <button class="export-btn export-pdf" onclick="exportPDF()"><i class="fas fa-file-pdf"></i> PDF</button>
        </div>
      </div>
    </div>

    <div class="stats-row">
      <div class="stat-card s-pending" onclick="filterByStatus('pending')" id="card-pending">
        <div class="stat-icon i-pending"><i class="fas fa-clock"></i></div>
        <div class="stat-num c-pending"><%= pendingCount %></div>
        <div class="stat-lbl"><%= TranslateUtil.t(lang, "appointment_pending") %></div>
      </div>
      <div class="stat-card s-confirmed" onclick="filterByStatus('confirmed')" id="card-confirmed">
        <div class="stat-icon i-confirmed"><i class="fas fa-check-circle"></i></div>
        <div class="stat-num c-confirmed"><%= confirmedCount %></div>
        <div class="stat-lbl"><%= TranslateUtil.t(lang, "appointment_confirmed") %></div>
      </div>
      <div class="stat-card s-completed" onclick="filterByStatus('completed')" id="card-completed">
        <div class="stat-icon i-completed"><i class="fas fa-flag-checkered"></i></div>
        <div class="stat-num c-completed"><%= completedCount %></div>
        <div class="stat-lbl"><%= TranslateUtil.t(lang, "appointment_completed") %></div>
      </div>
      <div class="stat-card s-cancelled" onclick="filterByStatus('cancelled')" id="card-cancelled">
        <div class="stat-icon i-cancelled"><i class="fas fa-times-circle"></i></div>
        <div class="stat-num c-cancelled"><%= cancelledCount %></div>
        <div class="stat-lbl"><%= TranslateUtil.t(lang, "appointment_cancelled") %></div>
      </div>
    </div>

    <div class="toolbar">
      <div class="search-wrap"><i class="fas fa-search"></i><input type="text" id="searchInput" placeholder="<%= TranslateUtil.t(lang, "search_appointments") %>" oninput="applyFilters()"></div>
      <select class="filter-select" id="statusSel" onchange="applyFilters()">
        <option value="all"><%= TranslateUtil.t(lang, "all_statuses") %></option>
        <option value="pending"><%= TranslateUtil.t(lang, "appointment_pending") %></option>
        <option value="confirmed"><%= TranslateUtil.t(lang, "appointment_confirmed") %></option>
        <option value="completed"><%= TranslateUtil.t(lang, "appointment_completed") %></option>
        <option value="cancelled"><%= TranslateUtil.t(lang, "appointment_cancelled") %></option>
      </select>
      <select class="filter-select" id="sortSel" onchange="applyFilters()">
        <option value="date-desc"><%= TranslateUtil.t(lang, "sort_date_desc") %></option>
        <option value="date-asc"><%= TranslateUtil.t(lang, "sort_date_asc") %></option>
        <option value="name-asc"><%= TranslateUtil.t(lang, "sort_name_asc") %></option>
        <option value="name-desc"><%= TranslateUtil.t(lang, "sort_name_desc") %></option>
        <option value="property-asc"><%= TranslateUtil.t(lang, "sort_property_asc") %></option>
      </select>
      <div class="toolbar-right"><span class="results-count" id="resultsCount"></span>
        <div class="view-toggle"><button class="view-btn active" id="btnTable" onclick="setView('table')" title="<%= TranslateUtil.t(lang, "table_view") %>"><i class="fas fa-list"></i></button>
        <button class="view-btn" id="btnCards" onclick="setView('cards')" title="<%= TranslateUtil.t(lang, "card_view") %>"><i class="fas fa-th-large"></i></button></div>
      </div>
    </div>

    <div id="tableView"><div class="table-card"><div class="tbl-head">
      <div class="tbl-th" onclick="sortBy('property')"><i class="fas fa-home"></i> <%= TranslateUtil.t(lang, "property") %><i class="fas fa-sort sort-ico"></i></div>
      <div class="tbl-th" onclick="sortBy('client')"><i class="fas fa-user"></i> <%= TranslateUtil.t(lang, "client") %><i class="fas fa-sort sort-ico"></i></div>
      <div class="tbl-th" onclick="sortBy('date')"><i class="fas fa-calendar"></i> <%= TranslateUtil.t(lang, "date") %><i class="fas fa-sort sort-ico"></i></div>
      <div class="tbl-th"><%= TranslateUtil.t(lang, "status") %></div>
      <div class="tbl-th"><%= TranslateUtil.t(lang, "actions") %></div>
    </div><div class="tbl-body" id="tableBody">
    <% if (appointments.isEmpty()) { %>
      <div class="empty-state"><span class="empty-icon">📭</span><div class="empty-title"><%= TranslateUtil.t(lang, "no_appointments") %></div><p style="font-size:13px;"><%= TranslateUtil.t(lang, "no_appointments_desc") %></p></div>
    <% } else { for (Map<String, Object> a : appointments) { String status = (String) a.get("status"); String clientName = (String) a.get("client_name"); String clientEmail = (String) a.get("client_email"); String clientPhone = (String) a.get("client_phone"); String clientPic = (String) a.get("client_pic"); String propTitle = (String) a.get("property_title"); String propLoc = (String) a.get("property_location"); String propImg = (String) a.get("property_image"); String message = (String) a.get("message"); int appointId = (Integer) a.get("id"); String clientInitial = clientName != null && !clientName.isEmpty() ? String.valueOf(clientName.charAt(0)).toUpperCase() : "?"; String statusLabel = ""; if ("pending".equals(status)) statusLabel = TranslateUtil.t(lang, "appointment_pending"); else if ("confirmed".equals(status)) statusLabel = TranslateUtil.t(lang, "appointment_confirmed"); else if ("completed".equals(status)) statusLabel = TranslateUtil.t(lang, "appointment_completed"); else if ("cancelled".equals(status)) statusLabel = TranslateUtil.t(lang, "appointment_cancelled"); String dateStr = a.get("appointment_date") != null ? sdf2.format((java.sql.Date)a.get("appointment_date")) : "-"; String timeStr = a.get("appointment_time") != null ? sdfTime2.format((java.sql.Time)a.get("appointment_time")) : ""; String rawDate = a.get("appointment_date") != null ? a.get("appointment_date").toString() : ""; String[] grads = {"linear-gradient(135deg,#7c3aed,#2563eb)","linear-gradient(135deg,#0e9e8a,#1f52d4)","linear-gradient(135deg,#e03060,#7c3aed)","linear-gradient(135deg,#d97706,#dc2626)","linear-gradient(135deg,#059669,#0e9e8a)"}; int gi = clientInitial.charAt(0) % grads.length; %>
      <div class="tbl-row" data-id="<%= appointId %>" data-status="<%= status %>" data-client="<%= clientName.toLowerCase() %>" data-property="<%= propTitle.toLowerCase() %>" data-date="<%= rawDate %>" data-name="<%= clientName %>" data-email="<%= clientEmail %>" data-phone="<%= clientPhone %>" data-message="<%= message.replace("\"", "&quot;").replace("\n", " ") %>" data-proptitle="<%= propTitle %>" data-proploc="<%= propLoc %>" data-datestr="<%= dateStr %>" data-timestr="<%= timeStr %>" data-propimg="<%= propImg %>" data-clientpic="<%= clientPic %>" onclick="showDetailsFromRow(this)">
        <div class="tbl-cell"><div class="prop-cell"><% if (propImg != null && !propImg.isEmpty()) { %><img class="prop-img" src="${pageContext.request.contextPath}/<%= propImg %>" alt="" onerror="this.style.display='none';this.nextElementSibling.style.display='flex'"><div class="prop-img-placeholder" style="display:none"><i class="fas fa-home"></i></div><% } else { %><div class="prop-img-placeholder"><i class="fas fa-home"></i></div><% } %><div><div class="prop-title" title="<%= propTitle %>"><%= propTitle %></div><div class="prop-loc"><i class="fas fa-map-marker-alt" style="font-size:9px;"></i><%= propLoc.length()>25?propLoc.substring(0,25)+"…":propLoc %></div></div></div></div>
        <div class="tbl-cell"><div class="client-cell"><div class="client-avatar" style="background:<%= grads[gi] %>"><% if (clientPic != null && !clientPic.isEmpty()) { %><img src="${pageContext.request.contextPath}/uploads/<%= clientPic %>" alt="<%= clientInitial %>" onerror="this.style.display='none';this.parentElement.textContent='<%= clientInitial %>'"><% } else { %><%= clientInitial %><% } %></div><div><div class="client-name"><%= clientName %></div><div class="client-email"><%= clientEmail %></div></div></div></div>
        <div class="tbl-cell"><div class="date-cell"><div class="date-main"><%= dateStr %></div><div class="date-time"><i class="fas fa-clock" style="font-size:10px;"></i> <%= timeStr %>h</div></div></div>
        <div class="tbl-cell"><span class="status-badge s-<%= status %>"><span class="status-dot"></span> <%= statusLabel %></span></div>
        <div class="tbl-cell"><div class="actions-cell" onclick="event.stopPropagation()"><% if ("pending".equals(status)) { %><button class="act-icon act-confirm" title="<%= TranslateUtil.t(lang, "confirm") %>" onclick="updateStatus(<%= appointId %>,'confirmed')"><i class="fas fa-check"></i></button><button class="act-icon act-cancel" title="<%= TranslateUtil.t(lang, "cancel") %>" onclick="updateStatus(<%= appointId %>,'cancelled')"><i class="fas fa-times"></i></button><% } else if ("confirmed".equals(status)) { %><button class="act-icon act-complete" title="<%= TranslateUtil.t(lang, "complete") %>" onclick="updateStatus(<%= appointId %>,'completed')"><i class="fas fa-flag-checkered"></i></button><button class="act-icon act-cancel" title="<%= TranslateUtil.t(lang, "cancel") %>" onclick="updateStatus(<%= appointId %>,'cancelled')"><i class="fas fa-times"></i></button><% } %><button class="act-icon act-view" title="<%= TranslateUtil.t(lang, "view_details") %>"><i class="fas fa-eye"></i></button></div></div>
      </div>
    <% } } %>
    </div></div></div>

    <div id="cardView" style="display:none"><div class="cards-grid" id="cardsGrid">
    <% if (!appointments.isEmpty()) { for (Map<String, Object> a : appointments) { String status = (String) a.get("status"); String clientName = (String) a.get("client_name"); String clientEmail = (String) a.get("client_email"); String clientPhone = (String) a.get("client_phone"); String clientPic = (String) a.get("client_pic"); String propTitle = (String) a.get("property_title"); String propLoc = (String) a.get("property_location"); String propImg = (String) a.get("property_image"); String message = (String) a.get("message"); int appointId = (Integer) a.get("id"); String clientInitial = clientName != null && !clientName.isEmpty() ? String.valueOf(clientName.charAt(0)).toUpperCase() : "?"; String statusLabel = ""; if ("pending".equals(status)) statusLabel = TranslateUtil.t(lang, "appointment_pending"); else if ("confirmed".equals(status)) statusLabel = TranslateUtil.t(lang, "appointment_confirmed"); else if ("completed".equals(status)) statusLabel = TranslateUtil.t(lang, "appointment_completed"); else if ("cancelled".equals(status)) statusLabel = TranslateUtil.t(lang, "appointment_cancelled"); String dateStr = a.get("appointment_date") != null ? sdf2.format((java.sql.Date)a.get("appointment_date")) : "-"; String timeStr = a.get("appointment_time") != null ? sdfTime2.format((java.sql.Time)a.get("appointment_time")) : ""; String rawDate = a.get("appointment_date") != null ? a.get("appointment_date").toString() : ""; String[] grads2 = {"linear-gradient(135deg,#7c3aed,#2563eb)","linear-gradient(135deg,#0e9e8a,#1f52d4)","linear-gradient(135deg,#e03060,#7c3aed)","linear-gradient(135deg,#d97706,#dc2626)","linear-gradient(135deg,#059669,#0e9e8a)"}; int gi2 = clientInitial.charAt(0) % grads2.length; %>
      <div class="appt-card" data-id="<%= appointId %>" data-status="<%= status %>" data-client="<%= clientName.toLowerCase() %>" data-property="<%= propTitle.toLowerCase() %>" data-date="<%= rawDate %>" data-name="<%= clientName %>" data-email="<%= clientEmail %>" data-phone="<%= clientPhone %>" data-message="<%= message.replace("\"", "&quot;").replace("\n", " ") %>" data-proptitle="<%= propTitle %>" data-proploc="<%= propLoc %>" data-datestr="<%= dateStr %>" data-timestr="<%= timeStr %>" data-propimg="<%= propImg %>" data-clientpic="<%= clientPic %>" onclick="showDetailsFromRow(this)">
        <div class="card-top"><% if (propImg != null && !propImg.isEmpty()) { %><img class="card-prop-img" src="${pageContext.request.contextPath}/<%= propImg %>" alt="" onerror="this.style.display='none';this.nextElementSibling.style.display='flex'"><div class="card-prop-img-ph" style="display:none"><i class="fas fa-home"></i></div><% } else { %><div class="card-prop-img-ph"><i class="fas fa-home"></i></div><% } %><div style="flex:1;min-width:0"><div class="card-title"><%= propTitle.length()>30?propTitle.substring(0,30)+"…":propTitle %></div><div class="card-loc"><i class="fas fa-map-marker-alt" style="font-size:9px;"></i><%= propLoc.length()>28?propLoc.substring(0,28)+"…":propLoc %></div></div><div class="card-status-wrap"><span class="status-badge s-<%= status %>"><span class="status-dot"></span><%= statusLabel %></span></div></div>
        <div class="card-body"><div class="card-client-row"><div class="card-client-av" style="background:<%= grads2[gi2] %>"><% if (clientPic != null && !clientPic.isEmpty()) { %><img src="${pageContext.request.contextPath}/uploads/<%= clientPic %>" alt="<%= clientInitial %>" onerror="this.style.display='none';this.parentElement.textContent='<%= clientInitial %>'"><% } else { %><%= clientInitial %><% } %></div><div><div class="card-client-name"><%= clientName %></div><div class="card-client-email"><%= clientEmail %></div></div></div><div class="card-datetime"><i class="fas fa-calendar-alt"></i><div><div class="card-datetime-val"><%= dateStr %> à <%= timeStr %>h</div><div class="card-datetime-sub"><i class="fas fa-clock" style="font-size:9px;"></i> <%= TranslateUtil.t(lang, "scheduled_visit") %></div></div></div><div class="card-actions" onclick="event.stopPropagation()"><% if ("pending".equals(status)) { %><button class="card-btn cb-confirm" onclick="updateStatus(<%= appointId %>,'confirmed')"><i class="fas fa-check"></i> <%= TranslateUtil.t(lang, "confirm") %></button><button class="card-btn cb-cancel" onclick="updateStatus(<%= appointId %>,'cancelled')"><i class="fas fa-times"></i> <%= TranslateUtil.t(lang, "cancel") %></button><% } else if ("confirmed".equals(status)) { %><button class="card-btn cb-complete" onclick="updateStatus(<%= appointId %>,'completed')"><i class="fas fa-flag-checkered"></i> <%= TranslateUtil.t(lang, "complete") %></button><button class="card-btn cb-cancel" onclick="updateStatus(<%= appointId %>,'cancelled')"><i class="fas fa-times"></i> <%= TranslateUtil.t(lang, "cancel") %></button><% } else { %><button class="card-btn cb-view" style="flex:1"><i class="fas fa-eye"></i> <%= TranslateUtil.t(lang, "view_details") %></button><% } %></div></div>
      </div>
    <% } } %>
    </div></div>
  </main>
</div>

<div id="detailModal" class="modal-overlay"><div class="modal-box"><div class="modal-header"><h3><i class="fas fa-calendar-check" style="color:var(--gold);font-size:16px;"></i> <%= TranslateUtil.t(lang, "appointment_details") %></h3><button class="modal-close" onclick="closeModal()"><i class="fas fa-times"></i></button></div><div class="modal-body"><div class="client-profile-header"><div class="client-profile-av" id="modalAvatar">?</div><div><div class="client-profile-name" id="modalClientName">—</div><div class="client-profile-email" id="modalClientEmail">—</div><div style="margin-top:6px;" id="modalStatusBadge"></div></div></div><div class="modal-section"><div class="modal-section-title"><%= TranslateUtil.t(lang, "contact_info") %></div><div id="modalContactInfo"></div></div><div class="modal-section"><div class="modal-section-title"><%= TranslateUtil.t(lang, "property_info") %></div><div id="modalPropertyInfo"></div></div><div class="modal-section" id="modalMessageSection" style="display:none"><div class="modal-section-title"><%= TranslateUtil.t(lang, "client_message") %></div><div class="message-box" id="modalMessage"></div></div></div><div class="modal-footer" id="modalFooter"><button class="mf-btn mf-secondary" onclick="closeModal()"><%= TranslateUtil.t(lang, "close") %></button></div></div></div>

<!-- MODAL PROFIL AMÉLIORÉ -->
<div class="modal-overlay" id="profileModal" onclick="if(event.target===this) closeProfileModal()">
  <div class="modal-box profile-modal">
    <div class="pm-header">
      <div>
        <h2><i class="fas fa-user-cog" style="margin-right: 8px;"></i> <%= TranslateUtil.t(lang, "my_profile") %></h2>
        <p><%= TranslateUtil.t(lang, "manage_your_account") %></p>
      </div>
      <button class="pm-close" onclick="closeProfileModal()">✕</button>
    </div>
    <div class="pm-body">
      <div class="pm-avatar-area">
        <div class="pm-avatar" id="pmAvatar">
          <% if (adminProfilePic != null && !adminProfilePic.isEmpty()) { %>
            <img src="${pageContext.request.contextPath}/avatars/<%= adminProfilePic %>" alt="Admin">
          <% } else { %>
            <%= adminInitial %>
          <% } %>
          <div class="pm-avatar-edit" onclick="document.getElementById('pmAvatarInput').click()">
            <i class="fas fa-camera"></i>
          </div>
        </div>
        <div class="pm-avatar-info">
          <h4><%= adminName %></h4>
          <span><i class="fas fa-shield-alt"></i> <%= TranslateUtil.t(lang, "administrator") %></span>
        </div>
      </div>
      <input type="file" id="pmAvatarInput" style="display: none;" accept="image/*">
      <div class="pm-field">
        <label><i class="fas fa-user"></i> <%= TranslateUtil.t(lang, "username") %></label>
        <input type="text" value="<%= adminName %>" readonly>
      </div>
      <div class="pm-field">
        <label><i class="fas fa-envelope"></i> <%= TranslateUtil.t(lang, "email") %></label>
        <input type="email" placeholder="admin@fredon.com" value="admin@fredon.com">
      </div>
      <div class="pm-field">
        <label><i class="fas fa-phone"></i> <%= TranslateUtil.t(lang, "phone") %></label>
        <input type="tel" placeholder="+261 XX XXX XXXX">
      </div>
      <div class="pm-field">
        <label><i class="fas fa-lock"></i> <%= TranslateUtil.t(lang, "new_password") %></label>
        <div class="pm-pw-wrapper">
          <input type="password" id="pmNewPassword" placeholder="••••••••">
          <button type="button" class="pm-pw-toggle" onclick="togglePw('pmNewPassword', this)"><i class="fas fa-eye"></i></button>
        </div>
      </div>
      <div class="pm-field" id="pmConfirmGroup" style="display: none;">
        <label><i class="fas fa-check-circle"></i> <%= TranslateUtil.t(lang, "confirm_password") %></label>
        <div class="pm-pw-wrapper">
          <input type="password" id="pmConfirmPassword" placeholder="••••••••">
          <button type="button" class="pm-pw-toggle" onclick="togglePw('pmConfirmPassword', this)"><i class="fas fa-eye"></i></button>
        </div>
      </div>
      <div class="pm-divider"><span><i class="fas fa-bell"></i> <%= TranslateUtil.t(lang, "notifications") %></span></div>
      <div class="pm-field">
        <label><i class="fas fa-envelope"></i> <%= TranslateUtil.t(lang, "email_alerts") %></label>
        <select>
          <option value="all"><%= TranslateUtil.t(lang, "all_notifications") %></option>
          <option value="important" selected><%= TranslateUtil.t(lang, "important_only") %></option>
          <option value="none"><%= TranslateUtil.t(lang, "none") %></option>
        </select>
      </div>
    </div>
    <div class="pm-footer">
      <button class="pm-btn pm-cancel" onclick="closeProfileModal()"><i class="fas fa-times"></i> <%= TranslateUtil.t(lang, "cancel") %></button>
      <button class="pm-btn pm-save" onclick="saveProfile()"><i class="fas fa-save"></i> <%= TranslateUtil.t(lang, "save_changes") %></button>
    </div>
  </div>
</div>

<div class="toast" id="toast"><i class="fas fa-check-circle"></i><span id="toastMsg">OK</span></div>

<script>
var CTX = '${pageContext.request.contextPath}';
var currentView = 'table';

function showToast(msg, type) {
  var t = document.getElementById('toast');
  document.getElementById('toastMsg').textContent = msg;
  t.className = 'toast' + (type==='error'?' t-error':type==='success'?' t-success':'');
  t.classList.add('show');
  setTimeout(function(){ t.classList.remove('show'); }, 3200);
}

function setView(v) {
  currentView = v;
  document.getElementById('tableView').style.display = v==='table' ? 'block' : 'none';
  document.getElementById('cardView').style.display = v==='cards' ? 'block' : 'none';
  document.getElementById('btnTable').classList.toggle('active', v==='table');
  document.getElementById('btnCards').classList.toggle('active', v==='cards');
  applyFilters();
}

function filterByStatus(status) {
  document.getElementById('statusSel').value = status;
  applyFilters();
}

function applyFilters() {
  var search = document.getElementById('searchInput').value.toLowerCase();
  var status = document.getElementById('statusSel').value;
  var sort   = document.getElementById('sortSel').value;
  var selector = currentView==='table' ? '#tableBody .tbl-row' : '#cardsGrid .appt-card';
  var rows = Array.from(document.querySelectorAll(selector));
  var visible = 0;
  rows.forEach(function(row) {
    var rStatus = row.getAttribute('data-status') || '';
    var rClient = row.getAttribute('data-client') || '';
    var rProp   = row.getAttribute('data-property') || '';
    var rDate   = row.getAttribute('data-date') || '';
    var ok = (!search || rClient.includes(search) || rProp.includes(search) || rDate.includes(search)) && (status==='all' || rStatus===status);
    row.style.display = ok ? '' : 'none';
    if (ok) visible++;
  });
  var container = currentView==='table' ? document.getElementById('tableBody') : document.getElementById('cardsGrid');
  rows.filter(function(r){ return r.style.display!=='none'; }).sort(function(a, b) {
    if (sort==='date-desc') return (b.getAttribute('data-date')||'').localeCompare(a.getAttribute('data-date')||'');
    if (sort==='date-asc') return (a.getAttribute('data-date')||'').localeCompare(b.getAttribute('data-date')||'');
    if (sort==='name-asc') return (a.getAttribute('data-client')||'').localeCompare(b.getAttribute('data-client')||'');
    if (sort==='name-desc') return (b.getAttribute('data-client')||'').localeCompare(a.getAttribute('data-client')||'');
    if (sort==='property-asc') return (a.getAttribute('data-property')||'').localeCompare(b.getAttribute('data-property')||'');
    return 0;
  }).forEach(function(r){ container.appendChild(r); });
  document.getElementById('resultsCount').textContent = visible + ' <%= TranslateUtil.t(lang, "result") %>' + (visible!==1?'s':'');
}

function sortBy(field) {
  var sel = document.getElementById('sortSel');
  if (field==='date') sel.value = sel.value==='date-desc' ? 'date-asc' : 'date-desc';
  else if (field==='client') sel.value = sel.value==='name-asc' ? 'name-desc' : 'name-asc';
  else if (field==='property') sel.value = 'property-asc';
  applyFilters();
}

function showDetailsFromRow(row) {
  showDetails(row.getAttribute('data-id'), row.getAttribute('data-name')||'', row.getAttribute('data-email')||'', row.getAttribute('data-phone')||'', row.getAttribute('data-message')||'', row.getAttribute('data-status')||'', row.getAttribute('data-proptitle')||'', row.getAttribute('data-proploc')||'', row.getAttribute('data-datestr')||'', row.getAttribute('data-timestr')||'', row.getAttribute('data-propimg')||'', row.getAttribute('data-clientpic')||'');
}

function showDetails(id, name, email, phone, message, status, propTitle, propLoc, date, time, propImg, clientPic) {
  var initial = name ? name.charAt(0).toUpperCase() : '?';
  var grads = ['linear-gradient(135deg,#7c3aed,#2563eb)','linear-gradient(135deg,#0e9e8a,#1f52d4)','linear-gradient(135deg,#e03060,#7c3aed)','linear-gradient(135deg,#d97706,#dc2626)','linear-gradient(135deg,#059669,#0e9e8a)'];
  var av = document.getElementById('modalAvatar');
  av.style.background = grads[initial.charCodeAt(0) % 5];
  if (clientPic && clientPic !== '') av.innerHTML = '<img src="' + CTX + '/uploads/' + clientPic + '" style="width:100%;height:100%;object-fit:cover;border-radius:18px;" onerror="this.parentElement.innerHTML=\'' + initial + '\'">';
  else av.innerHTML = initial;
  document.getElementById('modalClientName').textContent = name || '—';
  document.getElementById('modalClientEmail').textContent = email || '—';
  var labels = {pending:'<%= TranslateUtil.t(lang, "appointment_pending") %>',confirmed:'<%= TranslateUtil.t(lang, "appointment_confirmed") %>',completed:'<%= TranslateUtil.t(lang, "appointment_completed") %>',cancelled:'<%= TranslateUtil.t(lang, "appointment_cancelled") %>'};
  document.getElementById('modalStatusBadge').innerHTML = '<span class="status-badge s-' + status + '"><span class="status-dot"></span>' + (labels[status]||status) + '</span>';
  var contact = '<div style="display:flex;flex-direction:column;gap:0"><div class="info-row"><div class="info-icon"><i class="fas fa-envelope"></i></div><div><div class="info-label">Email</div><div class="info-value">' + (email||'—') + '</div></div></div>';
  if (phone && phone !== '') contact += '<div class="info-row"><div class="info-icon"><i class="fas fa-phone"></i></div><div><div class="info-label">Téléphone</div><div class="info-value">' + phone + '</div></div></div>';
  contact += '</div>';
  document.getElementById('modalContactInfo').innerHTML = contact;
  var prop = '<div style="display:flex;flex-direction:column;gap:0"><div class="info-row"><div class="info-icon"><i class="fas fa-home"></i></div><div><div class="info-label">Bien</div><div class="info-value">' + propTitle + '</div></div></div>';
  if (propLoc && propLoc !== '') prop += '<div class="info-row"><div class="info-icon"><i class="fas fa-map-marker-alt"></i></div><div><div class="info-label">Localisation</div><div class="info-value">' + propLoc + '</div></div></div>';
  prop += '<div class="info-row"><div class="info-icon"><i class="fas fa-calendar"></i></div><div><div class="info-label">Date & Heure</div><div class="info-value">' + date + ' à ' + time + 'h</div></div></div>';
  if (propImg && propImg !== '') prop += '<div class="info-row"><div class="info-icon"><i class="fas fa-image"></i></div><div><div class="info-label">Photo</div><img src="' + CTX + '/' + propImg + '" style="width:100%;max-width:220px;border-radius:10px;margin-top:6px;" onerror="this.style.display=\'none\'"></div></div>';
  prop += '</div>';
  document.getElementById('modalPropertyInfo').innerHTML = prop;
  var msgSection = document.getElementById('modalMessageSection');
  if (message && message.trim()) { document.getElementById('modalMessage').textContent = message; msgSection.style.display = 'block'; }
  else { msgSection.style.display = 'none'; }
  var footer = '<button class="mf-btn mf-secondary" onclick="closeModal()"><%= TranslateUtil.t(lang, "close") %></button>';
  if (status === 'pending') footer += '<button class="mf-btn mf-danger" onclick="updateStatusModal(' + id + ',\'cancelled\')"><i class="fas fa-times"></i> <%= TranslateUtil.t(lang, "cancel") %></button><button class="mf-btn mf-success" onclick="updateStatusModal(' + id + ',\'confirmed\')"><i class="fas fa-check"></i> <%= TranslateUtil.t(lang, "confirm") %></button>';
  else if (status === 'confirmed') footer += '<button class="mf-btn mf-danger" onclick="updateStatusModal(' + id + ',\'cancelled\')"><i class="fas fa-times"></i> <%= TranslateUtil.t(lang, "cancel") %></button><button class="mf-btn mf-primary" onclick="updateStatusModal(' + id + ',\'completed\')"><i class="fas fa-flag-checkered"></i> <%= TranslateUtil.t(lang, "complete") %></button>';
  document.getElementById('modalFooter').innerHTML = footer;
  document.getElementById('detailModal').classList.add('open');
}

function closeModal() { document.getElementById('detailModal').classList.remove('open'); }
document.getElementById('detailModal').addEventListener('click', function(e){ if (e.target === this) closeModal(); });

function updateStatus(id, newStatus) {
  var labels = {confirmed:'<%= TranslateUtil.t(lang, "confirm") %>',completed:'<%= TranslateUtil.t(lang, "complete") %>',cancelled:'<%= TranslateUtil.t(lang, "cancel") %>'};
  if (!confirm('Êtes-vous sûr de vouloir ' + (labels[newStatus]||newStatus) + ' cette visite ?')) return;
  fetch(CTX + '/admin/update-appointment-status', {method:'POST',headers:{'Content-Type':'application/x-www-form-urlencoded'},body:'id=' + id + '&status=' + newStatus})
  .then(function(r){ return r.json(); }).then(function(d){ if (d.success) { showToast('Statut mis à jour','success'); setTimeout(function(){ location.reload(); }, 900); } else { showToast('Erreur : ' + (d.error||'inconnue'),'error'); } })
  .catch(function(){ showToast('Erreur réseau','error'); });
}

function updateStatusModal(id, newStatus) { closeModal(); updateStatus(id, newStatus); }

function exportCSV() {
  var rows = document.querySelectorAll('#tableBody .tbl-row'), lines = ['ID,Client,Email,Telephone,Bien,Date,Heure,Statut,Message'];
  rows.forEach(function(r){ if (r.style.display==='none') return; lines.push([r.getAttribute('data-id')||'',r.getAttribute('data-name')||'',r.getAttribute('data-email')||'',r.getAttribute('data-phone')||'',r.getAttribute('data-proptitle')||'',r.getAttribute('data-datestr')||'',r.getAttribute('data-timestr')||'',r.getAttribute('data-status')||'',(r.getAttribute('data-message')||'').replace(/,/g,' ')].join(',')); });
  var blob = new Blob([lines.join('\n')], {type:'text/csv;charset=utf-8;'}), url = URL.createObjectURL(blob), a = document.createElement('a');
  a.href = url; a.download = 'appointments_' + new Date().toISOString().slice(0,10) + '.csv'; a.click(); showToast('Export CSV téléchargé','success');
}

async function exportPDF() {
  showToast('Génération du PDF en cours...', 'success');
  var pdfContainer = document.createElement('div'); pdfContainer.style.position = 'absolute'; pdfContainer.style.left = '-9999px'; pdfContainer.style.top = '0'; pdfContainer.style.backgroundColor = '#ffffff'; pdfContainer.style.padding = '20px'; pdfContainer.style.width = '800px'; pdfContainer.style.fontFamily = 'DM Sans, sans-serif';
  var today = new Date(), dateStr = today.toLocaleDateString('fr-FR');
  var statusLabels = { pending: 'En attente', confirmed: 'Confirmé', completed: 'Terminé', cancelled: 'Annulé' };
  var htmlContent = '<div style="text-align: center; margin-bottom: 30px;"><h1 style="color: #c8860a; font-family: Syne, sans-serif;">FREDON IMMOBILIER</h1><h2 style="color: #1f52d4;">Liste des rendez-vous</h2><p>Généré le ' + dateStr + '</p><hr style="border: 1px solid #c8860a;"></div><table style="width: 100%; border-collapse: collapse;"><thead><tr style="background-color: #f8f4ee;"><th style="border: 1px solid #ddd; padding: 10px; text-align: left;">Client</th><th style="border: 1px solid #ddd; padding: 10px; text-align: left;">Email</th><th style="border: 1px solid #ddd; padding: 10px; text-align: left;">Bien</th><th style="border: 1px solid #ddd; padding: 10px; text-align: left;">Date</th><th style="border: 1px solid #ddd; padding: 10px; text-align: left;">Heure</th><th style="border: 1px solid #ddd; padding: 10px; text-align: left;">Statut</th></tr></thead><tbody>';
  var visibleRows = document.querySelectorAll('#tableBody .tbl-row');
  visibleRows.forEach(function(row) { if (row.style.display === 'none') return; var name = row.getAttribute('data-name')||'', email = row.getAttribute('data-email')||'', prop = row.getAttribute('data-proptitle')||'', date = row.getAttribute('data-datestr')||'', time = row.getAttribute('data-timestr')||'', status = row.getAttribute('data-status')||'', statusText = statusLabels[status]||status, statusColor = status==='pending'?'#d97706':status==='confirmed'?'#059669':status==='completed'?'#1f52d4':'#dc2626';
    htmlContent += '<tr><td style="border: 1px solid #ddd; padding: 8px;">' + name + '</td><td style="border: 1px solid #ddd; padding: 8px;">' + email + '</td><td style="border: 1px solid #ddd; padding: 8px;">' + prop + '</td><td style="border: 1px solid #ddd; padding: 8px;">' + date + '</td><td style="border: 1px solid #ddd; padding: 8px;">' + time + 'h</td><td style="border: 1px solid #ddd; padding: 8px; color: ' + statusColor + '; font-weight: bold;">' + statusText + '</td></tr>';
  });
  htmlContent += '</tbody></table><div style="margin-top: 30px; text-align: center; font-size: 10px; color: #999;"><hr><p>Fredon Immobilier - Tous droits réservés</p></div>';
  pdfContainer.innerHTML = htmlContent; document.body.appendChild(pdfContainer);
  try { const { jsPDF } = window.jspdf; const pdf = new jsPDF('landscape', 'mm', 'a4'); const canvas = await html2canvas(pdfContainer, { scale: 2, backgroundColor: '#ffffff', logging: false }); const imgData = canvas.toDataURL('image/png'); const imgWidth = 297, pageHeight = 210, imgHeight = (canvas.height * imgWidth) / canvas.width; let heightLeft = imgHeight, position = 0; pdf.addImage(imgData, 'PNG', 0, position, imgWidth, imgHeight); heightLeft -= pageHeight; while (heightLeft >= 0) { position = heightLeft - imgHeight; pdf.addPage(); pdf.addImage(imgData, 'PNG', 0, position, imgWidth, imgHeight); heightLeft -= pageHeight; } pdf.save('appointments_' + new Date().toISOString().slice(0,10) + '.pdf'); showToast('PDF exporté avec succès !', 'success'); } catch(error) { console.error('Erreur PDF:', error); showToast('Erreur lors de la génération du PDF', 'error'); } finally { document.body.removeChild(pdfContainer); } }

// Fonctions pour le modal profil amélioré
function togglePw(inputId, btn) {
  var input = document.getElementById(inputId);
  var icon = btn.querySelector('i');
  if (input.type === 'password') {
    input.type = 'text';
    icon.classList.remove('fa-eye');
    icon.classList.add('fa-eye-slash');
  } else {
    input.type = 'password';
    icon.classList.remove('fa-eye-slash');
    icon.classList.add('fa-eye');
  }
}

document.getElementById('pmNewPassword')?.addEventListener('input', function(e) {
  var confirmGroup = document.getElementById('pmConfirmGroup');
  if (e.target.value.length > 0) {
    confirmGroup.style.display = 'block';
  } else {
    confirmGroup.style.display = 'none';
    document.getElementById('pmConfirmPassword').value = '';
  }
});

document.getElementById('pmAvatarInput')?.addEventListener('change', function(e) {
  if (e.target.files && e.target.files[0]) {
    var reader = new FileReader();
    reader.onload = function(ev) {
      var avatarDiv = document.getElementById('pmAvatar');
      avatarDiv.innerHTML = '<img src="' + ev.target.result + '" alt="Admin"><div class="pm-avatar-edit" onclick="document.getElementById(\'pmAvatarInput\').click()"><i class="fas fa-camera"></i></div>';
    };
    reader.readAsDataURL(e.target.files[0]);
    showToast('Avatar uploadé avec succès', 'success');
  }
});

function saveProfile() {
  var newPw = document.getElementById('pmNewPassword').value;
  var confirmPw = document.getElementById('pmConfirmPassword').value;
  if (newPw && newPw !== confirmPw) {
    showToast('Les mots de passe ne correspondent pas', 'error');
    return;
  }
  showToast('Profil mis à jour avec succès', 'success');
  setTimeout(function(){ closeProfileModal(); }, 1200);
}

function openProfileModal() { document.getElementById('profileModal').classList.add('open'); }
function closeProfileModal() { document.getElementById('profileModal').classList.remove('open'); }
document.getElementById('profileModal').addEventListener('click', function(e) { if (e.target === this) closeProfileModal(); });

document.addEventListener('DOMContentLoaded', function(){ applyFilters(); <% if (!statusFilter.equals("all")) { %> document.getElementById('statusSel').value = '<%= statusFilter %>'; applyFilters(); <% } %> });

//Empêche l'accès aux pages après déconnexion
if (performance.navigation.type === 2) {
 window.location.href = '${pageContext.request.contextPath}/login';
}


</script>
</body>
</html>