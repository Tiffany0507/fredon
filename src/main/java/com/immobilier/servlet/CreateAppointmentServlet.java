package com.immobilier.servlet;

import java.io.IOException;
import java.sql.*;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

@WebServlet("/api/create-appointment")
public class CreateAppointmentServlet extends HttpServlet {
    
    private static final String DB_URL = "jdbc:mysql://localhost:3306/quickchat";
    private static final String DB_USER = "root";
    private static final String DB_PASSWORD = "";
    
    protected void doPost(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        
        response.setCharacterEncoding("UTF-8");
        
        // 1. RÉCUPÉRER LES PARAMÈTRES D'ABORD
        String propertyId = request.getParameter("propertyId");
        String clientName = request.getParameter("clientName");
        String clientEmail = request.getParameter("clientEmail");
        String clientPhone = request.getParameter("clientPhone");
        String appointmentDate = request.getParameter("appointmentDate");
        String appointmentTime = request.getParameter("appointmentTime");
        String message = request.getParameter("message");
        
        // 2. VALIDATION
        if (propertyId == null || propertyId.trim().isEmpty() ||
            clientName == null || clientName.trim().isEmpty() ||
            clientEmail == null || clientEmail.trim().isEmpty()) {
            
            // Redirection avec erreur
            response.sendRedirect(request.getContextPath() + "/immo/schedule-appointment.jsp?property_id=" + propertyId + "&error=1");
            return;
        }
        
        Connection conn = null;
        PreparedStatement pstmt = null;
        
        try {
            Class.forName("com.mysql.cj.jdbc.Driver");
            conn = DriverManager.getConnection(DB_URL, DB_USER, DB_PASSWORD);
            
            // Requête d'insertion
            String sql = "INSERT INTO appointments (property_id, client_name, client_email, client_phone, appointment_date, appointment_time, message, status, created_at) VALUES (?, ?, ?, ?, ?, ?, ?, 'pending', NOW())";
            
            pstmt = conn.prepareStatement(sql);
            pstmt.setInt(1, Integer.parseInt(propertyId));
            pstmt.setString(2, clientName);
            pstmt.setString(3, clientEmail);
            pstmt.setString(4, clientPhone != null ? clientPhone : "");
            
            // Gestion des dates (peuvent être null si le formulaire ne les envoie pas)
            if (appointmentDate != null && !appointmentDate.trim().isEmpty()) {
                pstmt.setDate(5, Date.valueOf(appointmentDate));
            } else {
                pstmt.setNull(5, Types.DATE);
            }
            
            if (appointmentTime != null && !appointmentTime.trim().isEmpty()) {
                pstmt.setTime(6, Time.valueOf(appointmentTime + ":00"));
            } else {
                pstmt.setNull(6, Types.TIME);
            }
            
            pstmt.setString(7, message != null ? message : "");
            
            int result = pstmt.executeUpdate();
            
            if (result > 0) {
                // ✅ SUCCÈS : Redirection avec message de succès
                response.sendRedirect(request.getContextPath() + "/immo/schedule-appointment.jsp?property_id=" + propertyId + "&success=1");
            } else {
                // ❌ ÉCHEC : Redirection avec erreur
                response.sendRedirect(request.getContextPath() + "/immo/schedule-appointment.jsp?property_id=" + propertyId + "&error=1");
            }
            
        } catch (NumberFormatException e) {
            response.sendRedirect(request.getContextPath() + "/immo/schedule-appointment.jsp?property_id=" + propertyId + "&error=1");
        } catch (IllegalArgumentException e) {
            response.sendRedirect(request.getContextPath() + "/immo/schedule-appointment.jsp?property_id=" + propertyId + "&error=1");
        } catch (SQLException e) {
            e.printStackTrace();
            response.sendRedirect(request.getContextPath() + "/immo/schedule-appointment.jsp?property_id=" + propertyId + "&error=1");
        } catch (Exception e) {
            e.printStackTrace();
            response.sendRedirect(request.getContextPath() + "/immo/schedule-appointment.jsp?property_id=" + propertyId + "&error=1");
        } finally {
            try { if (pstmt != null) pstmt.close(); } catch (Exception e) {}
            try { if (conn != null) conn.close(); } catch (Exception e) {}
        }
    }
}