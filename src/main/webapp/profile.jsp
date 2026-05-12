<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="com.quickchat.model.User" %>
<%@ page import="com.quickchat.dao.UserDAO" %>
<%@ page import="java.sql.*" %>
<%@ page import="java.text.SimpleDateFormat" %>
<%

response.setHeader("Cache-Control", "no-cache, no-store, must-revalidate");
response.setHeader("Pragma", "no-cache");
response.setHeader("Expires", "0");

    // Vérifier si l'utilisateur est connecté
    User currentUser = (User) session.getAttribute("user");
    if (currentUser == null) {
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    }

    String DB_URL = "jdbc:mysql://localhost:3306/quickchat";
    String DB_USER = "root";
    String DB_PASSWORD = "";
    
    String successMessage = null;
    String errorMessage = null;
    
    // Traitement du formulaire de mise à jour du profil (sans mot de passe)
    if ("POST".equalsIgnoreCase(request.getMethod())) {
        String action = request.getParameter("action");
        
        if ("updateProfile".equals(action)) {
            String displayName = request.getParameter("displayName");
            String email = request.getParameter("email");
            String phone = request.getParameter("phone");
            String bio = request.getParameter("bio");
            
            try {
                Class.forName("com.mysql.cj.jdbc.Driver");
                Connection conn = DriverManager.getConnection(DB_URL, DB_USER, DB_PASSWORD);
                PreparedStatement pstmt = conn.prepareStatement(
                    "UPDATE users SET display_name = ?, email = ?, phone = ?, bio = ? WHERE id = ?"
                );
                pstmt.setString(1, displayName);
                pstmt.setString(2, email);
                pstmt.setString(3, phone);
                pstmt.setString(4, bio);
                pstmt.setInt(5, currentUser.getId());
                
                int updated = pstmt.executeUpdate();
                if (updated > 0) {
                    // Mettre à jour l'objet en session
                    currentUser.setDisplayName(displayName);
                    currentUser.setEmail(email);
                    currentUser.setPhone(phone);
                    currentUser.setBio(bio);
                    session.setAttribute("user", currentUser);
                    successMessage = "Profil mis à jour avec succès !";
                } else {
                    errorMessage = "Erreur lors de la mise à jour";
                }
                pstmt.close();
                conn.close();
            } catch (Exception e) {
                errorMessage = "Erreur : " + e.getMessage();
            }
        }
    }
    
    // Récupérer les informations supplémentaires depuis la base de données
    String userPhone = "";
    String userBio = "";
    String profilePic = "";
    int favoritesCount = 0;
    int messagesCount = 0;
    String memberSince = "";
    
    try {
        Class.forName("com.mysql.cj.jdbc.Driver");
        Connection conn = DriverManager.getConnection(DB_URL, DB_USER, DB_PASSWORD);
        
        // Récupérer les infos utilisateur
        PreparedStatement userStmt = conn.prepareStatement(
            "SELECT phone, bio, profile_pic, created_at FROM users WHERE id = ?"
        );
        userStmt.setInt(1, currentUser.getId());
        ResultSet userRs = userStmt.executeQuery();
        if (userRs.next()) {
            userPhone = userRs.getString("phone") != null ? userRs.getString("phone") : "";
            userBio = userRs.getString("bio") != null ? userRs.getString("bio") : "";
            profilePic = userRs.getString("profile_pic") != null ? userRs.getString("profile_pic") : "";
            Timestamp createdAt = userRs.getTimestamp("created_at");
            if (createdAt != null) {
                SimpleDateFormat sdf = new SimpleDateFormat("dd MMMM yyyy");
                memberSince = sdf.format(createdAt);
            }
        }
        userRs.close();
        userStmt.close();
        
        // Nombre de favoris
        PreparedStatement favStmt = conn.prepareStatement(
            "SELECT COUNT(*) as count FROM user_favorites WHERE user_id = ?"
        );
        favStmt.setInt(1, currentUser.getId());
        ResultSet favRs = favStmt.executeQuery();
        if (favRs.next()) favoritesCount = favRs.getInt("count");
        favRs.close();
        favStmt.close();
        
        // Nombre de messages envoyés
        PreparedStatement msgStmt = conn.prepareStatement(
            "SELECT COUNT(*) as count FROM messages WHERE sender_id = ? AND is_deleted_for_sender = 0"
        );
        msgStmt.setInt(1, currentUser.getId());
        ResultSet msgRs = msgStmt.executeQuery();
        if (msgRs.next()) messagesCount = msgRs.getInt("count");
        msgRs.close();
        msgStmt.close();
        
        conn.close();
    } catch (Exception e) {
        e.printStackTrace();
    }
    
    String userInitial = currentUser.getInitial();
    String displayName = currentUser.getDisplayName() != null ? currentUser.getDisplayName() : currentUser.getUsername();
    String userEmail = currentUser.getEmail() != null ? currentUser.getEmail() : "";
