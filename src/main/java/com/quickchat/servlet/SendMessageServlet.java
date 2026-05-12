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
import com.quickchat.dao.UserDAO;
import com.quickchat.utils.NotificationHelper;

@WebServlet("/sendMessage")
@MultipartConfig(
    fileSizeThreshold = 1024 * 1024,
    maxFileSize       = 1024 * 1024 * 10,
    maxRequestSize    = 1024 * 1024 * 15
)
public class SendMessageServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;
    private MessageDAO messageDAO;
    private UserDAO    userDAO;

    public void init() {
        messageDAO = new MessageDAO();
        userDAO    = new UserDAO();
    }

    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession();
        User user = (User) session.getAttribute("user");

        if (user == null) {
            response.sendRedirect("login.jsp");
            return;
        }

        int    receiverId = Integer.parseInt(request.getParameter("receiverId"));
        String content    = request.getParameter("content");
        String gifUrl     = request.getParameter("gifUrl");

        // ── Reply ──────────────────────────────────────────────────────────
        int replyToMessageId = 0;
        String replyParam = request.getParameter("replyToMessageId");
        if (replyParam != null && !replyParam.isEmpty()) {
            try { replyToMessageId = Integer.parseInt(replyParam); } catch (NumberFormatException e) {}
        }

        // ── Correction admin (ID 999 → envoie en tant qu'agent ID 9) ──────
        int effectiveSenderId = (user.getId() == 999) ? 9 : user.getId();

        // ── Publication immobilière partagée ───────────────────────────────
        String propIdStr    = request.getParameter("propertyId");
        String propTitle    = request.getParameter("propertyTitle");
        String propPriceStr = request.getParameter("propertyPrice");
        String propImage    = request.getParameter("propertyImage");
        String propType     = request.getParameter("propertyType");
        String propLocation = request.getParameter("propertyLocation");

        Integer propertyId    = null;
        Long    propertyPrice = null;

        if (propIdStr != null && !propIdStr.trim().isEmpty()) {
            try { propertyId = Integer.parseInt(propIdStr.trim()); } catch (NumberFormatException e) {}
        }
        if (propPriceStr != null && !propPriceStr.trim().isEmpty()) {
            try { propertyPrice = Long.parseLong(propPriceStr.trim()); } catch (NumberFormatException e) {}
        }

        // ── Construction du message ────────────────────────────────────────
        Message message = new Message();
        message.setSenderId(effectiveSenderId);
        message.setReceiverId(receiverId);
        message.setReplyToMessageId(replyToMessageId);

        // Champs publication
        message.setPropertyId(propertyId);
        message.setPropertyTitle(propTitle);
        message.setPropertyPrice(propertyPrice);
        message.setPropertyImage(propImage);
        message.setPropertyType(propType);
        message.setPropertyLocation(propLocation);

        // ── Contenu ────────────────────────────────────────────────────────
        boolean isMultipart = request.getContentType() != null &&
                              request.getContentType().toLowerCase().startsWith("multipart/form-data");

        if (gifUrl != null && !gifUrl.isEmpty()) {
            message.setGifUrl(gifUrl);
            message.setContent("[GIF]");

        } else if (isMultipart) {
            try {
                Part filePart = request.getPart("photo");
                if (filePart != null && filePart.getSize() > 0) {
                    String fileName  = System.currentTimeMillis() + "_" + filePart.getSubmittedFileName();
                    String uploadPath = getServletContext().getRealPath("/uploads/");
                    File uploadDir = new File(uploadPath);
                    if (!uploadDir.exists()) uploadDir.mkdirs();
                    filePart.write(uploadPath + fileName);
                    message.setFilePath("uploads/" + fileName);
                    message.setFileType(filePart.getContentType());
                    message.setContent((content == null || content.trim().isEmpty()) ? "[Photo]" : content);
                } else {
                    message.setContent(content);
                }
            } catch (Exception e) {
                e.printStackTrace();
                message.setContent(content);
            }
        } else {
            message.setContent(content);
        }

        // ── Envoi ──────────────────────────────────────────────────────────
        boolean sent = messageDAO.sendMessage(message);

        if (sent) {
            User receiver = userDAO.getUserById(receiverId);
            if (receiver != null) {
                String senderName = (user.getId() == 999) ? "Admin" : user.getUsername();
                NotificationHelper.notifyNewMessage(receiverId, senderName);
            }
            response.sendRedirect("chat.jsp?userId=" + receiverId);
        } else {
            response.sendRedirect("chat.jsp?userId=" + receiverId + "&error=Erreur+d%27envoi");
        }
    }
}