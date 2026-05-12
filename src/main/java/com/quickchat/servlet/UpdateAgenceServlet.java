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

@WebServlet("/immo/admin/update-agence")
public class UpdateAgenceServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;
    
    protected void doPost(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        
        HttpSession session = request.getSession();
        Integer adminId = (Integer) session.getAttribute("adminId");
        
        if (adminId == null) {
            response.sendRedirect(request.getContextPath() + "/immo/admin/login.jsp");
            return;
        }
        
        String siteName = request.getParameter("siteName");
        String siteSlogan = request.getParameter("siteSlogan");
        String siteEmail = request.getParameter("siteEmail");
        String sitePhone = request.getParameter("sitePhone");
        String siteAddress = request.getParameter("siteAddress");
        String siteHours = request.getParameter("siteHours");
        
        try {
            Class.forName("com.mysql.cj.jdbc.Driver");
            Connection conn = DriverManager.getConnection(
                "jdbc:mysql://localhost:3306/quickchat", "root", "");
            
            // Vérifier si la table settings existe, sinon la créer
            String createTable = "CREATE TABLE IF NOT EXISTS settings (" +
                "id INT PRIMARY KEY AUTO_INCREMENT, " +
                "site_name VARCHAR(255) DEFAULT 'Fredon Immobilier', " +
                "site_slogan TEXT, site_email VARCHAR(255), site_phone VARCHAR(50), " +
                "site_address TEXT, site_hours VARCHAR(255), updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP)";
            conn.createStatement().execute(createTable);
            
            // Vérifier si une ligne existe déjà
            java.sql.Statement stmt = conn.createStatement();
            java.sql.ResultSet rs = stmt.executeQuery("SELECT COUNT(*) FROM settings");
            rs.next();
            int count = rs.getInt(1);
            rs.close();
            
            String sql;
            PreparedStatement pstmt;
            
            if (count == 0) {
                sql = "INSERT INTO settings (site_name, site_slogan, site_email, site_phone, site_address, site_hours) VALUES (?, ?, ?, ?, ?, ?)";
                pstmt = conn.prepareStatement(sql);
            } else {
                sql = "UPDATE settings SET site_name = ?, site_slogan = ?, site_email = ?, site_phone = ?, site_address = ?, site_hours = ? WHERE id = 1";
                pstmt = conn.prepareStatement(sql);
            }
            
            pstmt.setString(1, siteName);
            pstmt.setString(2, siteSlogan);
            pstmt.setString(3, siteEmail);
            pstmt.setString(4, sitePhone);
            pstmt.setString(5, siteAddress);
            pstmt.setString(6, siteHours);
            pstmt.executeUpdate();
            pstmt.close();
            conn.close();
            
            response.sendRedirect(request.getContextPath() + "/immo/admin/setting.jsp?success=Informations de l'agence mises à jour");
            
        } catch (Exception e) {
            e.printStackTrace();
            response.sendRedirect(request.getContextPath() + "/immo/admin/setting.jsp?error=Erreur lors de la mise à jour");
        }
    }
}