package com.quickchat.servlet;

import com.quickchat.model.User;
import com.quickchat.dao.GroupMessageDAO;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import java.io.IOException;

@WebServlet("/deleteGroupConversation")
public class DeleteGroupConversationServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;
    
    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        
        System.out.println("=== DeleteGroupConversationServlet appelé ===");
        
        HttpSession session = request.getSession();
        User user = (User) session.getAttribute("user");
        
        if (user == null) {
            System.out.println("Utilisateur non connecté");
            response.sendRedirect("login.jsp");
            return;
        }
        
        System.out.println("Utilisateur ID: " + user.getId());
        
        try {
            String groupIdParam = request.getParameter("groupId");
            System.out.println("groupId param: " + groupIdParam);
            
            if (groupIdParam == null || groupIdParam.isEmpty()) {
                System.out.println("groupId manquant");
                response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
                response.getWriter().write("groupId manquant");
                return;
            }
            
            int groupId = Integer.parseInt(groupIdParam);
            System.out.println("Suppression pour groupe: " + groupId + ", user: " + user.getId());
            
            GroupMessageDAO messageDAO = new GroupMessageDAO();
            boolean success = messageDAO.deleteAllMessagesForUser(groupId, user.getId());
            
            System.out.println("Résultat: " + success);
            
            if (success) {
                response.sendRedirect("chat.jsp?deleted=success");
            } else {
                response.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
                response.getWriter().write("Échec de la suppression");
            }
        } catch (Exception e) {
            System.out.println("Erreur: " + e.getMessage());
            e.printStackTrace();
            response.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
            response.getWriter().write("Erreur: " + e.getMessage());
        }
    }
}