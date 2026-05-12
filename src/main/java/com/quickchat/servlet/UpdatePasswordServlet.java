package com.quickchat.servlet;

import java.io.IOException;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import com.quickchat.utils.PasswordUtil;

@WebServlet("/immo/admin/update-password")
public class UpdatePasswordServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;

    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        HttpSession session = request.getSession();
        Integer adminId = (Integer) session.getAttribute("adminId");
        System.out.println("=== DÉBOGAGE ===");
        System.out.println("adminId = " + adminId);
        
        if (adminId == null) {
            response.sendRedirect(request.getContextPath() + "/login.jsp");
            return;
        }
        
        String currentPassword = request.getParameter("currentPassword");
        String newPassword = request.getParameter("newPassword");
        String confirmPassword = request.getParameter("confirmPassword");
        
        // Vérifier que les mots de passe correspondent
        if (newPassword == null || !newPassword.equals(confirmPassword)) {
            response.sendRedirect(request.getContextPath() + "/immo/admin/setting.jsp?error=Les%20nouveaux%20mots%20de%20passe%20ne%20correspondent%20pas");
            return;
        }
        
        // Vérifier que le nouveau mot de passe a au moins 4 caractères
        if (newPassword.length() < 4) {
            response.sendRedirect(request.getContextPath() + "/immo/admin/setting.jsp?error=Le%20mot%20de%20passe%20doit%20contenir%20au%20moins%204%20caract%C3%A8res");
            return;
        }
        
        String DB_URL = "jdbc:mysql://localhost:3306/quickchat";
        String DB_USER = "root";
        String DB_PASSWORD = "";
        
        try {
            Class.forName("com.mysql.cj.jdbc.Driver");
            Connection conn = DriverManager.getConnection(DB_URL, DB_USER, DB_PASSWORD);
            
            // Vérifier l'ancien mot de passe
            PreparedStatement pstmt = conn.prepareStatement("SELECT password FROM users WHERE id = ?");
            pstmt.setInt(1, adminId);
            ResultSet rs = pstmt.executeQuery();
            
            if (rs.next()) {
                String storedHash = rs.getString("password");
                
                if (PasswordUtil.checkPassword(currentPassword, storedHash)) {
                    // Hasher le nouveau mot de passe
                    String newHashedPassword = PasswordUtil.hashPassword(newPassword);
                    
                    // Mettre à jour le mot de passe
                    PreparedStatement updateStmt = conn.prepareStatement("UPDATE users SET password = ? WHERE id = ?");
                    updateStmt.setString(1, newHashedPassword);
                    updateStmt.setInt(2, adminId);
                    updateStmt.executeUpdate();
                    updateStmt.close();
                    
                    response.sendRedirect(request.getContextPath() + "/immo/admin/setting.jsp?success=Votre%20mot%20de%20passe%20a%20%C3%A9t%C3%A9%20modifi%C3%A9%20avec%20succ%C3%A8s");
                } else {
                    response.sendRedirect(request.getContextPath() + "/immo/admin/setting.jsp?error=Mot%20de%20passe%20actuel%20incorrect");
                }
            } else {
                response.sendRedirect(request.getContextPath() + "/immo/admin/setting.jsp?error=Utilisateur%20non%20trouv%C3%A9");
            }
            
            rs.close();
            pstmt.close();
            conn.close();
            
        } catch (Exception e) {
            e.printStackTrace();
            response.sendRedirect(request.getContextPath() + "/immo/admin/setting.jsp?error=Erreur%20technique%3A%20" + e.getMessage());
        }
    }
}