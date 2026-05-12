<%@ page language="java" contentType="text/html; charset=UTF-8"
	pageEncoding="UTF-8"%>
<%@ page import="java.util.*, java.text.*"%>
<%@ page import="java.sql.*"%>
<%@ page import="com.quickchat.model.User"%>
<%@ page import="com.quickchat.utils.TranslateUtil"%>

<%
    String lang = "fr";
    try {
        Class.forName("com.mysql.cj.jdbc.Driver");
        Connection langConn = DriverManager.getConnection("jdbc:mysql://localhost:3306/quickchat","root","");
        PreparedStatement langPs = langConn.prepareStatement("SELECT default_language FROM settings WHERE id=1");
        ResultSet langRs = langPs.executeQuery();
        if (langRs.next()) lang = langRs.getString("default_language");
        langRs.close(); langPs.close(); langConn.close();
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
    String DB_USER_DB = "root";
    String DB_PASSWORD = "";

    String searchQuery  = request.getParameter("search");
    String statusFilter = request.getParameter("status");
    String dateFilter   = request.getParameter("dateFilter");
    String ownerFilter  = request.getParameter("ownerFilter");

    List<Map<String, Object>> clients  = new ArrayList<>();
    int totalClients  = 0;
    int newThisMonth  = 0;
    int activeClients = 0;
    int loyalClients  = 0;
    int ownerClients  = 0;
    int unreadMessages = 0;

    try {
        Class.forName("com.mysql.cj.jdbc.Driver");
        Connection conn = DriverManager.getConnection(DB_URL, DB_USER_DB, DB_PASSWORD);
        /* ── Messages non lus ── */
        try {
            com.quickchat.dao.MessageDAO messageDAO = new com.quickchat.dao.MessageDAO();
            unreadMessages = messageDAO.countUnreadMessagesForAgent();
        } catch(Exception e) {
            unreadMessages = 0;
        }

        /* ── Requête clients ── */
        StringBuilder sql = new StringBuilder("SELECT u.* FROM users u WHERE u.id NOT IN (9, 999)");
        List<Object> params = new ArrayList<>();

        if (searchQuery != null && !searchQuery.trim().isEmpty()) {
            sql.append(" AND (u.username LIKE ? OR u.email LIKE ? OR u.display_name LIKE ?)");
            String s = "%" + searchQuery.trim() + "%";
            params.add(s); params.add(s); params.add(s);
        }
        if (dateFilter != null && !dateFilter.equals("all")) {
            if (dateFilter.equals("week"))  sql.append(" AND u.created_at >= DATE_SUB(NOW(), INTERVAL 7 DAY)");
            else if (dateFilter.equals("month")) sql.append(" AND u.created_at >= DATE_SUB(NOW(), INTERVAL 30 DAY)");
            else if (dateFilter.equals("year"))  sql.append(" AND u.created_at >= DATE_SUB(NOW(), INTERVAL 1 YEAR)");
        }

        sql.append(" ORDER BY u.created_at DESC");

        PreparedStatement pst = conn.prepareStatement(sql.toString());
        for (int i = 0; i < params.size(); i++) pst.setString(i+1, (String) params.get(i));
        ResultSet rs = pst.executeQuery();

        while (rs.next()) {
            Map<String, Object> c = new HashMap<>();
            int uid = rs.getInt("id");
            c.put("id",       uid);
            c.put("username", rs.getString("username"));
            c.put("email",    rs.getString("email"));
            c.put("created_at", rs.getTimestamp("created_at"));
            try { c.put("avatar",       rs.getString("profile_pic")); } catch(Exception ex) { c.put("avatar",null); }
            try { c.put("phone",        rs.getString("phone")); }       catch(Exception ex) { c.put("phone",null); }
            try { c.put("display_name", rs.getString("display_name")); } catch(Exception ex) { c.put("display_name",null); }
            try { c.put("is_loyal",     rs.getInt("is_loyal") == 1); }  catch(Exception ex) { c.put("is_loyal",false); }

            /* ── Récupération des propriétés SANS DOUBLONS ── */
            boolean hasProperties = false;
            List<Map<String,Object>> ownedProps = new ArrayList<>();

            try {
                String propQuery = 
                    "SELECT DISTINCT p.id, p.title, p.location, p.price, p.type, p.status, " +
                    "COALESCE(p.sold_at, pt.purchase_date) as purchase_date, " +
                    "COALESCE(pt.amount, p.sold_price) as sold_price " +
                    "FROM properties p " +
                    "LEFT JOIN property_transactions pt ON p.id = pt.property_id " +
                    "WHERE (p.buyer_id = ? AND p.status = 'sold') " +
                    "   OR (pt.buyer_id = ?) " +
                    "ORDER BY purchase_date DESC";
                
                PreparedStatement pstProp = conn.prepareStatement(propQuery);
                pstProp.setInt(1, uid);
                pstProp.setInt(2, uid);
                ResultSet rsProp = pstProp.executeQuery();
                
                while (rsProp.next()) {
                    hasProperties = true;
                    Map<String,Object> pm = new HashMap<>();
                    pm.put("id", rsProp.getInt("id"));
                    pm.put("title", rsProp.getString("title"));
                    pm.put("location", rsProp.getString("location"));
                    pm.put("price", rsProp.getDouble("price"));
                    pm.put("type", rsProp.getString("type"));
                    
                    double soldPrice = rsProp.getDouble("sold_price");
                    if (soldPrice == 0) {
                        soldPrice = rsProp.getDouble("price");
                    }
                    pm.put("sold_price", soldPrice);
                    
                    Timestamp purchaseDate = rsProp.getTimestamp("purchase_date");
                    pm.put("purchase_date", purchaseDate);
                    ownedProps.add(pm);
                }
                rsProp.close();
                pstProp.close();
                
            } catch(Exception ex) { 
                System.out.println("Erreur propriétés user " + uid + ": " + ex.getMessage());
            }

            c.put("owned_properties", ownedProps);
            c.put("is_owner", hasProperties);

            /* ── Messages non lus de ce client → admin ── */
            int unreadFromClient = 0;
            List<Map<String,Object>> unreadMsgs = new ArrayList<>();
            try {
                PreparedStatement pstMsg = conn.prepareStatement(
                    "SELECT id, content, created_at FROM messages " +
                    "WHERE sender_id = ? AND receiver_id = 9 AND is_read = 0 " +
                    "ORDER BY created_at DESC LIMIT 5");
                pstMsg.setInt(1, uid);
                ResultSet rsMsg2 = pstMsg.executeQuery();
                while (rsMsg2.next()) {
                    Map<String,Object> mm = new HashMap<>();
                    mm.put("id",         rsMsg2.getInt("id"));
                    mm.put("content",    rsMsg2.getString("content"));
                    mm.put("created_at", rsMsg2.getTimestamp("created_at"));
                    unreadMsgs.add(mm);
                    unreadFromClient++;
                }
                rsMsg2.close(); pstMsg.close();
            } catch(Exception ex) {}
            c.put("unread_msgs", unreadMsgs);
            c.put("unread_count", unreadFromClient);

            clients.add(c);
        }
        rs.close();
        pst.close();

        /* ── Statistiques ── */
        Statement stmt = conn.createStatement();
        ResultSet r1 = stmt.executeQuery("SELECT COUNT(*) as t FROM users"); 
        if(r1.next()) totalClients = r1.getInt("t"); 
        r1.close();
        
        ResultSet r2 = stmt.executeQuery("SELECT COUNT(*) as t FROM users WHERE created_at >= DATE_SUB(NOW(), INTERVAL 30 DAY)"); 
        if(r2.next()) newThisMonth = r2.getInt("t"); 
        r2.close();
        
        // Calcul des clients actifs (ceux qui ont envoyé un message récemment)
        try { 
            ResultSet r3 = stmt.executeQuery("SELECT COUNT(DISTINCT sender_id) as t FROM messages WHERE created_at >= DATE_SUB(NOW(), INTERVAL 30 DAY)"); 
            if(r3.next()) activeClients = r3.getInt("t"); 
            r3.close(); 
        } catch(Exception e) {}
        
        try { 
            ResultSet r4 = stmt.executeQuery("SELECT COUNT(*) as t FROM users WHERE is_loyal=1"); 
            if(r4.next()) loyalClients = r4.getInt("t"); 
            r4.close(); 
        } catch(Exception e) {}
        
        try { 
            ResultSet r5 = stmt.executeQuery("SELECT COUNT(DISTINCT buyer_id) as t FROM property_transactions"); 
            if(r5.next()) ownerClients = r5.getInt("t"); 
            r5.close(); 
        } catch(Exception e) {}
        
        stmt.close();
        conn.close();

    } catch (Exception e) { 
        e.printStackTrace(); 
    }

    String adminName = session.getAttribute("adminUsername") != null ?
        session.getAttribute("adminUsername").toString() : "Admin";
    String adminInitial = (adminName != null && !adminName.isEmpty()) ? adminName.substring(0,1).toUpperCase() : "A";
    SimpleDateFormat sdfDisp = new SimpleDateFormat("dd/MM/yyyy");
    SimpleDateFormat sdfFull = new SimpleDateFormat("dd/MM/yyyy 'à' HH:mm");
    String[] avatarColors = {"#1f52d4","#e03060","#0e9e8a","#7c3aed","#c8860a","#0e7490","#b45309","#166534"};
%>
<!DOCTYPE html>
<html lang="<%= lang %>">
<head>
<%@ include file="includes/theme.jsp" %>
<%@ include file="includes/color.jsp" %>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title><%= TranslateUtil.t(lang,"clients") %> — Fredon Immobilier</title>
<link href="https://fonts.googleapis.com/css2?family=Syne:wght@400;600;700;800&family=DM+Sans:opsz,wght@9..40,300;9..40,400;9..40,500;9..40,600;9..40,700&display=swap" rel="stylesheet">
<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css">
<script src="https://cdnjs.cloudflare.com/ajax/libs/jspdf/2.5.1/jspdf.umd.min.js"></script>
<script src="https://cdnjs.cloudflare.com/ajax/libs/jspdf-autotable/3.6.0/jspdf.plugin.autotable.min.js"></script>

<script>
// Variables de traduction pour le JavaScript
const t = {
    owner: "<%= TranslateUtil.t(lang, "owner") %>",
    loyal_client: "<%= TranslateUtil.t(lang, "loyal_client") %>",
    no_properties_acquired: "<%= TranslateUtil.t(lang, "no_properties_acquired") %>",
    acquired_on: "<%= TranslateUtil.t(lang, "acquired_on") %>",
    no_unread_messages: "<%= TranslateUtil.t(lang, "no_unread_messages") %>",
    no_notes: "<%= TranslateUtil.t(lang, "no_notes") %>",
    remove_loyal: "<%= TranslateUtil.t(lang, "remove_loyal") %>",
    mark_loyal: "<%= TranslateUtil.t(lang, "mark_loyal") %>",
    enter_note_before_saving: "<%= TranslateUtil.t(lang, "enter_note_before_saving") %>",
    note_saved: "<%= TranslateUtil.t(lang, "note_saved") %>",
    client_marked_loyal: "<%= TranslateUtil.t(lang, "client_marked_loyal") %>",
    loyal_status_removed: "<%= TranslateUtil.t(lang, "loyal_status_removed") %>",
    update_error: "<%= TranslateUtil.t(lang, "update_error") %>",
    network_error: "<%= TranslateUtil.t(lang, "network_error") %>",
    yes: "<%= TranslateUtil.t(lang, "yes") %>",
    no: "<%= TranslateUtil.t(lang, "no") %>",
    csv_id: "<%= TranslateUtil.t(lang, "csv_id") %>",
    csv_name: "<%= TranslateUtil.t(lang, "csv_name") %>",
    csv_email: "<%= TranslateUtil.t(lang, "csv_email") %>",
    csv_owner: "<%= TranslateUtil.t(lang, "csv_owner") %>",
    csv_loyal: "<%= TranslateUtil.t(lang, "csv_loyal") %>",
    csv_registration: "<%= TranslateUtil.t(lang, "csv_registration") %>",
    csv_exported: "<%= TranslateUtil.t(lang, "csv_exported") %>",
    pdf_exported: "<%= TranslateUtil.t(lang, "pdf_exported") %>",
    profile_updated: "<%= TranslateUtil.t(lang, "profile_updated") %>",
    passwords_do_not_match: "<%= TranslateUtil.t(lang, "passwords_do_not_match") %>",
    avatar_uploaded: "<%= TranslateUtil.t(lang, "avatar_uploaded") %>"
};
</script>

<style>
/* VOTRE STYLE RESTE IDENTIQUE - AUCUN CHANGEMENT */
*, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }

