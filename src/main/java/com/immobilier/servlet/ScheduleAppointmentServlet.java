package com.immobilier.servlet;

import java.io.IOException;
import java.sql.*;
import java.text.SimpleDateFormat;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

import com.quickchat.model.User;

@WebServlet("/schedule-appointment")
public class ScheduleAppointmentServlet extends HttpServlet {
    
    private static final String DB_URL = "jdbc:mysql://localhost:3306/quickchat";
    private static final String DB_USER = "root";
    private static final String DB_PASSWORD = "";
    
    protected void doPost(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        
        HttpSession session = request.getSession();
        User currentUser = (User) session.getAttribute("user");
        
        String propertyId = request.getParameter("property_id");
        String fullName = request.getParameter("full_name");
        String email = request.getParameter("email");
        String phone = request.getParameter("phone");
        String appointmentDate = request.getParameter("appointment_date");
        String appointmentTime = request.getParameter("appointment_time");
        String message = request.getParameter("message");
        
        // Validation
        if (propertyId == null || fullName == null || email == null || 
            appointmentDate == null || appointmentTime == null) {
            response.sendRedirect(request.getContextPath() + "/immo/appointment.jsp?property_id=" + propertyId + "&error=Veuillez remplir tous les champs obligatoires");
            return;
        }
        
        try {
            Class.forName("com.mysql.cj.jdbc.Driver");
            Connection conn = DriverManager.getConnection(DB_URL, DB_USER, DB_PASSWORD);
            
            int clientId = (currentUser != null) ? currentUser.getId() : 0;
            
            String sql = "INSERT INTO appointments (property_id, client_id, client_name, client_email, client_phone, appointment_date, appointment_time, message, status) VALUES (?, ?, ?, ?, ?, ?, ?, ?, 'pending')";
            
            PreparedStatement pstmt = conn.prepareStatement(sql);
            pstmt.setInt(1, Integer.parseInt(propertyId));
            pstmt.setInt(2, clientId);
            pstmt.setString(3, fullName);
            pstmt.setString(4, email);
            pstmt.setString(5, phone);
            pstmt.setDate(6, Date.valueOf(appointmentDate));
            pstmt.setTime(7, Time.valueOf(appointmentTime + ":00"));
            pstmt.setString(8, message);
            
            int result = pstmt.executeUpdate();
            
            pstmt.close();
            conn.close();
            
            if (result > 0) {
                // Envoyer une notification à l'admin
                sendNotificationToAdmin(propertyId, fullName, appointmentDate, appointmentTime);
                
                response.sendRedirect(request.getContextPath() + "/immo/appointment.jsp?property_id=" + propertyId + "&success=Votre demande de visite a été envoyée avec succès. Un agent vous contactera prochainement.");
            } else {
                response.sendRedirect(request.getContextPath() + "/immo/appointment.jsp?property_id=" + propertyId + "&error=Erreur lors de l'envoi de la demande");
            }
            
        } catch (Exception e) {
            e.printStackTrace();
            response.sendRedirect(request.getContextPath() + "/immo/appointment.jsp?property_id=" + propertyId + "&error=" + e.getMessage());
        }
    }
    
    private void sendNotificationToAdmin(String propertyId, String clientName, String date, String time) {
        try {
            Connection conn = DriverManager.getConnection(DB_URL, DB_USER, DB_PASSWORD);
            
            // Récupérer le titre du bien
            String propertyTitle = "";
            PreparedStatement pstmtProp = conn.prepareStatement("SELECT title FROM properties WHERE id = ?");
            pstmtProp.setInt(1, Integer.parseInt(propertyId));
            ResultSet rsProp = pstmtProp.executeQuery();
            if (rsProp.next()) {
                propertyTitle = rsProp.getString("title");
            }
            rsProp.close();
            pstmtProp.close();
            
            // Créer une notification pour l'admin (user_id = 999)
            String sql = "INSERT INTO notifications (user_id, type, title, message, link) VALUES (999, 'appointment', ?, ?, ?)";
            PreparedStatement pstmt = conn.prepareStatement(sql);
            pstmt.setString(1, "📅 Nouvelle demande de visite");
            pstmt.setString(2, clientName + " a demandé une visite pour le bien \"" + propertyTitle + "\" le " + date + " à " + time);
            pstmt.setString(3, "/immo/admin/appointments.jsp");
            pstmt.executeUpdate();
            pstmt.close();
            
            conn.close();
        } catch(Exception e) {
            e.printStackTrace();
        }
    }
}