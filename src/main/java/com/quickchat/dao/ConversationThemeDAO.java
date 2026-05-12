package com.quickchat.dao;

import java.sql.*;
import com.quickchat.utils.DatabaseConnection;  // ← Correction ici

public class ConversationThemeDAO {
    
    // Récupérer le thème d'une conversation
    public String getTheme(int userId, int contactId) {
        String sql = "SELECT theme FROM conversation_themes WHERE user_id = ? AND contact_id = ?";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            
            pstmt.setInt(1, userId);
            pstmt.setInt(2, contactId);
            ResultSet rs = pstmt.executeQuery();
            
            if (rs.next()) {
                return rs.getString("theme");
            }
            
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return "default";
    }
    
    public boolean saveTheme(int userId, int contactId, String theme) {
        String sql = "INSERT INTO conversation_themes (user_id, contact_id, theme) VALUES (?, ?, ?) " +
                     "ON DUPLICATE KEY UPDATE theme = ?";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            
            pstmt.setInt(1, userId);
            pstmt.setInt(2, contactId);
            pstmt.setString(3, theme);
            pstmt.setString(4, theme);
            
            return pstmt.executeUpdate() > 0;
            
        } catch (SQLException e) {
            e.printStackTrace();
            return false;
        }
    }}