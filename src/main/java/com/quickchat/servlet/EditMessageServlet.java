package com.quickchat.servlet;

import java.io.IOException;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;import com.quickchat.dao.MessageDAO;
import com.quickchat.model.User;

@WebServlet("/editMessage")
public class EditMessageServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;
    private MessageDAO messageDAO;
    
    public void init() {
        messageDAO = new MessageDAO();
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
        String newContent = request.getParameter("content");
        int receiverId = Integer.parseInt(request.getParameter("receiverId"));
        
        if (messageDAO.updateMessage(messageId, newContent)) {
            response.sendRedirect("chat.jsp?userId=" + receiverId);
        } else {
            response.sendRedirect("chat.jsp?error=Modification échouée");
        }
    }
}