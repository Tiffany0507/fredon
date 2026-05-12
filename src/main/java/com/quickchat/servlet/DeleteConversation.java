package com.quickchat.servlet;

import com.quickchat.dao.ConversationDAO;
import com.quickchat.model.User;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;

@WebServlet("/deleteConversation")
public class DeleteConversation extends HttpServlet {
    
    protected void doPost(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        
        User user = (User) request.getSession().getAttribute("user");
        if (user == null) {
            response.sendRedirect("login.jsp");
            return;
        }
        
        int contactId = Integer.parseInt(request.getParameter("contactId"));
        
        ConversationDAO convDAO = new ConversationDAO();
        convDAO.deleteConversation(user.getId(), contactId);
        
        response.sendRedirect("chat.jsp");
    }
}