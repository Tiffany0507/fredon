package com.quickchat.servlet;

import java.io.*;
import java.sql.*;
import javax.servlet.*;
import javax.servlet.annotation.*;
import javax.servlet.http.*;

@WebServlet("/admin/mark-property-sold")
public class MarkPropertySoldServlet extends HttpServlet {
    
    protected void doPost(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        
        int propertyId = Integer.parseInt(request.getParameter("propertyId"));
        int clientId = Integer.parseInt(request.getParameter("clientId"));
        
        String DB_URL = "jdbc:mysql://localhost:3306/quickchat";
        String DB_USER = "root";
        String DB_PASSWORD = "";
        
        try {
            Class.forName("com.mysql.cj.jdbc.Driver");
            Connection conn = DriverManager.getConnection(DB_URL, DB_USER, DB_PASSWORD);
            
            // 1. Récupérer le prix du bien
            double price = 0;
            PreparedStatement psPrice = conn.prepareStatement("SELECT price FROM properties WHERE id = ?");
            psPrice.setInt(1, propertyId);
            ResultSet rsPrice = psPrice.executeQuery();
            if (rsPrice.next()) price = rsPrice.getDouble("price");
            rsPrice.close();
            psPrice.close();
            
            // 2. Mettre à jour properties (status, buyer_id, sold_at) - CORRIGÉ : supprimé updated_at
            PreparedStatement psUpdate = conn.prepareStatement(
                "UPDATE properties SET status = 'sold', buyer_id = ?, sold_at = NOW() WHERE id = ?"
            );
            psUpdate.setInt(1, clientId);
            psUpdate.setInt(2, propertyId);
            psUpdate.executeUpdate();
            psUpdate.close();
            
            // 3. Ajouter dans property_transactions
            PreparedStatement psTransaction = conn.prepareStatement(
                "INSERT INTO property_transactions (property_id, buyer_id, amount, purchase_date, status) VALUES (?, ?, ?, NOW(), 'completed')"
            );
            psTransaction.setInt(1, propertyId);
            psTransaction.setInt(2, clientId);
            psTransaction.setDouble(3, price);
            psTransaction.executeUpdate();
            psTransaction.close();
            
            // 4. Mettre à jour la caisse (total_cash dans settings)
            PreparedStatement psCash = conn.prepareStatement(
                "UPDATE settings SET total_cash = total_cash + ? WHERE id = 1"
            );
            psCash.setDouble(1, price);
            psCash.executeUpdate();
            psCash.close();
            
            conn.close();
            
            response.getWriter().print("{\"success\": true}");
            
        } catch(Exception e) {
            e.printStackTrace();
            response.getWriter().print("{\"success\": false, \"error\": \"" + e.getMessage().replace("\"", "\\\"") + "\"}");
        }
    }
}