%>
<!DOCTYPE html>
<html lang="fr">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Mon profil — Fredon</title>
<link href="https://fonts.googleapis.com/css2?family=Syne:wght@400;600;700;800&family=DM+Sans:opsz,wght@9..40,300;9..40,400;9..40,500;9..40,600&display=swap" rel="stylesheet">
<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
<style>
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
    --border: rgba(200, 134, 10, .1);
    --bh: rgba(200, 134, 10, .18);
    --tx: #0d0b08;
    --tx2: #6b5a3e;
    --tx3: #a89880;
    --shadow: 0 8px 40px rgba(0, 0, 0, .08);
    --shadow-lg: 0 20px 64px rgba(0, 0, 0, .12);
    --r-xl: 28px;
}

body.dm {
    --bg: #060c1a;
    --bg2: #0d1626;
    --surface: #111928;
    --s2: #172034;
    --border: rgba(255,255,255,.06);
    --bh: rgba(255,255,255,.12);
    --tx: #e0e8ff;
    --tx2: #8898cc;
    --tx3: #3a4a70;
}

*, *::before, *::after {
    box-sizing: border-box;
    margin: 0;
    padding: 0;
}

body {
    font-family: 'DM Sans', sans-serif;
    background: var(--bg);
    color: var(--tx);
    overflow-x: hidden;
    min-height: 100vh;
}

.header {
    position: sticky;
    top: 0;
    z-index: 800;
    height: 68px;
    background: rgba(248, 244, 238, .94);
    backdrop-filter: blur(28px);
    border-bottom: 1px solid var(--border);
}

