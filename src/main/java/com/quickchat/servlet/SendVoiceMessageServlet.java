package com.quickchat.servlet;

import java.io.File;
import java.io.IOException;
import javax.servlet.ServletException;
import javax.servlet.annotation.MultipartConfig;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import javax.servlet.http.Part;
import com.quickchat.model.Message;
import com.quickchat.model.User;
import com.quickchat.dao.MessageDAO;

@WebServlet("/sendVoiceMessage")
@MultipartConfig(
    fileSizeThreshold = 1024 * 1024,
    maxFileSize = 1024 * 1024 * 10,
    maxRequestSize = 1024 * 1024 * 15
)
public class SendVoiceMessageServlet extends HttpServlet {
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
        
        int receiverId = Integer.parseInt(request.getParameter("receiverId"));
        Part voicePart = request.getPart("voice");
        
        if (voicePart != null && voicePart.getSize() > 0) {
            String fileName = "voice_" + System.currentTimeMillis() + "_" + user.getId() + ".webm";
            String uploadPath = getServletContext().getRealPath("/uploads/voices/");
            File uploadDir = new File(uploadPath);
            if (!uploadDir.exists()) uploadDir.mkdirs();
            
            voicePart.write(uploadPath + fileName);
            
            Message message = new Message();
            message.setSenderId(user.getId());
            message.setReceiverId(receiverId);
            message.setContent("[Message vocal]");
            message.setFilePath("uploads/voices/" + fileName);
            message.setFileType("audio/webm");
            
            boolean sent = messageDAO.sendMessage(message);
            
            if (sent) {
                response.setStatus(HttpServletResponse.SC_OK);
            } else {
                response.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
            }
        } else {
            response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
        }
    }
}