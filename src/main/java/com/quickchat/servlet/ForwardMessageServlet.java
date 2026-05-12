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

@WebServlet("/forwardMessage")
public class ForwardMessageServlet extends HttpServlet {
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
        
        int originalMessageId = Integer.parseInt(request.getParameter("messageId"));
        int receiverId = Integer.parseInt(request.getParameter("receiverId"));
        
        // Récupérer le message original
        Message originalMessage = messageDAO.getMessageById(originalMessageId);
        
        if (originalMessage != null) {
            // Créer un nouveau message avec la mention "Transféré"
            String forwardedContent = "📤 Message transféré : " + originalMessage.getContent();
            
            Message newMessage = new Message();
            newMessage.setSenderId(user.getId());
            newMessage.setReceiverId(receiverId);
            newMessage.setContent(forwardedContent);
            
            messageDAO.sendMessage(newMessage);
        }
        
        // Rediriger vers la conversation avec le destinataire
        response.sendRedirect("chat.jsp?userId=" + receiverId);
    }
}