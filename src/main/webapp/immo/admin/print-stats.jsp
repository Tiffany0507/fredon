<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.*, java.text.*, java.math.*"%>
<%@ page import="java.sql.*"%>
<%@ page import="com.quickchat.utils.TranslateUtil"%>
<%
    String DB_URL = "jdbc:mysql://localhost:3306/quickchat";
    String DB_USER = "root";
    String DB_PASSWORD = "";
    
    // Récupérer toutes les statistiques
    int totalProperties = 0;
    int totalViews = 0;
    BigDecimal totalValue = BigDecimal.ZERO;
    BigDecimal averagePrice = BigDecimal.ZERO;
    int totalMessages = 0;
    int unreadMessages = 0;
    int activeProperties = 0;
    long totalCash = 0;
    int pendingAppointments = 0;
    int totalClients = 0;
    
    Map<String, Integer> propertiesByType = new LinkedHashMap<>();
    Map<String, Integer> monthlyAdditions = new LinkedHashMap<>();
    Map<String, Integer> monthlyMessages = new LinkedHashMap<>();
    List<Map<String, Object>> topProperties = new ArrayList<>();
    List<Map<String, Object>> reactionsSummary = new ArrayList<>();
    
    try {
        Class.forName("com.mysql.cj.jdbc.Driver");
        Connection conn = DriverManager.getConnection(DB_URL, DB_USER, DB_PASSWORD);
        
        // Stats globales
        String statsSql = "SELECT COUNT(*) as total, COALESCE(SUM(views_count),0) as total_views, COALESCE(SUM(price),0) as total_value, COALESCE(AVG(price),0) as avg_price FROM properties";
        try (Statement stmt = conn.createStatement(); ResultSet rs = stmt.executeQuery(statsSql)) {
            if (rs.next()) {
                totalProperties = rs.getInt("total");
                totalViews = rs.getInt("total_views");
                totalValue = rs.getBigDecimal("total_value");
                averagePrice = rs.getBigDecimal("avg_price");
            }
        }
        
        // Rendez-vous en attente
        String pendingSql = "SELECT COUNT(*) as count FROM appointments WHERE status = 'pending'";
        try (Statement stmt = conn.createStatement(); ResultSet rs = stmt.executeQuery(pendingSql)) {
            if (rs.next()) pendingAppointments = rs.getInt("count");
        }
        
        // Nombre de clients
        String clientsSql = "SELECT COUNT(*) as count FROM users WHERE role = 'client'";
        try (Statement stmt = conn.createStatement(); ResultSet rs = stmt.executeQuery(clientsSql)) {
            if (rs.next()) totalClients = rs.getInt("count");
        }
        
        // Répartition par type
        String typeSql = "SELECT type, COUNT(*) as count FROM properties GROUP BY type";
        try (Statement stmt = conn.createStatement(); ResultSet rs = stmt.executeQuery(typeSql)) {
            while (rs.next()) {
                propertiesByType.put(rs.getString("type"), rs.getInt("count"));
            }
        }
        
        // Messages
        String msgSql = "SELECT COUNT(*) as total, SUM(CASE WHEN is_read = 0 THEN 1 ELSE 0 END) as unread FROM messages WHERE receiver_id = ?";
        try (PreparedStatement pstmt = conn.prepareStatement(msgSql)) {
            pstmt.setInt(1, 9);
            ResultSet rs = pstmt.executeQuery();
            if (rs.next()) {
                totalMessages = rs.getInt("total");
                unreadMessages = rs.getInt("unread");
            }
            rs.close();
            pstmt.close();
        }
        
        // Top 5 biens
        String topSql = "SELECT id, title, location, type, price, views_count FROM properties ORDER BY views_count DESC LIMIT 5";
        try (Statement stmt = conn.createStatement(); ResultSet rs = stmt.executeQuery(topSql)) {
            while (rs.next()) {
                Map<String, Object> prop = new HashMap<>();
                prop.put("title", rs.getString("title"));
                prop.put("location", rs.getString("location"));
                prop.put("type", rs.getString("type"));
                prop.put("price", rs.getBigDecimal("price"));
                prop.put("views", rs.getInt("views_count"));
                topProperties.add(prop);
            }
        }
        
        // Réactions
        String reactionsSql = "SELECT p.id, p.title, p.location, " +
            "COALESCE((SELECT COUNT(*) FROM property_reactions WHERE property_id = p.id AND reaction_type = 'jadore'), 0) as jadore, " +
            "COALESCE((SELECT COUNT(*) FROM property_reactions WHERE property_id = p.id AND reaction_type = 'jaime'), 0) as jaime, " +
            "COALESCE((SELECT COUNT(*) FROM property_reactions WHERE property_id = p.id AND reaction_type = 'haha'), 0) as haha, " +
            "COALESCE((SELECT COUNT(*) FROM property_reactions WHERE property_id = p.id AND reaction_type = 'colere'), 0) as colere, " +
            "COALESCE((SELECT COUNT(*) FROM property_reactions WHERE property_id = p.id AND reaction_type = 'triste'), 0) as triste " +
            "FROM properties p ORDER BY (jadore + jaime + haha + colere + triste) DESC LIMIT 10";
        try (Statement stmt = conn.createStatement(); ResultSet rs = stmt.executeQuery(reactionsSql)) {
            while (rs.next()) {
                Map<String, Object> react = new HashMap<>();
                react.put("title", rs.getString("title"));
                react.put("location", rs.getString("location"));
                react.put("jadore", rs.getInt("jadore"));
                react.put("jaime", rs.getInt("jaime"));
                react.put("haha", rs.getInt("haha"));
                react.put("colere", rs.getInt("colere"));
                react.put("triste", rs.getInt("triste"));
                int total = rs.getInt("jadore") + rs.getInt("jaime") + rs.getInt("haha") + rs.getInt("colere") + rs.getInt("triste");
                react.put("total", total);
                reactionsSummary.add(react);
            }
        }
        
        // Évolution mensuelle
        SimpleDateFormat monthFormat = new SimpleDateFormat("MMM yyyy", Locale.FRENCH);
        Calendar cal = Calendar.getInstance();
        for (int i = 5; i >= 0; i--) {
            Calendar c = (Calendar) cal.clone();
            c.add(Calendar.MONTH, -i);
            String monthKey = monthFormat.format(c.getTime());
            monthlyAdditions.put(monthKey, 0);
            monthlyMessages.put(monthKey, 0);
        }
        
        String monthlySql = "SELECT DATE_FORMAT(created_at, '%b %Y') as month, COUNT(*) as count FROM properties WHERE created_at >= DATE_SUB(NOW(), INTERVAL 6 MONTH) GROUP BY DATE_FORMAT(created_at, '%b %Y')";
        try (Statement stmt = conn.createStatement(); ResultSet rs = stmt.executeQuery(monthlySql)) {
            while (rs.next()) {
                monthlyAdditions.put(rs.getString("month"), rs.getInt("count"));
            }
        }
        
        String msgMonthlySql = "SELECT DATE_FORMAT(created_at, '%b %Y') as month, COUNT(*) as count FROM messages WHERE receiver_id = 9 AND created_at >= DATE_SUB(NOW(), INTERVAL 6 MONTH) GROUP BY DATE_FORMAT(created_at, '%b %Y')";
        try (Statement stmt = conn.createStatement(); ResultSet rs = stmt.executeQuery(msgMonthlySql)) {
            while (rs.next()) {
                monthlyMessages.put(rs.getString("month"), rs.getInt("count"));
            }
        }
        
        // Caisse
        try {
            String cashSql = "SELECT total_cash FROM settings WHERE id = 1";
            Statement stmtCash = conn.createStatement();
            ResultSet rsCash = stmtCash.executeQuery(cashSql);
            if (rsCash.next()) {
                totalCash = rsCash.getLong("total_cash");
            }
            rsCash.close();
            stmtCash.close();
        } catch (Exception e) {}
        
        conn.close();
    } catch (Exception e) { 
        e.printStackTrace(); 
    }
    
    java.text.SimpleDateFormat sdf = new java.text.SimpleDateFormat("dd/MM/yyyy à HH:mm:ss");
    String currentDate = sdf.format(new java.util.Date());
