package com.immobilier.servlet;

import java.io.IOException;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

@WebServlet("/admin/delete-property")
public class DeletePropertyServlet extends HttpServlet {
    
    private static final String DB_URL = "jdbc:mysql://localhost:3306/quickchat";
    private static final String DB_USER = "root";
    private static final String DB_PASSWORD = "";
    
    protected void doPost(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        
        String propertyId = request.getParameter("id");
        
        if (propertyId == null || propertyId.trim().isEmpty()) {
            response.sendRedirect(request.getContextPath() + "/immo/admin/dashboard.jsp?error=missing_id");
            return;
        }
        
        try {
            Class.forName("com.mysql.cj.jdbc.Driver");
            Connection conn = DriverManager.getConnection(DB_URL, DB_USER, DB_PASSWORD);
            
            // Supprimer les images
            PreparedStatement pstmtImages = conn.prepareStatement("DELETE FROM property_images WHERE property_id = ?");
            pstmtImages.setInt(1, Integer.parseInt(propertyId));
            pstmtImages.executeUpdate();
            pstmtImages.close();
            
            // Supprimer les favoris
            PreparedStatement pstmtFavs = conn.prepareStatement("DELETE FROM user_favorites WHERE property_id = ?");
            pstmtFavs.setInt(1, Integer.parseInt(propertyId));
            pstmtFavs.executeUpdate();
            pstmtFavs.close();
            
            // Supprimer les réactions
            PreparedStatement pstmtReactions = conn.prepareStatement("DELETE FROM property_reactions WHERE property_id = ?");
            pstmtReactions.setInt(1, Integer.parseInt(propertyId));
            pstmtReactions.executeUpdate();
            pstmtReactions.close();
            
            // Supprimer les commentaires
            PreparedStatement pstmtComments = conn.prepareStatement("DELETE FROM comments WHERE property_id = ?");
            pstmtComments.setInt(1, Integer.parseInt(propertyId));
            pstmtComments.executeUpdate();
            pstmtComments.close();
            
            // Supprimer le bien
            PreparedStatement pstmtProp = conn.prepareStatement("DELETE FROM properties WHERE id = ?");
            pstmtProp.setInt(1, Integer.parseInt(propertyId));
            pstmtProp.executeUpdate();
            pstmtProp.close();
            
            conn.close();
            
            response.sendRedirect(request.getContextPath() + "/immo/admin/dashboard.jsp?success=property_deleted");
            
        } catch (Exception e) {
            e.printStackTrace();
            response.sendRedirect(request.getContextPath() + "/immo/admin/dashboard.jsp?error=delete_failed");
        }
    }
}