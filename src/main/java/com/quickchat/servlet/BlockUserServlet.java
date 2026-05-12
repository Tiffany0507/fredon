package com.quickchat.servlet;

import java.io.IOException;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import com.quickchat.dao.BlockedUserDAO;
import com.quickchat.model.User;

@WebServlet("/blockUser")
public class BlockUserServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;
    private BlockedUserDAO blockedDAO;
    
    public void init() {
        blockedDAO = new BlockedUserDAO();
    }
    
    protected void doPost(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        
        HttpSession session = request.getSession();
        User user = (User) session.getAttribute("user");
        
        if (user == null) {
            response.sendRedirect("login.jsp");
            return;
        }
        
        int contactId = Integer.parseInt(request.getParameter("contactId"));
        String action = request.getParameter("action");
        
        if ("block".equals(action)) {
            blockedDAO.blockUser(user.getId(), contactId);
        } else if ("unblock".equals(action)) {
            blockedDAO.unblockUser(user.getId(), contactId);
        }
        
        // Rediriger vers la page de chat (ou vers la liste des contacts)
        response.sendRedirect("chat.jsp");
    }
}