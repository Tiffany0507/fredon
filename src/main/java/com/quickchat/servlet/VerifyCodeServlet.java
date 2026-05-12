package com.quickchat.servlet;

import java.io.IOException;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import com.quickchat.dao.PasswordResetDAO;

@WebServlet("/verifyCode")
public class VerifyCodeServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;
    private PasswordResetDAO resetDAO;
    
    public void init() {
        resetDAO = new PasswordResetDAO();
    }
    
    protected void doPost(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        
        System.out.println("=== VerifyCodeServlet ===");
        
        HttpSession session = request.getSession(false);
        
        if (session == null) {
            System.out.println("❌ Session null");
            response.sendRedirect("forgot-password.jsp?error=Session expirée, recommencez");
            return;
        }
        
        System.out.println("Session ID: " + session.getId());
        
        Integer resetUserId = (Integer) session.getAttribute("resetUserId");
        Integer resetAdminId = (Integer) session.getAttribute("resetAdminId");
        Boolean isAdminReset = (Boolean) session.getAttribute("isAdminReset");
        String code = request.getParameter("code");
        
        System.out.println("resetUserId: " + resetUserId);
        System.out.println("resetAdminId: " + resetAdminId);
        System.out.println("isAdminReset: " + isAdminReset);
        System.out.println("code reçu: " + code);
        
        if (code == null || code.trim().isEmpty()) {
            response.sendRedirect("verify-code.jsp?error=Code requis");
            return;
        }
        
        boolean isValid = false;
        
        // Vérifier pour ADMIN
        if (isAdminReset != null && isAdminReset && resetAdminId != null) {
            isValid = resetDAO.verifyCode(resetAdminId, code);
            System.out.println("Vérification code ADMIN: " + isValid);
            
            if (isValid) {
                session.setAttribute("codeVerified", true);
                session.setAttribute("resetPasswordForAdmin", resetAdminId);
                session.removeAttribute("resetAdminId");
                response.sendRedirect("reset-password.jsp?success=Code vérifié, choisissez un nouveau mot de passe");
                return;
            }
        }
        
        // Vérifier pour CLIENT
        if (resetUserId != null) {
            isValid = resetDAO.verifyCode(resetUserId, code);
            System.out.println("Vérification code CLIENT: " + isValid);
            
            if (isValid) {
                session.setAttribute("codeVerified", true);
                session.setAttribute("resetPasswordForUser", resetUserId);
                session.removeAttribute("resetUserId");
                response.sendRedirect("reset-password.jsp?success=Code vérifié, choisissez un nouveau mot de passe");
                return;
            }
        }
        
        response.sendRedirect("verify-code.jsp?error=Code invalide ou expiré");
    }
}