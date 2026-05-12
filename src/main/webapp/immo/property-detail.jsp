<%@ page language="java" contentType="text/html; charset=UTF-8"
	pageEncoding="UTF-8" isELIgnored="true"%>
<%@ page import="java.util.List, java.util.Map"%>
<%@ page import="java.sql.SQLException"%>
<%@ page
	import="com.immobilier.model.Property, com.immobilier.model.PropertyImage, com.immobilier.model.Comment"%>
<%@ page
	import="com.immobilier.dao.PropertyDAO, com.immobilier.dao.PropertyImageDAO, com.immobilier.dao.CommentDAO, com.immobilier.dao.PropertyReactionDAO"%>
<%@ page
	import="java.sql.Connection, java.sql.DriverManager, java.sql.PreparedStatement, java.sql.ResultSet"%>

<%


response.setHeader("Cache-Control", "no-cache, no-store, must-revalidate");
response.setHeader("Pragma", "no-cache");
response.setHeader("Expires", "0");

String DB_URL  = "jdbc:mysql://localhost:3306/quickchat";
String DB_USER = "root";
String DB_PASSWORD = "";

String propertyIdStr = request.getParameter("id");
Property property     = null;
List<PropertyImage> images   = null;
List<Comment>       comments = null;
Map<String,Integer> reactionCounts = null;

if (propertyIdStr != null && !propertyIdStr.trim().isEmpty()) {
    try {
        int propertyId = Integer.parseInt(propertyIdStr);
        Class.forName("com.mysql.cj.jdbc.Driver");
        Connection conn = DriverManager.getConnection(DB_URL, DB_USER, DB_PASSWORD);
        PropertyDAO          propertyDAO  = new PropertyDAO(conn);
        PropertyImageDAO     imageDAO     = new PropertyImageDAO(conn);
        CommentDAO           commentDAO   = new CommentDAO(conn);
        PropertyReactionDAO  reactionDAO  = new PropertyReactionDAO(conn);
        property       = propertyDAO.getPropertyById(propertyId);
        if (property != null) {
            images         = imageDAO.getImagesByPropertyId(propertyId);
            try { comments = commentDAO.getApprovedCommentsByPropertyId(propertyId); }
            catch (SQLException e) { e.printStackTrace(); comments = new java.util.ArrayList<>(); }
            reactionCounts = reactionDAO.countReactionsByPropertyId(propertyId);
        }
        conn.close();
    } catch (Exception e) { e.printStackTrace(); }
}
if (property == null) {
    response.sendRedirect(request.getContextPath() + "/immo/index.jsp");
    return;
}

com.quickchat.model.User chatUser = (com.quickchat.model.User) session.getAttribute("user");
String userName    = chatUser != null ? (chatUser.getDisplayName() != null ? chatUser.getDisplayName() : chatUser.getUsername()) : null;
String userEmail   = chatUser != null ? chatUser.getEmail() : "";
String userProfilePic = chatUser != null ? chatUser.getProfilePic() : "";
String userInitial = userName != null ? userName.substring(0,1).toUpperCase() : "?";
int unreadMessagesCount = 0;
int unreadNotifications = 0;

if (chatUser != null) {
    try {
        com.quickchat.dao.MessageDAO messageDAO = new com.quickchat.dao.MessageDAO();
        unreadMessagesCount = messageDAO.countUnreadMessagesForUser(chatUser.getId());
        
        Connection conn = DriverManager.getConnection(DB_URL, DB_USER, DB_PASSWORD);
        PreparedStatement pstmt = conn.prepareStatement("SELECT COUNT(*) FROM notifications WHERE user_id = ? AND is_read = 0");
        pstmt.setInt(1, chatUser.getId());
        ResultSet rs = pstmt.executeQuery();
        if (rs.next()) unreadNotifications = rs.getInt(1);
        rs.close(); pstmt.close(); conn.close();
    } catch (Exception e) {}
}

int rc_jadore  = reactionCounts != null ? reactionCounts.getOrDefault("jadore",   0) : 0;
int rc_jaime   = reactionCounts != null ? reactionCounts.getOrDefault("jaime",    0) : 0;
int rc_haha    = reactionCounts != null ? reactionCounts.getOrDefault("haha",     0) : 0;
int rc_colere  = reactionCounts != null ? reactionCounts.getOrDefault("colere",   0) : 0;
int rc_triste  = reactionCounts != null ? reactionCounts.getOrDefault("triste",   0) : 0;
int commentCount = comments != null ? comments.size() : 0;

// Récupération des informations terrain
String landArea = property.getLandArea();
String landType = property.getLandType();
String landDocumentation = property.getLandDocumentation();
String landAccess = property.getLandAccess();
String landProximities = property.getLandProximities();
String landNotes = property.getLandNotes();
boolean isLand = "Terrain".equals(property.getType());

String typeClass = "";
if ("Location".equals(property.getType())) {
 typeClass = "location";
} else if ("Terrain".equals(property.getType())) {
 typeClass = "terrain";
} else {
 typeClass = "vente";
}
%>
<!DOCTYPE html>
<html lang="fr">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title><%= property.getTitle() %> — Fredon Immobilier</title>
<link
	href="https://fonts.googleapis.com/css2?family=Syne:wght@400;600;700;800&family=DM+Sans:opsz,wght@9..40,300;9..40,400;9..40,500;9..40,600;9..40,700&display=swap"
	rel="stylesheet">
<link rel="stylesheet"
	href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css">
<script src="https://meet.jit.si/external_api.js"></script>
<style>
/* ══════════════════════════════════════
   TOKENS — identiques à index.jsp
══════════════════════════════════════ */
:root {
	--blue: #1f52d4;
	--blue2: #0e2d82;
	--blue3: #4f7ef8;
	--blue-pale: #e8eeff;
	--gold: #c8860a;
	--gold2: #e8a220;
	--gold-pale: #fff3d4;
	--teal: #0e9e8a;
	--rose: #e03060;
	--rouge: #dc2626;
	--emerald: #059669;
	--bg: #f8f4ee;
	--bg2: #f2ede4;
	--surface: #ffffff;
	--s2: #fdf9f3;
	--s3: #f5f0e8;
	--border: rgba(200, 134, 10, .1);
	--bh: rgba(200, 134, 10, .18);
	--tx: #0d0b08;
	--tx2: #6b5a3e;
	--tx3: #a89880;
	--shadow: 0 8px 40px rgba(0, 0, 0, .08);
	--shadow-lg: 0 20px 64px rgba(0, 0, 0, .12);
	--r-lg: 20px;
	--r-xl: 28px;
	--hh: 68px;
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
	min-height: 100vh;
}

::-webkit-scrollbar {
	width: 4px;
}

::-webkit-scrollbar-thumb {
	background: linear-gradient(var(--blue), var(--gold));
	border-radius: 99px;
}

/* ══════ BG MAISONS ══════ */
#bgCanvas {
	position: fixed;
	inset: 0;
	z-index: 0;
	pointer-events: none;
	opacity: .055;
}

/* ══════ HEADER ══════ */
.header {
	position: sticky;
	top: 0;
	z-index: 800;
	height: var(--hh);
	background: rgba(248, 244, 238, .94);
	backdrop-filter: blur(28px);
	border-bottom: 1px solid var(--border);
	transition: box-shadow .3s;
}

.header.scrolled {
	box-shadow: 0 4px 32px rgba(14, 45, 130, .1);
}

.header-inner {
	max-width: 1400px;
	margin: 0 auto;
	height: 100%;
	padding: 0 36px;
	display: flex;
	align-items: center;
	justify-content: space-between;
	gap: 16px;
}

.logo {
	display: flex;
	align-items: center;
	gap: 12px;
	text-decoration: none;
}

.logo-svg {
	width: 42px;
	height: 42px;
	flex-shrink: 0;
	filter: drop-shadow(0 3px 12px rgba(14, 45, 130, .22));
	transition: transform .3s;
}

.logo:hover .logo-svg {
	transform: scale(1.07) rotate(-2deg);
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
}

.nav a i {
	font-size: 10px;
}

.nav a:hover {
	color: var(--blue);
	background: rgba(31, 82, 212, .07);
}

.nav a.active {
	color: var(--blue);
	background: rgba(31, 82, 212, .07);
	font-weight: 600;
}

.msg-link {
	position: relative;
}

.msg-badge {
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
		rgba(220, 38, 38, .4);
	animation: badgePulse 1.8s ease-in-out infinite;
	line-height: 1;
}

@keyframes badgePulse { 0%,100%{
	box-shadow: 0 0 0 2px rgba(220, 38, 38, .35), 0 3px 12px
		rgba(220, 38, 38, .4);
}
50% {
	box-shadow: 0 0 0 5px rgba(220, 38, 38, .12), 0 3px 18px
		rgba(220, 38, 38, .6);
}
}
.hright {
	display: flex;
	align-items: center;
	gap: 9px;
}