%>
<!DOCTYPE html>
<html lang="fr">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Export Statistiques — Fredon Immobilier</title>
<link href="https://fonts.googleapis.com/css2?family=Syne:wght@400;600;700;800&family=DM+Sans:ital,opsz,wght@0,9..40,300;0,9..40,400;0,9..40,500;0,9..40,600;0,9..40,700&display=swap" rel="stylesheet">
<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css">
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
    --r-xl: 26px;
}
body {
    font-family: 'DM Sans', sans-serif;
    background: var(--bg);
    color: var(--dark);
    padding: 40px;
}
.print-container {
    max-width: 1400px;
    margin: 0 auto;
}
/* Header */
.print-header {
    background: linear-gradient(165deg, #0a1d58 0%, #1a3aaa 35%, #0e2d82 65%, #071545 100%);
    color: white;
    padding: 40px;
    border-radius: 28px;
    margin-bottom: 28px;
    text-align: center;
}
.print-header h1 {
    font-family: 'Syne', sans-serif;
    font-size: 32px;
    margin-bottom: 10px;
}
.print-header p {
    opacity: 0.8;
    font-size: 14px;
}
/* Stats grid */
.stats-row {
    display: grid;
    grid-template-columns: repeat(4, 1fr);
    gap: 18px;
    margin-bottom: 28px;
}
.stat-card {
    background: var(--white);
    border-radius: var(--r-xl);
    padding: 22px 20px;
    border: 1.5px solid rgba(200, 134, 10, .1);
    transition: transform .25s;
}
.sc-blue { background: linear-gradient(135deg, #e8eeff 0%, #f8faff 100%); }
.sc-gold { background: linear-gradient(135deg, #fff3d4 0%, #fffaf0 100%); }
.sc-teal { background: linear-gradient(135deg, #e0faf5 0%, #f4fffe 100%); }
.sc-rose { background: linear-gradient(135deg, #fde8ee 0%, #fff5f8 100%); }
.stat-top { display: flex; justify-content: space-between; align-items: flex-start; margin-bottom: 14px; }
.stat-ico { width: 46px; height: 46px; border-radius: 14px; display: flex; align-items: center; justify-content: center; font-size: 20px; }
.ico-blue { background: rgba(79, 126, 248, .15); color: var(--blue-light); }
.ico-gold { background: rgba(200, 134, 10, .15); color: var(--gold); }
.ico-teal { background: rgba(14, 158, 138, .15); color: var(--teal); }
.ico-rose { background: rgba(224, 48, 96, .15); color: var(--rose); }
.stat-badge { font-size: 10.5px; font-weight: 700; padding: 3px 9px; border-radius: 20px; background: rgba(16, 185, 129, .12); color: #059669; }
.stat-val { font-family: 'Syne', sans-serif; font-size: 34px; font-weight: 800; line-height: 1; margin-bottom: 5px; }
.val-blue { color: var(--blue); }
.val-gold { color: var(--gold); }
.val-teal { color: var(--teal); }
.val-rose { color: var(--rose); }
.stat-lbl { font-size: 12px; color: var(--soft); font-weight: 500; }
/* Charts grid */
.charts-grid {
    display: grid;
    grid-template-columns: repeat(2, 1fr);
    gap: 24px;
    margin-bottom: 28px;
}
.chart-card {
    background: var(--white);
    border-radius: var(--r-xl);
    padding: 24px;
    border: 1.5px solid rgba(200, 134, 10, .1);
}
.chart-title {
    font-family: 'Syne', sans-serif;
    font-size: 16px;
    font-weight: 700;
    margin-bottom: 20px;
    display: flex;
    align-items: center;
    gap: 8px;
}
/* Top card */
.top-card {
    background: var(--white);
    border-radius: var(--r-xl);
    padding: 24px;
    border: 1.5px solid rgba(200, 134, 10, .1);
    margin-bottom: 28px;
}
.top-title {
    font-family: 'Syne', sans-serif;
    font-size: 16px;
    font-weight: 700;
    margin-bottom: 20px;
    display: flex;
    align-items: center;
    gap: 8px;
}
.prop-list {
    display: flex;
    flex-direction: column;
    gap: 12px;
}
.prop-item {
    display: flex;
    align-items: center;
    gap: 15px;
    padding: 12px;
    background: var(--bg);
    border-radius: 12px;
}
.prop-rank {
    width: 36px;
    height: 36px;
    background: linear-gradient(135deg, var(--gold), var(--gold-light));
    border-radius: 10px;
    display: flex;
    align-items: center;
    justify-content: center;
    font-weight: 800;
    color: white;
}
.prop-info { flex: 1; }
.prop-title { font-weight: 700; margin-bottom: 4px; }
.prop-stats { font-size: 12px; color: var(--soft); }
.prop-views { font-weight: 800; color: var(--blue); }
/* Tableaux */
.data-table {
    width: 100%;
    border-collapse: collapse;
}
.data-table th, .data-table td {
    padding: 12px;
    text-align: left;
    border-bottom: 1px solid rgba(200, 134, 10, .1);
}
.data-table th {
    background: var(--bg);
    font-weight: 700;
    color: var(--blue);
}
.reaction-badge {
    display: inline-block;
    padding: 3px 8px;
    border-radius: 20px;
    font-size: 11px;
    font-weight: 600;
}
/* Footer */
.print-footer {
    margin-top: 40px;
    padding: 20px;
    text-align: center;
    border-top: 1px solid rgba(200, 134, 10, .2);
    color: var(--soft);
    font-size: 12px;
}
/* Bouton impression */
.print-button {
    position: fixed;
    bottom: 20px;
    right: 20px;
    background: linear-gradient(135deg, #dc2626, #b91c1c);
    color: white;
    border: none;
    padding: 12px 24px;
    border-radius: 40px;
    cursor: pointer;
    font-weight: 700;
    font-family: 'Syne', sans-serif;
    box-shadow: 0 4px 15px rgba(0,0,0,0.2);
    z-index: 1000;
    display: flex;
    align-items: center;
    gap: 8px;
}
.print-button:hover {
    transform: scale(1.02);
}
/* Impression */
@media print {
    body {
        background: white;
        padding: 0;
        margin: 0;
    }
    .print-button {
        display: none;
    }
    .stat-card, .chart-card, .top-card {
        break-inside: avoid;
        page-break-inside: avoid;
    }
    .stats-row {
        break-inside: avoid;
    }
}
</style>
</head>
<body>
<button class="print-button" onclick="window.print()">
    <i class="fas fa-print"></i> Imprimer / Sauvegarder PDF
</button>

<div class="print-container">
    <!-- Header -->
    <div class="print-header">
        <h1>🏠 Fredon Immobilier</h1>
        <p>Rapport statistique complet - Généré le <%= currentDate %></p>
        <p style="font-size: 12px; margin-top: 8px;">Mahajanga, Madagascar</p>
    </div>

    <!-- Stats Row -->
    <div class="stats-row">
        <div class="stat-card sc-blue">
            <div class="stat-top"><div class="stat-ico ico-blue"><i class="fas fa-home"></i></div><span class="stat-badge">Total</span></div>
            <div class="stat-val val-blue"><%= totalProperties %></div>
            <div class="stat-lbl">Biens en ligne</div>
        </div>
        <div class="stat-card sc-gold">
            <div class="stat-top"><div class="stat-ico ico-gold"><i class="fas fa-eye"></i></div><span class="stat-badge">Vues</span></div>
            <div class="stat-val val-gold"><%= String.format("%,d", totalViews) %></div>
            <div class="stat-lbl">Vues totales</div>
        </div>
        <div class="stat-card sc-teal">
            <div class="stat-top"><div class="stat-ico ico-teal"><i class="fas fa-coins"></i></div><span class="stat-badge">💰 Caisse</span></div>
            <div class="stat-val val-teal"><%= String.format("%,.0f", (double) totalCash) %> Ar</div>
            <div class="stat-lbl">Caisse totale (ventes)</div>
        </div>
        
    </div>

    <!-- Charts Grid -->
    <div class="charts-grid">
        <div class="chart-card">
            <div class="chart-title"><i class="fas fa-chart-line" style="color: var(--blue);"></i> Évolution mensuelle (6 mois)</div>
            <table class="data-table">
                <thead><tr><th>Mois</th><th>Ajouts</th></tr></thead>
                <tbody>
                    <% for (Map.Entry<String, Integer> entry : monthlyAdditions.entrySet()) { %>
                    <tr><td><%= entry.getKey() %></td><td><strong><%= entry.getValue() %></strong> bien(s)</td></tr>
                    <% } %>
                </tbody>
            </table>
        </div>
        <div class="chart-card">
            <div class="chart-title"><i class="fas fa-chart-pie" style="color: var(--gold);"></i> Répartition par type</div>
            <table class="data-table">
                <thead><tr><th>Type</th><th>Nombre</th><th>%</th></tr></thead>
                <tbody>
                    <% for (Map.Entry<String, Integer> entry : propertiesByType.entrySet()) { 
                        int percent = totalProperties > 0 ? (entry.getValue() * 100 / totalProperties) : 0;
                    %>
                    <tr><td><%= entry.getKey() %></td><td><%= entry.getValue() %></td><td><%= percent %>%</td></tr>
                    <% } %>
                </tbody>
            </table>
        </div>
    </div>

    <!-- Top 5 Properties -->
    <div class="top-card">
        <div class="top-title"><i class="fas fa-trophy" style="color: var(--gold);"></i> Top 5 des biens les plus consultés</div>
        <div class="prop-list">
            <% int rank = 1; for (Map<String, Object> prop : topProperties) { %>
            <div class="prop-item">
                <div class="prop-rank"><%= rank++ %></div>
                <div class="prop-info">
                    <div class="prop-title"><%= prop.get("title") %></div>
                    <div class="prop-stats"><i class="fas fa-map-marker-alt"></i> <%= prop.get("location") %> &nbsp;|&nbsp; <i class="fas fa-tag"></i> <%= prop.get("type") %></div>
                </div>
                <div class="prop-views"><i class="fas fa-eye"></i> <%= prop.get("views") %> vues</div>
            </div>
            <% } %>
        </div>
    </div>

    <!-- Réactions -->
    <div class="top-card">
        <div class="top-title"><i class="fas fa-heart" style="color: var(--rose);"></i> Réactions des clients</div>
        <table class="data-table">
            <thead>
                <tr>
                    <th>Bien</th>
                    <th style="text-align: center;">❤️</th>
                    <th style="text-align: center;">👍</th>
                    <th style="text-align: center;">😂</th>
                    <th style="text-align: center;">😡</th>
                    <th style="text-align: center;">😢</th>
                    <th style="text-align: center;">Total</th>
                </tr>
            </thead>
            <tbody>
                <% for (Map<String, Object> react : reactionsSummary) { %>
                <tr>
                    <td><strong><%= react.get("title") %></strong><br><small><%= react.get("location") %></small></td>
                    <td style="text-align: center; color: #e03060;"><%= react.get("jadore") %></td>
                    <td style="text-align: center; color: #1f52d4;"><%= react.get("jaime") %></td>
                    <td style="text-align: center; color: #c8860a;"><%= react.get("haha") %></td>
                    <td style="text-align: center; color: #dc2626;"><%= react.get("colere") %></td>
                    <td style="text-align: center; color: #6b5a3e;"><%= react.get("triste") %></td>
                    <td style="text-align: center; font-weight: bold;"><%= react.get("total") %></td>
                </tr>
                <% } %>
            </tbody>
        </table>
    </div>

    <!-- Résumé financier -->
    <div class="top-card">
        <div class="top-title"><i class="fas fa-chart-simple" style="color: var(--purple);"></i> Résumé financier</div>
        <div style="display: grid; grid-template-columns: repeat(3, 1fr); gap: 20px;">
            <div style="text-align: center; padding: 15px; background: var(--bg); border-radius: 16px;">
                <div style="font-family: 'Syne', sans-serif; font-size: 24px; font-weight: 800; color: var(--gold);"><%= String.format("%,.0f", totalValue) %> Ar</div>
                <div style="font-size: 12px; color: var(--soft);">Valeur du portefeuille</div>
            </div>
            <div style="text-align: center; padding: 15px; background: var(--bg); border-radius: 16px;">
                <div style="font-family: 'Syne', sans-serif; font-size: 24px; font-weight: 800; color: var(--teal);"><%= totalProperties > 0 ? String.format("%.1f", (double) totalViews / totalProperties) : 0 %></div>
                <div style="font-size: 12px; color: var(--soft);">Vues par bien</div>
            </div>
            <div style="text-align: center; padding: 15px; background: var(--bg); border-radius: 16px;">
                <div style="font-family: 'Syne', sans-serif; font-size: 24px; font-weight: 800; color: var(--blue);"><%= String.format("%,.0f", averagePrice) %> Ar</div>
                <div style="font-size: 12px; color: var(--soft);">Prix moyen</div>
            </div>
        </div>
    </div>

    <!-- Footer -->
    <div class="print-footer">
        <p>Fredon Immobilier - Rapport généré le <%= currentDate %></p>
        <p>Tous droits réservés | Mahajanga, Madagascar</p>
    </div>
</div>

<script>
    console.log('Rapport généré le <%= currentDate %>');
  
 // Empêche l'accès aux pages après déconnexion
 if (performance.navigation.type === 2) {
     window.location.href = '${pageContext.request.contextPath}/login';
 }

</script>
</body>
</html>