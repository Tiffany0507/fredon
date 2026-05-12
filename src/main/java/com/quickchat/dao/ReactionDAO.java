package com.quickchat.dao;

import java.sql.*;
import java.util.HashMap;
import java.util.Map;
import com.quickchat.utils.DatabaseConnection;

public class ReactionDAO {
    
    // Ajouter ou modifier une réaction
    public boolean addReaction(int messageId, int userId, String reactionType) {
        String sql = "INSERT INTO reactions (message_id, user_id, reaction_type) VALUES (?, ?, ?) " +
                     "ON DUPLICATE KEY UPDATE reaction_type = ?";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            
            pstmt.setInt(1, messageId);
            pstmt.setInt(2, userId);
            pstmt.setString(3, reactionType);
            pstmt.setString(4, reactionType);
            
            return pstmt.executeUpdate() > 0;
            
        } catch (SQLException e) {
            e.printStackTrace();
            return false;
        }
    }
    
    // Supprimer une réaction
    public boolean removeReaction(int messageId, int userId) {
        String sql = "DELETE FROM reactions WHERE message_id = ? AND user_id = ?";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            
            pstmt.setInt(1, messageId);
            pstmt.setInt(2, userId);
            
            return pstmt.executeUpdate() > 0;
            
        } catch (SQLException e) {
            e.printStackTrace();
            return false;
        }
    }
    
    // Récupérer toutes les réactions d'un message
    public Map<String, Integer> getReactionsForMessage(int messageId) {
        Map<String, Integer> reactions = new HashMap<>();
        String sql = "SELECT reaction_type, COUNT(*) as count FROM reactions WHERE message_id = ? GROUP BY reaction_type";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            
            pstmt.setInt(1, messageId);
            ResultSet rs = pstmt.executeQuery();
            
            while (rs.next()) {
                reactions.put(rs.getString("reaction_type"), rs.getInt("count"));
            }
            
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return reactions;
    }
    
    // Récupérer la réaction d'un utilisateur pour un message
    public String getUserReaction(int messageId, int userId) {
        String sql = "SELECT reaction_type FROM reactions WHERE message_id = ? AND user_id = ?";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            
            pstmt.setInt(1, messageId);
            pstmt.setInt(2, userId);
            ResultSet rs = pstmt.executeQuery();
            
            if (rs.next()) {
                return rs.getString("reaction_type");
            }
            
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return null;
    }
}