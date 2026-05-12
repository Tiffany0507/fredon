<%@ page language="java" contentType="text/html; charset=UTF-8"
	pageEncoding="UTF-8"%>
<%@ page import="java.sql.*"%>
<%@ page import="com.quickchat.utils.NotificationHelper"%>

<%
String DB_URL = "jdbc:mysql://localhost:3306/quickchat";
String DB_USER = "root";
String DB_PASSWORD = "";

String propertyId = request.getParameter("propertyId");
String visitorName = request.getParameter("visitorName");
String visitorEmail = request.getParameter("visitorEmail");
String content = request.getParameter("content");

if (propertyId != null && visitorName != null && content != null && 
    !propertyId.trim().isEmpty() && !visitorName.trim().isEmpty() && !content.trim().isEmpty()) {
    
    Connection conn = null;
    PreparedStatement pstmt = null;
    String propertyTitle = "";
    
    try {
        Class.forName("com.mysql.cj.jdbc.Driver");
        conn = DriverManager.getConnection(DB_URL, DB_USER, DB_PASSWORD);
        
        // Récupérer le titre du bien pour la notification
        PreparedStatement pstmtTitle = conn.prepareStatement("SELECT title FROM properties WHERE id = ?");
        pstmtTitle.setInt(1, Integer.parseInt(propertyId));
        ResultSet rsTitle = pstmtTitle.executeQuery();
        if (rsTitle.next()) {
            propertyTitle = rsTitle.getString("title");
        }
        rsTitle.close();
        pstmtTitle.close();
        
        String sql = "INSERT INTO comments (property_id, visitor_name, visitor_email, content, is_approved, created_at) VALUES (?, ?, ?, ?, 1, NOW())";
        pstmt = conn.prepareStatement(sql);
        pstmt.setInt(1, Integer.parseInt(propertyId));
        pstmt.setString(2, visitorName.trim());
        pstmt.setString(3, visitorEmail != null ? visitorEmail.trim() : "");
        pstmt.setString(4, content.trim());
        
        pstmt.executeUpdate();
        
        // 🔔 ENVOYER UNE NOTIFICATION À L'ADMIN (ID 1)
        NotificationHelper.notifyNewComment(1, propertyTitle, visitorName);
        
    } catch (Exception e) {
        e.printStackTrace();
    } finally {
        if (pstmt != null) try { pstmt.close(); } catch(Exception e) {}
        if (conn != null) try { conn.close(); } catch(Exception e) {}
    }
}

// Rediriger vers la page de détail
response.sendRedirect("property-detail.jsp?id=" + propertyId);
%>