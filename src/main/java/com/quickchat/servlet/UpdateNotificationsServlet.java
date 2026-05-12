package com.quickchat.servlet;

import java.io.IOException;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

@WebServlet("/immo/admin/update-notifications")
public class UpdateNotificationsServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;
    
    protected void doPost(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        
        HttpSession session = request.getSession();
        Integer adminId = (Integer) session.getAttribute("adminId");
        
        if (adminId == null) {
            response.sendRedirect(request.getContextPath() + "/immo/admin/login.jsp");
            return;
        }
        
        // Les valeurs des toggles sont récupérées (si non présentes, c'est false)
        boolean emailNotif = request.getParameter("emailNotif") != null;
        boolean messageNotif = request.getParameter("messageNotif") != null;
        boolean clientNotif = request.getParameter("clientNotif") != null;
        boolean commentNotif = request.getParameter("commentNotif") != null;
        boolean propertyNotif = request.getParameter("propertyNotif") != null;
        boolean soundNotif = request.getParameter("soundNotif") != null;
        
        try {
            Class.forName("com.mysql.cj.jdbc.Driver");
            Connection conn = DriverManager.getConnection(
                "jdbc:mysql://localhost:3306/quickchat", "root", "");
            
            // Ajouter les colonnes si nécessaire
            String alterTable = "ALTER TABLE settings ADD COLUMN IF NOT EXISTS email_notifications BOOLEAN DEFAULT TRUE, " +
                                "ADD COLUMN IF NOT EXISTS message_notifications BOOLEAN DEFAULT TRUE, " +
                                "ADD COLUMN IF NOT EXISTS client_notifications BOOLEAN DEFAULT TRUE, " +
                                "ADD COLUMN IF NOT EXISTS comment_notifications BOOLEAN DEFAULT TRUE, " +
                                "ADD COLUMN IF NOT EXISTS property_notifications BOOLEAN DEFAULT TRUE, " +
                                "ADD COLUMN IF NOT EXISTS sound_notifications BOOLEAN DEFAULT FALSE";
            try {
                conn.createStatement().execute(alterTable);
            } catch(Exception e) {
                // Colonnes可能存在 déjà
            }
            
            String sql = "UPDATE settings SET email_notifications = ?, message_notifications = ?, " +
                        "client_notifications = ?, comment_notifications = ?, property_notifications = ?, " +
                        "sound_notifications = ? WHERE id = 1";
            PreparedStatement pstmt = conn.prepareStatement(sql);
            pstmt.setBoolean(1, emailNotif);
            pstmt.setBoolean(2, messageNotif);
            pstmt.setBoolean(3, clientNotif);
            pstmt.setBoolean(4, commentNotif);
            pstmt.setBoolean(5, propertyNotif);
            pstmt.setBoolean(6, soundNotif);
            pstmt.executeUpdate();
            pstmt.close();
            conn.close();
            
            response.sendRedirect(request.getContextPath() + "/immo/admin/setting.jsp?success=Préférences de notifications mises à jour");
            
        } catch (Exception e) {
            e.printStackTrace();
            response.sendRedirect(request.getContextPath() + "/immo/admin/setting.jsp?error=Erreur lors de la mise à jour");
        }
    }
}