package com.quickchat.servlet;

import java.io.IOException;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import com.quickchat.dao.GroupMessageDAO;
import com.quickchat.model.GroupMessage;
import com.quickchat.model.User;

@WebServlet("/sendGroupMessage")
public class SendGroupMessageServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;
    private GroupMessageDAO messageDAO;
    
    public void init() {
        messageDAO = new GroupMessageDAO();
    }
    
    protected void doPost(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        
        System.out.println("=== SendGroupMessageServlet appelé ===");
        
        HttpSession session = request.getSession();
        User user = (User) session.getAttribute("user");
        
        if (user == null) {
            System.out.println("Utilisateur non connecté");
            response.sendRedirect("login.jsp");
            return;
        }
        
        System.out.println("Utilisateur ID: " + user.getId());
        
        String groupIdParam = request.getParameter("groupId");
        String content = request.getParameter("content");
        
        // ========== NOUVEAU : Récupérer l'ID du message auquel on répond ==========
        int replyToMessageId = 0;
        String replyParam = request.getParameter("replyToMessageId");
        if (replyParam != null && !replyParam.isEmpty()) {
            replyToMessageId = Integer.parseInt(replyParam);
            System.out.println("replyToMessageId: " + replyToMessageId);
        }
        
        System.out.println("groupId: " + groupIdParam);
        System.out.println("content: " + content);
        
        if (groupIdParam == null || content == null || content.trim().isEmpty()) {
            System.out.println("Paramètres manquants ou message vide");
            response.sendRedirect("group-chat.jsp?groupId=" + (groupIdParam != null ? groupIdParam : ""));
            return;
        }
        
        int groupId = Integer.parseInt(groupIdParam);
        
        GroupMessage message = new GroupMessage();
        message.setGroupId(groupId);
        message.setSenderId(user.getId());
        message.setContent(content.trim());
        message.setReplyToMessageId(replyToMessageId);  // ========== NOUVEAU ==========
        
        boolean success = messageDAO.sendGroupMessage(message);
        System.out.println("Envoi réussi: " + success);
        
        response.sendRedirect("group-chat.jsp?groupId=" + groupId);
    }
}