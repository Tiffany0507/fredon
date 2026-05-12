package com.quickchat.dao;

import java.sql.*;
import com.quickchat.utils.DatabaseConnection;

public class ContactNameDAO {
    
    // Récupérer le nom personnalisé d'un contact
    public String getCustomName(int userId, int contactId) {
        String sql = "SELECT custom_name FROM contact_names WHERE user_id = ? AND contact_id = ?";
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setInt(1, userId);
            stmt.setInt(2, contactId);
            ResultSet rs = stmt.executeQuery();
            if (rs.next()) {
                return rs.getString("custom_name");
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return null;
    }
    
    // Ajouter ou modifier le nom personnalisé d'un contact
    public boolean updateCustomName(int userId, int contactId, String customName) {
        String sql = "INSERT INTO contact_names (user_id, contact_id, custom_name, updated_at) VALUES (?, ?, ?, NOW()) " +
                     "ON DUPLICATE KEY UPDATE custom_name = ?, updated_at = NOW()";
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setInt(1, userId);
            stmt.setInt(2, contactId);
            stmt.setString(3, customName);
            stmt.setString(4, customName);
            return stmt.executeUpdate() > 0;
        } catch (SQLException e) {
            e.printStackTrace();
            return false;
        }
    }
    
    // Supprimer le nom personnalisé d'un contact
    public boolean removeCustomName(int userId, int contactId) {
        String sql = "DELETE FROM contact_names WHERE user_id = ? AND contact_id = ?";
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setInt(1, userId);
            stmt.setInt(2, contactId);
            return stmt.executeUpdate() > 0;
        } catch (SQLException e) {
            e.printStackTrace();
            return false;
        }
    }
}