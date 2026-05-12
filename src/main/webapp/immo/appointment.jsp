<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*, java.util.*, java.text.*" %>
<%@ page import="com.quickchat.model.User" %>

<%
    String DB_URL = "jdbc:mysql://localhost:3306/quickchat";
    String DB_USER = "root";
    String DB_PASSWORD = "";

    // Récupérer l'utilisateur connecté
    User currentUser = (User) session.getAttribute("user");
    String propertyId = request.getParameter("property_id");
    String propertyTitle = request.getParameter("property_title");
    
    if (propertyId == null) {
        response.sendRedirect("index.jsp");
        return;
    }
    
    // Récupérer les informations du bien
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
    
    String success = request.getParameter("success");
    String error = request.getParameter("error");
    String lang = "fr";
%>

<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Demande de visite - <%= propTitle %> | Fredon Immobilier</title>
    <link href="https://fonts.googleapis.com/css2?family=Syne:wght@400;600;700;800&family=DM+Sans:wght@300;400;500;600;700&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css">
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: 'DM Sans', sans-serif;
            background: #f8f4ee;
            color: #0d0b08;
        }
        .container {
            max-width: 600px;
            margin: 0 auto;
            padding: 40px 20px;
        }
        .card {
            background: white;
            border-radius: 24px;
            padding: 32px;
            box-shadow: 0 4px 20px rgba(0,0,0,0.08);
            border: 1px solid rgba(200,134,10,.1);
        }
        .property-info {
            background: linear-gradient(135deg, #e8eeff 0%, #f8faff 100%);
            border-radius: 16px;
            padding: 20px;
            margin-bottom: 24px;
            border: 1px solid rgba(31,82,212,.2);
        }
        .property-title {
            font-family: 'Syne', sans-serif;
            font-size: 20px;
            font-weight: 700;
            margin-bottom: 8px;
        }
        .property-meta {
            color: #6b5a3e;
            font-size: 13px;
        }
        h1 {
            font-family: 'Syne', sans-serif;
            font-size: 28px;
            font-weight: 800;
            margin-bottom: 8px;
        }
        .subtitle {
            color: #a89880;
            margin-bottom: 24px;
        }
        .form-group {
            margin-bottom: 20px;
        }
        label {
            display: block;
            font-size: 13px;
            font-weight: 600;
            color: #6b5a3e;
            margin-bottom: 6px;
            text-transform: uppercase;
            letter-spacing: 0.5px;
        }
        input, select, textarea {
            width: 100%;
            padding: 12px 14px;
            border: 1.5px solid rgba(200,134,10,.15);
            border-radius: 12px;
            font-family: 'DM Sans', sans-serif;
            font-size: 14px;
            transition: all .2s;
            outline: none;
        }
        input:focus, select:focus, textarea:focus {
            border-color: #1f52d4;
            box-shadow: 0 0 0 3px rgba(31,82,212,.1);
        }
        textarea {
            resize: vertical;
            min-height: 100px;
        }
        .date-time-row {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 15px;
        }
        .btn-submit {
            width: 100%;
            padding: 14px;
            background: linear-gradient(115deg, #c8860a, #e8a220);
            color: white;
            border: none;
            border-radius: 14px;
            font-family: 'Syne', sans-serif;
            font-weight: 700;
            font-size: 16px;
            cursor: pointer;
            transition: all .25s;
            margin-top: 10px;
        }
        .btn-submit:hover {
            transform: translateY(-2px);
            box-shadow: 0 8px 20px rgba(200,134,10,.3);
        }
        .btn-back {
            display: inline-flex;
            align-items: center;
            gap: 8px;
            padding: 10px 20px;
            background: white;
            border: 1.5px solid rgba(200,134,10,.2);
            border-radius: 12px;
            text-decoration: none;
            color: #6b5a3e;
            margin-bottom: 20px;
            transition: all .2s;
        }
        .btn-back:hover {
            border-color: #c8860a;
            color: #c8860a;
        }
        .alert {
            padding: 12px 16px;
            border-radius: 12px;
            margin-bottom: 20px;
            font-size: 13px;
        }
        .alert-success {
            background: rgba(16,185,129,.1);
            border: 1px solid rgba(16,185,129,.25);
            color: #059669;
        }
        .alert-error {
            background: rgba(239,68,68,.1);
            border: 1px solid rgba(239,68,68,.25);
            color: #dc2626;
        }
        .info-icon {
            color: #1f52d4;
            margin-right: 8px;
        }
        @media (max-width: 560px) {
            .container { padding: 20px; }
            .card { padding: 24px; }
            .date-time-row { grid-template-columns: 1fr; }
            h1 { font-size: 24px; }
        }
    </style>
</head>
<body>

<div class="container">
   <a href="property-detail.jsp?id=<%= propertyId %>" class="btn-back">
        <i class="fas fa-arrow-left"></i> Retour au bien
    </a>

    <div class="card">
        <h1>📅 Demande de visite</h1>
        <p class="subtitle">Planifiez votre visite pour ce bien immobilier</p>

        <div class="property-info">
            <div class="property-title"><%= propTitle %></div>
            <div class="property-meta">
                <i class="fas fa-map-marker-alt"></i> <%= propLocation %> &nbsp;|&nbsp;
                <i class="fas fa-tag"></i> <%= String.format("%,.0f", propPrice) %> Ar
            </div>
        </div>

        <% if (success != null) { %>
        <div class="alert alert-success">
            <i class="fas fa-check-circle"></i> <%= success %>
        </div>
        <% } %>
        <% if (error != null) { %>
        <div class="alert alert-error">
            <i class="fas fa-exclamation-circle"></i> <%= error %>
        </div>
        <% } %>
<form action="<%= request.getContextPath() %>/schedule-appointment" method="POST">
            <input type="hidden" name="property_id" value="<%= propertyId %>">

            <div class="form-group">
                <label><i class="fas fa-user"></i> Nom complet *</label>
                <input type="text" name="full_name" required value="<%= currentUser != null ? currentUser.getDisplayName() : "" %>" placeholder="Votre nom">
            </div>

            <div class="form-group">
                <label><i class="fas fa-envelope"></i> Email *</label>
                <input type="email" name="email" required value="<%= currentUser != null ? currentUser.getEmail() : "" %>" placeholder="votre@email.com">
            </div>

            <div class="form-group">
                <label><i class="fas fa-phone"></i> Téléphone</label>
                <input type="tel" name="phone" placeholder="+261 34 00 000 00">
            </div>

            <div class="date-time-row">
                <div class="form-group">
                    <label><i class="fas fa-calendar"></i> Date souhaitée *</label>
                    <input type="date" name="appointment_date" required min="<%= new java.text.SimpleDateFormat("yyyy-MM-dd").format(new java.util.Date()) %>">
                </div>
                <div class="form-group">
                    <label><i class="fas fa-clock"></i> Heure souhaitée *</label>
                    <select name="appointment_time" required>
                        <option value="">Sélectionnez une heure</option>
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
                <textarea name="message" placeholder="Ajoutez un message pour l'agent..."></textarea>
            </div>

            <button type="submit" class="btn-submit">
                <i class="fas fa-paper-plane"></i> Envoyer la demande
            </button>
        </form>

        <p style="font-size: 12px; color: #a89880; text-align: center; margin-top: 20px;">
            <i class="fas fa-info-circle"></i> Un agent vous contactera pour confirmer votre visite.
        </p>
    </div>
</div>

<script>
    // Date minimale = aujourd'hui
    const today = new Date().toISOString().split('T')[0];
    document.querySelector('input[name="appointment_date"]').min = today;
</script>

</body>
</html>