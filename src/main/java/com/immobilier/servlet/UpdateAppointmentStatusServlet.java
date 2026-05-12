package com.immobilier.servlet;

import java.io.IOException;
import java.io.PrintWriter;
import java.sql.*;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

@WebServlet("/admin/update-appointment-status")
public class UpdateAppointmentStatusServlet extends HttpServlet {
    
    private static final String DB_URL = "jdbc:mysql://localhost:3306/quickchat";
    private static final String DB_USER = "root";
    private static final String DB_PASSWORD = "";
    
    protected void doPost(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        
        response.setContentType("application/json");
        PrintWriter out = response.getWriter();
        
        String id = request.getParameter("id");
        String status = request.getParameter("status");
        
        if (id == null || status == null) {
            out.print("{\"success\": false, \"error\": \"Paramètres manquants\"}");
            return;
        }
        
        try {
            Class.forName("com.mysql.cj.jdbc.Driver");
            Connection conn = DriverManager.getConnection(DB_URL, DB_USER, DB_PASSWORD);
            
            String sql = "UPDATE appointments SET status = ? WHERE id = ?";
            PreparedStatement pstmt = conn.prepareStatement(sql);
            pstmt.setString(1, status);
            pstmt.setInt(2, Integer.parseInt(id));
            
            int result = pstmt.executeUpdate();
            pstmt.close();
            conn.close();
            
            if (result > 0) {
                out.print("{\"success\": true}");
            } else {
                out.print("{\"success\": false, \"error\": \"Aucune modification\"}");
            }
            
        } catch (Exception e) {
            e.printStackTrace();
            out.print("{\"success\": false, \"error\": \"" + e.getMessage() + "\"}");
        }
    }
}