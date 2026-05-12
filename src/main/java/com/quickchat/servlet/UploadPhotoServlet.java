package com.quickchat.servlet;

import java.io.File;
import java.io.IOException;
import java.nio.file.Paths;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import javax.servlet.ServletException;
import javax.servlet.annotation.MultipartConfig;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import javax.servlet.http.Part;

@WebServlet("/uploadPhoto")
@MultipartConfig(
    fileSizeThreshold = 1024 * 1024 * 2,
    maxFileSize = 1024 * 1024 * 10,      // 10MB
    maxRequestSize = 1024 * 1024 * 50
)
public class UploadPhotoServlet extends HttpServlet {
    
    private static final long serialVersionUID = 1L;
    
    @Override
    protected void doOptions(HttpServletRequest request, HttpServletResponse response) {
        response.setHeader("Access-Control-Allow-Origin", "*");
        response.setHeader("Access-Control-Allow-Methods", "POST, OPTIONS");
        response.setHeader("Access-Control-Allow-Headers", "Content-Type");
        response.setStatus(HttpServletResponse.SC_OK);
    }
    
    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        
        System.out.println("=== UPLOAD PHOTO ===");
        
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        response.setHeader("Access-Control-Allow-Origin", "*");
        
        try {
            // Vérifier la session
            HttpSession session = request.getSession(false);
            if (session == null) {
                System.out.println("ERREUR: Session null");
                response.setStatus(403);
                response.getWriter().write("{\"status\":\"error\", \"message\":\"Session expirée\"}");
                return;
            }
            
            Object userObj = session.getAttribute("user");
            if (userObj == null) {
                Object adminId = session.getAttribute("adminId");
                if (adminId == null) {
                    System.out.println("ERREUR: Utilisateur non connecté");
                    response.setStatus(403);
                    response.getWriter().write("{\"status\":\"error\", \"message\":\"Non authentifié\"}");
                    return;
                }
            }
            
            // Récupérer l'ID du destinataire
            String receiverIdStr = request.getParameter("receiverId");
            int receiverId = 0;
            if (receiverIdStr != null && !receiverIdStr.isEmpty()) {
                receiverId = Integer.parseInt(receiverIdStr);
            } else {
                response.getWriter().write("{\"status\":\"error\", \"message\":\"Destinataire non spécifié\"}");
                return;
            }
            
            // Récupérer l'ID de l'expéditeur
            int senderId = getCurrentUserId(request);
            System.out.println("SenderId: " + senderId + ", ReceiverId: " + receiverId);
            
            // Récupérer la photo
            Part photoPart = request.getPart("photo");
            if (photoPart == null || photoPart.getSize() == 0) {
                response.getWriter().write("{\"status\":\"error\", \"message\":\"Aucune photo reçue\"}");
                return;
            }
            
            System.out.println("Photo reçue, taille: " + photoPart.getSize() + " bytes");
            
            // Nom du fichier
            String originalName = Paths.get(photoPart.getSubmittedFileName()).getFileName().toString();
            String extension = "";
            int dotIndex = originalName.lastIndexOf(".");
            if (dotIndex > 0) {
                extension = originalName.substring(dotIndex);
            }
            String fileName = System.currentTimeMillis() + "_photo" + extension;
            fileName = fileName.replaceAll("[^a-zA-Z0-9._-]", "_");
            
            // Chemin de sauvegarde
            String uploadPath = getServletContext().getRealPath("/") + "uploads" + File.separator;
            File uploadDir = new File(uploadPath);
            if (!uploadDir.exists()) {
                uploadDir.mkdirs();
            }
            
            String filePath = uploadPath + fileName;
            photoPart.write(filePath);
            System.out.println("Photo sauvegardée: " + filePath);
            
            // Sauvegarder dans la base de données
            String relativePath = "uploads/" + fileName;
            boolean saved = savePhotoToDatabase(senderId, receiverId, relativePath, photoPart.getContentType());
            
            if (saved) {
                response.getWriter().write("{\"status\":\"success\", \"message\":\"Photo envoyée\", \"filePath\":\"" + relativePath + "\"}");
                System.out.println("SUCCÈS: Photo envoyée");
            } else {
                response.getWriter().write("{\"status\":\"error\", \"message\":\"Erreur base de données\"}");
            }
            
        } catch (Exception e) {
            e.printStackTrace();
            response.setStatus(500);
            response.getWriter().write("{\"status\":\"error\", \"message\":\"" + e.getMessage().replace("\"", "\\\"") + "\"}");
        }
    }
    
    private int getCurrentUserId(HttpServletRequest request) {
        HttpSession session = request.getSession(false);
        if (session != null) {
            Object userObj = session.getAttribute("user");
            if (userObj != null) {
                try {
                    java.lang.reflect.Method getIdMethod = userObj.getClass().getMethod("getId");
                    int userId = (int) getIdMethod.invoke(userObj);
                    return userId == 999 ? 9 : userId;
                } catch (Exception e) {
                    e.printStackTrace();
                }
            }
        }
        return 0;
    }
    
    private boolean savePhotoToDatabase(int senderId, int receiverId, String filePath, String fileType) {
        Connection conn = null;
        PreparedStatement pstmt = null;
        
        try {
            Class.forName("com.mysql.cj.jdbc.Driver");
            conn = DriverManager.getConnection(
                "jdbc:mysql://localhost:3306/quickchat?useSSL=false&serverTimezone=UTC",
                "root",
                ""
            );
            
            String sql = "INSERT INTO messages (sender_id, receiver_id, content, file_path, file_type, is_read, is_delivered, created_at) "
                       + "VALUES (?, ?, '📷 Photo', ?, ?, 0, 1, NOW())";
            pstmt = conn.prepareStatement(sql);
            pstmt.setInt(1, senderId);
            pstmt.setInt(2, receiverId);
            pstmt.setString(3, filePath);
            pstmt.setString(4, fileType);
            
            return pstmt.executeUpdate() > 0;
            
        } catch (Exception e) {
            e.printStackTrace();
            return false;
        } finally {
            try { if (pstmt != null) pstmt.close(); } catch (Exception e) {}
            try { if (conn != null) conn.close(); } catch (Exception e) {}
        }
    }
}