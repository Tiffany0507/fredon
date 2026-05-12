package com.quickchat.servlet;

import com.quickchat.dao.GroupDAO;
import com.quickchat.dao.GroupMemberDAO;
import com.quickchat.model.Group;
import com.quickchat.model.User;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import java.io.IOException;

@WebServlet("/removeGroupMember")
public class RemoveGroupMemberServlet extends HttpServlet {
    
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
        
        int groupId = Integer.parseInt(request.getParameter("groupId"));
        int userIdToRemove = Integer.parseInt(request.getParameter("userId"));
        
        GroupDAO groupDAO = new GroupDAO();
        Group group = groupDAO.getGroupById(groupId);
        
        // Seul le créateur du groupe peut exclure des membres
        if (group != null && group.getCreatedBy() == user.getId()) {
            GroupMemberDAO memberDAO = new GroupMemberDAO();
            memberDAO.removeMember(groupId, userIdToRemove);
        }
        
        response.sendRedirect("group-chat.jsp?groupId=" + groupId);
    }
}