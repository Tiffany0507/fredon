<%@ page language="java" contentType="application/json; charset=UTF-8" pageEncoding="UTF-8" import="java.sql.*" %>
<%@ page import="com.quickchat.model.User" %>
<%
response.setContentType("application/json");
response.setCharacterEncoding("UTF-8");

String propertyIdStr = request.getParameter("propertyId");
String reactionType = request.getParameter("reactionType");

if(propertyIdStr == null || propertyIdStr.trim().isEmpty()) {
    out.print("{\"success\":false,\"error\":\"propertyId manquant\"}");
    return;
}
if(reactionType == null || reactionType.trim().isEmpty()) {
    out.print("{\"success\":false,\"error\":\"reactionType manquant\"}");
    return;
}

int propertyId = Integer.parseInt(propertyIdStr);

// ✅ Récupérer l'utilisateur connecté
User currentUser = (User) session.getAttribute("user");
Integer userId = null;
String userName = null;
String userEmail = null;

if(currentUser != null) {
    userId = currentUser.getId();
    userName = currentUser.getDisplayName();
    if(userName == null || userName.isEmpty()) {
        userName = currentUser.getUsername();
    }
    userEmail = currentUser.getEmail();
}

String DB_URL = "jdbc:mysql://localhost:3306/quickchat";
String DB_USER = "root";
String DB_PASSWORD = "";

try {
    Class.forName("com.mysql.cj.jdbc.Driver");
    Connection conn = DriverManager.getConnection(DB_URL, DB_USER, DB_PASSWORD);
    
    boolean isNewReaction = true;
    
    if(userId != null) {
        // ✅ Utilisateur connecté : vérifier s'il a déjà cette réaction
        PreparedStatement checkStmt = conn.prepareStatement(
            "SELECT id FROM property_reactions WHERE property_id = ? AND user_id = ? AND reaction_type = ?"
        );
        checkStmt.setInt(1, propertyId);
        checkStmt.setInt(2, userId);
        checkStmt.setString(3, reactionType);
        ResultSet rs = checkStmt.executeQuery();
        
        if(rs.next()) {
            // ✅ Déjà cette réaction → on la supprime (toggle)
            PreparedStatement deleteStmt = conn.prepareStatement(
                "DELETE FROM property_reactions WHERE property_id = ? AND user_id = ? AND reaction_type = ?"
            );
            deleteStmt.setInt(1, propertyId);
            deleteStmt.setInt(2, userId);
            deleteStmt.setString(3, reactionType);
            deleteStmt.executeUpdate();
            deleteStmt.close();
            isNewReaction = false;
        } else {
            // ✅ Supprimer les AUTRES réactions de l'utilisateur sur ce bien
            PreparedStatement deleteOthersStmt = conn.prepareStatement(
                "DELETE FROM property_reactions WHERE property_id = ? AND user_id = ?"
            );
            deleteOthersStmt.setInt(1, propertyId);
            deleteOthersStmt.setInt(2, userId);
            deleteOthersStmt.executeUpdate();
            deleteOthersStmt.close();
            
            // ✅ Ajouter la nouvelle réaction
            PreparedStatement insertStmt = conn.prepareStatement(
                "INSERT INTO property_reactions (property_id, user_id, visitor_identifier, reaction_type, created_at) VALUES (?, ?, ?, ?, NOW())"
            );
            insertStmt.setInt(1, propertyId);
            insertStmt.setInt(2, userId);
            insertStmt.setString(3, userName);
            insertStmt.setString(4, reactionType);
            insertStmt.executeUpdate();
            insertStmt.close();
        }
        rs.close();
        checkStmt.close();
    } else {
        // ✅ Visiteur non connecté
        String visitorIdentifier = session.getId();
        String userAgent = request.getHeader("User-Agent");
        String ip = request.getRemoteAddr();
        if(userAgent != null) {
            visitorIdentifier = Integer.toHexString((visitorIdentifier + userAgent + ip).hashCode());
        }
        
        // Vérifier si le visiteur a déjà cette réaction
        PreparedStatement checkStmt = conn.prepareStatement(
            "SELECT id FROM property_reactions WHERE property_id = ? AND visitor_identifier = ? AND reaction_type = ?"
        );
        checkStmt.setInt(1, propertyId);
        checkStmt.setString(2, visitorIdentifier);
        checkStmt.setString(3, reactionType);
        ResultSet rs = checkStmt.executeQuery();
        
        if(rs.next()) {
            // Déjà cette réaction → on la supprime
            PreparedStatement deleteStmt = conn.prepareStatement(
                "DELETE FROM property_reactions WHERE property_id = ? AND visitor_identifier = ? AND reaction_type = ?"
            );
            deleteStmt.setInt(1, propertyId);
            deleteStmt.setString(2, visitorIdentifier);
            deleteStmt.setString(3, reactionType);
            deleteStmt.executeUpdate();
            deleteStmt.close();
            isNewReaction = false;
        } else {
            // Supprimer les AUTRES réactions du visiteur
            PreparedStatement deleteOthersStmt = conn.prepareStatement(
                "DELETE FROM property_reactions WHERE property_id = ? AND visitor_identifier = ?"
            );
            deleteOthersStmt.setInt(1, propertyId);
            deleteOthersStmt.setString(2, visitorIdentifier);
            deleteOthersStmt.executeUpdate();
            deleteOthersStmt.close();
            
            // Ajouter la nouvelle réaction
            PreparedStatement insertStmt = conn.prepareStatement(
                "INSERT INTO property_reactions (property_id, visitor_identifier, reaction_type, created_at) VALUES (?, ?, ?, NOW())"
            );
            insertStmt.setInt(1, propertyId);
            insertStmt.setString(2, visitorIdentifier);
            insertStmt.setString(3, reactionType);
            insertStmt.executeUpdate();
            insertStmt.close();
        }
        rs.close();
        checkStmt.close();
    }
    
    // Récupérer les compteurs mis à jour
    String[] types = {"jadore", "jaime", "haha", "colere", "triste"};
    StringBuilder countsJson = new StringBuilder();
    countsJson.append("{");
    
    for(int i = 0; i < types.length; i++) {
        String type = types[i];
        PreparedStatement countStmt = conn.prepareStatement(
            "SELECT COUNT(*) as cnt FROM property_reactions WHERE property_id = ? AND reaction_type = ?"
        );
        countStmt.setInt(1, propertyId);
        countStmt.setString(2, type);
        ResultSet rs = countStmt.executeQuery();
        int count = 0;
        if(rs.next()) {
            count = rs.getInt("cnt");
        }
        rs.close();
        countStmt.close();
        
        if(i > 0) countsJson.append(",");
        countsJson.append("\"").append(type).append("\":").append(count);
    }
    countsJson.append("}");
    
    conn.close();
    
    out.print("{\"success\":true,\"isNew\":" + isNewReaction + ",\"counts\":" + countsJson.toString() + "}");
    
} catch(Exception e) {
    e.printStackTrace();
    out.print("{\"success\":false,\"error\":\"" + e.getMessage().replace("\"", "\\\"") + "\"}");
}
%>