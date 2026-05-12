package com.quickchat.servlet;

import java.io.IOException;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import com.quickchat.dao.GroupDAO;
import com.quickchat.dao.GroupMemberDAO;
import com.quickchat.model.Group;
import com.quickchat.model.User;

@WebServlet("/createGroup")
public class GroupServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;
    private GroupDAO groupDAO;
    private GroupMemberDAO memberDAO;
    
    public void init() {
        groupDAO = new GroupDAO();
        memberDAO = new GroupMemberDAO();
    }
    
    protected void doPost(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        
        HttpSession session = request.getSession();
        User user = (User) session.getAttribute("user");
        
        if (user == null) {
            response.sendRedirect("login.jsp");
            return;
        }
        
        String groupName = request.getParameter("groupName");
        String description = request.getParameter("description");
        
        Group group = new Group();
        group.setName(groupName);
        group.setDescription(description);
        group.setCreatedBy(user.getId());
        group.setTheme("default");
        
        boolean success = groupDAO.createGroup(group);
        
        if (success && group.getId() > 0) {
            // Ajouter le créateur avec le rôle admin
            memberDAO.addMember(group.getId(), user.getId(), "admin");
            response.sendRedirect("group-chat.jsp?groupId=" + group.getId());
        } else {
            response.sendRedirect("create-group.jsp?error=Erreur lors de la création");
        }
    }
}