package com.immobilier.dao;

import com.immobilier.model.Comment;
import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class CommentDAO {

    private Connection connection;

    public CommentDAO(Connection connection) {
        this.connection = connection;
    }

    // Ajouter un commentaire
    public boolean addComment(Comment comment) throws SQLException {
        String sql = "INSERT INTO comments (property_id, visitor_name, visitor_email, content, is_approved) VALUES (?, ?, ?, ?, ?)";
        
        try (PreparedStatement stmt = connection.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            stmt.setInt(1, comment.getPropertyId());
            stmt.setString(2, comment.getVisitorName());
            stmt.setString(3, comment.getVisitorEmail());
            stmt.setString(4, comment.getContent());
            stmt.setBoolean(5, comment.isApproved());

            int rowsAffected = stmt.executeUpdate();
            
            try (ResultSet generatedKeys = stmt.getGeneratedKeys()) {
                if (generatedKeys.next()) {
                    comment.setId(generatedKeys.getInt(1));
                }
            }
            
            return rowsAffected > 0;
        }
    }

    // Récupérer tous les commentaires d'un bien (approuvés uniquement)
    public List<Comment> getApprovedCommentsByPropertyId(int propertyId) throws SQLException {
        List<Comment> comments = new ArrayList<>();
        String sql = "SELECT * FROM comments WHERE property_id = ? AND is_approved = true ORDER BY created_at DESC";
        
        try (PreparedStatement stmt = connection.prepareStatement(sql)) {
            stmt.setInt(1, propertyId);
            
            try (ResultSet rs = stmt.executeQuery()) {
                while (rs.next()) {
                    comments.add(mapResultSetToComment(rs));
                }
            }
        }
        return comments;
    }

    // Récupérer tous les commentaires d'un bien (admin)
    public List<Comment> getAllCommentsByPropertyId(int propertyId) throws SQLException {
        List<Comment> comments = new ArrayList<>();
        String sql = "SELECT * FROM comments WHERE property_id = ? ORDER BY created_at DESC";
        
        try (PreparedStatement stmt = connection.prepareStatement(sql)) {
            stmt.setInt(1, propertyId);
            
            try (ResultSet rs = stmt.executeQuery()) {
                while (rs.next()) {
                    comments.add(mapResultSetToComment(rs));
                }
            }
        }
        return comments;
    }

    // Récupérer tous les commentaires en attente (non approuvés)
    public List<Comment> getPendingComments() throws SQLException {
        List<Comment> comments = new ArrayList<>();
        String sql = "SELECT c.*, p.title as property_title FROM comments c JOIN properties p ON c.property_id = p.id WHERE c.is_approved = false ORDER BY c.created_at ASC";
        
        try (Statement stmt = connection.createStatement();
             ResultSet rs = stmt.executeQuery(sql)) {
            
            while (rs.next()) {
                comments.add(mapResultSetToComment(rs));
            }
        }
        return comments;
    }

    // Approuver un commentaire
    public boolean approveComment(int id) throws SQLException {
        String sql = "UPDATE comments SET is_approved = true WHERE id = ?";
        
        try (PreparedStatement stmt = connection.prepareStatement(sql)) {
            stmt.setInt(1, id);
            return stmt.executeUpdate() > 0;
        }
    }

    // Supprimer un commentaire
    public boolean deleteComment(int id) throws SQLException {
        String sql = "DELETE FROM comments WHERE id = ?";
        
        try (PreparedStatement stmt = connection.prepareStatement(sql)) {
            stmt.setInt(1, id);
            return stmt.executeUpdate() > 0;
        }
    }

    // Compter les commentaires d'un bien
    public int countCommentsByPropertyId(int propertyId) throws SQLException {
        String sql = "SELECT COUNT(*) FROM comments WHERE property_id = ? AND is_approved = true";
        
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

    // Méthode utilitaire
    private Comment mapResultSetToComment(ResultSet rs) throws SQLException {
        Comment comment = new Comment();
        comment.setId(rs.getInt("id"));
        comment.setPropertyId(rs.getInt("property_id"));
        comment.setVisitorName(rs.getString("visitor_name"));
        comment.setVisitorEmail(rs.getString("visitor_email"));
        comment.setContent(rs.getString("content"));
        comment.setApproved(rs.getBoolean("is_approved"));
        comment.setCreatedAt(rs.getTimestamp("created_at"));
        return comment;
    }
}