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

@WebServlet("/immo/admin/update-localisation")
public class UpdateLocalisationServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;
    
    protected void doPost(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        
        HttpSession session = request.getSession();
        Integer adminId = (Integer) session.getAttribute("adminId");
        
        if (adminId == null) {
            response.sendRedirect(request.getContextPath() + "/immo/admin/login.jsp");
            return;
        }
        
        String language = request.getParameter("language");
        String timezone = request.getParameter("timezone");
        String dateFormat = request.getParameter("dateFormat");
        String currency = request.getParameter("currency");
        
        try {
            Class.forName("com.mysql.cj.jdbc.Driver");
            Connection conn = DriverManager.getConnection(
                "jdbc:mysql://localhost:3306/quickchat", "root", "");
            
            // Ajouter les colonnes si nécessaire
            String alterTable = "ALTER TABLE settings ADD COLUMN IF NOT EXISTS default_language VARCHAR(10) DEFAULT 'fr', " +
                                "ADD COLUMN IF NOT EXISTS timezone VARCHAR(50) DEFAULT 'Indian/Antananarivo', " +
                                "ADD COLUMN IF NOT EXISTS date_format VARCHAR(20) DEFAULT 'DD/MM/YYYY', " +
                                "ADD COLUMN IF NOT EXISTS currency VARCHAR(10) DEFAULT 'Ar'";
            try {
                conn.createStatement().execute(alterTable);
            } catch(Exception e) {
                // Colonnes可能存在 déjà
            }
            
            String sql = "UPDATE settings SET default_language = ?, timezone = ?, date_format = ?, currency = ? WHERE id = 1";
            PreparedStatement pstmt = conn.prepareStatement(sql);
            pstmt.setString(1, language);
            pstmt.setString(2, timezone);
            pstmt.setString(3, dateFormat);
            pstmt.setString(4, currency);
            pstmt.executeUpdate();
            pstmt.close();
            conn.close();
            
            // Stocker en session
            session.setAttribute("userLanguage", language);
            session.setAttribute("userTimezone", timezone);
            session.setAttribute("dateFormat", dateFormat);
            session.setAttribute("currency", currency);
            
            response.sendRedirect(request.getContextPath() + "/immo/admin/setting.jsp?success=Paramètres de localisation mis à jour");
            
        } catch (Exception e) {
            e.printStackTrace();
            response.sendRedirect(request.getContextPath() + "/immo/admin/setting.jsp?error=Erreur lors de la mise à jour");
        }
    }
}