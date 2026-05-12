package com.quickchat.dao;

import com.quickchat.model.User;
import com.quickchat.utils.DatabaseConnection;
import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class FriendDAO {
    
    // Récupérer tous les amis d'un utilisateur
    public List<User> getFriends(int userId) {
        List<User> friends = new ArrayList<>();
        String sql = "SELECT u.* FROM users u " +
                     "INNER JOIN friends f ON (f.user_id = ? AND f.friend_id = u.id) " +
                     "OR (f.friend_id = ? AND f.user_id = u.id) " +
                     "WHERE f.status = 'accepted'";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            
            stmt.setInt(1, userId);
            stmt.setInt(2, userId);
            
            try (ResultSet rs = stmt.executeQuery()) {
                while (rs.next()) {
                    User user = new User();
                    user.setId(rs.getInt("id"));
                    user.setUsername(rs.getString("username"));
                    user.setEmail(rs.getString("email"));
                    user.setDisplayName(rs.getString("display_name"));
                    user.setProfilePic(rs.getString("profile_pic"));
                    user.setCreatedAt(rs.getString("created_at"));
                    friends.add(user);
                }
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return friends;
    }
    
    // Vérifier si deux utilisateurs sont amis
    public boolean areFriends(int userId1, int userId2) {
        String sql = "SELECT * FROM friends WHERE " +
                     "(user_id = ? AND friend_id = ?) OR " +
                     "(user_id = ? AND friend_id = ?) AND status = 'accepted'";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            
            stmt.setInt(1, userId1);
            stmt.setInt(2, userId2);
            stmt.setInt(3, userId2);
            stmt.setInt(4, userId1);
            
            try (ResultSet rs = stmt.executeQuery()) {
                return rs.next();
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return false;
    }
    
    // Ajouter une demande d'ami
    public boolean sendFriendRequest(int userId, int friendId) {
        String sql = "INSERT INTO friends (user_id, friend_id, status, created_at) VALUES (?, ?, 'pending', NOW())";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            
            stmt.setInt(1, userId);
            stmt.setInt(2, friendId);
            return stmt.executeUpdate() > 0;
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return false;
    }
    
    // Accepter une demande d'ami
    public boolean acceptFriendRequest(int userId, int friendId) {
        String sql = "UPDATE friends SET status = 'accepted' WHERE " +
                     "(user_id = ? AND friend_id = ?) OR (user_id = ? AND friend_id = ?)";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            
            stmt.setInt(1, userId);
            stmt.setInt(2, friendId);
            stmt.setInt(3, friendId);
            stmt.setInt(4, userId);
            return stmt.executeUpdate() > 0;
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return false;
    }
    
    // Refuser ou supprimer un ami
    public boolean removeFriend(int userId, int friendId) {
        String sql = "DELETE FROM friends WHERE " +
                     "(user_id = ? AND friend_id = ?) OR (user_id = ? AND friend_id = ?)";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            
            stmt.setInt(1, userId);
            stmt.setInt(2, friendId);
            stmt.setInt(3, friendId);
            stmt.setInt(4, userId);
            return stmt.executeUpdate() > 0;
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return false;
    }
    
    // Récupérer les demandes d'amis en attente
    public List<User> getPendingRequests(int userId) {
        List<User> pending = new ArrayList<>();
        String sql = "SELECT u.* FROM users u " +
                     "INNER JOIN friends f ON f.user_id = u.id " +
                     "WHERE f.friend_id = ? AND f.status = 'pending'";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            
            stmt.setInt(1, userId);
            
            try (ResultSet rs = stmt.executeQuery()) {
                while (rs.next()) {
                    User user = new User();
                    user.setId(rs.getInt("id"));
                    user.setUsername(rs.getString("username"));
                    user.setEmail(rs.getString("email"));
                    user.setDisplayName(rs.getString("display_name"));
                    user.setProfilePic(rs.getString("profile_pic"));
                    pending.add(user);
                }
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return pending;
    }
}