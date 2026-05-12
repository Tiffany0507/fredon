package com.quickchat.utils;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;

public class NotificationHelper {
    
    private static final String DB_URL = "jdbc:mysql://localhost:3306/quickchat";
    private static final String DB_USER = "root";
    private static final String DB_PASSWORD = "";
    
    public static void sendNotification(int userId, String type, String title, String message, String link) {
        try {
            Class.forName("com.mysql.cj.jdbc.Driver");
            Connection conn = DriverManager.getConnection(DB_URL, DB_USER, DB_PASSWORD);
            String sql = "INSERT INTO notifications (user_id, type, title, message, link, is_read, created_at) VALUES (?, ?, ?, ?, ?, 0, NOW())";
            PreparedStatement pstmt = conn.prepareStatement(sql);
            pstmt.setInt(1, userId);
            pstmt.setString(2, type);
            pstmt.setString(3, title);
            pstmt.setString(4, message);
            pstmt.setString(5, link);
            pstmt.executeUpdate();
            pstmt.close();
            conn.close();
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
    
    public static void notifyNewMessage(int userId, String senderName) {
        sendNotification(userId, "message", "📩 Nouveau message", 
            senderName + " vous a envoyé un message.", "chat.jsp");
    }
    
    public static void notifyNewClient(int adminId, String clientName) {
        sendNotification(adminId, "client", "👤 Nouveau client", 
            clientName + " vient de s'inscrire sur la plateforme.", "clients.jsp");
    }
    
    public static void notifyNewComment(int adminId, String propertyTitle, String commenterName) {
        sendNotification(adminId, "comment", "💬 Nouveau commentaire", 
            commenterName + " a commenté sur le bien : " + propertyTitle, "property-detail.jsp");
    }
    
    public static void notifyNewProperty(int adminId, String propertyTitle) {
        sendNotification(adminId, "property", "🏠 Nouveau bien ajouté", 
            "Le bien \"" + propertyTitle + "\" a été ajouté avec succès.", "dashboard.jsp");
    }
    
    public static void notifyContactRequest(int adminId, String clientName, String propertyTitle) {
        sendNotification(adminId, "contact", "📞 Demande de contact", 
            clientName + " souhaite être contacté pour le bien : " + propertyTitle, "clients.jsp");
    }
}