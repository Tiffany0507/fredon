package com.immobilier.servlet;

import java.io.IOException;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.annotation.MultipartConfig;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

@WebServlet("/admin/edit-property")
@MultipartConfig
public class EditPropertyServlet extends HttpServlet {
    
    protected void doPost(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        
        HttpSession session = request.getSession();
        Integer adminId = (Integer) session.getAttribute("adminId");
        
        if (adminId == null) {
            response.sendRedirect(request.getContextPath() + "/login");
            return;
        }
        
        int propertyId = Integer.parseInt(request.getParameter("id"));
        String title = request.getParameter("title");
        String type = request.getParameter("type");
        String location = request.getParameter("location");
        String description = request.getParameter("description");
        
        // Récupération et nettoyage du prix
        long price = 0;
        String priceStr = request.getParameter("price");
        if (priceStr != null && !priceStr.isEmpty()) {
            priceStr = priceStr.replaceAll("[^0-9]", "");
            if (!priceStr.isEmpty()) {
                price = Long.parseLong(priceStr);
            }
        }
        
        String latitude = request.getParameter("latitude");
        String longitude = request.getParameter("longitude");
        
        // Pour maison
        Integer surface = null;
        Integer rooms = null;
        Integer bedrooms = null;
        
        try { surface = Integer.parseInt(request.getParameter("surface")); } catch(Exception e) {}
        try { rooms = Integer.parseInt(request.getParameter("rooms")); } catch(Exception e) {}
        try { bedrooms = Integer.parseInt(request.getParameter("bedrooms")); } catch(Exception e) {}
        
        // Pour terrain
        String landArea = request.getParameter("landArea");
        String landType = request.getParameter("landType");
        String landDocumentation = request.getParameter("landDocumentation");
        String landAccess = request.getParameter("landAccess");
        String landProximities = request.getParameter("landProximities");
        String landNotes = request.getParameter("landNotes");
        
        String DB_URL = "jdbc:mysql://localhost:3306/quickchat";
        String DB_USER = "root";
        String DB_PASSWORD = "";
        
        try {
            Class.forName("com.mysql.cj.jdbc.Driver");
            Connection conn = DriverManager.getConnection(DB_URL, DB_USER, DB_PASSWORD);
            
            // Requête UPDATE avec TOUTES les colonnes existantes
            String sql = "UPDATE properties SET title=?, type=?, location=?, description=?, price=?, " +
                        "latitude=?, longitude=?, surface=?, rooms=?, bedrooms=?, " +
                        "land_area=?, land_type=?, land_documentation=?, land_access=?, " +
                        "land_proximities=?, land_notes=? WHERE id=?";
            
            PreparedStatement pstmt = conn.prepareStatement(sql);
            pstmt.setString(1, title);
            pstmt.setString(2, type);
            pstmt.setString(3, location);
            pstmt.setString(4, description);
            pstmt.setLong(5, price);
            pstmt.setString(6, latitude);
            pstmt.setString(7, longitude);
            
            if (surface != null) pstmt.setInt(8, surface);
            else pstmt.setNull(8, java.sql.Types.INTEGER);
            
            if (rooms != null) pstmt.setInt(9, rooms);
            else pstmt.setNull(9, java.sql.Types.INTEGER);
            
            if (bedrooms != null) pstmt.setInt(10, bedrooms);
            else pstmt.setNull(10, java.sql.Types.INTEGER);
            
            pstmt.setString(11, landArea);
            pstmt.setString(12, landType);
            pstmt.setString(13, landDocumentation);
            pstmt.setString(14, landAccess);
            pstmt.setString(15, landProximities);
            pstmt.setString(16, landNotes);
            pstmt.setInt(17, propertyId);
            
            int result = pstmt.executeUpdate();
            System.out.println("=== MODIFICATION PROPRIÉTÉ ===");
            System.out.println("ID: " + propertyId);
            System.out.println("Titre: " + title);
            System.out.println("Prix: " + price);
            System.out.println("Lignes affectées: " + result);
            
            pstmt.close();
            conn.close();
            
            if (result > 0) {
                response.sendRedirect(request.getContextPath() + "/admin/dashboard?success=property_updated");
            } else {
                response.sendRedirect(request.getContextPath() + "/admin/edit-property?id=" + propertyId + "&error=Aucune modification effectuée");
            }
            
        } catch (Exception e) {
            e.printStackTrace();
            response.sendRedirect(request.getContextPath() + "/admin/edit-property?id=" + propertyId + "&error=" + e.getMessage());
        }
    }
}