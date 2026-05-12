<%@ page language="java" contentType="application/json; charset=UTF-8"
	pageEncoding="UTF-8"%>
<%@ page import="java.sql.*"%>

<%
String propertyIdStr = request.getParameter("propertyId");

response.setContentType("application/json");
response.setCharacterEncoding("UTF-8");

if (propertyIdStr == null || propertyIdStr.trim().isEmpty()) {
    out.print("{\"success\":false,\"error\":\"ID manquant\"}");
    return;
}

int propertyId = Integer.parseInt(propertyIdStr);
int views = 0;

String DB_URL = "jdbc:mysql://localhost:3306/quickchat";
String DB_USER = "root";
String DB_PASSWORD = "";

try {
    Class.forName("com.mysql.cj.jdbc.Driver");
    Connection conn = DriverManager.getConnection(DB_URL, DB_USER, DB_PASSWORD);
    
    // Incrémenter les vues
    PreparedStatement updateStmt = conn.prepareStatement("UPDATE properties SET views_count = views_count + 1 WHERE id = ?");
    updateStmt.setInt(1, propertyId);
    updateStmt.executeUpdate();
    updateStmt.close();
    
    // Récupérer le nouveau compteur
    PreparedStatement selectStmt = conn.prepareStatement("SELECT views_count FROM properties WHERE id = ?");
    selectStmt.setInt(1, propertyId);
    ResultSet rs = selectStmt.executeQuery();
    
    if (rs.next()) {
        views = rs.getInt("views_count");
    }
    
    rs.close();
    selectStmt.close();
    conn.close();
    
    out.print("{\"success\":true,\"views\":" + views + "}");
    
} catch (Exception e) {
    out.print("{\"success\":false,\"error\":\"" + e.getMessage().replace("\"", "\\\"") + "\"}");
}
%>