:root {
    --gold: #c8860a; --gold-light: #e8a220; --gold-pale: #fff3d4;
    --blue: #1f52d4; --blue-light: #4f7ef8; --blue-pale: #e8eeff;
    --teal: #0e9e8a; --teal-light: #2ecfb4; --teal-pale: #e0faf5;
    --rose: #e03060; --rose-light: #f7547a; --rose-pale: #fde8ee;
    --purple: #7c3aed; --purple-pale: #f0ebff;
    --emerald: #059669; --emerald-pale: #d1fae5;
    --green: #10b981; --red: #ef4444;
    --dark: #0d0b08; --mid: #6b5a3e; --soft: #a89880;
    --bg: #f8f4ee; --bg2: #fdf9f3; --white: #ffffff;
    --sidebar-w: 272px; --r-lg: 18px; --r-xl: 26px;
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

html, body { height: 100%; font-family: 'DM Sans', sans-serif; background: var(--bg); color: var(--dark); overflow-x: hidden; transition: background 0.3s, color 0.3s; }
#bgCanvas { position: fixed; inset: 0; z-index: 0; pointer-events: none; opacity: .06; }
.layout { display: flex; min-height: 100vh; position: relative; z-index: 1; }
::-webkit-scrollbar { width: 5px; }
::-webkit-scrollbar-thumb { background: rgba(200, 134, 10, .2); border-radius: 4px; }

/* ── SIDEBAR ── */
.sidebar {
    width: var(--sidebar-w); background: linear-gradient(160deg, #0d1f5e 0%, #1a3aaa 45%, #0e2d82 75%, #0a1d58 100%);
    display: flex; flex-direction: column; position: fixed; left: 0; top: 0; bottom: 0; z-index: 100;
    box-shadow: 8px 0 40px rgba(31, 82, 212, .18); overflow: hidden;
}
body.dark-theme .sidebar {
    background: linear-gradient(160deg, #050a18 0%, #0d1626 45%, #0a1030 75%, #040818 100%);
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
.nav-badge { margin-left: auto; background: var(--rose); color: white; font-size: 9.5px; font-weight: 700; padding: 2px 7px; border-radius: 20px; animation: pulse 2s ease-in-out infinite; }
@keyframes pulse { 0%,100% { opacity: 1; } 50% { opacity: .65; } }
.user-bottom { padding: 16px 14px; border-top: 1px solid rgba(255, 255, 255, .1); display: flex; align-items: center; gap: 10px; cursor: pointer; transition: all .22s; position: relative; z-index: 2; }
.user-bottom:hover { background: rgba(255, 255, 255, .08); }
.u-avatar { width: 42px; height: 42px; flex-shrink: 0; background: linear-gradient(135deg, var(--gold), var(--gold-light)); border-radius: 12px; display: flex; align-items: center; justify-content: center; font-family: 'Syne', sans-serif; font-size: 18px; font-weight: 800; color: #fff; box-shadow: 0 4px 14px rgba(200, 134, 10, .4); overflow: hidden; }
.u-avatar img { width: 100%; height: 100%; object-fit: cover; }
.u-info { flex: 1; }
.u-name { font-size: 13.5px; font-weight: 700; color: #fff; }
.u-role { font-size: 10.5px; color: rgba(255, 255, 255, .5); margin-top: 1px; }
.u-dot { width: 8px; height: 8px; background: #2ecfb4; border-radius: 50%; box-shadow: 0 0 8px #2ecfb4; }

/* ── MAIN ── */
.main { margin-left: var(--sidebar-w); flex: 1; padding: 28px 32px; min-height: 100vh; }
.top-bar { display: flex; justify-content: space-between; align-items: center; margin-bottom: 28px; gap: 16px; flex-wrap: wrap; }
.page-title h1 { font-family: 'Syne', sans-serif; font-size: 26px; font-weight: 800; color: var(--dark); letter-spacing: -.5px; }
.page-title p { font-size: 13px; color: var(--soft); margin-top: 3px; }
.top-right { display: flex; align-items: center; gap: 10px; }
.notif-wrap { position: relative; text-decoration: none; }
.icon-circle { width: 40px; height: 40px; background: var(--white); border: 1.5px solid rgba(200, 134, 10, .14); border-radius: 12px; display: flex; align-items: center; justify-content: center; cursor: pointer; color: var(--mid); font-size: 15px; transition: all .22s; text-decoration: none; }
.icon-circle:hover { border-color: var(--gold); color: var(--gold); }
.notif-pip { position: absolute; top: -2px; right: -2px; background: var(--red); color: white; font-size: 10px; width: 18px; height: 18px; border-radius: 50%; display: flex; align-items: center; justify-content: center; font-weight: bold; }

/* ── STATS ── */
.stats-row { display: grid; grid-template-columns: repeat(3, 1fr); gap: 14px; margin-bottom: 26px; }
.stat-card { background: var(--white); border-radius: var(--r-xl); padding: 18px 16px; border: 1.5px solid transparent; position: relative; overflow: hidden; transition: transform .25s, box-shadow .25s; }
.stat-card:hover { transform: translateY(-4px); box-shadow: 0 16px 40px rgba(0, 0, 0, .1); }
.sc-blue { background: linear-gradient(135deg, #e8eeff, #f8faff); border-color: rgba(79, 126, 248, .2); }
.sc-gold { background: linear-gradient(135deg, #fff3d4, #fffaf0); border-color: rgba(200, 134, 10, .2); }
.sc-teal { background: linear-gradient(135deg, #e0faf5, #f4fffe); border-color: rgba(14, 158, 138, .2); }
.sc-rose { background: linear-gradient(135deg, #fde8ee, #fff5f8); border-color: rgba(224, 48, 96, .18); }
.stat-top { display: flex; justify-content: space-between; align-items: flex-start; margin-bottom: 12px; }
.stat-ico { width: 40px; height: 40px; border-radius: 12px; display: flex; align-items: center; justify-content: center; font-size: 18px; }
.ico-blue { background: rgba(79, 126, 248, .15); color: var(--blue-light); }
.ico-gold { background: rgba(200, 134, 10, .15); color: var(--gold); }
.ico-teal { background: rgba(14, 158, 138, .15); color: var(--teal); }
.ico-rose { background: rgba(224, 48, 96, .15); color: var(--rose); }
.stat-badge { font-size: 9.5px; font-weight: 700; padding: 3px 8px; border-radius: 20px; }
.badge-up-blue { background: rgba(79, 126, 248, .14); color: var(--blue-light); }
.badge-up-gold { background: rgba(200, 134, 10, .14); color: var(--gold); }
.badge-up-teal { background: rgba(14, 158, 138, .14); color: var(--teal); }
.badge-up-rose { background: rgba(224, 48, 96, .14); color: var(--rose); }
.stat-val { font-family: 'Syne', sans-serif; font-size: 30px; font-weight: 800; line-height: 1; margin-bottom: 4px; }
.val-blue { color: var(--blue); }
.val-gold { color: var(--gold); }
.val-teal { color: var(--teal); }
.val-rose { color: var(--rose); }
.stat-lbl { font-size: 11.5px; color: var(--soft); font-weight: 500; }
.stat-bar { margin-top: 12px; height: 3px; background: rgba(0, 0, 0, .06); border-radius: 4px; overflow: hidden; }
.stat-fill { height: 100%; border-radius: 4px; width: 0; transition: width 1s ease; }
.fill-blue { background: linear-gradient(90deg, var(--blue), var(--blue-light)); }
.fill-gold { background: linear-gradient(90deg, var(--gold), var(--gold-light)); }
.fill-teal { background: linear-gradient(90deg, var(--teal), var(--teal-light)); }
.fill-rose { background: linear-gradient(90deg, var(--rose), var(--rose-light)); }

/* ── FILTERS BAR ── */
.filters-bar {
    background: var(--white); border-radius: var(--r-xl);
    padding: 16px 20px; margin-bottom: 20px;
    border: 1.5px solid rgba(200, 134, 10, .1);
    display: flex; flex-wrap: wrap; gap: 10px; align-items: center;
    box-shadow: 0 2px 12px rgba(0, 0, 0, .04);
}
.search-wrap { flex: 2; min-width: 180px; position: relative; }
.search-wrap i { position: absolute; left: 13px; top: 50%; transform: translateY(-50%); color: var(--soft); font-size: 13px; }
.search-wrap input { width: 100%; padding: 10px 13px 10px 38px; border: 1.5px solid rgba(200, 134, 10, .15); border-radius: 12px; font-family: 'DM Sans', sans-serif; font-size: 14px; background: var(--bg2); color: var(--dark); transition: all .22s; outline: none; }
.search-wrap input:focus { border-color: var(--blue-light); background: var(--white); box-shadow: 0 0 0 4px rgba(79, 126, 248, .1); }
.filter-sel { padding: 10px 13px; border: 1.5px solid rgba(200, 134, 10, .15); border-radius: 12px; font-family: 'DM Sans', sans-serif; font-size: 13px; background: var(--bg2); color: var(--mid); cursor: pointer; outline: none; transition: all .2s; min-width: 130px; }
.filter-sel:focus { border-color: var(--blue-light); }
.export-group { display: flex; gap: 7px; }
.btn-export { display: inline-flex; align-items: center; gap: 6px; padding: 9px 14px; border-radius: 11px; border: none; cursor: pointer; font-family: 'DM Sans', sans-serif; font-size: 13px; font-weight: 600; transition: all .22s; }
.btn-csv { background: var(--teal-pale); color: var(--teal); border: 1.5px solid rgba(14, 158, 138, .2); }
.btn-csv:hover { background: var(--teal); color: white; transform: translateY(-1px); }
.btn-pdf { background: var(--rose-pale); color: var(--rose); border: 1.5px solid rgba(224, 48, 96, .2); }
.btn-pdf:hover { background: var(--rose); color: white; transform: translateY(-1px); }

/* ── TABLE CARD ── */
.table-card { background: var(--white); border-radius: var(--r-xl); border: 1.5px solid rgba(200, 134, 10, .1); overflow: hidden; box-shadow: 0 2px 16px rgba(0, 0, 0, .05); animation: fadeUp .5s .1s both; }
@keyframes fadeUp { from { opacity: 0; transform: translateY(16px); } to { opacity: 1; transform: translateY(0); } }
.card-head { display: flex; justify-content: space-between; align-items: center; padding: 16px 22px; border-bottom: 1.5px solid rgba(200, 134, 10, .08); flex-wrap: wrap; gap: 10px; }
.ch-left { display: flex; align-items: center; gap: 12px; }
.ch-icon { width: 40px; height: 40px; border-radius: 12px; background: linear-gradient(135deg, var(--purple-pale), #e8e0ff); display: flex; align-items: center; justify-content: center; font-size: 17px; color: var(--purple); }
.ch-title { font-family: 'Syne', sans-serif; font-size: 16px; font-weight: 700; color: var(--dark); }
.ch-sub { font-size: 11.5px; color: var(--soft); margin-top: 2px; }
.clients-count { font-family: 'Syne', sans-serif; font-size: 12px; font-weight: 700; padding: 5px 13px; border-radius: 20px; background: var(--purple-pale); color: var(--purple); }
.tbl-wrap { overflow-x: auto; }
table { width: 100%; border-collapse: collapse; }
thead tr { background: rgba(248, 244, 238, .8); }
th { padding: 11px 14px; text-align: left; font-size: 10px; font-weight: 700; letter-spacing: 1.1px; text-transform: uppercase; color: var(--soft); border-bottom: 1.5px solid rgba(200, 134, 10, .08); }
td { padding: 12px 14px; font-size: 13px; color: var(--dark); border-bottom: 1px solid rgba(200, 134, 10, .05); vertical-align: middle; }
tr:last-child td { border-bottom: none; }
tr.client-row:hover td { background: rgba(248, 244, 238, .6); cursor: pointer; }
.client-cell { display: flex; align-items: center; gap: 10px; }
.client-av { width: 38px; height: 38px; border-radius: 11px; flex-shrink: 0; overflow: hidden; border: 2px solid rgba(200, 134, 10, .15); }
.client-av img { width: 100%; height: 100%; object-fit: cover; }
.client-av-placeholder { width: 100%; height: 100%; display: flex; align-items: center; justify-content: center; font-family: 'Syne', sans-serif; font-size: 15px; font-weight: 800; color: white; }
.client-meta h4 { font-weight: 700; font-size: 13px; }
.client-meta .sub { font-size: 10.5px; color: var(--soft); }
.owner-badge-yes { display: inline-flex; align-items: center; gap: 4px; padding: 3px 9px; border-radius: 20px; font-size: 10px; font-weight: 700; background: rgba(5, 150, 105, .12); color: var(--emerald); border: 1px solid rgba(5, 150, 105, .25); }
.owner-badge-no { display: inline-flex; align-items: center; gap: 4px; padding: 3px 9px; border-radius: 20px; font-size: 10px; font-weight: 700; background: rgba(239, 68, 68, .1); color: var(--red); border: 1px solid rgba(239, 68, 68, .2); }
.loyal-badge { display: inline-flex; align-items: center; gap: 4px; padding: 3px 9px; border-radius: 20px; font-size: 10px; font-weight: 700; background: rgba(200, 134, 10, .12); color: var(--gold); border: 1px solid rgba(200, 134, 10, .25); }
.unread-count-badge { display: inline-flex; align-items: center; gap: 4px; padding: 3px 9px; border-radius: 20px; font-size: 10px; font-weight: 800; background: rgba(224, 48, 96, .12); color: var(--rose); border: 1px solid rgba(224, 48, 96, .2); }
.act-cell { display: flex; gap: 5px; }
.act-btn { width: 30px; height: 30px; border-radius: 9px; border: 1.5px solid rgba(200, 134, 10, .15); background: transparent; display: flex; align-items: center; justify-content: center; cursor: pointer; transition: all .2s; color: var(--soft); font-size: 12px; }
.act-btn:hover { border-color: var(--blue-light); color: var(--blue-light); transform: scale(1.08); }
.act-btn.msg:hover { border-color: var(--teal); color: var(--teal); }
.act-btn.loyal-btn:hover { border-color: var(--gold); color: var(--gold); }
.act-btn.loyal-active { border-color: var(--gold); color: var(--gold); background: var(--gold-pale); }
.pagination { display: flex; justify-content: center; gap: 5px; padding: 16px; border-top: 1.5px solid rgba(200, 134, 10, .07); flex-wrap: wrap; }
.page-btn { padding: 6px 12px; border: 1.5px solid rgba(200, 134, 10, .15); border-radius: 9px; background: transparent; cursor: pointer; font-size: 12.5px; font-family: 'DM Sans', sans-serif; font-weight: 600; color: var(--mid); transition: all .2s; }
.page-btn.active { background: linear-gradient(115deg, var(--blue), var(--blue-light)); color: white; border-color: transparent; }
.page-btn:hover:not(.active) { border-color: var(--blue-light); color: var(--blue-light); }

/* MODAL FICHE CLIENT */
.modal { display: none; position: fixed; inset: 0; background: rgba(13, 11, 8, .78); backdrop-filter: blur(14px); z-index: 1000; align-items: center; justify-content: center; padding: 20px; }
.modal.open { display: flex; }
.modal-box { background: var(--white); border-radius: 28px; width: 780px; max-width: 100%; max-height: 92vh; overflow-y: auto; animation: mIn .32s cubic-bezier(.22, .97, .45, 1); border: 1.5px solid rgba(200, 134, 10, .1); box-shadow: 0 40px 80px rgba(0, 0, 0, .18); }
@keyframes mIn { from { opacity: 0; transform: scale(.93) translateY(-18px); } to { opacity: 1; transform: scale(1) translateY(0); } }
.profile-hero { background: linear-gradient(135deg, #0d1f5e 0%, #1a3aaa 50%, #c8860a 130%); padding: 28px 26px 22px; position: relative; overflow: hidden; }
.profile-hero::before { content: ''; position: absolute; inset: 0; background-image: linear-gradient(rgba(255, 255, 255, .04) 1px, transparent 1px), linear-gradient(90deg, rgba(255, 255, 255, .04) 1px, transparent 1px); background-size: 32px 32px; pointer-events: none; }
.ph-close { position: absolute; top: 14px; right: 14px; width: 34px; height: 34px; border-radius: 10px; background: rgba(255, 255, 255, .15); border: 1px solid rgba(255, 255, 255, .25); cursor: pointer; font-size: 18px; color: white; transition: all .2s; display: flex; align-items: center; justify-content: center; }
.ph-close:hover { background: rgba(239, 68, 68, .4); }
.ph-content { display: flex; align-items: center; gap: 18px; position: relative; z-index: 2; }
.ph-avatar { width: 80px; height: 80px; border-radius: 20px; flex-shrink: 0; overflow: hidden; border: 3px solid rgba(255, 255, 255, .35); box-shadow: 0 12px 28px rgba(0, 0, 0, .3); }
.ph-avatar img { width: 100%; height: 100%; object-fit: cover; }
.ph-av-placeholder { width: 100%; height: 100%; display: flex; align-items: center; justify-content: center; font-family: 'Syne', sans-serif; font-size: 28px; font-weight: 800; color: white; }
.ph-info { flex: 1; }
.ph-name { font-family: 'Syne', sans-serif; font-size: 21px; font-weight: 800; color: white; margin-bottom: 3px; }
.ph-email { font-size: 13px; color: rgba(255, 255, 255, .7); margin-bottom: 9px; }
.ph-badges { display: flex; gap: 7px; flex-wrap: wrap; }
.ph-badge { font-size: 10px; font-weight: 700; padding: 4px 11px; border-radius: 20px; }
.phb-online { background: rgba(16, 185, 129, .25); color: #4ade80; border: 1px solid rgba(74, 222, 128, .3); }
.phb-offline { background: rgba(255, 255, 255, .12); color: rgba(255, 255, 255, .7); border: 1px solid rgba(255, 255, 255, .2); }
.phb-id { background: rgba(200, 134, 10, .25); color: #fde9b0; border: 1px solid rgba(253, 233, 176, .3); }
.phb-owner { background: rgba(5, 150, 105, .3); color: #6ee7b7; border: 1px solid rgba(110, 231, 183, .3); }
.phb-loyal { background: rgba(200, 134, 10, .35); color: #fde9b0; border: 1px solid rgba(253, 233, 176, .4); }
.modal-body { padding: 22px 26px; }
.info-section { margin-bottom: 20px; }
.sec-title { display: flex; align-items: center; gap: 8px; font-family: 'Syne', sans-serif; font-size: 13px; font-weight: 700; color: var(--dark); margin-bottom: 12px; padding-bottom: 8px; border-bottom: 1.5px solid rgba(200, 134, 10, .1); }
.sec-ico { width: 26px; height: 26px; border-radius: 8px; display: flex; align-items: center; justify-content: center; font-size: 12px; }
.info-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 10px; }
.info-item { background: var(--bg2); border-radius: 12px; padding: 11px 13px; border: 1px solid rgba(200, 134, 10, .08); }
.info-lbl { font-size: 9.5px; font-weight: 700; text-transform: uppercase; letter-spacing: .8px; color: var(--soft); margin-bottom: 3px; }
.info-val { font-size: 13px; font-weight: 600; color: var(--dark); }
.prop-owned-item { display: flex; align-items: center; gap: 12px; background: linear-gradient(135deg, var(--emerald-pale), #f0fff8); border: 1.5px solid rgba(5, 150, 105, .2); border-radius: 14px; padding: 14px 16px; margin-bottom: 10px; transition: all .22s; cursor: pointer; text-decoration: none; }
.prop-owned-item:hover { transform: translateX(4px); border-color: var(--emerald); box-shadow: 0 4px 16px rgba(5, 150, 105, .15); }
.poi-icon { width: 42px; height: 42px; border-radius: 12px; background: rgba(5, 150, 105, .15); display: flex; align-items: center; justify-content: center; font-size: 18px; color: var(--emerald); flex-shrink: 0; }
.poi-info { flex: 1; }
.poi-title { font-family: 'Syne', sans-serif; font-size: 13.5px; font-weight: 700; color: var(--dark); }
.poi-meta { font-size: 11.5px; color: var(--mid); margin-top: 3px; }
.poi-price { font-family: 'Syne', sans-serif; font-size: 15px; font-weight: 800; color: var(--emerald); }
.poi-date { font-size: 10.5px; color: var(--soft); margin-top: 2px; }
.msg-unread-item { display: flex; gap: 10px; margin-bottom: 9px; }
.msg-unread-dot { width: 7px; height: 7px; border-radius: 50%; background: var(--rose); margin-top: 5px; flex-shrink: 0; animation: pulse 2s infinite; }
@keyframes pulse { 0%,100% { opacity: 1; } 50% { opacity: .5; } }
.msg-unread-bubble { flex: 1; background: var(--rose-pale); border-left: 3px solid var(--rose); border-radius: 0 12px 12px 12px; padding: 9px 12px; }
.msg-unread-txt { font-size: 13px; color: var(--dark); line-height: 1.5; }
.msg-unread-date { font-size: 10px; color: var(--soft); margin-top: 3px; }
.no-unread { text-align: center; padding: 20px; color: var(--soft); font-size: 13px; }
.no-unread i { font-size: 26px; display: block; margin-bottom: 8px; opacity: .3; }
.modal-actions { display: flex; gap: 9px; margin-top: 18px; padding-top: 16px; border-top: 1.5px solid rgba(200, 134, 10, .08); flex-wrap: wrap; }
.ma-btn { display: inline-flex; align-items: center; gap: 7px; padding: 10px 16px; border-radius: 12px; border: none; cursor: pointer; font-family: 'DM Sans', sans-serif; font-size: 13px; font-weight: 600; transition: all .22s; }
.ma-save { background: linear-gradient(115deg, var(--gold), var(--gold-light)); color: white; box-shadow: 0 5px 14px rgba(200, 134, 10, .28); }
.ma-save:hover { transform: translateY(-1px); box-shadow: 0 8px 20px rgba(200, 134, 10, .38); }
.ma-msg { background: var(--teal-pale); color: var(--teal); border: 1.5px solid rgba(14, 158, 138, .2); }
.ma-msg:hover { background: var(--teal); color: white; }
.ma-loyal { background: var(--gold-pale); color: var(--gold); border: 1.5px solid rgba(200, 134, 10, .25); }
.ma-loyal:hover { background: var(--gold); color: white; }
.ma-close { background: var(--bg2); color: var(--mid); border: 1.5px solid rgba(200, 134, 10, .15); }
.ma-close:hover { border-color: var(--rose); color: var(--rose); }
#toast { position: fixed; bottom: 24px; right: 24px; background: var(--white); border: 1.5px solid rgba(200, 134, 10, .18); border-left: 3px solid var(--blue); border-radius: 14px; padding: 12px 18px; font-size: 13px; font-weight: 500; color: var(--mid); box-shadow: 0 12px 40px rgba(0, 0, 0, .12); z-index: 9999; display: flex; align-items: center; gap: 9px; transform: translateY(80px); opacity: 0; transition: all .3s cubic-bezier(.34, 1.56, .64, 1); }
#toast.show { transform: translateY(0); opacity: 1; }
#toast i { color: var(--gold); }
.fade-1 { animation: fadeUp .5s .05s both; }
.fade-2 { animation: fadeUp .5s .15s both; }
.fade-3 { animation: fadeUp .5s .25s both; }
.fade-4 { animation: fadeUp .5s .35s both; }

/* MODAL PROFIL AMÉLIORÉ */
.profile-modal { max-width: 520px; width: 100%; background: var(--white); border-radius: 28px; overflow: hidden; }
.pm-header { background: linear-gradient(135deg, #0d1f5e, #1a3aaa); padding: 24px 28px; display: flex; justify-content: space-between; align-items: flex-start; }
.pm-header h2 { color: white; font-family: 'Syne', sans-serif; font-size: 20px; margin: 0; }
.pm-header p { color: rgba(255,255,255,0.6); font-size: 12px; margin: 4px 0 0; }
.pm-close { width: 32px; height: 32px; background: rgba(255,255,255,0.1); border-radius: 10px; display: flex; align-items: center; justify-content: center; cursor: pointer; color: white; border: none; transition: all 0.2s; }
.pm-close:hover { background: rgba(239,68,68,0.4); }
.pm-body { padding: 28px; }
.pm-avatar-area { display: flex; align-items: center; gap: 18px; margin-bottom: 28px; padding-bottom: 20px; border-bottom: 1px solid rgba(200,134,10,0.1); }
.pm-avatar { width: 70px; height: 70px; border-radius: 20px; background: linear-gradient(135deg, var(--gold), var(--gold-light)); display: flex; align-items: center; justify-content: center; font-size: 28px; font-weight: 800; color: white; position: relative; overflow: hidden; }
.pm-avatar img { width: 100%; height: 100%; object-fit: cover; }
.pm-avatar-edit { position: absolute; bottom: -4px; right: -4px; width: 28px; height: 28px; background: var(--gold); border-radius: 10px; display: flex; align-items: center; justify-content: center; cursor: pointer; border: 2px solid white; font-size: 12px; color: white; transition: all 0.2s; }
.pm-avatar-edit:hover { transform: scale(1.05); background: var(--gold-light); }
.pm-avatar-info h4 { font-size: 16px; font-weight: 700; color: var(--dark); margin: 0; }
.pm-avatar-info span { font-size: 11px; color: var(--soft); background: var(--gold-pale); padding: 3px 10px; border-radius: 20px; }
.pm-field { margin-bottom: 18px; }
.pm-field label { display: flex; align-items: center; gap: 6px; font-size: 11px; font-weight: 700; color: var(--mid); text-transform: uppercase; margin-bottom: 6px; }
.pm-field label i { color: var(--gold); font-size: 11px; }
.pm-field input, .pm-field select { width: 100%; padding: 11px 14px; border: 1.5px solid rgba(200,134,10,0.15); border-radius: 14px; font-size: 13px; background: var(--bg2); color: var(--dark); outline: none; transition: all 0.2s; }
.pm-field input:focus, .pm-field select:focus { border-color: var(--blue-light); box-shadow: 0 0 0 3px rgba(79,126,248,0.1); }
.pm-field input:read-only { background: var(--bg); cursor: not-allowed; opacity: 0.7; }
.pm-pw-wrapper { position: relative; }
.pm-pw-wrapper input { padding-right: 42px; }
.pm-pw-toggle { position: absolute; right: 12px; top: 50%; transform: translateY(-50%); background: none; border: none; color: var(--soft); cursor: pointer; font-size: 14px; }
.pm-pw-toggle:hover { color: var(--gold); }
.pm-divider { margin: 24px 0 18px; text-align: center; position: relative; }
.pm-divider::before { content: ''; position: absolute; left: 0; top: 50%; width: 100%; height: 1px; background: linear-gradient(90deg, transparent, rgba(200,134,10,0.2), transparent); }
.pm-divider span { background: var(--white); padding: 0 12px; font-size: 10px; font-weight: 700; color: var(--mid); position: relative; }
.pm-footer { padding: 18px 28px 24px; border-top: 1px solid rgba(200,134,10,0.08); display: flex; justify-content: flex-end; gap: 12px; background: var(--bg2); }
.pm-btn { padding: 10px 20px; border-radius: 14px; font-size: 13px; font-weight: 600; cursor: pointer; border: none; transition: all 0.2s; display: inline-flex; align-items: center; gap: 6px; }
.pm-save { background: linear-gradient(115deg, var(--gold), var(--gold-light)); color: white; box-shadow: 0 4px 12px rgba(200,134,10,0.3); }
.pm-save:hover { transform: translateY(-1px); box-shadow: 0 6px 16px rgba(200,134,10,0.4); }
.pm-cancel { background: var(--bg); color: var(--mid); border: 1.5px solid rgba(200,134,10,0.15); }
.pm-cancel:hover { border-color: var(--rose); color: var(--rose); }

/* Mode sombre corrections */
body.dark-theme .stat-card,
body.dark-theme .content-card,
body.dark-theme .quick-action,
body.dark-theme .modal-box,
body.dark-theme .overlay-content,
body.dark-theme .profile-modal {
    background: var(--white);
    border-color: rgba(255,255,255,.08);
}
body.dark-theme .stat-lbl,
body.dark-theme .qa-text p,
body.dark-theme .ch-sub,
body.dark-theme .prop-meta span,
body.dark-theme .pm-divider span {
    color: var(--soft);
}
body.dark-theme td,
body.dark-theme .prop-meta h4,
body.dark-theme .qa-text h4,
body.dark-theme .ch-title,
body.dark-theme .pm-avatar-info h4 {
    color: var(--dark);
}
body.dark-theme thead tr {
    background: rgba(255,255,255,.05);
}
body.dark-theme tr:hover td {
    background: rgba(255,255,255,.03);
}

@media (max-width:1100px) { .stats-row { grid-template-columns: repeat(3, 1fr); } }
@media (max-width:900px) { .sidebar { transform: translateX(-100%); } .main { margin-left: 0; padding: 20px; } .stats-row { grid-template-columns: repeat(2, 1fr); } }
@media (max-width:560px) { .stats-row { grid-template-columns: 1fr; } .info-grid { grid-template-columns: 1fr; } }
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

// Application du thème
(function() {
    var theme = localStorage.getItem('fredon_theme') || 'light';
    if (theme === 'dark') {
        document.body.classList.add('dark-theme');
    }
})();
</script>

<canvas id="bgCanvas"></canvas>

<div id="toast"><i class="fas fa-check-circle"></i><span id="toastMsg">OK</span></div>

<div class="layout">

<aside class="sidebar">
    <div class="sidebar-grid"></div>
    <div class="logo-area" style="padding: 20px 18px 18px; gap: 14px;">
    <img src="${pageContext.request.contextPath}/immo/admin/images/Logo.jpg"
         alt="Fredon"
         style="width: 68px; height: 68px; object-fit: cover; border-radius: 18px; box-shadow: 0 6px 22px rgba(0,0,0,.45), 0 0 0 2px rgba(255,255,255,.2);">
    <div class="logo-text-wrap">
        <span class="logo-name" style="font-size: 26px;">Fredon</span>
        <span class="logo-sub"><%= TranslateUtil.t(lang,"real_estate_agency") %></span>
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
        <a href="${pageContext.request.contextPath}/admin/clients" class="nav-item active"> <i class="fas fa-users"></i> <%= TranslateUtil.t(lang, "clients") %></a>
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
        <a href="${pageContext.request.contextPath}/admin/setting" class="nav-item"><i class="fas fa-cog"></i> <%= TranslateUtil.t(lang, "settings") %></a>
        <a href="${pageContext.request.contextPath}/logout" class="nav-item logout"> <i class="fas fa-sign-out-alt"></i> <%= TranslateUtil.t(lang, "logout") %></a>
    </nav>
    <div class="user-bottom" onclick="openProfileModal()">
       <div class="u-avatar">
    <%
        String adminProfilePic = null;
        try {
            Connection conn = DriverManager.getConnection("jdbc:mysql://localhost:3306/quickchat", "root", "");
            PreparedStatement pstmt = conn.prepareStatement("SELECT profile_pic FROM users WHERE id = 9");
            ResultSet rs = pstmt.executeQuery();
            if (rs.next()) {
                adminProfilePic = rs.getString("profile_pic");
            }
            rs.close(); pstmt.close(); conn.close();
        } catch(Exception e) {}
        
        if (adminProfilePic != null && !adminProfilePic.isEmpty()) {
    %>
        <img src="${pageContext.request.contextPath}/avatars/<%= adminProfilePic %>" style="width:100%;height:100%;object-fit:cover;border-radius:12px;">
    <% } else { %>
        <%= adminInitial %>
    <% } %>
</div>
        <div class="u-info">
            <div class="u-name"><%= adminName %></div>
            <div class="u-role"><%= TranslateUtil.t(lang,"admin") %></div>
        </div>
        <div class="u-dot"></div>
    </div>
</aside>

<main class="main">

    <div class="top-bar fade-1">
        <div class="page-title">
            <h1><%= TranslateUtil.t(lang,"client_management") %></h1>
            <p><i class="fas fa-users" style="color:var(--gold);margin-right:4px;"></i><%= TranslateUtil.t(lang,"track_clients") %></p>
        </div>
        <div class="top-right">
            <a href="${pageContext.request.contextPath}/admin/notifications" class="notif-wrap">
                <div class="icon-circle">
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
            <a href="${pageContext.request.contextPath}/admin/setting" class="icon-circle"> <i class="fas fa-cog"></i></a>
        </div>
    </div>

    <!-- ── STATS ── -->
   <div class="stats-row fade-2">
    <div class="stat-card sc-blue">
        <div class="stat-top"><div class="stat-ico ico-blue"><i class="fas fa-users"></i></div><span class="stat-badge badge-up-blue">Total</span></div>
        <div class="stat-val val-blue"><%= totalClients %></div>
        <div class="stat-lbl"><%= TranslateUtil.t(lang,"total_clients") %></div>
        <div class="stat-bar"><div class="stat-fill fill-blue" style="width:<%= Math.min(100,totalClients*2) %>%"></div></div>
    </div>
    <div class="stat-card sc-gold">
        <div class="stat-top"><div class="stat-ico ico-gold"><i class="fas fa-calendar-plus"></i></div><span class="stat-badge badge-up-gold">↑ Mois</span></div>
        <div class="stat-val val-gold"><%= newThisMonth %></div>
        <div class="stat-lbl"><%= TranslateUtil.t(lang,"new_this_month") %></div>
        <div class="stat-bar"><div class="stat-fill fill-gold" style="width:<%= Math.min(100,newThisMonth*8) %>%"></div></div>
    </div>
    <div class="stat-card sc-teal">
        <div class="stat-top"><div class="stat-ico ico-teal"><i class="fas fa-user-check"></i></div><span class="stat-badge badge-up-teal">Actifs</span></div>
        <div class="stat-val val-teal"><%= activeClients %></div>
        <div class="stat-lbl"><%= TranslateUtil.t(lang,"active_clients_30d") %></div>
        <div class="stat-bar"><div class="stat-fill fill-teal" style="width:<%= totalClients>0?Math.min(100,activeClients*100/totalClients):0 %>%"></div></div>
    </div>
</div>

    <!-- ── FILTRES ── -->
    <div class="filters-bar fade-3">
        <div class="search-wrap"><i class="fas fa-search"></i><input type="text" id="searchInput" placeholder="<%= TranslateUtil.t(lang,"search_by_name_email") %>" oninput="filterClients()" autocomplete="new-password" readonly onfocus="this.removeAttribute('readonly')"></div>
        <select class="filter-sel" id="ownerFilterSel" onchange="filterClients()">
            <option value="all">👥 <%= TranslateUtil.t(lang, "all_clients") %></option>
            <option value="owner">🏠 <%= TranslateUtil.t(lang, "owners") %></option>
            <option value="notowner">🔍 <%= TranslateUtil.t(lang, "non_owners") %></option>
            <option value="loyal">⭐ <%= TranslateUtil.t(lang, "loyal_clients") %></option>
        </select>
        <select class="filter-sel" id="dateFilter" onchange="filterClients()">
            <option value="all"><%= TranslateUtil.t(lang, "all_periods") %></option>
            <option value="week"><%= TranslateUtil.t(lang, "this_week") %></option>
            <option value="month"><%= TranslateUtil.t(lang, "this_month") %></option>
            <option value="year"><%= TranslateUtil.t(lang, "this_year") %></option>
        </select>
        <div class="export-group">
            <button class="btn-export btn-csv" onclick="exportCSV()"><i class="fas fa-file-csv"></i> CSV</button>
            <button class="btn-export btn-pdf" onclick="exportPDF()"><i class="fas fa-file-pdf"></i> PDF</button>
        </div>
    </div>

    <!-- ── TABLE ── -->
    <div class="table-card fade-4">
        <div class="card-head">
            <div class="ch-left">
                <div class="ch-icon"><i class="fas fa-users"></i></div>
                <div>
                    <div class="ch-title"><%= TranslateUtil.t(lang, "clients_list_title") %></div>
                    <div class="ch-sub"><%= TranslateUtil.t(lang, "click_client_details") %></div>
                </div>
            </div>
            <span class="clients-count" id="clientsCountBadge"><%= clients.size() %> client<%= clients.size()>1?"s":"" %></span>
        </div>

        <div class="tbl-wrap">
            <table id="clientsTable">
                <thead>
                    <tr>
                        <th><%= TranslateUtil.t(lang, "client") %></th>
                        <th><%= TranslateUtil.t(lang, "email") %></th>
                        <th><%= TranslateUtil.t(lang, "owner_status") %></th>
                        <th><%= TranslateUtil.t(lang, "unread_messages_label") %></th>
                        <th><%= TranslateUtil.t(lang, "registration_date") %></th>
                        <th><%= TranslateUtil.t(lang, "actions") %></th>
                    </tr>
                </thead>
                <tbody id="clientsBody">
                    <% int colorIdx=0;
                       for (Map<String,Object> client : clients) {
                         String uname       = (String) client.get("username");
                         String email       = (String) client.get("email");
                         String avatarUrl   = client.get("avatar") != null ? client.get("avatar").toString() : null;
                         String initial     = uname!=null&&!uname.isEmpty() ? uname.substring(0,1).toUpperCase() : "?";
                         String avColor     = avatarColors[colorIdx % avatarColors.length];
                         colorIdx++;
                         String displayName = client.get("display_name") != null ? client.get("display_name").toString() : uname;
                         String phone       = client.get("phone") != null ? client.get("phone").toString() : "";
                         String createdStr  = client.get("created_at") != null ? sdfDisp.format(client.get("created_at")) : "-";
                         boolean isOwner    = (Boolean) client.get("is_owner");
                         boolean isLoyal    = (Boolean) client.get("is_loyal");
                         int unreadCnt      = (int) client.get("unread_count");
                         @SuppressWarnings("unchecked")
                         List<Map<String,Object>> ownedProps = (List<Map<String,Object>>) client.get("owned_properties");

                         StringBuilder propsJson = new StringBuilder("[");
                         for (int pi = 0; pi < ownedProps.size(); pi++) {
                             Map<String,Object> pm = ownedProps.get(pi);
                             if (pi > 0) propsJson.append(",");
                             String purchaseDateStr = "";
                             if (pm.get("purchase_date") != null) {
                                 java.util.Date date = (java.util.Date) pm.get("purchase_date");
                                 purchaseDateStr = sdfFull.format(date);
                             }
                             String title = pm.get("title") != null ? pm.get("title").toString().replace("\"", "\\\"").replace("\n", " ").replace("\r", " ") : "";
                             String location = pm.get("location") != null ? pm.get("location").toString().replace("\"", "\\\"").replace("\n", " ").replace("\r", " ") : "";
                             String type = pm.get("type") != null ? pm.get("type").toString() : "";
                             String price = pm.get("price") != null ? String.format("%,.0f", (Double)pm.get("price")) : "0";
                             propsJson.append("{")
                                 .append("\"id\":\"").append(pm.get("id")).append("\",")
                                 .append("\"title\":\"").append(title).append("\",")
                                 .append("\"location\":\"").append(location).append("\",")
                                 .append("\"price\":\"").append(price).append("\",")
                                 .append("\"type\":\"").append(type).append("\",")
                                 .append("\"purchase_date\":\"").append(purchaseDateStr).append("\"")
                                 .append("}");
                         }
                         propsJson.append("]");

                         StringBuilder msgsJson = new StringBuilder("[");
                         @SuppressWarnings("unchecked")
                         List<Map<String,Object>> unreadMsgs = (List<Map<String,Object>>) client.get("unread_msgs");
                         for (int mi=0; mi<unreadMsgs.size(); mi++) {
                             Map<String,Object> mm = unreadMsgs.get(mi);
                             if (mi>0) msgsJson.append(",");
                             String msgDate = mm.get("created_at")!=null ? sdfFull.format(mm.get("created_at")) : "-";
                             String msgContent = mm.get("content")!=null ? mm.get("content").toString().replace("\"","'").replace("<","&lt;") : "";
                             msgsJson.append("{")
                               .append("\"content\":\"").append(msgContent).append("\",")
                               .append("\"date\":\"").append(msgDate).append("\"")
                               .append("}");
                         }
                         msgsJson.append("]");
                    %>
                    <tr class="client-row" data-id="<%= client.get("id") %>" data-name="<%= uname %>" data-email="<%= email %>" data-created="<%= createdStr %>" data-avatar="<%= avatarUrl!=null?avatarUrl:"" %>" data-color="<%= avColor %>" data-phone="<%= phone %>" data-display="<%= displayName %>" data-owner="<%= isOwner %>" data-loyal="<%= isLoyal %>" data-unread="<%= unreadCnt %>" data-props='<%= propsJson.toString() %>' data-msgs='<%= msgsJson.toString() %>' onclick="openModal(this)">
                        <td>
                            <div class="client-cell">
                                <div class="client-av">
                                    <% if (avatarUrl!=null&&!avatarUrl.isEmpty()) { %>
                                    <img src="${pageContext.request.contextPath}/uploads/<%= avatarUrl %>" alt="<%= uname %>">
                                    <% } else { %>
                                    <div class="client-av-placeholder" style="background:<%= avColor %>"><%= initial %></div>
                                    <% } %>
                                </div>
                                <div class="client-meta">
                                    <h4><%= uname %></h4>
                                    <div class="sub" style="display:flex;gap:5px;flex-wrap:wrap;margin-top:3px;">
                                        <% if (isLoyal) { %><span class="loyal-badge"><i class="fas fa-star"></i> <%= TranslateUtil.t(lang, "loyal") %></span><% } %>
                                    </div>
                                </div>
                            </div>
                        </td>
                        <td style="color: var(--mid); font-size: 12.5px;"><%= email %></td>
                        <td style="min-width: 100px;">
                            <% if(isOwner){ %>
                                <span class="owner-badge-yes" id="ownerBadge_<%= client.get("id") %>">
                                    <i class="fas fa-check-circle"></i> <%= TranslateUtil.t(lang, "yes") %>
                                </span>
                            <% } else { %>
                                <span class="owner-badge-no" id="ownerBadge_<%= client.get("id") %>">
                                    <i class="fas fa-times-circle"></i> <%= TranslateUtil.t(lang, "no") %>
                                </span>
                            <% } %>
                        </td>
                        <td>
                            <% if(unreadCnt>0){ %><span class="unread-count-badge"><i class="fas fa-envelope"></i> <%= unreadCnt %></span>
                            <% }else{ %><span style="font-size:11.5px;color:var(--soft);">0</span><% } %>
                        </td>
                        <td style="color: var(--soft); font-size: 12px;"><%= createdStr %></td>
                        <td onclick="event.stopPropagation()">
                            <div class="act-cell">
                                <button class="act-btn" title="<%= TranslateUtil.t(lang, "view_client") %>" onclick="openModal(this.closest('tr'))"><i class="fas fa-eye"></i></button>
                                <button class="act-btn msg" title="<%= TranslateUtil.t(lang, "send_message") %>" onclick="sendMsg('<%= client.get("id") %>')"><i class="fas fa-envelope"></i></button>
                            </div>
                        </td>
                    </tr>
                    <% } %>
                </tbody>
            </table>
        </div>
        <div class="pagination" id="pagination"></div>
    </div>

</main>
</div>

<!-- MODAL FICHE CLIENT -->
<div class="modal" id="clientModal">
    <div class="modal-box">
        <div class="profile-hero">
            <button class="ph-close" onclick="closeModal()">×</button>
            <div class="ph-content">
                <div class="ph-avatar" id="mAvatar"></div>
                <div class="ph-info">
                    <div class="ph-name" id="mName">—</div>
                    <div class="ph-email" id="mEmail">—</div>
                    <div class="ph-badges" id="mBadges"></div>
                </div>
            </div>
        </div>
        <div class="modal-body">
            <div class="info-section">
                <div class="sec-title"><div class="sec-ico" style="background:var(--blue-pale);color:var(--blue);"><i class="fas fa-id-card"></i></div><%= TranslateUtil.t(lang, "personal_information") %></div>
                <div class="info-grid">
                    <div class="info-item"><div class="info-lbl"><%= TranslateUtil.t(lang, "username") %></div><div class="info-val" id="mUsername">—</div></div>
                    <div class="info-item"><div class="info-lbl"><%= TranslateUtil.t(lang, "email") %></div><div class="info-val" id="mEmailInfo">—</div></div>
                    <div class="info-item"><div class="info-lbl"><%= TranslateUtil.t(lang, "phone") %></div><div class="info-val" id="mPhone"><%= TranslateUtil.t(lang, "not_provided") %></div></div>
                    <div class="info-item"><div class="info-lbl"><%= TranslateUtil.t(lang, "registration_date") %></div><div class="info-val" id="mCreated">—</div></div>
                </div>
            </div>
            
            <div class="info-section" id="mPropsSection">
                <div class="sec-title"><div class="sec-ico" style="background:var(--emerald-pale);color:var(--emerald);"><i class="fas fa-home"></i></div><%= TranslateUtil.t(lang, "acquired_properties") %> <span id="mPropsCount" style="font-size:11px;color:var(--soft);margin-left:6px;"></span></div>
                <div id="mPropsList"></div>
            </div>
            
            <div class="info-section">
                <div class="sec-title"><div class="sec-ico" style="background:var(--rose-pale);color:var(--rose);"><i class="fas fa-envelope-open-text"></i></div><%= TranslateUtil.t(lang, "unread_messages") %> <span id="mUnreadCount" style="font-size:11px;color:var(--soft);margin-left:6px;"></span></div>
                <div id="mMsgsList"></div>
            </div>
            
            <div class="info-section">
                <div class="sec-title"><div class="sec-ico" style="background:var(--teal-pale);color:var(--teal);"><i class="fas fa-sticky-note"></i></div><%= TranslateUtil.t(lang, "internal_notes") %></div>
                <div id="notesList"><div style="text-align:center;padding:14px;color:var(--soft);font-size:12.5px;font-style:italic;"><%= TranslateUtil.t(lang, "no_notes") %></div></div>
                <textarea id="newNote" rows="2" placeholder="<%= TranslateUtil.t(lang, "add_note_placeholder") %>" style="width:100%;padding:11px 13px;border:1.5px solid rgba(200,134,10,.15);border-radius:12px;font-family:'DM Sans',sans-serif;font-size:13px;background:var(--bg2);color:var(--dark);resize:vertical;outline:none;transition:all .2s;margin-top:10px;"></textarea>
            </div>
            
            <div class="modal-actions">
                <button class="ma-btn ma-save" onclick="addNote()"><i class="fas fa-save"></i> <%= TranslateUtil.t(lang, "save_note") %></button>
                <button class="ma-btn ma-msg" onclick="sendMsgModal()"><i class="fas fa-paper-plane"></i> <%= TranslateUtil.t(lang, "contact") %></button>
                <button class="ma-btn ma-loyal" id="mLoyalBtn" onclick="toggleLoyalModal()"><i class="fas fa-star"></i> <span id="mLoyalBtnTxt"><%= TranslateUtil.t(lang, "mark_loyal") %></span></button>
                <button class="ma-btn ma-close" onclick="closeModal()"><i class="fas fa-times"></i> <%= TranslateUtil.t(lang, "close") %></button>
            </div>
        </div>
    </div>
</div>

<!-- MODAL PROFIL AMÉLIORÉ -->
<div class="modal" id="profileModal">
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
                    <%
                        String adminPic = null;
                        try {
                            Connection c = DriverManager.getConnection("jdbc:mysql://localhost:3306/quickchat", "root", "");
                            PreparedStatement ps = c.prepareStatement("SELECT profile_pic FROM users WHERE id = 9");
                            ResultSet rs = ps.executeQuery();
                            if (rs.next()) adminPic = rs.getString("profile_pic");
                            rs.close(); ps.close(); c.close();
                        } catch(Exception e) {}
                        if (adminPic != null && !adminPic.isEmpty()) {
                    %>
                        <img src="${pageContext.request.contextPath}/avatars/<%= adminPic %>" alt="Admin">
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

<script>
/* ══ BG CANVAS ══ */
(function(){
  const canvas=document.getElementById('bgCanvas');
  const ctx=canvas.getContext('2d');
  let W,H,houses=[];
  function resize(){W=canvas.width=window.innerWidth;H=canvas.height=window.innerHeight;}
  resize(); window.addEventListener('resize',resize);
  function drawHouse(ctx,x,y,s,alpha,color){
    ctx.save();ctx.globalAlpha=alpha;ctx.strokeStyle=color;ctx.fillStyle=color;ctx.lineWidth=1.4*s;ctx.translate(x,y);
    ctx.beginPath();ctx.rect(-14*s,-8*s,28*s,20*s);ctx.stroke();
    ctx.beginPath();ctx.moveTo(-17*s,-8*s);ctx.lineTo(0,-22*s);ctx.lineTo(17*s,-8*s);ctx.closePath();ctx.stroke();
    ctx.beginPath();ctx.arc(0,7*s,5*s,Math.PI,0);ctx.rect(-5*s,2*s,10*s,5*s);ctx.stroke();
    ctx.strokeRect(-12*s,-5*s,7*s,6*s);ctx.strokeRect(5*s,-5*s,7*s,6*s);
    ctx.fillRect(5*s,-24*s,4*s,8*s);ctx.restore();
  }
  const COLORS=['#1f52d4','#c8860a','#0e9e8a','#e03060','#7c3aed','#0e7490','#b45309','#166534'];
  for(let i=0;i<16;i++) houses.push({x:Math.random()*1600,y:Math.random()*900,s:.5+Math.random()*1.3,alpha:.04+Math.random()*.055,color:COLORS[Math.floor(Math.random()*COLORS.length)],vx:(Math.random()-.5)*.11,vy:(Math.random()-.5)*.09});
  function animate(){ctx.clearRect(0,0,W,H);houses.forEach(h=>{h.x+=h.vx;h.y+=h.vy;if(h.x<-100)h.x=W+60;if(h.x>W+100)h.x=-60;if(h.y<-100)h.y=H+60;if(h.y>H+100)h.y=-60;drawHouse(ctx,h.x,h.y,h.s,h.alpha,h.color);});requestAnimationFrame(animate);}
  animate();
})();

/* ══ STAT BARS ══ */
document.querySelectorAll('.stat-fill').forEach(b=>{const w=b.style.width;b.style.width='0';setTimeout(()=>b.style.width=w,300);});

/* ══ TOAST ══ */
function showToast(msg,type='success'){
  const t=document.getElementById('toast');
  document.getElementById('toastMsg').textContent=msg;
  t.style.borderLeftColor=type==='error'?'var(--red)':type==='info'?'var(--blue)':'var(--gold)';
  t.classList.add('show');
  setTimeout(()=>t.classList.remove('show'),3200);
}

/* ══ FILTER JS ══ */
function filterClients(){
  const search = document.getElementById('searchInput').value.toLowerCase();
  const owner  = document.getElementById('ownerFilterSel').value;
  let visible  = 0;
  document.querySelectorAll('.client-row').forEach(row=>{
    const name  = (row.dataset.name||'').toLowerCase();
    const email = (row.dataset.email||'').toLowerCase();
    const own   = row.dataset.owner === 'true';
    const loyal = row.dataset.loyal === 'true';
    const matchSearch = name.includes(search)||email.includes(search);
    const matchOwner  = owner==='all' || (owner==='owner' && own) || (owner==='notowner' && !own) || (owner==='loyal' && loyal);
    const ok = matchSearch && matchOwner;
    row.style.display = ok?'':'none';
    if(ok) visible++;
  });
  document.getElementById('clientsCountBadge').textContent = visible + ' client' + (visible>1?'s':'');
  currentPage=1; buildPagination();
}

/* ══ PAGINATION ══ */
let currentPage=1; const PER_PAGE=12;
function buildPagination(){
  const rows=[...document.querySelectorAll('.client-row')].filter(r=>r.style.display!=='none');
  const total=Math.ceil(rows.length/PER_PAGE);
  rows.forEach((r,i)=>{r.style.display=(i>=(currentPage-1)*PER_PAGE&&i<currentPage*PER_PAGE)?'':'none';});
  const div=document.getElementById('pagination');
  if(total<=1){div.innerHTML='';return;}
  let html='';
  for(let i=1;i<=total;i++) html+='<button class="page-btn'+(i===currentPage?' active':'')+'" onclick="goPage('+i+')">'+i+'</button>';
  div.innerHTML=html;
}
function goPage(p){currentPage=p;buildPagination();}
setTimeout(()=>filterClients(),100);

/* ══ MODAL CLIENT ══ */
let currentClientId=null, currentClientLoyal=false;

function openModal(row){
    const d=row.dataset;
    currentClientId   = d.id;
    currentClientLoyal= d.loyal==='true';

    const mAv=document.getElementById('mAvatar');
    const init=(d.name||'?').charAt(0).toUpperCase();
    if(d.avatar && d.avatar !== '') {
        mAv.innerHTML='<img src="${pageContext.request.contextPath}/uploads/'+d.avatar+'" alt="'+d.name+'">';
    } else {
        mAv.innerHTML='<div class="ph-av-placeholder" style="background:'+d.color+'">'+init+'</div>';
    }
    
    document.getElementById('mName').textContent=(d.display&&d.display!==d.name)?d.display:d.name;
    document.getElementById('mEmail').textContent=d.email;

    let badges='';
    badges += '<span class="ph-badge phb-id">ID #'+d.id+'</span>';
    if(d.owner==='true') badges += '<span class="ph-badge phb-owner"><i class="fas fa-home"></i> '+t.owner+'</span>';
    if(d.loyal==='true') badges += '<span class="ph-badge phb-loyal"><i class="fas fa-star"></i> '+t.loyal_client+'</span>';
    document.getElementById('mBadges').innerHTML=badges;

    document.getElementById('mUsername').textContent=d.name;
    document.getElementById('mEmailInfo').textContent=d.email;
    document.getElementById('mPhone').textContent=d.phone||'Non renseigné';
    document.getElementById('mCreated').textContent=d.created;

    let props=[];
    try{ props=JSON.parse(d.props||'[]'); }catch(e){}
    const propsList=document.getElementById('mPropsList');
    const propsCount=document.getElementById('mPropsCount');
    if(props.length===0){
        propsCount.textContent='';
        propsList.innerHTML='<div style="text-align:center;padding:14px;color:var(--soft);font-size:12.5px;font-style:italic;">'+t.no_properties_acquired+'</div>';
    } else {
        propsCount.textContent='('+props.length+' bien'+(props.length>1?'s':'')+')';
        let html='';
        props.forEach(function(pm){
        	html+='<a href="${pageContext.request.contextPath}/immo/property-detail?id='+pm.id+'" class="prop-owned-item" target="_blank">';
            html+='<div class="poi-icon"><i class="fas fa-home"></i></div>';
            html+='<div class="poi-info"><div class="poi-title">'+esc(pm.title)+'</div>';
            html+='<div class="poi-meta"><i class="fas fa-map-marker-alt" style="color:var(--rose-light);font-size:10px;margin-right:4px;"></i>'+esc(pm.location)+' — '+esc(pm.type)+'</div>';
            html+='<div class="poi-date"><i class="fas fa-calendar-check" style="color:var(--emerald);font-size:10px;margin-right:4px;"></i>'+t.acquired_on+' '+esc(pm.purchase_date)+'</div>';
            html+='</div><div style="text-align:right;flex-shrink:0"><div class="poi-price">'+esc(pm.price)+' Ar</div></div></a>';
        });
        propsList.innerHTML=html;
    }

    let msgs=[];
    try{ msgs=JSON.parse(d.msgs||'[]'); }catch(e){}
    const msgsList=document.getElementById('mMsgsList');
    const unreadCount=document.getElementById('mUnreadCount');
    if(msgs.length===0){
        unreadCount.textContent='';
        msgsList.innerHTML='<div class="no-unread"><i class="fas fa-check-double"></i>'+t.no_unread_messages+'</div>';
    } else {
        unreadCount.textContent='('+msgs.length+' non lu'+(msgs.length>1?'s':'')+')';
        let html='';
        msgs.forEach(function(mm){
            html+='<div class="msg-unread-item"><div class="msg-unread-dot"></div><div class="msg-unread-bubble">';
            html+='<div class="msg-unread-txt">'+esc(mm.content)+'</div>';
            html+='<div class="msg-unread-date"><i class="fas fa-clock"></i> '+esc(mm.date)+'</div>';
            html+='</div></div>';
        });
        msgsList.innerHTML=html;
    }

    updateLoyalBtn();
    document.getElementById('notesList').innerHTML='<div style="text-align:center;padding:14px;color:var(--soft);font-size:12.5px;font-style:italic;">'+t.no_notes+'</div>';
    document.getElementById('newNote').value='';
    document.getElementById('clientModal').classList.add('open');
}

function updateLoyalBtn(){
    const btn=document.getElementById('mLoyalBtn');
    const txt=document.getElementById('mLoyalBtnTxt');
    if(currentClientLoyal){
        btn.style.background='linear-gradient(115deg,var(--gold),var(--gold-light))';
        btn.style.color='white';
        txt.textContent=t.remove_loyal;
    } else {
        btn.style.background='var(--gold-pale)';
        btn.style.color='var(--gold)';
        txt.textContent=t.mark_loyal;
    }
}

function closeModal(){ document.getElementById('clientModal').classList.remove('open'); }
document.getElementById('clientModal').addEventListener('click',function(e){if(e.target===this)closeModal();});

function addNote(){
    const v=document.getElementById('newNote').value.trim();
    if(!v){showToast(t.enter_note_before_saving,'error');return;}
    const list=document.getElementById('notesList');
    const now=new Date().toLocaleString('fr-FR');
    const div=document.createElement('div');
    div.style.cssText='background:var(--bg2);border-radius:12px;padding:11px 13px;margin-bottom:8px;border-left:3px solid var(--gold);';
    div.innerHTML='<div style="font-size:13px;color:var(--dark);">'+esc(v)+'</div><div style="font-size:10px;color:var(--soft);margin-top:3px;"><i class="fas fa-clock"></i> '+now+' — Admin</div>';
    if(list.querySelector('div[style*="font-style:italic"]')) list.innerHTML='';
    list.prepend(div);
    document.getElementById('newNote').value='';
    showToast(t.note_saved);
}

function sendMsg(id){window.location.href='${pageContext.request.contextPath}/chat?userId='+id;}
function sendMsgModal(){if(currentClientId) sendMsg(currentClientId);}

function toggleLoyalModal(){
    if(!currentClientId) return;
    currentClientLoyal = !currentClientLoyal;
    fetch('${pageContext.request.contextPath}/admin/update-client-loyal',{
        method:'POST',
        headers:{'Content-Type':'application/x-www-form-urlencoded'},
        body:'id='+currentClientId+'&loyal='+(currentClientLoyal?1:0)
    }).then(function(r){
        if(r.ok){
            updateLoyalBtn();
            const row=document.querySelector('.client-row[data-id="'+currentClientId+'"]');
            if(row){
                row.dataset.loyal=String(currentClientLoyal);
            }
            showToast(currentClientLoyal ? t.client_marked_loyal : t.loyal_status_removed);
        } else {showToast(t.update_error,'error'); }
    }).catch(function(){ showToast(t.network_error,'error'); });
}

/* ══ EXPORT CSV ══ */
function exportCSV(){
    let csv=t.csv_id+","+t.csv_name+","+t.csv_email+","+t.csv_owner+","+t.csv_loyal+","+t.csv_registration+"\n";
    document.querySelectorAll('.client-row').forEach(r=>{
        csv+=[r.dataset.id,r.dataset.name,r.dataset.email,
              r.dataset.owner==='true'?t.yes:t.no,
              r.dataset.loyal==='true'?t.yes:t.no,
              r.dataset.created].join(',')+'\n';
    });
    const a=document.createElement('a');
    a.href=URL.createObjectURL(new Blob(['\ufeff'+csv],{type:'text/csv;charset=utf-8'}));
    a.download='clients_fredon_'+new Date().toISOString().slice(0,10)+'.csv';
    a.click(); URL.revokeObjectURL(a.href);
    showToast(t.csv_exported);
}

/* ══ EXPORT PDF ══ */
function exportPDF(){
    const { jsPDF } = window.jspdf;
    const doc = new jsPDF({ orientation:'landscape', unit:'mm', format:'a4' });
    const PW = 297, PH = 210;

    doc.setFillColor(13,31,94);
    doc.roundedRect(0,0,PW,38,0,0,'F');
    doc.setFillColor(200,134,10);
    doc.rect(0,35,PW,3,'F');
    doc.setTextColor(255,220,80);
    doc.setFontSize(22);
    doc.setFont('helvetica','bold');
    doc.text('FREDON', 14, 16);
    doc.setTextColor(255,255,255);
    doc.setFontSize(10);
    doc.setFont('helvetica','normal');
    doc.text('AGENCE IMMOBILIÈRE', 14, 23);
    doc.setFontSize(13);
    doc.setFont('helvetica','bold');
    doc.setTextColor(255,255,255);
    doc.text('Gestion des clients', 14, 32);

    const today = new Date().toLocaleDateString('fr-FR',{day:'2-digit',month:'long',year:'numeric'});
    doc.setFontSize(9);
    doc.setFont('helvetica','normal');
    doc.setTextColor(200,200,200);
    doc.text('Exporté le : '+today, PW-14, 32, {align:'right'});

    doc.setFillColor(240,235,228);
    doc.roundedRect(14,42,PW-28,20,3,3,'F');
    doc.setFillColor(200,134,10);
    doc.roundedRect(14,42,3,20,0,0,'F');

    const rows=[...document.querySelectorAll('.client-row')];
    const ownerCount = rows.filter(r=>r.dataset.owner==='true').length;
    const loyalCount = rows.filter(r=>r.dataset.loyal==='true').length;

    doc.setFontSize(9);
    doc.setFont('helvetica','bold');
    doc.setTextColor(13,31,94);
    doc.text('RÉSUMÉ', 20, 50);
    doc.setFont('helvetica','normal');
    doc.setTextColor(50,50,50);
    doc.text(`Total : ${rows.length} clients`, 20, 56);
    doc.text(`Propriétaires : ${ownerCount}`, 130, 56);
    doc.text(`Fidèles : ${loyalCount}`, 185, 56);
    doc.text(`Export : ${today}`, 240, 56);

    const body = rows.map(r => [
        '#'+r.dataset.id,
        r.dataset.name,
        r.dataset.email,
        r.dataset.owner==='true'?'Oui':'Non',
        r.dataset.loyal==='true'?'Oui':'Non',
        r.dataset.created
    ]);

    doc.autoTable({
        startY: 66,
        head: [['#','Nom d\'utilisateur','Email','Propriétaire','Fidèle','Inscription']],
        body: body,
        styles: { font:'helvetica', fontSize:9, cellPadding:4, lineColor:[230,225,215], lineWidth:0.3 },
        headStyles: { fillColor:[13,31,94], textColor:[255,255,255], fontStyle:'bold', fontSize:9, cellPadding:{top:5,right:4,bottom:5,left:4} },
        alternateRowStyles: { fillColor:[248,244,238] },
        rowPageBreak: 'auto',
        columnStyles: { 0: { cellWidth:14, halign:'center', fontStyle:'bold' }, 1: { cellWidth:50 }, 2: { cellWidth:70 }, 3: { cellWidth:30, halign:'center' }, 4: { cellWidth:30, halign:'center' }, 5: { cellWidth:35, halign:'center' } },
        margin: { left:14, right:14 },
        didParseCell: function(data){
            if(data.section==='body'){
                if(data.column.index===3){
                    if(data.cell.raw==='Oui'){data.cell.styles.textColor=[5,150,105];data.cell.styles.fontStyle='bold';}
                    else{data.cell.styles.textColor=[239,68,68];data.cell.styles.fontStyle='bold';}
                }
                if(data.column.index===4){
                    if(data.cell.raw==='Oui'){data.cell.styles.textColor=[200,134,10];data.cell.styles.fontStyle='bold';}
                }
            }
        },
        didDrawPage: function(data){
            const pgCount=doc.getNumberOfPages();
            doc.setFillColor(13,31,94);
            doc.rect(0,PH-12,PW,12,'F');
            doc.setFontSize(8);
            doc.setFont('helvetica','normal');
            doc.setTextColor(180,180,180);
            doc.text('Fredon Immobilier — Document confidentiel', 14, PH-5);
            doc.text('Page '+data.pageNumber+' / '+pgCount, PW-14, PH-5, {align:'right'});
        }
    });

    const finalY = doc.lastAutoTable.finalY + 8;
    if(finalY < PH - 20){
        doc.setFontSize(9);
        doc.setFont('helvetica','italic');
        doc.setTextColor(120,100,70);
        doc.text('Total exporté : '+rows.length+' client'+(rows.length>1?'s':''), 14, finalY);
        doc.text('Propriétaires : '+ownerCount+' | Fidèles : '+loyalCount, 14, finalY+6);
    }
    doc.save('clients_fredon_'+new Date().toISOString().slice(0,10)+'.pdf');
    showToast(t.pdf_exported);
}

function esc(str){
    if(!str) return '';
    return String(str).replace(/[&<>"']/g,function(m){return({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[m]||m);});
}

/* ══ MODAL PROFIL AMÉLIORÉ ══ */
function togglePw(inputId, btn) {
    const input = document.getElementById(inputId);
    const icon = btn.querySelector('i');
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
    const confirmGroup = document.getElementById('pmConfirmGroup');
    if (e.target.value.length > 0) {
        confirmGroup.style.display = 'block';
    } else {
        confirmGroup.style.display = 'none';
        document.getElementById('pmConfirmPassword').value = '';
    }
});

document.getElementById('pmAvatarInput')?.addEventListener('change', function(e) {
    if (e.target.files && e.target.files[0]) {
        const reader = new FileReader();
        reader.onload = function(ev) {
            const avatarDiv = document.getElementById('pmAvatar');
            avatarDiv.innerHTML = `<img src="${ev.target.result}" alt="Admin"><div class="pm-avatar-edit" onclick="document.getElementById('pmAvatarInput').click()"><i class="fas fa-camera"></i></div>`;
        };
        reader.readAsDataURL(e.target.files[0]);
        showToast(t.avatar_uploaded, 'success');
    }
});

function saveProfile() {
    const newPw = document.getElementById('pmNewPassword').value;
    const confirmPw = document.getElementById('pmConfirmPassword').value;
    if (newPw && newPw !== confirmPw) {
        showToast(t.passwords_do_not_match, 'error');
        return;
    }
    showToast(t.profile_updated, 'success');
    setTimeout(() => closeProfileModal(), 1200);
}

function openProfileModal() { 
    document.getElementById('profileModal').classList.add('open'); 
}
function closeProfileModal() { 
    document.getElementById('profileModal').classList.remove('open'); 
}
document.getElementById('profileModal').addEventListener('click', function(e) { 
    if (e.target === this) closeProfileModal(); 
});

//Empêche l'accès aux pages après déconnexion
if (performance.navigation.type === 2) {
 window.location.href = '${pageContext.request.contextPath}/login';
}

</script>

</body>
</html>