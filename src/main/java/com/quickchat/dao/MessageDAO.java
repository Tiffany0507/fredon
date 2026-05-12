package com.quickchat.dao;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;
import com.quickchat.model.Message;
import com.quickchat.utils.DatabaseConnection;

public class MessageDAO {
    
    // Envoyer un message (version complète avec GIF, photo et propriétés immobilières)
    public boolean sendMessage(Message message) {
        String sql = "INSERT INTO messages (sender_id, receiver_id, content, file_path, file_type, gif_url, reply_to_message_id, is_delivered, created_at, property_id, property_title, property_price, property_image, property_type, property_location) VALUES (?, ?, ?, ?, ?, ?, ?, TRUE, NOW(), ?, ?, ?, ?, ?, ?)";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            
            stmt.setInt(1, message.getSenderId());
            stmt.setInt(2, message.getReceiverId());
            stmt.setString(3, message.getContent());
            stmt.setString(4, message.getFilePath());
            stmt.setString(5, message.getFileType());
            stmt.setString(6, message.getGifUrl());
            
            int replyId = message.getReplyToMessageId();
            if (replyId > 0) {
                stmt.setInt(7, replyId);
            } else {
                stmt.setNull(7, java.sql.Types.INTEGER);
            }
            
            // Nouveaux champs de propriété immobilière
            if (message.getPropertyId() != null && message.getPropertyId() > 0) {
                stmt.setInt(8, message.getPropertyId());
            } else {
                stmt.setNull(8, java.sql.Types.INTEGER);
            }
            
            stmt.setString(9, message.getPropertyTitle());
            
            if (message.getPropertyPrice() != null && message.getPropertyPrice() > 0) {
                stmt.setLong(10, message.getPropertyPrice());
            } else {
                stmt.setNull(10, java.sql.Types.BIGINT);
            }
            
            stmt.setString(11, message.getPropertyImage());
            stmt.setString(12, message.getPropertyType());
            stmt.setString(13, message.getPropertyLocation());
            
            return stmt.executeUpdate() > 0;
        } catch (SQLException e) {
            e.printStackTrace();
            return false;
        }
    }
    
    // Méthode simplifiée pour envoyer un fichier (photo, vidéo, fichier)
    public boolean sendMessage(int senderId, int receiverId, String content, String filePath, String fileType) {
        Message message = new Message();
        message.setSenderId(senderId);
        message.setReceiverId(receiverId);
        message.setContent(content);
        message.setFilePath(filePath);
        message.setFileType(fileType);
        return sendMessage(message);
    }
    
    // Vérifier si l'envoi de message est autorisé entre deux utilisateurs
    public boolean canSendMessage(int senderId, int receiverId) {
        BlockedUserDAO blockedDAO = new BlockedUserDAO();
        if (blockedDAO.isBlocked(senderId, receiverId)) {
            return false;
        }
        if (blockedDAO.isBlocked(receiverId, senderId)) {
            return false;
        }
        return true;
    }
    
    // Récupérer la conversation (avec gestion des suppressions, GIF et propriétés)
    public List<Message> getConversation(int user1Id, int user2Id) {
        List<Message> messages = new ArrayList<>();
        
        BlockedUserDAO blockedDAO = new BlockedUserDAO();
        if (blockedDAO.isBlocked(user1Id, user2Id) || blockedDAO.isBlocked(user2Id, user1Id)) {
            return messages;
        }
        
        String sql = "SELECT m.id, m.sender_id, m.receiver_id, m.content, m.file_path, m.file_type, m.gif_url, m.reply_to_message_id, m.is_delivered, m.is_pinned, m.is_read, m.created_at, m.updated_at, m.deleted_for_sender, m.deleted_for_receiver, " +
                     "m.property_id, m.property_title, m.property_price, m.property_image, m.property_type, m.property_location, " +
                     "u1.username as sender_name, u2.username as receiver_name " +
                     "FROM messages m " +
                     "JOIN users u1 ON m.sender_id = u1.id " +
                     "JOIN users u2 ON m.receiver_id = u2.id " +
                     "WHERE ((sender_id = ? AND receiver_id = ?) OR (sender_id = ? AND receiver_id = ?)) " +
                     "AND NOT (sender_id = ? AND deleted_for_sender = TRUE AND m.content != '[Message supprimé]') " +
                     "AND NOT (receiver_id = ? AND deleted_for_receiver = TRUE AND m.content != '[Message supprimé]') " +
                     "ORDER BY m.created_at ASC";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            
            pstmt.setInt(1, user1Id);
            pstmt.setInt(2, user2Id);
            pstmt.setInt(3, user2Id);
            pstmt.setInt(4, user1Id);
            pstmt.setInt(5, user1Id);
            pstmt.setInt(6, user1Id);
            
            ResultSet rs = pstmt.executeQuery();
            
            while (rs.next()) {
                Message message = new Message();
                message.setId(rs.getInt("id"));
                message.setSenderId(rs.getInt("sender_id"));
                message.setReceiverId(rs.getInt("receiver_id"));
                message.setContent(rs.getString("content"));
                message.setGifUrl(rs.getString("gif_url"));
                message.setIsRead(rs.getBoolean("is_read"));
                message.setCreatedAt(rs.getString("created_at"));
                message.setUpdatedAt(rs.getString("updated_at"));
                message.setSenderName(rs.getString("sender_name"));
                message.setReceiverName(rs.getString("receiver_name"));
                message.setDeletedForSender(rs.getBoolean("deleted_for_sender"));
                message.setDeletedForReceiver(rs.getBoolean("deleted_for_receiver"));
                message.setFilePath(rs.getString("file_path"));
                message.setFileType(rs.getString("file_type"));
                message.setReplyToMessageId(rs.getInt("reply_to_message_id"));
                message.setIsDelivered(rs.getBoolean("is_delivered"));
                message.setIsPinned(rs.getBoolean("is_pinned"));
                
                // NOUVEAUX CHAMPS : Propriétés immobilières
                int propId = rs.getInt("property_id");
                if (!rs.wasNull()) {
                    message.setPropertyId(propId);
                }
                message.setPropertyTitle(rs.getString("property_title"));
                long propPrice = rs.getLong("property_price");
                if (!rs.wasNull()) {
                    message.setPropertyPrice(propPrice);
                }
                message.setPropertyImage(rs.getString("property_image"));
                message.setPropertyType(rs.getString("property_type"));
                message.setPropertyLocation(rs.getString("property_location"));
                
                messages.add(message);
            }
            
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return messages;
    }
    
    // Modifier un message
    public boolean updateMessage(int messageId, String newContent) {
        String sql = "UPDATE messages SET content = ?, updated_at = NOW() WHERE id = ?";
        
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
    
    // Supprimer un message (définitif)
    public boolean deleteMessage(int messageId) {
        String sql = "DELETE FROM messages WHERE id = ?";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            
            pstmt.setInt(1, messageId);
            return pstmt.executeUpdate() > 0;
            
        } catch (SQLException e) {
            e.printStackTrace();
            return false;
        }
    }
    
    // Marquer un message comme lu
    public boolean markAsRead(int messageId) {
        String sql = "UPDATE messages SET is_read = TRUE WHERE id = ?";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            
            pstmt.setInt(1, messageId);
            return pstmt.executeUpdate() > 0;
            
        } catch (SQLException e) {
            e.printStackTrace();
            return false;
        }
    }
    
    // Récupérer les messages non lus d'un utilisateur
    public List<Message> getUnreadMessages(int userId) {
        List<Message> messages = new ArrayList<>();
        String sql = "SELECT m.*, u1.username as sender_name, m.gif_url " +
                     "FROM messages m " +
                     "JOIN users u1 ON m.sender_id = u1.id " +
                     "WHERE m.receiver_id = ? AND m.is_read = FALSE " +
                     "ORDER BY m.created_at DESC";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            
            pstmt.setInt(1, userId);
            ResultSet rs = pstmt.executeQuery();
            
            while (rs.next()) {
                Message message = new Message();
                message.setId(rs.getInt("id"));
                message.setSenderId(rs.getInt("sender_id"));
                message.setReceiverId(rs.getInt("receiver_id"));
                message.setContent(rs.getString("content"));
                message.setGifUrl(rs.getString("gif_url"));
                message.setIsRead(rs.getBoolean("is_read"));
                message.setCreatedAt(rs.getString("created_at"));
                message.setSenderName(rs.getString("sender_name"));
                messages.add(message);
            }
            
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return messages;
    }
    
    // Compter les messages non lus d'un utilisateur pour chaque expéditeur
    public int countUnreadMessagesFromUser(int receiverId, int senderId) {
        String sql = "SELECT COUNT(*) FROM messages WHERE receiver_id = ? AND sender_id = ? AND is_read = FALSE";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            
            pstmt.setInt(1, receiverId);
            pstmt.setInt(2, senderId);
            ResultSet rs = pstmt.executeQuery();
            
            if (rs.next()) {
                return rs.getInt(1);
            }
            
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return 0;
    }
    
    // Récupérer un message par son ID
    public Message getMessageById(int messageId) {
        String sql = "SELECT m.id, m.sender_id, m.receiver_id, m.content, m.file_path, m.file_type, m.gif_url, m.reply_to_message_id, m.is_delivered, m.is_pinned, m.is_read, m.created_at, m.updated_at, m.deleted_for_sender, m.deleted_for_receiver, " +
                     "m.property_id, m.property_title, m.property_price, m.property_image, m.property_type, m.property_location, " +
                     "u1.username as sender_name, u2.username as receiver_name " +
                     "FROM messages m " +
                     "JOIN users u1 ON m.sender_id = u1.id " +
                     "JOIN users u2 ON m.receiver_id = u2.id " +
                     "WHERE m.id = ?";
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            
            pstmt.setInt(1, messageId);
            ResultSet rs = pstmt.executeQuery();
            
            if (rs.next()) {
                Message message = new Message();
                message.setId(rs.getInt("id"));
                message.setSenderId(rs.getInt("sender_id"));
                message.setReceiverId(rs.getInt("receiver_id"));
                message.setContent(rs.getString("content"));
                message.setGifUrl(rs.getString("gif_url"));
                message.setIsRead(rs.getBoolean("is_read"));
                message.setCreatedAt(rs.getString("created_at"));
                message.setUpdatedAt(rs.getString("updated_at"));
                message.setSenderName(rs.getString("sender_name"));
                message.setReceiverName(rs.getString("receiver_name"));
                message.setDeletedForSender(rs.getBoolean("deleted_for_sender"));
                message.setDeletedForReceiver(rs.getBoolean("deleted_for_receiver"));
                message.setFilePath(rs.getString("file_path"));
                message.setFileType(rs.getString("file_type"));
                message.setReplyToMessageId(rs.getInt("reply_to_message_id"));
                message.setIsDelivered(rs.getBoolean("is_delivered"));
                message.setIsPinned(rs.getBoolean("is_pinned"));
                
                // NOUVEAUX CHAMPS : Propriétés immobilières
                int propId = rs.getInt("property_id");
                if (!rs.wasNull()) {
                    message.setPropertyId(propId);
                }
                message.setPropertyTitle(rs.getString("property_title"));
                long propPrice = rs.getLong("property_price");
                if (!rs.wasNull()) {
                    message.setPropertyPrice(propPrice);
                }
                message.setPropertyImage(rs.getString("property_image"));
                message.setPropertyType(rs.getString("property_type"));
                message.setPropertyLocation(rs.getString("property_location"));
                
                return message;
            }
            
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return null;
    }
    
    // Épingler/Désépingler un message
    public boolean togglePinMessage(int messageId, int userId) {
        String checkSql = "SELECT is_pinned FROM messages WHERE id = ? AND (sender_id = ? OR receiver_id = ?)";
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(checkSql)) {
            stmt.setInt(1, messageId);
            stmt.setInt(2, userId);
            stmt.setInt(3, userId);
            ResultSet rs = stmt.executeQuery();
            if (rs.next()) {
                boolean isPinned = rs.getBoolean("is_pinned");
                String updateSql = "UPDATE messages SET is_pinned = ? WHERE id = ?";
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

    // Récupérer le message épinglé d'une conversation
    public Message getPinnedMessage(int user1Id, int user2Id) {
        String sql = "SELECT m.id, m.sender_id, m.receiver_id, m.content, m.gif_url, m.created_at, m.is_pinned, " +
                     "u1.username as sender_name, u2.username as receiver_name " +
                     "FROM messages m " +
                     "JOIN users u1 ON m.sender_id = u1.id " +
                     "JOIN users u2 ON m.receiver_id = u2.id " +
                     "WHERE ((sender_id = ? AND receiver_id = ?) OR (sender_id = ? AND receiver_id = ?)) " +
                     "AND is_pinned = TRUE LIMIT 1";
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setInt(1, user1Id);
            stmt.setInt(2, user2Id);
            stmt.setInt(3, user2Id);
            stmt.setInt(4, user1Id);
            ResultSet rs = stmt.executeQuery();
            if (rs.next()) {
                Message message = new Message();
                message.setId(rs.getInt("id"));
                message.setSenderId(rs.getInt("sender_id"));
                message.setReceiverId(rs.getInt("receiver_id"));
                message.setContent(rs.getString("content"));
                message.setGifUrl(rs.getString("gif_url"));
                message.setCreatedAt(rs.getString("created_at"));
                message.setSenderName(rs.getString("sender_name"));
                message.setIsPinned(rs.getBoolean("is_pinned"));
                return message;
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return null;
    }
    
    // Marquer tous les messages d'un expéditeur comme lus
    public boolean markAllMessagesAsRead(int receiverId, int senderId) {
        String sql = "UPDATE messages SET is_read = TRUE WHERE receiver_id = ? AND sender_id = ? AND is_read = FALSE";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            
            pstmt.setInt(1, receiverId);
            pstmt.setInt(2, senderId);
            return pstmt.executeUpdate() > 0;
            
        } catch (SQLException e) {
            e.printStackTrace();
            return false;
        }
    }
    
    // Supprimer un message pour l'utilisateur (suppression personnelle)
    public boolean deleteForUser(int messageId, int userId, boolean isSender) {
        String column = isSender ? "deleted_for_sender = TRUE" : "deleted_for_receiver = TRUE";
        String sql = "UPDATE messages SET " + column + " WHERE id = ?";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            
            pstmt.setInt(1, messageId);
            return pstmt.executeUpdate() > 0;
            
        } catch (SQLException e) {
            e.printStackTrace();
            return false;
        }
    }
    
    // Supprimer un message pour tout le monde
    public boolean deleteForEveryone(int messageId) {
        String sql = "UPDATE messages SET content = NULL, file_path = NULL, file_type = NULL, gif_url = NULL, deleted_for_sender = TRUE, deleted_for_receiver = TRUE WHERE id = ?";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            
            pstmt.setInt(1, messageId);
            return pstmt.executeUpdate() > 0;
            
        } catch (SQLException e) {
            e.printStackTrace();
            return false;
        }
    }
    
    // Compter tous les messages non lus pour l'agent (ID 9)
    public int countUnreadMessagesForAgent() {
        String sql = "SELECT COUNT(*) FROM messages WHERE receiver_id = 9 AND is_read = FALSE";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            
            ResultSet rs = pstmt.executeQuery();
            
            if (rs.next()) {
                return rs.getInt(1);
            }
            
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return 0;
    }
    
    // Envoyer un message avec fichier
    public boolean sendMessageWithFile(int senderId, int receiverId, String content, String filePath, String fileType) {
        String sql = "INSERT INTO messages (sender_id, receiver_id, content, file_path, file_type, created_at, is_delivered, is_read) VALUES (?, ?, ?, ?, ?, NOW(), 1, 0)";
        
        try (Connection conn = DriverManager.getConnection("jdbc:mysql://localhost:3306/quickchat", "root", "");
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            
            pstmt.setInt(1, senderId);
            pstmt.setInt(2, receiverId);
            pstmt.setString(3, content);
            pstmt.setString(4, filePath);
            pstmt.setString(5, fileType);
            
            return pstmt.executeUpdate() > 0;
        } catch (SQLException e) {
            e.printStackTrace();
            return false;
        }
    }
    
    // Compter les messages non lus pour un utilisateur
    public int countUnreadMessagesForUser(int userId) {
        String sql = "SELECT COUNT(*) FROM messages WHERE receiver_id = ? AND is_read = 0";
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            pstmt.setInt(1, userId);
            ResultSet rs = pstmt.executeQuery();
            if (rs.next()) {
                return rs.getInt(1);
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return 0;
    }
}