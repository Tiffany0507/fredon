package com.quickchat.servlet;

import java.io.*;
import java.sql.*;
import java.util.*;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;
import com.google.gson.JsonArray;
import com.google.gson.JsonObject;

@WebServlet("/api/get-available-time-slots")
public class GetAvailableTimeSlotsServlet extends HttpServlet {
    
    private static final String DB_URL = "jdbc:mysql://localhost:3306/quickchat";
    private static final String DB_USER = "root";
    private static final String DB_PASSWORD = "";
    
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        
        String propertyId = request.getParameter("propertyId");
        String date = request.getParameter("date");
        
        JsonObject result = new JsonObject();
        JsonArray bookedSlots = new JsonArray();
        
        if (propertyId == null || date == null) {
            result.addProperty("error", "Paramètres manquants");
            response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
            response.getWriter().write(result.toString());
            return;
        }
        
        try (Connection conn = DriverManager.getConnection(DB_URL, DB_USER, DB_PASSWORD)) {
            // Récupérer les créneaux déjà réservés pour cette propriété et cette date
            String sql = "SELECT appointment_time FROM appointments " +
                        "WHERE property_id = ? AND appointment_date = ? " +
                        "AND status != 'cancelled'";
            
            try (PreparedStatement pstmt = conn.prepareStatement(sql)) {
                pstmt.setInt(1, Integer.parseInt(propertyId));
                pstmt.setDate(2, java.sql.Date.valueOf(date));
                
                try (ResultSet rs = pstmt.executeQuery()) {
                    while (rs.next()) {
                        Time t = rs.getTime("appointment_time");
                        if (t != null) {
                            bookedSlots.add(t.toString().substring(0, 5)); // Format HH:mm
                        }
                    }
                }
            }
            
            result.add("bookedSlots", bookedSlots);
            result.addProperty("success", true);
            
        } catch (Exception e) {
            e.printStackTrace();
            result.addProperty("error", "Erreur serveur : " + e.getMessage());
            response.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
        }
        
        response.getWriter().write(result.toString());
    }
}