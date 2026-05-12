package com.quickchat.servlet;

import java.io.IOException;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import com.quickchat.dao.ReactionDAO;
import com.quickchat.model.User;

@WebServlet("/reaction")
public class ReactionServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;
    private ReactionDAO reactionDAO;
    
    public void init() {
        reactionDAO = new ReactionDAO();
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
        String reaction = request.getParameter("reaction");
        String action = request.getParameter("action");
        
        if ("remove".equals(action)) {
            reactionDAO.removeReaction(messageId, user.getId());
        } else {
            reactionDAO.addReaction(messageId, user.getId(), reaction);
        }
        
        // Rediriger vers la même conversation
        response.sendRedirect("chat.jsp?userId=" + receiverId);
    }
}