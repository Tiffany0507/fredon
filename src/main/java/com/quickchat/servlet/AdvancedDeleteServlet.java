package com.quickchat.servlet;

import java.io.IOException;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import com.quickchat.dao.MessageDAO;
import com.quickchat.model.Message;
import com.quickchat.model.User;

@WebServlet("/advancedDelete")
public class AdvancedDeleteServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;
    private MessageDAO messageDAO;
    
    public void init() {
        messageDAO = new MessageDAO();
    }
    
    protected void doPost(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        
        HttpSession session = request.getSession();
        User user = (User) session.getAttribute("user");
        
        if (user == null) {
            response.sendRedirect("login.jsp");
            return;
        }
        
        int messageId = Integer.parseInt(request.getParameter("messageId"));
        int receiverId = Integer.parseInt(request.getParameter("receiverId"));
        String type = request.getParameter("type");
        
        Message msg = messageDAO.getMessageById(messageId);
        
        if (msg != null) {
            if ("everyone".equals(type) && msg.getSenderId() == user.getId()) {
                // Supprimer pour tout le monde
                messageDAO.deleteForEveryone(messageId);
            } else if ("me".equals(type)) {
                // Supprimer pour moi
                boolean isSender = (msg.getSenderId() == user.getId());
                messageDAO.deleteForUser(messageId, user.getId(), isSender);
            }
        }
        
        response.sendRedirect("chat.jsp?userId=" + receiverId);
    }
}