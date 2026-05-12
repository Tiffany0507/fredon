<%@ page language="java" contentType="text/html; charset=UTF-8"
	pageEncoding="UTF-8" isELIgnored="true"%>
<%@ page import="java.util.List"%>
<%@ page import="com.immobilier.model.Property"%>
<%@ page import="com.immobilier.dao.PropertyDAO"%>
<%@ page import="java.sql.Connection"%>
<%@ page import="java.sql.DriverManager"%>
<%@ page import="java.sql.PreparedStatement"%>
<%@ page import="java.sql.ResultSet"%>
<%@ page import="com.quickchat.utils.PasswordUtil"%>

<%

response.setHeader("Cache-Control", "no-cache, no-store, must-revalidate");
response.setHeader("Pragma", "no-cache");
response.setHeader("Expires", "0");

    String DB_URL = "jdbc:mysql://localhost:3306/quickchat";
    String DB_USER = "root";
    String DB_PASSWORD = "";

    com.quickchat.model.User chatUser = (com.quickchat.model.User) session.getAttribute("user");
    
    // Vérifier si l'utilisateur est admin
    boolean isAdmin = chatUser != null && ("admin".equals(chatUser.getRole()) || "admin@fredon.mg".equals(chatUser.getEmail()));
    boolean isLoggedIn = chatUser != null;
    
    // Récupération du paramètre page pour la navigation
   String pageParam = request.getParameter("page");
if (pageParam == null || pageParam.isEmpty()) {
    if (chatUser != null && !isAdmin) {
        pageParam = "biens";
    } else {
        pageParam = "accueil";
    }
} 
    // Traitement de suppression de compte
    String deleteAccountMessage = null;
    String deleteAccountError = null;
    if ("POST".equalsIgnoreCase(request.getMethod()) && "deleteAccount".equals(request.getParameter("action"))) {
        String password = request.getParameter("password");
        if (password != null && chatUser != null) {
            try {
                Class.forName("com.mysql.cj.jdbc.Driver");
                Connection conn = DriverManager.getConnection(DB_URL, DB_USER, DB_PASSWORD);
                
                // Vérifier le mot de passe
                PreparedStatement checkStmt = conn.prepareStatement("SELECT password FROM users WHERE id = ?");
                checkStmt.setInt(1, chatUser.getId());
                ResultSet rs = checkStmt.executeQuery();
                
                if (rs.next()) {
                    String storedHash = rs.getString("password");
                    if (PasswordUtil.checkPassword(password, storedHash)) {
                        // Supprimer les favoris
                        PreparedStatement delFavs = conn.prepareStatement("DELETE FROM user_favorites WHERE user_id = ?");
                        delFavs.setInt(1, chatUser.getId());
                        delFavs.executeUpdate();
                        delFavs.close();
                        
                        // Supprimer l'utilisateur
                        PreparedStatement delUser = conn.prepareStatement("DELETE FROM users WHERE id = ?");
                        delUser.setInt(1, chatUser.getId());
                        delUser.executeUpdate();
                        delUser.close();
                        
                        session.invalidate();
                        response.sendRedirect(request.getContextPath() + "/immo/index.jsp?accountDeleted=true");
                        return;
                    } else {
                        deleteAccountError = "Mot de passe incorrect";
                    }
                }
                rs.close();
                checkStmt.close();
                conn.close();
            } catch (Exception e) {
                deleteAccountError = "Erreur: " + e.getMessage();
            }
        } else {
            deleteAccountError = "Veuillez entrer votre mot de passe";
        }
    }
    
    // Message de confirmation de suppression
    if (request.getParameter("accountDeleted") != null) {
        deleteAccountMessage = "Votre compte a été supprimé avec succès. Merci d'avoir utilisé Fredon Immobilier.";
    }

    int unreadNotifications = 0;
    if (chatUser != null && !isAdmin) {
        try {
            Connection conn = DriverManager.getConnection(DB_URL, DB_USER, DB_PASSWORD);
            PreparedStatement pstmt = conn.prepareStatement("SELECT COUNT(*) FROM notifications WHERE user_id = ? AND is_read = 0");
            pstmt.setInt(1, chatUser.getId());
            ResultSet rs = pstmt.executeQuery();
            if (rs.next()) unreadNotifications = rs.getInt(1);
            rs.close(); pstmt.close(); conn.close();
        } catch(Exception e) {}
    }

    String budgetStr    = request.getParameter("budget");
    String typeFilter   = request.getParameter("type");
    String applyFilter  = request.getParameter("applyFilter");
    String budgetMinStr = request.getParameter("budgetMin");
    String budgetMaxStr = request.getParameter("budgetMax");

    long budgetMax = 0;
    long budgetMin = 0;

    if (budgetMaxStr != null && !budgetMaxStr.trim().isEmpty() && applyFilter != null) {
        try { budgetMax = Long.parseLong(budgetMaxStr); } catch (NumberFormatException e) {}
    }
    if (budgetMinStr != null && !budgetMinStr.trim().isEmpty() && applyFilter != null) {
        try { budgetMin = Long.parseLong(budgetMinStr); } catch (NumberFormatException e) {}
    }
    if (budgetStr != null && !budgetStr.trim().isEmpty() && applyFilter != null) {
        try { budgetMax = Long.parseLong(budgetStr); } catch (NumberFormatException e) {}
    }

    if (typeFilter == null || applyFilter == null) typeFilter = "all";

    List<Property> properties = null;
    int totalProperties = 0;

    try {
        Class.forName("com.mysql.cj.jdbc.Driver");
        Connection conn = DriverManager.getConnection(DB_URL, DB_USER, DB_PASSWORD);
        PropertyDAO propertyDAO = new PropertyDAO(conn);
        if (applyFilter != null) {
            if (budgetMax > 0 && !typeFilter.equals("all"))       properties = propertyDAO.getPropertiesByBudgetAndType(budgetMax, typeFilter);
            else if (budgetMax > 0)                                properties = propertyDAO.getPropertiesByBudget(budgetMax);
            else if (!typeFilter.equals("all"))                    properties = propertyDAO.getPropertiesByType(typeFilter);
            else                                                   properties = propertyDAO.getAvailableProperties();
        } else {
            properties = propertyDAO.getAvailableProperties();
        }
        if (properties != null) totalProperties = properties.size();
        conn.close();
    } catch (Exception e) { e.printStackTrace(); }

    String userName    = chatUser != null ? (chatUser.getDisplayName() != null ? chatUser.getDisplayName() : chatUser.getUsername()) : null;
    String userInitial = userName != null ? userName.substring(0, 1).toUpperCase() : "";
    int unreadMessagesCount = 0;
    if (chatUser != null && !isAdmin) {
        try {
            com.quickchat.dao.MessageDAO messageDAO = new com.quickchat.dao.MessageDAO();
            unreadMessagesCount = messageDAO.countUnreadMessagesForUser(chatUser.getId());
        } catch (Exception e) {}
    }
%>

<!DOCTYPE html>
<html lang="fr">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Fredon — Agence Immobilière Madagascar</title>
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

