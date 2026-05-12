package com.quickchat.dao;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;
import com.quickchat.model.User;
import com.quickchat.utils.DatabaseConnection;
import com.quickchat.utils.PasswordUtil;

public class UserDAO {
    
    public boolean createUser(User user) {
        String sql = "INSERT INTO users (username, email, password, full_name, profile_pic, display_name, phone, bio) VALUES (?, ?, ?, ?, ?, ?, ?, ?)";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            
            String hashedPassword = PasswordUtil.hashPassword(user.getPassword());
            
            pstmt.setString(1, user.getUsername());
            pstmt.setString(2, user.getEmail());
            pstmt.setString(3, hashedPassword);
            pstmt.setString(4, user.getFullName());
            pstmt.setString(5, user.getProfilePic());
            pstmt.setString(6, user.getDisplayName());
            pstmt.setString(7, user.getPhone());
            pstmt.setString(8, user.getBio());
            
            int affected = pstmt.executeUpdate();
            
            if (affected > 0) {
                ResultSet rs = pstmt.getGeneratedKeys();
                if (rs.next()) {
                    user.setId(rs.getInt(1));
                    System.out.println("✅ Nouvel utilisateur créé avec ID: " + user.getId());
                }
                rs.close();
                return true;
            }
            
            return false;
            
        } catch (SQLException e) {
            e.printStackTrace();
            return false;
        }
    }
    
    public User login(String username, String password) {
        String sql = "SELECT * FROM users WHERE username = ?";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            
            pstmt.setString(1, username);
            ResultSet rs = pstmt.executeQuery();
            
            if (rs.next()) {
                if (PasswordUtil.checkPassword(password, rs.getString("password"))) {
                    return mapResultSetToUser(rs);
                }
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return null;
    }
    
    public User loginByEmail(String email, String password) {
        String sql = "SELECT * FROM users WHERE email = ?";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            
            pstmt.setString(1, email);
            ResultSet rs = pstmt.executeQuery();
            
            if (rs.next()) {
                if (PasswordUtil.checkPassword(password, rs.getString("password"))) {
                    User user = mapResultSetToUser(rs);
                    System.out.println("✅ Connexion par email réussie pour: " + email);
                    return user;
                } else {
                    System.out.println("❌ Mot de passe incorrect pour: " + email);
                }
            } else {
                System.out.println("❌ Aucun utilisateur trouvé avec l'email: " + email);
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return null;
    }
    
    public List<User> getAllUsersExcept(int userId) {
        List<User> users = new ArrayList<>();
        String sql = "SELECT id, username, email, full_name, status, profile_pic, display_name, phone, bio, created_at, last_seen FROM users WHERE id != ? ORDER BY username";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            
            pstmt.setInt(1, userId);
            ResultSet rs = pstmt.executeQuery();
            
            while (rs.next()) {
                users.add(mapResultSetToUser(rs));
            }
            
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return users;
    }
    
    public User getUserById(int id) {
        String sql = "SELECT id, username, email, full_name, status, profile_pic, display_name, phone, bio, created_at, last_seen FROM users WHERE id = ?";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            
            pstmt.setInt(1, id);
            ResultSet rs = pstmt.executeQuery();
            
            if (rs.next()) {
                return mapResultSetToUser(rs);
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return null;
    }
    
    public User getUserByEmail(String email) {
        System.out.println("=== getUserByEmail ===");
        System.out.println("Email recherché: '" + email + "'");
        
        String sql = "SELECT id, username, email, full_name, status, profile_pic, display_name, phone, bio, created_at, last_seen FROM users WHERE email = ?";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            
            pstmt.setString(1, email.trim());
            System.out.println("Requête SQL préparée avec email: " + email.trim());
            
            ResultSet rs = pstmt.executeQuery();
            
            if (rs.next()) {
                System.out.println("✅ Utilisateur trouvé: " + rs.getString("email"));
                return mapResultSetToUser(rs);
            } else {
                System.out.println("❌ Aucun utilisateur trouvé avec l'email: " + email);
            }
        } catch (SQLException e) {
            System.out.println("❌ Erreur SQL dans getUserByEmail: " + e.getMessage());
            e.printStackTrace();
        }
        return null;
    }
    
    public User getUserByUsername(String username) {
        String sql = "SELECT id, username, email, full_name, status, profile_pic, display_name, phone, bio, created_at, last_seen FROM users WHERE username = ?";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            
            pstmt.setString(1, username);
            ResultSet rs = pstmt.executeQuery();
            
            if (rs.next()) {
                return mapResultSetToUser(rs);
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return null;
    }
    
    public boolean updatePassword(int userId, String newPassword) {
        String sql = "UPDATE users SET password = ? WHERE id = ?";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            
            pstmt.setString(1, PasswordUtil.hashPassword(newPassword));
            pstmt.setInt(2, userId);
            
            return pstmt.executeUpdate() > 0;
            
        } catch (SQLException e) {
            e.printStackTrace();
            return false;
        }
    }
    
    public boolean updateStatus(int userId, String status) {
        String sql = "UPDATE users SET status = ? WHERE id = ?";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            
            pstmt.setString(1, status);
            pstmt.setInt(2, userId);
            
            return pstmt.executeUpdate() > 0;
            
        } catch (SQLException e) {
            e.printStackTrace();
            return false;
        }
    }
    
    public boolean updateProfilePic(int userId, String profilePicFilename) {
        String sql = "UPDATE users SET profile_pic = ? WHERE id = ?";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            
            pstmt.setString(1, profilePicFilename);
            pstmt.setInt(2, userId);
            
            return pstmt.executeUpdate() > 0;
            
        } catch (SQLException e) {
            e.printStackTrace();
            return false;
        }
    }
    
    public boolean updateLastSeen(int userId) {
        String sql = "UPDATE users SET last_seen = NOW() WHERE id = ?";
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setInt(1, userId);
            return stmt.executeUpdate() > 0;
        } catch (SQLException e) {
            e.printStackTrace();
            return false;
        }
    }

    public String getLastSeen(int userId) {
        String sql = "SELECT last_seen FROM users WHERE id = ?";
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setInt(1, userId);
            ResultSet rs = stmt.executeQuery();
            if (rs.next()) {
                return rs.getString("last_seen");
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return null;
    }
    
    public boolean updateDisplayName(int userId, String displayName) {
        String sql = "UPDATE users SET display_name = ? WHERE id = ?";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            
            pstmt.setString(1, displayName);
            pstmt.setInt(2, userId);
            
            return pstmt.executeUpdate() > 0;
            
        } catch (SQLException e) {
            e.printStackTrace();
            return false;
        }
    }
    
    public boolean updateFullName(int userId, String fullName) {
        String sql = "UPDATE users SET full_name = ? WHERE id = ?";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            
            pstmt.setString(1, fullName);
            pstmt.setInt(2, userId);
            
            return pstmt.executeUpdate() > 0;
            
        } catch (SQLException e) {
            e.printStackTrace();
            return false;
        }
    }
    
    // ========== NOUVEAUX MÉTHODES POUR PHONE ET BIO ==========
    
    public boolean updatePhone(int userId, String phone) {
        String sql = "UPDATE users SET phone = ? WHERE id = ?";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            
            pstmt.setString(1, phone);
            pstmt.setInt(2, userId);
            
            return pstmt.executeUpdate() > 0;
            
        } catch (SQLException e) {
            e.printStackTrace();
            return false;
        }
    }
    
    public boolean updateBio(int userId, String bio) {
        String sql = "UPDATE users SET bio = ? WHERE id = ?";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            
            pstmt.setString(1, bio);
            pstmt.setInt(2, userId);
            
            return pstmt.executeUpdate() > 0;
            
        } catch (SQLException e) {
            e.printStackTrace();
            return false;
        }
    }
    
    public boolean updateUserProfile(int userId, String displayName, String email, String phone, String bio) {
        String sql = "UPDATE users SET display_name = ?, email = ?, phone = ?, bio = ? WHERE id = ?";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            
            pstmt.setString(1, displayName);
            pstmt.setString(2, email);
            pstmt.setString(3, phone);
            pstmt.setString(4, bio);
            pstmt.setInt(5, userId);
            
            return pstmt.executeUpdate() > 0;
            
        } catch (SQLException e) {
            e.printStackTrace();
            return false;
        }
    }
    
    // ========== MÉTHODES EXISTANTES ==========
    
    public boolean emailExists(String email) {
        String sql = "SELECT COUNT(*) FROM users WHERE email = ?";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            
            pstmt.setString(1, email);
            ResultSet rs = pstmt.executeQuery();
            
            if (rs.next()) {
                return rs.getInt(1) > 0;
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return false;
    }
    
    public boolean usernameExists(String username) {
        String sql = "SELECT COUNT(*) FROM users WHERE username = ?";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            
            pstmt.setString(1, username);
            ResultSet rs = pstmt.executeQuery();
            
            if (rs.next()) {
                return rs.getInt(1) > 0;
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return false;
    }
 
    private User mapResultSetToUser(ResultSet rs) throws SQLException {
        User user = new User();
        user.setId(rs.getInt("id"));
        user.setUsername(rs.getString("username"));
        user.setEmail(rs.getString("email"));
        user.setFullName(rs.getString("full_name"));
        user.setStatus(rs.getString("status"));
        user.setProfilePic(rs.getString("profile_pic"));
        user.setDisplayName(rs.getString("display_name"));
        
        // AJOUT : récupérer phone et bio
        try {
            user.setPhone(rs.getString("phone"));
        } catch (SQLException e) {
            user.setPhone(null);
        }
        try {
            user.setBio(rs.getString("bio"));
        } catch (SQLException e) {
            user.setBio(null);
        }
        
        try {
            user.setCreatedAt(rs.getString("created_at"));
        } catch (SQLException e) {
            user.setCreatedAt(null);
        }
        try {
            user.setLastSeen(rs.getString("last_seen"));
        } catch (SQLException e) {
            user.setLastSeen(null);
        }
        
        return user;
    }
}