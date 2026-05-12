package com.quickchat.servlet;

import com.quickchat.dao.ConversationDAO;
import com.quickchat.model.User;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;

@WebServlet("/archiveConversation")
public class ArchiveConversation extends HttpServlet {
    
    protected void doPost(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        
        User user = (User) request.getSession().getAttribute("user");
        if (user == null) {
            response.sendRedirect("login.jsp");
            return;
        }
        
        int contactId = Integer.parseInt(request.getParameter("contactId"));
        boolean archived = Boolean.parseBoolean(request.getParameter("archived"));
        
        ConversationDAO convDAO = new ConversationDAO();
        convDAO.setArchived(user.getId(), contactId, archived);
        
        // Rediriger vers la page précédente ou l'accueil
        String referer = request.getHeader("Referer");
        if (referer != null && !referer.isEmpty()) {
            response.sendRedirect(referer);
        } else {
            response.sendRedirect("chat.jsp");
        }
    }
}