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

@WebServlet("/deleteMessage")
public class DeleteMessageServlet extends HttpServlet {
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
        
        if ("everyone".equals(type)) {
            Message msg = messageDAO.getMessageById(messageId);
            if (msg != null && msg.getFilePath() != null && !msg.getFilePath().isEmpty()) {
                String filePath = getServletContext().getRealPath("/") + msg.getFilePath();
                java.io.File file = new java.io.File(filePath);
                if (file.exists()) {
                    file.delete();
                }
            }
            messageDAO.deleteForEveryone(messageId);
        } else {
            boolean isSender = (messageDAO.getMessageById(messageId).getSenderId() == user.getId());
            messageDAO.deleteForUser(messageId, user.getId(), isSender);
        }
        
        response.sendRedirect("chat.jsp?userId=" + receiverId);
    }
}