package com.quickchat.servlet;

import java.io.IOException;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import com.quickchat.dao.UserDAO;
import com.quickchat.dao.PasswordResetDAO;
import com.quickchat.model.User;
import com.quickchat.utils.EmailUtil;
import com.immobilier.dao.AdminDAO;
import com.immobilier.model.Admin;

@WebServlet("/forgotPassword")
public class ForgotPasswordServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;
    private UserDAO userDAO;
    private PasswordResetDAO resetDAO;
    private AdminDAO adminDAO;
    
    public void init() {
        userDAO = new UserDAO();
        resetDAO = new PasswordResetDAO();
        adminDAO = new AdminDAO();
    }
    
    protected void doGet(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
    	HttpSession session = request.getSession(true);
    	System.out.println("=== ForgotPasswordServlet ===");
    	System.out.println("Session ID: " + session.getId());
        request.getRequestDispatcher("forgot-password.jsp").forward(request, response);
    }
    
    protected void doPost(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        
        String email = request.getParameter("email");
        
        if (email == null || email.trim().isEmpty()) {
            response.sendRedirect("forgot-password.jsp?error=Email requis");
            return;
        }
        
        // 1. Vérifier d'abord si c'est un ADMIN
        Admin admin = adminDAO.getAdminByEmail(email);
        
        if (admin != null) {
            System.out.println("✅ Admin trouvé: " + admin.getEmail());
            
            String code = resetDAO.generateResetCodeForAdmin(admin.getId());
            
            if (code == null) {
                response.sendRedirect("forgot-password.jsp?error=Erreur technique, réessayez plus tard");
                return;
            }
            
            boolean emailSent = EmailUtil.sendResetCode(email, code, admin.getUsername());
            
            if (emailSent) {
                HttpSession session = request.getSession();
                session.setAttribute("resetAdminId", admin.getId());
                session.setAttribute("resetEmail", email);
                session.setAttribute("isAdminReset", true);
                session.setMaxInactiveInterval(15 * 60);
                
                System.out.println("=== ForgotPasswordServlet ADMIN ===");
                System.out.println("Session ID: " + session.getId());
                System.out.println("resetAdminId: " + admin.getId());
                
                response.sendRedirect("verify-code.jsp?success=Un code a été envoyé à votre email");
            } else {
                response.sendRedirect("forgot-password.jsp?error=Erreur d'envoi d'email");
            }
            return;
        }
        
        // 2. Sinon, vérifier si c'est un CLIENT
        User user = userDAO.getUserByEmail(email);
        
        if (user == null) {
            response.sendRedirect("forgot-password.jsp?error=Aucun compte associé à cet email");
            return;
        }
        
        String code = resetDAO.generateResetCode(user.getId());
        
        if (code == null) {
            response.sendRedirect("forgot-password.jsp?error=Erreur technique, réessayez plus tard");
            return;
        }
        
        boolean emailSent = EmailUtil.sendResetCode(email, code, user.getUsername());
        
        if (emailSent) {
            HttpSession session = request.getSession();
            session.setAttribute("resetUserId", user.getId());
            session.setAttribute("resetEmail", email);
            session.setAttribute("isAdminReset", false);
            session.setMaxInactiveInterval(15 * 60);
            
            System.out.println("=== ForgotPasswordServlet CLIENT ===");
            System.out.println("Session ID: " + session.getId());
            System.out.println("resetUserId: " + user.getId());
            
            response.sendRedirect("verify-code.jsp?success=Un code a été envoyé à votre email");
        } else {
            response.sendRedirect("forgot-password.jsp?error=Erreur d'envoi d'email");
        }
    }
}