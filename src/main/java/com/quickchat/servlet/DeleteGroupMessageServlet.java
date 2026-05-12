package com.quickchat.servlet;

import com.quickchat.model.User;
import com.quickchat.model.GroupMessage;
import com.quickchat.dao.GroupMessageDAO;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import java.io.File;
import java.io.IOException;

@WebServlet("/deleteGroupMessage")
public class DeleteGroupMessageServlet extends HttpServlet {
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
        
        int messageId = Integer.parseInt(request.getParameter("messageId"));
        int groupId = Integer.parseInt(request.getParameter("groupId"));
        String type = request.getParameter("type");
        
        GroupMessageDAO messageDAO = new GroupMessageDAO();
        boolean success = false;
        
        if ("me".equals(type)) {
            success = messageDAO.deleteMessageForUser(messageId, user.getId());
        } else if ("everyone".equals(type)) {
            // Récupérer le message pour supprimer le fichier physique
            GroupMessage msg = messageDAO.getMessageById(messageId);
            if (msg != null && msg.getFilePath() != null && !msg.getFilePath().isEmpty()) {
                String filePath = getServletContext().getRealPath("/") + msg.getFilePath();
                File file = new File(filePath);
                if (file.exists()) {
                    file.delete();
                }
            }
            success = messageDAO.deleteMessageForEveryone(messageId, user.getId());
        }
        
        if (success) {
            response.sendRedirect("group-chat.jsp?groupId=" + groupId);
        } else {
            response.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
            response.getWriter().write("Erreur lors de la suppression");
        }
    }
}