package com.quickchat.dao;

import java.sql.*;
import com.quickchat.utils.DatabaseConnection;

public class PasswordResetDAO {
    
    // Générer un code aléatoire à 6 chiffres et le sauvegarder
    public String generateResetCode(int userId) {
        String code = String.format("%06d", (int)(Math.random() * 1000000));
        String sql = "INSERT INTO password_reset_codes (user_id, code, expires_at) VALUES (?, ?, DATE_ADD(NOW(), INTERVAL 15 MINUTE))";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            
            pstmt.setInt(1, userId);
            pstmt.setString(2, code);
            int result = pstmt.executeUpdate();
            
            if (result > 0) {
                return code;
            }
            
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return null;
    }
    
    // Générer un code pour ADMIN
    public String generateResetCodeForAdmin(int adminId) {
        String code = String.format("%06d", (int)(Math.random() * 1000000));
        String sql = "INSERT INTO password_reset_codes (user_id, code, expires_at) VALUES (?, ?, DATE_ADD(NOW(), INTERVAL 15 MINUTE))";
        
        System.out.println("=== generateResetCodeForAdmin ===");
        System.out.println("adminId: " + adminId);
        System.out.println("code: " + code);
        
        try {
            Connection conn = DatabaseConnection.getConnection();
            System.out.println("Connexion DB: " + (conn != null ? "OK" : "NULL"));
            
            PreparedStatement stmt = conn.prepareStatement(sql);
            stmt.setInt(1, adminId);
            stmt.setString(2, code);
            
            int result = stmt.executeUpdate();
            System.out.println("Result: " + result);
            
            stmt.close();
            conn.close();
            
            if (result > 0) {
                return code;
            }
        } catch (SQLException e) {
            System.out.println("SQL Error: " + e.getMessage());
            e.printStackTrace();
        }
        return null;
    }
    
    // Vérifier si le code est valide (existe et pas expiré)
    public boolean verifyCode(int userId, String code) {
        String sql = "SELECT * FROM password_reset_codes WHERE user_id = ? AND code = ? AND expires_at > NOW()";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            
            pstmt.setInt(1, userId);
            pstmt.setString(2, code);
            ResultSet rs = pstmt.executeQuery();
            
            if (rs.next()) {
                deleteCode(userId, code);
                return true;
            }
            
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return false;
    }
    
    // Supprimer un code (après utilisation ou expiration)
    private void deleteCode(int userId, String code) {
        String sql = "DELETE FROM password_reset_codes WHERE user_id = ? AND code = ?";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            
            pstmt.setInt(1, userId);
            pstmt.setString(2, code);
            pstmt.executeUpdate();
            
        } catch (SQLException e) {
            e.printStackTrace();
        }
    }
    
    // Nettoyer tous les codes expirés
    public void cleanExpiredCodes() {
        String sql = "DELETE FROM password_reset_codes WHERE expires_at < NOW()";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            
            pstmt.executeUpdate();
            
        } catch (SQLException e) {
            e.printStackTrace();
        }
    }
}