@keyframes toastIn {
	from { opacity: 0; transform: translateX(60px) scale(.92); }
	to { opacity: 1; transform: translateX(0) scale(1); }
}
@keyframes toastOut {
	from { opacity: 1; transform: translateX(0); }
	to { opacity: 0; transform: translateX(60px); }
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
	gap: 12px;
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

@keyframes badgePulse { 0%,100% {
	box-shadow: 0 0 0 2px rgba(220, 38, 38, .35), 0 3px 12px
		rgba(220, 38, 38, .45);
}
50% {
	box-shadow: 0 0 0 5px rgba(220, 38, 38, .15), 0 3px 16px
		rgba(220, 38, 38, .6);
}
}

.favorites-tab {
	position: relative;
}

.fav-badge {
	position: absolute;
	top: -8px;
	right: -10px;
	background: var(--rouge);
	color: white;
	font-size: 9px;
	font-weight: 800;
	padding: 2px 6px;
	border-radius: 20px;
	min-width: 18px;
	text-align: center;
	border: 2px solid var(--bg);
	box-shadow: 0 2px 8px rgba(220, 38, 38, .3);
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

.btn-login {
	display: flex;
	align-items: center;
	gap: 7px;
	padding: 9px 20px;
	border-radius: 11px;
	background: linear-gradient(115deg, var(--blue2), var(--blue));
	color: #fff;
	font-size: 12.5px;
	font-weight: 700;
	text-decoration: none;
	border: none;
	cursor: pointer;
	box-shadow: 0 4px 18px rgba(31, 82, 212, .3);
	transition: transform .2s, box-shadow .2s;
	font-family: 'Syne', sans-serif;
}

.btn-login:hover {
	transform: translateY(-2px);
	box-shadow: 0 8px 28px rgba(31, 82, 212, .4);
}

.user-menu {
    position: relative;
}

.user-pill {
    display: flex;
    align-items: center;
    gap: 10px;
    padding: 6px 14px 6px 6px;
    border-radius: 40px;
    background: var(--surface);
    border: 1.5px solid var(--border);
    cursor: pointer;
    transition: all 0.3s cubic-bezier(0.2, 0.9, 0.4, 1.1);
    position: relative;
    z-index: 10;
}

.user-pill:hover {
    border-color: var(--blue);
    box-shadow: 0 4px 20px rgba(31, 82, 212, 0.15);
    transform: translateY(-2px);
}

.user-av {
    width: 34px;
    height: 34px;
    border-radius: 50%;
    background: linear-gradient(135deg, var(--blue2), var(--blue));
    display: flex;
    align-items: center;
    justify-content: center;
    font-family: 'Syne', sans-serif;
    font-size: 14px;
    font-weight: 800;
    color: #fff;
    box-shadow: 0 2px 8px rgba(31, 82, 212, 0.3);
    overflow: hidden;
}

.user-av img {
    width: 100%;
    height: 100%;
    object-fit: cover;
}

.user-name {
    font-size: 13px;
    font-weight: 600;
    color: var(--tx);
    letter-spacing: -0.2px;
}

.ch {
    font-size: 10px;
    color: var(--tx3);
    transition: transform 0.3s ease;
}

.user-pill:hover .ch {
    transform: rotate(180deg);
}

.dropdown {
    position: absolute;
    top: calc(100% + 12px);
    right: 0;
    min-width: 260px;
    background: var(--surface);
    border-radius: 20px;
    box-shadow: 0 20px 40px rgba(0, 0, 0, 0.12), 0 8px 16px rgba(0, 0, 0, 0.06);
    opacity: 0;
    visibility: hidden;
    transform: translateY(-10px);
    transition: all 0.3s cubic-bezier(0.2, 0.9, 0.4, 1.1);
    z-index: 1000;
    overflow: hidden;
}

.user-menu:hover .dropdown,
.dropdown:hover {
    opacity: 1;
    visibility: visible;
    transform: translateY(0);
}

.dropdown::before {
    content: '';
    position: absolute;
    top: -8px;
    right: 20px;
    width: 16px;
    height: 16px;
    background: var(--surface);
    transform: rotate(45deg);
    border-left: 1px solid var(--border);
    border-top: 1px solid var(--border);
    z-index: -1;
}

.dropdown-header {
    padding: 16px 18px;
    background: linear-gradient(135deg, var(--blue2), var(--blue));
    color: white;
    display: flex;
    align-items: center;
    gap: 12px;
}

.dropdown-avatar {
    width: 44px;
    height: 44px;
    border-radius: 50%;
    background: rgba(255, 255, 255, 0.2);
    display: flex;
    align-items: center;
    justify-content: center;
    font-size: 18px;
    font-weight: 800;
    font-family: 'Syne', sans-serif;
}

.dropdown-info h4 {
    font-size: 14px;
    font-weight: 700;
    margin-bottom: 2px;
}

.dropdown-info p {
    font-size: 11px;
    opacity: 0.8;
}

.dropdown-divider {
    height: 1px;
    background: linear-gradient(90deg, transparent, var(--border), transparent);
    margin: 6px 0;
}

.dropdown-item {
    display: flex;
    align-items: center;
    gap: 12px;
    padding: 12px 18px;
    color: var(--tx2);
    font-size: 13px;
    font-weight: 500;
    text-decoration: none;
    transition: all 0.2s ease;
    cursor: pointer;
}

.dropdown-item i {
    width: 20px;
    font-size: 14px;
    color: var(--blue);
    transition: all 0.2s ease;
}

.dropdown-item span {
    flex: 1;
}

.dropdown-badge {
    background: linear-gradient(135deg, #ef4444, #dc2626);
    color: white;
    font-size: 9px;
    font-weight: 800;
    width: 18px;
    height: 18px;
    border-radius: 50%;
    display: inline-flex;
    align-items: center;
    justify-content: center;
    margin-left: 8px;
    flex-shrink: 0;
    box-shadow: 0 1px 3px rgba(0,0,0,0.2);
}

.dropdown-item:hover {
    background: var(--bl);
    padding-left: 22px;
}

.dropdown-item:hover i {
    transform: translateX(3px);
    color: var(--blue);
}

.dropdown-item.danger {
    color: var(--rouge);
}

.dropdown-item.danger i {
    color: var(--rouge);
}

.dropdown-item.danger:hover {
    background: rgba(220, 38, 38, 0.08);
}

.dropdown-footer {
    padding: 12px 18px;
    border-top: 1px solid var(--border);
    background: var(--s2);
    font-size: 11px;
    color: var(--tx3);
    text-align: center;
}

.hero {
	position: relative;
	overflow: hidden;
	min-height: 560px;
	display: flex;
	flex-direction: column;
	align-items: center;
	justify-content: center;
	padding: 80px 32px 90px;
	background: linear-gradient(165deg, #0a1d58 0%, #1a3aaa 35%, #0e2d82 65%, #071545
		100%);
}

.hero::before {
	content: '';
	position: absolute;
	inset: 0;
	background-image: linear-gradient(rgba(255, 255, 255, .04) 1px,
		transparent 1px), linear-gradient(90deg, rgba(255, 255, 255, .04) 1px,
		transparent 1px);
	background-size: 44px 44px;
	pointer-events: none;
}

.hero-glow-a {
	position: absolute;
	width: 600px;
	height: 600px;
	border-radius: 50%;
	background: radial-gradient(circle, rgba(232, 168, 32, .18) 0%,
		transparent 70%);
	top: -120px;
	right: -80px;
	pointer-events: none;
	animation: glowFloat 8s ease-in-out infinite;
}

.hero-glow-b {
	position: absolute;
	width: 500px;
	height: 500px;
	border-radius: 50%;
	background: radial-gradient(circle, rgba(79, 126, 248, .2) 0%,
		transparent 70%);
	bottom: -100px;
	left: -60px;
	pointer-events: none;
	animation: glowFloat 10s ease-in-out infinite reverse;
}

@keyframes glowFloat { 0%,100%{ transform: translate(0, 0); } 50%{ transform: translate(20px, -30px); } }

#heroCanvas {
	position: absolute;
	inset: 0;
	z-index: 1;
	pointer-events: none;
}

.hero-content {
	position: relative;
	z-index: 3;
	text-align: center;
	max-width: 820px;
}

.hero-eyebrow {
	display: inline-flex;
	align-items: center;
	gap: 8px;
	background: rgba(255, 255, 255, .1);
	border: 1px solid rgba(255, 255, 255, .2);
	backdrop-filter: blur(12px);
	border-radius: 99px;
	padding: 6px 16px;
	font-size: 11px;
	font-weight: 700;
	letter-spacing: 2px;
	text-transform: uppercase;
	color: rgba(255, 255, 255, .75);
	margin-bottom: 28px;
	animation: fadeUp .7s .1s both;
}

.hero-eyebrow span {
	color: var(--gold2);
}

.hero-title {
	font-family: 'Syne', sans-serif;
	font-weight: 800;
	font-size: clamp(36px, 6vw, 68px);
	line-height: 1.05;
	margin-bottom: 22px;
	color: #fff;
	animation: fadeUp .7s .2s both;
}

.hero-title em {
	font-style: normal;
	background: linear-gradient(120deg, var(--gold2), #fff 50%, var(--gold2));
	background-size: 200%;
	-webkit-background-clip: text;
	background-clip: text;
	color: transparent;
	animation: shimmer 4s ease-in-out infinite;
}

@keyframes shimmer { 0%,100%{ background-position: 0% center; } 50%{ background-position: 100% center; } }

.hero-sub {
	font-size: clamp(15px, 2vw, 18px);
	color: rgba(255, 255, 255, .68);
	line-height: 1.7;
	max-width: 580px;
	margin: 0 auto 42px;
	font-weight: 400;
	animation: fadeUp .7s .3s both;
}

.hero-stats {
	display: flex;
	gap: 0;
	justify-content: center;
	background: rgba(255, 255, 255, .07);
	border: 1px solid rgba(255, 255, 255, .14);
	backdrop-filter: blur(20px);
	border-radius: 20px;
	overflow: hidden;
	animation: fadeUp .7s .4s both;
	flex-wrap: wrap;
}

.hstat {
	padding: 22px 40px;
	text-align: center;
	border-right: 1px solid rgba(255, 255, 255, .1);
	flex: 1;
	min-width: 130px;
}

.hstat:last-child {
	border-right: none;
}

.hstat-val {
	font-family: 'Syne', sans-serif;
	font-size: 28px;
	font-weight: 800;
	color: #fff;
	display: block;
	margin-bottom: 4px;
}

.hstat-val em {
	font-style: normal;
	color: var(--gold2);
}

.hstat-lbl {
	font-size: 11px;
	color: rgba(255, 255, 255, .55);
	letter-spacing: .5px;
}

.hero-scroll {
	position: absolute;
	bottom: 28px;
	left: 50%;
	transform: translateX(-50%);
	z-index: 3;
	display: flex;
	flex-direction: column;
	align-items: center;
	gap: 6px;
	animation: fadeUp .7s .6s both;
}

.hero-scroll span {
	font-size: 10px;
	color: rgba(255, 255, 255, .4);
	letter-spacing: 2px;
	text-transform: uppercase;
}

.scroll-line {
	width: 1px;
	height: 38px;
	background: linear-gradient(to bottom, rgba(255, 255, 255, .4),
		transparent);
	animation: scrollPulse 1.8s ease-in-out infinite;
}

@keyframes scrollPulse { 0%,100%{ transform: scaleY(1); opacity: .5; } 50%{ transform: scaleY(1.2); opacity: 1; } }
@keyframes fadeUp { from { opacity: 0; transform: translateY(20px); } to { opacity: 1; transform: translateY(0); } }

.catalog-outer {
	max-width: 1400px;
	margin: 0 auto;
	padding: 48px 36px 80px;
	display: grid;
	grid-template-columns: 300px 1fr;
	gap: 28px;
	align-items: start;
}

.filter-sidebar {
	background: var(--surface);
	border: 1.5px solid var(--border);
	border-radius: 24px;
	overflow: hidden;
	position: sticky;
	top: 84px;
	box-shadow: 0 6px 32px rgba(0, 0, 0, .06);
}

.fsb-head {
	padding: 22px 24px;
	background: linear-gradient(135deg, var(--blue2), var(--blue));
	display: flex;
	align-items: center;
	justify-content: space-between;
}

.fsb-head h3 {
	font-family: 'Syne', sans-serif;
	font-weight: 700;
	font-size: 15px;
	color: #fff;
	display: flex;
	align-items: center;
	gap: 9px;
}

.fsb-head h3 i {
	font-size: 14px;
	color: var(--gold2);
}

.fsb-reset {
	font-size: 11px;
	font-weight: 700;
	color: rgba(255, 255, 255, .6);
	text-decoration: none;
	display: flex;
	align-items: center;
	gap: 5px;
	transition: color .2s;
	cursor: pointer;
	background: none;
	border: none;
}

.fsb-reset:hover {
	color: #fff;
}

.fsb-body {
	padding: 24px;
	display: flex;
	flex-direction: column;
	gap: 26px;
}

.fblock label {
	display: block;
	font-size: 9.5px;
	font-weight: 800;
	letter-spacing: 1.8px;
	text-transform: uppercase;
	color: var(--tx3);
	margin-bottom: 14px;
}

.type-pills {
	display: flex;
	flex-direction: column;
	gap: 8px;
}

.type-pill {
	display: flex;
	align-items: center;
	gap: 12px;
	padding: 12px 14px;
	border-radius: 13px;
	border: 1.5px solid var(--border);
	cursor: pointer;
	font-weight: 600;
	font-size: 13.5px;
	color: var(--tx2);
	text-decoration: none;
	transition: all .22s;
	position: relative;
	overflow: hidden;
}

.type-pill::after {
	content: '';
	position: absolute;
	inset: 0;
	background: linear-gradient(135deg, transparent, rgba(255, 255, 255, .3));
	opacity: 0;
	transition: opacity .2s;
}

.type-pill:hover {
	border-color: var(--blue);
	color: var(--blue);
	background: var(--bl);
}

.type-pill:hover::after {
	opacity: 1;
}

.type-pill.active {
	border-color: var(--blue);
	background: var(--bl);
	color: var(--blue);
	box-shadow: 0 4px 16px rgba(31, 82, 212, .12);
}

.type-pill.active .pill-check {
	opacity: 1;
	transform: scale(1);
}

.pill-ico {
	width: 36px;
	height: 36px;
	border-radius: 10px;
	flex-shrink: 0;
	display: flex;
	align-items: center;
	justify-content: center;
	font-size: 15px;
	background: var(--s2);
	transition: all .22s;
}

.type-pill.active .pill-ico {
	background: rgba(31, 82, 212, .15);
	color: var(--blue);
}

.pill-check {
	margin-left: auto;
	color: var(--blue);
	font-size: 12px;
	opacity: 0;
	transform: scale(.5);
	transition: all .22s;
}

.budget-display {
	display: flex;
	justify-content: space-between;
	margin-bottom: 16px;
}

.bd-block {
	display: flex;
	flex-direction: column;
	gap: 3px;
}

.bd-label {
	font-size: 9.5px;
	font-weight: 700;
	color: var(--tx3);
	letter-spacing: 1px;
	text-transform: uppercase;
}

.bd-val {
	font-family: 'Syne', sans-serif;
	font-weight: 800;
	font-size: 15px;
	color: var(--blue);
}

.range-track {
	position: relative;
	height: 6px;
	background: var(--s3);
	border-radius: 6px;
	margin-bottom: 10px;
}

.range-fill {
	position: absolute;
	height: 100%;
	background: linear-gradient(90deg, var(--blue2), var(--blue3));
	border-radius: 6px;
	pointer-events: none;
}

input[type="range"] {
	position: absolute;
	width: 100%;
	top: 50%;
	transform: translateY(-50%);
	height: 6px;
	-webkit-appearance: none;
	background: transparent;
	outline: none;
	pointer-events: all;
}

input[type="range"]::-webkit-slider-thumb {
	-webkit-appearance: none;
	width: 20px;
	height: 20px;
	border-radius: 50%;
	background: var(--blue);
	cursor: pointer;
	border: 3px solid #fff;
	box-shadow: 0 2px 10px rgba(31, 82, 212, .35);
	transition: transform .2s, box-shadow .2s;
}

input[type="range"]::-webkit-slider-thumb:hover {
	transform: scale(1.2);
	box-shadow: 0 4px 18px rgba(31, 82, 212, .5);
}

.range-labels {
	display: flex;
	justify-content: space-between;
	font-size: 10px;
	color: var(--tx3);
	margin-top: 6px;
}

.btn-apply-filter {
	width: 100%;
	padding: 14px;
	border-radius: 14px;
	border: none;
	background: linear-gradient(115deg, var(--blue2), var(--blue3));
	color: #fff;
	font-family: 'Syne', sans-serif;
	font-weight: 700;
	font-size: 14px;
	cursor: pointer;
	transition: all .25s;
	display: flex;
	align-items: center;
	justify-content: center;
	gap: 9px;
	box-shadow: 0 6px 22px rgba(31, 82, 212, .28);
	position: relative;
	overflow: hidden;
}

.btn-apply-filter::before {
	content: '';
	position: absolute;
	inset: 0;
	background: linear-gradient(135deg, rgba(255, 255, 255, .15),
		transparent);
	opacity: 0;
	transition: opacity .2s;
}

.btn-apply-filter:hover {
	transform: translateY(-2px);
	box-shadow: 0 10px 30px rgba(31, 82, 212, .4);
}

.btn-apply-filter:hover::before {
	opacity: 1;
}

.btn-apply-filter:active {
	transform: translateY(0);
}

.btn-clear-filter {
	width: 100%;
	padding: 12px;
	border-radius: 14px;
	background: transparent;
	border: 1.5px solid var(--border);
	color: var(--tx2);
	font-weight: 600;
	font-size: 13px;
	cursor: pointer;
	transition: all .22s;
	display: flex;
	align-items: center;
	justify-content: center;
	gap: 8px;
}

.btn-clear-filter:hover {
	border-color: var(--rose);
	color: var(--rose);
	background: rgba(224, 48, 96, .05);
}

.active-filters {
	display: flex;
	flex-wrap: wrap;
	gap: 6px;
}

.af-pill {
	display: flex;
	align-items: center;
	gap: 6px;
	padding: 5px 11px;
	border-radius: 20px;
	font-size: 11px;
	font-weight: 700;
	background: var(--bl);
	border: 1px solid rgba(31, 82, 212, .2);
	color: var(--blue);
}

.af-pill i {
	font-size: 9px;
}

.catalog-content {
	
}

.toolbar {
	display: flex;
	align-items: center;
	justify-content: space-between;
	margin-bottom: 24px;
	flex-wrap: wrap;
	gap: 14px;
}

.results-pill {
	background: var(--surface);
	border: 1.5px solid var(--border);
	border-radius: 99px;
	padding: 7px 18px;
	font-size: 12.5px;
	font-weight: 700;
	display: flex;
	align-items: center;
	gap: 8px;
}

.results-pill .cnt {
	color: var(--blue);
	font-size: 16px;
}

.props-grid {
	display: grid;
	grid-template-columns: repeat(auto-fill, minmax(310px, 1fr));
	gap: 22px;
	transition: opacity .3s;
}

.props-grid.loading {
	opacity: .45;
	pointer-events: none;
}

.prop-card {
	background: var(--surface);
	border: 1.5px solid var(--border);
	border-radius: 22px;
	overflow: hidden;
	transition: all .28s;
	position: relative;
	animation: cardIn .5s both;
}

@keyframes cardIn { from { opacity: 0; transform: translateY(18px); } to { opacity: 1; transform: translateY(0); } }

.prop-card:nth-child(1) { animation-delay: .05s; }
.prop-card:nth-child(2) { animation-delay: .1s; }
.prop-card:nth-child(3) { animation-delay: .15s; }
.prop-card:nth-child(4) { animation-delay: .2s; }
.prop-card:nth-child(5) { animation-delay: .25s; }
.prop-card:nth-child(6) { animation-delay: .3s; }

.prop-card:hover {
	transform: translateY(-7px);
	border-color: rgba(31, 82, 212, .2);
	box-shadow: 0 20px 60px rgba(14, 45, 130, .12);
}

.card-img {
	position: relative;
	height: 215px;
	overflow: hidden;
	background: var(--s2);
}

.card-img img {
	width: 100%;
	height: 100%;
	object-fit: cover;
	transition: transform .55s ease;
	display: block;
}

.prop-card:hover .card-img img {
	transform: scale(1.08);
}

.card-overlay {
	position: absolute;
	inset: 0;
	background: linear-gradient(to top, rgba(5, 12, 28, .72) 0%,
		rgba(5, 12, 28, .1) 55%, transparent 100%);
}

.card-badge {
	position: absolute;
	top: 13px;
	left: 13px;
	padding: 5px 13px;
	border-radius: 99px;
	font-size: 9.5px;
	font-weight: 800;
	letter-spacing: 1.5px;
	text-transform: uppercase;
	backdrop-filter: blur(12px);
}

.badge-vente {
	background: rgba(5, 150, 105, .88);
	color: #fff;
}

.badge-location {
	background: rgba(31, 82, 212, .88);
	color: #fff;
}

.card-fav {
	position: absolute;
	top: 12px;
	right: 12px;
	width: 33px;
	height: 33px;
	border-radius: 9px;
	background: rgba(255, 255, 255, .18);
	backdrop-filter: blur(10px);
	border: 1px solid rgba(255, 255, 255, .25);
	display: flex;
	align-items: center;
	justify-content: center;
	cursor: pointer;
	color: rgba(255, 255, 255, .8);
	font-size: 13px;
	transition: all .2s;
	border: none;
}

.card-fav:hover {
	background: rgba(224, 48, 96, .7);
	color: #fff;
	transform: scale(1.1);
}

.card-fav.active {
	background: rgba(224, 48, 96, .85);
	color: #fff;
}

.card-price-area {
	position: absolute;
	bottom: 14px;
	left: 15px;
	right: 15px;
	display: flex;
	align-items: flex-end;
	justify-content: space-between;
}

.card-price {
	font-family: 'Syne', sans-serif;
	font-size: 22px;
	font-weight: 800;
	color: #fff;
	text-shadow: 0 2px 12px rgba(0, 0, 0, .4);
	line-height: 1;
}

.card-price-cur {
	color: var(--gold2);
	font-size: 14px;
	vertical-align: super;
}

.card-price-sub {
	font-size: 10px;
	color: rgba(255, 255, 255, .6);
	margin-top: 2px;
}

.card-views {
	display: flex;
	align-items: center;
	gap: 4px;
	font-size: 10.5px;
	color: rgba(255, 255, 255, .6);
	background: rgba(0, 0, 0, .3);
	backdrop-filter: blur(8px);
	padding: 4px 8px;
	border-radius: 7px;
}

.card-views i {
	font-size: 9px;
}

.card-body {
	padding: 16px 18px 20px;
}

.card-title {
	font-family: 'Syne', sans-serif;
	font-weight: 700;
	font-size: 15px;
	color: var(--tx);
	margin-bottom: 6px;
	line-height: 1.3;
}

.card-loc {
	display: flex;
	align-items: center;
	gap: 5px;
	font-size: 12px;
	color: var(--tx3);
	margin-bottom: 14px;
}

.card-loc i {
	color: var(--rose);
	font-size: 10px;
}

.card-rule {
	height: 1px;
	margin-bottom: 14px;
	background: linear-gradient(90deg, rgba(31, 82, 212, .12),
		rgba(184, 144, 14, .12), transparent);
}

.card-feats {
	display: flex;
	gap: 6px;
	flex-wrap: wrap;
	margin-bottom: 15px;
}

.feat {
	display: flex;
	align-items: center;
	gap: 5px;
	padding: 5px 11px;
	border-radius: 8px;
	background: var(--s2);
	border: 1px solid var(--border);
	font-size: 11px;
	font-weight: 500;
	color: var(--tx2);
}

.feat i {
	font-size: 9px;
	color: var(--blue);
}

.card-actions {
	display: flex;
	gap: 8px;
}

.btn-see {
	flex: 1;
	display: flex;
	align-items: center;
	justify-content: center;
	gap: 7px;
	padding: 11px;
	border-radius: 12px;
	background: linear-gradient(115deg, var(--blue2), var(--blue3));
	color: #fff;
	font-size: 12.5px;
	font-weight: 700;
	text-decoration: none;
	transition: all .22s;
	border: none;
	cursor: pointer;
	font-family: 'Syne', sans-serif;
}

.btn-see:hover {
	transform: translateY(-1px);
	box-shadow: 0 6px 22px rgba(31, 82, 212, .35);
}

.btn-contact {
	width: 42px;
	flex-shrink: 0;
	border-radius: 12px;
	background: var(--gl);
	border: 1.5px solid rgba(184, 144, 14, .22);
	color: var(--gold);
	display: flex;
	align-items: center;
	justify-content: center;
	text-decoration: none;
	font-size: 14px;
	transition: all .22s;
}

.btn-contact:hover {
	background: var(--gold);
	color: #fff;
	transform: scale(1.05);
}

.empty-state {
	text-align: center;
	padding: 80px 20px;
	grid-column: 1/-1;
}

.empty-state svg {
	width: 80px;
	height: 80px;
	opacity: .2;
	margin-bottom: 20px;
}

.empty-state h3 {
	font-family: 'Syne', sans-serif;
	font-size: 20px;
	font-weight: 700;
	color: var(--tx2);
	margin-bottom: 8px;
}

.empty-state p {
	font-size: 13.5px;
	color: var(--tx3);
}

.view-header {
	display: flex;
	align-items: center;
	justify-content: space-between;
	margin-bottom: 24px;
	padding-bottom: 16px;
	border-bottom: 2px solid var(--border);
	flex-wrap: wrap;
	gap: 12px;
}

.view-title {
	font-family: 'Syne', sans-serif;
	font-size: 20px;
	font-weight: 700;
	display: flex;
	align-items: center;
	gap: 10px;
}

.view-title i {
	color: var(--rouge);
	font-size: 22px;
}

.btn-clear-favs {
	background: transparent;
	border: 1.5px solid var(--border);
	border-radius: 40px;
	padding: 8px 18px;
	font-size: 12px;
	font-weight: 600;
	color: var(--tx2);
	cursor: pointer;
	transition: all 0.2s;
	display: flex;
	align-items: center;
	gap: 8px;
}

.btn-clear-favs:hover {
	border-color: var(--rouge);
	color: var(--rouge);
	background: rgba(220, 38, 38, 0.05);
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

@media (max-width:1000px) {
	.catalog-outer { grid-template-columns: 1fr; }
	.filter-sidebar { position: static; }
	.nav { display: none; }
	.hero-title { font-size: 36px; }
	.hstat { padding: 16px 20px; }
}

@media (max-width:640px) {
	.props-grid { grid-template-columns: 1fr; }
	.footer-inner { grid-template-columns: 1fr; gap: 32px; }
	.hero-stats { flex-direction: column; }
	.catalog-outer { padding: 28px 18px 60px; }
	.header-inner { padding: 0 18px; }
}

.section-page {
	display: none;
}

.section-page.active-page {
	display: block;
}

.modal-overlay {
	position: fixed;
	top: 0;
	left: 0;
	width: 100%;
	height: 100%;
	background: rgba(0, 0, 0, 0.75);
	backdrop-filter: blur(12px);
	z-index: 9999;
	display: none;
	align-items: center;
	justify-content: center;
}

.modal-overlay.open {
	display: flex;
}

.modal-container {
	background: var(--surface);
	border-radius: 32px;
	width: 90%;
	max-width: 520px;
	box-shadow: 0 25px 50px rgba(0, 0, 0, 0.3);
	animation: modalIn 0.35s cubic-bezier(0.34, 1.2, 0.64, 1);
}

@keyframes modalIn { from { opacity: 0; transform: scale(0.96) translateY(-10px); } to { opacity: 1; transform: scale(1) translateY(0); } }

.modal-header {
	padding: 24px 28px;
	background: linear-gradient(135deg, var(--blue2), var(--blue));
	color: white;
	display: flex;
	justify-content: space-between;
	align-items: center;
	border-radius: 32px 32px 0 0;
}

.modal-header h3 {
	font-family: 'Syne', sans-serif;
	font-weight: 700;
	font-size: 20px;
	display: flex;
	align-items: center;
	gap: 10px;
}

.modal-close {
	background: rgba(255, 255, 255, 0.2);
	border: none;
	width: 34px;
	height: 34px;
	border-radius: 50%;
	cursor: pointer;
	color: white;
	font-size: 18px;
	transition: background 0.2s;
}

.modal-close:hover {
	background: rgba(255, 255, 255, 0.35);
}

.modal-body {
	padding: 24px 28px;
	max-height: 70vh;
	overflow-y: auto;
}

.setting-group {
	margin-bottom: 28px;
}

.setting-group:last-child {
	margin-bottom: 0;
}

.setting-label {
	font-size: 12px;
	font-weight: 800;
	text-transform: uppercase;
	letter-spacing: 1.5px;
	color: var(--tx3);
	margin-bottom: 14px;
	display: flex;
	align-items: center;
	gap: 10px;
}

.setting-label i {
	font-size: 14px;
	color: var(--blue);
}

.lang-buttons {
	display: flex;
	gap: 12px;
	flex-wrap: wrap;
}

.lang-btn {
	flex: 1;
	padding: 12px;
	border: 2px solid var(--border);
	background: var(--surface);
	border-radius: 14px;
	cursor: pointer;
	font-weight: 600;
	display: flex;
	align-items: center;
	justify-content: center;
	gap: 8px;
	transition: all 0.2s;
}

.lang-btn:hover {
	border-color: var(--blue);
	background: var(--bl);
}

.lang-btn.active {
	border-color: var(--blue);
	background: var(--bl);
	color: var(--blue);
}

.setting-divider {
	height: 1px;
	background: linear-gradient(90deg, transparent, var(--border), transparent);
	margin: 20px 0;
}

.switch {
	position: relative;
	display: inline-block;
	width: 50px;
	height: 26px;
}

.switch input {
	opacity: 0;
	width: 0;
	height: 0;
}

.slider-switch {
	position: absolute;
	cursor: pointer;
	top: 0;
	left: 0;
	right: 0;
	bottom: 0;
	background-color: var(--bg2);
	transition: 0.3s;
	border-radius: 34px;
	border: 1.5px solid var(--border);
}

.slider-switch:before {
	position: absolute;
	content: "";
	height: 20px;
	width: 20px;
	left: 3px;
	bottom: 2px;
	background-color: var(--tx3);
	transition: 0.3s;
	border-radius: 50%;
}

input:checked + .slider-switch {
	background: linear-gradient(135deg, var(--blue2), var(--blue));
}

input:checked + .slider-switch:before {
	transform: translateX(22px);
	background-color: white;
}

.setting-checkbox {
	display: flex;
	align-items: center;
	justify-content: space-between;
	padding: 8px 0;
}

.setting-checkbox span {
	font-size: 13px;
	color: var(--tx2);
}

.font-size-buttons {
	display: flex;
	gap: 10px;
}

.font-size-btn {
	flex: 1;
	padding: 10px;
	border: 2px solid var(--border);
	background: var(--surface);
	border-radius: 12px;
	cursor: pointer;
	font-weight: 600;
	font-size: 13px;
	transition: all 0.2s;
}

.font-size-btn.active {
	border-color: var(--blue);
	background: var(--bl);
	color: var(--blue);
}

.danger-zone {
	background: rgba(220, 38, 38, 0.05);
	border: 1.5px solid rgba(220, 38, 38, 0.2);
	border-radius: 20px;
	padding: 16px 20px;
	margin-top: 10px;
}

.danger-zone .setting-label {
	color: var(--rouge);
}

.danger-zone .setting-label i {
	color: var(--rouge);
}

.delete-account-btn {
	width: 100%;
	padding: 12px;
	background: transparent;
	border: 1.5px solid var(--rouge);
	border-radius: 12px;
	color: var(--rouge);
	font-weight: 700;
	cursor: pointer;
	transition: all 0.2s;
	display: flex;
	align-items: center;
	justify-content: center;
	gap: 10px;
}

.delete-account-btn:hover {
	background: var(--rouge);
	color: white;
}

.modal-footer {
	padding: 20px 28px;
	border-top: 1px solid var(--border);
	display: flex;
	gap: 12px;
	justify-content: flex-end;
}

.btn-save {
	padding: 12px 28px;
	background: linear-gradient(135deg, var(--blue2), var(--blue));
	color: white;
	border: none;
	border-radius: 14px;
	font-weight: 700;
	cursor: pointer;
	transition: transform 0.2s, box-shadow 0.2s;
}

.btn-save:hover {
	transform: translateY(-2px);
	box-shadow: 0 8px 20px rgba(31, 82, 212, 0.35);
}

.btn-cancel {
	padding: 12px 28px;
	background: transparent;
	border: 1.5px solid var(--border);
	border-radius: 14px;
	cursor: pointer;
	transition: all 0.2s;
}

.btn-cancel:hover {
	border-color: var(--blue);
	color: var(--blue);
}

body.font-small { font-size: 13px; }
body.font-normal { font-size: 15px; }
body.font-large { font-size: 17px; }
body.font-small .card-title { font-size: 14px; }
body.font-normal .card-title { font-size: 16px; }
body.font-large .card-title { font-size: 18px; }
</style>

</head>
<body id="body">

	<div class="toast-container" id="toastContainer"></div>

	<header class="header" id="header">
		<div class="header-inner">
			<a href="<%= request.getContextPath() %>/?page=accueil" class="logo" style="gap: 12px;">
				<img src="<%= request.getContextPath() %>/immo/admin/images/Logo.jpg"
				     alt="Fredon"
				     style="width: 44px; height: 44px; object-fit: cover; border-radius: 12px; box-shadow: 0 4px 12px rgba(0,0,0,.15);">
				<div>
					<div class="logo-name" style="font-size: 20px;">Fredon</div>
					<div class="logo-sub">Agence Immobilière</div>
				</div>
			</a>
			<nav class="nav">
				<a href="<%= request.getContextPath() %>/?page=accueil" class="nav-link <%= "accueil".equals(pageParam) ? "active" : "" %>"><i class="fas fa-home"></i> Accueil</a> 
				<a href="<%= request.getContextPath() %>/?page=biens" class="nav-link <%= "biens".equals(pageParam) ? "active" : "" %>"><i class="fas fa-building"></i> Nos biens</a>
				<a href="<%= request.getContextPath() %>/?page=historique" class="nav-link <%= "historique".equals(pageParam) ? "active" : "" %>"><i class="fas fa-landmark"></i> Historique</a>
				<% if (isLoggedIn && !isAdmin) { %>
<a href="<%= request.getContextPath() %>/?page=favoris" class="nav-link favorites-tab <%= "favoris".equals(pageParam) ? "active" : "" %>"><i class="fas fa-heart"></i> Favoris <span id="favCount" class="fav-badge">0</span></a>
				<% } %>
				<% if (isLoggedIn && !isAdmin) { %>
				<a href="<%= request.getContextPath() %>/notifications" class="msg-link"><i class="fas fa-bell"></i> Notifications 
					<% if (unreadNotifications > 0) { %>
					<span class="msg-badge-dot"><%= unreadNotifications > 9 ? "9+" : unreadNotifications %></span>
					<% } %>
				</a> 
				<a href="<%= request.getContextPath() %>/chat" class="msg-link"><i class="fas fa-comments"></i> Messages 
					<% if (unreadMessagesCount > 0) { %>
					<span class="msg-badge-dot"><%= unreadMessagesCount > 9 ? "9+" : unreadMessagesCount %></span>
					<% } %>
				</a>
				<% } %>
			</nav>
			<div class="hright">
				<div class="toggle-btn" id="toggleTheme" onclick="switchTheme()">
					<div class="toggle-thumb" id="tThumb">☀️</div>
				</div>
				<% if (chatUser == null) { %>
				<a href="<%= request.getContextPath() %>/login" class="btn-login"><i class="fas fa-sign-in-alt"></i> Connexion</a>
				<% } else { %>
				<div class="user-menu">
					<div class="user-pill">
						<div class="user-av">
							<% if (chatUser != null && chatUser.getProfilePic() != null && !chatUser.getProfilePic().isEmpty()) { %>
							<img src="<%= request.getContextPath() %>/uploads/<%= chatUser.getProfilePic() %>" style="width: 100%; height: 100%; border-radius: 50%; object-fit: cover;">
							<% } else { %>
							<%= userInitial %>
							<% } %>
						</div>
						<span class="user-name"><%= userName %></span> 
						<i class="fas fa-chevron-down ch"></i>
					</div>
					<div class="dropdown">
						<div class="dropdown-header">
							<div class="dropdown-avatar">
								<% if (chatUser != null && chatUser.getProfilePic() != null && !chatUser.getProfilePic().isEmpty()) { %>
								<img src="<%= request.getContextPath() %>/uploads/<%= chatUser.getProfilePic() %>" style="width: 100%; height: 100%; border-radius: 50%; object-fit: cover;">
								<% } else { %>
								<%= userInitial %>
								<% } %>
							</div>
							<div class="dropdown-info">
								<h4><%= userName %></h4>
								<p><%= chatUser != null ? chatUser.getEmail() : "" %></p>
							</div>
						</div>
						<div class="dropdown-divider"></div>
						<% if (!isAdmin) { %>
						<a href="<%= request.getContextPath() %>/notifications" class="dropdown-item"><i class="fas fa-bell"></i><span>Mes notifications</span>
							<% if (unreadNotifications > 0) { %>
							<span class="dropdown-badge"><%= unreadNotifications > 9 ? "9+" : unreadNotifications %></span>
							<% } %>
						</a>
			<a href="<%= request.getContextPath() %>/chat" class="dropdown-item"><i class="fas fa-comments"></i><span>Mes messages</span>
							<% if (unreadMessagesCount > 0) { %>
							<span class="dropdown-badge"><%= unreadMessagesCount > 9 ? "9+" : unreadMessagesCount %></span>
							<% } %>
						</a>
						<div class="dropdown-divider"></div>
						<% } %>
						<a href="<%= request.getContextPath() %>/profile.jsp" class="dropdown-item"><i class="fas fa-user-circle"></i><span>Mon profil</span></a>
						<a href="#" onclick="openSettingsModal(); return false;" class="dropdown-item"><i class="fas fa-sliders-h"></i><span>Paramètres</span></a>
						<div class="dropdown-divider"></div>
						<a href="<%= request.getContextPath() %>/logout" class="dropdown-item danger"><i class="fas fa-sign-out-alt"></i><span>Déconnexion</span></a>
						<div class="dropdown-footer"><i class="fas fa-shield-alt"></i> Compte sécurisé</div>
					</div>
				</div>
				<% } %>
			</div>
		</div>
	</header>

	<div id="page-accueil" class="section-page <%= "accueil".equals(pageParam) ? "active-page" : "" %>">
		<section class="hero" id="hero">
			<div class="hero-glow-a"></div>
			<div class="hero-glow-b"></div>
			<canvas id="heroCanvas"></canvas>
			<div class="hero-content">
				<div class="hero-eyebrow">
					<i class="fas fa-map-marker-alt" style="color: var(--gold2)"></i> <span>Madagascar — <span>Votre partenaire immobilier de confiance</span></span>
				</div>
				<h1 class="hero-title">Votre prochain chez‑vous<br>commence <em>ici</em></h1>
				<p class="hero-sub">Vente, location, investissement — découvrez une sélection soigneuse de propriétés d'exception à Mahajanga, Antananarivo, Toamasina et dans toute l'île.</p>
				<div class="hero-stats">
					<div class="hstat"><span class="hstat-val">De <em>nombreux</em></span><span class="hstat-lbl">Biens vendus avec succès</span></div>
					<div class="hstat"><span class="hstat-val"><em>Toute</em> l'île</span><span class="hstat-lbl">Régions couvertes</span></div>
					<div class="hstat"><span class="hstat-val">Toujours <em>là</em></span><span class="hstat-lbl">Pour vous accompagner</span></div>
					<div class="hstat"><span class="hstat-val"><em>Chaque</em> jour</span><span class="hstat-lbl">De nouveaux biens disponibles</span></div>
				</div>
			</div>
			<div class="hero-scroll"><span>Explorer</span><div class="scroll-line"></div><i class="fas fa-chevron-down" style="color: rgba(255, 255, 255, .35); font-size: 11px;"></i></div>
		</section>
	</div>

	<div id="page-biens" class="section-page <%= "biens".equals(pageParam) ? "active-page" : "" %>">
		<div class="catalog-outer" id="catalog">
			<aside class="filter-sidebar">
				<div class="fsb-head">
					<h3><i class="fas fa-sliders-h"></i> Filtres de recherche</h3>
					<button class="fsb-reset" onclick="resetFilters()"><i class="fas fa-undo-alt"></i> Réinitialiser</button>
				</div>
				<form id="filterForm" method="get" action="<%= request.getContextPath() %>/" class="fsb-body">
				
					<div class="fblock">
						<label>Type de transaction</label>
						<div class="type-pills">
							<a class="type-pill <%= typeFilter.equals("all") ? "active" : "" %>" data-type="all" href="#"><div class="pill-ico"><i class="fas fa-th-large"></i></div><span>Tous les biens</span><i class="fas fa-check pill-check"></i></a>
							<a class="type-pill <%= typeFilter.equals("Vente") ? "active" : "" %>" data-type="Vente" href="#"><div class="pill-ico"><i class="fas fa-key"></i></div><span>Vente</span><i class="fas fa-check pill-check"></i></a>
							<a class="type-pill <%= typeFilter.equals("Location") ? "active" : "" %>" data-type="Location" href="#"><div class="pill-ico"><i class="fas fa-home"></i></div><span>Location</span><i class="fas fa-check pill-check"></i></a>
						</div>
					</div>
					<div class="fblock">
						<label>Budget</label>
						<div class="budget-display">
							<div class="bd-block"><span class="bd-label">Minimum</span><span class="bd-val" id="bdMinVal">0 Ar</span></div>
							<div class="bd-block" style="text-align: right"><span class="bd-label">Maximum</span><span class="bd-val" id="bdMaxVal">Tous</span></div>
						</div>
						<div class="range-track">
							<div class="range-fill" id="rangeFill"></div>
							<input type="range" name="budgetMin" id="sliderMin" min="0" max="500000000" step="5000000" value="<%= budgetMin > 0 ? budgetMin : 0 %>">
							<input type="range" name="budgetMax" id="sliderMax" min="0" max="500000000" step="5000000" value="<%= budgetMax > 0 ? budgetMax : 500000000 %>">
						</div>
						<div class="range-labels"><span>0</span><span>125M</span><span>250M</span><span>375M</span><span>500M</span></div>
					</div>
					<div class="fblock" id="activeFiltersBlock" style="display: none;">
						<label>Filtres actifs</label>
						<div class="active-filters" id="activeFiltersList"></div>
					</div>
					<input type="hidden" name="type" id="typeInput" value="<%= typeFilter %>">
					<input type="hidden" name="page" value="biens">
					<button type="button" class="btn-apply-filter" onclick="applyFilters()"><i class="fas fa-search"></i> Rechercher</button>
					<button type="button" class="btn-clear-filter" onclick="resetFilters()"><i class="fas fa-times"></i> Tout effacer</button>
				</form>
			</aside>
			<div class="catalog-content">
				<div class="toolbar">
					<div style="display: flex; align-items: center; gap: 10px; flex-wrap: wrap;">
						<div class="results-pill"><span class="cnt" id="resultCount"><%= totalProperties %></span><span id="resultLabel">bien<%= totalProperties > 1 ? "s" : "" %> disponible<%= totalProperties > 1 ? "s" : "" %></span></div>
					</div>
				</div>
				<div class="props-grid" id="propsGrid">
					<% if (properties == null || properties.isEmpty()) { %>
					<div class="empty-state"><i class="fas fa-home" style="font-size: 52px; opacity: .2; color: var(--blue); display: block; margin-bottom: 16px;"></i><h3>Aucun bien trouvé</h3><p>Modifiez vos filtres ou revenez plus tard.</p></div>
					<% } else { %>
					<% for (Property property : properties) {
						com.immobilier.model.PropertyImage pImg = null;
						try {
							Connection c2 = DriverManager.getConnection(DB_URL, DB_USER, DB_PASSWORD);
							com.immobilier.dao.PropertyImageDAO imgDAO = new com.immobilier.dao.PropertyImageDAO(c2);
							pImg = imgDAO.getPrimaryImageByPropertyId(property.getId());
							c2.close();
						} catch(Exception ex){}
						String imgUrl = pImg != null ? request.getContextPath() + "/" + pImg.getImageUrl() : "https://images.unsplash.com/photo-1564013799919-ab600027ffc6?w=600&q=80";
						String typeClass = property.getType() != null && property.getType().equals("Location") ? "location" : "vente";
						
						// Encodage pour le chat
						String _encTitle = java.net.URLEncoder.encode(property.getTitle() != null ? property.getTitle() : "", "UTF-8");
						String _encLoc   = java.net.URLEncoder.encode(property.getLocation() != null ? property.getLocation() : "", "UTF-8");
						String _encType  = java.net.URLEncoder.encode(property.getType() != null ? property.getType() : "", "UTF-8");
						String _encImg   = (pImg != null && pImg.getImageUrl() != null)
						                   ? java.net.URLEncoder.encode(pImg.getImageUrl(), "UTF-8") : "";
						long   _price    = property.getPrice() != null ? property.getPrice().longValue() : 0;
					%>
					<div class="prop-card" data-prop-id="<%= property.getId() %>">
						<div class="card-img">
							<img src="<%= imgUrl %>" alt="<%= property.getTitle() %>" loading="lazy">
							<div class="card-overlay"></div>
							<span class="card-badge badge-<%= typeClass %>"><%= property.getType() %></span>
							<% if (isLoggedIn && !isAdmin) { %>
							<button class="card-fav" onclick="toggleFav(this, '<%= property.getId() %>', '<%= property.getTitle().replace("'","\\'" ) %>')"><i class="fas fa-heart"></i></button>
							<% } %>
							<div class="card-price-area">
								<div><div class="card-price"><%= String.format("%,.0f", property.getPrice()) %><span class="card-price-cur"> Ar</span></div>
								<% if ("Location".equals(property.getType())) { %><div class="card-price-sub">par mois</div><% } %></div>
								<div class="card-views"><i class="fas fa-eye"></i> <span></span></div>
							</div>
						</div>
						<div class="card-body">
							<h3 class="card-title"><%= property.getTitle() %></h3>
							<div class="card-loc"><i class="fas fa-map-marker-alt"></i> <%= property.getLocation() %></div>
							<div class="card-rule"></div>
							<div class="card-feats">
    <% if ("Terrain".equals(property.getType())) { 
        String landArea = property.getLandArea();
        String landType = property.getLandType();
    %>
        <% if (landArea != null && !landArea.isEmpty()) { %>
        <span class="feat"><i class="fas fa-vector-square"></i> <%= landArea %></span>
        <% } %>
        <% if (landType != null && !landType.isEmpty()) { %>
        <span class="feat"><i class="fas fa-tree"></i> <%= landType %></span>
        <% } %>
    <% } else { %>
        <% if (property.getSurface() != null && property.getSurface() > 0) { %><span class="feat"><i class="fas fa-ruler-combined"></i> <%= property.getSurface() %> m²</span><% } %>
        <% if (property.getRooms() != null && property.getRooms() > 0) { %><span class="feat"><i class="fas fa-door-open"></i> <%= property.getRooms() %> pièces</span><% } %>
        <% if (property.getBedrooms() != null && property.getBedrooms() > 0) { %><span class="feat"><i class="fas fa-bed"></i> <%= property.getBedrooms() %> ch.</span><% } %>
    <% } %>
</div>
							<div class="card-actions">
								<a href="<%= request.getContextPath() %>/immo/property-detail.jsp?id=<%= property.getId() %>" class="btn-see"><i class="fas fa-eye"></i> Voir le bien</a>
								<a href="javascript:void(0)"
								   onclick="contactAboutProperty('<%= property.getId() %>','<%= _encTitle %>','<%= _price %>','<%= _encImg %>','<%= _encType %>','<%= _encLoc %>')"
								   class="btn-contact" title="Contacter l'agent">
								  <i class="fas fa-comments"></i>
								</a>
							</div>
						</div>
					</div>
					<% } %>
					<% } %>
				</div>
			</div>
		</div>
	</div>
	<div id="page-historique" class="section-page <%= "historique".equals(pageParam) ? "active-page" : "" %>">
	<div style="max-width:1100px;margin:0 auto;padding:60px 36px 80px;">

		<!-- EN-TÊTE -->
		<div style="text-align:center;margin-bottom:60px;">
			<div style="display:inline-flex;align-items:center;gap:8px;background:var(--bl);border:1px solid rgba(31,82,212,.2);border-radius:99px;padding:6px 18px;font-size:11px;font-weight:700;letter-spacing:2px;text-transform:uppercase;color:var(--blue);margin-bottom:20px;">
				<i class="fas fa-landmark"></i> Depuis notre création
			</div>
			<h2 id="hist-nom" style="font-family:'Syne',sans-serif;font-size:clamp(28px,5vw,48px);font-weight:800;color:var(--tx);margin-bottom:14px;">Fredon Immobilier</h2>
			<p id="hist-desc" style="font-size:16px;color:var(--tx2);line-height:1.8;max-width:680px;margin:0 auto;">Votre partenaire de confiance pour l'immobilier à Madagascar.</p>
		</div>

		<!-- CARTES INFOS -->
		<div style="display:grid;grid-template-columns:repeat(auto-fit,minmax(220px,1fr));gap:20px;margin-bottom:60px;">
			<div style="background:var(--surface);border:1.5px solid var(--border);border-radius:22px;padding:28px 24px;text-align:center;transition:transform .25s,box-shadow .25s;" onmouseover="this.style.transform='translateY(-6px)';this.style.boxShadow='0 16px 40px rgba(31,82,212,.1)'" onmouseout="this.style.transform='';this.style.boxShadow=''">
				<div style="width:52px;height:52px;border-radius:14px;background:var(--bl);display:flex;align-items:center;justify-content:center;margin:0 auto 16px;font-size:22px;color:var(--blue);"><i class="fas fa-calendar-alt"></i></div>
				<div style="font-size:10px;font-weight:800;letter-spacing:2px;text-transform:uppercase;color:var(--tx3);margin-bottom:8px;">Année de création</div>
				<div id="hist-annee" style="font-family:'Syne',sans-serif;font-size:28px;font-weight:800;color:var(--blue);">—</div>
			</div>
			<div style="background:var(--surface);border:1.5px solid var(--border);border-radius:22px;padding:28px 24px;text-align:center;transition:transform .25s,box-shadow .25s;" onmouseover="this.style.transform='translateY(-6px)';this.style.boxShadow='0 16px 40px rgba(31,82,212,.1)'" onmouseout="this.style.transform='';this.style.boxShadow=''">
				<div style="width:52px;height:52px;border-radius:14px;background:var(--gl);display:flex;align-items:center;justify-content:center;margin:0 auto 16px;font-size:22px;color:var(--gold);"><i class="fas fa-map-marker-alt"></i></div>
				<div style="font-size:10px;font-weight:800;letter-spacing:2px;text-transform:uppercase;color:var(--tx3);margin-bottom:8px;">Siège social</div>
				<div id="hist-siege" style="font-family:'Syne',sans-serif;font-size:17px;font-weight:700;color:var(--tx);">—</div>
			</div>
			<div style="background:var(--surface);border:1.5px solid var(--border);border-radius:22px;padding:28px 24px;text-align:center;transition:transform .25s,box-shadow .25s;" onmouseover="this.style.transform='translateY(-6px)';this.style.boxShadow='0 16px 40px rgba(31,82,212,.1)'" onmouseout="this.style.transform='';this.style.boxShadow=''">
				<div style="width:52px;height:52px;border-radius:14px;background:rgba(5,150,105,.1);display:flex;align-items:center;justify-content:center;margin:0 auto 16px;font-size:22px;color:var(--emerald);"><i class="fas fa-phone-alt"></i></div>
				<div style="font-size:10px;font-weight:800;letter-spacing:2px;text-transform:uppercase;color:var(--tx3);margin-bottom:8px;">Téléphone</div>
				<div id="hist-tel" style="font-family:'Syne',sans-serif;font-size:17px;font-weight:700;color:var(--tx);">—</div>
			</div>
			<div style="background:var(--surface);border:1.5px solid var(--border);border-radius:22px;padding:28px 24px;text-align:center;transition:transform .25s,box-shadow .25s;" onmouseover="this.style.transform='translateY(-6px)';this.style.boxShadow='0 16px 40px rgba(31,82,212,.1)'" onmouseout="this.style.transform='';this.style.boxShadow=''">
				<div style="width:52px;height:52px;border-radius:14px;background:rgba(224,48,96,.08);display:flex;align-items:center;justify-content:center;margin:0 auto 16px;font-size:22px;color:var(--rose);"><i class="fas fa-envelope"></i></div>
				<div style="font-size:10px;font-weight:800;letter-spacing:2px;text-transform:uppercase;color:var(--tx3);margin-bottom:8px;">Email</div>
				<div id="hist-email" style="font-family:'Syne',sans-serif;font-size:15px;font-weight:700;color:var(--tx);">—</div>
			</div>
		</div>

		<!-- TIMELINE -->
		<div style="margin-bottom:60px;">
			<h3 style="font-family:'Syne',sans-serif;font-size:22px;font-weight:800;color:var(--tx);margin-bottom:32px;display:flex;align-items:center;gap:10px;"><i class="fas fa-history" style="color:var(--blue);"></i> Notre parcours</h3>
			<div id="hist-timeline" style="position:relative;padding-left:32px;border-left:3px solid var(--border);">
				<div style="text-align:center;padding:40px;color:var(--tx3);"><i class="fas fa-spinner fa-spin" style="font-size:24px;margin-bottom:12px;display:block;"></i>Chargement...</div>
			</div>
		</div>

		<!-- SERVICES -->
		<div>
			<h3 style="font-family:'Syne',sans-serif;font-size:22px;font-weight:800;color:var(--tx);margin-bottom:32px;display:flex;align-items:center;gap:10px;"><i class="fas fa-concierge-bell" style="color:var(--gold);"></i> Nos services</h3>
			<div id="hist-services" style="display:grid;grid-template-columns:repeat(auto-fit,minmax(200px,1fr));gap:16px;">
				<div style="text-align:center;padding:40px;color:var(--tx3);grid-column:1/-1;"><i class="fas fa-spinner fa-spin" style="font-size:24px;margin-bottom:12px;display:block;"></i>Chargement...</div>
			</div>
		</div>

	</div>
</div>

	<% if (isLoggedIn && !isAdmin) { %>
	<div id="page-favoris" class="section-page <%= "favoris".equals(pageParam) ? "active-page" : "" %>">
		<div class="catalog-outer">
			<div class="catalog-content" style="grid-column: 1/-1;">
				<div class="view-header">
					<div class="view-title"><i class="fas fa-heart" style="color: var(--rouge);"></i> Mes favoris <span id="favCountSection" style="font-size: 14px; color: var(--tx3);">(0)</span></div>
					<button class="btn-clear-favs" onclick="clearAllFavorites()"><i class="fas fa-trash-alt"></i> Tout supprimer</button>
				</div>
				<div class="props-grid" id="favorisGrid">
					<div class="empty-state"><i class="fas fa-heart" style="font-size: 64px; opacity: .2; margin-bottom: 20px; display: block;"></i><h3>Aucun favori</h3><p>Cliquez sur le cœur ❤️ d'un bien pour l'ajouter à vos favoris.</p></div>
				</div>
			</div>
		</div>
	</div>
	<% } %>

	<footer>
		<div class="footer-inner">
			<div>
				<div style="display: flex; align-items: center; gap: 11px; margin-bottom: 14px;">
					<img src="<%= request.getContextPath() %>/immo/admin/images/Logo.jpg" alt="Fredon" style="width: 36px; height: 36px; object-fit: cover; border-radius: 8px;">
					<div>
						<div class="footer-brand-name">Fredon</div>
						<div class="footer-brand-tag">Agence Immobilière Madagascar</div>
					</div>
				</div>
				<p class="footer-desc">Votre partenaire de confiance pour vendre, louer ou investir dans l'immobilier à Madagascar. Des professionnels à votre écoute, chaque jour.</p>
			</div>
			<div class="footer-col">
				<h4>Navigation</h4>
				<ul>
					<li><a href="<%= request.getContextPath() %>/?page=accueil"><i class="fas fa-home"></i> Accueil</a></li>
					<li><a href="<%= request.getContextPath() %>/?page=biens"><i class="fas fa-building"></i> Nos biens</a></li>
					<li><a href="<%= request.getContextPath() %>/?page=historique"><i class="fas fa-landmark"></i> Historique</a></li>
					<% if (isLoggedIn && !isAdmin) { %>
					<li><a href="<%= request.getContextPath() %>/?page=favoris"><i class="fas fa-heart"></i> Mes favoris</a></li>
					<% } %>
					<% if (chatUser == null) { %>
					<li><a href="<%= request.getContextPath() %>/login.jsp"><i class="fas fa-sign-in-alt"></i> Connexion</a></li>
					<% } else if (!isAdmin) { %>
					<li><a href="<%= request.getContextPath() %>/chat"><i class="fas fa-comments"></i> Messages</a></li>
					<% } %>
				</ul>
			</div>
			<div class="footer-col">
				<h4>Contact</h4>
				<ul>
					<li><a href="mailto:contact@fredon.mg"><i class="fas fa-envelope"></i> contact@fredon.mg</a></li>
					<li><a href="#"><i class="fas fa-map-marker-alt"></i> Mahajanga, Madagascar</a></li>
				</ul>
			</div>
		</div>
		<div class="footer-bottom">
			<p>© 2026 Fredon Immobilier — Madagascar</p>
			<p>Fait avec <i class="fas fa-heart heart"></i> à Madagascar</p>
		</div>
	</footer>

	<div id="settingsModal" class="modal-overlay">
		<div class="modal-container">
			<div class="modal-header">
				<h3><i class="fas fa-sliders-h"></i> Paramètres</h3>
				<button class="modal-close" onclick="closeSettingsModal()">✕</button>
			</div>
			<div class="modal-body">
				<div class="setting-group">
					<div class="setting-label"><i class="fas fa-language"></i> Langue / Language</div>
					<div class="lang-buttons">
						<button class="lang-btn" data-lang="fr" onclick="document.querySelectorAll('.lang-btn').forEach(b=>b.classList.remove('active')); this.classList.add('active');"><span>🇫🇷</span> Français</button>
						<button class="lang-btn" data-lang="mg" onclick="document.querySelectorAll('.lang-btn').forEach(b=>b.classList.remove('active')); this.classList.add('active');"><span>🇲🇬</span> Malagasy</button>
						<button class="lang-btn" data-lang="en" onclick="document.querySelectorAll('.lang-btn').forEach(b=>b.classList.remove('active')); this.classList.add('active');"><span>🇬🇧</span> English</button>
					</div>
				</div>
				<div class="setting-divider"></div>
				<div class="setting-group">
					<div class="setting-label"><i class="fas fa-palette"></i> Apparence</div>
					<label class="setting-checkbox"><span><i class="fas fa-moon"></i> Mode sombre automatique (selon l'heure)</span><label class="switch"><input type="checkbox" id="autoDarkMode"><span class="slider-switch"></span></label></label>
				</div>
				<div class="setting-divider"></div>
				<div class="setting-group">
					<div class="setting-label"><i class="fas fa-font"></i> Taille du texte</div>
					<div class="font-size-buttons">
						<button class="font-size-btn" data-size="small" onclick="setFontSize('small')">Petite</button>
						<button class="font-size-btn" data-size="normal" onclick="setFontSize('normal')">Normale</button>
						<button class="font-size-btn" data-size="large" onclick="setFontSize('large')">Grande</button>
					</div>
				</div>
				<div class="setting-divider"></div>
				<div class="danger-zone">
					<div class="setting-label"><i class="fas fa-exclamation-triangle"></i> Zone dangereuse</div>
					<button class="delete-account-btn" onclick="showDeleteAccountModal()"><i class="fas fa-trash-alt"></i> Supprimer mon compte</button>
					<p style="font-size: 11px; color: var(--tx3); margin-top: 12px; text-align: center;">⚠️ Cette action est irréversible. Toutes vos données seront supprimées.</p>
				</div>
			</div>
			<div class="modal-footer">
				<button class="btn-cancel" onclick="closeSettingsModal()">Annuler</button>
				<button class="btn-save" onclick="saveSettings()">Enregistrer</button>
			</div>
		</div>
	</div>

	<div id="deleteAccountModal" class="modal-overlay">
		<div class="modal-container" style="max-width: 450px;">
			<div class="modal-header" style="background: linear-gradient(135deg, var(--rouge), #991b1b);">
				<h3><i class="fas fa-exclamation-triangle"></i> Supprimer mon compte</h3>
				<button class="modal-close" onclick="closeDeleteAccountModal()">✕</button>
			</div>
			<form method="POST" action="<%= request.getContextPath() %>/deleteAccount" id="deleteAccountForm">
				<input type="hidden" name="action" value="deleteAccount">
				<div class="modal-body">
					<p style="margin-bottom: 20px; color: var(--tx2);">⚠️ <strong>Attention :</strong> Cette action est <strong>irréversible</strong>. Tous vos favoris, messages et données personnelles seront définitivement supprimés.</p>
					<div class="form-group" style="margin-bottom: 0;">
						<label style="display: block; margin-bottom: 8px; font-weight: 600;">Confirmez avec votre mot de passe</label>
						<input type="password" name="password" id="deletePassword" class="form-control" placeholder="Votre mot de passe" required style="width: 100%; padding: 12px; border: 1.5px solid var(--border); border-radius: 12px; background: var(--bg);">
					</div>
					<% if (deleteAccountError != null) { %>
					<div style="margin-top: 15px; padding: 10px; background: rgba(220,38,38,0.1); border-radius: 10px; color: var(--rouge); font-size: 13px;"><i class="fas fa-times-circle"></i> <%= deleteAccountError %></div>
					<% } %>
				</div>
				<div class="modal-footer">
					<button type="button" class="btn-cancel" onclick="closeDeleteAccountModal()">Annuler</button>
					<button type="submit" class="btn-save" style="background: linear-gradient(135deg, var(--rouge), #991b1b);">Confirmer la suppression</button>
				</div>
			</form>
		</div>
	</div>

	<script>
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

	const hdr = document.getElementById('header');
	window.addEventListener('scroll', () => hdr.classList.toggle('scrolled', scrollY > 10), { passive: true });

	(function() {
		const canvas = document.getElementById('heroCanvas');
		if(!canvas) return;
		const ctx = canvas.getContext('2d');
		const hero = document.getElementById('hero');
		let W, H, items = [];
		function resize() {
			const r = hero.getBoundingClientRect();
			W = canvas.width = r.width;
			H = canvas.height = r.height;
		}
		const PALETTE = [{r:232,g:168,b:32},{r:79,g:126,b:248},{r:14,g:158,b:138},{r:224,g:48,b:96},{r:255,g:255,b:255},{r:255,g:210,b:100}];
		function drawStyledHouse(ctx, x, y, sc, alpha, col) {
			ctx.save(); ctx.globalAlpha = alpha; ctx.translate(x, y); ctx.scale(sc, sc);
			const c = `rgba(${col.r},${col.g},${col.b},1)`;
			const cf = `rgba(${col.r},${col.g},${col.b},0.3)`;
			ctx.strokeStyle = c; ctx.fillStyle = cf; ctx.lineWidth = 1.5 / sc;
			ctx.shadowColor = c; ctx.shadowBlur = 8 / sc;
			ctx.beginPath(); ctx.rect(-20, -12, 40, 28); ctx.fill(); ctx.stroke();
			ctx.beginPath(); ctx.moveTo(-24, -12); ctx.lineTo(0, -32); ctx.lineTo(24, -12); ctx.closePath(); ctx.fill(); ctx.stroke();
			ctx.beginPath(); ctx.arc(0, 10, 7, Math.PI, 0); ctx.lineTo(7, 16); ctx.lineTo(-7, 16); ctx.closePath();
			ctx.fillStyle = `rgba(${col.r},${col.g},${col.b},0.55)`; ctx.fill(); ctx.stroke();
			ctx.fillStyle = cf;
			ctx.beginPath(); ctx.rect(-17, -8, 10, 9); ctx.fill(); ctx.stroke();
			ctx.beginPath(); ctx.moveTo(-12, -8); ctx.lineTo(-12, 1); ctx.moveTo(-17, -3.5); ctx.lineTo(-7, -3.5); ctx.stroke();
			ctx.beginPath(); ctx.rect(7, -8, 10, 9); ctx.fill(); ctx.stroke();
			ctx.beginPath(); ctx.moveTo(12, -8); ctx.lineTo(12, 1); ctx.moveTo(7, -3.5); ctx.lineTo(17, -3.5); ctx.stroke();
			ctx.fillStyle = `rgba(${col.r},${col.g},${col.b},0.6)`;
			ctx.fillRect(10, -38, 6, 12); ctx.strokeRect(10, -38, 6, 12);
			for (let i = 0; i < 3; i++) {
				const fy = -38 - i * 8 - (Date.now() / 3000 * 10 % 8);
				const fr = 2.5 + i * 1.5;
				const fa = (0.4 - i * 0.12);
				ctx.globalAlpha = alpha * fa;
				ctx.beginPath(); ctx.arc(13 + i * 2, fy, fr, 0, Math.PI * 2); ctx.fill();
			}
			ctx.globalAlpha = alpha;
			if (sc > 0.55) {
				ctx.fillStyle = `rgba(34,197,94,${alpha * 0.8})`;
				ctx.beginPath(); ctx.arc(-32, -4, 10, 0, Math.PI * 2); ctx.fill();
				ctx.fillStyle = `rgba(120,80,20,${alpha * 0.6})`;
				ctx.fillRect(-33.5, 6, 3, 10);
			}
			ctx.restore();
		}
		function init() {
			resize(); items = [];
			for (let i = 0; i < 22; i++) {
				const col = PALETTE[Math.floor(Math.random() * PALETTE.length)];
				items.push({ x: Math.random() * W, y: Math.random() * H, sc: 0.4 + Math.random() * 1.1, alpha: 0.06 + Math.random() * 0.1, col, vx: (Math.random() - 0.5) * 0.15, vy: (Math.random() - 0.5) * 0.10, phase: Math.random() * Math.PI * 2 });
			}
		}
		let raf;
		function animate(t) {
			ctx.clearRect(0, 0, W, H);
			items.forEach((h) => {
				h.x += h.vx; h.y += h.vy + Math.sin(t * 0.0005 + h.phase) * 0.05;
				if (h.x < -80) h.x = W + 60; if (h.x > W+80) h.x = -60;
				if (h.y < -100) h.y = H + 80; if (h.y > H+80) h.y = -80;
				drawStyledHouse(ctx, h.x, h.y, h.sc, h.alpha, h.col);
			});
			raf = requestAnimationFrame(animate);
		}
		init();
		window.addEventListener('resize', () => { cancelAnimationFrame(raf); init(); animate(0); });
		animate(0);
	})();

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

	const slMin = document.getElementById('sliderMin');
	const slMax = document.getElementById('sliderMax');
	const bdMinV = document.getElementById('bdMinVal');
	const bdMaxV = document.getElementById('bdMaxVal');
	const fill = document.getElementById('rangeFill');
	const MAX_B = 500000000;

	function fmtBudget(v) {
		if (v <= 0) return '0 Ar';
		if (v >= MAX_B) return 'Illimité';
		if (v >= 1000000) return (v / 1000000).toFixed(0) + 'M Ar';
		return new Intl.NumberFormat('fr-FR').format(v) + ' Ar';
	}

	function updateSliders() {
		let mn = parseInt(slMin.value), mx = parseInt(slMax.value);
		if (mn > mx) { const tmp = mn; mn = mx; mx = tmp; slMin.value = mn; slMax.value = mx; }
		bdMinV.textContent = fmtBudget(mn);
		bdMaxV.textContent = fmtBudget(mx);
		const pct1 = (mn / MAX_B) * 100;
		const pct2 = (mx / MAX_B) * 100;
		fill.style.left = pct1 + '%';
		fill.style.width = (pct2 - pct1) + '%';
	}
	if(slMin && slMax) { slMin.addEventListener('input', updateSliders); slMax.addEventListener('input', updateSliders); updateSliders(); }

	document.querySelectorAll('.type-pill').forEach(pill => {
		pill.addEventListener('click', function(e) {
			e.preventDefault();
			document.querySelectorAll('.type-pill').forEach(p => p.classList.remove('active'));
			this.classList.add('active');
			document.getElementById('typeInput').value = this.dataset.type;
		});
	});

	function updateActiveFilters() {
		const type = document.getElementById('typeInput').value;
		const minVal = parseInt(slMin ? slMin.value : 0);
		const maxVal = parseInt(slMax ? slMax.value : MAX_B);
		const block = document.getElementById('activeFiltersBlock');
		const list = document.getElementById('activeFiltersList');
		let pills = '';
		if (type && type !== 'all') pills += `<div class="af-pill"><i class="fas fa-tag"></i>${type}</div>`;
		if (minVal > 0) pills += `<div class="af-pill"><i class="fas fa-arrow-up"></i>Min : ${fmtBudget(minVal)}</div>`;
		if (maxVal < MAX_B) pills += `<div class="af-pill"><i class="fas fa-arrow-down"></i>Max : ${fmtBudget(maxVal)}</div>`;
		if (pills) { if(list) list.innerHTML = pills; if(block) block.style.display = 'block'; }
		else { if(block) block.style.display = 'none'; }
	}

	function applyFilters() {
		const type = document.getElementById('typeInput').value;
		const minVal = parseInt(slMin ? slMin.value : 0);
		const maxVal = parseInt(slMax ? slMax.value : MAX_B);
		const grid = document.getElementById('propsGrid');
		const rcnt = document.getElementById('resultCount');
		const rlbl = document.getElementById('resultLabel');
		updateActiveFilters();
		if(grid) grid.classList.add('loading');
		let url = '<%= request.getContextPath() %>/immo/ajax-properties.jsp?';
		if (minVal > 0) url += 'budgetMin=' + minVal + '&';
		if (maxVal < MAX_B) url += 'budgetMax=' + maxVal + '&';
		if (type !== 'all') url += 'type=' + encodeURIComponent(type);
		fetch(url).then(r => r.json()).then(data => {
			if(grid) grid.classList.remove('loading');
			const n = data.count || (data.properties ? data.properties.length : 0);
			if(rcnt) rcnt.textContent = n;
			if(rlbl) rlbl.textContent = `bien${n > 1 ? 's' : ''} disponible${n > 1 ? 's' : ''}`;
			if (data.properties && data.properties.length > 0) {
				let html = '';
				data.properties.forEach((prop, idx) => {
					const imgUrl = prop.imageUrl ? '<%= request.getContextPath() %>/' + prop.imageUrl : 'https://images.unsplash.com/photo-1564013799919-ab600027ffc6?w=600&q=80';
					const tc = prop.type === 'Location' ? 'location' : 'vente';
					const priceF = new Intl.NumberFormat('fr-FR').format(prop.price);
					html += `<div class="prop-card" data-prop-id="${prop.id}"><div class="card-img"><img src="${imgUrl}" alt="${escHtml(prop.title)}" loading="lazy"><div class="card-overlay"></div><span class="card-badge badge-${tc}">${escHtml(prop.type)}</span>`;
					<% if (isLoggedIn && !isAdmin) { %>
					html += `<button class="card-fav" onclick="toggleFav(this,'${prop.id}','${escHtml(prop.title)}')"><i class="fas fa-heart"></i></button>`;
					<% } %>
					html += `<div class="card-price-area"><div><div class="card-price">${priceF}<span class="card-price-cur"> Ar</span></div>${prop.type === 'Location' ? '<div class="card-price-sub">par mois</div>' : ''}</div><div class="card-views"><i class="fas fa-eye"></i> <span></span></div></div></div><div class="card-body"><h3 class="card-title">${escHtml(prop.title)}</h3><div class="card-loc"><i class="fas fa-map-marker-alt"></i> ${escHtml(prop.location)}</div><div class="card-rule"></div><div class="card-feats">${prop.surface > 0 ? `<span class="feat"><i class="fas fa-ruler-combined"></i> ${prop.surface} m²</span>` : ''}${prop.rooms > 0 ? `<span class="feat"><i class="fas fa-door-open"></i> ${prop.rooms} pièces</span>` : ''}${prop.bedrooms > 0 ? `<span class="feat"><i class="fas fa-bed"></i> ${prop.bedrooms} ch.</span>` : ''}</div><div class="card-actions"><a href="<%= request.getContextPath() %>/immo/property-detail.jsp?id=${prop.id}" class="btn-see"><i class="fas fa-eye"></i> Voir le bien</a><a href="javascript:void(0)" onclick="contactAboutProperty('${prop.id}',encodeURIComponent(prop.title || ''),'${prop.price}',encodeURIComponent(prop.imageUrl || ''),encodeURIComponent(prop.type || ''),encodeURIComponent(prop.location || ''))" class="btn-contact" title="Contacter l'agent"><i class="fas fa-comments"></i></a></div></div></div>`;
				});
				if(grid) grid.innerHTML = html;
				<% if (isLoggedIn && !isAdmin) { %>
				updateFavButtonsState();
				<% } %>
			} else {
				if(grid) grid.innerHTML = `<div class="empty-state"><i class="fas fa-home" style="font-size:52px;opacity:.2;color:var(--blue);display:block;margin-bottom:16px;"></i><h3>Aucun bien trouvé</h3><p>Essayez d'élargir vos critères de recherche.</p></div>`;
			}
			if (n === 0) showToast('info', `😕 Aucun bien ne correspond à vos critères.`);
			else if (type !== 'all' || minVal > 0 || maxVal < MAX_B) showToast('success', `✅ ${n} bien${n > 1 ? 's trouvés' : ' trouvé'} selon vos critères !`);
		}).catch(err => { if(grid) grid.classList.remove('loading'); showToast('error', '❌ Erreur lors de la recherche.'); console.error(err); });
	}

	function resetFilters() {
		if(slMin) slMin.value = 0;
		if(slMax) slMax.value = MAX_B;
		updateSliders();
		document.getElementById('typeInput').value = 'all';
		document.querySelectorAll('.type-pill').forEach(p => p.classList.remove('active'));
		const allPill = document.querySelector('.type-pill[data-type="all"]');
		if(allPill) allPill.classList.add('active');
		const block = document.getElementById('activeFiltersBlock');
		if(block) block.style.display = 'none';
		applyFilters();
		showToast('info', '🔄 Filtres réinitialisés — tous les biens affichés.');
	}

	function escHtml(str) {
		if (!str) return '';
		return String(str).replace(/[&<>"']/g, m => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[m]));
	}
	
	/* ── Partager une publication vers le chat ── */
	function contactAboutProperty(propId, propTitle, propPrice, propImage, propType, propLocation) {
	    <% if (chatUser == null) { %>
	    /* Utilisateur non connecté → rediriger vers login */
	    showToast('info', '🔒 Connectez-vous pour contacter l\'agent');
	    setTimeout(function() {
	        window.location.href = '<%= request.getContextPath() %>/login.jsp';
	    }, 1200);
	    return;
	    <% } %>

	    /* Construire l'URL vers le chat avec les données de la publication */
	    var params = new URLSearchParams({
	        userId          : 9,
	        propertyId      : propId,
	        propertyTitle   : decodeURIComponent(propTitle),
	        propertyPrice   : propPrice,
	        propertyImage   : decodeURIComponent(propImage),
	        propertyType    : decodeURIComponent(propType),
	        propertyLocation: decodeURIComponent(propLocation)
	    });
	    window.location.href = '<%= request.getContextPath() %>/chat?' + params.toString();
	}

	<% if (isLoggedIn && !isAdmin) { %>
	let favorites = JSON.parse(localStorage.getItem('fredon_favs') || '[]');

	function updateFavBadges() {
		const count = favorites.length;
		const favCountSpan = document.getElementById('favCount');
		const favCountSectionSpan = document.getElementById('favCountSection');
		if(favCountSpan) { favCountSpan.textContent = count; favCountSpan.style.display = count > 0 ? 'inline-flex' : 'none'; }
		if(favCountSectionSpan) favCountSectionSpan.textContent = `(${count})`;
	}

	function updateFavButtonsState() {
		document.querySelectorAll('.card-fav').forEach(btn => {
			const onclickAttr = btn.getAttribute('onclick');
			const match = onclickAttr ? onclickAttr.match(/'(\d+)'/) : null;
			const id = match ? match[1] : null;
			if (id && favorites.includes(id)) btn.classList.add('active');
			else btn.classList.remove('active');
		});
	}

	function toggleFav(btn, id, title) {
		const idx = favorites.indexOf(id);
		if (idx === -1) {
			favorites.push(id);
			btn.classList.add('active');
			showToast('success', `❤️ "${title}" ajouté aux favoris`);
		} else {
			favorites.splice(idx, 1);
			btn.classList.remove('active');
			showToast('info', `💔 "${title}" retiré des favoris`);
		}
		localStorage.setItem('fredon_favs', JSON.stringify(favorites));
		updateFavBadges();
		refreshFavoritesGrid();
	}

	function refreshFavoritesGrid() {
		const grid = document.getElementById('favorisGrid');
		if(!grid) return;
		const allCards = document.querySelectorAll('#propsGrid .prop-card');
		const favCards = Array.from(allCards).filter(card => favorites.includes(card.getAttribute('data-prop-id')));
		if (favCards.length === 0) {
			grid.innerHTML = '<div class="empty-state" style="grid-column:1/-1;"><i class="fas fa-heart" style="font-size:64px;opacity:.2;margin-bottom:20px;display:block;"></i><h3>Aucun favori</h3><p>Cliquez sur le cœur ❤️ d\'un bien pour l\'ajouter à vos favoris.</p></div>';
			return;
		}
		let html = '';
		favCards.forEach(card => { html += card.outerHTML; });
		grid.innerHTML = html;
		updateFavButtonsState();
	}

	function clearAllFavorites() {
		if (confirm('⚠️ Supprimer définitivement tous vos favoris ?')) {
			favorites = [];
			localStorage.setItem('fredon_favs', JSON.stringify(favorites));
			updateFavBadges();
			refreshFavoritesGrid();
			showToast('info', '🗑️ Tous les favoris ont été supprimés');
		}
	}
	<% } %>

	document.querySelectorAll('.card-views span').forEach(el => { el.textContent = (Math.floor(Math.random() * 90) + 10) + ' vues'; });

	<% if (isLoggedIn && !isAdmin) { %>
	updateFavBadges();
	updateFavButtonsState();
	<% } %>

	function openSettingsModal() {
		const modal = document.getElementById('settingsModal');
		if(modal) modal.classList.add('open');
		const savedLang = localStorage.getItem('fredon_lang') || 'fr';
		document.querySelectorAll('.lang-btn').forEach(btn => {
			if(btn.dataset.lang === savedLang) btn.classList.add('active');
			else btn.classList.remove('active');
		});
		const autoDark = localStorage.getItem('fredon_auto_dark') === 'true';
		const autoToggle = document.getElementById('autoDarkMode');
		if(autoToggle) autoToggle.checked = autoDark;
		const savedFont = localStorage.getItem('fredon_font_size') || 'normal';
		document.querySelectorAll('.font-size-btn').forEach(btn => {
			if(btn.dataset.size === savedFont) btn.classList.add('active');
			else btn.classList.remove('active');
		});
	}
	function closeSettingsModal() { document.getElementById('settingsModal').classList.remove('open'); }

	function saveSettings() {
		const activeLang = document.querySelector('.lang-btn.active')?.dataset.lang || 'fr';
		localStorage.setItem('fredon_lang', activeLang);
		const autoDark = document.getElementById('autoDarkMode')?.checked || false;
		localStorage.setItem('fredon_auto_dark', autoDark);
		closeSettingsModal();
		showToast('success', '⚙️ Paramètres enregistrés !');
		setTimeout(() => location.reload(), 800);
	}

	function showDeleteAccountModal() {
		closeSettingsModal();
		document.getElementById('deleteAccountModal').classList.add('open');
	}
	function closeDeleteAccountModal() {
		document.getElementById('deleteAccountModal').classList.remove('open');
		document.getElementById('deletePassword').value = '';
	}

	function setFontSize(size) {
		const body = document.getElementById('body');
		body.classList.remove('font-small', 'font-normal', 'font-large');
		body.classList.add('font-' + size);
		localStorage.setItem('fredon_font_size', size);
		document.querySelectorAll('.font-size-btn').forEach(btn => {
			if(btn.dataset.size === size) btn.classList.add('active');
			else btn.classList.remove('active');
		});
		showToast('success', `📏 Taille ${size === 'small' ? 'petite' : size === 'normal' ? 'normale' : 'grande'} activée`);
	}

	// ===== HISTORIQUE AGENCE =====
	function loadHistorique() {
		if (document.getElementById('page-historique') === null) return;
		fetch('<%= request.getContextPath() %>/historique-agence')
			.then(r => r.json())
			.then(data => {
				if (!data) return;

				// Infos principales
				if (data.nom) document.getElementById('hist-nom').textContent = data.nom;
				if (data.description) document.getElementById('hist-desc').textContent = data.description;
				if (data.annee_creation) document.getElementById('hist-annee').textContent = data.annee_creation;
				if (data.siege) document.getElementById('hist-siege').textContent = data.siege;
				if (data.telephone) document.getElementById('hist-tel').textContent = data.telephone;
				if (data.email) document.getElementById('hist-email').textContent = data.email;

				// Timeline
				const tl = document.getElementById('hist-timeline');
				if (data.timeline && data.timeline.length > 0) {
					let html = '';
					const colors = ['var(--blue)', 'var(--gold)', 'var(--emerald)', 'var(--rose)', 'var(--teal)'];
					data.timeline.forEach((item, i) => {
						const col = colors[i % colors.length];
						html += `
						<div style="position:relative;margin-bottom:36px;padding-left:28px;animation:fadeUp .5s ${i * 0.1}s both;">
							<div style="position:absolute;left:-22px;top:4px;width:18px;height:18px;border-radius:50%;background:${col};border:3px solid var(--surface);box-shadow:0 0 0 3px ${col}33;"></div>
							<div style="background:var(--surface);border:1.5px solid var(--border);border-radius:16px;padding:20px 22px;transition:transform .2s,box-shadow .2s;" onmouseover="this.style.transform='translateX(6px)';this.style.boxShadow='0 8px 24px rgba(0,0,0,.08)'" onmouseout="this.style.transform='';this.style.boxShadow=''">
								<div style="display:flex;align-items:center;gap:10px;margin-bottom:8px;">
									<span style="font-family:'Syne',sans-serif;font-size:18px;font-weight:800;color:${col};">${item.annee}</span>
									<span style="font-family:'Syne',sans-serif;font-size:15px;font-weight:700;color:var(--tx);">${item.titre}</span>
								</div>
								<p style="font-size:13.5px;color:var(--tx2);line-height:1.7;margin:0;">${item.description}</p>
							</div>
						</div>`;
					});
					tl.innerHTML = html;
				} else {
					tl.innerHTML = '<p style="color:var(--tx3);font-size:14px;padding:20px 0;">Aucun événement enregistré.</p>';
				}

				// Services
				const sv = document.getElementById('hist-services');
				if (data.services && data.services.length > 0) {
					const icons = ['fas fa-key', 'fas fa-home', 'fas fa-file-contract', 'fas fa-hard-hat', 'fas fa-chart-line', 'fas fa-handshake'];
					const cols = ['var(--blue)', 'var(--gold)', 'var(--emerald)', 'var(--rose)', 'var(--teal)', 'var(--blue3)'];
					let html = '';
					data.services.forEach((s, i) => {
						const col = cols[i % cols.length];
						const ico = icons[i % icons.length];
						html += `
						<div style="background:var(--surface);border:1.5px solid var(--border);border-radius:18px;padding:24px 20px;text-align:center;transition:transform .25s,box-shadow .25s;" onmouseover="this.style.transform='translateY(-5px)';this.style.boxShadow='0 12px 32px rgba(0,0,0,.09)'" onmouseout="this.style.transform='';this.style.boxShadow=''">
							<div style="width:48px;height:48px;border-radius:13px;background:${col}18;display:flex;align-items:center;justify-content:center;margin:0 auto 14px;font-size:20px;color:${col};"><i class="${ico}"></i></div>
							<div style="font-family:'Syne',sans-serif;font-size:14px;font-weight:700;color:var(--tx);">${s}</div>
						</div>`;
					});
					sv.innerHTML = html;
				} else {
					sv.innerHTML = '<p style="color:var(--tx3);font-size:14px;padding:20px 0;grid-column:1/-1;">Aucun service enregistré.</p>';
				}
			})
			.catch(() => {
				document.getElementById('hist-timeline').innerHTML = '<p style="color:var(--rose);">Erreur de chargement.</p>';
			});
	}

	// Charger si page historique active au démarrage
	if ('<%= pageParam %>'.includes('historique')) loadHistorique();

	// Charger quand on clique sur le lien nav
	document.querySelectorAll('.nav-link').forEach(link => {
		link.addEventListener('click', function(e) {
			const href = this.getAttribute('href');
			if (href && href.includes('page=historique')) {
				setTimeout(loadHistorique, 100);
			}
		});
	});
	// ===== FIN HISTORIQUE =====
	const savedFontSize = localStorage.getItem('fredon_font_size');
	if(savedFontSize) setFontSize(savedFontSize);
	else setFontSize('normal');

	document.querySelectorAll('.modal-overlay').forEach(modal => {
		modal.addEventListener('click', function(e) {
			if (e.target === this) this.classList.remove('open');
		});
	});
	
	// Empêche l'accès aux pages après déconnexion
	if (performance.navigation.type === 2) {
	    window.location.href = '${pageContext.request.contextPath}/login';
	}
	
	</script>
</body>
</html>