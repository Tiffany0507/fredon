package com.quickchat.servlet;

import java.io.IOException;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import com.quickchat.dao.UserDAO;
import com.quickchat.model.User;

@WebServlet("/logout")
public class LogoutServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;
    
    protected void doGet(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        
        HttpSession session = request.getSession();
        User user = (User) session.getAttribute("user");
        
        if (user != null) {
            // Mettre à jour le statut en hors ligne
            UserDAO userDAO = new UserDAO();
            userDAO.updateStatus(user.getId(), "offline");
        }
        
        // Détruire la session
        session.invalidate();
        
        // Rediriger vers login (sans .jsp)
        response.sendRedirect(request.getContextPath() + "/login");
    }
}