body.dm .header {
    background: rgba(6, 12, 26, .94);
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
    width: 40px;
    height: 40px;
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

.main-container {
    max-width: 1200px;
    margin: 40px auto;
    padding: 0 24px;
}

.profile-grid {
    display: grid;
    grid-template-columns: 360px 1fr;
    gap: 32px;
}

.profile-card {
    background: var(--surface);
    border-radius: var(--r-xl);
    border: 1.5px solid var(--border);
    overflow: hidden;
    position: sticky;
    top: 88px;
}

.avatar-section {
    text-align: center;
    padding: 32px 24px;
    background: linear-gradient(135deg, var(--blue2), var(--blue));
    position: relative;
}

.avatar-wrapper {
    position: relative;
    width: 140px;
    height: 140px;
    margin: 0 auto;
}

.avatar-img {
    width: 100%;
    height: 100%;
    border-radius: 50%;
    object-fit: cover;
    border: 4px solid rgba(255, 255, 255, .3);
    background: var(--surface);
}

.avatar-placeholder {
    width: 100%;
    height: 100%;
    border-radius: 50%;
    background: linear-gradient(135deg, var(--gold), var(--gold2));
    display: flex;
    align-items: center;
    justify-content: center;
    font-family: 'Syne', sans-serif;
    font-size: 48px;
    font-weight: 800;
    color: #fff;
    border: 4px solid rgba(255, 255, 255, .3);
}

.change-photo-btn {
    position: absolute;
    bottom: 5px;
    right: 5px;
    width: 36px;
    height: 36px;
    border-radius: 50%;
    background: var(--surface);
    border: 1.5px solid var(--border);
    display: flex;
    align-items: center;
    justify-content: center;
    cursor: pointer;
    color: var(--blue);
    transition: all .2s;
}

.change-photo-btn:hover {
    background: var(--blue);
    color: white;
    transform: scale(1.1);
}

.profile-name {
    font-family: 'Syne', sans-serif;
    font-size: 22px;
    font-weight: 700;
    color: #fff;
    margin: 16px 0 4px;
}

.profile-username {
    font-size: 13px;
    color: rgba(255, 255, 255, .7);
}

.profile-stats {
    display: flex;
    justify-content: space-around;
    padding: 20px 24px;
    background: var(--s2);
    border-bottom: 1.5px solid var(--border);
}

.stat-item {
    text-align: center;
}

.stat-value {
    font-family: 'Syne', sans-serif;
    font-size: 20px;
    font-weight: 800;
    color: var(--tx);
}

.stat-label {
    font-size: 10.5px;
    color: var(--tx3);
    margin-top: 4px;
}

.profile-info {
    padding: 20px 24px;
}

.info-row {
    display: flex;
    align-items: center;
    gap: 12px;
    margin-bottom: 16px;
    padding: 8px 0;
    border-bottom: 1px solid var(--border);
}

.info-row i {
    width: 20px;
    color: var(--gold);
    font-size: 14px;
}

.info-row .label {
    font-size: 12px;
    color: var(--tx3);
    width: 80px;
}

.info-row .value {
    flex: 1;
    font-size: 13px;
    color: var(--tx);
}

.settings-card {
    background: var(--surface);
    border-radius: var(--r-xl);
    border: 1.5px solid var(--border);
    overflow: hidden;
}

.card-header {
    display: flex;
    align-items: center;
    gap: 12px;
    padding: 20px 24px;
    background: var(--s2);
    border-bottom: 1.5px solid var(--border);
}

.card-header i {
    width: 32px;
    height: 32px;
    display: flex;
    align-items: center;
    justify-content: center;
    border-radius: 10px;
    background: var(--blue-pale);
    color: var(--blue);
    font-size: 14px;
}

.card-header h2 {
    font-family: 'Syne', sans-serif;
    font-size: 18px;
    font-weight: 700;
    color: var(--tx);
}

.card-header p {
    font-size: 12px;
    color: var(--tx3);
    margin-top: 2px;
}

.card-body {
    padding: 24px;
}

.form-group {
    margin-bottom: 20px;
}

.form-group label {
    display: block;
    font-size: 12px;
    font-weight: 600;
    color: var(--tx2);
    margin-bottom: 6px;
}

.form-group label i {
    margin-right: 6px;
    color: var(--gold);
    font-size: 11px;
}

.form-control {
    width: 100%;
    padding: 12px 14px;
    border: 1.5px solid var(--border);
    border-radius: 12px;
    font-family: 'DM Sans', sans-serif;
    font-size: 14px;
    color: var(--tx);
    background: var(--bg);
    transition: all .2s;
}

.form-control:focus {
    outline: none;
    border-color: var(--blue);
    box-shadow: 0 0 0 3px rgba(31, 82, 212, .1);
}

textarea.form-control {
    resize: vertical;
    min-height: 80px;
}

.form-row-2 {
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: 16px;
}

.btn {
    padding: 12px 24px;
    border-radius: 12px;
    font-family: 'Syne', sans-serif;
    font-weight: 700;
    font-size: 13px;
    cursor: pointer;
    border: none;
    transition: all .2s;
}

.btn-primary {
    background: linear-gradient(115deg, var(--blue2), var(--blue));
    color: #fff;
    box-shadow: 0 4px 14px rgba(31, 82, 212, .3);
}

.btn-primary:hover {
    transform: translateY(-2px);
    box-shadow: 0 6px 20px rgba(31, 82, 212, .4);
}

.form-actions {
    display: flex;
    gap: 12px;
    justify-content: flex-end;
    margin-top: 24px;
}

.alert {
    padding: 14px 18px;
    border-radius: 14px;
    margin-bottom: 24px;
    display: flex;
    align-items: center;
    gap: 10px;
    font-size: 13px;
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

.alert-close {
    margin-left: auto;
    background: none;
    border: none;
    cursor: pointer;
    font-size: 18px;
    color: inherit;
    opacity: .5;
}

.toast-container {
    position: fixed;
    bottom: 24px;
    right: 24px;
    z-index: 9999;
    display: flex;
    flex-direction: column;
    gap: 8px;
}

.toast {
    background: var(--surface);
    border: 1.5px solid var(--border);
    border-left: 3px solid var(--emerald);
    border-radius: 12px;
    padding: 12px 18px;
    display: flex;
    align-items: center;
    gap: 10px;
    box-shadow: var(--shadow-lg);
    animation: slideIn 0.3s ease;
    font-size: 13px;
    color: var(--tx2);
}

@keyframes slideIn {
    from {
        opacity: 0;
        transform: translateX(100px);
    }
    to {
        opacity: 1;
        transform: translateX(0);
    }
}

.modal-overlay {
    display: none;
    position: fixed;
    top: 0;
    left: 0;
    width: 100%;
    height: 100%;
    background: rgba(0, 0, 0, .7);
    backdrop-filter: blur(8px);
    z-index: 10000;
    align-items: center;
    justify-content: center;
}

.modal-overlay.active {
    display: flex;
}

.modal-content {
    background: var(--surface);
    border-radius: 24px;
    width: 400px;
    max-width: 90%;
    padding: 28px;
    animation: modalIn 0.3s ease;
}

@keyframes modalIn {
    from {
        opacity: 0;
        transform: scale(0.95);
    }
    to {
        opacity: 1;
        transform: scale(1);
    }
}

.modal-content h3 {
    font-family: 'Syne', sans-serif;
    font-size: 18px;
    margin-bottom: 16px;
    text-align: center;
}

.modal-actions {
    display: flex;
    gap: 12px;
    margin-top: 24px;
}

@media (max-width: 900px) {
    .profile-grid {
        grid-template-columns: 1fr;
    }
    .profile-card {
        position: static;
    }
    .header-inner {
        padding: 0 18px;
    }
    .main-container {
        padding: 20px 16px;
    }
}

@media (max-width: 560px) {
    .form-row-2 {
        grid-template-columns: 1fr;
    }
}
</style>
</head>
<body id="body">

<header class="header">
    <div class="header-inner">
        <a href="<%= request.getContextPath() %>/immo/index.jsp" class="logo">
            <svg class="logo-svg" viewBox="0 0 54 54" fill="none">
                <defs>
                    <linearGradient id="hg" x1="0%" y1="0%" x2="100%" y2="100%">
                        <stop offset="0%" stop-color="#FFD060"/>
                        <stop offset="50%" stop-color="#F59E0B"/>
                        <stop offset="100%" stop-color="#B45309"/>
                    </linearGradient>
                    <linearGradient id="rg" x1="0%" y1="0%" x2="100%" y2="100%">
                        <stop offset="0%" stop-color="#FDE68A"/>
                        <stop offset="100%" stop-color="#D97706"/>
                    </linearGradient>
                </defs>
                <circle cx="27" cy="27" r="25" fill="rgba(31,82,212,.1)" stroke="rgba(31,82,212,.22)" stroke-width="1.5"/>
                <rect x="13" y="28" width="28" height="18" rx="2" fill="url(#hg)"/>
                <polygon points="10,29 27,12 44,29" fill="url(#rg)"/>
                <rect x="22" y="35" width="10" height="11" rx="5" fill="rgba(14,45,130,.58)"/>
                <rect x="14" y="31" width="7" height="6" rx="1.5" fill="rgba(180,220,255,.85)"/>
                <rect x="33" y="31" width="7" height="6" rx="1.5" fill="rgba(180,220,255,.85)"/>
            </svg>
            <div>
                <div class="logo-name">Fredon</div>
                <div class="logo-sub">Mon profil</div>
            </div>
        </a>
        <a href="<%= request.getContextPath() %>/immo/index.jsp" style="color: var(--tx2); text-decoration: none;">
            <i class="fas fa-arrow-left"></i> Retour à l'accueil
        </a>
    </div>
</header>

<main class="main-container">
    <% if (successMessage != null) { %>
    <div class="alert alert-success">
        <i class="fas fa-check-circle"></i> <%= successMessage %>
        <button class="alert-close" onclick="this.parentElement.remove()">×</button>
    </div>
    <% } %>
    <% if (errorMessage != null) { %>
    <div class="alert alert-error">
        <i class="fas fa-exclamation-triangle"></i> <%= errorMessage %>
        <button class="alert-close" onclick="this.parentElement.remove()">×</button>
    </div>
    <% } %>

    <div class="profile-grid">
        <!-- Colonne gauche : Carte de profil -->
        <div class="profile-card">
            <div class="avatar-section">
                <div class="avatar-wrapper">
                    <% if (profilePic != null && !profilePic.isEmpty()) { %>
                        <img id="profileAvatar" src="<%= request.getContextPath() %>/uploads/<%= profilePic %>" alt="Avatar" class="avatar-img">
                    <% } else { %>
                        <div id="profileAvatar" class="avatar-placeholder"><%= userInitial %></div>
                    <% } %>
                    <button class="change-photo-btn" onclick="openPhotoModal()">
                        <i class="fas fa-camera"></i>
                    </button>
                </div>
                <h2 class="profile-name"><%= displayName %></h2>
                <div class="profile-username">@<%= currentUser.getUsername() %></div>
            </div>
            
            <div class="profile-stats">
                <div class="stat-item">
                    <div class="stat-value"><%= favoritesCount %></div>
                    <div class="stat-label">Favoris</div>
                </div>
                <div class="stat-item">
                    <div class="stat-value"><%= messagesCount %></div>
                    <div class="stat-label">Messages</div>
                </div>
                <div class="stat-item">
                    <div class="stat-value">—</div>
                    <div class="stat-label">Biens contactés</div>
                </div>
            </div>
            
            <div class="profile-info">
                <div class="info-row">
                    <i class="fas fa-envelope"></i>
                    <span class="label">Email</span>
                    <span class="value"><%= userEmail %></span>
                </div>
                <div class="info-row">
                    <i class="fas fa-phone"></i>
                    <span class="label">Téléphone</span>
                    <span class="value"><%= userPhone.isEmpty() ? "Non renseigné" : userPhone %></span>
                </div>
                <div class="info-row">
                    <i class="fas fa-calendar-alt"></i>
                    <span class="label">Membre depuis</span>
                    <span class="value"><%= memberSince.isEmpty() ? "—" : memberSince %></span>
                </div>
                <div class="info-row">
                    <i class="fas fa-id-card"></i>
                    <span class="label">Rôle</span>
                    <span class="value"><%= "admin".equals(currentUser.getRole()) ? "Administrateur" : "Client" %></span>
                </div>
            </div>
        </div>

        <!-- Colonne droite : Formulaire de modification -->
        <div class="settings-card">
            <div class="card-header">
                <i class="fas fa-user-edit"></i>
                <div>
                    <h2>Modifier mon profil</h2>
                    <p>Mettez à jour vos informations personnelles</p>
                </div>
            </div>
            <form method="POST" action="<%= request.getContextPath() %>/profile.jsp" id="profileForm">
                <input type="hidden" name="action" value="updateProfile">
                <div class="card-body">
                    <div class="form-group">
                        <label><i class="fas fa-user"></i> Nom d'affichage</label>
                        <input type="text" name="displayName" class="form-control" value="<%= displayName %>" required>
                    </div>
                    <div class="form-row-2">
                        <div class="form-group">
                            <label><i class="fas fa-envelope"></i> Adresse email</label>
                            <input type="email" name="email" class="form-control" value="<%= userEmail %>" required>
                        </div>
                        <div class="form-group">
                            <label><i class="fas fa-phone"></i> Téléphone</label>
                            <input type="tel" name="phone" class="form-control" value="<%= userPhone %>" placeholder="+261 XX XXX XX">
                        </div>
                    </div>
                    <div class="form-group">
                        <label><i class="fas fa-info-circle"></i> Bio / À propos</label>
                        <textarea name="bio" class="form-control" placeholder="Parlez-nous un peu de vous..."><%= userBio %></textarea>
                    </div>
                    <div class="form-actions">
                        <button type="submit" class="btn btn-primary">
                            <i class="fas fa-save"></i> Enregistrer les modifications
                        </button>
                    </div>
                </div>
            </form>
        </div>
    </div>
</main>

<!-- Modal changement photo -->
<div id="photoModal" class="modal-overlay">
    <div class="modal-content">
        <h3><i class="fas fa-camera"></i> Changer ma photo</h3>
        <form id="photoForm" method="POST" action="<%= request.getContextPath() %>/uploadProfilePic" enctype="multipart/form-data">
            <div class="form-group">
                <label>Sélectionner une image</label>
                <input type="file" name="profilePic" accept="image/*" class="form-control" required>
            </div>
            <div class="modal-actions">
                <button type="submit" class="btn btn-primary">Télécharger</button>
                <button type="button" class="btn" style="background: var(--s2); border: 1px solid var(--border);" onclick="closePhotoModal()">Annuler</button>
            </div>
        </form>
    </div>
</div>

<div class="toast-container" id="toastContainer"></div>

<script>
// Thème
const KEY = 'fredon_theme';
let dark = localStorage.getItem(KEY) === 'dark';
function applyTheme() {
    const body = document.getElementById('body');
    if (dark) body.classList.add('dm');
    else body.classList.remove('dm');
}
applyTheme();

// Notifications
function showToast(message, isError) {
    const container = document.getElementById('toastContainer');
    const toast = document.createElement('div');
    toast.className = 'toast' + (isError ? ' error' : '');
    toast.innerHTML = `<i class="fas ${isError ? 'fa-exclamation-triangle' : 'fa-check-circle'}"></i><span>${message}</span>`;
    container.appendChild(toast);
    setTimeout(() => toast.remove(), 3000);
}

// Modales
function openPhotoModal() {
    document.getElementById('photoModal').classList.add('active');
}
function closePhotoModal() {
    document.getElementById('photoModal').classList.remove('active');
}

// Fermer modales en cliquant en dehors
document.querySelectorAll('.modal-overlay').forEach(modal => {
    modal.addEventListener('click', function(e) {
        if (e.target === this) this.classList.remove('active');
    });
});

// Fermer les alertes
document.querySelectorAll('.alert-close').forEach(btn => {
    btn.addEventListener('click', function() {
        this.parentElement.remove();
    });
});

// Auto-fermeture des alertes
setTimeout(() => {
    document.querySelectorAll('.alert').forEach(alert => alert.remove());
}, 5000);

// Message après changement de photo
const urlParams = new URLSearchParams(window.location.search);
if (urlParams.get('photo') === 'updated') {
    showToast('Photo de profil mise à jour !');
    setTimeout(() => location.href = '<%= request.getContextPath() %>/profile.jsp', 1500);
}

//Empêche l'accès aux pages après déconnexion
if (performance.navigation.type === 2) {
 window.location.href = '${pageContext.request.contextPath}/login';
}

</script>
</body>
</html>