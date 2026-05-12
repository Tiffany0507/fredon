package com.quickchat.servlet;

import java.io.IOException;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import com.quickchat.dao.UserDAO;
import com.immobilier.dao.AdminDAO;

@WebServlet("/resetPassword")
public class ResetPasswordServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;
    private UserDAO userDAO;
    private AdminDAO adminDAO;
    
    public void init() {
        userDAO = new UserDAO();
        adminDAO = new AdminDAO();
    }
    
    protected void doPost(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        
        HttpSession session = request.getSession(false);
        
        if (session == null) {
            response.sendRedirect("forgot-password.jsp?error=Session expirée");
            return;
        }
        
        Boolean codeVerified = (Boolean) session.getAttribute("codeVerified");
        Integer userId = (Integer) session.getAttribute("resetPasswordForUser");
        Integer adminId = (Integer) session.getAttribute("resetPasswordForAdmin");
        
        String newPassword = request.getParameter("newPassword");
        String confirmPassword = request.getParameter("confirmPassword");
        
        System.out.println("=== ResetPasswordServlet ===");
        System.out.println("codeVerified: " + codeVerified);
        System.out.println("userId: " + userId);
        System.out.println("adminId: " + adminId);
        
        if (codeVerified == null || !codeVerified) {
            response.sendRedirect("verify-code.jsp?error=Veuillez d'abord vérifier votre code");
            return;
        }
        
        if (userId == null && adminId == null) {
            response.sendRedirect("forgot-password.jsp?error=Session expirée");
            return;
        }
        
        if (!newPassword.equals(confirmPassword)) {
            response.sendRedirect("reset-password.jsp?error=Les mots de passe ne correspondent pas");
            return;
        }
        
        if (newPassword.length() < 4) {
            response.sendRedirect("reset-password.jsp?error=Le mot de passe doit contenir au moins 4 caractères");
            return;
        }
        
        boolean updated = false;
        
        // Mettre à jour pour ADMIN
        if (adminId != null) {
            updated = adminDAO.updatePassword(adminId, newPassword);
            System.out.println("Mise à jour mot de passe ADMIN: " + updated);
        }
        
        // Mettre à jour pour CLIENT
        if (userId != null) {
            updated = userDAO.updatePassword(userId, newPassword);
            System.out.println("Mise à jour mot de passe CLIENT: " + updated);
        }
        
        if (updated) {
            session.removeAttribute("resetPasswordForUser");
            session.removeAttribute("resetPasswordForAdmin");
            session.removeAttribute("codeVerified");
            session.removeAttribute("resetEmail");
            
            response.sendRedirect("login.jsp?success=Votre mot de passe a été réinitialisé avec succès !");
        } else {
            response.sendRedirect("reset-password.jsp?error=Erreur lors de la réinitialisation");
        }
    }
}