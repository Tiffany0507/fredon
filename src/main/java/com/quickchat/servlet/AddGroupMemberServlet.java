package com.quickchat.servlet;

import java.io.IOException;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import com.quickchat.dao.GroupMemberDAO;
import com.quickchat.model.User;

@WebServlet("/addGroupMember")
public class AddGroupMemberServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;
    private GroupMemberDAO memberDAO;
    
    public void init() {
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
        
        int groupId = Integer.parseInt(request.getParameter("groupId"));
        int newMemberId = Integer.parseInt(request.getParameter("userId"));
        int addedBy = user.getId(); // ← L'utilisateur qui ajoute
        
        boolean success = memberDAO.addMember(groupId, newMemberId, addedBy, "member");
        
        if (success) {
            response.sendRedirect("group-chat.jsp?groupId=" + groupId + "&success=member_added");
        } else {
            response.sendRedirect("group-chat.jsp?groupId=" + groupId + "&error=already_member");
        }
    }
}