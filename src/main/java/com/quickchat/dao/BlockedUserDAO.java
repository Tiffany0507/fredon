package com.quickchat.dao;

import java.sql.*;
import java.util.HashSet;
import java.util.Set;
import com.quickchat.utils.DatabaseConnection;

public class BlockedUserDAO {
    
    // Bloquer un utilisateur
    public boolean blockUser(int userId, int blockedUserId) {
        String sql = "INSERT INTO blocked_users (user_id, blocked_user_id) VALUES (?, ?)";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            
            pstmt.setInt(1, userId);
            pstmt.setInt(2, blockedUserId);
            pstmt.executeUpdate();
            return true;
            
        } catch (SQLException e) {
            // Si c'est une duplication, c'est déjà bloqué
            if (e.getErrorCode() != 1062) { // 1062 = Duplicate entry
                e.printStackTrace();
            }
            return false;
        }
    }
    
    // Débloquer un utilisateur
    public boolean unblockUser(int userId, int blockedUserId) {
        String sql = "DELETE FROM blocked_users WHERE user_id = ? AND blocked_user_id = ?";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            
            pstmt.setInt(1, userId);
            pstmt.setInt(2, blockedUserId);
            return pstmt.executeUpdate() > 0;
            
        } catch (SQLException e) {
            e.printStackTrace();
            return false;
        }
    }
    
    // Vérifier si un utilisateur est bloqué
    public boolean isBlocked(int userId, int blockedUserId) {
        String sql = "SELECT 1 FROM blocked_users WHERE user_id = ? AND blocked_user_id = ?";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            
            pstmt.setInt(1, userId);
            pstmt.setInt(2, blockedUserId);
            ResultSet rs = pstmt.executeQuery();
            return rs.next();
            
        } catch (SQLException e) {
            e.printStackTrace();
            return false;
        }
    }
    
    // Récupérer tous les utilisateurs bloqués par un utilisateur
    public Set<Integer> getBlockedUsers(int userId) {
        Set<Integer> blockedUsers = new HashSet<>();
        String sql = "SELECT blocked_user_id FROM blocked_users WHERE user_id = ?";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            
            pstmt.setInt(1, userId);
            ResultSet rs = pstmt.executeQuery();
            
            while (rs.next()) {
                blockedUsers.add(rs.getInt("blocked_user_id"));
            }
            
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return blockedUsers;
    }
}