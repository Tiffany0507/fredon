package com.quickchat.dao;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;
import com.quickchat.model.GroupMessage;
import com.quickchat.utils.DatabaseConnection;

public class GroupMessageDAO {
    
    // Envoyer un message de groupe
    public boolean sendGroupMessage(GroupMessage message) {
        String sql = "INSERT INTO group_messages (group_id, sender_id, content, file_path, file_type, gif_url, reply_to_message_id, created_at) VALUES (?, ?, ?, ?, ?, ?, ?, NOW())";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            
            pstmt.setInt(1, message.getGroupId());
            pstmt.setInt(2, message.getSenderId());
            pstmt.setString(3, message.getContent());
            pstmt.setString(4, message.getFilePath());
            pstmt.setString(5, message.getFileType());
            pstmt.setString(6, message.getGifUrl());
            
            int replyId = message.getReplyToMessageId();
            if (replyId > 0) {
                pstmt.setInt(7, replyId);
            } else {
                pstmt.setNull(7, java.sql.Types.INTEGER);
            }
            
            return pstmt.executeUpdate() > 0;
            
        } catch (SQLException e) {
            e.printStackTrace();
            return false;
        }
    }
    
    // Récupérer les messages d'un groupe
    public List<GroupMessage> getGroupMessages(int groupId, int userId) {
        List<GroupMessage> messages = new ArrayList<>();
        
        // Vérifier si l'utilisateur a supprimé toute la conversation
        String checkDeletionSql = "SELECT deleted_at FROM group_messages_user_deletion WHERE user_id = ? AND group_id = ?";
        boolean conversationDeleted = false;
        Timestamp deletionTime = null;
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement checkStmt = conn.prepareStatement(checkDeletionSql)) {
            
            checkStmt.setInt(1, userId);
            checkStmt.setInt(2, groupId);
            ResultSet rs = checkStmt.executeQuery();
            if (rs.next()) {
                conversationDeleted = true;
                deletionTime = rs.getTimestamp("deleted_at");
            }
            
        } catch (SQLException e) {
            e.printStackTrace();
        }
        
        // Construire la requête SQL avec deleted_for_everyone
        String sql = "SELECT gm.*, gm.deleted_for_everyone, gm.reply_to_message_id, gm.is_pinned, u.username as sender_name, u.display_name, u.profile_pic " +
                     "FROM group_messages gm " +
                     "INNER JOIN users u ON gm.sender_id = u.id " +
                     "WHERE gm.group_id = ? " +
                     "AND NOT EXISTS (SELECT 1 FROM group_message_deletions gmd WHERE gmd.message_id = gm.id AND gmd.user_id = ?) ";
        
        // Si la conversation a été supprimée, ne montrer que les messages postérieurs à la suppression
        if (conversationDeleted && deletionTime != null) {
            sql += "AND gm.created_at > ? ";
        }
        
        sql += "ORDER BY gm.created_at ASC";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            
            pstmt.setInt(1, groupId);
            pstmt.setInt(2, userId);
            
            if (conversationDeleted && deletionTime != null) {
                pstmt.setTimestamp(3, deletionTime);
            }
            
            ResultSet rs = pstmt.executeQuery();
            
            while (rs.next()) {
                GroupMessage message = new GroupMessage();
                message.setId(rs.getInt("id"));
                message.setGroupId(rs.getInt("group_id"));
                message.setSenderId(rs.getInt("sender_id"));
                message.setSenderName(rs.getString("sender_name"));
                message.setContent(rs.getString("content"));
                message.setFilePath(rs.getString("file_path"));
                message.setFileType(rs.getString("file_type"));
                message.setGifUrl(rs.getString("gif_url"));
                message.setCreatedAt(rs.getString("created_at"));
                message.setUpdatedAt(rs.getString("updated_at"));
                message.setReplyToMessageId(rs.getInt("reply_to_message_id"));
                message.setIsPinned(rs.getBoolean("is_pinned"));
                message.setDeletedForEveryone(rs.getBoolean("deleted_for_everyone"));
                messages.add(message);
            }
            
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return messages;
    }
    
    // Récupérer un message par son ID
    public GroupMessage getMessageById(int messageId) {
        String sql = "SELECT gm.*, gm.deleted_for_everyone, gm.reply_to_message_id, gm.is_pinned, u.username as sender_name " +
                     "FROM group_messages gm " +
                     "JOIN users u ON gm.sender_id = u.id " +
                     "WHERE gm.id = ?";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            
            pstmt.setInt(1, messageId);
            ResultSet rs = pstmt.executeQuery();
            
            if (rs.next()) {
                GroupMessage message = new GroupMessage();
                message.setId(rs.getInt("id"));
                message.setGroupId(rs.getInt("group_id"));
                message.setSenderId(rs.getInt("sender_id"));
                message.setSenderName(rs.getString("sender_name"));
                message.setContent(rs.getString("content"));
                message.setFilePath(rs.getString("file_path"));
                message.setFileType(rs.getString("file_type"));
                message.setGifUrl(rs.getString("gif_url"));
                message.setCreatedAt(rs.getString("created_at"));
                message.setUpdatedAt(rs.getString("updated_at"));
                message.setReplyToMessageId(rs.getInt("reply_to_message_id"));
                message.setIsPinned(rs.getBoolean("is_pinned"));
                message.setDeletedForEveryone(rs.getBoolean("deleted_for_everyone"));
                return message;
            }
            
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return null;
    }
    
    // Modifier un message
    public boolean updateGroupMessage(int messageId, String newContent) {
        String sql = "UPDATE group_messages SET content = ?, updated_at = NOW() WHERE id = ?";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            
            pstmt.setString(1, newContent);
            pstmt.setInt(2, messageId);
            return pstmt.executeUpdate() > 0;
            
        } catch (SQLException e) {
            e.printStackTrace();
            return false;
        }
    }
    
    // Supprimer un message seulement pour un utilisateur spécifique
    public boolean deleteMessageForUser(int messageId, int userId) {
        String sql = "INSERT INTO group_message_deletions (message_id, user_id, deleted_at) " +
                     "VALUES (?, ?, NOW()) " +
                     "ON DUPLICATE KEY UPDATE deleted_at = NOW()";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            
            stmt.setInt(1, messageId);
            stmt.setInt(2, userId);
            
            return stmt.executeUpdate() > 0;
            
        } catch (SQLException e) {
            e.printStackTrace();
            return false;
        }
    }
    
    // Supprimer un message pour tout le monde (soft delete)
    public boolean deleteMessageForEveryone(int messageId, int userId) {
        String checkSql = "SELECT sender_id FROM group_messages WHERE id = ?";
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement checkStmt = conn.prepareStatement(checkSql)) {
            checkStmt.setInt(1, messageId);
            ResultSet rs = checkStmt.executeQuery();
            if (rs.next()) {
                int senderId = rs.getInt("sender_id");
                if (senderId != userId) return false;
            } else return false;
        } catch (SQLException e) { return false; }
        
        String sql = "UPDATE group_messages SET deleted_for_everyone = TRUE, content = NULL, file_path = NULL, file_type = NULL, gif_url = NULL, deleted_at = NOW() WHERE id = ?";
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setInt(1, messageId);
            return stmt.executeUpdate() > 0;
        } catch (SQLException e) { return false; }
    }
    
    // Supprimer tous les messages du groupe pour un utilisateur (suppression de la conversation)
    public boolean deleteAllMessagesForUser(int groupId, int userId) {
        String sql = "INSERT INTO group_messages_user_deletion (user_id, group_id, deleted_at) " +
                     "VALUES (?, ?, NOW()) " +
                     "ON DUPLICATE KEY UPDATE deleted_at = NOW()";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            
            stmt.setInt(1, userId);
            stmt.setInt(2, groupId);
            
            int result = stmt.executeUpdate();
            System.out.println("deleteAllMessagesForUser - résultat: " + result + " pour groupId=" + groupId + ", userId=" + userId);
            
            return result > 0;
            
        } catch (SQLException e) {
            System.out.println("Erreur SQL dans deleteAllMessagesForUser: " + e.getMessage());
            e.printStackTrace();
            return false;
        }
    }
    
    // Restaurer la conversation (supprimer l'entrée de suppression)
    public boolean restoreConversation(int groupId, int userId) {
        String sql = "DELETE FROM group_messages_user_deletion WHERE user_id = ? AND group_id = ?";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            
            stmt.setInt(1, userId);
            stmt.setInt(2, groupId);
            
            return stmt.executeUpdate() > 0;
            
        } catch (SQLException e) {
            e.printStackTrace();
            return false;
        }
    }
    
    // Marquer tous les messages d'un groupe comme lus
    public void markGroupMessagesAsRead(int groupId, int userId) {
        String getLastMsgSql = "SELECT MAX(id) FROM group_messages WHERE group_id = ?";
        int lastMessageId = 0;
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(getLastMsgSql)) {
            stmt.setInt(1, groupId);
            ResultSet rs = stmt.executeQuery();
            if (rs.next()) {
                lastMessageId = rs.getInt(1);
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        
        if (lastMessageId > 0) {
            String sql = "INSERT INTO group_read_status (group_id, user_id, last_read_message_id) VALUES (?, ?, ?) " +
                         "ON DUPLICATE KEY UPDATE last_read_message_id = ?";
            try (Connection conn = DatabaseConnection.getConnection();
                 PreparedStatement stmt = conn.prepareStatement(sql)) {
                stmt.setInt(1, groupId);
                stmt.setInt(2, userId);
                stmt.setInt(3, lastMessageId);
                stmt.setInt(4, lastMessageId);
                stmt.executeUpdate();
            } catch (Exception e) {
                e.printStackTrace();
            }
        }
    }
    
    // Compter les messages non lus pour un groupe et un utilisateur
    public int countUnreadGroupMessages(int groupId, int userId) {
        int count = 0;
        String sql = "SELECT COUNT(*) FROM group_messages gm " +
                     "WHERE gm.group_id = ? " +
                     "AND gm.id > COALESCE((SELECT last_read_message_id FROM group_read_status WHERE group_id = ? AND user_id = ?), 0) " +
                     "AND (gm.deleted_for_everyone = 0 OR gm.deleted_for_everyone IS NULL) " +
                     "AND NOT EXISTS (SELECT 1 FROM group_message_deletions gmd WHERE gmd.message_id = gm.id AND gmd.user_id = ?)";
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setInt(1, groupId);
            stmt.setInt(2, groupId);
            stmt.setInt(3, userId);
            stmt.setInt(4, userId);
            ResultSet rs = stmt.executeQuery();
            if (rs.next()) {
                count = rs.getInt(1);
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return count;
    }
    
    // Récupérer le message épinglé d'un groupe
    public GroupMessage getPinnedMessage(int groupId) {
        String sql = "SELECT gm.*, gm.deleted_for_everyone, gm.reply_to_message_id, u.username as sender_name FROM group_messages gm " +
                     "JOIN users u ON gm.sender_id = u.id " +
                     "WHERE gm.group_id = ? AND gm.is_pinned = TRUE " +
                     "LIMIT 1";
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setInt(1, groupId);
            ResultSet rs = stmt.executeQuery();
            if (rs.next()) {
                GroupMessage msg = new GroupMessage();
                msg.setId(rs.getInt("id"));
                msg.setGroupId(rs.getInt("group_id"));
                msg.setSenderId(rs.getInt("sender_id"));
                msg.setSenderName(rs.getString("sender_name"));
                msg.setContent(rs.getString("content"));
                msg.setFilePath(rs.getString("file_path"));
                msg.setFileType(rs.getString("file_type"));
                msg.setGifUrl(rs.getString("gif_url"));
                msg.setCreatedAt(rs.getString("created_at"));
                msg.setUpdatedAt(rs.getString("updated_at"));
                msg.setReplyToMessageId(rs.getInt("reply_to_message_id"));
                msg.setIsPinned(rs.getBoolean("is_pinned"));
                msg.setDeletedForEveryone(rs.getBoolean("deleted_for_everyone"));
                return msg;
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return null;
    }
    
    // Épingler/Désépingler un message
    public boolean togglePinMessage(int messageId, int groupId) {
        String checkSql = "SELECT is_pinned FROM group_messages WHERE id = ? AND group_id = ?";
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(checkSql)) {
            stmt.setInt(1, messageId);
            stmt.setInt(2, groupId);
            ResultSet rs = stmt.executeQuery();
            if (rs.next()) {
                boolean isPinned = rs.getBoolean("is_pinned");
                String updateSql = "UPDATE group_messages SET is_pinned = ? WHERE id = ?";
                try (PreparedStatement updateStmt = conn.prepareStatement(updateSql)) {
                    updateStmt.setBoolean(1, !isPinned);
                    updateStmt.setInt(2, messageId);
                    return updateStmt.executeUpdate() > 0;
                }
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return false;
    }
    
    // Vérifier si un message est supprimé pour un utilisateur
    public boolean isMessageDeletedForUser(int messageId, int userId) {
        String sql = "SELECT 1 FROM group_message_deletions WHERE message_id = ? AND user_id = ?";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            
            stmt.setInt(1, messageId);
            stmt.setInt(2, userId);
            
            ResultSet rs = stmt.executeQuery();
            return rs.next();
            
        } catch (SQLException e) {
            e.printStackTrace();
            return false;
        }
    }
}