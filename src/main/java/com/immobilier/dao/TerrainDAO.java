package com.immobilier.dao;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.ArrayList;
import java.util.List;
import com.immobilier.model.Terrain;

public class TerrainDAO {
    
    private static final String DB_URL = "jdbc:mysql://localhost:3306/quickchat";
    private static final String DB_USER = "root";
    private static final String DB_PASSWORD = "";
    
    private Connection getConnection() throws SQLException {
        try {
            Class.forName("com.mysql.cj.jdbc.Driver");
        } catch (ClassNotFoundException e) {
            e.printStackTrace();
        }
        return DriverManager.getConnection(DB_URL, DB_USER, DB_PASSWORD);
    }
    
    public int createTerrain(String titre, String description, double superficie,
                             double prix, String localisation, String statut, int adminId) throws SQLException {
        String sql = "INSERT INTO terrains (titre, description, superficie, " +
                     "prix, localisation, statut, admin_id) VALUES (?, ?, ?, ?, ?, ?, ?)";
        
        try (Connection conn = getConnection();
             PreparedStatement ps = conn.prepareStatement(sql, 
                     Statement.RETURN_GENERATED_KEYS)) {
            
            ps.setString(1, titre);
            ps.setString(2, description);
            ps.setDouble(3, superficie);
            ps.setDouble(4, prix);
            ps.setString(5, localisation);
            ps.setString(6, statut);
            ps.setInt(7, adminId);
            
            ps.executeUpdate();
            
            try (ResultSet rs = ps.getGeneratedKeys()) {
                if (rs.next()) {
                    return rs.getInt(1);
                }
            }
        }
        return -1;
    }
    
    public List<Terrain> getAllTerrains() throws SQLException {
        List<Terrain> terrains = new ArrayList<>();
        String sql = "SELECT * FROM terrains ORDER BY created_at DESC";
        
        try (Connection conn = getConnection();
             Statement stmt = conn.createStatement();
             ResultSet rs = stmt.executeQuery(sql)) {
            
            while (rs.next()) {
                Terrain t = new Terrain();
                t.setId(rs.getInt("id"));
                t.setTitre(rs.getString("titre"));
                t.setDescription(rs.getString("description"));
                t.setSuperficie(rs.getDouble("superficie"));
                t.setPrix(rs.getDouble("prix"));
                t.setLocalisation(rs.getString("localisation"));
                t.setStatut(rs.getString("statut"));
                t.setAdminId(rs.getInt("admin_id"));
                t.setCreatedAt(rs.getTimestamp("created_at"));
                terrains.add(t);
            }
        }
        return terrains;
    }
    
    public boolean deleteTerrain(int id) throws SQLException {
        String sql = "DELETE FROM terrains WHERE id = ?";
        
        try (Connection conn = getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            
            ps.setInt(1, id);
            return ps.executeUpdate() > 0;
        }
    }
}