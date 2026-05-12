<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*, java.util.*, java.text.*" %>
<%@ page import="com.quickchat.model.User" %>

<%
    String DB_URL = "jdbc:mysql://localhost:3306/quickchat";
    String DB_USER = "root";
    String DB_PASSWORD = "";

    User currentUser = (User) session.getAttribute("user");
    String propertyId = request.getParameter("property_id");
    
    if (propertyId == null) {
        response.sendRedirect("index.jsp");
        return;
    }
    
    // Récupérer les infos du bien
    String propTitle = "";
    String propLocation = "";
    double propPrice = 0;
    
    try {
        Class.forName("com.mysql.cj.jdbc.Driver");
        Connection conn = DriverManager.getConnection(DB_URL, DB_USER, DB_PASSWORD);
        PreparedStatement pstmt = conn.prepareStatement("SELECT title, location, price FROM properties WHERE id = ?");
        pstmt.setInt(1, Integer.parseInt(propertyId));
        ResultSet rs = pstmt.executeQuery();
        if (rs.next()) {
            propTitle = rs.getString("title");
            propLocation = rs.getString("location");
            propPrice = rs.getDouble("price");
        }
        rs.close();
        pstmt.close();
        conn.close();
    } catch(Exception e) {
        e.printStackTrace();
    }
    
    // Récupérer l'utilisateur connecté pour le menu
    String userName = "";
    String userEmail = "";
    String userProfilePic = "";
    int unreadMessagesCount = 0;
    int unreadNotifications = 0;
    
    if (currentUser != null) {
        userName = currentUser.getDisplayName() != null ? currentUser.getDisplayName() : currentUser.getUsername();
        userEmail = currentUser.getEmail() != null ? currentUser.getEmail() : "";
        userProfilePic = currentUser.getProfilePic() != null ? currentUser.getProfilePic() : "";
        try {
            com.quickchat.dao.MessageDAO messageDAO = new com.quickchat.dao.MessageDAO();
            unreadMessagesCount = messageDAO.countUnreadMessagesForUser(currentUser.getId());
            
            Connection conn = DriverManager.getConnection(DB_URL, DB_USER, DB_PASSWORD);
            PreparedStatement pstmt = conn.prepareStatement("SELECT COUNT(*) FROM notifications WHERE user_id = ? AND is_read = 0");
            pstmt.setInt(1, currentUser.getId());
            ResultSet rs = pstmt.executeQuery();
            if (rs.next()) unreadNotifications = rs.getInt(1);
            rs.close(); pstmt.close(); conn.close();
        } catch (Exception e) {}
    }
    
    String success = request.getParameter("success");
    String error = request.getParameter("error");
%>

