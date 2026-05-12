package com.immobilier.servlet;

import com.immobilier.dao.PropertyDAO;
import com.immobilier.dao.PropertyImageDAO;
import com.immobilier.model.Property;
import com.immobilier.model.PropertyImage;
import com.quickchat.utils.NotificationHelper;

import javax.servlet.ServletException;
import javax.servlet.annotation.MultipartConfig;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import javax.servlet.http.Part;
import java.io.File;
import java.io.IOException;
import java.math.BigDecimal;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.Statement;
import java.sql.SQLException;
import java.util.UUID;

@WebServlet("/immo/admin/add-property")
@MultipartConfig(
    fileSizeThreshold = 1024 * 1024 * 2,
    maxFileSize = 1024 * 1024 * 10,
    maxRequestSize = 1024 * 1024 * 50
)
public class AddPropertyServlet extends HttpServlet {

    private static final String UPLOAD_DIRECTORY = "uploads/properties";
    private static final String DB_URL = "jdbc:mysql://localhost:3306/quickchat";
    private static final String DB_USER = "root";
    private static final String DB_PASSWORD = "";

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        
        HttpSession session = request.getSession(false);
        
        if (session == null || session.getAttribute("adminId") == null) {
            response.sendRedirect(request.getContextPath() + "/immo/admin/login.jsp");
            return;
        }

        int adminId = (int) session.getAttribute("adminId");

        // Champs communs à tous les types de biens
        String title = request.getParameter("title");
        String description = request.getParameter("description");
        String priceStr = request.getParameter("price");
        String location = request.getParameter("location");
        String type = request.getParameter("type");
        
        // Nettoyage du prix
        BigDecimal price = null;
        try {
            String cleanPrice = priceStr.replaceAll("[^0-9]", "");
            price = new BigDecimal(cleanPrice);
        } catch (Exception e) {
            request.setAttribute("error", "Format de prix invalide.");
            request.getRequestDispatcher("/immo/admin/add-property.jsp").forward(request, response);
            return;
        }
        
        // Champs pour Maison/Appartement (peuvent être null pour les terrains)
        String surfaceStr = request.getParameter("surface");
        String roomsStr = request.getParameter("rooms");
        String bedroomsStr = request.getParameter("bedrooms");
        String bathroomsStr = request.getParameter("bathrooms");
        
        // Champs GPS
        String latitudeStr = request.getParameter("latitude");
        String longitudeStr = request.getParameter("longitude");
        
        // ⭐⭐⭐ CHAMPS SPÉCIFIQUES AUX TERRAINS ⭐⭐⭐
        String landArea = request.getParameter("landArea");
        String landType = request.getParameter("landType");
        String landDocumentation = request.getParameter("landDocumentation");
        String landAccess = request.getParameter("landAccess");
        String landProximities = request.getParameter("landProximities");
        String landNotes = request.getParameter("landNotes");

        // Validation des champs obligatoires communs
        if (title == null || title.trim().isEmpty() ||
            description == null || description.trim().isEmpty() ||
            priceStr == null || priceStr.trim().isEmpty() ||
            location == null || location.trim().isEmpty() ||
            type == null || type.trim().isEmpty()) {
            
            request.setAttribute("error", "Tous les champs obligatoires doivent être remplis.");
            request.getRequestDispatcher("/immo/admin/add-property.jsp").forward(request, response);
            return;
        }

        // Validation supplémentaire pour les terrains
        if ("Terrain".equals(type)) {
            if ((landArea == null || landArea.trim().isEmpty()) &&
                (landType == null || landType.trim().isEmpty()) &&
                (landDocumentation == null || landDocumentation.trim().isEmpty())) {
                System.out.println("Info: Terrain ajouté avec peu de détails");
            }
        } else {
            // Pour les maisons/appartements, la surface est fortement recommandée
            if (surfaceStr == null || surfaceStr.trim().isEmpty()) {
                request.setAttribute("error", "La surface du bien est requise.");
                request.getRequestDispatcher("/immo/admin/add-property.jsp").forward(request, response);
                return;
            }
        }

