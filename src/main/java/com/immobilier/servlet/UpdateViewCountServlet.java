package com.immobilier.servlet;

import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.io.PrintWriter;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.ResultSet;

@WebServlet("/update-view")
public class UpdateViewCountServlet extends HttpServlet {
    private static final String DB_URL = "jdbc:mysql://localhost:3306/quickchat";
    private static final String DB_USER = "root";
    private static final String DB_PASSWORD = "";

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws IOException {
        String propertyIdStr = request.getParameter("propertyId");
        
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        PrintWriter out = response.getWriter();
        
        if (propertyIdStr == null || propertyIdStr.trim().isEmpty()) {
            out.print("{\"success\":false,\"error\":\"ID manquant\"}");
            return;
        }
        
        int propertyId = Integer.parseInt(propertyIdStr);
        
        try {
            Class.forName("com.mysql.cj.jdbc.Driver");
            Connection conn = DriverManager.getConnection(DB_URL, DB_USER, DB_PASSWORD);
            
            // Incrémenter les vues
            String updateSql = "UPDATE properties SET views_count = views_count + 1 WHERE id = ?";
            PreparedStatement updateStmt = conn.prepareStatement(updateSql);
            updateStmt.setInt(1, propertyId);
            updateStmt.executeUpdate();
            updateStmt.close();
            
            // Récupérer le nouveau compteur
            String selectSql = "SELECT views_count FROM properties WHERE id = ?";
            PreparedStatement selectStmt = conn.prepareStatement(selectSql);
            selectStmt.setInt(1, propertyId);
            ResultSet rs = selectStmt.executeQuery();
            
            if (rs.next()) {
                int views = rs.getInt("views_count");
                out.print("{\"success\":true,\"views\":" + views + "}");
            } else {
                out.print("{\"success\":false,\"error\":\"Propriété non trouvée\"}");
            }
            
            rs.close();
            selectStmt.close();
            conn.close();
            
        } catch (Exception e) {
            e.printStackTrace();
            out.print("{\"success\":false,\"error\":\"" + e.getMessage() + "\"}");
        }
        
        out.flush();
    }
}