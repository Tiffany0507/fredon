package com.quickchat.servlet;

import java.io.IOException;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import com.quickchat.model.User;
import com.quickchat.dao.GroupMessageDAO;

@WebServlet("/pinGroupMessage")
public class PinGroupMessageServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;
    private GroupMessageDAO groupMessageDAO;
    
    public void init() {
        groupMessageDAO = new GroupMessageDAO();
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
        int groupId = Integer.parseInt(request.getParameter("groupId"));
        
        boolean success = groupMessageDAO.togglePinMessage(messageId, groupId);
        
        if (success) {
            response.setStatus(HttpServletResponse.SC_OK);
        } else {
            response.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
        }
    }
}