        try (Connection conn = DriverManager.getConnection(DB_URL, DB_USER, DB_PASSWORD)) {
            Class.forName("com.mysql.cj.jdbc.Driver");
            
            conn.setAutoCommit(false);
            
            try {
                // ⭐ CRÉATION DE L'OBJET PROPERTY (déplacé ici) ⭐
                Property property = new Property();
                property.setTitle(title);
                property.setDescription(description);
                property.setPrice(price);  // ← Utiliser le prix nettoyé
                property.setLocation(location);
                property.setType(type);
                property.setAdminId(adminId);

                // Ajout des optionnels (maisons/appartements)
                if (surfaceStr != null && !surfaceStr.trim().isEmpty()) {
                    property.setSurface(Integer.parseInt(surfaceStr));
                } else {
                    property.setSurface(0);
                }
                if (roomsStr != null && !roomsStr.trim().isEmpty()) {
                    property.setRooms(Integer.parseInt(roomsStr));
                } else {
                    property.setRooms(0);
                }
                if (bedroomsStr != null && !bedroomsStr.trim().isEmpty()) {
                    property.setBedrooms(Integer.parseInt(bedroomsStr));
                } else {
                    property.setBedrooms(0);
                }
                if (bathroomsStr != null && !bathroomsStr.trim().isEmpty()) {
                    property.setBathrooms(Integer.parseInt(bathroomsStr));
                } else {
                    property.setBathrooms(0);
                }
                
                // Coordonnées GPS
                if (latitudeStr != null && !latitudeStr.trim().isEmpty()) {
                    property.setLatitude(Double.parseDouble(latitudeStr));
                }
                if (longitudeStr != null && !longitudeStr.trim().isEmpty()) {
                    property.setLongitude(Double.parseDouble(longitudeStr));
                }

                // Stockage des infos terrain si c'est un terrain
                if ("Terrain".equals(type)) {
                    property.setLandArea(landArea);
                    property.setLandType(landType);
                    property.setLandDocumentation(landDocumentation);
                    property.setLandAccess(landAccess);
                    property.setLandProximities(landProximities);
                    property.setLandNotes(landNotes);
                }

                PropertyDAO propertyDAO = new PropertyDAO(conn);
                
                if (propertyDAO.addProperty(property)) {
                    
                    PropertyImageDAO imageDAO = new PropertyImageDAO(conn);
                    String uploadPath = getServletContext().getRealPath("") + File.separator + UPLOAD_DIRECTORY;
                    
                    File uploadDir = new File(uploadPath);
                    if (!uploadDir.exists()) {
                        uploadDir.mkdirs();
                    }

                    boolean isFirstImage = true;
                    String[] imageFields = {"image1", "image2", "image3"};
                    
                    for (String fieldName : imageFields) {
                        Part part = request.getPart(fieldName);
                        if (part != null && part.getSize() > 0) {
                            String fileName = extractFileName(part);
                            String uniqueFileName = UUID.randomUUID().toString() + "_" + fileName;
                            String filePath = uploadPath + File.separator + uniqueFileName;
                            
                            part.write(filePath);
                            
                            PropertyImage image = new PropertyImage();
                            image.setPropertyId(property.getId());
                            image.setImageUrl(UPLOAD_DIRECTORY + "/" + uniqueFileName);
                            image.setPrimary(isFirstImage);
                            imageDAO.addImage(image);
                            isFirstImage = false;
                        }
                    }
                    
                    if (isFirstImage) {
                        conn.rollback();
                        request.setAttribute("error", "Veuillez ajouter au moins une photo.");
                        request.getRequestDispatcher("/immo/admin/add-property.jsp").forward(request, response);
                        return;
                    }
                    
                    conn.commit();
                    
                    // 🔔 NOTIFICATION À L'ADMIN
                    NotificationHelper.notifyNewProperty(adminId, title);
                    
                    // 🔔 NOTIFICATION À TOUS LES CLIENTS
                    String notificationTitle = "";
                    String notificationMessage = "";
                    
                    if ("Terrain".equals(type)) {
                        notificationTitle = "🌾 Nouveau terrain disponible !";
                        notificationMessage = "Un nouveau terrain \"" + title + "\" vient d'être ajouté à " + location;
                    } else if ("Vente".equals(type)) {
                        notificationTitle = "🏠 Nouveau bien à vendre !";
                        notificationMessage = "Un nouveau bien \"" + title + "\" vient d'être mis en vente à " + location;
                    } else {
                        notificationTitle = "🔑 Nouvelle location disponible !";
                        notificationMessage = "Un nouveau bien \"" + title + "\" est disponible à la location à " + location;
                    }
                    
                    try {
                        String sqlNotif = "INSERT INTO notifications (user_id, user_type, type, title, message, link) VALUES (?, ?, ?, ?, ?, ?)";
                        PreparedStatement pstmt = conn.prepareStatement(sqlNotif);
                        
                        Statement stmt = conn.createStatement();
                        ResultSet rs = stmt.executeQuery("SELECT id FROM users WHERE role = 'client' OR role IS NULL OR role = ''");
                        
                        while (rs.next()) {
                            pstmt.setInt(1, rs.getInt("id"));
                            pstmt.setString(2, "client");
                            pstmt.setString(3, "new_property");
                            pstmt.setString(4, notificationTitle);
                            pstmt.setString(5, notificationMessage);
                            pstmt.setString(6, request.getContextPath() + "/immo/property-detail.jsp?id=" + property.getId());
                            pstmt.addBatch();
                        }
                        pstmt.executeBatch();
                        rs.close();
                        stmt.close();
                        pstmt.close();
                    } catch(Exception e) {
                        e.printStackTrace();
                    }
                    
                    response.sendRedirect(request.getContextPath() + "/immo/admin/dashboard.jsp?success=property_added");
                    
                } else {
                    conn.rollback();
                    request.setAttribute("error", "Erreur lors de l'ajout du bien.");
                    request.getRequestDispatcher("/immo/admin/add-property.jsp").forward(request, response);
                }
                
            } catch (SQLException e) {
                conn.rollback();
                throw e;
            }
            
        } catch (NumberFormatException e) {
            request.setAttribute("error", "Format de nombre invalide: " + e.getMessage());
            request.getRequestDispatcher("/immo/admin/add-property.jsp").forward(request, response);
        } catch (SQLException | ClassNotFoundException e) {
            e.printStackTrace();
            request.setAttribute("error", "Erreur de base de données : " + e.getMessage());
            request.getRequestDispatcher("/immo/admin/add-property.jsp").forward(request, response);
        }
    }

    private String extractFileName(Part part) {
        String contentDisp = part.getHeader("content-disposition");
        String[] items = contentDisp.split(";");
        for (String s : items) {
            if (s.trim().startsWith("filename")) {
                return s.substring(s.indexOf("=") + 2, s.length() - 1);
            }
        }
        return "";
    }
}