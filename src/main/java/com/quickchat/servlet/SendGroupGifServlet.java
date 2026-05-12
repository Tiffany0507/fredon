package com.quickchat.servlet;

import java.io.IOException;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import com.quickchat.dao.GroupMessageDAO;
import com.quickchat.model.GroupMessage;
import com.quickchat.model.User;

@WebServlet("/sendGroupGif")
public class SendGroupGifServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;
    private GroupMessageDAO messageDAO;
    
    public void init() {
        messageDAO = new GroupMessageDAO();
    }
    
    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        
        HttpSession session = request.getSession();
        User user = (User) session.getAttribute("user");
        
        if (user == null) {
            response.sendRedirect("login.jsp");
            return;
        }
        
        try {
            int groupId = Integer.parseInt(request.getParameter("groupId"));
            String gifUrl = request.getParameter("gifUrl");
            
            GroupMessage message = new GroupMessage();
            message.setGroupId(groupId);
            message.setSenderId(user.getId());
            message.setContent("[GIF]");
            message.setFilePath(gifUrl);
            message.setFileType("gif");
            
            boolean success = messageDAO.sendGroupMessage(message);
            
            if (success) {
                response.sendRedirect("group-chat.jsp?groupId=" + groupId);
            } else {
                response.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
                response.getWriter().write("Erreur lors de l'envoi du GIF");
            }
        } catch (Exception e) {
            e.printStackTrace();
            response.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
            response.getWriter().write("Erreur: " + e.getMessage());
        }
    }
}