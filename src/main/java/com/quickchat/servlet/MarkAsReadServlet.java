package com.quickchat.servlet;

import java.io.IOException;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import com.quickchat.dao.MessageDAO;
import com.quickchat.model.User;

@WebServlet("/markAsRead")
public class MarkAsReadServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;
    private MessageDAO messageDAO;
    
    public void init() {
        messageDAO = new MessageDAO();
    }
    
    protected void doGet(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        
        HttpSession session = request.getSession();
        User user = (User) session.getAttribute("user");
        
        if (user == null) {
            response.sendRedirect("login.jsp");
            return;
        }
        
        int senderId = Integer.parseInt(request.getParameter("senderId"));
        
        // Marquer tous les messages de cet expéditeur comme lus
        messageDAO.markAllMessagesAsRead(user.getId(), senderId);
        
        response.sendRedirect("chat.jsp?userId=" + senderId);
    }
}