.btn-login {
	display: flex;
	align-items: center;
	gap: 7px;
	padding: 9px 20px;
	border-radius: 11px;
	background: linear-gradient(115deg, var(--blue2), var(--blue3));
	color: #fff;
	font-size: 12.5px;
	font-weight: 700;
	text-decoration: none;
	border: none;
	cursor: pointer;
	box-shadow: 0 4px 18px rgba(31, 82, 212, .28);
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
    padding: 5px 14px 5px 5px;
    border-radius: 40px;
    background: var(--surface);
    border: 1.5px solid var(--border);
    cursor: pointer;
    transition: all 0.3s cubic-bezier(0.2, 0.9, 0.4, 1.1);
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
    box-shadow: 0 20px 40px rgba(0, 0, 0, 0.12);
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
    overflow: hidden;
}

.dropdown-avatar img {
    width: 100%;
    height: 100%;
    object-fit: cover;
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
}

.dropdown-item i {
    width: 20px;
    font-size: 14px;
    color: var(--blue);
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
}

.dropdown-item:hover {
    background: rgba(31, 82, 212, .07);
    padding-left: 22px;
}

.dropdown-item:hover i {
    transform: translateX(3px);
}

.dropdown-item.danger {
    color: var(--rouge);
}

.dropdown-item.danger i {
    color: var(--rouge);
}

.dropdown-footer {
    padding: 12px 18px;
    border-top: 1px solid var(--border);
    background: var(--s2);
    font-size: 11px;
    color: var(--tx3);
    text-align: center;
}

/* ══════ LAYOUT ══════ */
.outer {
	position: relative;
	z-index: 1;
	max-width: 1400px;
	margin: 0 auto;
	padding: 36px 36px 80px;
}

/* Breadcrumb */
.breadcrumb {
	display: flex;
	align-items: center;
	gap: 8px;
	margin-bottom: 28px;
	font-size: 12.5px;
	color: var(--tx3);
}

.breadcrumb a {
	color: var(--tx3);
	text-decoration: none;
	transition: color .2s;
}

.breadcrumb a:hover {
	color: var(--gold);
}

.breadcrumb .sep {
	opacity: .4;
}

.breadcrumb .cur {
	color: var(--tx);
	font-weight: 600;
}

/* ══════ BADGE TYPE ══════ */
.type-badge {
	display: inline-flex;
	align-items: center;
	gap: 6px;
	padding: 5px 14px;
	border-radius: 99px;
	font-size: 10px;
	font-weight: 800;
	letter-spacing: 1.5px;
	text-transform: uppercase;
}

.type-vente {
	background: rgba(5, 150, 105, .12);
	color: var(--emerald);
	border: 1px solid rgba(5, 150, 105, .25);
}

.type-location {
	background: rgba(31, 82, 212, .1);
	color: var(--blue);
	border: 1px solid rgba(31, 82, 212, .2);
}

.type-terrain {
	background: rgba(5, 150, 105, .12);
	color: #059669;
	border: 1px solid rgba(5, 150, 105, .25);
}

/* ══════ HERO GRID ══════ */
.hero-grid {
	display: grid;
	grid-template-columns: 1fr 400px;
	gap: 24px;
	margin-bottom: 24px;
	align-items: start;
}

/* GALLERY */
.gallery-card {
	background: var(--tx);
	border-radius: var(--r-xl);
	overflow: hidden;
	box-shadow: var(--shadow-lg);
	position: relative;
}

.main-img-wrap {
	position: relative;
	height: 500px;
	overflow: hidden;
	cursor: zoom-in;
}

.main-img-wrap img {
	width: 100%;
	height: 100%;
	object-fit: cover;
	display: block;
	transition: transform .6s cubic-bezier(.25, .46, .45, .94);
}

.main-img-wrap:hover img {
	transform: scale(1.04);
}

.main-img-wrap::after {
	content: '';
	position: absolute;
	inset: 0;
	background: linear-gradient(to top, rgba(13, 11, 8, .6) 0%, transparent
		55%);
	pointer-events: none;
}

.gal-nav {
	position: absolute;
	top: 50%;
	transform: translateY(-50%);
	width: 44px;
	height: 44px;
	border-radius: 50%;
	background: rgba(255, 255, 255, .15);
	backdrop-filter: blur(10px);
	border: 1.5px solid rgba(255, 255, 255, .25);
	color: #fff;
	font-size: 14px;
	cursor: pointer;
	z-index: 3;
	transition: all .22s;
	display: flex;
	align-items: center;
	justify-content: center;
}

.gal-nav:hover {
	background: rgba(200, 134, 10, .7);
	border-color: var(--gold);
}

.gal-nav.prev {
	left: 14px;
}

.gal-nav.next {
	right: 14px;
}

.gal-counter {
	position: absolute;
	bottom: 16px;
	right: 16px;
	z-index: 3;
	background: rgba(13, 11, 8, .65);
	backdrop-filter: blur(8px);
	color: #fff;
	font-size: 12px;
	font-weight: 600;
	padding: 5px 13px;
	border-radius: 99px;
	border: 1px solid rgba(200, 134, 10, .3);
}

.thumb-strip {
	display: flex;
	gap: 8px;
	padding: 12px 14px;
	background: rgba(13, 11, 8, .85);
	overflow-x: auto;
	scrollbar-width: none;
}

.thumb-strip::-webkit-scrollbar {
	display: none;
}

.thumb {
	width: 86px;
	height: 58px;
	border-radius: 11px;
	overflow: hidden;
	flex-shrink: 0;
	cursor: pointer;
	opacity: .4;
	transition: all .25s;
	border: 2px solid transparent;
}

.thumb:hover {
	opacity: .75;
	transform: translateY(-3px);
}

.thumb.active {
	opacity: 1;
	border-color: var(--gold2);
	box-shadow: 0 4px 16px rgba(200, 134, 10, .35);
}

.thumb img {
	width: 100%;
	height: 100%;
	object-fit: cover;
}

/* SIDEBAR CARD */
.info-card {
	background: var(--surface);
	border-radius: var(--r-xl);
	overflow: hidden;
	box-shadow: var(--shadow-lg);
	border: 1.5px solid var(--border);
	position: sticky;
	top: 84px;
}

.ic-head {
	padding: 26px 24px 22px;
	background: linear-gradient(155deg, #0d1f5e 0%, #1a3aaa 45%, #0e2d82 75%, #0a1d58
		100%);
	position: relative;
	overflow: hidden;
}

.ic-head::before {
	content: '';
	position: absolute;
	inset: 0;
	background: radial-gradient(ellipse at 80% 10%, rgba(200, 134, 10, .2)
		0%, transparent 60%),
		radial-gradient(ellipse at 20% 90%, rgba(79, 126, 248, .15) 0%,
		transparent 50%);
	pointer-events: none;
}

.ic-head-grid {
	position: absolute;
	inset: 0;
	pointer-events: none;
	background-image: linear-gradient(rgba(255, 255, 255, .03) 1px,
		transparent 1px), linear-gradient(90deg, rgba(255, 255, 255, .03) 1px,
		transparent 1px);
	background-size: 32px 32px;
}

.ic-type {
	margin-bottom: 12px;
	position: relative;
	z-index: 2;
}

.ic-title {
	font-family: 'Syne', sans-serif;
	font-size: 19px;
	font-weight: 700;
	color: #fff;
	line-height: 1.3;
	margin-bottom: 12px;
	position: relative;
	z-index: 2;
}

