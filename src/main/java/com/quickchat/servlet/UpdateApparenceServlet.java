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

@WebServlet("/immo/admin/update-apparence")
public class UpdateApparenceServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;
    
    protected void doPost(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        
        HttpSession session = request.getSession();
        Integer adminId = (Integer) session.getAttribute("adminId");
        
        if (adminId == null) {
            response.sendRedirect(request.getContextPath() + "/immo/admin/login.jsp");
            return;
        }
        
        String theme = request.getParameter("theme");
        String primaryColor = request.getParameter("primaryColor");
        String font = request.getParameter("font");
        
        try {
            Class.forName("com.mysql.cj.jdbc.Driver");
            Connection conn = DriverManager.getConnection(
                "jdbc:mysql://localhost:3306/quickchat", "root", "");
            
            // S'assurer que la table settings existe avec les colonnes nécessaires
            String alterTable = "ALTER TABLE settings ADD COLUMN IF NOT EXISTS default_theme VARCHAR(20) DEFAULT 'light', " +
                                "ADD COLUMN IF NOT EXISTS primary_color VARCHAR(20) DEFAULT 'gold', " +
                                "ADD COLUMN IF NOT EXISTS default_font VARCHAR(50) DEFAULT 'dm-sans'";
            try {
                conn.createStatement().execute(alterTable);
            } catch(Exception e) {
                // Colonnes可能存在 déjà
            }
            
            String sql = "UPDATE settings SET default_theme = ?, primary_color = ?, default_font = ? WHERE id = 1";
            PreparedStatement pstmt = conn.prepareStatement(sql);
            pstmt.setString(1, theme);
            pstmt.setString(2, primaryColor);
            pstmt.setString(3, font);
            pstmt.executeUpdate();
            pstmt.close();
            conn.close();
            
            // Stocker en session pour utilisation immédiate
            session.setAttribute("userTheme", theme);
            session.setAttribute("themeColor", primaryColor);
            
            response.sendRedirect(request.getContextPath() + "/immo/admin/setting.jsp?success=Apparence mise à jour");
            
        } catch (Exception e) {
            e.printStackTrace();
            response.sendRedirect(request.getContextPath() + "/immo/admin/setting.jsp?error=Erreur lors de la mise à jour");
        }
    }
}