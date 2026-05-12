package com.quickchat.servlet;

import java.io.IOException;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import com.quickchat.dao.UserDAO;
import com.quickchat.model.User;

@WebServlet("/updateDisplayName")
public class UpdateDisplayNameServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;
    private UserDAO userDAO;
    
    public void init() {
        userDAO = new UserDAO();
    }
    
    protected void doPost(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        
        HttpSession session = request.getSession();
        User user = (User) session.getAttribute("user");
        
        if (user == null) {
            response.sendRedirect("login.jsp");
            return;
        }
        
        String displayName = request.getParameter("displayName");
        
        if (displayName != null && !displayName.trim().isEmpty()) {
            boolean updated = userDAO.updateDisplayName(user.getId(), displayName.trim());
            
            if (updated) {
                user.setDisplayName(displayName.trim());
                session.setAttribute("user", user);
            }
        }
        
        response.sendRedirect("chat.jsp");
    }
}