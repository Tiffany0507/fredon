package com.immobilier.dao;

import com.immobilier.model.Property;
import java.math.BigDecimal;
import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class PropertyDAO {

    private Connection connection;

    public PropertyDAO(Connection connection) {
        this.connection = connection;
    }

    public boolean addProperty(Property property) throws SQLException {
        String sql = "INSERT INTO properties (title, description, price, location, type, surface, rooms, bedrooms, bathrooms, admin_id, views_count, latitude, longitude, image_path, land_area, land_type, land_documentation, land_access, land_proximities, land_notes, status) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 0, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'available')";
        
        try (PreparedStatement stmt = connection.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            stmt.setString(1, property.getTitle());
            stmt.setString(2, property.getDescription());
            stmt.setBigDecimal(3, property.getPrice());
            stmt.setString(4, property.getLocation());
            stmt.setString(5, property.getType());
            
            // Surface (maison/appartement)
            if (property.getSurface() != null && property.getSurface() > 0) {
                stmt.setInt(6, property.getSurface());
            } else {
                stmt.setNull(6, Types.INTEGER);
            }
            
            // Nombre de pièces
            if (property.getRooms() != null && property.getRooms() > 0) {
                stmt.setInt(7, property.getRooms());
            } else {
                stmt.setNull(7, Types.INTEGER);
            }
            
            // Chambres
            if (property.getBedrooms() != null && property.getBedrooms() > 0) {
                stmt.setInt(8, property.getBedrooms());
            } else {
                stmt.setNull(8, Types.INTEGER);
            }
            
            // Salles de bain
            if (property.getBathrooms() != null && property.getBathrooms() > 0) {
                stmt.setInt(9, property.getBathrooms());
            } else {
                stmt.setNull(9, Types.INTEGER);
            }
            
            stmt.setInt(10, property.getAdminId());
            
            // Latitude
            if (property.getLatitude() != null) {
                stmt.setDouble(11, property.getLatitude());
            } else {
                stmt.setNull(11, Types.DOUBLE);
            }
            
            // Longitude
            if (property.getLongitude() != null) {
                stmt.setDouble(12, property.getLongitude());
            } else {
                stmt.setNull(12, Types.DOUBLE);
            }
            
            // Image principale
            if (property.getImagePath() != null && !property.getImagePath().isEmpty()) {
                stmt.setString(13, property.getImagePath());
            } else {
                stmt.setNull(13, Types.VARCHAR);
            }
            
            // ⭐⭐⭐ CHAMPS TERRAIN ⭐⭐⭐
            // Surface du terrain (land_area)
            if (property.getLandArea() != null && !property.getLandArea().isEmpty()) {
                stmt.setString(14, property.getLandArea());
            } else {
                stmt.setNull(14, Types.VARCHAR);
            }
            
            // Type de terrain (constructible, agricole, etc.)
            if (property.getLandType() != null && !property.getLandType().isEmpty()) {
                stmt.setString(15, property.getLandType());
            } else {
                stmt.setNull(15, Types.VARCHAR);
            }
            
            // Documentation (titre foncier, etc.)
            if (property.getLandDocumentation() != null && !property.getLandDocumentation().isEmpty()) {
                stmt.setString(16, property.getLandDocumentation());
            } else {
                stmt.setNull(16, Types.VARCHAR);
            }
            
            // Accès au terrain
            if (property.getLandAccess() != null && !property.getLandAccess().isEmpty()) {
                stmt.setString(17, property.getLandAccess());
            } else {
                stmt.setNull(17, Types.VARCHAR);
            }
            
            // Proximités
            if (property.getLandProximities() != null && !property.getLandProximities().isEmpty()) {
                stmt.setString(18, property.getLandProximities());
            } else {
                stmt.setNull(18, Types.VARCHAR);
            }
            
            // Notes supplémentaires
            if (property.getLandNotes() != null && !property.getLandNotes().isEmpty()) {
                stmt.setString(19, property.getLandNotes());
            } else {
                stmt.setNull(19, Types.VARCHAR);
            }

            int rowsAffected = stmt.executeUpdate();
            
            try (ResultSet generatedKeys = stmt.getGeneratedKeys()) {
                if (generatedKeys.next()) {
                    property.setId(generatedKeys.getInt(1));
                }
            }
            
            return rowsAffected > 0;
        }
    }

    public Property getPropertyById(int id) throws SQLException {
        String sql = "SELECT * FROM properties WHERE id = ?";
        
        try (PreparedStatement stmt = connection.prepareStatement(sql)) {
            stmt.setInt(1, id);
            try (ResultSet rs = stmt.executeQuery()) {
                if (rs.next()) {
                    return mapResultSetToProperty(rs);
                }
            }
        }
        return null;
    }

    public boolean updateProperty(Property property) throws SQLException {
        String sql = "UPDATE properties SET title = ?, description = ?, price = ?, location = ?, type = ?, surface = ?, rooms = ?, bedrooms = ?, bathrooms = ?, views_count = ?, latitude = ?, longitude = ?, image_path = ?, land_area = ?, land_type = ?, land_documentation = ?, land_access = ?, land_proximities = ?, land_notes = ? WHERE id = ?";
        
        try (PreparedStatement stmt = connection.prepareStatement(sql)) {
            stmt.setString(1, property.getTitle());
            stmt.setString(2, property.getDescription());
            stmt.setBigDecimal(3, property.getPrice());
            stmt.setString(4, property.getLocation());
            stmt.setString(5, property.getType());
            
            if (property.getSurface() != null && property.getSurface() > 0) {
                stmt.setInt(6, property.getSurface());
            } else {
                stmt.setNull(6, Types.INTEGER);
            }
            
            if (property.getRooms() != null && property.getRooms() > 0) {
                stmt.setInt(7, property.getRooms());
            } else {
                stmt.setNull(7, Types.INTEGER);
            }
            
            if (property.getBedrooms() != null && property.getBedrooms() > 0) {
                stmt.setInt(8, property.getBedrooms());
            } else {
                stmt.setNull(8, Types.INTEGER);
            }
            
            if (property.getBathrooms() != null && property.getBathrooms() > 0) {
                stmt.setInt(9, property.getBathrooms());
            } else {
                stmt.setNull(9, Types.INTEGER);
            }
            
            stmt.setInt(10, property.getViewsCount());
            
            if (property.getLatitude() != null) {
                stmt.setDouble(11, property.getLatitude());
            } else {
                stmt.setNull(11, Types.DOUBLE);
            }
            
            if (property.getLongitude() != null) {
                stmt.setDouble(12, property.getLongitude());
            } else {
                stmt.setNull(12, Types.DOUBLE);
            }
            
            // Image
            if (property.getImagePath() != null && !property.getImagePath().isEmpty()) {
                stmt.setString(13, property.getImagePath());
            } else {
                stmt.setNull(13, Types.VARCHAR);
            }
            
            // ⭐⭐⭐ CHAMPS TERRAIN ⭐⭐⭐
            if (property.getLandArea() != null && !property.getLandArea().isEmpty()) {
                stmt.setString(14, property.getLandArea());
            } else {
                stmt.setNull(14, Types.VARCHAR);
            }
            
            if (property.getLandType() != null && !property.getLandType().isEmpty()) {
                stmt.setString(15, property.getLandType());
            } else {
                stmt.setNull(15, Types.VARCHAR);
            }
            
            if (property.getLandDocumentation() != null && !property.getLandDocumentation().isEmpty()) {
                stmt.setString(16, property.getLandDocumentation());
            } else {
                stmt.setNull(16, Types.VARCHAR);
            }
            
            if (property.getLandAccess() != null && !property.getLandAccess().isEmpty()) {
                stmt.setString(17, property.getLandAccess());
            } else {
                stmt.setNull(17, Types.VARCHAR);
            }
            
            if (property.getLandProximities() != null && !property.getLandProximities().isEmpty()) {
                stmt.setString(18, property.getLandProximities());
            } else {
                stmt.setNull(18, Types.VARCHAR);
            }
            
            if (property.getLandNotes() != null && !property.getLandNotes().isEmpty()) {
                stmt.setString(19, property.getLandNotes());
            } else {
                stmt.setNull(19, Types.VARCHAR);
            }
            
            stmt.setInt(20, property.getId());

            return stmt.executeUpdate() > 0;
        }
    }

    public List<Property> getAllProperties() throws SQLException {
        List<Property> properties = new ArrayList<>();
        String sql = "SELECT * FROM properties ORDER BY created_at DESC";
        
        try (Statement stmt = connection.createStatement();
             ResultSet rs = stmt.executeQuery(sql)) {
            while (rs.next()) {
                properties.add(mapResultSetToProperty(rs));
            }
        }
        return properties;
    }
    
    public List<Property> getAvailableProperties() throws SQLException {
        List<Property> properties = new ArrayList<>();
        String sql = "SELECT * FROM properties WHERE (status != 'sold' OR status IS NULL) ORDER BY created_at DESC";
        try (Statement stmt = connection.createStatement();
             ResultSet rs = stmt.executeQuery(sql)) {
            while (rs.next()) {
                properties.add(mapResultSetToProperty(rs));
            }
        }
        return properties;
    }

    public List<Property> getPropertiesByBudget(long budgetMax) throws SQLException {
        List<Property> properties = new ArrayList<>();
        String sql = "SELECT * FROM properties WHERE price <= ? AND (status != 'sold' OR status IS NULL) ORDER BY created_at DESC";
        
        try (PreparedStatement stmt = connection.prepareStatement(sql)) {
            stmt.setBigDecimal(1, new BigDecimal(budgetMax));
            ResultSet rs = stmt.executeQuery();
            while (rs.next()) {
                properties.add(mapResultSetToProperty(rs));
            }
        }
        return properties;
    }

    public List<Property> getPropertiesByType(String type) throws SQLException {
        List<Property> properties = new ArrayList<>();
        String sql = "SELECT * FROM properties WHERE type = ? AND (status != 'sold' OR status IS NULL) ORDER BY created_at DESC";
        
        try (PreparedStatement stmt = connection.prepareStatement(sql)) {
            stmt.setString(1, type);
            ResultSet rs = stmt.executeQuery();
            while (rs.next()) {
                properties.add(mapResultSetToProperty(rs));
            }
        }
        return properties;
    }

    public List<Property> getPropertiesByBudgetAndType(long budgetMax, String type) throws SQLException {
        List<Property> properties = new ArrayList<>();
        String sql = "SELECT * FROM properties WHERE price <= ? AND type = ? AND (status != 'sold' OR status IS NULL) ORDER BY created_at DESC";
        
        try (PreparedStatement stmt = connection.prepareStatement(sql)) {
            stmt.setBigDecimal(1, new BigDecimal(budgetMax));
            stmt.setString(2, type);
            ResultSet rs = stmt.executeQuery();
            while (rs.next()) {
                properties.add(mapResultSetToProperty(rs));
            }
        }
        return properties;
    }

    public boolean deleteProperty(int id) throws SQLException {
        String sql = "DELETE FROM properties WHERE id = ?";
        try (PreparedStatement stmt = connection.prepareStatement(sql)) {
            stmt.setInt(1, id);
            return stmt.executeUpdate() > 0;
        }
    }

    public boolean incrementViewsCount(int propertyId) throws SQLException {
        String sql = "UPDATE properties SET views_count = views_count + 1 WHERE id = ?";
        try (PreparedStatement stmt = connection.prepareStatement(sql)) {
            stmt.setInt(1, propertyId);
            return stmt.executeUpdate() > 0;
        }
    }

    public int getViewsCount(int propertyId) throws SQLException {
        String sql = "SELECT views_count FROM properties WHERE id = ?";
        try (PreparedStatement stmt = connection.prepareStatement(sql)) {
            stmt.setInt(1, propertyId);
            ResultSet rs = stmt.executeQuery();
            if (rs.next()) {
                return rs.getInt("views_count");
            }
        }
        return 0;
    }
    
    /**
     * Récupère les propriétés vendues pour un client donné
     */
    public List<Property> getPropertiesByBuyerId(int buyerId) throws SQLException {
        List<Property> properties = new ArrayList<>();
        String sql = "SELECT * FROM properties WHERE buyer_id = ? AND status = 'sold' ORDER BY sold_at DESC";
        
        try (PreparedStatement stmt = connection.prepareStatement(sql)) {
            stmt.setInt(1, buyerId);
            ResultSet rs = stmt.executeQuery();
            while (rs.next()) {
                properties.add(mapResultSetToProperty(rs));
            }
        }
        return properties;
    }

    private Property mapResultSetToProperty(ResultSet rs) throws SQLException {
        Property property = new Property();
        property.setId(rs.getInt("id"));
        property.setTitle(rs.getString("title"));
        property.setDescription(rs.getString("description"));
        property.setPrice(rs.getBigDecimal("price"));
        property.setLocation(rs.getString("location"));
        property.setType(rs.getString("type"));
        property.setStatus(rs.getString("status"));
        
        // Surface (maison/appartement)
        Object surface = rs.getObject("surface");
        if (surface != null) property.setSurface(rs.getInt("surface"));
        
        // Nombre de pièces
        Object rooms = rs.getObject("rooms");
        if (rooms != null) property.setRooms(rs.getInt("rooms"));
        
        // Chambres
        Object bedrooms = rs.getObject("bedrooms");
        if (bedrooms != null) property.setBedrooms(rs.getInt("bedrooms"));
        
        // Salles de bain
        Object bathrooms = rs.getObject("bathrooms");
        if (bathrooms != null) property.setBathrooms(rs.getInt("bathrooms"));
        
        property.setCreatedAt(rs.getTimestamp("created_at"));
        property.setAdminId(rs.getInt("admin_id"));
        
        // Vues
        Object viewsCount = rs.getObject("views_count");
        property.setViewsCount(viewsCount != null ? rs.getInt("views_count") : 0);
        
        // Coordonnées GPS
        Object latitude = rs.getObject("latitude");
        if (latitude != null) property.setLatitude(rs.getDouble("latitude"));
        
        Object longitude = rs.getObject("longitude");
        if (longitude != null) property.setLongitude(rs.getDouble("longitude"));
        
        // Image principale
        Object imagePath = rs.getObject("image_path");
        if (imagePath != null) {
            property.setImagePath(rs.getString("image_path"));
        }
        
        // ⭐⭐⭐ CHAMPS TERRAIN ⭐⭐⭐
        Object landArea = rs.getObject("land_area");
        if (landArea != null) property.setLandArea(rs.getString("land_area"));
        
        Object landType = rs.getObject("land_type");
        if (landType != null) property.setLandType(rs.getString("land_type"));
        
        Object landDocumentation = rs.getObject("land_documentation");
        if (landDocumentation != null) property.setLandDocumentation(rs.getString("land_documentation"));
        
        Object landAccess = rs.getObject("land_access");
        if (landAccess != null) property.setLandAccess(rs.getString("land_access"));
        
        Object landProximities = rs.getObject("land_proximities");
        if (landProximities != null) property.setLandProximities(rs.getString("land_proximities"));
        
        Object landNotes = rs.getObject("land_notes");
        if (landNotes != null) property.setLandNotes(rs.getString("land_notes"));
        
        // Buyer ID et date de vente
        Object buyerId = rs.getObject("buyer_id");
        if (buyerId != null) property.setBuyerId(rs.getInt("buyer_id"));
        
        Object soldAt = rs.getObject("sold_at");
        if (soldAt != null) property.setSoldAt(rs.getTimestamp("sold_at"));
        
        return property;
    }
}