.ic-price {
	font-family: 'Syne', sans-serif;
	font-size: 34px;
	font-weight: 800;
	background: linear-gradient(120deg, #fff, #fde9b0);
	-webkit-background-clip: text;
	background-clip: text;
	color: transparent;
	line-height: 1;
	margin-bottom: 8px;
	position: relative;
	z-index: 2;
}

.ic-price-sub {
	font-size: 12px;
	color: rgba(255, 255, 255, .5);
	position: relative;
	z-index: 2;
	margin-bottom: 10px;
}

.ic-loc {
	display: flex;
	align-items: center;
	gap: 7px;
	color: rgba(255, 255, 255, .6);
	font-size: 12.5px;
	position: relative;
	z-index: 2;
}

.ic-loc i {
	color: var(--gold2);
	font-size: 11px;
}

.ic-body {
	padding: 20px 22px;
}

/* Features grid */
.feats-grid {
	display: grid;
	grid-template-columns: 1fr 1fr;
	gap: 8px;
	margin-bottom: 18px;
}

.feat-item {
	background: var(--s2);
	border-radius: 14px;
	padding: 13px 10px;
	text-align: center;
	border: 1.5px solid var(--border);
	transition: all .22s;
}

.feat-item:hover {
	background: var(--gold-pale);
	border-color: var(--bh);
	transform: translateY(-2px);
}

.feat-item i {
	display: block;
	font-size: 18px;
	color: var(--gold);
	margin-bottom: 5px;
}

.feat-val {
	font-family: 'Syne', sans-serif;
	font-weight: 800;
	font-size: 15px;
	display: block;
	color: var(--tx);
}

.feat-lbl {
	font-size: 9.5px;
	text-transform: uppercase;
	letter-spacing: .8px;
	color: var(--tx3);
	margin-top: 2px;
	display: block;
}

/* Action buttons */
.actions {
	display: flex;
	flex-direction: column;
	gap: 9px;
	margin-bottom: 18px;
}

.act-btn {
	display: flex;
	align-items: center;
	justify-content: center;
	gap: 9px;
	padding: 13px;
	border-radius: 14px;
	font-family: 'Syne', sans-serif;
	font-size: 13.5px;
	font-weight: 700;
	cursor: pointer;
	border: none;
	transition: all .25s;
	text-decoration: none;
}

.act-primary {
	background: linear-gradient(115deg, var(--gold), var(--gold2));
	color: #fff;
	box-shadow: 0 6px 22px rgba(200, 134, 10, .3);
}

.act-primary:hover {
	transform: translateY(-2px);
	box-shadow: 0 10px 30px rgba(200, 134, 10, .4);
}

.act-wa {
	background: #25D366;
	color: #fff;
	box-shadow: 0 5px 18px rgba(37, 211, 102, .28);
}

.act-wa:hover {
	transform: translateY(-2px);
	box-shadow: 0 9px 26px rgba(37, 211, 102, .4);
}

.act-mail {
	background: var(--surface);
	color: var(--tx2);
	border: 1.5px solid var(--border);
}

.act-mail:hover {
	border-color: var(--gold);
	color: var(--gold);
	background: var(--gold-pale);
	transform: translateY(-2px);
}

/* Reactions */
.reactions-wrap {
	background: var(--s2);
	border-radius: 16px;
	padding: 12px 8px;
	border: 1.5px solid var(--border);
	margin-bottom: 14px;
}

.reactions-title {
	font-size: 10px;
	font-weight: 700;
	text-transform: uppercase;
	letter-spacing: 1.5px;
	color: var(--tx3);
	text-align: center;
	margin-bottom: 10px;
}

.reactions-row {
	display: flex;
	justify-content: space-around;
	gap: 4px;
}

.react-btn {
	display: flex;
	flex-direction: column;
	align-items: center;
	gap: 2px;
	background: none;
	border: none;
	cursor: pointer;
	padding: 8px 6px;
	border-radius: 12px;
	transition: all .22s;
	font-family: 'DM Sans', sans-serif;
	flex: 1;
}

.react-btn:hover {
	background: rgba(200, 134, 10, .1);
	transform: scale(1.12);
}

.react-btn.reacted {
	background: var(--gold-pale);
}

.react-btn .emoji {
	font-size: 22px;
	display: block;
	transition: transform .25s;
}

.react-btn:hover .emoji {
	transform: scale(1.25) translateY(-3px);
}

.react-btn.reacted .emoji {
	transform: scale(1.15);
}

.react-count {
	font-size: 11px;
	font-weight: 700;
	color: var(--tx2);
}

.react-label {
	font-size: 8.5px;
	color: var(--tx3);
}

/* Stats row */
.stats-bar {
	display: flex;
	gap: 8px;
}

.stat-pill {
	flex: 1;
	display: flex;
	align-items: center;
	justify-content: center;
	gap: 5px;
	background: var(--s2);
	border: 1.5px solid var(--border);
	border-radius: 99px;
	padding: 7px 10px;
	font-size: 12px;
	font-weight: 500;
	color: var(--tx2);
	text-decoration: none;
}

.stat-pill i {
	color: var(--gold);
	font-size: 10px;
}

/* ══════ BOTTOM GRID ══════ */
.bottom-grid {
	display: grid;
	grid-template-columns: 1fr 400px;
	gap: 24px;
	align-items: start;
}

/* Content card */
.content-card {
	background: var(--surface);
	border-radius: var(--r-xl);
	border: 1.5px solid var(--border);
	overflow: hidden;
	box-shadow: var(--shadow);
	margin-bottom: 22px;
	animation: fadeUp .5s both;
}

.content-card:nth-child(2) {
	animation-delay: .1s;
}

.content-card:nth-child(3) {
	animation-delay: .2s;
}

@keyframes fadeUp {
	from {opacity: 0;
	transform: translateY(18px);
}
to {
	opacity: 1;
	transform: translateY(0);
}
}
.cc-head {
	display: flex;
	align-items: center;
	gap: 13px;
	padding: 18px 24px;
	border-bottom: 1.5px solid var(--border);
}

.cc-icon {
	width: 42px;
	height: 42px;
	border-radius: 13px;
	flex-shrink: 0;
	display: flex;
	align-items: center;
	justify-content: center;
	font-size: 17px;
}

.icon-blue {
	background: var(--blue-pale);
	color: var(--blue);
}

.icon-gold {
	background: var(--gold-pale);
	color: var(--gold);
}

.icon-purple {
	background: #f0ebff;
	color: #7c3aed;
}

.cc-title {
	font-family: 'Syne', sans-serif;
	font-size: 17px;
	font-weight: 700;
	color: var(--tx);
}

.cc-sub {
	font-size: 11.5px;
	color: var(--tx3);
	margin-top: 2px;
}

.cc-body {
	padding: 24px;
}

.desc-text {
	font-size: 15px;
	line-height: 1.85;
	color: var(--tx2);
}

/* Map */
.map-wrap {
	border-radius: 16px;
	overflow: hidden;
}

.map-wrap iframe {
	width: 100%;
	height: 300px;
	border: 0;
	display: block;
}

.map-coords {
	display: flex;
	align-items: center;
	justify-content: center;
	gap: 6px;
	margin-top: 10px;
	font-size: 12px;
	color: var(--tx3);
	background: var(--s2);
	padding: 7px 14px;
	border-radius: 99px;
	width: fit-content;
	margin-left: auto;
	margin-right: auto;
}

.map-coords i {
	color: var(--gold);
}

/* ══════ COMMENTS ══════ */
.comment-form-box {
	background: var(--s2);
	border-radius: 18px;
	padding: 22px;
	margin-bottom: 22px;
	border: 1.5px solid var(--border);
}

.form-row-2 {
	display: grid;
	grid-template-columns: 1fr 1fr;
	gap: 12px;
	margin-bottom: 12px;
}

.form-input {
	width: 100%;
	padding: 12px 14px;
	border: 1.5px solid var(--border);
	border-radius: 12px;
	font-family: 'DM Sans', sans-serif;
	font-size: 14px;
	color: var(--tx);
	background: var(--surface);
	transition: all .22s;
	resize: none;
}

.form-input:focus {
	outline: none;
	border-color: var(--gold);
	box-shadow: 0 0 0 3px rgba(200, 134, 10, .1);
}

.form-input::placeholder {
	color: rgba(168, 152, 128, .65);
}

.form-bottom {
	display: flex;
	align-items: center;
	justify-content: space-between;
	gap: 12px;
	flex-wrap: wrap;
	margin-top: 12px;
}

.btn-submit {
	display: inline-flex;
	align-items: center;
	gap: 8px;
	padding: 12px 24px;
	border-radius: 40px;
	border: none;
	background: linear-gradient(115deg, var(--gold), var(--gold2));
	color: #fff;
	font-family: 'Syne', sans-serif;
	font-size: 13.5px;
	font-weight: 700;
	cursor: pointer;
	transition: all .25s;
	box-shadow: 0 5px 18px rgba(200, 134, 10, .3);
	white-space: nowrap;
	flex-shrink: 0;
}

.btn-submit:hover {
	transform: translateY(-2px);
	box-shadow: 0 9px 26px rgba(200, 134, 10, .4);
}

.emoji-wrap {
	position: relative;
	flex-shrink: 0;
}

.emoji-trigger-btn {
	display: flex;
	align-items: center;
	gap: 6px;
	background: var(--surface);
	border: 1.5px solid var(--border);
	border-radius: 40px;
	padding: 9px 14px;
	cursor: pointer;
	font-size: 14px;
	transition: all .2s;
	font-family: 'DM Sans', sans-serif;
	color: var(--tx2);
	font-size: 13px;
	font-weight: 500;
}

.emoji-trigger-btn:hover {
	border-color: var(--gold);
	background: var(--gold-pale);
	color: var(--gold);
}

.emoji-panel {
	position: absolute;
	bottom: calc(100% + 10px);
	right: 0;
	background: var(--surface);
	border-radius: 20px;
	border: 1.5px solid var(--bh);
	box-shadow: var(--shadow-lg);
	width: 320px;
	max-height: 300px;
	overflow-y: auto;
	padding: 14px;
	z-index: 500;
	display: none;
	scrollbar-width: thin;
}

.emoji-panel.open {
	display: block;
	animation: panelIn .22s ease;
}

@keyframes panelIn {
	from {opacity: 0;
	transform: translateY(8px) scale(.97);
}
to {
	opacity: 1;
	transform: translateY(0) scale(1);
}
}
.ep-cat-title {
	font-size: 9.5px;
	font-weight: 800;
	text-transform: uppercase;
	letter-spacing: 1.5px;
	color: var(--tx3);
	margin: 10px 0 7px;
}

.ep-cat-title:first-child {
	margin-top: 0;
}

.ep-grid {
	display: grid;
	grid-template-columns: repeat(8, 1fr);
	gap: 4px;
	margin-bottom: 4px;
}

.ep-emoji {
	font-size: 20px;
	text-align: center;
	cursor: pointer;
	padding: 4px;
	border-radius: 8px;
	transition: all .15s;
}

.ep-emoji:hover {
	background: var(--gold-pale);
	transform: scale(1.25);
}

/* Comment list */
.comment-item {
	padding: 18px 0;
	border-bottom: 1px solid var(--border);
	animation: fadeUp .4s both;
}

.comment-item:last-child {
	border-bottom: none;
	padding-bottom: 0;
}

.c-meta {
	display: flex;
	align-items: center;
	gap: 10px;
	margin-bottom: 8px;
}

.c-avatar {
	width: 36px;
	height: 36px;
	border-radius: 11px;
	flex-shrink: 0;
	background: linear-gradient(135deg, var(--gold), var(--gold2));
	display: flex;
	align-items: center;
	justify-content: center;
	font-family: 'Syne', sans-serif;
	font-size: 14px;
	font-weight: 800;
	color: #fff;
}

.c-author {
	font-weight: 700;
	font-size: 13.5px;
	color: var(--tx);
}

.c-date {
	font-size: 11px;
	color: var(--tx3);
}

.c-text {
	font-size: 14px;
	line-height: 1.7;
	color: var(--tx2);
	padding-left: 46px;
}

.empty-comments {
	text-align: center;
	padding: 48px 20px;
	color: var(--tx3);
}

.empty-comments .ec-icon {
	font-size: 42px;
	display: block;
	margin-bottom: 12px;
	opacity: .3;
}

/* ══════ JITSI MODAL ══════ */
.jmodal {
	display: none;
	position: fixed;
	inset: 0;
	background: rgba(13, 11, 8, .88);
	backdrop-filter: blur(14px);
	z-index: 9999;
	align-items: center;
	justify-content: center;
}

.jmodal.open {
	display: flex;
}

.jmodal-box {
	background: var(--surface);
	border-radius: 24px;
	width: 95%;
	max-width: 1200px;
	height: 86vh;
	display: flex;
	flex-direction: column;
	overflow: hidden;
	box-shadow: 0 40px 120px rgba(0, 0, 0, .5);
	border: 1.5px solid var(--border);
	animation: fadeUp .3s both;
}

.jmodal-head {
	padding: 14px 22px;
	background: linear-gradient(155deg, #0d1f5e, #1a3aaa);
	display: flex;
	justify-content: space-between;
	align-items: center;
}

.jmodal-head h3 {
	font-family: 'Syne', sans-serif;
	font-size: 16px;
	font-weight: 700;
	color: #fff;
}

.jmodal-close {
	width: 34px;
	height: 34px;
	border-radius: 50%;
	background: rgba(255, 255, 255, .12);
	border: 1px solid rgba(255, 255, 255, .2);
	color: #fff;
	font-size: 18px;
	cursor: pointer;
	transition: all .2s;
	display: flex;
	align-items: center;
	justify-content: center;
}

.jmodal-close:hover {
	background: rgba(224, 48, 96, .5);
}

#jitsiContainer {
	flex: 1;
	background: #0d0b08;
}

.jmodal-foot {
	padding: 12px 20px;
	background: var(--s2);
	display: flex;
	align-items: center;
	justify-content: center;
	gap: 10px;
	flex-wrap: wrap;
	font-size: 12.5px;
	color: var(--tx3);
}

.room-input {
	border: 1.5px solid var(--border);
	background: var(--surface);
	padding: 6px 14px;
	border-radius: 99px;
	font-size: 12px;
	width: 300px;
	font-family: monospace;
}

.copy-btn {
	background: linear-gradient(115deg, var(--gold), var(--gold2));
	color: #fff;
	border: none;
	padding: 7px 18px;
	border-radius: 99px;
	cursor: pointer;
	font-size: 12px;
	font-weight: 700;
	transition: all .2s;
	font-family: 'Syne', sans-serif;
}

.copy-btn:hover {
	transform: translateY(-1px);
	box-shadow: 0 5px 16px rgba(200, 134, 10, .35);
}

/* ══════ TOAST ══════ */
.toast-stack {
	position: fixed;
	bottom: 28px;
	right: 24px;
	z-index: 8888;
	display: flex;
	flex-direction: column;
	gap: 8px;
	pointer-events: none;
}

.toast {
	display: flex;
	align-items: center;
	gap: 11px;
	padding: 13px 18px;
	border-radius: 15px;
	min-width: 260px;
	background: var(--surface);
	border: 1.5px solid var(--border);
	box-shadow: var(--shadow-lg);
	pointer-events: all;
	animation: toastIn .4s cubic-bezier(.22, .97, .45, 1) both;
	font-size: 13.5px;
	font-weight: 500;
	color: var(--tx);
}

.toast.exit {
	animation: toastOut .3s ease forwards;
}

.ti {
	width: 32px;
	height: 32px;
	border-radius: 9px;
	flex-shrink: 0;
	display: flex;
	align-items: center;
	justify-content: center;
	font-size: 13px;
}

.ti-success {
	background: rgba(5, 150, 105, .12);
	color: var(--emerald);
}

.ti-info {
	background: rgba(31, 82, 212, .1);
	color: var(--blue);
}

.ti-error {
	background: rgba(220, 38, 38, .1);
	color: var(--rouge);
}

.toast-x {
	margin-left: auto;
	background: none;
	border: none;
	cursor: pointer;
	color: var(--tx3);
	font-size: 16px;
}

@keyframes toastIn {
	from {opacity: 0;
	transform: translateX(50px) scale(.93);
}
to {
	opacity: 1;
	transform: translateX(0) scale(1);
}
}
@keyframes toastOut {
	from {opacity: 1;
}
to {
	opacity: 0;
	transform: translateX(50px);
}
}
/* ══════ RESPONSIVE ══════ */
@media ( max-width :1100px) {
	.hero-grid, .bottom-grid {
		grid-template-columns: 1fr;
	}
	.info-card {
		position: static;
	}
}
@media ( max-width :768px) {
	.main-img-wrap {
		height: 320px;
	}
	.nav a:not(.btn-login) {
		display: none;
	}
	.outer {
		padding: 24px 18px 60px;
	}
	.form-row-2 {
		grid-template-columns: 1fr;
	}
	.feats-grid {
		grid-template-columns: repeat(4, 1fr);
	}
	.header-inner {
		padding: 0 18px;
	}
}
@media ( max-width :480px) {
	.feats-grid {
		grid-template-columns: 1fr 1fr;
	}
	.emoji-panel {
		width: 280px;
		right: -30px;
	}
}
</style>
</head>
<body>

	<!-- BG Canvas -->
	<canvas id="bgCanvas"></canvas>

	<!-- ══════ TOAST STACK ══════ -->
	<div class="toast-stack" id="toastStack"></div>

	<!-- ══════ HEADER ══════ -->
	<header class="header" id="header">
		<div class="header-inner">
			<a href="<%= request.getContextPath() %>/immo/index.jsp" class="logo" style="gap: 12px;">
				<img src="<%= request.getContextPath() %>/immo/admin/images/Logo.jpg"
				     alt="Fredon"
				     style="width: 44px; height: 44px; object-fit: cover; border-radius: 12px; box-shadow: 0 4px 12px rgba(0,0,0,.15);">
				<div>
					<div class="logo-name">Fredon</div>
					<div class="logo-sub">Agence Immobilière</div>
				</div>
			</a>

			<nav class="nav">
				<a href="<%= request.getContextPath() %>/immo/index.jsp"><i
					class="fas fa-home"></i> Accueil</a> 
				<a href="<%= request.getContextPath() %>/immo/index.jsp?page=biens"><i
					class="fas fa-building"></i> Nos biens</a>
				<% if (chatUser != null) { %>
				<a href="<%= request.getContextPath() %>/notifications.jsp" class="msg-link">
					<i class="fas fa-bell"></i> Notifications
					<% if (unreadNotifications > 0) { %>
					<span class="msg-badge"><%= unreadNotifications > 9 ? "9+" : unreadNotifications %></span>
					<% } %>
				</a>
				<a href="<%= request.getContextPath() %>/chat.jsp" class="msg-link">
					<i class="fas fa-comments"></i> Messages 
					<% if (unreadMessagesCount > 0) { %>
					<span class="msg-badge"><%= unreadMessagesCount > 9 ? "9+" : unreadMessagesCount %></span>
					<% } %>
				</a>
				<% } %>
			</nav>

			<div class="hright">
				<% if (chatUser == null) { %>
				<a href="<%= request.getContextPath() %>/login.jsp"
					class="btn-login"> <i class="fas fa-sign-in-alt"></i> Connexion
				</a>
				<% } else { %>
				<div class="user-menu">
					<div class="user-pill">
						<div class="user-av">
							<% if (userProfilePic != null && !userProfilePic.isEmpty()) { %>
							<img src="<%= request.getContextPath() %>/uploads/<%= userProfilePic %>" alt="<%= userName %>">
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
								<% if (userProfilePic != null && !userProfilePic.isEmpty()) { %>
								<img src="<%= request.getContextPath() %>/uploads/<%= userProfilePic %>" alt="<%= userName %>">
								<% } else { %>
								<%= userInitial %>
								<% } %>
							</div>
							<div class="dropdown-info">
								<h4><%= userName %></h4>
								<p><%= userEmail %></p>
							</div>
						</div>
						<div class="dropdown-divider"></div>
						<a href="<%= request.getContextPath() %>/notifications.jsp" class="dropdown-item">
							<i class="fas fa-bell"></i><span>Notifications</span>
							<% if (unreadNotifications > 0) { %>
							<span class="dropdown-badge"><%= unreadNotifications > 9 ? "9+" : unreadNotifications %></span>
							<% } %>
						</a>
						<a href="<%= request.getContextPath() %>/chat.jsp" class="dropdown-item">
							<i class="fas fa-comments"></i><span>Messages</span>
							<% if (unreadMessagesCount > 0) { %>
							<span class="dropdown-badge"><%= unreadMessagesCount > 9 ? "9+" : unreadMessagesCount %></span>
							<% } %>
						</a>
						<div class="dropdown-divider"></div>
						<a href="<%= request.getContextPath() %>/profile.jsp" class="dropdown-item"><i class="fas fa-user-circle"></i><span>Mon profil</span></a>
						<div class="dropdown-divider"></div>
						<a href="<%= request.getContextPath() %>/logout" class="dropdown-item danger"><i class="fas fa-sign-out-alt"></i><span>Déconnexion</span></a>
						<div class="dropdown-footer"><i class="fas fa-shield-alt"></i> Compte sécurisé</div>
					</div>
				</div>
				<% } %>
			</div>
		</div>
	</header>

	<!-- ══════ MAIN ══════ -->
	<main class="outer">

		<!-- Breadcrumb -->
		<div class="breadcrumb">
			<a href="<%= request.getContextPath() %>/immo/index.jsp"><i
				class="fas fa-home"></i> Accueil</a> <span class="sep">/</span> 
			<a href="<%= request.getContextPath() %>/immo/index.jsp">Annonces</a> <span class="sep">/</span> 
			<span class="cur"><%= property.getTitle() %></span>
		</div>

		<!-- ══ HERO GRID ══ -->
		<div class="hero-grid">

			<!-- Gallery -->
			<div class="gallery-card">
				<div class="main-img-wrap" id="mainWrap">
					<% if (images != null && !images.isEmpty()) {
						PropertyImage primary = null;
						for (PropertyImage img : images) { if (img.isPrimary()) { primary = img; break; } }
						if (primary == null) primary = images.get(0);
					%>
					<img id="mainImg"
						src="<%= request.getContextPath() %>/<%= primary.getImageUrl() %>"
						alt="<%= property.getTitle() %>">
					<% } else { %>
					<img id="mainImg"
						src="https://via.placeholder.com/1200x500/0d1f5e/c8860a?text=Fredon+Immobilier"
						alt="Image">
					<% } %>
					<% if (images != null && images.size() > 1) { %>
					<button class="gal-nav prev" onclick="prevImg()">
						<i class="fas fa-chevron-left"></i>
					</button>
					<button class="gal-nav next" onclick="nextImg()">
						<i class="fas fa-chevron-right"></i>
					</button>
					<div class="gal-counter">
						<span id="imgIdx">1</span> /
						<%= images.size() %>
					</div>
					<% } %>
				</div>
				<% if (images != null && images.size() > 1) { %>
				<div class="thumb-strip" id="thumbStrip">
					<% for (int i = 0; i < images.size(); i++) { PropertyImage im = images.get(i); %>
					<div class="thumb <%= i==0?"active":"" %>" data-i="<%= i %>"
						onclick="goImg(<%= i %>)">
						<img src="<%= request.getContextPath() %>/<%= im.getImageUrl() %>"
							alt="Photo <%= i+1 %>">
					</div>
					<% } %>
				</div>
				<% } %>
			</div>

			<!-- Info sidebar card -->
			<div class="info-card">
				<div class="ic-head">
					<div class="ic-head-grid"></div>
					<div class="ic-type">
						<span class="type-badge type-<%= typeClass %>"><i
							class="fas fa-tag"></i> <%= property.getType() %></span>
					</div>
					<div class="ic-title"><%= property.getTitle() %></div>
					<div class="ic-price"><%= String.format("%,.0f", property.getPrice()) %> Ar</div>
					<% if ("Location".equals(property.getType())) { %>
					<div class="ic-price-sub">par mois</div>
					<% } %>
					<div class="ic-loc">
						<i class="fas fa-map-marker-alt"></i>
						<%= property.getLocation() %>
					</div>
				</div>

				<div class="ic-body">
					<!-- Caractéristiques -->
					<div class="feats-grid">
				    <% if (isLand) { %>
				        <% if (landArea != null && !landArea.isEmpty()) { %>
				        <div class="feat-item">
				            <i class="fas fa-vector-square"></i> 
				            <span class="feat-val"><%= landArea %></span>
				            <span class="feat-lbl">Superficie</span>
				        </div>
				        <% } %>
				        <% if (landType != null && !landType.isEmpty()) { %>
				        <div class="feat-item">
				            <i class="fas fa-tree"></i> 
				            <span class="feat-val"><%= landType %></span>
				            <span class="feat-lbl">Type</span>
				        </div>
				        <% } %>
				        <% if (landDocumentation != null && !landDocumentation.isEmpty()) { %>
				        <div class="feat-item">
				            <i class="fas fa-file-alt"></i> 
				            <span class="feat-val"><%= landDocumentation %></span>
				            <span class="feat-lbl">Documentation</span>
				        </div>
				        <% } %>
				        <% if (landAccess != null && !landAccess.isEmpty()) { %>
				        <div class="feat-item">
				            <i class="fas fa-road"></i> 
				            <span class="feat-val"><%= landAccess %></span>
				            <span class="feat-lbl">Accès</span>
				        </div>
				        <% } %>
				    <% } else { %>
				        <% if (property.getSurface() != null && property.getSurface() > 0) { %>
				        <div class="feat-item">
				            <i class="fas fa-ruler-combined"></i> 
				            <span class="feat-val"><%= property.getSurface() %></span>
				            <span class="feat-lbl">m² Surface</span>
				        </div>
				        <% } %>
				        <% if (property.getRooms() != null && property.getRooms() > 0) { %>
				        <div class="feat-item">
				            <i class="fas fa-door-open"></i> 
				            <span class="feat-val"><%= property.getRooms() %></span>
				            <span class="feat-lbl">Pièces</span>
				        </div>
				        <% } %>
				        <% if (property.getBedrooms() != null && property.getBedrooms() > 0) { %>
				        <div class="feat-item">
				            <i class="fas fa-bed"></i> 
				            <span class="feat-val"><%= property.getBedrooms() %></span>
				            <span class="feat-lbl">Chambres</span>
				        </div>
				        <% } %>
				        <% if (property.getBathrooms() != null && property.getBathrooms() > 0) { %>
				        <div class="feat-item">
				            <i class="fas fa-bath"></i> 
				            <span class="feat-val"><%= property.getBathrooms() %></span>
				            <span class="feat-lbl">Sdb</span>
				        </div>
				        <% } %>
				    <% } %>
				</div>

					<div class="actions">
						<button class="act-btn act-primary" onclick="startCall()">
							<i class="fas fa-video"></i> Visite vidéo en direct
						</button>
						
						<a href="<%= request.getContextPath() %>/immo/schedule-appointment.jsp?property_id=<%= property.getId() %>&property_title=<%= java.net.URLEncoder.encode(property.getTitle(), "UTF-8") %>" class="act-btn act-primary" style="background: linear-gradient(135deg, #0e9e8a, #0e2d82); text-decoration: none;">
    <i class="fas fa-calendar-check"></i> Prendre rendez-vous
</a>
						
						<a href="https://wa.me/?text=Intéressé+par+le+bien+:<%= java.net.URLEncoder.encode(property.getTitle(),"UTF-8") %>" target="_blank" class="act-btn act-wa">
							<i class="fab fa-whatsapp"></i> Contacter sur WhatsApp
						</a>
						<a href="mailto:contact@fredon.mg?subject=Demande+pour+<%= java.net.URLEncoder.encode(property.getTitle(),"UTF-8") %>" class="act-btn act-mail">
							<i class="fas fa-envelope"></i> Envoyer un email
						</a>
					</div>

					<!-- ═══ RÉACTIONS ═══ -->
					<div class="reactions-wrap">
						<div class="reactions-title">
							<i class="fas fa-heart" style="color: var(--rose); margin-right: 5px;"></i> 
							Réagissez à ce bien
						</div>
						<div class="reactions-row">
							<button class="react-btn" id="rb_jadore" data-type="jadore" title="J'adore">
								<span class="emoji">❤️</span> 
								<span class="react-count" id="rc_jadore"><%= rc_jadore %></span> 
								<span class="react-label">J'adore</span>
							</button>
							<button class="react-btn" id="rb_jaime" data-type="jaime" title="J'aime">
								<span class="emoji">👍</span> 
								<span class="react-count" id="rc_jaime"><%= rc_jaime %></span> 
								<span class="react-label">J'aime</span>
							</button>
							<button class="react-btn" id="rb_haha" data-type="haha" title="Hahaha">
								<span class="emoji">😂</span> 
								<span class="react-count" id="rc_haha"><%= rc_haha %></span> 
								<span class="react-label">Hahaha</span>
							</button>
							<button class="react-btn" id="rb_colere" data-type="colere" title="En colère">
								<span class="emoji">😡</span> 
								<span class="react-count" id="rc_colere"><%= rc_colere %></span> 
								<span class="react-label">Colère</span>
							</button>
							<button class="react-btn" id="rb_triste" data-type="triste" title="Triste">
								<span class="emoji">😢</span> 
								<span class="react-count" id="rc_triste"><%= rc_triste %></span> 
								<span class="react-label">Triste</span>
							</button>
						</div>
					</div>

					<!-- Stats -->
					<div class="stats-bar">
						<div class="stat-pill">
							<i class="fas fa-eye"></i> <span id="viewCount">—</span> vues
						</div>
						<a href="#comments" class="stat-pill"> 
							<i class="fas fa-comments"></i> <span><%= commentCount %></span> avis
						</a>
					</div>
				</div>
			</div>
		</div>

		<!-- ══ BOTTOM GRID ══ -->
		<div class="bottom-grid">

			<!-- Colonne gauche -->
			<div>

				<!-- Description -->
				<div class="content-card">
					<div class="cc-head">
						<div class="cc-icon icon-blue">
							<i class="fas fa-align-left"></i>
						</div>
						<div>
							<div class="cc-title">Description du bien</div>
							<div class="cc-sub">Détails complets de cette propriété</div>
						</div>
					</div>
					<div class="cc-body">
						<p class="desc-text"><%= property.getDescription() %></p>
					</div>
				</div>
				
				<% if (isLand && landProximities != null && !landProximities.isEmpty()) { %>
				<div class="content-card">
				    <div class="cc-head">
				        <div class="cc-icon" style="background: var(--teal-pale); color: var(--teal);">
				            <i class="fas fa-city"></i>
				        </div>
				        <div>
				            <div class="cc-title">Proximités & environnement</div>
				            <div class="cc-sub">À proximité du terrain</div>
				        </div>
				    </div>
				    <div class="cc-body">
				        <p class="desc-text"><%= landProximities %></p>
				    </div>
				</div>
				<% } %>

				<% if (isLand && landNotes != null && !landNotes.isEmpty()) { %>
				<div class="content-card">
				    <div class="cc-head">
				        <div class="cc-icon" style="background: var(--rose-pale); color: var(--rose);">
				            <i class="fas fa-info-circle"></i>
				        </div>
				        <div>
				            <div class="cc-title">Informations complémentaires</div>
				            <div class="cc-sub">Détails importants</div>
				        </div>
				    </div>
				    <div class="cc-body">
				        <p class="desc-text"><%= landNotes %></p>
				    </div>
				</div>
				<% } %>

				<!-- Commentaires -->
				<div class="content-card" id="comments">
					<div class="cc-head">
						<div class="cc-icon icon-gold">
							<i class="fas fa-comments"></i>
						</div>
						<div>
							<div class="cc-title">Avis &amp; Commentaires</div>
							<div class="cc-sub"><%= commentCount %>
								commentaire<%= commentCount > 1 ? "s" : "" %></div>
						</div>
					</div>
					<div class="cc-body">

						<!-- Formulaire -->
						<div class="comment-form-box">
							<form id="commentForm"
								action="<%= request.getContextPath() %>/immo/add-comment.jsp"
								method="POST">
								<input type="hidden" name="propertyId"
									value="<%= property.getId() %>">
								<div class="form-row-2">
									<input class="form-input" type="text" name="visitorName"
										placeholder="Votre nom *" required> 
									<input class="form-input" type="email" name="visitorEmail"
										placeholder="Email (optionnel)">
								</div>
								<textarea class="form-input" name="content" id="commentContent"
									rows="4" placeholder="Partagez votre avis sur ce bien…"
									required></textarea>

								<div class="form-bottom">
									<button type="submit" class="btn-submit">
										<i class="fas fa-paper-plane"></i> Publier
									</button>

									<div class="emoji-wrap">
										<button type="button" class="emoji-trigger-btn"
											id="emojiTrigger">
											😊 <i class="fas fa-chevron-up" id="emojiChev"
												style="font-size: 9px; transition: transform .2s;"></i>
										</button>
										<div class="emoji-panel" id="emojiPanel">
											<div class="ep-cat-title">😀 Smileys</div>
											<div class="ep-grid">
												<span class="ep-emoji">😀</span><span class="ep-emoji">😃</span><span
													class="ep-emoji">😄</span><span class="ep-emoji">😁</span>
												<span class="ep-emoji">😆</span><span class="ep-emoji">😅</span><span
													class="ep-emoji">😂</span><span class="ep-emoji">🤣</span>
												<span class="ep-emoji">😊</span><span class="ep-emoji">😇</span><span
													class="ep-emoji">🙂</span><span class="ep-emoji">😉</span>
												<span class="ep-emoji">😍</span><span class="ep-emoji">🥰</span><span
													class="ep-emoji">😘</span><span class="ep-emoji">😎</span>
												<span class="ep-emoji">🤩</span><span class="ep-emoji">🥳</span><span
													class="ep-emoji">😏</span><span class="ep-emoji">😒</span>
												<span class="ep-emoji">😔</span><span class="ep-emoji">😢</span><span
													class="ep-emoji">😭</span><span class="ep-emoji">😤</span>
												<span class="ep-emoji">😠</span><span class="ep-emoji">😡</span><span
													class="ep-emoji">🤬</span><span class="ep-emoji">😱</span>
												<span class="ep-emoji">🤯</span><span class="ep-emoji">😳</span><span
													class="ep-emoji">😴</span><span class="ep-emoji">🤗</span>
											</div>
											<div class="ep-cat-title">👍 Gestes</div>
											<div class="ep-grid">
												<span class="ep-emoji">👍</span><span class="ep-emoji">👎</span><span
													class="ep-emoji">👌</span><span class="ep-emoji">✌️</span>
												<span class="ep-emoji">🤞</span><span class="ep-emoji">🙌</span><span
													class="ep-emoji">👏</span><span class="ep-emoji">🤝</span>
												<span class="ep-emoji">🙏</span><span class="ep-emoji">💪</span><span
													class="ep-emoji">❤️</span><span class="ep-emoji">🔥</span>
												<span class="ep-emoji">✨</span><span class="ep-emoji">💯</span><span
													class="ep-emoji">✅</span><span class="ep-emoji">⭐</span>
											</div>
											<div class="ep-cat-title">🏠 Immobilier</div>
											<div class="ep-grid">
												<span class="ep-emoji">🏠</span><span class="ep-emoji">🏡</span><span
													class="ep-emoji">🏢</span><span class="ep-emoji">🏰</span>
												<span class="ep-emoji">🔑</span><span class="ep-emoji">🗝️</span><span
													class="ep-emoji">🛋️</span><span class="ep-emoji">🛏️</span>
												<span class="ep-emoji">🚿</span><span class="ep-emoji">🛁</span><span
													class="ep-emoji">🚪</span><span class="ep-emoji">🪟</span>
												<span class="ep-emoji">🌿</span><span class="ep-emoji">🌳</span><span
													class="ep-emoji">🌺</span><span class="ep-emoji">🌈</span>
											</div>
										</div>
									</div>
								</div>
							</form>
						</div>

						<!-- Liste commentaires -->
						<div id="commentsList">
							<% if (comments != null && !comments.isEmpty()) {
								for (Comment c : comments) {
									String init = (c.getVisitorName() != null && !c.getVisitorName().isEmpty())
										? String.valueOf(c.getVisitorName().charAt(0)).toUpperCase() : "?";
							%>
							<div class="comment-item">
								<div class="c-meta">
									<div class="c-avatar"><%= init %></div>
									<div>
										<div class="c-author"><%= c.getVisitorName() %></div>
										<div class="c-date">
											<i class="fas fa-clock"></i>
											<%= c.getCreatedAt() %>
										</div>
									</div>
								</div>
								<p class="c-text"><%= c.getContent() %></p>
							</div>
							<% } } else { %>
							<div class="empty-comments">
								<span class="ec-icon">✨</span>
								<p style="font-weight: 700; color: var(--tx); margin-bottom: 6px;">Aucun commentaire pour le moment</p>
								<p>Soyez le premier à donner votre avis !</p>
							</div>
							<% } %>
						</div>

					</div>
				</div>

			</div>

			<!-- Colonne droite — Carte -->
			<div>
				<% if (property.getLatitude() != null && property.getLongitude() != null) { %>
				<div class="content-card">
					<div class="cc-head">
						<div class="cc-icon icon-purple">
							<i class="fas fa-map-marked-alt"></i>
						</div>
						<div>
							<div class="cc-title">Localisation</div>
							<div class="cc-sub"><%= property.getLocation() %></div>
						</div>
					</div>
					<div class="cc-body">
						<div class="map-wrap">
							<iframe
								src="https://www.openstreetmap.org/export/embed.html?bbox=<%= property.getLongitude()-0.01 %>,<%= property.getLatitude()-0.01 %>,<%= property.getLongitude()+0.01 %>,<%= property.getLatitude()+0.01 %>&layer=mapnik&marker=<%= property.getLatitude() %>,<%= property.getLongitude() %>"
								allowfullscreen loading="lazy"></iframe>
						</div>
						<div class="map-coords">
							<i class="fas fa-location-dot"></i>
							<%= property.getLatitude() %>, <%= property.getLongitude() %>
						</div>
					</div>
				</div>
				<% } %>

				<!-- Infos rapides -->
				<div class="content-card">
					<div class="cc-head">
						<div class="cc-icon icon-gold">
							<i class="fas fa-info-circle"></i>
						</div>
						<div>
							<div class="cc-title">Infos rapides</div>
							<div class="cc-sub">Référence #FRED-<%= property.getId() %></div>
						</div>
					</div>
					<div class="cc-body">
						<div style="display: flex; flex-direction: column; gap: 10px; font-size: 13.5px; color: var(--tx2);">
						    <div style="display: flex; justify-content: space-between; padding: 10px 14px; background: var(--s2); border-radius: 11px; border: 1px solid var(--border);">
						        <span><i class="fas fa-tag" style="color: var(--gold); width: 18px;"></i> Type</span> 
						        <strong style="color: var(--tx)"><%= property.getType() %></strong>
						    </div>
						    <div style="display: flex; justify-content: space-between; padding: 10px 14px; background: var(--s2); border-radius: 11px; border: 1px solid var(--border);">
						        <span><i class="fas fa-coins" style="color: var(--gold); width: 18px;"></i> Prix</span> 
						        <strong style="color: var(--gold); font-family: 'Syne', sans-serif;"><%= String.format("%,.0f", property.getPrice()) %> Ar</strong>
						    </div>
						    <% if (isLand) { %>
						        <% if (landArea != null && !landArea.isEmpty()) { %>
						        <div style="display: flex; justify-content: space-between; padding: 10px 14px; background: var(--s2); border-radius: 11px; border: 1px solid var(--border);">
						            <span><i class="fas fa-vector-square" style="color: var(--emerald); width: 18px;"></i> Superficie</span> 
						            <strong style="color: var(--tx)"><%= landArea %></strong>
						        </div>
						        <% } %>
						    <% } else { %>
						        <% if (property.getSurface() != null && property.getSurface() > 0) { %>
						        <div style="display: flex; justify-content: space-between; padding: 10px 14px; background: var(--s2); border-radius: 11px; border: 1px solid var(--border);">
						            <span><i class="fas fa-ruler-combined" style="color: var(--gold); width: 18px;"></i> Surface</span> 
						            <strong style="color: var(--tx)"><%= property.getSurface() %> m²</strong>
						        </div>
						        <% } %>
						    <% } %>
						    <div style="display: flex; justify-content: space-between; padding: 10px 14px; background: var(--s2); border-radius: 11px; border: 1px solid var(--border);">
						        <span><i class="fas fa-map-marker-alt" style="color: var(--gold); width: 18px;"></i> Lieu</span> 
						        <strong style="color: var(--tx)"><%= property.getLocation() %></strong>
						    </div>
						</div>
					</div>
				</div>
			</div>

		</div>
		<!-- /bottom-grid -->

	</main>

	<!-- ══════ JITSI MODAL ══════ -->
	<div class="jmodal" id="jmodal">
		<div class="jmodal-box">
			<div class="jmodal-head">
				<h3>📹 Visite virtuelle — <%= property.getTitle() %></h3>
				<button class="jmodal-close" onclick="closeCall()">✕</button>
			</div>
			<div id="jitsiContainer"></div>
			<div class="jmodal-foot">
				<i class="fas fa-lock" style="color: var(--emerald);"></i> 
				<span>Appel sécurisé et gratuit</span> 
				<span>Lien :</span> 
				<input class="room-input" type="text" id="roomLink" readonly>
				<button class="copy-btn" onclick="copyLink()">
					<i class="fas fa-copy"></i> Copier
				</button>
			</div>
		</div>
	</div>

	<script>
	var CTX = '<%= request.getContextPath() %>';
	var propertyId = <%= property.getId() %>;

	/* ══════ BG CANVAS ══════ */
	(function(){
		var canvas = document.getElementById('bgCanvas');
		var ctx = canvas.getContext('2d');
		var W, H, items = [];
		
		function resize() {
			W = canvas.width = window.innerWidth;
			H = canvas.height = window.innerHeight;
		}
		resize();
		window.addEventListener('resize', function() { resize(); init(); });
		
		var PAL = [
			{r:200,g:134,b:10},
			{r:31,g:82,b:212},
			{r:14,g:158,b:138},
			{r:224,g:48,b:96},
			{r:79,g:126,b:248}
		];
		
		function drawHouse(x, y, s, a, col) {
			ctx.save();
			ctx.globalAlpha = a;
			ctx.translate(x, y);
			ctx.scale(s, s);
			var c = 'rgba(' + col.r + ',' + col.g + ',' + col.b + ',1)';
			var cf = 'rgba(' + col.r + ',' + col.g + ',' + col.b + ',.25)';
			ctx.strokeStyle = c;
			ctx.fillStyle = cf;
			ctx.lineWidth = 1.5 / s;
			ctx.lineCap = 'round';
			ctx.beginPath();
			ctx.rect(-18, -10, 36, 26);
			ctx.fill();
			ctx.stroke();
			ctx.beginPath();
			ctx.moveTo(-22, -10);
			ctx.lineTo(0, -28);
			ctx.lineTo(22, -10);
			ctx.closePath();
			ctx.fill();
			ctx.stroke();
			ctx.beginPath();
			ctx.arc(0, 10, 6, Math.PI, 0);
			ctx.lineTo(6, 16);
			ctx.lineTo(-6, 16);
			ctx.closePath();
			ctx.fillStyle = 'rgba(' + col.r + ',' + col.g + ',' + col.b + ',.5)';
			ctx.fill();
			ctx.stroke();
			ctx.fillStyle = cf;
			ctx.strokeRect(-15, -7, 9, 8);
			ctx.strokeRect(6, -7, 9, 8);
			ctx.fillStyle = 'rgba(' + col.r + ',' + col.g + ',' + col.b + ',.6)';
			ctx.fillRect(7, -32, 5, 10);
			ctx.strokeRect(7, -32, 5, 10);
			ctx.restore();
		}
		
		function init() {
			items = [];
			for (var i = 0; i < 20; i++) {
				var col = PAL[Math.floor(Math.random() * PAL.length)];
				items.push({
					x: Math.random() * W,
					y: Math.random() * H,
					s: 0.45 + Math.random() * 1.1,
					a: 0.04 + Math.random() * 0.08,
					col: col,
					vx: (Math.random() - 0.5) * 0.12,
					vy: (Math.random() - 0.5) * 0.1,
					ph: Math.random() * Math.PI * 2
				});
			}
		}
		init();
		
		function anim(t) {
			ctx.clearRect(0, 0, W, H);
			items.forEach(function(h) {
				h.x += h.vx;
				h.y += h.vy + Math.sin(t * 0.0004 + h.ph) * 0.04;
				if (h.x < -80) h.x = W + 60;
				if (h.x > W + 80) h.x = -60;
				if (h.y < -80) h.y = H + 60;
				if (h.y > H + 80) h.y = -60;
				drawHouse(h.x, h.y, h.s, h.a, h.col);
			});
			requestAnimationFrame(anim);
		}
		anim(0);
	})();

	/* ══════ HEADER SCROLL ══════ */
	window.addEventListener('scroll', function() {
		document.getElementById('header').classList.toggle('scrolled', window.scrollY > 10);
	}, {passive: true});

	/* ══════ GALLERY ══════ */
	var allImgs = [], curIdx = 0;
	<% if(images != null && images.size() > 0){
		for(PropertyImage im : images) {
	%>
		allImgs.push("<%= request.getContextPath() %>/<%= im.getImageUrl() %>");
	<% 
		}
	} 
	%>
	
	function goImg(i) {
		if (!allImgs.length) return;
		i = (i + allImgs.length) % allImgs.length;
		curIdx = i;
		document.getElementById('mainImg').src = allImgs[i];
		var el = document.getElementById('imgIdx');
		if (el) el.textContent = i + 1;
		var thumbs = document.querySelectorAll('.thumb');
		for (var j = 0; j < thumbs.length; j++) {
			thumbs[j].classList.toggle('active', j === i);
		}
	}
	
	function nextImg() { goImg(curIdx + 1); }
	function prevImg() { goImg(curIdx - 1); }
	
	document.addEventListener('keydown', function(e) {
		if (document.getElementById('jmodal').classList.contains('open')) {
			if (e.key === 'Escape') closeCall();
			return;
		}
		if (e.key === 'ArrowRight') nextImg();
		if (e.key === 'ArrowLeft') prevImg();
	});

	/* ══════ TOAST ══════ */
	function showToast(message, type) {
		type = type || 'success';
		var toastStack = document.getElementById('toastStack');
		if (!toastStack) return;
		
		var toast = document.createElement('div');
		toast.className = 'toast';
		
		var icon = document.createElement('i');
		icon.className = type === 'success' ? 'fas fa-check-circle' : (type === 'error' ? 'fas fa-exclamation-circle' : 'fas fa-info-circle');
		icon.style.marginRight = '8px';
		icon.style.color = type === 'success' ? 'var(--emerald)' : (type === 'error' ? 'var(--rouge)' : 'var(--gold)');
		
		var text = document.createElement('span');
		text.textContent = message;
		
		var closeBtn = document.createElement('button');
		closeBtn.innerHTML = '×';
		closeBtn.className = 'toast-x';
		closeBtn.onclick = function() { toast.remove(); };
		
		toast.appendChild(icon);
		toast.appendChild(text);
		toast.appendChild(closeBtn);
		
		toastStack.appendChild(toast);
		
		setTimeout(function() {
			if (toast && toast.parentNode) {
				toast.style.opacity = '0';
				setTimeout(function() { if (toast && toast.parentNode) toast.remove(); }, 300);
			}
		}, 4000);
	}

	/* ══════ GESTION DES RÉACTIONS ══════ */
	var propId = <%= property.getId() %>;
	
	function sendReaction(type) {
		var btn = document.getElementById('rb_' + type);
		if (!btn) return;
		
		var emojiSpan = btn.querySelector('.emoji');
		if (emojiSpan) {
			emojiSpan.style.transform = 'scale(1.5) translateY(-6px)';
			setTimeout(function() { if (emojiSpan) emojiSpan.style.transform = ''; }, 400);
		}
		
		fetch('<%= request.getContextPath() %>/immo/add-reaction.jsp', {
			method: 'POST',
			headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
			body: 'propertyId=' + propId + '&reactionType=' + type
		})
		.then(function(response) { return response.json(); })
		.then(function(data) {
			if (data.success && data.counts) {
				document.getElementById('rc_jadore').textContent = data.counts.jadore || 0;
				document.getElementById('rc_jaime').textContent = data.counts.jaime || 0;
				document.getElementById('rc_haha').textContent = data.counts.haha || 0;
				document.getElementById('rc_colere').textContent = data.counts.colere || 0;
				document.getElementById('rc_triste').textContent = data.counts.triste || 0;
				
				var labels = { jadore: '❤️ J\'adore', jaime: '👍 J\'aime', haha: '😂 Haha', colere: '😡 Colère', triste: '😢 Triste' };
				showToast(data.isNew ? labels[type] + ' ajoutée' : labels[type] + ' retirée', 'success');
			}
		})
		.catch(function(error) {
			console.error('Erreur:', error);
			showToast('❌ Erreur lors de l\'envoi', 'error');
		});
	}
	
	document.querySelectorAll('.react-btn').forEach(function(btn) {
		var newBtn = btn.cloneNode(true);
		btn.parentNode.replaceChild(newBtn, btn);
		
		newBtn.addEventListener('click', function(e) {
			e.preventDefault();
			var type = this.getAttribute('data-type');
			sendReaction(type);
		});
	});

	/* ══════ VUES ══════ */
	fetch('<%= request.getContextPath() %>/immo/update-view.jsp', {
		method: 'POST',
		headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
		body: 'propertyId=' + propId
	})
	.then(function(response) { return response.json(); })
	.then(function(data) {
		if (data && data.views !== undefined) {
			document.getElementById('viewCount').textContent = data.views;
		}
	})
	.catch(function() { document.getElementById('viewCount').textContent = '—'; });

	/* ══════ EMOJI PICKER ══════ */
	var emojiTrigger = document.getElementById('emojiTrigger');
	var emojiPanel = document.getElementById('emojiPanel');
	var emojiChev = document.getElementById('emojiChev');
	
	if (emojiTrigger && emojiPanel) {
		emojiTrigger.addEventListener('click', function(e) {
			e.stopPropagation();
			var open = emojiPanel.classList.toggle('open');
			if (emojiChev) emojiChev.style.transform = open ? 'rotate(180deg)' : '';
		});
		
		document.addEventListener('click', function(e) {
			if (emojiTrigger && emojiPanel && !emojiTrigger.contains(e.target) && !emojiPanel.contains(e.target)) {
				emojiPanel.classList.remove('open');
				if (emojiChev) emojiChev.style.transform = '';
			}
		});
		
		document.querySelectorAll('.ep-emoji').forEach(function(em) {
			em.addEventListener('click', function() {
				var emoji = this.textContent;
				var ta = document.getElementById('commentContent');
				if (ta) {
					var pos = ta.selectionStart;
					ta.value = ta.value.slice(0, pos) + emoji + ta.value.slice(pos);
					ta.focus();
					ta.selectionStart = ta.selectionEnd = pos + emoji.length;
				}
				this.style.transform = 'scale(1.3)';
				setTimeout(function() { if (em) em.style.transform = ''; }, 200);
			});
		});
	}

	/* ══════ JITSI ══════ */
	var jitsiApi = null;
	var roomName = 'fredon_prop_<%= property.getId() %>_' + Date.now();
	
	function startCall() {
		var modal = document.getElementById('jmodal');
		modal.classList.add('open');
		try {
			jitsiApi = new JitsiMeetExternalAPI("meet.jit.si", {
				roomName: roomName,
				parentNode: document.getElementById('jitsiContainer'),
				userInfo: { displayName: "Visiteur — <%= property.getTitle().replace("\"", "\\\"") %>" },
				configOverwrite: { startWithAudioMuted: false, startWithVideoMuted: false, prejoinPageEnabled: false },
				interfaceConfigOverwrite: { SHOW_JITSI_WATERMARK: false, TOOLBAR_BUTTONS: ['microphone', 'camera', 'desktop', 'fullscreen', 'hangup', 'chat'] }
			});
			document.getElementById('roomLink').value = "https://meet.jit.si/" + roomName;
		} catch(e) { 
			showToast("Impossible de démarrer l'appel vidéo", 'error'); 
		}
	}
	
	function closeCall() {
		if (jitsiApi) { jitsiApi.dispose(); jitsiApi = null; }
		document.getElementById('jmodal').classList.remove('open');
		document.getElementById('jitsiContainer').innerHTML = '';
	}
	
	function copyLink() {
		var inp = document.getElementById('roomLink');
		if (inp) {
			inp.select();
			document.execCommand('copy');
			showToast('✅ Lien copié !', 'success');
		}
	}
	
	document.addEventListener('DOMContentLoaded', function() {
		console.log('Page chargée - property-detail.jsp (design moderne)');
	});

	// Empêche l'accès aux pages après déconnexion
	if (performance.navigation.type === 2) {
	    window.location.href = '${pageContext.request.contextPath}/login';
	}
	
	</script>
</body>
</html>