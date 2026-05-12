<%@ page language="java" contentType="application/json; charset=UTF-8" pageEncoding="UTF-8" import="java.sql.*, java.util.*" %>
<%
response.setContentType("application/json");
response.setCharacterEncoding("UTF-8");

String DB_URL = "jdbc:mysql://localhost:3306/quickchat";
String DB_USER = "root";
String DB_PASSWORD = "";

List<Map<String, Object>> results = new ArrayList<>();

try {
    Class.forName("com.mysql.cj.jdbc.Driver");
    Connection conn = DriverManager.getConnection(DB_URL, DB_USER, DB_PASSWORD);
    
    // Requête pour récupérer l'image principale de chaque bien
    String sql = "SELECT " +
                 "p.id, " +
                 "p.title, " +
                 "p.location, " +
                 "COALESCE((SELECT image_url FROM property_images WHERE property_id = p.id AND is_primary = 1 LIMIT 1), " +
                 "(SELECT image_url FROM property_images WHERE property_id = p.id LIMIT 1)) as main_image, " +
                 "COUNT(CASE WHEN pr.reaction_type = 'jadore' THEN 1 END) as jadore, " +
                 "COUNT(CASE WHEN pr.reaction_type = 'jaime' THEN 1 END) as jaime, " +
                 "COUNT(CASE WHEN pr.reaction_type = 'haha' THEN 1 END) as haha, " +
                 "COUNT(CASE WHEN pr.reaction_type = 'colere' THEN 1 END) as colere, " +
                 "COUNT(CASE WHEN pr.reaction_type = 'triste' THEN 1 END) as triste " +
                 "FROM properties p " +
                 "LEFT JOIN property_reactions pr ON p.id = pr.property_id " +
                 "GROUP BY p.id, p.title, p.location " +
                 "ORDER BY p.id DESC";
    
    Statement stmt = conn.createStatement();
    ResultSet rs = stmt.executeQuery(sql);
    
    while(rs.next()) {
        Map<String, Object> row = new HashMap<>();
        row.put("id", rs.getInt("id"));
        row.put("title", rs.getString("title"));
        row.put("location", rs.getString("location"));
        
        // Récupérer l'URL de l'image
        String mainImage = rs.getString("main_image");
        if(mainImage != null && !mainImage.isEmpty()) {
            // Ne pas ajouter le chemin ici, on le fera dans le JavaScript
            row.put("main_image", mainImage);
        } else {
            row.put("main_image", null);
        }
        
        row.put("jadore", rs.getInt("jadore"));
        row.put("jaime", rs.getInt("jaime"));
        row.put("haha", rs.getInt("haha"));
        row.put("colere", rs.getInt("colere"));
        row.put("triste", rs.getInt("triste"));
        results.add(row);
    }
    
    rs.close();
    stmt.close();
    conn.close();
    
} catch(Exception e) {
    e.printStackTrace();
}

// Construction JSON
StringBuilder json = new StringBuilder();
json.append("[");

int index = 0;
for(Map<String, Object> row : results) {
    int total = (Integer)row.get("jadore") + (Integer)row.get("jaime") + 
                (Integer)row.get("haha") + (Integer)row.get("colere") + 
                (Integer)row.get("triste");
    
    if(total > 0) {
        if(index > 0) json.append(",");
        
        json.append("{");
        json.append("\"id\":").append(row.get("id"));
        json.append(",\"title\":\"").append(String.valueOf(row.get("title")).replace("\"", "\\\"")).append("\"");
        json.append(",\"location\":\"").append(String.valueOf(row.get("location")).replace("\"", "\\\"")).append("\"");
        
        // Ajouter l'image principale
        String mainImage = (String) row.get("main_image");
        if(mainImage != null && !mainImage.isEmpty()) {
            json.append(",\"main_image\":\"").append(mainImage.replace("\"", "\\\"")).append("\"");
        } else {
            json.append(",\"main_image\":null");
        }
        
        json.append(",\"jadore\":").append(row.get("jadore"));
        json.append(",\"jaime\":").append(row.get("jaime"));
        json.append(",\"haha\":").append(row.get("haha"));
        json.append(",\"colere\":").append(row.get("colere"));
        json.append(",\"triste\":").append(row.get("triste"));
        json.append("}");
        index++;
    }
}

json.append("]");
out.print(json.toString());
%>