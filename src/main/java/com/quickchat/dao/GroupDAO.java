package com.quickchat.dao;

import com.quickchat.model.Group;
import com.quickchat.utils.DatabaseConnection;
import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class GroupDAO {
    
    // Récupérer un groupe par son ID
    public Group getGroupById(int groupId) {
        Group group = null;
        String sql = "SELECT id, name, description, created_by, created_at, updated_at, theme FROM groups WHERE id = ?";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            
            stmt.setInt(1, groupId);
            ResultSet rs = stmt.executeQuery();
            
            if (rs.next()) {
                group = new Group();
                group.setId(rs.getInt("id"));
                group.setName(rs.getString("name"));
                group.setDescription(rs.getString("description"));
                group.setCreatedBy(rs.getInt("created_by"));
                group.setCreatedAt(rs.getString("created_at"));
                group.setUpdatedAt(rs.getString("updated_at"));
                group.setTheme(rs.getString("theme"));  // Ajout du thème
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return group;
    }
    
    // Récupérer tous les groupes d'un utilisateur
    public List<Group> getUserGroups(int userId) {
        List<Group> groups = new ArrayList<>();
        String sql = "SELECT g.id, g.name, g.description, g.created_by, g.created_at, g.updated_at, g.theme " +
                     "FROM groups g " +
                     "INNER JOIN group_members gm ON gm.group_id = g.id " +
                     "WHERE gm.user_id = ? " +
                     "ORDER BY g.created_at DESC";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            
            stmt.setInt(1, userId);
            ResultSet rs = stmt.executeQuery();
            
            while (rs.next()) {
                Group group = new Group();
                group.setId(rs.getInt("id"));
                group.setName(rs.getString("name"));
                group.setDescription(rs.getString("description"));
                group.setCreatedBy(rs.getInt("created_by"));
                group.setCreatedAt(rs.getString("created_at"));
                group.setUpdatedAt(rs.getString("updated_at"));
                group.setTheme(rs.getString("theme"));  // Ajout du thème
                groups.add(group);
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return groups;
    }
    
    // Créer un nouveau groupe
    public boolean createGroup(Group group) {
        String sql = "INSERT INTO groups (name, description, created_by, theme) VALUES (?, ?, ?, ?)";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            
            stmt.setString(1, group.getName());
            stmt.setString(2, group.getDescription());
            stmt.setInt(3, group.getCreatedBy());
            stmt.setString(4, group.getTheme() != null ? group.getTheme() : "default");
            
            int affectedRows = stmt.executeUpdate();
            
            if (affectedRows > 0) {
                try (ResultSet generatedKeys = stmt.getGeneratedKeys()) {
                    if (generatedKeys.next()) {
                        group.setId(generatedKeys.getInt(1));
                    }
                }
                return true;
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return false;
    }
    
    // Mettre à jour le thème d'un groupe
    public boolean updateGroupTheme(int groupId, String theme) {
        String sql = "UPDATE groups SET theme = ? WHERE id = ?";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            
            stmt.setString(1, theme);
            stmt.setInt(2, groupId);
            return stmt.executeUpdate() > 0;
            
        } catch (SQLException e) {
            e.printStackTrace();
            return false;
        }
    }
    
    // Supprimer un groupe
    public boolean deleteGroup(int groupId) {
        String sql = "DELETE FROM groups WHERE id = ?";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            
            stmt.setInt(1, groupId);
            return stmt.executeUpdate() > 0;
            
        } catch (SQLException e) {
            e.printStackTrace();
            return false;
        }
    }
    
    // Transférer la propriété du groupe
    public boolean transferOwnership(int groupId, int newCreatorId) {
        String sql = "UPDATE groups SET created_by = ? WHERE id = ?";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            
            stmt.setInt(1, newCreatorId);
            stmt.setInt(2, groupId);
            return stmt.executeUpdate() > 0;
            
        } catch (SQLException e) {
            e.printStackTrace();
            return false;
        }
    }
}