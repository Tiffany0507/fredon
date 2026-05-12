package com.immobilier.dao;

import com.immobilier.model.PropertyReaction;
import java.sql.*;
import java.util.HashMap;
import java.util.Map;

public class PropertyReactionDAO {

    private Connection connection;

    public PropertyReactionDAO(Connection connection) {
        this.connection = connection;
    }

    // Ajouter ou mettre à jour une réaction
    public boolean addOrUpdateReaction(PropertyReaction reaction) throws SQLException {
        String sql = "INSERT INTO property_reactions (property_id, visitor_identifier, reaction_type) VALUES (?, ?, ?) " +
                     "ON DUPLICATE KEY UPDATE reaction_type = VALUES(reaction_type)";
        
        try (PreparedStatement stmt = connection.prepareStatement(sql)) {
            stmt.setInt(1, reaction.getPropertyId());
            stmt.setString(2, reaction.getVisitorIdentifier());
            stmt.setString(3, reaction.getReactionType());
            
            return stmt.executeUpdate() > 0;
        }
    }

    // Récupérer la réaction d'un visiteur sur un bien
    public PropertyReaction getVisitorReaction(int propertyId, String visitorIdentifier) throws SQLException {
        String sql = "SELECT * FROM property_reactions WHERE property_id = ? AND visitor_identifier = ?";
        
        try (PreparedStatement stmt = connection.prepareStatement(sql)) {
            stmt.setInt(1, propertyId);
            stmt.setString(2, visitorIdentifier);
            
            try (ResultSet rs = stmt.executeQuery()) {
                if (rs.next()) {
                    return mapResultSetToReaction(rs);
                }
            }
        }
        return null;
    }

    // Supprimer la réaction d'un visiteur
    public boolean deleteReaction(int propertyId, String visitorIdentifier) throws SQLException {
        String sql = "DELETE FROM property_reactions WHERE property_id = ? AND visitor_identifier = ?";
        
        try (PreparedStatement stmt = connection.prepareStatement(sql)) {
            stmt.setInt(1, propertyId);
            stmt.setString(2, visitorIdentifier);
            
            return stmt.executeUpdate() > 0;
        }
    }

    // Compter les réactions par type pour un bien
    public Map<String, Integer> countReactionsByPropertyId(int propertyId) throws SQLException {
        Map<String, Integer> counts = new HashMap<>();
        counts.put("like", 0);
        counts.put("love", 0);
        counts.put("interested", 0);
        counts.put("dislike", 0);
        
        String sql = "SELECT reaction_type, COUNT(*) as count FROM property_reactions WHERE property_id = ? GROUP BY reaction_type";
        
        try (PreparedStatement stmt = connection.prepareStatement(sql)) {
            stmt.setInt(1, propertyId);
            
            try (ResultSet rs = stmt.executeQuery()) {
                while (rs.next()) {
                    counts.put(rs.getString("reaction_type"), rs.getInt("count"));
                }
            }
        }
        return counts;
    }

    // Compter le total des réactions pour un bien
    public int countTotalReactionsByPropertyId(int propertyId) throws SQLException {
        String sql = "SELECT COUNT(*) FROM property_reactions WHERE property_id = ?";
        
        try (PreparedStatement stmt = connection.prepareStatement(sql)) {
            stmt.setInt(1, propertyId);
            
            try (ResultSet rs = stmt.executeQuery()) {
                if (rs.next()) {
                    return rs.getInt(1);
                }
            }
        }
        return 0;
    }

    // Vérifier si un visiteur a déjà réagi
    public boolean hasVisitorReacted(int propertyId, String visitorIdentifier) throws SQLException {
        String sql = "SELECT id FROM property_reactions WHERE property_id = ? AND visitor_identifier = ?";
        
        try (PreparedStatement stmt = connection.prepareStatement(sql)) {
            stmt.setInt(1, propertyId);
            stmt.setString(2, visitorIdentifier);
            
            try (ResultSet rs = stmt.executeQuery()) {
                return rs.next();
            }
        }
    }

    // Méthode utilitaire
    private PropertyReaction mapResultSetToReaction(ResultSet rs) throws SQLException {
        PropertyReaction reaction = new PropertyReaction();
        reaction.setId(rs.getInt("id"));
        reaction.setPropertyId(rs.getInt("property_id"));
        reaction.setVisitorIdentifier(rs.getString("visitor_identifier"));
        reaction.setReactionType(rs.getString("reaction_type"));
        reaction.setCreatedAt(rs.getTimestamp("created_at"));
        return reaction;
    }
}