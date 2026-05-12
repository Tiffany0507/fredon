<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.quickchat.model.User, com.quickchat.model.Message, com.quickchat.dao.UserDAO, com.quickchat.dao.MessageDAO, com.quickchat.dao.ReactionDAO, com.quickchat.dao.ContactNameDAO, java.util.List, java.util.Map"%>
<%@ page import="com.quickchat.dao.ConversationThemeDAO"%>
<%@ page import="com.quickchat.dao.BlockedUserDAO"%>
<%@ page import="com.quickchat.model.Group, com.quickchat.dao.GroupDAO, java.util.ArrayList"%>
<%@ page import="com.quickchat.dao.ConversationDAO"%>
<%@ page import="java.util.Collections"%>
<%@ page import="java.util.Comparator"%>
<%@ page import="com.quickchat.dao.GroupMessageDAO"%>
<%@ page import="java.util.HashMap"%>
<%@ page import="java.sql.*, java.text.*"%>
<%@ page import="com.quickchat.utils.TranslateUtil"%>

<%!
// Méthode d'échappement HTML sans dépendance externe
public String escapeHtml(String text) {
    if (text == null) return "";
    return text.replace("&", "&amp;")
               .replace("<", "&lt;")
               .replace(">", "&gt;")
               .replace("\"", "&quot;")
               .replace("'", "&#39;");
}

// Méthode d'échappement pour JavaScript
public String escapeJs(String text) {
    if (text == null) return "";
    return text.replace("\\", "\\\\")
               .replace("'", "\\'")
               .replace("\"", "\\\"")
               .replace("\n", "\\n")
               .replace("\r", "\\r");
}

public String formatLastSeen(String lastSeen) {
    if (lastSeen == null || lastSeen.isEmpty()) return "Récemment";
    try {
        java.text.SimpleDateFormat dbFormat = new java.text.SimpleDateFormat("yyyy-MM-dd HH:mm:ss");
        java.util.Date lastDate = dbFormat.parse(lastSeen);
        java.util.Date now = new java.util.Date();
        long diffMs = now.getTime() - lastDate.getTime();
        long diffMin = diffMs / (60 * 1000);
        java.text.SimpleDateFormat timeFormat = new java.text.SimpleDateFormat("HH:mm");
        java.text.SimpleDateFormat dayFormat  = new java.text.SimpleDateFormat("yyyyMMdd");
        java.util.Calendar calLast = java.util.Calendar.getInstance();
        java.util.Calendar calNow  = java.util.Calendar.getInstance();
        calLast.setTime(lastDate); calNow.setTime(now);
        boolean isToday     = dayFormat.format(lastDate).equals(dayFormat.format(now));
        boolean isYesterday = (calNow.get(java.util.Calendar.DAY_OF_YEAR) - calLast.get(java.util.Calendar.DAY_OF_YEAR) == 1)
                           && calNow.get(java.util.Calendar.YEAR) == calLast.get(java.util.Calendar.YEAR);
        if (diffMin < 1)         return "En ligne";
        if (diffMin < 60 && isToday) return "Vu il y a " + diffMin + " min";
        if (isToday)             return "Aujourd'hui à " + timeFormat.format(lastDate);
        if (isYesterday)         return "Hier à " + timeFormat.format(lastDate);
        String[] jours = {"Dimanche","Lundi","Mardi","Mercredi","Jeudi","Vendredi","Samedi"};
        String jour = jours[calLast.get(java.util.Calendar.DAY_OF_WEEK) - 1];
        if (calNow.get(java.util.Calendar.YEAR) == calLast.get(java.util.Calendar.YEAR))
            return jour + " " + calLast.get(java.util.Calendar.DAY_OF_MONTH) + "/" + (calLast.get(java.util.Calendar.MONTH)+1);
        return "Le " + new java.text.SimpleDateFormat("dd/MM/yyyy").format(lastDate);
    } catch(Exception e) { return "Récemment"; }
}
%>
<%
/* ── Langue ── */
String lang = "fr";
try {
    Class.forName("com.mysql.cj.jdbc.Driver");
    Connection langConn = DriverManager.getConnection("jdbc:mysql://localhost:3306/quickchat","root","");
    PreparedStatement langPs = langConn.prepareStatement("SELECT default_language FROM settings WHERE id=1");
    ResultSet langRs = langPs.executeQuery();
    if (langRs.next()) lang = langRs.getString("default_language");
    langRs.close(); langPs.close(); langConn.close();
} catch(Exception e) {}

/* ── Auth ── */
int selectedUserId = 0;
User user    = (User) session.getAttribute("user");
Integer adminId = (Integer) session.getAttribute("adminId");
int AGENT_ID = 9;

if (user == null && adminId == null) { response.sendRedirect("login.jsp"); return; }
if (user == null && adminId != null) {
    UserDAO tempDAO = new UserDAO();
    user = tempDAO.getUserById(999);
    if (user == null) { user = new User(); user.setId(999); user.setUsername("admin_user"); user.setDisplayName("Administrateur"); user.setEmail("admin@agence.com"); }
    session.setAttribute("user", user);
}

String userIdParam = request.getParameter("userId");
if (userIdParam != null && !userIdParam.isEmpty()) {
    try { selectedUserId = Integer.parseInt(userIdParam); } catch (NumberFormatException e) { selectedUserId = 0; }
}

ConversationThemeDAO themeDAO = new ConversationThemeDAO();
String conversationTheme = "default";
if (selectedUserId > 0) conversationTheme = themeDAO.getTheme(user.getId(), selectedUserId);

UserDAO userDAO = new UserDAO();
MessageDAO messageDAO = new MessageDAO();
ReactionDAO reactionDAO = new ReactionDAO();
ContactNameDAO contactNameDAO = new ContactNameDAO();

if (adminId == null && userIdParam == null) userIdParam = String.valueOf(AGENT_ID);

List<User> users;
if (user.getId() == 999)  { users = userDAO.getAllUsersExcept(999); users.removeIf(u -> u.getId() == 9); }
else if (adminId == null) { users = new ArrayList<>(); User ag = userDAO.getUserById(9); if (ag!=null) users.add(ag); }
else                      { users = userDAO.getAllUsersExcept(user.getId()); }
if (adminId == null) { List<User> f2 = new ArrayList<>(); for (User u:users) { if(u.getId()==AGENT_ID) f2.add(u); } users = f2; }

List<Message> messages = null;
User selectedUser = null;
if (selectedUserId > 0) {
    if (user.getId()==999) messages = messageDAO.getConversation(9, selectedUserId);
    else                   messages = messageDAO.getConversation(user.getId(), selectedUserId);
    selectedUser = userDAO.getUserById(selectedUserId);
    if (user.getId()==999) messageDAO.markAllMessagesAsRead(9, selectedUserId);
    else                   messageDAO.markAllMessagesAsRead(user.getId(), selectedUserId);
}

GroupDAO groupDAO = new GroupDAO();
List<Group> userGroups = groupDAO.getUserGroups(user.getId());

String adminName    = user.getDisplayName(); if (adminName==null||adminName.isEmpty()) adminName=user.getUsername();
String adminInitial = user.getInitial();

int unreadMessages = 0;
try { MessageDAO md2=new MessageDAO(); if(user.getId()==999) unreadMessages=md2.countUnreadMessagesForUser(9); else unreadMessages=md2.countUnreadMessagesForUser(user.getId()); } catch(Exception e){}

/* Traductions */
String t_messages  = TranslateUtil.t(lang,"messages");
String t_dashboard = TranslateUtil.t(lang,"dashboard");
String t_add_prop  = TranslateUtil.t(lang,"add_property");
String t_clients   = TranslateUtil.t(lang,"clients");
String t_stats     = TranslateUtil.t(lang,"statistics");
String t_view_site = TranslateUtil.t(lang,"view_site");
String t_logout    = TranslateUtil.t(lang,"logout");
String t_search    = TranslateUtil.t(lang,"search");
String t_online    = TranslateUtil.t(lang,"online");
String t_type_msg  = TranslateUtil.t(lang,"type_message");
String t_back_site = TranslateUtil.t(lang,"back_to_site");
String t_groups    = TranslateUtil.t(lang,"groups");
String t_private   = TranslateUtil.t(lang,"private_messages");
String t_deleted_ev= TranslateUtil.t(lang,"deleted_for_everyone");
String t_no_msg    = TranslateUtil.t(lang,"no_messages_yet");
String t_start_conv= TranslateUtil.t(lang,"start_conversation");
String t_select_chat=TranslateUtil.t(lang,"select_chat");
String t_messaging = TranslateUtil.t(lang,"messaging");
String t_settings  = TranslateUtil.t(lang,"settings");
String t_principal = TranslateUtil.t(lang,"principal");
String t_management= TranslateUtil.t(lang,"management");
String t_system    = TranslateUtil.t(lang,"system");
String t_admin     = TranslateUtil.t(lang,"admin");

/* ── MODIFICATION 1 : Publication partagée depuis index.jsp ── */
String sharedPropId       = request.getParameter("propertyId");
String sharedPropTitle    = request.getParameter("propertyTitle");
String sharedPropPriceStr = request.getParameter("propertyPrice");
String sharedPropImage    = request.getParameter("propertyImage");
String sharedPropType     = request.getParameter("propertyType");
String sharedPropLocation = request.getParameter("propertyLocation");
boolean hasSharedProp = (sharedPropId != null && !sharedPropId.trim().isEmpty());
long sharedPropPrice = 0;
if (hasSharedProp && sharedPropPriceStr != null) {
    try { sharedPropPrice = Long.parseLong(sharedPropPriceStr.trim()); } catch(Exception e2){}
}
%>
<!DOCTYPE html>
<html lang="<%= lang %>">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Fredon <%= t_messaging %> — <%=user.getDisplayName()%></title>
<link href="https://fonts.googleapis.com/css2?family=Syne:wght@400;600;700;800&family=DM+Sans:opsz,wght@9..40,300;9..40,400;9..40,500;9..40,600&display=swap" rel="stylesheet">
<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
<link rel="stylesheet" href="css/style.css">
<link rel="stylesheet" href="css/conversation_themes.css">
<script src="https://meet.jit.si/external_api.js"></script>
<style>
/* Vos styles CSS ici (gardez ceux que vous aviez) */
:root {
  --bleu: #1f52d4; --bleu2: #0e2d82; --bleu-l: rgba(31,82,212,.08);
  --bleu-glow: rgba(31,82,212,.22); --or: #b8900e; --or2: #d4a820;
  --gold: #c8860a; --gold-l: #e8a220; --bg: #f8f4ee; --bg2: #fdf9f3;
  --surface: #ffffff; --surface2: #f7f6f2; --border: rgba(0,0,0,.065);
  --border-h: rgba(0,0,0,.12); --tx: #0d0b08; --tx2: #6b5a3e; --tx3: #a89880;
  --input-bg: #f2ede4; --msg-recv-bg: #ffffff; --msg-recv-tx: #0d0b08;
  --msg-recv-bd: rgba(0,0,0,.065); --sep-bg: #f8f4ee; --sep-tx: #a89880;
  --sidebar-bg: #ffffff; --header-bg: #ffffff; --rouge: #dc2626;
  --vert: #059669; --violet: #7c3aed; --teal: #0e9e8a; --rose: #e03060;
  --sidebar-admin-w: 248px; --sidebar-chat-w: 296px; --header-h: 60px;
  --shadow: 0 4px 24px rgba(14,45,130,.08); --shadow-md: 0 8px 40px rgba(14,45,130,.12);
  --grad-brand: linear-gradient(135deg,var(--bleu2),var(--bleu));
  --bubble-sent: linear-gradient(135deg,var(--bleu2),var(--bleu));
  --bubble-sent-txt: #fff;
}
body.dm {
  --bg: #0a0f1e; --bg2: #0d1525; --surface: #111928; --surface2: #172034;
  --border: rgba(255,255,255,.06); --border-h: rgba(255,255,255,.12);
  --tx: #e8eeff; --tx2: #8898cc; --tx3: #3a4a70; --input-bg: #0d1525;
  --msg-recv-bg: rgba(255,255,255,.07); --msg-recv-tx: #e8eeff;
  --msg-recv-bd: rgba(255,255,255,.09); --sep-bg: #0a0f1e; --sep-tx: #3a4a70;
  --sidebar-bg: #111928; --header-bg: #111928; --bleu-l: rgba(31,82,212,.18);
}
*,*::before,*::after { box-sizing:border-box; margin:0; padding:0; }
html,body { height:100%; overflow:hidden; }
body { font-family:'DM Sans',sans-serif; background:var(--bg); color:var(--tx); transition:background .35s, color .35s; }
::-webkit-scrollbar { width:4px; }
::-webkit-scrollbar-thumb { background:linear-gradient(var(--bleu),var(--or)); border-radius:99px; }
.app-container { display:flex; height:100vh; overflow:hidden; }

