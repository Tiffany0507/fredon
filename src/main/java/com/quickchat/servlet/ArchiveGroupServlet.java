package com.quickchat.servlet;

import com.quickchat.model.User;
import com.quickchat.dao.ConversationDAO;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import java.io.IOException;

@WebServlet("/archiveGroup")
public class ArchiveGroupServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;
    
    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        
        HttpSession session = request.getSession();
        User user = (User) session.getAttribute("user");
        
        if (user == null) {
            response.sendRedirect("login.jsp");
            return;
        }
        
        try {
            int groupId = Integer.parseInt(request.getParameter("groupId"));
            
            ConversationDAO conversationDAO = new ConversationDAO();
            boolean success = conversationDAO.archiveGroupConversation(user.getId(), groupId);
            
            if (success) {
                response.sendRedirect("chat.jsp?archived=success");
            } else {
                response.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
                response.getWriter().write("Échec de l'archivage");
            }
        } catch (Exception e) {
            e.printStackTrace();
            response.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
            response.getWriter().write("Erreur: " + e.getMessage());
        }
    }
}