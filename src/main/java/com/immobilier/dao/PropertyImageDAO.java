package com.immobilier.dao;

import com.immobilier.model.PropertyImage;
import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class PropertyImageDAO {

    private Connection connection;

    public PropertyImageDAO(Connection connection) {
        this.connection = connection;
    }

    // Ajouter une image
    public boolean addImage(PropertyImage image) throws SQLException {
        String sql = "INSERT INTO property_images (property_id, image_url, is_primary) VALUES (?, ?, ?)";
        
        try (PreparedStatement stmt = connection.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            stmt.setInt(1, image.getPropertyId());
            stmt.setString(2, image.getImageUrl());
            stmt.setBoolean(3, image.isPrimary());

            int rowsAffected = stmt.executeUpdate();
            
            try (ResultSet generatedKeys = stmt.getGeneratedKeys()) {
                if (generatedKeys.next()) {
                    image.setId(generatedKeys.getInt(1));
                }
            }
            
            return rowsAffected > 0;
        }
    }

    // Récupérer toutes les images d'un bien
    public List<PropertyImage> getImagesByPropertyId(int propertyId) throws SQLException {
        List<PropertyImage> images = new ArrayList<>();
        String sql = "SELECT * FROM property_images WHERE property_id = ? ORDER BY is_primary DESC, created_at ASC";
        
        try (PreparedStatement stmt = connection.prepareStatement(sql)) {
            stmt.setInt(1, propertyId);
            
            try (ResultSet rs = stmt.executeQuery()) {
                while (rs.next()) {
                    images.add(mapResultSetToPropertyImage(rs));
                }
            }
        }
        return images;
    }

    // Récupérer l'image principale d'un bien
    public PropertyImage getPrimaryImageByPropertyId(int propertyId) throws SQLException {
        String sql = "SELECT * FROM property_images WHERE property_id = ? AND is_primary = true LIMIT 1";
        
        try (PreparedStatement stmt = connection.prepareStatement(sql)) {
            stmt.setInt(1, propertyId);
            
            try (ResultSet rs = stmt.executeQuery()) {
                if (rs.next()) {
                    return mapResultSetToPropertyImage(rs);
                }
            }
        }
        return null;
    }

    // Définir une image comme principale
    public boolean setAsPrimary(int imageId, int propertyId) throws SQLException {
        // D'abord, enlever le statut primary de toutes les images du bien
        String resetSql = "UPDATE property_images SET is_primary = false WHERE property_id = ?";
        try (PreparedStatement stmt = connection.prepareStatement(resetSql)) {
            stmt.setInt(1, propertyId);
            stmt.executeUpdate();
        }
        
        // Ensuite, définir la nouvelle image principale
        String updateSql = "UPDATE property_images SET is_primary = true WHERE id = ?";
        try (PreparedStatement stmt = connection.prepareStatement(updateSql)) {
            stmt.setInt(1, imageId);
            return stmt.executeUpdate() > 0;
        }
    }

    // Supprimer une image
    public boolean deleteImage(int id) throws SQLException {
        String sql = "DELETE FROM property_images WHERE id = ?";
        
        try (PreparedStatement stmt = connection.prepareStatement(sql)) {
            stmt.setInt(1, id);
            return stmt.executeUpdate() > 0;
        }
    }

    // Supprimer toutes les images d'un bien
    public boolean deleteImagesByPropertyId(int propertyId) throws SQLException {
        String sql = "DELETE FROM property_images WHERE property_id = ?";
        
        try (PreparedStatement stmt = connection.prepareStatement(sql)) {
            stmt.setInt(1, propertyId);
            return stmt.executeUpdate() > 0;
        }
    }

    // Méthode utilitaire - CORRIGÉE (supprimé setCreatedAt)
    private PropertyImage mapResultSetToPropertyImage(ResultSet rs) throws SQLException {
        PropertyImage image = new PropertyImage();
        image.setId(rs.getInt("id"));
        image.setPropertyId(rs.getInt("property_id"));
        image.setImageUrl(rs.getString("image_url"));
        image.setPrimary(rs.getBoolean("is_primary"));
        // La ligne suivante a été supprimée car setCreatedAt n'existe pas dans PropertyImage
        // image.setCreatedAt(rs.getTimestamp("created_at"));
        return image;
    }
}