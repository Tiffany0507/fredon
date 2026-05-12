package com.quickchat.dao;

import com.quickchat.model.User;
import com.quickchat.utils.DatabaseConnection;
import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class ConversationDAO {
    
    // Pas besoin d'instancier DatabaseConnection, on utilise la méthode statique
    
    /**
     * Archive ou désarchive une conversation
     */
    public void setArchived(int userId, int contactId, boolean archived) {
        String sql = "INSERT INTO conversations (user_id, contact_id, archived) VALUES (?, ?, ?) " +
                     "ON DUPLICATE KEY UPDATE archived = ?";
        try (Connection conn = DatabaseConnection.getConnection();  // ← MODIFIÉ
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setInt(1, userId);
            stmt.setInt(2, contactId);
            stmt.setBoolean(3, archived);
            stmt.setBoolean(4, archived);
            stmt.executeUpdate();
        } catch (SQLException e) {
            e.printStackTrace();
        }
    }
    
    /**
     * Vérifie si une conversation est archivée
     */
    public boolean isArchived(int userId, int contactId) {
        String sql = "SELECT archived FROM conversations WHERE user_id = ? AND contact_id = ?";
        try (Connection conn = DatabaseConnection.getConnection();  // ← MODIFIÉ
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setInt(1, userId);
            stmt.setInt(2, contactId);
            ResultSet rs = stmt.executeQuery();
            if (rs.next()) {
                return rs.getBoolean("archived");
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return false;
    }
    
    /**
     * Récupère les contacts non archivés (discussions actives)
     */
    public List<User> getActiveConversations(int userId, List<User> allUsers) {
        List<User> active = new ArrayList<>();
        for (User u : allUsers) {
            if (!isArchived(userId, u.getId())) {
                active.add(u);
            }
        }
        return active;
    }
    
    /**
     * Récupère les contacts archivés
     */
    public List<User> getArchivedConversations(int userId, List<User> allUsers) {
        List<User> archived = new ArrayList<>();
        for (User u : allUsers) {
            if (isArchived(userId, u.getId())) {
                archived.add(u);
            }
        }
        return archived;
    }
 // Ajouter cette méthode pour archiver une conversation de groupe
    public boolean archiveGroupConversation(int userId, int groupId) {
        String sql = "INSERT INTO archived_group_conversations (user_id, group_id, archived_at) " +
                     "VALUES (?, ?, NOW()) " +
                     "ON DUPLICATE KEY UPDATE archived_at = NOW()";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            
            stmt.setInt(1, userId);
            stmt.setInt(2, groupId);
            
            int rowsAffected = stmt.executeUpdate();
            return rowsAffected > 0;
            
        } catch (SQLException e) {
            e.printStackTrace();
            return false;
        }
    }

    // Ajouter cette méthode pour vérifier si un groupe est archivé
    public boolean isGroupArchived(int userId, int groupId) {
        String sql = "SELECT 1 FROM archived_group_conversations WHERE user_id = ? AND group_id = ?";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            
            stmt.setInt(1, userId);
            stmt.setInt(2, groupId);
            
            ResultSet rs = stmt.executeQuery();
            return rs.next();
            
        } catch (SQLException e) {
            e.printStackTrace();
            return false;
        }
    }

    // Ajouter cette méthode pour supprimer une conversation de groupe (pour un utilisateur)
    public boolean deleteGroupConversation(int userId, int groupId) {
        String sql = "DELETE FROM group_messages_user_deletion WHERE user_id = ? AND group_id = ?";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            
            stmt.setInt(1, userId);
            stmt.setInt(2, groupId);
            
            int rowsAffected = stmt.executeUpdate();
            
            // Si le message n'existe pas encore dans la table de suppression, on l'ajoute
            if (rowsAffected == 0) {
                sql = "INSERT INTO group_messages_user_deletion (user_id, group_id, deleted_at) VALUES (?, ?, NOW())";
                try (PreparedStatement stmt2 = conn.prepareStatement(sql)) {
                    stmt2.setInt(1, userId);
                    stmt2.setInt(2, groupId);
                    return stmt2.executeUpdate() > 0;
                }
            }
            
            return rowsAffected > 0;
            
        } catch (SQLException e) {
            e.printStackTrace();
            return false;
        }
    }
 // Désarchive une conversation de groupe
    public boolean unarchiveGroupConversation(int userId, int groupId) {
        String sql = "DELETE FROM archived_group_conversations WHERE user_id = ? AND group_id = ?";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            
            stmt.setInt(1, userId);
            stmt.setInt(2, groupId);
            
            int rowsAffected = stmt.executeUpdate();
            return rowsAffected > 0;
            
        } catch (SQLException e) {
            e.printStackTrace();
            return false;
        }
    }
    
    /**
     * Supprime complètement une conversation (tous les messages + archivage)
     */
    public void deleteConversation(int userId, int contactId) {
        Connection conn = null;
        try {
            conn = DatabaseConnection.getConnection();  // ← MODIFIÉ
            conn.setAutoCommit(false);
            
            // 1. Supprimer les messages de cette conversation pour cet utilisateur
            String deleteMessages = "DELETE FROM messages WHERE (sender_id = ? AND receiver_id = ?) " +
                                    "OR (sender_id = ? AND receiver_id = ?)";
            try (PreparedStatement stmt = conn.prepareStatement(deleteMessages)) {
                stmt.setInt(1, userId);
                stmt.setInt(2, contactId);
                stmt.setInt(3, contactId);
                stmt.setInt(4, userId);
                stmt.executeUpdate();
            }
            
            // 2. Supprimer l'entrée de conversation (archivage)
            String deleteConv = "DELETE FROM conversations WHERE user_id = ? AND contact_id = ?";
            try (PreparedStatement stmt = conn.prepareStatement(deleteConv)) {
                stmt.setInt(1, userId);
                stmt.setInt(2, contactId);
                stmt.executeUpdate();
            }
            
            conn.commit();
        } catch (SQLException e) {
            try { if (conn != null) conn.rollback(); } catch (SQLException ex) {}
            e.printStackTrace();
        } finally {
            try { if (conn != null) conn.setAutoCommit(true); } catch (SQLException e) {}
        }
    }
}