<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Demande de visite - <%= propTitle %> | Fredon Immobilier</title>
    <link href="https://fonts.googleapis.com/css2?family=Syne:wght@400;600;700;800&family=DM+Sans:opsz,wght@9..40,300;9..40,400;9..40,500;9..40,600;9..40,700&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css">
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

        /* ══════ BG CANVAS ══════ */
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
        .logo img {
            width: 44px;
            height: 44px;
            object-fit: cover;
            border-radius: 12px;
            box-shadow: 0 4px 12px rgba(0,0,0,.15);
        }
        .logo-name {
            font-family: 'Syne', sans-serif;
            font-weight: 800;
            font-size: 20px;
            background: linear-gradient(130deg, var(--blue2), var(--blue) 50%, var(--gold));
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
        }
        .nav a i {
            font-size: 10px;
        }
        .nav a:hover {
            color: var(--blue);
            background: rgba(31, 82, 212, .07);
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
            box-shadow: 0 0 0 2px rgba(220, 38, 38, .35), 0 3px 12px rgba(220, 38, 38, .4);
            animation: badgePulse 1.8s ease-in-out infinite;
        }
        @keyframes badgePulse {
            0%,100% { box-shadow: 0 0 0 2px rgba(220, 38, 38, .35), 0 3px 12px rgba(220, 38, 38, .4); }
            50% { box-shadow: 0 0 0 5px rgba(220, 38, 38, .12), 0 3px 18px rgba(220, 38, 38, .6); }
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
        }

        /* ══════ MAIN LAYOUT ══════ */
        .outer {
            position: relative;
            z-index: 1;
            max-width: 1400px;
            margin: 0 auto;
            padding: 36px 36px 80px;
        }

        .btn-back {
            display: inline-flex;
            align-items: center;
            gap: 8px;
            padding: 8px 16px;
            background: var(--surface);
            border: 1.5px solid var(--border);
            border-radius: 40px;
            text-decoration: none;
            color: var(--tx2);
            font-size: 12.5px;
            font-weight: 500;
            margin-bottom: 24px;
            transition: all .2s;
        }
        .btn-back:hover {
            border-color: var(--gold);
            color: var(--gold);
            background: var(--gold-pale);
        }

        /* Form Card */
        .form-card {
            background: var(--surface);
            border-radius: var(--r-xl);
            border: 1.5px solid var(--border);
            overflow: hidden;
            box-shadow: var(--shadow-lg);
            max-width: 700px;
            margin: 0 auto;
        }
        .form-header {
            padding: 28px 32px 20px;
            background: linear-gradient(135deg, #0d1f5e, #1a3aaa);
            position: relative;
        }
        .form-header h1 {
            font-family: 'Syne', sans-serif;
            font-size: 24px;
            font-weight: 700;
            color: #fff;
            display: flex;
            align-items: center;
            gap: 10px;
        }
        .form-header p {
            color: rgba(255,255,255,.7);
            font-size: 13px;
            margin-top: 8px;
        }
        .property-badge {
            background: rgba(255,255,255,.12);
            border-radius: 12px;
            padding: 14px 18px;
            margin-top: 16px;
            border: 1px solid rgba(255,255,255,.1);
        }
        .property-badge .title {
            font-weight: 700;
            font-size: 15px;
            color: #fff;
        }
        .property-badge .meta {
            font-size: 12px;
            color: rgba(255,255,255,.6);
            margin-top: 4px;
        }
        .form-body {
            padding: 32px;
        }
        .form-group {
            margin-bottom: 22px;
        }
        label {
            display: block;
            font-size: 12px;
            font-weight: 700;
            text-transform: uppercase;
            letter-spacing: 1px;
            color: var(--tx3);
            margin-bottom: 8px;
        }
        input, select, textarea {
            width: 100%;
            padding: 12px 16px;
            border: 1.5px solid var(--border);
            border-radius: 12px;
            font-family: 'DM Sans', sans-serif;
            font-size: 14px;
            color: var(--tx);
            background: var(--surface);
            transition: all .22s;
        }
        input:focus, select:focus, textarea:focus {
            outline: none;
            border-color: var(--gold);
            box-shadow: 0 0 0 3px rgba(200, 134, 10, .1);
        }
        .date-time-row {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 20px;
        }
        .btn-submit {
            width: 100%;
            padding: 14px;
            background: linear-gradient(115deg, var(--gold), var(--gold2));
            color: #fff;
            border: none;
            border-radius: 14px;
            font-family: 'Syne', sans-serif;
            font-weight: 700;
            font-size: 15px;
            cursor: pointer;
            transition: all .25s;
            margin-top: 10px;
            display: flex;
            align-items: center;
            justify-content: center;
            gap: 10px;
        }
        .btn-submit:hover {
            transform: translateY(-2px);
            box-shadow: 0 8px 25px rgba(200, 134, 10, .35);
        }
        .alert {
            padding: 16px 20px;
            border-radius: 14px;
            margin-bottom: 24px;
            display: flex;
            align-items: center;
            gap: 14px;
        }
        .alert-success {
            background: rgba(5, 150, 105, .1);
            border: 1px solid rgba(5, 150, 105, .25);
            color: var(--emerald);
        }
        .alert-error {
            background: rgba(220, 38, 38, .1);
            border: 1px solid rgba(220, 38, 38, .25);
            color: var(--rouge);
        }
        .alert i {
            font-size: 22px;
        }
        .form-note {
            text-align: center;
            font-size: 12px;
            color: var(--tx3);
            margin-top: 24px;
            padding-top: 20px;
            border-top: 1.5px solid var(--border);
        }

        @media (max-width: 768px) {
            .outer { padding: 20px 18px 60px; }
            .form-header { padding: 22px 24px; }
            .form-body { padding: 24px; }
            .date-time-row { grid-template-columns: 1fr; gap: 0; }
            .header-inner { padding: 0 18px; }
            .nav a:not(.btn-login) { display: none; }
        }
    </style>
</head>
<body>

    <!-- BG Canvas -->
    <canvas id="bgCanvas"></canvas>

    <!-- HEADER -->
    <header class="header" id="header">
        <div class="header-inner">
            <a href="<%= request.getContextPath() %>/immo/index.jsp" class="logo">
                <img src="<%= request.getContextPath() %>/immo/admin/images/Logo.jpg" alt="Fredon">
                <div>
                    <div class="logo-name">Fredon</div>
                    <div class="logo-sub">Agence Immobilière</div>
                </div>
            </a>
            <nav class="nav">
                <a href="<%= request.getContextPath() %>/immo/index.jsp"><i class="fas fa-home"></i> Accueil</a>
                <a href="<%= request.getContextPath() %>/immo/index.jsp?page=biens"><i class="fas fa-building"></i> Nos biens</a>
                <% if (currentUser != null) { %>
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
                <% if (currentUser == null) { %>
                <a href="<%= request.getContextPath() %>/login.jsp" class="btn-login"><i class="fas fa-sign-in-alt"></i> Connexion</a>
                <% } else { %>
                <div class="user-menu">
                    <div class="user-pill">
                        <div class="user-av">
                            <% if (userProfilePic != null && !userProfilePic.isEmpty()) { %>
                            <img src="<%= request.getContextPath() %>/uploads/<%= userProfilePic %>" alt="<%= userName %>">
                            <% } else { %>
                            <%= userName.substring(0,1).toUpperCase() %>
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
                                <%= userName.substring(0,1).toUpperCase() %>
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

    <!-- MAIN -->
    <main class="outer">
        <div style="max-width: 800px; margin: 0 auto;">
            <a href="property-detail.jsp?id=<%= propertyId %>" class="btn-back">
                <i class="fas fa-arrow-left"></i> Retour au bien
            </a>

            <div class="form-card">
                <div class="form-header">
                    <h1><i class="fas fa-calendar-check"></i> Demande de visite</h1>
                    <p>Planifiez votre visite en quelques clics</p>
                    <div class="property-badge">
                        <div class="title"><%= propTitle %></div>
                        <div class="meta">
                            <i class="fas fa-map-marker-alt"></i> <%= propLocation %> &nbsp;|&nbsp;
                            <i class="fas fa-tag"></i> <%= String.format("%,.0f", propPrice) %> Ar
                        </div>
                    </div>
                </div>

                <div class="form-body">
                    <% if (success != null) { %>
                    <div class="alert alert-success">
                        <i class="fas fa-check-circle"></i>
                        <div>
                            <strong>Demande envoyée avec succès !</strong><br>
                            Un agent vous contactera dans les plus brefs délais.
                        </div>
                    </div>
                    <% } %>

                    <% if (error != null) { %>
                    <div class="alert alert-error">
                        <i class="fas fa-exclamation-circle"></i>
                        <div>
                            <strong>Une erreur s'est produite</strong><br>
                            Veuillez réessayer ou nous contacter directement.
                        </div>
                    </div>
                    <% } %>

                    <form action="<%= request.getContextPath() %>/api/create-appointment" method="POST">
                        <input type="hidden" name="propertyId" value="<%= propertyId %>">

                        <div class="form-group">
                            <label><i class="fas fa-user"></i> Nom complet *</label>
                            <input type="text" name="clientName" required value="<%= currentUser != null ? currentUser.getDisplayName() : "" %>" placeholder="Votre nom">
                        </div>

                        <div class="form-group">
                            <label><i class="fas fa-envelope"></i> Email *</label>
                            <input type="email" name="clientEmail" required value="<%= currentUser != null ? currentUser.getEmail() : "" %>" placeholder="votre@email.com">
                        </div>

                        <div class="form-group">
                            <label><i class="fas fa-phone"></i> Téléphone</label>
                            <input type="tel" name="clientPhone" placeholder="+261 34 00 000 00">
                        </div>

                        <div class="date-time-row">
                            <div class="form-group">
                                <label><i class="fas fa-calendar"></i> Date souhaitée *</label>
                                <input type="date" name="appointmentDate" required min="<%= new java.text.SimpleDateFormat("yyyy-MM-dd").format(new java.util.Date()) %>">
                            </div>
                            <div class="form-group">
                                <label><i class="fas fa-clock"></i> Heure souhaitée *</label>
                                <select name="appointmentTime" required>
                                    <option value="">Sélectionnez</option>
                                    <option value="09:00">09:00</option>
                                    <option value="10:00">10:00</option>
                                    <option value="11:00">11:00</option>
                                    <option value="14:00">14:00</option>
                                    <option value="15:00">15:00</option>
                                    <option value="16:00">16:00</option>
                                    <option value="17:00">17:00</option>
                                </select>
                            </div>
                        </div>

                        <div class="form-group">
                            <label><i class="fas fa-comment"></i> Message (optionnel)</label>
                            <textarea name="message" rows="3" placeholder="Informations complémentaires..."></textarea>
                        </div>

                        <button type="submit" class="btn-submit">
                            <i class="fas fa-paper-plane"></i> Envoyer la demande
                        </button>

                        <div class="form-note">
                            <i class="fas fa-lock" style="opacity: .5;"></i> Vos informations sont confidentielles
                        </div>
                    </form>
                </div>
            </div>
        </div>
    </main>

    <script>
        // BG Canvas animation
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

            var PAL = [{r:200,g:134,b:10},{r:31,g:82,b:212},{r:14,g:158,b:138},{r:224,g:48,b:96},{r:79,g:126,b:248}];

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
                        x: Math.random() * W, y: Math.random() * H,
                        s: 0.45 + Math.random() * 1.1, a: 0.04 + Math.random() * 0.08,
                        col: col,
                        vx: (Math.random() - 0.5) * 0.12, vy: (Math.random() - 0.5) * 0.1,
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

        // Header scroll
        window.addEventListener('scroll', function() {
            document.getElementById('header').classList.toggle('scrolled', window.scrollY > 10);
        });

        // Date min = aujourd'hui
        const today = new Date().toISOString().split('T')[0];
        const dateInput = document.querySelector('input[name="appointmentDate"]');
        if (dateInput) dateInput.min = today;
    </script>
</body>
</html>