/* Admin nav */
.admin-nav { width:var(--sidebar-admin-w); min-width:var(--sidebar-admin-w); background:linear-gradient(160deg,#0d1f5e 0%,#1a3aaa 45%,#0e2d82 75%,#0a1d58 100%); display:flex; flex-direction:column; overflow:hidden; flex-shrink:0; transition:width .3s,min-width .3s; position:relative; box-shadow:4px 0 24px rgba(14,45,130,.2); }
.admin-nav-header { display:flex; align-items:center; gap:11px; padding:20px 18px 18px; border-bottom:1px solid rgba(255,255,255,.1); position:relative; z-index:2; }
.admin-nav-header .nav-logo-svg { width:38px; height:38px; flex-shrink:0; filter:drop-shadow(0 4px 10px rgba(0,0,0,.3)); }
.admin-nav-header span { font-family:'Syne',sans-serif; font-weight:800; font-size:18px; color:#fff; }
.admin-nav-header small { display:block; font-size:8px; color:rgba(255,255,255,.45); letter-spacing:2px; text-transform:uppercase; margin-top:1px; }
.admin-nav-menu { flex:1; padding:14px 10px; display:flex; flex-direction:column; gap:2px; overflow-y:auto; position:relative; z-index:2; }
.nav-sec-label { font-size:9px; font-weight:700; letter-spacing:1.8px; text-transform:uppercase; color:rgba(255,255,255,.35); padding:12px 10px 5px; }
.admin-nav-item { display:flex; align-items:center; gap:10px; padding:10px 12px; border-radius:12px; color:rgba(255,255,255,.62); text-decoration:none; font-size:13px; font-weight:500; transition:all .2s; }
.admin-nav-item i { width:16px; text-align:center; font-size:13px; flex-shrink:0; }
.admin-nav-item:hover { background:rgba(255,255,255,.1); color:#fff; }
.admin-nav-item.active { background:rgba(255,255,255,.15); color:#fff; border-left:3px solid var(--gold-l); font-weight:600; }
.admin-nav-item.logout { color:rgba(255,110,110,.7); }
.admin-nav-item.logout:hover { background:rgba(220,38,38,.18); color:#fca5a5; }
.admin-nav-badge { margin-left:auto; background:var(--rouge); color:#fff; border-radius:99px; font-size:9px; font-weight:800; padding:2px 7px; min-width:20px; text-align:center; animation:pulse 2s ease-in-out infinite; }
@keyframes pulse { 0%,100%{opacity:1}50%{opacity:.6} }
.admin-nav-bottom { padding:14px 10px; border-top:1px solid rgba(255,255,255,.1); position:relative; z-index:2; }
.admin-nav-user { display:flex; align-items:center; gap:10px; padding:8px 10px; border-radius:12px; cursor:pointer; transition:background .2s; }
.admin-nav-user:hover { background:rgba(255,255,255,.08); }
.admin-nav-avatar { width:36px; height:36px; border-radius:10px; background:linear-gradient(135deg,var(--gold),var(--gold-l)); display:flex; align-items:center; justify-content:center; font-family:'Syne',sans-serif; font-weight:800; font-size:14px; color:#fff; flex-shrink:0; box-shadow:0 4px 10px rgba(200,134,10,.35); }
.admin-nav-name { font-size:12.5px; font-weight:700; color:#fff; }
.admin-nav-role { font-size:10px; color:rgba(255,255,255,.45); margin-top:1px; }
.admin-nav-online { width:8px; height:8px; border-radius:50%; background:#22c55e; margin-left:auto; box-shadow:0 0 0 2px rgba(34,197,94,.3); flex-shrink:0; }

/* Sidebar chat */
.sidebar { width:var(--sidebar-chat-w); min-width:var(--sidebar-chat-w); background:var(--sidebar-bg); border-right:1px solid var(--border); display:flex; flex-direction:column; overflow:hidden; flex-shrink:0; transition:width .3s,min-width .3s,background .35s,border-color .35s; position:relative; }
.back-to-site-btn { display:flex; align-items:center; gap:8px; padding:10px 14px; background:linear-gradient(135deg,rgba(31,82,212,.07),rgba(200,134,10,.04)); color:var(--bleu); font-size:12px; font-weight:700; text-decoration:none; border-bottom:1px solid rgba(31,82,212,.12); transition:background .2s; }
.back-to-site-btn:hover { background:rgba(31,82,212,.12); }
.sidebar-header { padding:14px 14px 12px; display:flex; align-items:center; justify-content:space-between; border-bottom:1px solid var(--border); background:var(--sidebar-bg); flex-shrink:0; transition:background .35s; }
.sidebar-logo-wrap { display:flex; align-items:center; gap:10px; }
.sidebar-logo-wrap svg { width:36px; height:36px; flex-shrink:0; }
.sidebar-brand-name { font-family:'Syne',sans-serif; font-weight:800; font-size:15px; background:linear-gradient(130deg,var(--bleu2),var(--bleu) 55%,var(--or)); -webkit-background-clip:text; background-clip:text; color:transparent; display:block; line-height:1; }
.sidebar-brand-tag { font-size:9px; color:var(--tx3); letter-spacing:2px; text-transform:uppercase; display:block; margin-top:2px; }
.profile-pic { width:34px; height:34px; border-radius:10px; background:var(--grad-brand); display:flex; align-items:center; justify-content:center; font-family:'Syne',sans-serif; font-weight:800; font-size:13px; color:#fff; cursor:pointer; overflow:hidden; flex-shrink:0; border:1.5px solid rgba(31,82,212,.15); transition:transform .2s,box-shadow .2s; }
.profile-pic:hover { transform:scale(1.05); box-shadow:0 4px 14px var(--bleu-glow); }
.profile-menu { position:absolute; top:66px; right:14px; background:var(--surface); border:1.5px solid var(--border-h); border-radius:16px; box-shadow:var(--shadow-md); min-width:210px; z-index:900; overflow:hidden; animation:fadeDown .2s ease; }
@keyframes fadeDown { from{opacity:0;transform:translateY(-8px)}to{opacity:1;transform:translateY(0)} }
.profile-menu-item { display:flex; align-items:center; gap:10px; padding:11px 14px; font-size:13px; color:var(--tx2); cursor:pointer; border-bottom:1px solid var(--border); transition:all .2s; }
.profile-menu-item:last-child { border-bottom:none; }
.profile-menu-item:hover { background:var(--bleu-l); color:var(--bleu); }
.profile-menu-item i { color:var(--bleu); width:14px; }
.logout-item { color:var(--rouge) !important; }
.logout-item i { color:var(--rouge) !important; }
.logout-item:hover { background:rgba(220,38,38,.07) !important; }
.sidebar-toolbar { display:flex; align-items:center; gap:6px; padding:8px 12px; border-bottom:1px solid var(--border); background:var(--sidebar-bg); flex-shrink:0; }
.stb-btn { width:32px; height:32px; border-radius:9px; background:var(--surface2); border:1px solid var(--border); display:flex; align-items:center; justify-content:center; cursor:pointer; color:var(--tx2); font-size:13px; transition:all .2s; position:relative; }
.stb-btn:hover { background:var(--bleu-l); color:var(--bleu); border-color:rgba(31,82,212,.2); }
.search-bar { padding:8px 12px; border-bottom:1px solid var(--border); flex-shrink:0; }
.search-box { display:flex; align-items:center; gap:7px; background:var(--surface2); border:1px solid var(--border); border-radius:11px; padding:7px 11px; transition:all .2s; }
.search-box:focus-within { border-color:rgba(31,82,212,.3); box-shadow:0 0 0 3px var(--bleu-l); }
.search-box i { color:var(--tx3); font-size:12px; flex-shrink:0; }
.search-box input { flex:1; border:none; background:transparent; color:var(--tx); font-family:'DM Sans',sans-serif; font-size:13px; outline:none; }
.search-box input::placeholder { color:var(--tx3); }
.contacts-list { flex:1; overflow-y:auto; background:var(--sidebar-bg); }
.contacts-section-label { padding:8px 14px 4px; font-size:10px; font-weight:700; letter-spacing:1.5px; text-transform:uppercase; color:var(--tx3); }
.contact-item { display:flex; align-items:center; gap:10px; padding:9px 12px; text-decoration:none; color:var(--tx); transition:background .2s; border-bottom:1px solid rgba(200,134,10,.05); cursor:pointer; }
.contact-item:hover { background:rgba(200,134,10,.04); }
.contact-item.active { background:rgba(31,82,212,.09); border-right:3px solid var(--bleu); }
.contact-avatar { width:40px; height:40px; border-radius:12px; background:var(--grad-brand); display:flex; align-items:center; justify-content:center; font-family:'Syne',sans-serif; font-weight:800; font-size:14px; color:#fff; position:relative; flex-shrink:0; overflow:hidden; }
.contact-avatar img { width:100%; height:100%; border-radius:12px; object-fit:cover; display:block; }
.online-dot { position:absolute; bottom:1px; right:1px; width:9px; height:9px; border-radius:50%; background:#22c55e; border:1.5px solid var(--surface); box-shadow:0 0 0 2px rgba(34,197,94,.2); }
.contact-info { flex:1; min-width:0; }
.contact-name { font-weight:600; font-size:13px; color:var(--tx); white-space:nowrap; overflow:hidden; text-overflow:ellipsis; line-height:1.3; }
.contact-preview { font-size:11.5px; color:var(--tx3); margin-top:2px; white-space:nowrap; overflow:hidden; text-overflow:ellipsis; display:flex; align-items:center; gap:4px; }
.contact-preview i { color:var(--bleu); font-size:10px; }
.contact-time { flex-shrink:0; display:flex; flex-direction:column; align-items:flex-end; gap:4px; }
.contact-time div:first-child { font-size:11px; color:var(--tx3); }
.unread-badge { background:var(--bleu); color:#fff; border-radius:99px; font-size:9.5px; font-weight:800; padding:2px 7px; min-width:20px; text-align:center; display:inline-block; }

/* Chat area */
.chat-area { flex:1; display:flex; flex-direction:column; overflow:hidden; background:var(--bg); min-width:0; transition:background .35s; }
.chat-header { height:var(--header-h); background:var(--header-bg); border-bottom:1px solid var(--border); display:flex; align-items:center; justify-content:space-between; padding:0 18px; flex-shrink:0; box-shadow:0 1px 8px rgba(14,45,130,.04); transition:background .35s; }
.chat-header-left { display:flex; align-items:center; gap:11px; }
.chat-header-avatar { width:38px; height:38px; border-radius:11px; background:var(--grad-brand); display:flex; align-items:center; justify-content:center; font-family:'Syne',sans-serif; font-weight:800; font-size:14px; color:#fff; overflow:hidden; flex-shrink:0; cursor:pointer; }
.chat-header-info h3 { font-family:'Syne',sans-serif; font-weight:700; font-size:14px; color:var(--tx); line-height:1.2; }
.chat-header-info p { font-size:11.5px; color:var(--tx3); margin-top:1px; }
.chat-header-info p.online { color:#22c55e; }
.chat-header-actions { display:flex; align-items:center; gap:5px; }
.hdr-btn { width:36px; height:36px; border-radius:10px; background:transparent; border:1px solid transparent; display:flex; align-items:center; justify-content:center; cursor:pointer; color:var(--tx2); font-size:15px; transition:all .2s; }
.hdr-btn:hover { background:var(--bleu-l); color:var(--bleu); border-color:rgba(31,82,212,.15); }
.hdr-menu-wrap { position:relative; }
.hdr-menu-popup { position:absolute; top:calc(100% + 8px); right:0; background:var(--surface); border:1.5px solid var(--border-h); border-radius:16px; box-shadow:var(--shadow-md); min-width:210px; z-index:800; overflow:hidden; display:none; animation:fadeDown .18s ease; }
.hdr-menu-popup.open { display:block; }
.hdr-menu-item { display:flex; align-items:center; gap:10px; padding:10px 14px; font-size:13px; color:var(--tx2); cursor:pointer; border-bottom:1px solid var(--border); transition:all .2s; }
.hdr-menu-item:last-child { border-bottom:none; }
.hdr-menu-item:hover { background:var(--bleu-l); color:var(--bleu); }
.hdr-menu-item i { width:14px; font-size:12px; color:var(--bleu); }
.hdr-menu-item.danger { color:var(--rouge); }
.hdr-menu-item.danger i { color:var(--rouge); }
.hdr-menu-item.danger:hover { background:rgba(220,38,38,.07); }

#searchBar { background:var(--header-bg); padding:8px 14px; border-bottom:1px solid var(--border); flex-shrink:0; }
#searchBar .search-inner { display:flex; gap:8px; align-items:center; background:var(--surface2); border:1px solid var(--border); border-radius:11px; padding:7px 12px; }
#searchInputChat { flex:1; border:none; background:transparent; color:var(--tx); font-family:'DM Sans',sans-serif; font-size:13px; outline:none; }
#searchInputChat::placeholder { color:var(--tx3); }
#closeSearch { cursor:pointer; color:var(--tx3); font-size:14px; }
.messages-container { flex:1; overflow-y:auto; padding:18px 22px; display:flex; flex-direction:column; gap:4px; background:var(--bg); transition:background .35s; }
.pinned-message { position:sticky; top:0; z-index:10; background:var(--surface); border-left:3px solid var(--or); border-radius:12px; padding:9px 12px; margin-bottom:10px; display:flex; align-items:center; justify-content:space-between; box-shadow:0 2px 10px rgba(0,0,0,.06); border:1px solid rgba(184,144,14,.2); }
.time-separator { display:flex; align-items:center; gap:12px; margin:8px 0; }
.time-separator::before,.time-separator::after { content:''; flex:1; height:1px; background:linear-gradient(90deg,transparent,var(--border-h),transparent); }
.time-separator span { font-size:11px; color:var(--sep-tx); white-space:nowrap; background:var(--sep-bg); padding:3px 10px; border:1px solid var(--border); border-radius:20px; }

.message { display:flex; align-items:flex-end; gap:8px; margin-bottom:3px; width:100%; animation:msgIn .22s ease both; }
@keyframes msgIn { from{opacity:0;transform:translateY(6px)}to{opacity:1;transform:translateY(0)} }
.message.sent { flex-direction:row-reverse; justify-content:flex-start; }
.message.sent .message-wrapper { align-items:flex-end; }
.message.received { flex-direction:row; justify-content:flex-start; }
.message.received .message-wrapper { align-items:flex-start; }
.message-avatar { width:30px; height:30px; flex-shrink:0; }
.message-wrapper { max-width:66%; display:flex; flex-direction:column; }
.message-bubble { padding:9px 13px; border-radius:18px; font-size:13.5px; line-height:1.55; word-break:break-word; position:relative; display:inline-block; }
.message.sent .message-bubble { background:var(--bubble-sent); color:var(--bubble-sent-txt); border-bottom-right-radius:4px; box-shadow:0 3px 12px var(--bleu-glow); }
.message.received .message-bubble { background:var(--msg-recv-bg); color:var(--msg-recv-tx); border:1px solid var(--msg-recv-bd); border-bottom-left-radius:4px; box-shadow:0 2px 6px rgba(0,0,0,.04); }
.message-info { display:flex; align-items:center; gap:4px; margin-top:3px; padding:0 3px; }
.message.sent .message-info { justify-content:flex-end; }
.message.received .message-info { justify-content:flex-start; }
.message-time { font-size:10.5px; color:var(--tx3); }
.deleted-message { font-size:12.5px; color:var(--tx3); font-style:italic; display:flex; align-items:center; gap:6px; }
.replied-message-preview { background:rgba(0,0,0,.06); border-left:3px solid var(--or); padding:5px 8px; margin-bottom:6px; border-radius:8px; font-size:11.5px; }
.message.sent .replied-message-preview { background:rgba(255,255,255,.15); border-color:var(--or2); }
.replied-message-preview strong { color:var(--or); font-weight:700; font-size:10.5px; }
.replied-message-preview div { color:var(--tx3); margin-top:2px; }
.message.sent .replied-message-preview div { color:rgba(255,255,255,.7); }
.message-reactions { margin-top:3px; }
.reactions-bar { display:flex; gap:3px; flex-wrap:wrap; }
.reaction-badge { background:var(--surface); border:1px solid var(--border); border-radius:99px; padding:2px 7px; font-size:12px; cursor:pointer; transition:all .2s; }
.reaction-badge:hover { transform:scale(1.1); }
.message-actions { display:none; gap:3px; margin-top:3px; background:var(--surface); border:1px solid var(--border); border-radius:24px; padding:4px 8px; box-shadow:var(--shadow); }
.message:hover .message-actions { display:flex; }
.message.sent .message-actions { justify-content:flex-end; }
.message-actions a { font-size:13px; text-decoration:none; padding:3px 5px; border-radius:6px; transition:background .2s; cursor:pointer; }
.message-actions a:hover { background:var(--bleu-l); }
.reaction-picker { position:relative; display:flex; align-items:center; cursor:pointer; color:var(--tx3); font-size:13px; padding:3px 5px; border-radius:6px; }
.reaction-picker:hover { background:var(--bleu-l); color:var(--bleu); }
.reaction-picker-popup { position:absolute; bottom:32px; left:0; background:var(--surface); border:1.5px solid var(--border-h); border-radius:14px; padding:7px 10px; display:none; gap:7px; box-shadow:var(--shadow-md); white-space:nowrap; z-index:100; flex-direction:row; }
.reaction-picker-popup span { font-size:19px; cursor:pointer; transition:transform .15s; }
.reaction-picker-popup span:hover { transform:scale(1.3); }
.delete-menu-wrapper { position:relative; }
.delete-menu { position:absolute; bottom:28px; right:0; background:var(--surface); border:1.5px solid var(--border-h); border-radius:12px; box-shadow:var(--shadow-md); min-width:210px; z-index:100; overflow:hidden; }
.delete-menu a { display:flex; align-items:center; gap:8px; padding:10px 12px; font-size:12.5px; color:var(--tx2); text-decoration:none; border-bottom:1px solid var(--border); transition:all .2s; cursor:pointer; }
.delete-menu a:last-child { border-bottom:none; }
.delete-menu a:hover { background:var(--bleu-l); color:var(--bleu); }
.edit-form { margin-top:5px; }
.edit-form form { display:flex; gap:6px; }
.edit-form input { flex:1; padding:7px 11px; border:1.5px solid rgba(31,82,212,.25); border-radius:9px; background:var(--surface); color:var(--tx); font-family:'DM Sans',sans-serif; font-size:13px; outline:none; }
.edit-form input:focus { border-color:var(--bleu); }
.edit-form button { padding:7px 12px; border-radius:9px; border:none; font-weight:600; font-size:12px; cursor:pointer; transition:all .2s; }
.edit-form button[type="submit"] { background:var(--bleu); color:#fff; }
.edit-form button[type="button"] { background:var(--surface2); color:var(--tx2); }

/* Fichier attaché */
.file-bubble { display:flex; align-items:center; gap:10px; padding:10px 14px; background:rgba(31,82,212,.1); border-radius:12px; border:1px solid rgba(31,82,212,.2); max-width:240px; cursor:pointer; transition:background .2s; }
.file-bubble:hover { background:rgba(31,82,212,.16); }
.file-ico { width:36px; height:36px; border-radius:10px; background:var(--bleu); display:flex; align-items:center; justify-content:center; color:#fff; font-size:16px; flex-shrink:0; }
.file-info { flex:1; min-width:0; }
.file-name { font-size:12.5px; font-weight:600; color:var(--tx); white-space:nowrap; overflow:hidden; text-overflow:ellipsis; }
.file-size { font-size:10.5px; color:var(--tx3); margin-top:2px; }
.message.sent .file-bubble { background:rgba(255,255,255,.15); border-color:rgba(255,255,255,.25); }
.message.sent .file-ico { background:rgba(255,255,255,.2); }
.message.sent .file-name { color:#fff; }
.message.sent .file-size { color:rgba(255,255,255,.65); }

.video-bubble { max-width:260px; }
.video-bubble video { width:100%; border-radius:12px; max-height:180px; object-fit:cover; }

/* Message input */
.message-input-area { padding:10px 14px; background:var(--header-bg); border-top:1px solid var(--border); display:flex; align-items:flex-end; gap:7px; flex-shrink:0; position:relative; transition:background .35s; }
#replyPreview { position:absolute; bottom:calc(100% + 4px); left:14px; right:14px; background:var(--surface); border:1px solid rgba(31,82,212,.2); border-left:3px solid var(--bleu); border-radius:11px; padding:7px 11px; display:none; z-index:10; }
#replyPreview .reply-name { font-size:11px; font-weight:700; color:var(--bleu); }
#replyPreviewContent { font-size:12px; color:var(--tx3); margin-top:2px; }

.input-left-tools { display:flex; gap:5px; align-items:center; flex-shrink:0; }
.tool-btn { width:34px; height:34px; border-radius:10px; background:var(--surface2); border:1px solid var(--border); display:flex; align-items:center; justify-content:center; cursor:pointer; color:var(--tx2); font-size:14px; transition:all .2s; flex-shrink:0; position:relative; }
.tool-btn:hover { background:var(--bleu-l); color:var(--bleu); border-color:rgba(31,82,212,.2); }
.photo-label { width:34px; height:34px; border-radius:10px; background:var(--surface2); border:1px solid var(--border); display:flex; align-items:center; justify-content:center; cursor:pointer; color:#a78bfa; font-size:14px; transition:all .2s; flex-shrink:0; }
.photo-label:hover { background:rgba(124,58,237,.1); color:#7c3aed; }

#messageForm { flex:1; display:flex; gap:7px; min-width:0; align-items:center; }
#messageInput { flex:1; padding:10px 14px; border:1.5px solid var(--border); border-radius:12px; background:var(--input-bg); color:var(--tx); font-family:'DM Sans',sans-serif; font-size:13.5px; outline:none; transition:all .2s; min-width:0; }
#messageInput:focus { border-color:rgba(31,82,212,.35); box-shadow:0 0 0 3px var(--bleu-l); background:var(--surface); }
#messageInput::placeholder { color:var(--tx3); }

.emoji-wrap-right { position:relative; flex-shrink:0; }
.emoji-trigger-btn { width:34px; height:34px; border-radius:10px; background:var(--surface2); border:1px solid var(--border); display:flex; align-items:center; justify-content:center; cursor:pointer; color:#f59e0b; font-size:16px; transition:all .2s; }
.emoji-trigger-btn:hover { background:rgba(245,158,11,.1); border-color:rgba(245,158,11,.3); }
.emoji-picker-panel { position:fixed; z-index:9990; background:var(--surface); border:1.5px solid var(--border-h); border-radius:20px; box-shadow:var(--shadow-md); width:272px; display:none; }
.emoji-picker-inner { padding:10px 12px; }
.emoji-tabs { display:flex; gap:4px; overflow-x:auto; scrollbar-width:none; margin-bottom:8px; padding-bottom:4px; border-bottom:1px solid var(--border); }
.emoji-tabs::-webkit-scrollbar { display:none; }
.emoji-tab { background:none; border:none; cursor:pointer; font-size:17px; padding:4px 6px; border-radius:8px; transition:background .15s; flex-shrink:0; }
.emoji-tab:hover,.emoji-tab.active { background:var(--bleu-l); }
.emoji-search-box { display:flex; align-items:center; gap:6px; background:var(--surface2); border:1px solid var(--border); border-radius:9px; padding:5px 9px; margin-bottom:8px; }
.emoji-search-box input { flex:1; border:none; background:transparent; color:var(--tx); font-size:12px; outline:none; }
.emoji-search-box input::placeholder { color:var(--tx3); }
.emoji-grid { display:grid; grid-template-columns:repeat(7,1fr); gap:3px; max-height:180px; overflow-y:auto; scrollbar-width:thin; }
.emoji-grid span { font-size:19px; cursor:pointer; text-align:center; padding:3px 2px; border-radius:7px; transition:background .12s,transform .12s; display:block; }
.emoji-grid span:hover { background:var(--bleu-l); transform:scale(1.2); }

#sendButton { width:38px; height:38px; border-radius:11px; background:var(--grad-brand); border:none; cursor:pointer; color:#fff; font-size:14px; flex-shrink:0; display:flex; align-items:center; justify-content:center; transition:all .2s; box-shadow:0 3px 12px var(--bleu-glow); }
#sendButton:hover { transform:translateY(-2px); box-shadow:0 6px 18px var(--bleu-glow); }

.left-panel { position:absolute; bottom:calc(100% + 10px); left:0; z-index:999; background:var(--surface); border:1.5px solid var(--border-h); border-radius:20px; box-shadow:var(--shadow-md); display:none; }
.gif-picker-panel { width:310px; }
.gif-picker-panel input { background:var(--surface2); border:1px solid var(--border); border-radius:9px; color:var(--tx); font-family:'DM Sans',sans-serif; font-size:13px; outline:none; width:100%; }
#searchGifBtn { background:var(--bleu); color:#fff; border:none; border-radius:9px; cursor:pointer; padding:8px 12px; }
.sticker-picker-panel { width:290px; }
.sticker-cats-header { padding:10px 12px; border-bottom:1px solid var(--border); }
.sticker-cats-label { font-size:10px; font-weight:700; color:var(--tx3); text-transform:uppercase; letter-spacing:1px; display:block; margin-bottom:7px; }
.sticker-cats-scroll { display:flex; gap:5px; overflow-x:auto; scrollbar-width:none; }
.sticker-cats-scroll::-webkit-scrollbar { display:none; }
.sticker-cat-pill { display:flex; align-items:center; gap:4px; padding:5px 10px; border-radius:99px; background:var(--surface2); border:1px solid var(--border); font-size:11px; font-weight:600; color:var(--tx2); cursor:pointer; white-space:nowrap; transition:all .2s; }
.sticker-cat-pill.active { background:var(--bleu-l); border-color:rgba(31,82,212,.3); color:var(--bleu); }
.voice-recorder-panel { width:250px; }
.voice-btn { border-radius:50%; width:44px; height:44px; display:inline-flex; align-items:center; justify-content:center; transition:transform .2s; }
.voice-btn:hover { transform:scale(1.06); }

.blocked-banner { background:var(--surface2); border:1px solid var(--border); border-radius:12px; padding:11px 14px; display:flex; align-items:center; justify-content:space-between; width:100%; }
.blocked-banner span { font-size:13px; color:var(--tx2); display:flex; align-items:center; gap:8px; }
.blocked-banner i { color:var(--rouge); }
.bb-btn { padding:7px 14px; border:none; border-radius:9px; font-size:12px; font-weight:600; cursor:pointer; transition:all .2s; }
.bb-btn.primary { background:var(--bleu); color:#fff; }
.bb-btn.danger { background:var(--rouge); color:#fff; }
.no-selection { flex:1; display:flex; flex-direction:column; align-items:center; justify-content:center; gap:12px; color:var(--tx3); text-align:center; padding:40px; }
.no-selection h2 { font-family:'Syne',sans-serif; font-size:20px; font-weight:700; color:var(--tx2); }

.ringing-overlay { position:fixed; bottom:24px; left:50%; transform:translateX(-50%); z-index:9997; background:var(--surface); border:1.5px solid var(--border-h); border-radius:24px; padding:18px 28px; box-shadow:0 20px 60px rgba(0,0,0,.22); display:none; flex-direction:column; align-items:center; gap:12px; min-width:320px; animation:slideUp .4s cubic-bezier(.22,.97,.45,1) both; }
.ringing-overlay.show { display:flex; }
@keyframes slideUp { from{opacity:0;transform:translateX(-50%) translateY(40px);}to{opacity:1;transform:translateX(-50%) translateY(0);} }
.ringing-avatar { width:64px; height:64px; border-radius:18px; background:var(--grad-brand); display:flex; align-items:center; justify-content:center; font-family:'Syne',sans-serif; font-size:24px; font-weight:800; color:#fff; animation:rPulse 1s ease-in-out infinite; }
@keyframes rPulse { 0%,100%{box-shadow:0 0 0 0 rgba(31,82,212,.4);}50%{box-shadow:0 0 0 16px rgba(31,82,212,.0);} }
.ringing-label h4 { font-family:'Syne',sans-serif; font-weight:700; font-size:16px; color:var(--tx); }
.ringing-label p { font-size:12px; color:var(--tx3); margin-top:3px; }
.ringing-cancel-btn { width:48px; height:48px; border-radius:50%; background:var(--rouge); border:none; color:#fff; font-size:18px; cursor:pointer; display:flex; align-items:center; justify-content:center; transition:all .2s; box-shadow:0 4px 14px rgba(220,38,38,.4); }
.ringing-cancel-btn:hover { transform:scale(1.1); }

.modal-overlay { display:none; position:fixed; inset:0; background:rgba(0,0,0,.55); backdrop-filter:blur(8px); z-index:5000; align-items:center; justify-content:center; }
.modal-overlay.open { display:flex; }
.modal-box { background:var(--surface); border-radius:22px; padding:26px; box-shadow:0 40px 80px rgba(14,45,130,.18); animation:fadeDown .22s ease; border:1.5px solid var(--border-h); }
.modal-box h3 { font-family:'Syne',sans-serif; font-size:17px; font-weight:700; margin-bottom:14px; color:var(--tx); }
.modal-input { width:100%; padding:10px 13px; border:1.5px solid var(--border); border-radius:11px; background:var(--surface2); color:var(--tx); font-family:'DM Sans',sans-serif; font-size:13.5px; outline:none; transition:all .2s; }
.modal-input:focus { border-color:rgba(31,82,212,.35); box-shadow:0 0 0 3px var(--bleu-l); }
.modal-textarea { resize:none; }
.modal-btns { display:flex; gap:9px; margin-top:18px; }
.modal-btn { flex:1; padding:10px; border:none; border-radius:11px; font-weight:700; font-size:13px; cursor:pointer; transition:all .2s; font-family:'DM Sans',sans-serif; }
.modal-btn-primary { background:var(--grad-brand); color:#fff; box-shadow:0 4px 14px var(--bleu-glow); }
.modal-btn-secondary { background:var(--surface2); color:var(--tx2); border:1px solid var(--border); }
.modal-btn-danger { background:var(--rouge); color:#fff; box-shadow:0 4px 14px rgba(220,38,38,.25); }
.modal-btn-primary:hover { transform:translateY(-1px); }

.theme-grid { display:grid; grid-template-columns:repeat(2,1fr); gap:12px; }
.theme-preview-card { cursor:pointer; border-radius:14px; overflow:hidden; border:2px solid var(--border); transition:all .2s; }
.theme-preview-card:hover { border-color:rgba(31,82,212,.3); transform:translateY(-2px); }
.theme-preview-card .preview-area { height:88px; padding:9px; position:relative; overflow:hidden; }
.preview-bubble-r { background:var(--surface2); border-radius:12px; padding:5px 9px; width:72%; margin-bottom:5px; font-size:10px; border:1px solid var(--border); color:var(--tx); }
.preview-bubble-s { border-radius:12px; padding:5px 9px; width:62%; margin-left:auto; color:white; font-size:10px; }
.theme-preview-card .preview-label { padding:7px 10px; text-align:center; font-size:11.5px; font-weight:700; background:var(--surface); border-top:1px solid var(--border); color:var(--tx); }
.color-palette-grid { display:flex; flex-wrap:wrap; gap:10px; padding:4px 0 14px; }
.color-swatch-btn { display:flex; flex-direction:column; align-items:center; gap:5px; cursor:pointer; transition:transform .2s; background:none; border:none; padding:0; }
.color-swatch-btn:hover { transform:scale(1.1); }
.swatch-ring { width:40px; height:40px; border-radius:50%; border:3px solid var(--border); overflow:hidden; transition:box-shadow .2s; box-shadow:0 2px 6px rgba(0,0,0,.1); }
.swatch-ring .swatch-inner { width:100%; height:100%; border-radius:50%; }
.swatch-label { font-size:9.5px; font-weight:600; color:var(--tx2); white-space:nowrap; }
.color-swatch-btn.active-swatch .swatch-ring { border-color:var(--bleu); box-shadow:0 0 0 3px var(--bleu-l); }

/* ===== BASE - THEMES VIVANTS & ANIMÉS ===== */

/* --- THÈME BASKETBALL --- */
body.theme-basketball .messages-container {
  background-color: #f97316;
  background-image: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 800 600'%3E%3Ccircle cx='150' cy='120' r='12' fill='%23ffffff30'/%3E%3Ccircle cx='650' cy='180' r='18' fill='%23ffffff20'/%3E%3C/svg%3E");
  background-repeat: repeat;
  position: relative;
  overflow-x: hidden;
}
body.theme-basketball .messages-container::before {
  content: '';
  position: fixed;
  bottom: 20px;
  right: 20px;
  width: 160px;
  height: 160px;
  background: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 100 100'%3E%3Ccircle cx='50' cy='50' r='45' fill='%23d97a00' stroke='%23442200' stroke-width='4'/%3E%3Cpath d='M50 5 L50 95 M15 25 L85 75 M15 75 L85 25' stroke='%23442200' stroke-width='4' fill='none'/%3E%3C/svg%3E") no-repeat center;
  background-size: contain;
  animation: bounce-ball 2s ease-in-out infinite, rotate-ball 4s linear infinite;
  z-index: 1;
  pointer-events: none;
}
body.theme-basketball .messages-container::after {
  content: '🏀';
  position: fixed;
  bottom: 120px;
  right: 30px;
  font-size: 60px;
  animation: shake-hoop 1.5s infinite;
  pointer-events: none;
}
@keyframes bounce-ball {
  0%, 100% { transform: translateY(0px) rotate(0deg); }
  50% { transform: translateY(-60px) rotate(180deg); }
}
@keyframes rotate-ball {
  100% { transform: rotate(360deg); }
}
@keyframes shake-hoop {
  0%, 100% { transform: rotate(0deg); }
  50% { transform: rotate(15deg); }
}

/* --- THÈME NUIT ÉTOILÉE --- */
body.theme-midnight .messages-container {
  background-color: #0a0a2a;
  background-image: radial-gradient(circle at 20% 40%, white 1px, transparent 1px);
  background-size: 40px 40px;
  position: relative;
  overflow: hidden;
}
body.theme-midnight .messages-container::before {
  content: '';
  position: fixed;
  top: 10%;
  left: 15%;
  width: 80px;
  height: 80px;
  background: radial-gradient(circle, #fff9c4, transparent);
  border-radius: 50%;
  animation: shooting-star 6s linear infinite;
  pointer-events: none;
}
body.theme-midnight .messages-container::after {
  content: '🌙';
  position: fixed;
  top: 20px;
  right: 30px;
  font-size: 70px;
  filter: drop-shadow(0 0 12px #ffefb0);
  animation: float-moon 8s ease-in-out infinite;
  pointer-events: none;
}
@keyframes shooting-star {
  0% { transform: translateX(0) translateY(0) scale(1); opacity: 1; }
  20% { opacity: 1; }
  80% { transform: translateX(300px) translateY(200px) scale(0.5); opacity: 0; }
  100% { transform: translateX(300px) translateY(200px) scale(0); opacity: 0; }
}
@keyframes float-moon {
  0%, 100% { transform: translateY(0px); }
  50% { transform: translateY(-15px); }
}

/* --- THÈME OCÉAN --- */
body.theme-ocean .messages-container {
  background: linear-gradient(180deg, #0077be, #004466);
  position: relative;
  overflow: hidden;
}
body.theme-ocean .messages-container::before {
  content: '';
  position: fixed;
  bottom: 0;
  left: 0;
  width: 100%;
  height: 60px;
  background: repeating-linear-gradient(transparent 0px, transparent 29px, #00b8ff30 30px);
  animation: wave 3s linear infinite;
  pointer-events: none;
}
body.theme-ocean .messages-container::after {
  content: '🐠🐟🐡';
  position: fixed;
  bottom: 20px;
  left: 10%;
  font-size: 40px;
  white-space: nowrap;
  animation: fish-swim 15s linear infinite;
  filter: drop-shadow(0 0 4px cyan);
  pointer-events: none;
}
@keyframes wave {
  0% { background-position: 0 0; }
  100% { background-position: 200px 0; }
}
@keyframes fish-swim {
  0% { transform: translateX(-100px); }
  100% { transform: translateX(calc(100vw + 100px)); }
}

/* --- THÈME AMOUR --- */
body.theme-rose .messages-container {
  background: linear-gradient(145deg, #ffb6c1, #ff69b4);
  position: relative;
}
body.theme-rose .messages-container::before {
  content: '❤️💖❤️';
  position: fixed;
  top: 20px;
  left: 0;
  width: 100%;
  font-size: 50px;
  text-align: center;
  animation: floating-hearts 4s infinite;
  opacity: 0.7;
  pointer-events: none;
}
body.theme-rose .messages-container::after {
  content: '💕';
  position: fixed;
  bottom: 40px;
  right: 20px;
  font-size: 70px;
  animation: heartbeat 1s ease infinite;
  pointer-events: none;
}
@keyframes floating-hearts {
  0% { transform: translateY(0px); opacity: 0.5; }
  50% { transform: translateY(-25px); opacity: 1; }
  100% { transform: translateY(0px); opacity: 0.5; }
}
@keyframes heartbeat {
  0%, 100% { transform: scale(1); }
  50% { transform: scale(1.3); }
}

/* --- THÈME FORÊT --- */
body.theme-forest .messages-container {
  background: linear-gradient(180deg, #1a4d1a, #0a2e0a);
  position: relative;
}
body.theme-forest .messages-container::before {
  content: '🍃🌲🍂';
  position: fixed;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  background-image: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 200 600'%3E%3Cpath d='M20 600 L40 450 L60 600Z' fill='%23336633' fill-opacity='0.3'/%3E%3C/svg%3E");
  background-repeat: repeat-y;
  background-size: 80px;
  animation: sway 3s ease-in-out infinite;
  pointer-events: none;
}
body.theme-forest .messages-container::after {
  content: '🐿️🦊🐦';
  position: fixed;
  bottom: 30px;
  left: 20px;
  font-size: 45px;
  animation: animal-walk 12s linear infinite;
  pointer-events: none;
}
@keyframes sway {
  0%, 100% { transform: rotate(0deg); }
  50% { transform: rotate(4deg); }
}
@keyframes animal-walk {
  0% { transform: translateX(-100px); }
  100% { transform: translateX(calc(100vw + 100px)); }
}

/* --- THÈME AURORA BOREALE --- */
body.theme-aurora .messages-container {
  background: linear-gradient(180deg, #001f3f, #003366, #0088aa);
  position: relative;
  overflow: hidden;
}
body.theme-aurora .messages-container::before {
  content: '';
  position: fixed;
  top: 0;
  left: -50%;
  width: 200%;
  height: 200px;
  background: linear-gradient(90deg, transparent, #00ffcc80, #ff66cc80, #00ffcc80, transparent);
  filter: blur(40px);
  animation: aurora-wave 6s linear infinite;
  pointer-events: none;
}
@keyframes aurora-wave {
  0% { transform: translateX(0%) rotate(0deg); opacity: 0.6; }
  50% { transform: translateX(10%) rotate(2deg); opacity: 1; }
  100% { transform: translateX(0%) rotate(0deg); opacity: 0.6; }
}

/* --- THÈME COSMIC --- */
body.theme-cosmic .messages-container {
  background: radial-gradient(circle at 20% 30%, #1a0033, #000011);
  position: relative;
}
body.theme-cosmic .messages-container::before {
  content: '';
  position: fixed;
  width: 3px;
  height: 3px;
  background: white;
  border-radius: 50%;
  box-shadow: 50px 80px white, 200px 150px white, 350px 60px white, 500px 200px white, 650px 120px white;
  animation: twinkle 3s infinite alternate;
  pointer-events: none;
}
body.theme-cosmic .messages-container::after {
  content: '🌌✨🪐';
  position: fixed;
  top: 50px;
  right: 30px;
  font-size: 50px;
  animation: spin-planet 20s linear infinite;
  pointer-events: none;
}
@keyframes twinkle {
  0% { opacity: 0.2; transform: scale(1); }
  100% { opacity: 1; transform: scale(1.5); }
}
@keyframes spin-planet {
  100% { transform: rotate(360deg); }
}

/* --- THÈME GOLDEN LUXE --- */
body.theme-golden .messages-container {
  background: linear-gradient(135deg, #fde047, #facc15);
  position: relative;
}
body.theme-golden .messages-container::before {
  content: '✨💎✨';
  position: fixed;
  font-size: 70px;
  animation: glitter-spark 1.5s steps(2, jump-none) infinite;
  pointer-events: none;
}

@keyframes glitter-spark {
  0% { opacity: 0.4; text-shadow: 0 0 0px gold; }
  100% { opacity: 1; text-shadow: 0 0 20px #ffd700; }
}

/* --- BULLES DE CHAT STYLES VIVANTS --- */
body.theme-ocean .message.sent .message-bubble {
  background: linear-gradient(135deg, #00aaff, #0055aa) !important;
  box-shadow: 0 0 15px #00aaff80;
  animation: bubble-glow 2s infinite alternate;
}
body.theme-aurora .message.sent .message-bubble {
  background: linear-gradient(145deg, #06b6d4, #8b5cf6, #ec4899) !important;
  background-size: 200% 200%;
  animation: gradient-shift 5s ease infinite;
}
@keyframes gradient-shift {
  0% { background-position: 0% 50%; }
  50% { background-position: 100% 50%; }
  100% { background-position: 0% 50%; }
}
@keyframes bubble-glow {
  0% { box-shadow: 0 0 5px cyan; }
  100% { box-shadow: 0 0 20px #00ffff; }
}

/* --- ANIMATION GLOBALE POUR TOUS LES THEMES --- */
.messages-container {
  transition: background 0.5s ease;
}
.message-bubble {
  transition: transform 0.2s, box-shadow 0.2s;
}
.message-bubble:hover {
  transform: scale(1.02);
}
/* Video call */
#videoCallModal { display:none; position:fixed; inset:0; background:rgba(0,0,0,.9); backdrop-filter:blur(12px); z-index:9000; align-items:center; justify-content:center; }
.vcall-box { background:var(--surface); border-radius:22px; width:95%; max-width:1100px; height:84vh; display:flex; flex-direction:column; overflow:hidden; box-shadow:0 40px 100px rgba(0,0,0,.5); border:1px solid rgba(31,82,212,.2); }
.vcall-header { padding:13px 18px; background:var(--bleu2); display:flex; justify-content:space-between; align-items:center; }
.vcall-header h3 { font-family:'Syne',sans-serif; font-size:15px; color:#fff; font-weight:700; margin:0; }
.vcall-close { width:30px; height:30px; border-radius:50%; background:rgba(255,255,255,.12); border:1px solid rgba(255,255,255,.18); color:#fff; cursor:pointer; font-size:15px; display:flex; align-items:center; justify-content:center; transition:all .2s; }
.vcall-close:hover { background:rgba(220,38,38,.5); }
#jitsiContainer { flex:1; background:#111; display:none; }
#vcallWaiting { flex:1; background:#0d1117; display:flex; flex-direction:column; align-items:center; justify-content:center; gap:18px; position:relative; overflow:hidden; }
.vcall-footer { padding:9px 16px; background:var(--surface2); display:flex; align-items:center; justify-content:center; gap:10px; flex-wrap:wrap; font-size:12px; color:var(--tx2); border-top:1px solid var(--border); }
.room-link-input { background:var(--surface); border:1px solid var(--border); border-radius:24px; padding:5px 12px; font-size:11px; color:var(--tx); width:260px; font-family:monospace; outline:none; }
.vcall-copy-btn { background:var(--grad-brand); color:#fff; border:none; padding:6px 16px; border-radius:24px; font-size:12px; font-weight:700; cursor:pointer; transition:all .2s; }

.toast { position:fixed; bottom:22px; right:22px; background:var(--surface); border:1.5px solid var(--border-h); border-left:3px solid var(--bleu); border-radius:12px; padding:11px 18px; font-size:13px; font-weight:500; color:var(--tx2); box-shadow:var(--shadow-md); z-index:9999; display:flex; align-items:center; gap:9px; transform:translateY(80px); opacity:0; transition:all .3s cubic-bezier(.34,1.56,.64,1); }
.toast.show { transform:translateY(0); opacity:1; }
.toast i { color:var(--bleu); }
.toast.toast-error { border-left-color:var(--rouge); }
.toast.toast-error i { color:var(--rouge); }

.sidebar.collapsed { width:62px !important; min-width:62px !important; }
.sidebar.collapsed .sidebar-brand-text,.sidebar.collapsed .contact-info,.sidebar.collapsed .contact-time,.sidebar.collapsed .search-bar { display:none !important; }
.sidebar.collapsed .sidebar-header { justify-content:center !important; }
.sidebar.collapsed .contact-avatar { margin:0 auto !important; }
.sidebar.collapsed .contact-item { justify-content:center !important; padding:10px 0 !important; }
.pin-toggle-btn { position:absolute; bottom:18px; right:10px; width:28px; height:28px; border-radius:50%; background:var(--bleu); border:none; cursor:pointer; display:flex; align-items:center; justify-content:center; color:white; z-index:100; transition:transform .2s; }

#toggleAdminNavBtn { position:fixed; top:16px; width:26px; height:26px; border-radius:50%; background:var(--bleu); color:white; border:none; cursor:pointer; display:flex; align-items:center; justify-content:center; z-index:1001; font-size:10px; box-shadow:0 2px 8px var(--bleu-glow); transition:left .3s, opacity .3s; }

#loadingIndicator { position:fixed; bottom:72px; left:50%; transform:translateX(-50%); background:var(--surface); padding:7px 16px; border-radius:18px; box-shadow:var(--shadow); z-index:1000; display:none; align-items:center; gap:7px; font-size:13px; color:var(--tx2); border:1px solid var(--border); }

@media (max-width:768px) { .admin-nav{display:none;} #toggleAdminNavBtn{display:none;} .sidebar{width:100%;} .chat-area{display:none;} }
/* Thèmes de bulles */
body.theme-pink .message.sent .message-bubble {
    background: linear-gradient(135deg, #ec4899, #be185d) !important;
}
body.theme-gold .message.sent .message-bubble {
    background: linear-gradient(135deg, #f59e0b, #b45309) !important;
}
body.theme-green .message.sent .message-bubble {
    background: linear-gradient(135deg, #10b981, #065f46) !important;
}
body.theme-purple .message.sent .message-bubble {
    background: linear-gradient(135deg, #8b5cf6, #5b21b6) !important;
}
body.theme-red .message.sent .message-bubble {
    background: linear-gradient(135deg, #ef4444, #991b1b) !important;
}
body.theme-cyan .message.sent .message-bubble {
    background: linear-gradient(135deg, #06b6d4, #0e7490) !important;
}
body.theme-golden .message.sent .message-bubble {
    background: linear-gradient(135deg, #d97706, #92400e) !important;
}

/* ── MODIFICATION 2 : Carte publication dans un message ─────────────────────────────── */
.prop-card-msg {
  border-radius:14px; overflow:hidden;
  border:1.5px solid var(--border);
  max-width:260px; margin-bottom:6px;
  cursor:pointer; transition:transform .2s, box-shadow .2s;
  text-decoration:none; display:block;
  background:var(--surface);
}
.prop-card-msg:hover { transform:translateY(-2px); box-shadow:0 8px 24px rgba(14,45,130,.12); }
.prop-card-msg-img { width:100%; height:130px; object-fit:cover; display:block; }
.prop-card-msg-img-placeholder { width:100%; height:130px; background:var(--surface2); display:flex; align-items:center; justify-content:center; color:var(--tx3); font-size:28px; }
.prop-card-msg-body { padding:10px 12px; }
.prop-card-msg-type { display:inline-flex; align-items:center; gap:5px; font-size:9px; font-weight:800; letter-spacing:1.5px; text-transform:uppercase; padding:3px 9px; border-radius:99px; margin-bottom:6px; }
.prop-card-msg-type.vente    { background:rgba(5,150,105,.12); color:#059669; }
.prop-card-msg-type.location { background:rgba(31,82,212,.12);  color:var(--bleu); }
.prop-card-msg-title { font-family:'Syne',sans-serif; font-weight:700; font-size:13px; color:var(--tx); line-height:1.3; margin-bottom:4px; white-space:nowrap; overflow:hidden; text-overflow:ellipsis; }
.message.sent .prop-card-msg-title { color:#fff; }
.prop-card-msg-price { font-family:'Syne',sans-serif; font-weight:800; font-size:15px; color:var(--bleu); margin-bottom:3px; }
.message.sent .prop-card-msg-price { color:var(--gold2, #e8a820); }
.prop-card-msg-loc { font-size:11px; color:var(--tx3); display:flex; align-items:center; gap:4px; }
.prop-card-msg-loc i { color:var(--rouge); font-size:9px; }
.prop-card-msg-footer { border-top:1px solid var(--border); padding:7px 12px; font-size:11px; font-weight:700; color:var(--bleu); display:flex; align-items:center; gap:5px; }
.message.sent .prop-card-msg { background:rgba(255,255,255,.12); border-color:rgba(255,255,255,.2); }
.message.sent .prop-card-msg-loc { color:rgba(255,255,255,.55); }
.message.sent .prop-card-msg-footer { border-color:rgba(255,255,255,.15); color:rgba(255,255,255,.8); }

/* ── Bannière de prévisualisation publication (zone saisie) ─────────── */
#propertySharePreview {
  position:absolute; bottom:calc(100% + 4px); left:14px; right:14px;
  background:var(--surface); border:1.5px solid rgba(31,82,212,.2);
  border-left:3px solid var(--bleu); border-radius:14px;
  padding:0; overflow:hidden; z-index:20; box-shadow:0 4px 18px rgba(14,45,130,.1);
  animation:fadeUp .22s ease both;
}
.prop-preview-header {
  display:flex; align-items:center; justify-content:space-between;
  padding:7px 12px; border-bottom:1px solid var(--border);
  background:var(--bleu-l);
}
.prop-preview-header span { font-size:10px; font-weight:800; letter-spacing:1.5px; text-transform:uppercase; color:var(--bleu); display:flex; align-items:center; gap:6px; }
.prop-preview-dismiss { background:none; border:none; cursor:pointer; color:var(--tx3); font-size:16px; transition:color .2s; }
.prop-preview-dismiss:hover { color:var(--rouge); }
.prop-preview-body { display:flex; gap:10px; padding:10px 12px; align-items:center; }
.prop-preview-thumb { width:52px; height:52px; border-radius:10px; object-fit:cover; flex-shrink:0; }
.prop-preview-thumb-ph { width:52px; height:52px; border-radius:10px; background:var(--surface2); display:flex; align-items:center; justify-content:center; color:var(--tx3); font-size:18px; flex-shrink:0; }
.prop-preview-info { flex:1; min-width:0; }
.prop-preview-title { font-weight:700; font-size:13px; color:var(--tx); white-space:nowrap; overflow:hidden; text-overflow:ellipsis; }
.prop-preview-meta { font-size:11px; color:var(--tx3); margin-top:2px; }

/* ── Boutons suggestions rapides ───────────────────────────────────── */
#quickReplies {
  display:flex; gap:7px; flex-wrap:wrap;
  padding:0 12px 10px;
}
.quick-reply-btn {
  display:inline-flex; align-items:center; gap:5px;
  padding:6px 13px; border-radius:99px;
  background:var(--surface2); border:1.5px solid var(--border);
  font-size:12px; font-weight:600; color:var(--tx2);
  cursor:pointer; transition:all .2s; white-space:nowrap;
}
.quick-reply-btn:hover { background:var(--bleu-l); border-color:rgba(31,82,212,.3); color:var(--bleu); transform:translateY(-1px); }

</style>
</head>

<body class="light<%=(!conversationTheme.equals("default") ? " theme-" + conversationTheme : "")%>" id="body">
<div class="app-container">

<%-- ADMIN NAV --%>
<% if (adminId != null) { %>
<div class="admin-nav" id="adminNavEl">
  <div class="admin-nav-header">
    <img src="<%= request.getContextPath() %>/immo/admin/images/Logo.jpg"
         alt="Fredon"
         style="width: 38px; height: 38px; object-fit: cover; border-radius: 10px; box-shadow: 0 2px 8px rgba(0,0,0,.25);">
    <div><span>Fredon</span><small>Agence Immobilière</small></div>
</div>
 <nav class="admin-nav-menu">
    <div class="nav-sec-label"><%= t_principal %></div>
    <a href="<%= request.getContextPath() %>/admin/dashboard" class="admin-nav-item"><i class="fas fa-chart-line"></i><span><%= t_dashboard %></span></a>
    <a href="<%= request.getContextPath() %>/admin/add-property" class="admin-nav-item"><i class="fas fa-plus-circle"></i><span><%= t_add_prop %></span></a>
    <a href="<%= request.getContextPath() %>/chat" class="admin-nav-item active"><i class="fas fa-comments"></i><span><%= t_messages %></span>
    <% if (unreadMessages > 0) { %><span class="admin-nav-badge"><%= unreadMessages > 99 ? "99+" : unreadMessages %></span><% } %>
    </a>
    
    <div class="nav-sec-label"><%= t_management %></div>
    <a href="<%= request.getContextPath() %>/admin/clients" class="admin-nav-item"><i class="fas fa-users"></i><span><%= t_clients %></span></a>
    
    <!-- Ajouter le lien Visites -->
    <a href="<%= request.getContextPath() %>/admin/appointments" class="admin-nav-item">
        <i class="fas fa-calendar-check"></i>
        <span>Visites</span>
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
        <span class="admin-nav-badge"><%= pendingAppointments %></span>
        <% } %>
    </a>
    
<a href="<%= request.getContextPath() %>/admin/statistics" class="admin-nav-item"><i class="fas fa-chart-pie"></i><span><%= t_stats %></span></a>
    
    <div class="nav-sec-label"><%= t_system %></div>
    <!-- Ajouter le lien Paramètres -->
    <a href="<%= request.getContextPath() %>/admin/setting" class="admin-nav-item"><i class="fas fa-cog"></i><span><%= t_settings %></span></a>
    <a href="<%= request.getContextPath() %>/home" class="admin-nav-item"><i class="fas fa-eye"></i><span><%= t_view_site %></span></a>
    <a href="<%= request.getContextPath() %>/logout" class="admin-nav-item logout"><i class="fas fa-sign-out-alt"></i><span><%= t_logout %></span></a>
</nav>
  <div class="admin-nav-bottom">
    <div class="admin-nav-user" onclick="openProfileModal()">
     <div class="admin-nav-avatar">
    <%
        String adminProfilePic = null;
        try {
            Connection conn = DriverManager.getConnection("jdbc:mysql://localhost:3306/quickchat", "root", "");
            PreparedStatement pstmt = conn.prepareStatement("SELECT profile_pic FROM users WHERE id = ?");
            pstmt.setInt(1, adminId);
            ResultSet rs = pstmt.executeQuery();
            if (rs.next()) {
                adminProfilePic = rs.getString("profile_pic");
            }
            rs.close(); pstmt.close(); conn.close();
        } catch(Exception e) {}
        
        if (adminProfilePic != null && !adminProfilePic.isEmpty()) {
    %>
        <img src="<%= request.getContextPath() %>/avatars/<%= adminProfilePic %>" style="width:100%;height:100%;object-fit:cover;border-radius:10px;">
    <% } else { %>
        <%= adminInitial %>
    <% } %>
</div>
      <div><div class="admin-nav-name"><%= adminName %></div><div class="admin-nav-role"><%= t_admin %></div></div>
      <div class="admin-nav-online"></div>
    </div>
  </div>
</div>
<% } %>

<%-- SIDEBAR CHAT --%>
<div class="sidebar" id="sidebarEl">
  <% if (adminId == null) { %>
  <a href="<%= request.getContextPath() %>/home" class="back-to-site-btn"><i class="fas fa-arrow-left"></i> <%= t_back_site %></a>
  <% } %>

  <div class="sidebar-header">
    <div class="sidebar-logo-wrap" style="gap: 12px;">
      <img src="<%= request.getContextPath() %>/immo/admin/images/Logo.jpg"
           alt="Fredon"
           style="width: 48px; height: 48px; object-fit: cover; border-radius: 14px; box-shadow: 0 4px 12px rgba(0,0,0,.25);">
      <div class="sidebar-brand-text">
        <span class="sidebar-brand-name" style="font-size: 18px;">Fredon</span>
        <span class="sidebar-brand-tag"><%= t_messaging %></span>
      </div>
    </div>
    <div class="profile-pic" onclick="toggleMenu()">
      <% if (user.getProfilePic() != null && !user.getProfilePic().isEmpty()) { %>
        <img src="<%=request.getContextPath()%>/uploads/<%=user.getProfilePic()%>" style="width:100%;height:100%;border-radius:10px;object-fit:cover;">
      <% } else { %><%=user.getInitial()%><% } %>
    </div>
  </div>
  <div id="profileMenu" class="profile-menu" style="display:none;">
    <div class="profile-menu-item"><i class="fas fa-user"></i><span><%=user.getDisplayName()%></span></div>
    <div class="profile-menu-item"><i class="fas fa-envelope"></i><span><%=user.getEmail()%></span></div>
    <div style="height:1px;background:var(--border);"></div>
    <div class="profile-menu-item" onclick="showEditNameModal()"><i class="fas fa-pen"></i><span><%= TranslateUtil.t(lang,"change_nickname") %></span></div>
    <div class="profile-menu-item" onclick="document.getElementById('profilePicInput').click();"><i class="fas fa-camera"></i><span><%= TranslateUtil.t(lang,"change_photo") %></span></div>
    <div style="height:1px;background:var(--border);"></div>
    <a href="logout" class="profile-menu-item logout-item"><i class="fas fa-sign-out-alt"></i><span><%= t_logout %></span></a>
  </div>

  <div class="sidebar-toolbar">
    <div id="themeToggle" class="stb-btn" title="Mode sombre / clair"><i class="fas fa-moon"></i></div>
    <% if (adminId != null) { %>
    <div id="createGroupBtn" class="stb-btn" title="Créer un groupe"><i class="fas fa-users"></i></div>
    <% } %>
  </div>

  <div class="search-bar">
    <div class="search-box">
      <i class="fas fa-search"></i>
      <input type="text" id="searchInput" placeholder="<%= t_search %>…">
    </div>
  </div>

  <div class="contacts-list" id="contactsList">
    <%
    ConversationDAO convDAO = new ConversationDAO();
    GroupMessageDAO groupMsgDAO = new GroupMessageDAO();
    List<Group> activeGroups  = new ArrayList<>();
    if (userGroups != null) {
        for (Group g : userGroups) {
            if (!convDAO.isGroupArchived(user.getId(), g.getId())) activeGroups.add(g);
        }
    }
    %>
    <% if (adminId != null && activeGroups != null && !activeGroups.isEmpty()) { %>
    <div class="contacts-section-label"><%= t_groups %></div>
    <% for (Group g : activeGroups) { int guc = groupMsgDAO.countUnreadGroupMessages(g.getId(), user.getId()); %>
    <a href="group-chat.jsp?groupId=<%=g.getId()%>" class="contact-item">
      <div class="contact-avatar" style="background:linear-gradient(135deg,#7c3aed,#2563eb);"><i class="fas fa-users" style="font-size:14px;"></i></div>
      <div class="contact-info">
        <div class="contact-name"><%=g.getName()%></div>
        <div class="contact-preview"><span><%=g.getDescription()!=null&&!g.getDescription().isEmpty()?g.getDescription():"Groupe"%></span></div>
      </div>
      <div class="contact-time"><% if(guc>0){%><div class="unread-badge"><%=guc%></div><%}%></div>
    </a>
    <% } %>
    <div style="height:5px;"></div>
    <% } %>

    <%
    List<User> activeContacts = new ArrayList<>();
    if (users != null) {
        for (User u : users) { if (!convDAO.isArchived(user.getId(), u.getId())) activeContacts.add(u); }
    }
    List<Map<String, Object>> sortedContacts = new ArrayList<>();
    if (!activeContacts.isEmpty()) {
        for (User u : activeContacts) {
            List<Message> lastMsgs;
            if (user.getId()==999) lastMsgs = messageDAO.getConversation(9, u.getId());
            else                   lastMsgs = messageDAO.getConversation(user.getId(), u.getId());
            String lm="",lt="",lts="0000-00-00 00:00:00";
            if (lastMsgs != null && !lastMsgs.isEmpty()) {
                Message last = lastMsgs.get(lastMsgs.size()-1);
                String cnt = last.getContent();
                if      (last.isDeletedForEveryone())                                         lm = "🚫 " + t_deleted_ev;
                else if (last.isDeletedForUser(user.getId()))                                lm = "";
                else if (last.getFilePath()!=null && last.getFileType()!=null && last.getFileType().startsWith("image/")) lm = "📷 Photo";
                else if (last.getFilePath()!=null && last.getFileType()!=null && last.getFileType().startsWith("audio/")) lm = "🎤 Vocal";
                else if (last.getFilePath()!=null && last.getFileType()!=null && last.getFileType().startsWith("video/")) lm = "🎥 Vidéo";
                else if (last.getFilePath()!=null && !last.getFilePath().isEmpty())          lm = "📎 Fichier";
                else if (last.getGifUrl()!=null && !last.getGifUrl().isEmpty())             lm = "🎞️ GIF";
                else if (cnt!=null && !cnt.isEmpty())                                        lm = cnt.length()>32?cnt.substring(0,32)+"…":cnt;
                if (last.getCreatedAt()!=null&&last.getCreatedAt().length()>16){lt=last.getCreatedAt().substring(11,16);lts=last.getCreatedAt();}
            }
            int uc = user.getId()==999 ? messageDAO.countUnreadMessagesFromUser(9,u.getId()) : messageDAO.countUnreadMessagesFromUser(user.getId(),u.getId());
            Map<String,Object> info=new HashMap<>(); info.put("user",u);info.put("lm",lm);info.put("lt",lt);info.put("lts",lts);info.put("uc",uc);
            sortedContacts.add(info);
        }
        sortedContacts.sort((a,b)->((String)b.get("lts")).compareTo((String)a.get("lts")));
    }
    %>
    <div class="contacts-section-label"><%= t_private %></div>
    <% if (!sortedContacts.isEmpty()) {
        for (Map<String,Object> info : sortedContacts) {
            User u = (User) info.get("user");
            String lm3 = (String) info.get("lm");
            String lt3  = (String) info.get("lt");
            int uc3     = (int)    info.get("uc");
            String dcn  = u.getDisplayName();
            String cn   = contactNameDAO.getCustomName(user.getId(), u.getId());
            if (cn!=null&&!cn.isEmpty()) dcn=cn;
    %>
    <a href="chat.jsp?userId=<%=u.getId()%>" class="contact-item <%=(selectedUserId==u.getId())?"active":""%>" data-name="<%=u.getUsername().toLowerCase()%>" data-userid="<%=u.getId()%>">
      <div class="contact-avatar">
        <% if(u.getProfilePic()!=null&&!u.getProfilePic().isEmpty()){%><img src="<%=request.getContextPath()%>/uploads/<%=u.getProfilePic()%>" alt="<%=u.getInitial()%>"><%}else{%><%=u.getInitial()%><%}%>
        <% if("online".equals(u.getStatus())){%><span class="online-dot"></span><%}%>
      </div>
      <div class="contact-info">
        <div class="contact-name"><%=dcn%></div>
        <div class="contact-preview">
          <% if(lm3!=null&&!lm3.isEmpty()){%><i class="fas fa-check-double"></i><span><%=lm3%></span><%}else{%><span style="color:var(--tx3);font-style:italic;"><%= t_start_conv %></span><%}%>
        </div>
      </div>
      <div class="contact-time" id="contact-time-<%=u.getId()%>">
        <%if(lt3!=null&&!lt3.isEmpty()){%><div><%=lt3%></div><%}%>
        <div class="unread-badge" id="badge-<%=u.getId()%>" style="<%=uc3>0?"":"display:none;"%>"><%=uc3>0?(uc3>99?"99+":String.valueOf(uc3)):"0"%></div>
      </div>
    </a>
    <% } } else { %>
    <div style="padding:28px 16px;text-align:center;color:var(--tx3);"><i class="fas fa-comments" style="font-size:32px;opacity:.25;display:block;margin-bottom:10px;"></i><p style="font-size:12.5px;"><%= t_no_msg %></p></div>
    <% } %>
  </div>
  <button class="pin-toggle-btn" id="pinToggleBtn" title="Épingler/réduire"><i class="fas fa-chevron-left"></i></button>
</div>

<%-- CHAT AREA --%>
<div class="chat-area">
<% if (selectedUser != null) { %>
<div class="chat-header" data-contact-id="<%=selectedUserId%>">
  <div class="chat-header-left">
    <div class="chat-header-avatar" onclick="openUserProfileModal(<%=selectedUserId%>)">
      <% if(selectedUser.getProfilePic()!=null&&!selectedUser.getProfilePic().isEmpty()){%><img src="<%=request.getContextPath()%>/uploads/<%=selectedUser.getProfilePic()%>" style="width:100%;height:100%;border-radius:11px;object-fit:cover;"><%}else{%><%=selectedUser.getInitial()%><%}%>
    </div>
    <div class="chat-header-info">
      <%
      String hdn = selectedUser.getDisplayName();
      String hcn = contactNameDAO.getCustomName(user.getId(), selectedUser.getId());
      if (hcn!=null&&!hcn.isEmpty()) hdn=hcn;
      %>
      <h3><%=hdn%></h3>
      <p class="<%="online".equals(selectedUser.getStatus())?"online":""%>">
        <%="online".equals(selectedUser.getStatus())?"● "+t_online:formatLastSeen(selectedUser.getLastSeen())%>
      </p>
    </div>
  </div>
  <div class="chat-header-actions">
    <button class="hdr-btn" id="searchIcon" title="<%= t_search %>"><i class="fas fa-search"></i></button>
    <button class="hdr-btn" style="color:var(--vert);" onclick="startVoiceCall()" title="Appel vocal"><i class="fas fa-phone"></i></button>
    <button class="hdr-btn" style="color:var(--bleu);" onclick="startVideoCall()" title="Appel vidéo"><i class="fas fa-video"></i></button>
    <div class="hdr-menu-wrap">
      <button class="hdr-btn" onclick="toggleHdrMenu()"><i class="fas fa-ellipsis-vertical"></i></button>
      <div class="hdr-menu-popup" id="hdrMenuPopup">
        <div class="hdr-menu-item" onclick="showThemeModal();closeHdrMenu();"><i class="fas fa-palette"></i> Thème de conversation</div>
        <div class="hdr-menu-item" onclick="showRenameModal();closeHdrMenu();"><i class="fas fa-user-pen"></i> Renommer le contact</div>
        <div class="hdr-menu-item" onclick="archiveConversation();closeHdrMenu();"><i class="fas fa-archive"></i> Archiver</div>
        <div style="height:1px;background:var(--border);margin:3px 0;"></div>
        <div class="hdr-menu-item danger" onclick="showDeleteConvModal();closeHdrMenu();"><i class="fas fa-trash-alt"></i> Supprimer la discussion</div>
        <div class="hdr-menu-item danger" onclick="showBlockModal();closeHdrMenu();"><i class="fas fa-ban"></i> Bloquer ce contact</div>
      </div>
    </div>
  </div>
</div>

<div id="searchBar" style="display:none;">
  <div class="search-inner">
    <i class="fas fa-search" style="color:var(--tx3);font-size:12px;"></i>
    <input type="text" id="searchInputChat" placeholder="<%= t_search %>…">
    <i class="fas fa-times" id="closeSearch"></i>
  </div>
</div>

<div class="messages-container" id="messagesContainer">
  <%
  Message pinnedMsg = null;
  if (selectedUserId>0) { try { pinnedMsg = messageDAO.getPinnedMessage(user.getId(), selectedUserId); } catch(Exception e){} }
  if (pinnedMsg != null) {
  %>
  <div class="pinned-message" id="pinnedMsgBar_<%=pinnedMsg.getId()%>">
    <div style="display:flex;align-items:center;gap:9px;">
      <i class="fas fa-thumbtack" style="color:var(--or);transform:rotate(45deg);"></i>
      <div>
        <div style="font-size:9.5px;color:var(--or);font-weight:700;letter-spacing:1px;text-transform:uppercase;">Message épinglé</div>
        <div style="font-size:12.5px;color:var(--tx2);margin-top:2px;"><strong><%= pinnedMsg.getSenderId()==user.getId()?"Vous":pinnedMsg.getSenderName() %> :</strong> <%= pinnedMsg.getContent()!=null&&pinnedMsg.getContent().length()>50?pinnedMsg.getContent().substring(0,50)+"…":pinnedMsg.getContent() %></div>
      </div>
    </div>
    <div style="display:flex;gap:10px;align-items:center;">
      <a href="#" onclick="scrollToMessage(<%= pinnedMsg.getId() %>);return false;" style="font-size:11px;color:var(--bleu);font-weight:600;text-decoration:none;">Voir →</a>
      <a href="#" onclick="pinMessage(<%= pinnedMsg.getId() %>,<%= selectedUserId %>);return false;" style="font-size:11px;color:var(--rouge);font-weight:600;text-decoration:none;">📌 Détacher</a>
    </div>
  </div>
  <% } %>

  <%
  if (messages != null && !messages.isEmpty()) {
      String lastDayKey = ""; java.util.Date lastMsgDate = null;
      for (Message msg : messages) {
          String ft = "", fDate = ""; boolean showSep = false;
          if (msg.getCreatedAt() != null && !msg.getCreatedAt().isEmpty()) {
              try {
                  SimpleDateFormat dbF = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");
                  java.util.Date md = dbF.parse(msg.getCreatedAt());
                  java.util.Date now2 = new java.util.Date();
                  ft = new SimpleDateFormat("HH:mm").format(md);
                  String dk = new SimpleDateFormat("yyyy-MM-dd").format(md);
                  java.util.Calendar cm=java.util.Calendar.getInstance(); cm.setTime(md);
                  java.util.Calendar cn2=java.util.Calendar.getInstance(); cn2.setTime(now2);
                  if (!dk.equals(lastDayKey)) {
                      lastDayKey=dk; showSep=true;
                      if (cm.get(java.util.Calendar.YEAR)==cn2.get(java.util.Calendar.YEAR)&&cm.get(java.util.Calendar.DAY_OF_YEAR)==cn2.get(java.util.Calendar.DAY_OF_YEAR)) fDate="Aujourd'hui";
                      else if (cm.get(java.util.Calendar.YEAR)==cn2.get(java.util.Calendar.YEAR)&&cm.get(java.util.Calendar.DAY_OF_YEAR)==cn2.get(java.util.Calendar.DAY_OF_YEAR)-1) fDate="Hier";
                      else { String[]mois={"Jan","Fév","Mar","Avr","Mai","Juin","Juil","Août","Sep","Oct","Nov","Déc"}; fDate=cm.get(java.util.Calendar.DAY_OF_MONTH)+" "+mois[cm.get(java.util.Calendar.MONTH)]; if(cm.get(java.util.Calendar.YEAR)!=cn2.get(java.util.Calendar.YEAR)) fDate+=" "+cm.get(java.util.Calendar.YEAR); }
                  } else if (lastMsgDate!=null && (md.getTime()-lastMsgDate.getTime())/(60*1000)>=60) { showSep=true; fDate=ft; }
                  lastMsgDate=md;
              } catch(Exception ex) { ft=""; }
          }
          boolean isDelAll = msg.isDeletedForEveryone();
          boolean isDelMe  = msg.isDeletedForUser(user.getId());
          
          // Ne pas afficher du tout si supprimé pour moi ET pas supprimé pour tous
          if (isDelMe && !isDelAll) continue;
          
          if (showSep && !fDate.isEmpty()) {
  %><div class="time-separator"><span><%= fDate %></span></div>
  <%      }
          boolean isSent = user.getId()==999 ? msg.getSenderId()==9 : msg.getSenderId()==user.getId();
  %>
  <div class="message <%= isSent?"sent":"received" %>" data-message-id="<%= msg.getId() %>">
    <% if (!isSent) { %>
    <div class="message-avatar">
      <% if(selectedUser.getProfilePic()!=null&&!selectedUser.getProfilePic().isEmpty()){%><img src="<%= request.getContextPath() %>/uploads/<%= selectedUser.getProfilePic() %>" style="width:30px;height:30px;border-radius:9px;object-fit:cover;"><%}else{%><div style="width:30px;height:30px;border-radius:9px;background:var(--grad-brand);display:flex;align-items:center;justify-content:center;color:white;font-size:12px;font-weight:700;"><%= selectedUser.getInitial() %></div><%}%>
    </div>
    <% } %>
    <div class="message-wrapper">
      <div class="message-bubble">
        <% if (isDelAll) { %>
          <span class="deleted-message"><i class="fas fa-ban"></i> Ce message a été supprimé</span>
        <% } else { %>
          <%-- Vocal --%>
          <% if (msg.getFilePath()!=null && msg.getFileType()!=null && msg.getFileType().startsWith("audio/")) { %>
            <div style="display:flex;align-items:center;gap:9px;min-width:170px;"><i class="fas fa-microphone" style="color:var(--or);font-size:15px;"></i><audio controls style="height:36px;max-width:170px;"><source src="<%= request.getContextPath() %>/<%= msg.getFilePath() %>" type="audio/webm"></audio></div>
          <%-- Photo --%>
          <% } else if (msg.getFilePath()!=null && msg.getFileType()!=null && msg.getFileType().startsWith("image/")) { %>
            <div style="position:relative;display:inline-block;"><img src="<%= request.getContextPath() %>/<%= msg.getFilePath() %>" alt="Photo" onclick="openImageModal(this.src)" style="max-width:200px;max-height:200px;border-radius:11px;cursor:pointer;margin-top:3px;display:block;"><button onclick="downloadFile('<%= msg.getFilePath() %>')" style="position:absolute;bottom:7px;right:7px;background:rgba(0,0,0,.6);border:none;border-radius:50%;width:28px;height:28px;color:white;cursor:pointer;display:flex;align-items:center;justify-content:center;"><i class="fas fa-download" style="font-size:10px;"></i></button></div>
          <%-- Vidéo --%>
          <% } else if (msg.getFilePath()!=null && msg.getFileType()!=null && msg.getFileType().startsWith("video/")) { %>
            <div class="video-bubble"><video controls style="max-width:240px;max-height:200px;border-radius:11px;display:block;"><source src="<%= request.getContextPath() %>/<%= msg.getFilePath() %>" type="<%= msg.getFileType() %>"></video><div style="font-size:10px;color:var(--tx3);margin-top:4px;display:flex;align-items:center;gap:6px;"><i class="fas fa-video"></i>Vidéo<button onclick="downloadFile('<%= msg.getFilePath() %>')" style="background:none;border:none;cursor:pointer;color:var(--bleu);font-size:11px;margin-left:auto;"><i class="fas fa-download"></i></button></div></div>
          <%-- Fichier générique --%>
          <% } else if (msg.getFilePath()!=null && !msg.getFilePath().isEmpty()) { %>
            <%
            String fp2 = msg.getFilePath();
            String fn2 = fp2.substring(fp2.lastIndexOf('/')+1);
            String ext2= fn2.contains(".")?fn2.substring(fn2.lastIndexOf('.')+1).toUpperCase():"FILE";
            String fIcon= "fa-file";
            if ("PDF".equals(ext2)) fIcon="fa-file-pdf";
            else if ("DOC".equals(ext2)||"DOCX".equals(ext2)) fIcon="fa-file-word";
            else if ("XLS".equals(ext2)||"XLSX".equals(ext2)) fIcon="fa-file-excel";
            else if ("PPT".equals(ext2)||"PPTX".equals(ext2)) fIcon="fa-file-powerpoint";
            else if ("ZIP".equals(ext2)||"RAR".equals(ext2))  fIcon="fa-file-archive";
            %>
            <div class="file-bubble" onclick="downloadFile('<%= fp2 %>')">
              <div class="file-ico"><i class="fas <%= fIcon %>"></i></div>
              <div class="file-info"><div class="file-name"><%= fn2 %></div><div class="file-size"><%= ext2 %> · Cliquez pour télécharger</div></div>
              <i class="fas fa-download" style="font-size:13px;opacity:.7;margin-left:4px;"></i>
            </div>
          <% } %>
          <%-- Reply preview --%>
          <%
          Message rm = null;
          if (msg.getReplyToMessageId()>0) { try { rm = messageDAO.getMessageById(msg.getReplyToMessageId()); } catch(Exception e2){} }
          if (rm != null) {
              String rc = rm.getContent(); if(rc==null||rc.isEmpty()) rc="[Message]"; if(rc.length()>55) rc=rc.substring(0,55)+"…";
              String rn = rm.getSenderId()==user.getId()?"Vous":rm.getSenderName();
          %>
          <div class="replied-message-preview"><strong><%= rn %></strong><div><%= rc %></div></div>
          <% } %>
          <%-- Contenu --%>
          <% if(msg.getGifUrl()!=null&&!msg.getGifUrl().isEmpty()){%><div><img src="<%= msg.getGifUrl() %>" alt="GIF" style="max-width:185px;max-height:185px;border-radius:11px;cursor:pointer;" onclick="openImageModal(this.src)"></div><%}%>
          <% if(msg.getContent()!=null&&!msg.getContent().isEmpty()&&!"[GIF]".equals(msg.getContent())){out.print(escapeHtml(msg.getContent()).replace("\n","<br>"));}%>
          
          <%-- MODIFICATION 3 : Carte publication dans les messages --%>
          <% if (msg.getPropertyId() != null && !isDelAll && !isDelMe) {
               String pImgPath = msg.getPropertyImage();
               String pImgUrl  = (pImgPath != null && !pImgPath.isEmpty())
                                 ? request.getContextPath() + "/" + pImgPath : null;
               String pTypeClass = "Location".equals(msg.getPropertyType()) ? "location" : "vente";
               String pPriceFormatted = msg.getPropertyPrice() != null
                   ? String.format("%,.0f", msg.getPropertyPrice().doubleValue()) : "—";
          %>
          <a href="<%= request.getContextPath() %>/immo/property-detail.jsp?id=<%= msg.getPropertyId() %>"
             class="prop-card-msg" target="_blank">
            <% if (pImgUrl != null) { %>
              <img src="<%= pImgUrl %>" alt="<%= escapeHtml(msg.getPropertyTitle()) %>" class="prop-card-msg-img">
            <% } else { %>
              <div class="prop-card-msg-img-placeholder"><i class="fas fa-home"></i></div>
            <% } %>
            <div class="prop-card-msg-body">
              <span class="prop-card-msg-type <%= pTypeClass %>">
                <i class="fas <%= "location".equals(pTypeClass) ? "fa-home" : "fa-key" %>"></i>
                <%= escapeHtml(msg.getPropertyType()) %>
              </span>
              <div class="prop-card-msg-title"><%= escapeHtml(msg.getPropertyTitle()) %></div>
              <div class="prop-card-msg-price"><%= pPriceFormatted %> Ar</div>
              <% if (msg.getPropertyLocation() != null && !msg.getPropertyLocation().isEmpty()) { %>
              <div class="prop-card-msg-loc"><i class="fas fa-map-marker-alt"></i><%= escapeHtml(msg.getPropertyLocation()) %></div>
              <% } %>
            </div>
            <div class="prop-card-msg-footer"><i class="fas fa-external-link-alt"></i> Voir le bien</div>
          </a>
          <% } %>
        <% } %>
      </div>
      <% if(!ft.isEmpty() && !isDelAll && !isDelMe){%>
      <div class="message-info">
        <span class="message-time"><%= ft %></span>
        <% if(isSent){ if(msg.isIsRead()){%><i class="fas fa-check-double" style="color:#34b7f1;font-size:10px;"></i><%}else if(msg.isIsDelivered()){%><i class="fas fa-check-double" style="color:var(--tx3);font-size:10px;"></i><%}else{%><i class="fas fa-check" style="color:var(--tx3);font-size:10px;"></i><%}}%>
      </div>
      <% } %>
      <% if(!isDelAll && !isDelMe){%>
      <div class="message-reactions" id="reactions-<%= msg.getId() %>">
        <% Map<String,Integer> rxns=reactionDAO.getReactionsForMessage(msg.getId()); if(!rxns.isEmpty()){%><div class="reactions-bar"><% for(Map.Entry<String,Integer> e:rxns.entrySet()){String em="";if("like".equals(e.getKey()))em="👍";else if("love".equals(e.getKey()))em="❤️";else if("laugh".equals(e.getKey()))em="😂";else if("wow".equals(e.getKey()))em="😮";else if("sad".equals(e.getKey()))em="😢";%><span class="reaction-badge" onclick="toggleReaction(<%= msg.getId() %>,'<%= e.getKey() %>',<%= selectedUserId %>)"><%= em %> <%= e.getValue() %></span><%}%></div><%}%>
      </div>
      <div class="message-actions">
        <div class="reaction-picker" onmouseenter="showReactionPicker(this)" onmouseleave="hideReactionPickerDelayed(this)">
          <i class="far fa-smile-wink"></i>
          <div class="reaction-picker-popup" style="display:none;" onmouseenter="cancelHideReactionPicker()" onmouseleave="hideReactionPicker(this)">
            <span onclick="addReaction(<%= msg.getId() %>,'like',<%= selectedUserId %>)">👍</span>
            <span onclick="addReaction(<%= msg.getId() %>,'love',<%= selectedUserId %>)">❤️</span>
            <span onclick="addReaction(<%= msg.getId() %>,'laugh',<%= selectedUserId %>)">😂</span>
            <span onclick="addReaction(<%= msg.getId() %>,'wow',<%= selectedUserId %>)">😮</span>
            <span onclick="addReaction(<%= msg.getId() %>,'sad',<%= selectedUserId %>)">😢</span>
          </div>
        </div>
        <a href="#" onclick="showEditForm(<%= msg.getId() %>);return false;" title="Modifier">✏️</a>
        <a href="#" onclick="showForwardModal(<%= msg.getId() %>,'<%= msg.getContent()!=null?escapeJs(msg.getContent()):"" %>');return false;" title="Transférer">📤</a>
        <a href="#" onclick="replyToMessage(<%= msg.getId() %>,'<%= msg.getContent()!=null?escapeJs(msg.getContent()):"" %>','<%= isSent?"Vous":selectedUser.getDisplayName() %>');return false;" title="Répondre">💬</a>
        <a href="#" onclick="pinMessage(<%= msg.getId() %>,<%= selectedUserId %>);return false;" title="Épingler/Détacher">📌</a>
        <div class="delete-menu-wrapper">
          <a href="#" onclick="toggleDeleteMenu(this);return false;" title="Supprimer">🗑</a>
          <div class="delete-menu" style="display:none;">
            <a href="#" onclick="deleteMessageForMe(<%= msg.getId() %>,<%= selectedUserId %>);return false;"><i class="fas fa-mobile-alt"></i> Supprimer pour moi</a>
            <% if(isSent){%><a href="#" onclick="deleteMessageForEveryone(<%= msg.getId() %>,<%= selectedUserId %>);return false;"><i class="fas fa-globe"></i> Supprimer pour tout le monde</a><%}%>
          </div>
        </div>
      </div>
      <div id="editForm<%= msg.getId() %>" class="edit-form" style="display:none;">
        <form action="editMessage" method="post">
          <input type="hidden" name="messageId" value="<%= msg.getId() %>">
          <input type="hidden" name="receiverId" value="<%= selectedUserId %>">
          <input type="text" name="content" value="<%= msg.getContent()!=null?escapeHtml(msg.getContent()):"" %>">
          <button type="submit">OK</button><button type="button" onclick="hideEditForm(<%= msg.getId() %>)">Annuler</button>
        </form>
      </div>
      <% } %>
    </div>
  </div>
  <% } } else { %>
  <div class="no-selection" style="flex:1;"><i class="fas fa-comment-dots" style="font-size:38px;opacity:.18;color:var(--bleu);"></i><p><%= t_no_msg %></p></div>
  <% } %>
</div>

<%-- ZONE SAISIE --%>
<%
BlockedUserDAO bDAO = new BlockedUserDAO();
boolean uBlocked = bDAO.isBlocked(user.getId(), selectedUserId);
boolean cBlocked = bDAO.isBlocked(selectedUserId, user.getId());
String dsn = selectedUser.getDisplayName();
String dcnn= contactNameDAO.getCustomName(user.getId(), selectedUser.getId());
if (dcnn!=null&&!dcnn.isEmpty()) dsn=dcnn;
%>
<div class="message-input-area" id="inputArea">
  <div id="replyPreview" style="display:none;">
    <div style="display:flex;justify-content:space-between;align-items:center;">
      <div><span class="reply-name">Répondre à <span id="replyToName"></span></span><div id="replyPreviewContent"></div></div>
      <button type="button" onclick="cancelReply()" style="background:none;border:none;cursor:pointer;color:var(--tx3);font-size:18px;">&times;</button>
    </div>
  </div>
  
  <%-- MODIFICATION 4 : Prévisualisation + suggestions dans la zone de saisie --%>
  <!-- Publication partagée preview -->
  <% if (hasSharedProp) {
     String spImg = (sharedPropImage != null && !sharedPropImage.isEmpty())
                    ? request.getContextPath() + "/" + java.net.URLDecoder.decode(sharedPropImage, "UTF-8") : null;
     String spTitle    = sharedPropTitle    != null ? java.net.URLDecoder.decode(sharedPropTitle,    "UTF-8") : "";
     String spLocation = sharedPropLocation != null ? java.net.URLDecoder.decode(sharedPropLocation, "UTF-8") : "";
     String spType     = sharedPropType     != null ? java.net.URLDecoder.decode(sharedPropType,     "UTF-8") : "";
     String spPriceFmt = sharedPropPrice > 0 ? String.format("%,.0f", (double) sharedPropPrice) : "";
  %>
  <div id="propertySharePreview">
    <div class="prop-preview-header">
      <span><i class="fas fa-home"></i> Publication partagée</span>
      <button type="button" class="prop-preview-dismiss" onclick="dismissPropertyPreview()" title="Retirer">✕</button>
    </div>
    <div class="prop-preview-body">
      <% if (spImg != null) { %>
        <img src="<%= escapeHtml(spImg) %>" alt="" class="prop-preview-thumb">
      <% } else { %>
        <div class="prop-preview-thumb-ph"><i class="fas fa-home"></i></div>
      <% } %>
      <div class="prop-preview-info">
        <div class="prop-preview-title"><%= escapeHtml(spTitle) %></div>
        <div class="prop-preview-meta">
          <% if (!spPriceFmt.isEmpty()) { %><strong><%= spPriceFmt %> Ar</strong> · <% } %>
          <%= escapeHtml(spType) %>
          <% if (!spLocation.isEmpty()) { %> · <i class="fas fa-map-marker-alt" style="color:var(--rouge);font-size:9px;"></i> <%= escapeHtml(spLocation) %><% } %>
        </div>
      </div>
    </div>
    <!-- Suggestions rapides -->
    <div id="quickReplies">
      <button type="button" class="quick-reply-btn" onclick="useQuickReply(this)"><span>🏠</span> Je suis intéressé(e) !</button>
      <button type="button" class="quick-reply-btn" onclick="useQuickReply(this)"><span>🔑</span> Est-il encore disponible ?</button>
      <button type="button" class="quick-reply-btn" onclick="useQuickReply(this)"><span>📅</span> Je voudrais visiter</button>
      <button type="button" class="quick-reply-btn" onclick="useQuickReply(this)"><span>💬</span> Quel est le prix final ?</button>
    </div>
  </div>
  <% } else { %>
  <div id="propertySharePreview" style="display:none;"></div>
  <% } %>

  <% if (uBlocked) { %>
  <div class="blocked-banner"><span><i class="fas fa-ban"></i> Vous avez bloqué <%=dsn%></span><div style="display:flex;gap:7px;"><button class="bb-btn primary" onclick="unblockContact()">Débloquer</button><button class="bb-btn danger" onclick="deleteConversation()">Supprimer</button></div></div>
  <% } else if (cBlocked) { %>
  <div class="blocked-banner"><span><i class="fas fa-ban"></i> Vous ne pouvez pas répondre à cette discussion.</span></div>
  <% } else { %>

  <div class="input-left-tools">
    <label class="photo-label" for="photoInput" title="Envoyer une image"><i class="fas fa-image"></i></label>
    <input type="file" id="photoInput" accept="image/*" style="display:none;">
    
    <label class="tool-btn" for="videoInput" title="Envoyer une vidéo" style="cursor:pointer;color:#ef4444;"><i class="fas fa-video"></i></label>
    <input type="file" id="videoInput" accept="video/*" style="display:none;">
    
    <label class="tool-btn" for="fileInput" title="Envoyer un fichier" style="cursor:pointer;color:#059669;"><i class="fas fa-paperclip"></i></label>
    <input type="file" id="fileInput" accept=".pdf,.doc,.docx,.xls,.xlsx,.ppt,.pptx,.zip,.rar,.txt,.csv" style="display:none;">

    <div style="position:relative;">
      <button type="button" class="tool-btn" id="voiceTriggerBtn" title="Message vocal" style="color:#f97316;"><i class="fas fa-microphone"></i></button>
      <div class="left-panel voice-recorder-panel" id="voiceRecorderPanel">
        <div style="padding:16px;text-align:center;">
          <div id="voiceRecordingStatus" style="margin-bottom:10px;font-size:12.5px;color:var(--tx2);"><i class="fas fa-circle" style="color:var(--rouge);font-size:10px;"></i> Prêt à enregistrer</div>
          <div style="display:flex;gap:12px;justify-content:center;">
            <button id="startRecordBtn" class="voice-btn" type="button" style="background:var(--rouge);color:white;border:none;"><i class="fas fa-microphone"></i></button>
            <button id="stopRecordBtn"  class="voice-btn" type="button" style="background:var(--tx3);color:white;border:none;display:none;"><i class="fas fa-stop"></i></button>
            <button id="cancelRecordBtn" class="voice-btn" type="button" style="background:var(--surface2);border:1px solid var(--border);display:none;"><i class="fas fa-times"></i></button>
            <button id="sendVoiceBtn"   class="voice-btn" type="button" style="background:var(--vert);color:white;border:none;display:none;"><i class="fas fa-paper-plane"></i></button>
          </div>
          <div id="voiceTimer" style="display:none;margin-top:9px;font-size:14px;font-weight:700;color:var(--bleu);">0:00</div>
          <audio id="voicePreview" controls style="display:none;margin-top:9px;width:100%;"></audio>
        </div>
      </div>
    </div>

    <div style="position:relative;">
      <button type="button" class="tool-btn" id="gifTriggerBtn" title="GIF" style="color:#7c3aed;font-size:11px;font-weight:800;">GIF</button>
      <div class="left-panel gif-picker-panel" id="gifPickerPanel">
        <div style="padding:11px;">
          <div style="display:flex;gap:7px;margin-bottom:10px;">
            <input type="text" id="gifSearchInput" placeholder="<%= t_search %> GIF…" style="padding:7px 10px;border-radius:9px;font-size:12.5px;">
            <button id="searchGifBtn" type="button" style="padding:8px 12px;border-radius:9px;">🔍</button>
          </div>
          <div id="gifResults" style="display:grid;grid-template-columns:repeat(2,1fr);gap:7px;max-height:260px;overflow-y:auto;"><div style="text-align:center;padding:18px;color:var(--tx3);grid-column:1/-1;"><i class="fas fa-spinner fa-spin"></i></div></div>
          <div style="margin-top:7px;text-align:center;"><a href="#" onclick="loadTrendingGifs();return false;" style="font-size:11px;color:var(--tx3);">Tendances 🔥</a></div>
        </div>
      </div>
    </div>

    <div style="position:relative;">
      <button type="button" class="tool-btn" id="stickerTriggerBtn" title="Stickers" style="color:#f59e0b;"><i class="fas fa-face-grin-stars"></i></button>
      <div class="left-panel sticker-picker-panel" id="stickerPickerPanel">
        <div class="sticker-cats-header">
          <span class="sticker-cats-label">Catégories</span>
          <div class="sticker-cats-scroll">
            <button class="sticker-cat-pill active" data-cat="love"><span>😻</span><span>Amour</span></button>
            <button class="sticker-cat-pill" data-cat="happy"><span>😄</span><span>Joyeux</span></button>
            <button class="sticker-cat-pill" data-cat="sad"><span>😿</span><span>Triste</span></button>
            <button class="sticker-cat-pill" data-cat="funny"><span>😂</span><span>Drôle</span></button>
            <button class="sticker-cat-pill" data-cat="angry"><span>😡</span><span>Colère</span></button>
            <button class="sticker-cat-pill" data-cat="cool"><span>😎</span><span>Cool</span></button>
            <button class="sticker-cat-pill" data-cat="animal"><span>🐾</span><span>Animaux</span></button>
            <button class="sticker-cat-pill" data-cat="food"><span>🍕</span><span>Food</span></button>
          </div>
        </div>
        <div style="padding:10px;"><div id="stickerGrid" style="display:grid;grid-template-columns:repeat(4,1fr);gap:7px;max-height:230px;overflow-y:auto;scrollbar-width:thin;"></div></div>
      </div>
    </div>
  </div>

  <input type="hidden" id="replyToMessageId" value="">

  <form action="sendMessage" method="post" id="messageForm" enctype="multipart/form-data">
    <input type="hidden" name="receiverId" value="<%=selectedUserId%>">
    <input type="hidden" name="replyToMessageId" id="replyToMessageIdInput" value="">
    
    <%-- MODIFICATION 5 : Champs cachés pour la publication partagée --%>
    <input type="hidden" name="propertyId"       id="propertyIdInput"       value="<%= hasSharedProp ? escapeHtml(sharedPropId) : "" %>">
    <input type="hidden" name="propertyTitle"    id="propertyTitleInput"    value="<%= hasSharedProp && sharedPropTitle    != null ? escapeHtml(java.net.URLDecoder.decode(sharedPropTitle,    "UTF-8")) : "" %>">
    <input type="hidden" name="propertyPrice"    id="propertyPriceInput"    value="<%= hasSharedProp ? sharedPropPrice : "" %>">
    <input type="hidden" name="propertyImage"    id="propertyImageInput"    value="<%= hasSharedProp && sharedPropImage    != null ? escapeHtml(java.net.URLDecoder.decode(sharedPropImage,    "UTF-8")) : "" %>">
    <input type="hidden" name="propertyType"     id="propertyTypeInput"     value="<%= hasSharedProp && sharedPropType     != null ? escapeHtml(java.net.URLDecoder.decode(sharedPropType,     "UTF-8")) : "" %>">
    <input type="hidden" name="propertyLocation" id="propertyLocationInput" value="<%= hasSharedProp && sharedPropLocation != null ? escapeHtml(java.net.URLDecoder.decode(sharedPropLocation, "UTF-8")) : "" %>">
    
    <input type="text" name="content" id="messageInput" placeholder="<%= t_type_msg %>…" autocomplete="off">
    <div class="emoji-wrap-right">
      <button type="button" class="emoji-trigger-btn" id="emojiTriggerBtn" title="Emoji">😊</button>
      <div class="emoji-picker-panel" id="emojiPickerPanel">
        <div class="emoji-picker-inner">
          <div class="emoji-search-box"><i class="fas fa-search" style="color:var(--tx3);font-size:10px;"></i><input type="text" id="emojiSearchInput" placeholder="<%= t_search %>…"></div>
          <div class="emoji-tabs" id="emojiTabs">
            <button type="button" class="emoji-tab active" data-cat="recent">🕐</button>
            <button type="button" class="emoji-tab" data-cat="smileys">😀</button>
            <button type="button" class="emoji-tab" data-cat="people">👋</button>
            <button type="button" class="emoji-tab" data-cat="nature">🌿</button>
            <button type="button" class="emoji-tab" data-cat="food">🍕</button>
            <button type="button" class="emoji-tab" data-cat="travel">✈️</button>
            <button type="button" class="emoji-tab" data-cat="objects">💡</button>
            <button type="button" class="emoji-tab" data-cat="symbols">❤️</button>
          </div>
          <div class="emoji-grid" id="emojiGrid"></div>
        </div>
      </div>
    </div>
    <button type="submit" id="sendButton"><i class="fas fa-paper-plane"></i></button>
  </form>
  <% } %>
</div>
<div id="loadingIndicator"><i class="fas fa-spinner fa-pulse" style="color:var(--bleu);"></i><span>Envoi…</span></div>

<form action="uploadPhoto"  method="post" enctype="multipart/form-data" id="photoUploadForm"  style="display:none;"><input type="hidden" name="receiverId" id="photoReceiverId"><input type="file" name="photo"  id="photoFileInput"></form>
<form action="uploadVideo"  method="post" enctype="multipart/form-data" id="videoUploadForm"  style="display:none;"><input type="hidden" name="receiverId" id="videoReceiverId"><input type="file" name="video"  id="videoFileInput"></form>
<form action="uploadFile"   method="post" enctype="multipart/form-data" id="fileUploadForm"   style="display:none;"><input type="hidden" name="receiverId" id="fileReceiverId"><input type="file" name="file"   id="fileFileInput"></form>

<% } else { %>
<div class="no-selection">
  <img src="<%= request.getContextPath() %>/immo/admin/images/Logo.jpg"
       alt="Fredon"
       style="width: 64px; height: 64px; object-fit: cover; border-radius: 16px; box-shadow: 0 4px 12px rgba(0,0,0,.15);">
  <h2>Fredon <%= t_messaging %></h2>
  <p><%= t_select_chat %></p>
</div>
<% } %>
</div>
</div>

<div class="ringing-overlay" id="ringingOverlay">
  <div class="ringing-avatar" id="ringingAvatar"><% if(selectedUser!=null){%><%=selectedUser.getInitial()%><%}else{%>?<%}%></div>
  <div class="ringing-label" style="text-align:center;">
    <h4 id="ringingName"><% if(selectedUser!=null){%><%=selectedUser.getDisplayName()%><%}%></h4>
    <p id="ringingStatus"></p>
  </div>
  <div><button class="ringing-cancel-btn" onclick="cancelCall()"><i class="fas fa-phone-slash"></i></button></div>
</div>

<div id="editNameModal" class="modal-overlay">
  <div class="modal-box" style="width:310px;">
    <h3>✏️ Changer mon pseudo</h3>
    <input type="text" id="newDisplayName" placeholder="Nouveau pseudo" class="modal-input" style="margin-bottom:14px;">
    <div class="modal-btns"><button onclick="updateDisplayName()" class="modal-btn modal-btn-primary">Enregistrer</button><button onclick="closeNameModal()" class="modal-btn modal-btn-secondary">Annuler</button></div>
  </div>
</div>

<div id="renameModal" class="modal-overlay">
  <div class="modal-box" style="width:340px;">
    <h3>👤 Renommer le contact</h3>
    <input type="text" id="newContactName" placeholder="Nouveau nom" class="modal-input" style="margin-bottom:14px;">
    <div class="modal-btns"><button onclick="updateContactName()" class="modal-btn modal-btn-primary">Enregistrer</button><button onclick="closeRenameModal()" class="modal-btn modal-btn-secondary">Annuler</button></div>
    <div style="margin-top:10px;text-align:center;"><a href="#" onclick="removeContactName();return false;" style="font-size:12px;color:var(--rouge);">Supprimer le surnom</a></div>
  </div>
</div>

<div id="forwardModal" class="modal-overlay">
  <div class="modal-box" style="width:340px;">
    <h3>📤 Transférer le message</h3>
    <div style="background:var(--surface2);padding:10px 12px;border-radius:11px;margin-bottom:14px;max-height:70px;overflow-y:auto;border:1px solid var(--border);"><p id="forwardMessagePreview" style="font-size:12.5px;color:var(--tx2);"></p></div>
    <select id="forwardContactSelect" class="modal-input" style="margin-bottom:14px;">
      <option value="">-- Sélectionner un contact --</option>
      <% if(users!=null){for(User u:users){String dfn=u.getDisplayName();String cfn=contactNameDAO.getCustomName(user.getId(),u.getId());if(cfn!=null&&!cfn.isEmpty())dfn=cfn;%><option value="<%=u.getId()%>"><%=dfn%></option><%}}%>
    </select>
    <div class="modal-btns"><button onclick="submitForward()" class="modal-btn modal-btn-primary">Transférer</button><button onclick="closeForwardModal()" class="modal-btn modal-btn-secondary">Annuler</button></div>
  </div>
</div>

<div id="blockModal" class="modal-overlay">
  <div class="modal-box" style="width:300px;text-align:center;">
    <div style="width:52px;height:52px;background:rgba(220,38,38,.1);border-radius:14px;display:flex;align-items:center;justify-content:center;margin:0 auto 14px;"><i class="fas fa-ban" style="font-size:22px;color:var(--rouge);"></i></div>
    <h3>Bloquer ce contact ?</h3>
    <p style="color:var(--tx2);font-size:12.5px;margin-bottom:18px;line-height:1.6;">Vous ne recevrez plus ses messages.</p>
    <div class="modal-btns"><button onclick="blockContact()" class="modal-btn modal-btn-danger">Bloquer</button><button onclick="closeBlockModal()" class="modal-btn modal-btn-secondary">Annuler</button></div>
  </div>
</div>

<div id="deleteConversationModal" class="modal-overlay">
  <div class="modal-box" style="width:320px;text-align:center;">
    <div style="width:52px;height:52px;background:rgba(220,38,38,.1);border-radius:14px;display:flex;align-items:center;justify-content:center;margin:0 auto 14px;"><i class="fas fa-trash-alt" style="font-size:22px;color:var(--rouge);"></i></div>
    <h3>Supprimer la conversation ?</h3>
    <p style="color:var(--tx2);font-size:12.5px;margin-bottom:18px;line-height:1.6;">Tous les messages seront définitivement supprimés.</p>
    <div class="modal-btns"><button onclick="confirmDeleteConversation()" class="modal-btn modal-btn-danger">Supprimer</button><button onclick="closeDeleteConvModal()" class="modal-btn modal-btn-secondary">Annuler</button></div>
  </div>
</div>

<div id="themeModal" class="modal-overlay">
  <div class="modal-box" style="width:560px;max-width:94vw;max-height:88vh;overflow-y:auto;padding:0;">
    <div style="padding:18px 22px 12px;border-bottom:1px solid var(--border);position:sticky;top:0;background:var(--surface);z-index:1;border-radius:22px 22px 0 0;"><h3 style="margin:0;">🎨 Personnaliser la discussion</h3><p style="font-size:12px;color:var(--tx3);margin-top:3px;">Choisissez un thème</p></div>
    <div style="padding:18px 22px;">
      <p style="font-size:9.5px;font-weight:700;letter-spacing:1.5px;text-transform:uppercase;color:var(--tx3);margin-bottom:12px;">🎨 Couleurs de bulles</p>
      <div class="color-palette-grid">
        <button type="button" class="color-swatch-btn" onclick="selectTheme('default')"><div class="swatch-ring"><div class="swatch-inner" style="background:linear-gradient(135deg,#0e2d82,#1f52d4);"></div></div><span class="swatch-label">Défaut</span></button>
        <button type="button" class="color-swatch-btn" onclick="selectTheme('pink')"><div class="swatch-ring"><div class="swatch-inner" style="background:linear-gradient(135deg,#ec4899,#be185d);"></div></div><span class="swatch-label">💗 Rose</span></button>
        <button type="button" class="color-swatch-btn" onclick="selectTheme('gold')"><div class="swatch-ring"><div class="swatch-inner" style="background:linear-gradient(135deg,#f59e0b,#b45309);"></div></div><span class="swatch-label">✨ Or</span></button>
        <button type="button" class="color-swatch-btn" onclick="selectTheme('green')"><div class="swatch-ring"><div class="swatch-inner" style="background:linear-gradient(135deg,#10b981,#065f46);"></div></div><span class="swatch-label">🟢 Vert</span></button>
        <button type="button" class="color-swatch-btn" onclick="selectTheme('purple')"><div class="swatch-ring"><div class="swatch-inner" style="background:linear-gradient(135deg,#8b5cf6,#5b21b6);"></div></div><span class="swatch-label">💜 Violet</span></button>
        <button type="button" class="color-swatch-btn" onclick="selectTheme('red')"><div class="swatch-ring"><div class="swatch-inner" style="background:linear-gradient(135deg,#ef4444,#991b1b);"></div></div><span class="swatch-label">🔴 Rouge</span></button>
        <button type="button" class="color-swatch-btn" onclick="selectTheme('cyan')"><div class="swatch-ring"><div class="swatch-inner" style="background:linear-gradient(135deg,#06b6d4,#0e7490);"></div></div><span class="swatch-label">🩵 Cyan</span></button>
        <button type="button" class="color-swatch-btn" onclick="selectTheme('golden')"><div class="swatch-ring"><div class="swatch-inner" style="background:linear-gradient(135deg,#d97706,#92400e);"></div></div><span class="swatch-label">👑 Luxe</span></button>
      </div>
      <div style="height:1px;background:var(--border);margin:16px 0;"></div>
      <p style="font-size:9.5px;font-weight:700;letter-spacing:1.5px;text-transform:uppercase;color:var(--tx3);margin-bottom:12px;">✨ Thèmes animés</p>
      <div class="theme-grid">
        <div onclick="selectTheme('midnight')" class="theme-preview-card"><div class="preview-area" style="background:#0f172a;"><div class="preview-bubble-r" style="background:rgba(255,255,255,.12);color:#e2e8f0;margin-top:10px;">🌙 Bonsoir</div><div class="preview-bubble-s" style="background:linear-gradient(135deg,#1e40af,#2563eb);">⭐ Étoiles</div></div><div class="preview-label">🌙 Nuit étoilée</div></div>
        <div onclick="selectTheme('basketball')" class="theme-preview-card"><div class="preview-area" style="background:#fff7ed;"><div class="preview-bubble-r">🏀 Match ?</div><div class="preview-bubble-s" style="background:linear-gradient(135deg,#f97316,#c2410c);">💪 Dunk !</div></div><div class="preview-label">🏀 Basketball</div></div>
        <div onclick="selectTheme('rose')" class="theme-preview-card"><div class="preview-area" style="background:#fff1f2;"><div class="preview-bubble-r">💕 Coucou</div><div class="preview-bubble-s" style="background:linear-gradient(135deg,#e11d48,#9d174d);">❤️ Je t'aime</div></div><div class="preview-label">💕 Amour</div></div>
        <div onclick="selectTheme('aurora')" class="theme-preview-card"><div class="preview-area" style="background:linear-gradient(135deg,#0f0c29,#302b63);"><div class="preview-bubble-r" style="background:rgba(255,255,255,.1);color:#f0f4ff;">✨ Magique</div><div class="preview-bubble-s" style="background:linear-gradient(145deg,#06b6d4,#8b5cf6,#ec4899);">🌈 Aurore</div></div><div class="preview-label">✨ Aurore</div></div>
        <div onclick="selectTheme('ocean')" class="theme-preview-card"><div class="preview-area" style="background:#e0f7fa;"><div class="preview-bubble-r">🌊 Bonjour</div><div class="preview-bubble-s" style="background:linear-gradient(135deg,#0891b2,#155e75);">👋 Salut</div></div><div class="preview-label">🌊 Océan</div></div>
        <div onclick="selectTheme('cherry')" class="theme-preview-card"><div class="preview-area" style="background:#fdf2f8;"><div class="preview-bubble-r">🌸 Kawaii</div><div class="preview-bubble-s" style="background:linear-gradient(135deg,#f472b6,#db2777);">🌺 Mignon</div></div><div class="preview-label">🌸 Cerisier</div></div>
        <div onclick="selectTheme('cosmic')" class="theme-preview-card"><div class="preview-area" style="background:#0f0f23;"><div class="preview-bubble-r" style="background:rgba(168,85,247,.15);color:#f5f3ff;">🔮 Cosmos</div><div class="preview-bubble-s" style="background:linear-gradient(135deg,#a855f7,#5b21b6);">🌌 Galaxie</div></div><div class="preview-label">🌌 Cosmique</div></div>
        <div onclick="selectTheme('sunset')" class="theme-preview-card"><div class="preview-area" style="background:linear-gradient(180deg,#fff7ed 0%,#fed7aa 100%);"><div class="preview-bubble-r">🌅 Bonsoir</div><div class="preview-bubble-s" style="background:linear-gradient(135deg,#f97316,#dc2626);">✨ Magnifique</div></div><div class="preview-label">🌅 Coucher</div></div>
      </div>
    </div>
    <div style="padding:12px 22px 20px;border-top:1px solid var(--border);"><button onclick="closeThemeModal()" class="modal-btn modal-btn-secondary" style="width:100%;">Fermer</button></div>
  </div>
</div>

<div id="userProfileModal" class="modal-overlay">
  <div class="modal-box" style="width:340px;text-align:center;position:relative;">
    <button onclick="closeUserProfileModal()" style="position:absolute;top:12px;right:12px;background:var(--surface2);border:1px solid var(--border);border-radius:50%;width:30px;height:30px;cursor:pointer;color:var(--tx3);display:flex;align-items:center;justify-content:center;">✕</button>
    <div id="profileModalAvatar" style="width:110px;height:110px;margin:0 auto 14px;border-radius:50%;background:var(--grad-brand);display:flex;align-items:center;justify-content:center;color:white;font-size:38px;font-weight:700;border:3px solid var(--surface2);overflow:hidden;"></div>
    <h2 id="profileModalName" style="font-family:'Syne',sans-serif;font-size:19px;font-weight:700;margin-bottom:5px;color:var(--tx);"></h2>
    <p id="profileModalUsername" style="font-size:13px;color:var(--tx3);margin-bottom:14px;"></p>
    <button onclick="closeUserProfileModal()" class="modal-btn modal-btn-secondary" style="width:100%;margin-top:18px;">Fermer</button>
  </div>
</div>

<% if (adminId != null) { %>
<div id="createGroupModal" class="modal-overlay">
  <div class="modal-box" style="width:420px;">
    <div style="text-align:center;margin-bottom:18px;"><div style="width:46px;height:46px;background:var(--bleu-l);border-radius:13px;display:flex;align-items:center;justify-content:center;margin:0 auto 10px;"><i class="fas fa-users" style="font-size:19px;color:var(--bleu);"></i></div><h3>Créer un groupe</h3></div>
    <form id="createGroupForm" action="createGroup" method="post" style="display:flex;flex-direction:column;gap:12px;">
      <input type="text" name="groupName" placeholder="Nom du groupe *" required class="modal-input">
      <textarea name="description" placeholder="Description (optionnel)" rows="3" class="modal-input modal-textarea"></textarea>
      <button type="submit" class="modal-btn modal-btn-primary">Créer le groupe</button>
    </form>
    <div style="margin-top:10px;text-align:center;"><button onclick="closeCreateGroupModal()" style="background:none;border:none;color:var(--tx3);cursor:pointer;font-size:13px;">Annuler</button></div>
  </div>
</div>
<% } %>

<div id="videoCallModal">
  <div class="vcall-box">
    <div class="vcall-header"><h3>📹 Appel vidéo — <%= selectedUser!=null?selectedUser.getDisplayName():"Fredon" %></h3><button class="vcall-close" onclick="closeVideoCall()">✕</button></div>
    <div id="vcallWaiting" style="flex:1;background:#0d1117;display:flex;flex-direction:column;align-items:center;justify-content:center;gap:18px;position:relative;overflow:hidden;">
      <video id="localVideoPreview" autoplay muted playsinline style="position:absolute;inset:0;width:100%;height:100%;object-fit:cover;filter:blur(8px) brightness(0.35);transform:scaleX(-1);"></video>
      <div style="position:relative;z-index:2;display:flex;flex-direction:column;align-items:center;gap:16px;">
        <div style="position:relative;width:140px;height:140px;border-radius:50%;overflow:hidden;border:3px solid rgba(255,255,255,.25);box-shadow:0 0 40px rgba(31,82,212,.5);">
          <video id="localVideoMain" autoplay muted playsinline style="width:100%;height:100%;object-fit:cover;transform:scaleX(-1);"></video>
        </div>
        <div style="text-align:center;">
          <div style="font-family:'Syne',sans-serif;font-size:18px;font-weight:700;color:#fff;margin-bottom:4px;"><%=user.getDisplayName()%></div>
          <div style="font-size:13px;color:rgba(255,255,255,.55);display:flex;align-items:center;gap:6px;justify-content:center;"><span style="width:8px;height:8px;background:#22c55e;border-radius:50%;display:inline-block;animation:pulse 1.5s infinite;"></span>Appel en cours…</div>
        </div>
        <div style="display:flex;align-items:center;gap:10px;background:rgba(255,255,255,.08);border:1px solid rgba(255,255,255,.15);border-radius:14px;padding:10px 18px;">
          <div style="width:36px;height:36px;border-radius:10px;background:linear-gradient(135deg,#0e2d82,#1f52d4);display:flex;align-items:center;justify-content:center;font-family:'Syne',sans-serif;font-weight:800;font-size:14px;color:#fff;"><%= selectedUser!=null?selectedUser.getInitial():"?" %></div>
          <div><div style="font-size:13px;font-weight:600;color:#fff;"><%= selectedUser!=null?selectedUser.getDisplayName():"Contact" %></div><div id="vcallRingStatus" style="font-size:11px;color:rgba(255,255,255,.5);">Sonnerie…</div></div>
        </div>
        <button onclick="closeVideoCall()" style="background:var(--rouge);border:none;border-radius:50%;width:52px;height:52px;display:flex;align-items:center;justify-content:center;cursor:pointer;font-size:20px;color:#fff;box-shadow:0 4px 16px rgba(220,38,38,.5);margin-top:8px;"><i class="fas fa-phone-slash"></i></button>
      </div>
    </div>
    <div id="jitsiContainer" style="flex:1;background:#111;display:none;"></div>
    <div class="vcall-footer"><span>🔒 Appel sécurisé</span><input type="text" id="roomLink" class="room-link-input" readonly><button class="vcall-copy-btn" onclick="copyRoomLink()">Copier le lien</button></div>
  </div>
</div>

<div class="toast" id="toast"><i class="fas fa-check-circle"></i><span id="toastMsg">OK</span></div>
<form action="uploadProfilePic" method="post" enctype="multipart/form-data" id="uploadForm" style="display:none;"><input type="file" id="profilePicInput" name="profilePic" accept="image/*" onchange="this.form.submit();"></form>
<% if (adminId != null) { %><button id="toggleAdminNavBtn"><i class="fas fa-chevron-left" id="adminToggleIcon"></i></button><% } %>
<script>
// ============================================================
// SCRIPT UNIQUE - TOUTES LES FONCTIONNALITÉS
// ============================================================

var selectedUserId = <%= selectedUserId %>;
var currentUserId = <%= user.getId() == 999 ? 9 : user.getId() %>;
var jitsiApi = null;
var roomName = "fredon_<%= selectedUserId %>_" + Math.floor(Date.now()/1000);
var callType = null, ringingTimer = null, ringingSeconds = 0, RINGING_MAX = 20;
var audioCtx = null, oscillators = [], localStream = null;
var mediaRecorder = null, audioChunks = [], recTimer = null, recSecs = 0, recordedBlob = null;

function showToast(msg, type) {
  var t = document.getElementById('toast');
  if(!t) return;
  document.getElementById('toastMsg').textContent = msg;
  t.className = 'toast' + (type==='error'?' toast-error':'');
  t.classList.add('show');
  setTimeout(function(){ t.classList.remove('show'); }, 3200);
}

/* Dark mode */
var isDark = localStorage.getItem('fredon_theme') === 'dark';
function applyTheme() {
  var b = document.getElementById('body');
  var tt = document.getElementById('themeToggle');
  if (isDark) {
    b.classList.add('dm');
    b.classList.remove('light');
    if (tt) tt.innerHTML = '<i class="fas fa-sun" style="font-size:14px;color:#f59e0b;"></i>';
  } else {
    b.classList.remove('dm');
    b.classList.add('light');
    if (tt) tt.innerHTML = '<i class="fas fa-moon" style="font-size:14px;"></i>';
  }
}
var themeBtn = document.getElementById('themeToggle');
if (themeBtn) {
  themeBtn.addEventListener('click', function() {
    isDark = !isDark;
    localStorage.setItem('fredon_theme', isDark ? 'dark' : 'light');
    applyTheme();
    showToast(isDark ? '🌙 Mode sombre activé' : '☀️ Mode clair activé');
  });
}
applyTheme();

/* Admin nav toggle */
var adminNav = document.getElementById('adminNavEl');
var toggleBtn = document.getElementById('toggleAdminNavBtn');
if (toggleBtn && adminNav) {
  toggleBtn.style.left = '248px';
  toggleBtn.addEventListener('click', function() {
    if (adminNav.style.width === '0px') {
      adminNav.style.width = '';
      adminNav.style.minWidth = '';
      adminNav.style.overflow = '';
      adminNav.style.padding = '';
      document.getElementById('adminToggleIcon').className = 'fas fa-chevron-left';
      toggleBtn.style.left = '248px';
    } else {
      adminNav.style.width = '0';
      adminNav.style.minWidth = '0';
      adminNav.style.overflow = 'hidden';
      adminNav.style.padding = '0';
      document.getElementById('adminToggleIcon').className = 'fas fa-chevron-right';
      toggleBtn.style.left = '20px';
    }
  });
}

/* Sidebar pin */
var isPinned = localStorage.getItem('sidebar_pinned') !== 'false';
var sidebar = document.getElementById('sidebarEl');
var pinBtn = document.getElementById('pinToggleBtn');
function applySidebarState() {
  if (!sidebar || !pinBtn) return;
  if (!isPinned) { sidebar.classList.add('collapsed'); pinBtn.innerHTML='<i class="fas fa-chevron-right"></i>'; }
  else { sidebar.classList.remove('collapsed'); pinBtn.innerHTML='<i class="fas fa-chevron-left"></i>'; }
}
if (pinBtn) pinBtn.onclick = function() { isPinned=!isPinned; localStorage.setItem('sidebar_pinned',isPinned); applySidebarState(); };
applySidebarState();

/* Header menu */
function toggleHdrMenu() { document.getElementById('hdrMenuPopup').classList.toggle('open'); }
function closeHdrMenu() { document.getElementById('hdrMenuPopup').classList.remove('open'); }
document.addEventListener('click', function(e) { var w=document.querySelector('.hdr-menu-wrap'); if(w&&!w.contains(e.target)) closeHdrMenu(); });

/* Appels */
function playRingtone() {
  try {
    audioCtx = new (window.AudioContext || window.webkitAudioContext)();
    var ri = setInterval(function() {
      if (!audioCtx) { clearInterval(ri); return; }
      var o=audioCtx.createOscillator(), g=audioCtx.createGain();
      o.connect(g); g.connect(audioCtx.destination);
      o.frequency.setValueAtTime(880, audioCtx.currentTime);
      o.frequency.setValueAtTime(1100, audioCtx.currentTime+0.1);
      g.gain.setValueAtTime(0.25, audioCtx.currentTime);
      g.gain.exponentialRampToValueAtTime(0.001, audioCtx.currentTime+0.4);
      o.start(); o.stop(audioCtx.currentTime+0.4);
    }, 700);
    oscillators.push(ri);
  } catch(e) {}
}
function stopRingtone() {
  oscillators.forEach(function(id){clearInterval(id);}); oscillators=[];
  if(audioCtx){try{audioCtx.close();}catch(e){} audioCtx=null;}
}
function stopLocalStream() {
  if(localStream){localStream.getTracks().forEach(function(t){t.stop();});localStream=null;}
}

function sendMissedCallMsg(msg, type) {
  var f = document.createElement('form');
  f.method = 'POST';
  f.action = 'sendMessage';
  f.style.display = 'none';
  var i1 = document.createElement('input'); i1.type='hidden'; i1.name='receiverId'; i1.value=selectedUserId;
  var i2 = document.createElement('input'); i2.type='hidden'; i2.name='content'; i2.value=msg;
  f.appendChild(i1); f.appendChild(i2);
  document.body.appendChild(f);
  f.submit();
}

function showRinging(type) {
  callType=type; ringingSeconds=0;
  var overlay=document.getElementById('ringingOverlay');
  document.getElementById('ringingStatus').textContent = type==='video'?'📹 Sonnerie…':'📞 Sonnerie…';
  overlay.classList.add('show');
  playRingtone();
  ringingTimer=setInterval(function(){
    ringingSeconds++;
    if(ringingSeconds>=RINGING_MAX){
      clearInterval(ringingTimer); ringingTimer=null; stopRingtone();
      overlay.classList.remove('show');
      if(type==='video'){
        sendMissedCallMsg('📹 Appel vidéo manqué', type);
        showToast('📹 Appel vidéo manqué');
        stopLocalStream();
        document.getElementById('videoCallModal').style.display='none';
      } else {
        sendMissedCallMsg('📞 Appel vocal manqué', type);
        showToast('📞 Appel vocal manqué');
      }
    }
  },1000);
}

function cancelCall() {
  if(ringingTimer){clearInterval(ringingTimer);ringingTimer=null;}
  stopRingtone(); stopLocalStream();
  document.getElementById('ringingOverlay').classList.remove('show');
  if(jitsiApi){jitsiApi.dispose();jitsiApi=null;}
  document.getElementById('videoCallModal').style.display='none';
  var jc=document.getElementById('jitsiContainer'); jc.innerHTML=''; jc.style.display='none';
  var vw=document.getElementById('vcallWaiting'); if(vw) vw.style.display='flex';
}

async function startVideoCall() {
  document.getElementById('videoCallModal').style.display='flex';
  var jitsiDiv=document.getElementById('jitsiContainer');
  var waitDiv =document.getElementById('vcallWaiting');
  jitsiDiv.style.display='none'; waitDiv.style.display='flex';
  try {
    localStream = await navigator.mediaDevices.getUserMedia({video:true,audio:true});
    var lv1=document.getElementById('localVideoPreview');
    var lv2=document.getElementById('localVideoMain');
    if(lv1){lv1.srcObject=localStream;}
    if(lv2){lv2.srcObject=localStream;}
  } catch(e){ console.warn('Caméra indisponible',e); }
  showRinging('video');
  try {
    jitsiApi = new JitsiMeetExternalAPI("meet.jit.si",{
      roomName:roomName, parentNode:jitsiDiv,
      userInfo:{displayName:"<%=user.getDisplayName()%>"},
      configOverwrite:{startWithAudioMuted:false,startWithVideoMuted:false,prejoinPageEnabled:false,enableWelcomePage:false},
      interfaceConfigOverwrite:{SHOW_JITSI_WATERMARK:false,TOOLBAR_BUTTONS:['microphone','camera','desktop','fullscreen','hangup','chat','raisehand']}
    });
    document.getElementById('roomLink').value="https://meet.jit.si/"+roomName;
    jitsiApi.addEventListener('participantJoined',function(){
      if(ringingTimer){clearInterval(ringingTimer);ringingTimer=null;}
      stopRingtone(); stopLocalStream();
      document.getElementById('ringingOverlay').classList.remove('show');
      waitDiv.style.display='none';
      jitsiDiv.style.display='block';
    });
  } catch(e){ cancelCall(); showToast('Impossible de démarrer l\'appel','error'); }
}
function closeVideoCall(){ cancelCall(); }
function copyRoomLink(){ var i=document.getElementById('roomLink');i.select();document.execCommand('copy');showToast('✅ Lien copié !'); }
function startVoiceCall(){ showRinging('voice'); }

/* Répondre */
function replyToMessage(messageId, content, senderName) {
  document.getElementById('replyPreview').style.display='block';
  document.getElementById('replyToName').innerText=senderName;
  document.getElementById('replyPreviewContent').innerText=content.length>55?content.substring(0,55)+'…':content;
  document.getElementById('replyToMessageId').value=messageId;
  document.getElementById('replyToMessageIdInput').value=messageId;
  document.getElementById('messageInput').focus();
}
function cancelReply() {
  document.getElementById('replyPreview').style.display='none';
  document.getElementById('replyToMessageId').value='';
  document.getElementById('replyToMessageIdInput').value='';
}
function scrollToMessage(messageId) {
  var el=document.querySelector('.message[data-message-id="'+messageId+'"]');
  if(el){ el.scrollIntoView({behavior:'smooth',block:'center'}); el.style.transition='background .3s'; el.style.background='rgba(31,82,212,.1)'; setTimeout(function(){ el.style.background=''; },2000); }
}

/* Suppression */
function deleteMessageForMe(messageId, receiverId) {
  if(!confirm('Supprimer ce message pour vous uniquement ?')) return;
  var f=document.createElement('form');
  f.method='POST'; f.action='deleteMessage'; f.style.display='none';
  [['messageId',messageId],['receiverId',receiverId],['type','me']].forEach(function(p){
    var i=document.createElement('input'); i.type='hidden'; i.name=p[0]; i.value=p[1]; f.appendChild(i);
  });
  document.body.appendChild(f); f.submit();
}
function deleteMessageForEveryone(messageId, receiverId) {
  if(!confirm('Supprimer ce message pour tout le monde ?\nTous verront "Ce message a été supprimé".')) return;
  var f=document.createElement('form');
  f.method='POST'; f.action='deleteMessage'; f.style.display='none';
  [['messageId',messageId],['receiverId',receiverId],['type','everyone']].forEach(function(p){
    var i=document.createElement('input'); i.type='hidden'; i.name=p[0]; i.value=p[1]; f.appendChild(i);
  });
  document.body.appendChild(f); f.submit();
}

/* Épingler / Détacher */
function pinMessage(messageId, userId) {
  var form = document.createElement('form');
  form.method = 'POST';
  form.action = 'pinMessage';
  form.style.display = 'none';
  var inp1 = document.createElement('input'); inp1.type='hidden'; inp1.name='messageId'; inp1.value=messageId;
  var inp2 = document.createElement('input'); inp2.type='hidden'; inp2.name='userId'; inp2.value=userId;
  form.appendChild(inp1); form.appendChild(inp2);
  document.body.appendChild(form);
  form.submit();
}

/* Uploads */
function setupUpload(inputId, apiUrl, typeName) {
  var input = document.getElementById(inputId);
  if (!input) return;
  input.addEventListener('change', function() {
    if (!this.files || !this.files[0]) return;
    var file = this.files[0];
    if (typeName === 'video' && file.size > 50*1024*1024) { showToast('Vidéo trop grande (max 50 Mo)','error'); return; }
    if (typeName === 'file' && file.size > 20*1024*1024) { showToast('Fichier trop grand (max 20 Mo)','error'); return; }
    var fd = new FormData();
    fd.append('receiverId', selectedUserId);
    fd.append(typeName, file);
    showToast('📎 Envoi du ' + typeName + '…');
    fetch(apiUrl, {method:'POST', body:fd})
      .then(function(r){ if(r.ok) location.reload(); else showToast('Erreur envoi','error'); })
      .catch(function(){ showToast('Erreur réseau','error'); });
    input.value = '';
  });
}
setupUpload('photoInput', 'uploadPhoto', 'photo');
setupUpload('videoInput', 'uploadVideo', 'video');
setupUpload('fileInput', 'uploadFile', 'file');

/* Émojis - VERSION FONCTIONNELLE */
var emojiData = {
  recent:['😊','❤️','😂','👍','🔥','🎉','😍','✨','🙏','💕','😘','🥰','😅','🤣','😭','💪','🎊','🌸','💯','😎'],
  smileys:['😀','😃','😄','😁','😆','😅','😂','🤣','😊','😇','🙂','🙃','😉','😌','😍','🥰','😘','😗','😚','😋','😛','😝','😜','🤪','🤨','🧐','🤓','😎','🤩','🥳','😏','😒','😞','😔','😟','😕','🙁','☹️','😣','😖','😫','😩','🥺','😢','😭','😤','😠','😡','🤬','🤯','😳','🥵','🥶','😱','😨','😰','😥','😓','🤗','🤔','🤭','🤫','🤥','😶','😐','😑','😬','🙄','😯','😦','😧','😮','😲','🥱','😴','😵','😷','🤒','🤕','🤑','🤠'],
  people:['👋','🤚','🖐️','✋','🖖','👌','🤏','✌️','🤞','🤟','🤘','🤙','👈','👉','👆','👇','☝️','👍','👎','✊','👊','🤛','🤜','👏','🙌','👐','🤲','🤝','🙏','✍️','💅','💪','🦾'],
  nature:['🐶','🐱','🐭','🐹','🐰','🦊','🐻','🐼','🐨','🐯','🦁','🐮','🐷','🐸','🐵','🙈','🐔','🐧','🐦','🦆','🦅','🦉','🐝','🌱','🌿','☘️','🍀','🌺','🌸','🌹','🌻','🌼','🌷','🌳','🌲','🌵','🌴','🌊','🌈','⭐','🌟','✨','☀️','🌙','❄️','⚡','🔥'],
  food:['🍎','🍐','🍊','🍋','🍌','🍉','🍇','🍓','🍒','🍑','🥭','🍍','🥥','🥝','🍅','🥑','🥦','🌽','🥕','🧄','🍳','🥘','🍲','🥗','🧁','🍰','🎂','🍭','🍬','🍫','🍿','🍩','🍪','🍕','🍔','🌮'],
  travel:['🚗','🚕','🚙','🏎️','✈️','🚀','🛸','🚁','⛵','🚢','🏖️','🏔️','🌋','🏕️','🗺️','🗼','🗽','🏰','🌅','🌄','🌠','🌇','🌆','🏙️','🌃','🌌','🌉'],
  objects:['💡','🔦','💎','💍','👑','🎩','🎨','📷','📱','💻','📚','📖','🔑','🗝️','🔒','🔓','🔨','⚙️','🔬','🔭','💊','🩺','🩹','🛋️','🛏️','🚿','🚪','🪟'],
  symbols:['❤️','🧡','💛','💚','💙','💜','🖤','🤍','🤎','❣️','💕','💞','💓','💗','💖','💘','💝','☮️','✝️','☯️','✡️','⭐','🌟','💫','✨','🔥','💥','❄️','🌊','🎊','🎉','🎁','🎀','🎈','🏆','🥇','💯','✅','❌','🔴','🟠','🟡','🟢','🔵','🟣','⚫','⚪']
};
var currentEmojiCat = 'recent';
var recentEmojis = JSON.parse(localStorage.getItem('fredon_recent_emojis') || '["😊","❤️","😂","👍","🔥","🎉","😍","✨","🙏","💕"]');

function renderEmojiGrid(cat, filter) {
  var grid = document.getElementById('emojiGrid');
  if (!grid) return;
  var list = (cat==='recent') ? recentEmojis : (emojiData[cat]||[]);
  if (filter && filter.trim()) { var all=[]; Object.values(emojiData).forEach(function(a){all=all.concat(a);}); list=Array.from(new Set(all)); }
  grid.innerHTML = list.map(function(e){ return '<span onclick="insertEmoji(\''+e+'\')" title="'+e+'">'+e+'</span>'; }).join('');
}
function insertEmoji(emoji) {
  var input = document.getElementById('messageInput');
  if (!input) return;
  var s=input.selectionStart||0, e2=input.selectionEnd||0;
  input.value = input.value.substring(0,s)+emoji+input.value.substring(e2);
  input.selectionStart = input.selectionEnd = s+emoji.length;
  input.focus();
  recentEmojis = [emoji,...recentEmojis.filter(function(x){return x!==emoji;})].slice(0,20);
  localStorage.setItem('fredon_recent_emojis', JSON.stringify(recentEmojis));
  var panel = document.getElementById('emojiPickerPanel');
  if (panel) panel.style.display = 'none';
}

function closeAllPickers() {
  var panels = document.querySelectorAll('.emoji-picker-panel, .gif-picker-panel, .sticker-picker-panel, .voice-recorder-panel');
  panels.forEach(function(p){ if(p) p.style.display = 'none'; });
}

/* GIF */
var GIPHY_KEY='tQcwxW98yKeti6Wq5b5Zc2WEHtPeoequ';
function loadTrendingGifs(){
  var c=document.getElementById('gifResults'); if(!c)return;
  c.innerHTML='<div style="text-align:center;padding:18px;grid-column:1/-1;"><i class="fas fa-spinner fa-spin"></i></div>';
  fetch('https://api.giphy.com/v1/gifs/trending?api_key='+GIPHY_KEY+'&limit=10&rating=g')
  .then(function(r){return r.json();}).then(function(d){
    if(d.data&&d.data.length>0) c.innerHTML=d.data.map(function(g){return '<div onclick="sendGif(\''+g.images.fixed_height_small.url.replace(/'/g,"\\'")+'\');" style="cursor:pointer;border-radius:8px;overflow:hidden;"><img src="'+g.images.fixed_height_small.url+'" style="width:100%;border-radius:8px;"></div>';}).join('');
  }).catch(function(){c.innerHTML='<div style="text-align:center;padding:18px;grid-column:1/-1;color:var(--tx3);">Erreur</div>';});
}
function searchGifs(q){
  var c=document.getElementById('gifResults');
  c.innerHTML='<div style="text-align:center;padding:18px;grid-column:1/-1;"><i class="fas fa-spinner fa-spin"></i></div>';
  fetch('https://api.giphy.com/v1/gifs/search?api_key='+GIPHY_KEY+'&q='+encodeURIComponent(q)+'&limit=10&rating=g')
  .then(function(r){return r.json();}).then(function(d){
    if(d.data&&d.data.length>0) c.innerHTML=d.data.map(function(g){return '<div onclick="sendGif(\''+g.images.fixed_height_small.url.replace(/'/g,"\\'")+'\');" style="cursor:pointer;border-radius:8px;overflow:hidden;"><img src="'+g.images.fixed_height_small.url+'" style="width:100%;border-radius:8px;"></div>';}).join('');
    else c.innerHTML='<div style="text-align:center;grid-column:1/-1;padding:18px;color:var(--tx3);">Aucun résultat</div>';
  }).catch(function(){c.innerHTML='<div style="text-align:center;grid-column:1/-1;padding:18px;">Erreur</div>';});
}
function sendGif(url){
  var f=document.createElement('form');f.method='POST';f.action='sendMessage';f.style.display='none';
  [['receiverId',selectedUserId],['gifUrl',url]].forEach(function(p){var i=document.createElement('input');i.type='hidden';i.name=p[0];i.value=p[1];f.appendChild(i);});
  document.body.appendChild(f);f.submit();
}

/* Stickers */
var stickerCats={love:'love cute sticker kiss',happy:'happy celebration sticker',sad:'sad crying broken heart',funny:'funny laughing meme sticker',angry:'angry mad frustrated',cool:'cool sunglasses dancing',animal:'cute cat dog animal',food:'pizza burger food sticker'};
function loadStickers(cat){
  var grid=document.getElementById('stickerGrid');if(!grid)return;
  grid.innerHTML='<div style="text-align:center;padding:16px;grid-column:1/-1;"><i class="fas fa-spinner fa-spin"></i></div>';
  fetch('https://api.giphy.com/v1/stickers/search?api_key='+GIPHY_KEY+'&q='+encodeURIComponent(stickerCats[cat]||cat)+'&limit=16&rating=g')
  .then(function(r){return r.json();}).then(function(d){
    if(d.data&&d.data.length>0) grid.innerHTML=d.data.map(function(s){return '<div style="cursor:pointer;border-radius:9px;overflow:hidden;transition:transform .15s;" onmouseover="this.style.transform=\'scale(1.08)\'" onmouseout="this.style.transform=\'\'" onclick="sendSticker(\''+s.images.fixed_height_small.url.replace(/'/g,"\\'")+'\')"><img src="'+s.images.fixed_height_small.url+'" style="width:58px;height:58px;border-radius:9px;"></div>';}).join('');
    else grid.innerHTML='<div style="text-align:center;padding:16px;color:var(--tx3);grid-column:1/-1;">Aucun</div>';
  }).catch(function(){grid.innerHTML='<div style="text-align:center;padding:16px;grid-column:1/-1;">Erreur</div>';});
}
function sendSticker(url){
  var f=document.createElement('form');f.method='POST';f.action='sendMessage';f.style.display='none';
  [['receiverId',selectedUserId],['gifUrl',url]].forEach(function(p){var i=document.createElement('input');i.type='hidden';i.name=p[0];i.value=p[1];f.appendChild(i);});
  document.body.appendChild(f);f.submit();
}

/* Voice recorder */
function resetRecording(){
  if(mediaRecorder&&mediaRecorder.state==='recording')mediaRecorder.stop();
  audioChunks=[];if(recTimer)clearInterval(recTimer);recSecs=0;
  var vt2=document.getElementById('voiceTimer'),vp2=document.getElementById('voicePreview'),vs2=document.getElementById('voiceRecordingStatus');
  if(vt2)vt2.style.display='none';
  if(vp2){vp2.style.display='none';vp2.src='';}
  var sb=document.getElementById('startRecordBtn'),stpb=document.getElementById('stopRecordBtn'),cb=document.getElementById('cancelRecordBtn'),svb=document.getElementById('sendVoiceBtn');
  if(sb)sb.style.display='inline-flex';if(stpb)stpb.style.display='none';if(cb)cb.style.display='none';if(svb)svb.style.display='none';
  if(vs2)vs2.innerHTML='<i class="fas fa-circle" style="color:var(--rouge);font-size:10px;"></i> Prêt';
  recordedBlob=null;
}
var startRB=document.getElementById('startRecordBtn');
if(startRB){
  startRB.addEventListener('click',async function(){
    try{
      var stream=await navigator.mediaDevices.getUserMedia({audio:true});
      mediaRecorder=new MediaRecorder(stream);audioChunks=[];
      mediaRecorder.ondataavailable=function(e){audioChunks.push(e.data);};
      mediaRecorder.onstop=function(){
        recordedBlob=new Blob(audioChunks,{type:'audio/webm'});
        var vp2=document.getElementById('voicePreview');
        vp2.src=URL.createObjectURL(recordedBlob);vp2.style.display='block';
        document.getElementById('sendVoiceBtn').style.display='inline-flex';
        stream.getTracks().forEach(function(t){t.stop();});
      };
      mediaRecorder.start();
      startRB.style.display='none';
      document.getElementById('stopRecordBtn').style.display='inline-flex';
      document.getElementById('cancelRecordBtn').style.display='inline-flex';
      document.getElementById('voiceRecordingStatus').innerHTML='<i class="fas fa-circle" style="color:var(--rouge);font-size:10px;"></i> Enregistrement…';
      var vt2=document.getElementById('voiceTimer');vt2.style.display='block';vt2.textContent='0:00';recSecs=0;
      recTimer=setInterval(function(){recSecs++;var m=Math.floor(recSecs/60),s=recSecs%60;vt2.textContent=m+':'+(s<10?'0':'')+s;if(recSecs>=120)stopRecFn();},1000);
    }catch(err){showToast('Microphone inaccessible','error');}
  });
}
function stopRecFn(){if(mediaRecorder&&mediaRecorder.state==='recording'){mediaRecorder.stop();if(recTimer)clearInterval(recTimer);document.getElementById('stopRecordBtn').style.display='none';document.getElementById('voiceRecordingStatus').innerHTML='<i class="fas fa-check-circle" style="color:var(--vert);"></i> Terminé';}}
var stpRB=document.getElementById('stopRecordBtn'),canRB=document.getElementById('cancelRecordBtn'),sndVRB=document.getElementById('sendVoiceBtn');
if(stpRB)stpRB.addEventListener('click',stopRecFn);
if(canRB)canRB.addEventListener('click',resetRecording);
if(sndVRB){sndVRB.addEventListener('click',function(){
  if(!recordedBlob)return;
  var fd=new FormData();fd.append('receiverId',selectedUserId);fd.append('voice',recordedBlob,'voice_'+Date.now()+'.webm');
  fetch('sendVoiceMessage',{method:'POST',body:fd}).then(function(r){if(r.ok){closeAllPickers();resetRecording();location.reload();}else showToast('Erreur envoi','error');});
});}

/* Réactions */
var rxHideTimeout=null;
function showReactionPicker(el){if(rxHideTimeout)clearTimeout(rxHideTimeout);el.querySelector('.reaction-picker-popup').style.display='flex';}
function hideReactionPickerDelayed(el){rxHideTimeout=setTimeout(function(){if(el.querySelector('.reaction-picker-popup'))el.querySelector('.reaction-picker-popup').style.display='none';},400);}
function cancelHideReactionPicker(){if(rxHideTimeout)clearTimeout(rxHideTimeout);}
function hideReactionPicker(el){el.style.display='none';}
function addReaction(messageId, type, userId) {
    var form = document.createElement('form');
    form.method = 'POST';
    form.action = '<%= request.getContextPath() %>/addReaction';
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
    input3.name = 'userId';
    input3.value = userId;
    form.appendChild(input3);
    
    document.body.appendChild(form);
    form.submit();
}
function toggleReaction(messageId,type,userId){addReaction(messageId,type,userId);}

/* Renommer */
function showRenameModal(){document.getElementById('renameModal').classList.add('open');}
function closeRenameModal(){document.getElementById('renameModal').classList.remove('open');}
function updateContactName(){
  var nn=document.getElementById('newContactName').value;
  if(!nn.trim()){showToast('Entrez un nom','error');return;}
  var f=document.createElement('form');f.method='POST';f.action='renameContact';f.style.display='none';
  [['contactId',selectedUserId],['newName',nn]].forEach(function(p){var i=document.createElement('input');i.type='hidden';i.name=p[0];i.value=p[1];f.appendChild(i);});
  document.body.appendChild(f);f.submit();
}
function removeContactName(){
  var f=document.createElement('form');f.method='POST';f.action='renameContact';f.style.display='none';
  [['contactId',selectedUserId],['newName','']].forEach(function(p){var i=document.createElement('input');i.type='hidden';i.name=p[0];i.value=p[1];f.appendChild(i);});
  document.body.appendChild(f);f.submit();
}

/* Group / Edit name */
function openCreateGroupModal(){var m=document.getElementById('createGroupModal');if(m)m.classList.add('open');}
function closeCreateGroupModal(){var m=document.getElementById('createGroupModal');if(m)m.classList.remove('open');}
function showEditNameModal(){document.getElementById('profileMenu').style.display='none';document.getElementById('editNameModal').classList.add('open');}
function closeNameModal(){document.getElementById('editNameModal').classList.remove('open');}
function updateDisplayName(){
  var n=document.getElementById('newDisplayName').value;
  if(!n.trim()){showToast('Entrez un pseudo','error');return;}
  var f=document.createElement('form');f.method='POST';f.action='updateDisplayName';f.style.display='none';
  var i=document.createElement('input');i.type='hidden';i.name='displayName';i.value=n;f.appendChild(i);
  document.body.appendChild(f);f.submit();
}

/* Block / Delete / Archive */
function showBlockModal(){document.getElementById('blockModal').classList.add('open');}
function closeBlockModal(){document.getElementById('blockModal').classList.remove('open');}
function blockContact(){
  var f=document.createElement('form');f.method='POST';f.action='blockUser';f.style.display='none';
  var i=document.createElement('input');i.type='hidden';i.name='blockedId';i.value=selectedUserId;f.appendChild(i);
  document.body.appendChild(f);f.submit();
}
function unblockContact(){
  var f=document.createElement('form');f.method='POST';f.action='unblockUser';f.style.display='none';
  var i=document.createElement('input');i.type='hidden';i.name='blockedId';i.value=selectedUserId;f.appendChild(i);
  document.body.appendChild(f);f.submit();
}
function showDeleteConvModal(){document.getElementById('deleteConversationModal').classList.add('open');}
function closeDeleteConvModal(){document.getElementById('deleteConversationModal').classList.remove('open');}
function confirmDeleteConversation(){
  var f=document.createElement('form');f.method='POST';f.action='deleteConversation';f.style.display='none';
  var i=document.createElement('input');i.type='hidden';i.name='contactId';i.value=selectedUserId;f.appendChild(i);
  document.body.appendChild(f);f.submit();
}
function deleteConversation(){showDeleteConvModal();}
function archiveConversation(){
  var f=document.createElement('form');f.method='POST';f.action='archiveConversation';f.style.display='none';
  var i=document.createElement('input');i.type='hidden';i.name='contactId';i.value=selectedUserId;f.appendChild(i);
  document.body.appendChild(f);f.submit();
}

/* Theme */
function showThemeModal(){document.getElementById('themeModal').classList.add('open');}
function selectTheme(theme) {
    var body = document.getElementById('body');
    var classes = body.className.split(' ');
    var newClasses = [];
    var themeClass = '';
    
    for (var i = 0; i < classes.length; i++) {
        var c = classes[i];
        if (!c.startsWith('theme-')) {
            newClasses.push(c);
        }
    }
    
    if (theme !== 'default') {
        themeClass = 'theme-' + theme;
        newClasses.push(themeClass);
    }
    
    body.className = newClasses.join(' ');
    
    var xhr = new XMLHttpRequest();
    xhr.open('POST', '<%= request.getContextPath() %>/saveTheme', true);
    xhr.setRequestHeader('Content-Type', 'application/x-www-form-urlencoded');
    xhr.send('contactId=' + selectedUserId + '&theme=' + theme);
    
    showToast('Thème "' + theme + '" appliqué');
    closeThemeModal();
}
function closeThemeModal(){document.getElementById('themeModal').classList.remove('open');}

/* User profile */
function openUserProfileModal(userId){
  fetch('getUserProfile?userId='+userId).then(function(r){return r.json();}).then(function(data){
    if(data.success){
      var av=document.getElementById('profileModalAvatar');
      av.innerHTML=data.profilePic&&data.profilePic!==''?'<img src="<%=request.getContextPath()%>/uploads/'+data.profilePic+'" style="width:100%;height:100%;border-radius:50%;object-fit:cover;">':data.initial;
      document.getElementById('profileModalName').textContent=data.displayName;
      document.getElementById('profileModalUsername').textContent='@'+data.username;
      document.getElementById('userProfileModal').classList.add('open');
    }
  }).catch(function(){});
}
function closeUserProfileModal(){document.getElementById('userProfileModal').classList.remove('open');}

/* Forward */
var fwdMsgId=null;
function showForwardModal(messageId,content){fwdMsgId=messageId;document.getElementById('forwardMessagePreview').textContent=content;document.getElementById('forwardModal').classList.add('open');}
function closeForwardModal(){document.getElementById('forwardModal').classList.remove('open');}
function submitForward(){
  var cid=document.getElementById('forwardContactSelect').value;
  if(!cid){showToast('Sélectionnez un contact','error');return;}
  var f=document.createElement('form');f.method='POST';f.action='forwardMessage';f.style.display='none';
  [['messageId',fwdMsgId],['receiverId',cid]].forEach(function(p){var i=document.createElement('input');i.type='hidden';i.name=p[0];i.value=p[1];f.appendChild(i);});
  document.body.appendChild(f);f.submit();
}

/* Delete menu toggle */
function toggleDeleteMenu(el) {
  var wrapper = el;
  while (wrapper && !wrapper.classList.contains('delete-menu-wrapper')) { wrapper = wrapper.parentElement; }
  if (!wrapper) return;
  var dm = wrapper.querySelector('.delete-menu');
  if (!dm) return;
  var isOpen = dm.style.display === 'block';
  document.querySelectorAll('.delete-menu').forEach(function(m){ m.style.display='none'; });
  if (!isOpen) { dm.style.display='block'; }
}
document.addEventListener('click',function(e){
  if (!e.target.closest || !e.target.closest('.delete-menu-wrapper')) {
    document.querySelectorAll('.delete-menu').forEach(function(m){ m.style.display='none'; });
  }
});

/* Profile menu */
function toggleMenu(){var m=document.getElementById('profileMenu');m.style.display=m.style.display==='none'?'block':'none';}
document.addEventListener('click',function(e){var pm=document.getElementById('profileMenu');var pp=document.querySelector('.profile-pic');if(pm&&pp&&!pp.contains(e.target)&&!pm.contains(e.target))pm.style.display='none';});

/* Modal overlay click */
document.querySelectorAll('.modal-overlay').forEach(function(o){o.addEventListener('click',function(e){if(e.target===o)o.classList.remove('open');});});

/* ESC */
document.addEventListener('keydown',function(e){if(e.key==='Escape'){cancelCall();closeHdrMenu();closeAllPickers();document.querySelectorAll('.modal-overlay.open').forEach(function(m){m.classList.remove('open');});}});

/* Edit form */
function showEditForm(id){document.querySelectorAll('[id^="editForm"]').forEach(function(f){f.style.display='none';});var ef=document.getElementById('editForm'+id);if(ef)ef.style.display='block';}
function hideEditForm(id){var ef=document.getElementById('editForm'+id);if(ef)ef.style.display='none';}
function downloadFile(filePath){var l=document.createElement('a');l.href='<%=request.getContextPath()%>/'+filePath;l.download=filePath.split('/').pop();document.body.appendChild(l);l.click();document.body.removeChild(l);}
function openImageModal(src){var ex=document.getElementById('imgModal');if(ex)ex.remove();var d=document.createElement('div');d.id='imgModal';d.style.cssText='position:fixed;inset:0;background:rgba(0,0,0,.88);backdrop-filter:blur(8px);z-index:9999;display:flex;align-items:center;justify-content:center;cursor:zoom-out;';d.onclick=function(){d.remove();};var img=document.createElement('img');img.src=src;img.style.cssText='max-width:90vw;max-height:88vh;border-radius:14px;box-shadow:0 20px 60px rgba(0,0,0,.5);';d.appendChild(img);document.body.appendChild(d);}
function openProfileModal(){showToast('Redirection vers les paramètres…');setTimeout(function(){window.location.href='<%=request.getContextPath()%>/immo/admin/settings.jsp';},1200);}

/* ── MODIFICATION 6 : Fonctions JavaScript pour publication partagée ── */
function useQuickReply(btn) {
    var msg = btn.textContent.trim();
    var input = document.getElementById('messageInput');
    if (input) { input.value = msg; input.focus(); }
    /* Mettre en avant le bouton sélectionné */
    document.querySelectorAll('.quick-reply-btn').forEach(function(b) {
        b.style.background = '';
        b.style.borderColor = '';
        b.style.color = '';
    });
    btn.style.background   = 'var(--bleu)';
    btn.style.borderColor  = 'var(--bleu)';
    btn.style.color        = '#fff';
}

/* ── Retirer la prévisualisation de publication ── */
function dismissPropertyPreview() {
    var preview = document.getElementById('propertySharePreview');
    if (preview) preview.style.display = 'none';
    /* Effacer les champs cachés pour ne pas envoyer la publication */
    ['propertyIdInput','propertyTitleInput','propertyPriceInput',
     'propertyImageInput','propertyTypeInput','propertyLocationInput'].forEach(function(id) {
        var el = document.getElementById(id);
        if (el) el.value = '';
    });
}

/* Initialisation au chargement de la page */
document.addEventListener('DOMContentLoaded', function() {
    console.log('🚀 Application chargée - Initialisation des fonctionnalités');
    
    // Scroll to bottom
    var mc = document.getElementById('messagesContainer');
    if(mc) mc.scrollTop = mc.scrollHeight;
    
    // GIF Trigger
    var gt=document.getElementById('gifTriggerBtn'), gp=document.getElementById('gifPickerPanel');
    if(gt&&gp){
      gt.addEventListener('click',function(e){e.stopPropagation();var o=gp.style.display==='block';closeAllPickers();if(!o){gp.style.display='block';loadTrendingGifs();}});
      gp.addEventListener('click',function(e){e.stopPropagation();});
      var sgb=document.getElementById('searchGifBtn');
      if(sgb) sgb.addEventListener('click',function(){var q=document.getElementById('gifSearchInput').value;if(q.trim())searchGifs(q);});
    }
    
    // Sticker Trigger
    var st=document.getElementById('stickerTriggerBtn'), sp=document.getElementById('stickerPickerPanel');
    if(st&&sp){
      st.addEventListener('click',function(e){e.stopPropagation();var o=sp.style.display==='block';closeAllPickers();if(!o){sp.style.display='block';loadStickers('love');}});
      sp.addEventListener('click',function(e){e.stopPropagation();});
    }
    document.querySelectorAll('.sticker-cat-pill').forEach(function(btn){
      btn.addEventListener('click',function(e){
        e.stopPropagation();
        document.querySelectorAll('.sticker-cat-pill').forEach(function(b){b.classList.remove('active');});
        this.classList.add('active'); loadStickers(this.getAttribute('data-cat'));
      });
    });
    
    // Voice Trigger
    var vt=document.getElementById('voiceTriggerBtn'), vp=document.getElementById('voiceRecorderPanel');
    if(vt&&vp){ vt.addEventListener('click',function(e){e.stopPropagation();var o=vp.style.display==='block';closeAllPickers();if(!o)vp.style.display='block';}); vp.addEventListener('click',function(e){e.stopPropagation();}); }
    
    // Search bar
    var si2=document.getElementById('searchIcon'), sb3=document.getElementById('searchBar');
    if(si2&&sb3) si2.addEventListener('click',function(){sb3.style.display=sb3.style.display==='none'?'block':'none';});
    var cs3=document.getElementById('closeSearch');
    if(cs3&&sb3) cs3.addEventListener('click',function(){sb3.style.display='none';});
    
    // Message input Enter
    var msgInput = document.getElementById('messageInput');
    if(msgInput) {
      msgInput.addEventListener('keydown', function(e) {
        if(e.key === 'Enter' && !e.shiftKey) {
          e.preventDefault();
          var form = document.getElementById('messageForm');
          if(form) form.submit();
        }
      });
    }
    
    // Initialisation de l'emoji picker
    var emojiBtn = document.getElementById('emojiTriggerBtn');
    var emojiPanel = document.getElementById('emojiPickerPanel');
    
    if (emojiBtn && emojiPanel) {
        emojiBtn.addEventListener('click', function(e) {
            e.preventDefault();
            e.stopPropagation();
            if (emojiPanel.style.display === 'block') {
                emojiPanel.style.display = 'none';
            } else {
                closeAllPickers();
                emojiPanel.style.display = 'block';
                renderEmojiGrid(currentEmojiCat);
                var rect = emojiBtn.getBoundingClientRect();
                emojiPanel.style.position = 'fixed';
                emojiPanel.style.bottom = (window.innerHeight - rect.top + 8) + 'px';
                emojiPanel.style.right = (window.innerWidth - rect.right + 5) + 'px';
                emojiPanel.style.left = 'auto';
                emojiPanel.style.width = '320px';
                emojiPanel.style.width = '320px';
                emojiPanel.style.background = 'var(--bg-sidebar, white)';
                emojiPanel.style.border = '2px solid var(--accent, #2560e0)';
                emojiPanel.style.borderRadius = '16px';
                emojiPanel.style.zIndex = '99999';
            }
        });
    }
    
    // Tabs émoji
    document.querySelectorAll('.emoji-tab').forEach(function(tab) {
        tab.addEventListener('click', function() {
            document.querySelectorAll('.emoji-tab').forEach(function(t) { t.classList.remove('active'); });
            this.classList.add('active');
            currentEmojiCat = this.getAttribute('data-cat');
            renderEmojiGrid(currentEmojiCat);
        });
    });
    
    // Recherche émoji
    var emojiSearch = document.getElementById('emojiSearchInput');
    if (emojiSearch) {
        emojiSearch.addEventListener('input', function() {
            renderEmojiGrid(currentEmojiCat, this.value);
        });
    }
});
</script>
</body>
</html>