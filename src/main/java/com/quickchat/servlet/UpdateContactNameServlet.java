package com.quickchat.servlet;

import java.io.IOException;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import com.quickchat.model.User;
import com.quickchat.dao.ContactNameDAO;

@WebServlet("/updateContactName")
public class UpdateContactNameServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;
    private ContactNameDAO contactNameDAO;
    
    public void init() {
        contactNameDAO = new ContactNameDAO();
    }
    
    protected void doPost(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        
        HttpSession session = request.getSession();
        User user = (User) session.getAttribute("user");
        
        if (user == null) {
            response.sendRedirect("login.jsp");
            return;
        }
        
        int contactId = Integer.parseInt(request.getParameter("contactId"));
        String action = request.getParameter("action");
        String newName = request.getParameter("newName");
        
        // ===== AJOUTE CES LIGNES ICI =====
        System.out.println("=== DEBUG ===");
        System.out.println("userId: " + user.getId());
        System.out.println("contactId: " + contactId);
        System.out.println("action: " + action);
        System.out.println("newName: " + newName);
        // ================================
        
        if ("save".equals(action) && newName != null && !newName.trim().isEmpty()) {
            contactNameDAO.updateCustomName(user.getId(), contactId, newName.trim());
        } else if ("remove".equals(action)) {
            contactNameDAO.removeCustomName(user.getId(), contactId);
        }
        
        String referer = request.getHeader("referer");
        if (referer != null && !referer.isEmpty()) {
            response.sendRedirect(referer);
        } else {
            response.sendRedirect("chat.jsp");
        }
    }
}