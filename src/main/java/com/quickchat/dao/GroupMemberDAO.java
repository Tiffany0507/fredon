package com.quickchat.dao;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;
import com.quickchat.model.User;
import com.quickchat.utils.DatabaseConnection;
import java.util.Map;
import java.util.HashMap;

public class GroupMemberDAO {
    
    // Ajouter un membre (avec added_by - version complète)
    public boolean addMember(int groupId, int userId, int addedBy, String role) {
        String sql = "INSERT INTO group_members (group_id, user_id, added_by, role, joined_at) VALUES (?, ?, ?, ?, NOW())";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            
            stmt.setInt(1, groupId);
            stmt.setInt(2, userId);
            stmt.setInt(3, addedBy);
            stmt.setString(4, role);
            
            return stmt.executeUpdate() > 0;
            
        } catch (SQLException e) {
            e.printStackTrace();
            return false;
        }
    }
    
    // Ajouter un membre (sans added_by - pour compatibilité avec anciens appels)
    public boolean addMember(int groupId, int userId, String role) {
        String sql = "INSERT INTO group_members (group_id, user_id, role, joined_at) VALUES (?, ?, ?, NOW())";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            
            stmt.setInt(1, groupId);
            stmt.setInt(2, userId);
            stmt.setString(3, role);
            
            return stmt.executeUpdate() > 0;
            
        } catch (SQLException e) {
            e.printStackTrace();
            return false;
        }
    }
    
    // Supprimer un membre
    public boolean removeMember(int groupId, int userId) {
        String sql = "DELETE FROM group_members WHERE group_id = ? AND user_id = ?";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            
            pstmt.setInt(1, groupId);
            pstmt.setInt(2, userId);
            return pstmt.executeUpdate() > 0;
            
        } catch (SQLException e) {
            e.printStackTrace();
            return false;
        }
    }
    
    // Récupérer les membres d'un groupe
    public List<User> getGroupMembers(int groupId) {
        List<User> members = new ArrayList<>();
        String sql = "SELECT u.id, u.username, u.full_name, u.status, u.profile_pic, u.display_name, u.created_at, gm.role, gm.added_by " +
                     "FROM users u " +
                     "JOIN group_members gm ON u.id = gm.user_id " +
                     "WHERE gm.group_id = ? " +
                     "ORDER BY gm.role DESC, u.username";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            
            pstmt.setInt(1, groupId);
            ResultSet rs = pstmt.executeQuery();
            
            while (rs.next()) {
                User user = new User();
                user.setId(rs.getInt("id"));
                user.setUsername(rs.getString("username"));
                user.setFullName(rs.getString("full_name"));
                user.setStatus(rs.getString("status"));
                user.setProfilePic(rs.getString("profile_pic"));
                user.setDisplayName(rs.getString("display_name"));
                user.setCreatedAt(rs.getString("created_at"));
                members.add(user);
            }
            
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return members;
    }
    
    // Récupérer les informations d'un membre spécifique (pour la modale)
    public Map<String, Object> getMemberInfo(int groupId, int userId) {
        Map<String, Object> info = new java.util.HashMap<>();
        String sql = "SELECT gm.*, u.username as added_by_username, u.display_name as added_by_displayname, " +
                     "g.created_by as group_creator " +
                     "FROM group_members gm " +
                     "LEFT JOIN users u ON gm.added_by = u.id " +
                     "LEFT JOIN groups g ON gm.group_id = g.id " +
                     "WHERE gm.group_id = ? AND gm.user_id = ?";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            
            stmt.setInt(1, groupId);
            stmt.setInt(2, userId);
            ResultSet rs = stmt.executeQuery();
            
            if (rs.next()) {
                boolean isCreator = (rs.getInt("group_creator") == userId);
                info.put("isCreator", isCreator);
                
                int addedBy = rs.getInt("added_by");
                if (addedBy > 0 && !isCreator) {
                    String addedByName = rs.getString("added_by_displayname");
                    if (addedByName == null || addedByName.isEmpty()) {
                        addedByName = rs.getString("added_by_username");
                    }
                    info.put("addedBy", addedByName);
                } else if (isCreator) {
                    info.put("addedBy", "Créateur du groupe");
                } else {
                    info.put("addedBy", "");
                }
                info.put("success", true);
            } else {
                info.put("success", false);
            }
            
        } catch (SQLException e) {
            e.printStackTrace();
            info.put("success", false);
        }
        return info;
    }
    
    // Vérifier si un utilisateur est membre du groupe
    public boolean isMember(int groupId, int userId) {
        String sql = "SELECT 1 FROM group_members WHERE group_id = ? AND user_id = ?";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            
            pstmt.setInt(1, groupId);
            pstmt.setInt(2, userId);
            ResultSet rs = pstmt.executeQuery();
            return rs.next();
            
        } catch (SQLException e) {
            e.printStackTrace();
            return false;
        }
    }
}