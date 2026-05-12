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

@WebServlet("/uploadFile")
@MultipartConfig(
    fileSizeThreshold = 1024 * 1024 * 2,   // 2MB
    maxFileSize = 1024 * 1024 * 20,        // 20MB max
    maxRequestSize = 1024 * 1024 * 50      // 50MB total request
)
public class FileUploadServlet extends HttpServlet {
    
    private static final long serialVersionUID = 1L;
    
    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        
        try {
            // 1. Récupérer l'ID du destinataire
            String receiverIdStr = request.getParameter("receiverId");
            int receiverId = 0;
            if (receiverIdStr != null && !receiverIdStr.isEmpty()) {
                receiverId = Integer.parseInt(receiverIdStr);
            } else {
                response.getWriter().write("{\"status\":\"error\", \"message\":\"Destinataire non spécifié\"}");
                return;
            }
            
            // 2. Récupérer l'ID de l'expéditeur depuis la session
            int senderId = getCurrentUserId(request);
            if (senderId == 0) {
                response.getWriter().write("{\"status\":\"error\", \"message\":\"Utilisateur non connecté\"}");
                return;
            }
            
            // 3. Récupérer le fichier
            Part filePart = request.getPart("file");
            if (filePart == null || filePart.getSize() == 0) {
                response.getWriter().write("{\"status\":\"error\", \"message\":\"Aucun fichier reçu\"}");
                return;
            }
            
            // 4. Récupérer le nom du fichier
            String fileName = Paths.get(filePart.getSubmittedFileName()).getFileName().toString();
            // Nettoyer le nom du fichier
            fileName = fileName.replaceAll("[^a-zA-Z0-9._-]", "_");
            
            // 5. Générer un nom unique
            String uniqueFileName = System.currentTimeMillis() + "_" + fileName;
            
            // 6. Définir le chemin de sauvegarde
            String uploadPath = getServletContext().getRealPath("/") + "uploads" + File.separator;
            File uploadDir = new File(uploadPath);
            if (!uploadDir.exists()) {
                uploadDir.mkdirs();
            }
            
            // 7. Sauvegarder le fichier
            String filePath = uploadPath + uniqueFileName;
            filePart.write(filePath);
            
            // 8. Sauvegarder dans la base de données
            String relativePath = "uploads/" + uniqueFileName;
            String fileType = filePart.getContentType();
            
            boolean saved = saveMessageToDatabase(senderId, receiverId, relativePath, fileType, fileName);
            
            if (saved) {
                response.getWriter().write("{\"status\":\"success\", \"message\":\"Fichier envoyé avec succès\", \"filePath\":\"" + relativePath + "\"}");
            } else {
                response.getWriter().write("{\"status\":\"error\", \"message\":\"Erreur lors de l'enregistrement\"}");
            }
            
        } catch (Exception e) {
            e.printStackTrace();
            response.getWriter().write("{\"status\":\"error\", \"message\":\"" + e.getMessage().replace("\"", "\\\"") + "\"}");
        }
    }
    
    private int getCurrentUserId(HttpServletRequest request) {
        HttpSession session = request.getSession(false);
        if (session != null) {
            Object userObj = session.getAttribute("user");
            if (userObj != null) {
                try {
                    // Utiliser la réflexion pour éviter d'importer la classe User
                    java.lang.reflect.Method getIdMethod = userObj.getClass().getMethod("getId");
                    int userId = (int) getIdMethod.invoke(userObj);
                    // Pour l'admin (ID 999) on utilise 9
                    return userId == 999 ? 9 : userId;
                } catch (Exception e) {
                    e.printStackTrace();
                }
            }
        }
        return 0;
    }
    
    private boolean saveMessageToDatabase(int senderId, int receiverId, String filePath, String fileType, String fileName) {
        Connection conn = null;
        PreparedStatement pstmt = null;
        
        try {
            // Charger le driver MySQL
            Class.forName("com.mysql.cj.jdbc.Driver");
            
            // Connexion à la base de données
            conn = DriverManager.getConnection(
                "jdbc:mysql://localhost:3306/quickchat?useSSL=false&serverTimezone=UTC",
                "root",
                ""
            );
            
            // Requête d'insertion
            String sql = "INSERT INTO messages (sender_id, receiver_id, content, file_path, file_type, is_read, is_delivered, created_at) "
                       + "VALUES (?, ?, ?, ?, ?, 0, 1, NOW())";
            pstmt = conn.prepareStatement(sql);
            pstmt.setInt(1, senderId);
            pstmt.setInt(2, receiverId);
            pstmt.setString(3, "📎 " + fileName);  // Nom du fichier comme contenu
            pstmt.setString(4, filePath);
            pstmt.setString(5, fileType);
            
            int result = pstmt.executeUpdate();
            return result > 0;
            
        } catch (Exception e) {
            e.printStackTrace();
            return false;
        } finally {
            try { if (pstmt != null) pstmt.close(); } catch (Exception e) {}
            try { if (conn != null) conn.close(); } catch (Exception e) {}
        }
    }
}