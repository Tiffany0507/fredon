<%@ page language="java" contentType="application/json; charset=UTF-8"
	pageEncoding="UTF-8"%>
<%@ page import="java.sql.*, java.util.*"%>
<%@ page
	import="com.immobilier.model.Property, com.immobilier.model.PropertyImage"%>
<%@ page
	import="com.immobilier.dao.PropertyDAO, com.immobilier.dao.PropertyImageDAO"%>

<%!
// Fonction pour échapper les caractères JSON
String escapeJson(String str) {
    if (str == null) return "";
    return str.replace("\\", "\\\\")
              .replace("\"", "\\\"")
              .replace("\n", "\\n")
              .replace("\r", "\\r")
              .replace("\t", "\\t");
}
%>

<%
String DB_URL = "jdbc:mysql://localhost:3306/quickchat";
String DB_USER = "root";
String DB_PASSWORD = "";

String budgetMinStr = request.getParameter("budgetMin");
String budgetMaxStr = request.getParameter("budgetMax");
String typeFilter = request.getParameter("type");

long budgetMin = 0;
long budgetMax = Long.MAX_VALUE;

if (budgetMinStr != null && !budgetMinStr.trim().isEmpty()) {
    try {
        budgetMin = Long.parseLong(budgetMinStr);
    } catch (NumberFormatException e) {}
}

if (budgetMaxStr != null && !budgetMaxStr.trim().isEmpty()) {
    try {
        budgetMax = Long.parseLong(budgetMaxStr);
    } catch (NumberFormatException e) {}
}

if (typeFilter == null || typeFilter.trim().isEmpty()) {
    typeFilter = "all";
}

StringBuilder jsonBuilder = new StringBuilder();
Connection conn = null;
PreparedStatement pstmt = null;
ResultSet rs = null;

try {
    Class.forName("com.mysql.cj.jdbc.Driver");
    conn = DriverManager.getConnection(DB_URL, DB_USER, DB_PASSWORD);
    
    // Construction de la requête SQL directe (sans DAO pour éviter les problèmes de types)
    String sql = "SELECT id, title, description, price, surface, rooms, bedrooms, bathrooms, location, type, latitude, longitude, created_at FROM properties WHERE (status != 'sold' OR status IS NULL) AND price >= ? AND price <= ?";
    List<Object> params = new ArrayList<>();
    params.add(budgetMin);
    params.add(budgetMax);
    
    if (!typeFilter.equals("all")) {
        sql += " AND type = ?";
        params.add(typeFilter);
    }
    
    sql += " ORDER BY created_at DESC";
    
    pstmt = conn.prepareStatement(sql);
    for (int i = 0; i < params.size(); i++) {
        if (params.get(i) instanceof Long) {
            pstmt.setLong(i + 1, (Long) params.get(i));
        } else {
            pstmt.setString(i + 1, (String) params.get(i));
        }
    }
    
    rs = pstmt.executeQuery();
    
    // Construction manuelle du JSON
    jsonBuilder.append("{\"properties\":[");
    
    int count = 0;
    while (rs.next()) {
        if (count > 0) {
            jsonBuilder.append(",");
        }
        
        int id = rs.getInt("id");
        String title = rs.getString("title");
        String description = rs.getString("description");
        long price = rs.getLong("price");
        int surface = rs.getInt("surface");
        int rooms = rs.getInt("rooms");
        int bedrooms = rs.getInt("bedrooms");
        int bathrooms = rs.getInt("bathrooms");
        String location = rs.getString("location");
        String type = rs.getString("type");
        
        // Récupérer l'image principale avec une requête séparée
        String imageUrl = "";
        PreparedStatement pstmtImg = conn.prepareStatement("SELECT image_url FROM property_images WHERE property_id = ? AND is_primary = 1 LIMIT 1");
        pstmtImg.setInt(1, id);
        ResultSet rsImg = pstmtImg.executeQuery();
        if (rsImg.next()) {
            imageUrl = rsImg.getString("image_url");
        }
        rsImg.close();
        pstmtImg.close();
        
        jsonBuilder.append("{");
        jsonBuilder.append("\"id\":").append(id).append(",");
        jsonBuilder.append("\"title\":\"").append(escapeJson(title)).append("\",");
        jsonBuilder.append("\"description\":\"").append(escapeJson(description)).append("\",");
        jsonBuilder.append("\"price\":").append(price).append(",");
        jsonBuilder.append("\"surface\":").append(surface).append(",");
        jsonBuilder.append("\"rooms\":").append(rooms).append(",");
        jsonBuilder.append("\"bedrooms\":").append(bedrooms).append(",");
        jsonBuilder.append("\"bathrooms\":").append(bathrooms).append(",");
        jsonBuilder.append("\"location\":\"").append(escapeJson(location)).append("\",");
        jsonBuilder.append("\"type\":\"").append(escapeJson(type)).append("\",");
        jsonBuilder.append("\"imageUrl\":\"").append(escapeJson(imageUrl)).append("\"");
        jsonBuilder.append("}");
        
        count++;
    }
    
    jsonBuilder.append("],");
    jsonBuilder.append("\"count\":").append(count);
    jsonBuilder.append("}");
    
} catch (Exception e) {
    e.printStackTrace();
    jsonBuilder = new StringBuilder();
    jsonBuilder.append("{\"properties\":[],\"count\":0,\"error\":\"").append(e.getMessage().replace("\"", "\\\"")).append("\"}");
} finally {
    if (rs != null) try { rs.close(); } catch(Exception e) {}
    if (pstmt != null) try { pstmt.close(); } catch(Exception e) {}
    if (conn != null) try { conn.close(); } catch(Exception e) {}
}

// Envoyer la réponse JSON
response.setContentType("application/json");
response.setCharacterEncoding("UTF-8");
out.print(jsonBuilder.toString());
%>