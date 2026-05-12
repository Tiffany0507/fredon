<%@ page language="java" contentType="application/json; charset=UTF-8" pageEncoding="UTF-8" import="java.sql.*, java.util.*" %>
<%
response.setContentType("application/json");
response.setCharacterEncoding("UTF-8");

String propertyIdStr = request.getParameter("propertyId");
if(propertyIdStr == null || propertyIdStr.trim().isEmpty()) {
    out.print("{}");
    return;
}

int propertyId = Integer.parseInt(propertyIdStr);

String DB_URL = "jdbc:mysql://localhost:3306/quickchat";
String DB_USER = "root";
String DB_PASSWORD = "";

Map<String, List<Map<String, String>>> reactionsMap = new HashMap<>();
reactionsMap.put("jadore", new ArrayList<>());
reactionsMap.put("jaime", new ArrayList<>());
reactionsMap.put("haha", new ArrayList<>());
reactionsMap.put("colere", new ArrayList<>());
reactionsMap.put("triste", new ArrayList<>());

try {
    Class.forName("com.mysql.cj.jdbc.Driver");
    Connection conn = DriverManager.getConnection(DB_URL, DB_USER, DB_PASSWORD);
    
    // Requête corrigée pour bien récupérer les utilisateurs connectés
    String sql = "SELECT " +
                 "pr.reaction_type, " +
                 "pr.user_id, " +
                 "CASE " +
                 "  WHEN pr.user_id IS NOT NULL AND u.display_name IS NOT NULL THEN u.display_name " +
                 "  WHEN pr.user_id IS NOT NULL AND u.username IS NOT NULL THEN u.username " +
                 "  ELSE pr.visitor_identifier " +
                 "END as user_name, " +
                 "u.email, " +
                 "u.profile_pic " +
                 "FROM property_reactions pr " +
                 "LEFT JOIN users u ON pr.user_id = u.id " +
                 "WHERE pr.property_id = ?";
    
    PreparedStatement pstmt = conn.prepareStatement(sql);
    pstmt.setInt(1, propertyId);
    ResultSet rs = pstmt.executeQuery();
    
    while(rs.next()) {
        String reactionType = rs.getString("reaction_type");
        String userName = rs.getString("user_name");
        String email = rs.getString("email");
        String profilePic = rs.getString("profile_pic");
        int userId = rs.getInt("user_id");
        
        // Nettoyer le nom
        if(userName == null || userName.isEmpty()) {
            userName = "Visiteur";
        }
        // Si c'est un hash, le rendre lisible
        else if(userName.length() > 10 && !userName.contains(" ")) {
            userName = "Visiteur_" + userName.substring(0, 6);
        }
        
        Map<String, String> userInfo = new HashMap<>();
        userInfo.put("type", userId > 0 ? "registered" : "guest");
        userInfo.put("name", userName);
        userInfo.put("email", email != null ? email : "");
        userInfo.put("profile_pic", profilePic != null ? profilePic : "");
        userInfo.put("initial", userId > 0 ? userName.substring(0, 1).toUpperCase() : "👤");
        
        if(reactionsMap.containsKey(reactionType)) {
            reactionsMap.get(reactionType).add(userInfo);
        }
    }
    
    rs.close();
    pstmt.close();
    conn.close();
    
} catch(Exception e) {
    e.printStackTrace();
    out.print("{\"error\":\"" + e.getMessage().replace("\"", "\\\"") + "\"}");
    return;
}

// Construction JSON
StringBuilder json = new StringBuilder();
json.append("{");

String[] types = {"jadore", "jaime", "haha", "colere", "triste"};
String[] emojis = {"❤️", "👍", "😂", "😡", "😢"};
String[] labels = {"J'adore", "J'aime", "Haha", "Colère", "Triste"};

for(int i = 0; i < types.length; i++) {
    String type = types[i];
    List<Map<String, String>> users = reactionsMap.get(type);
    
    json.append("\"").append(type).append("\":{");
    json.append("\"emoji\":\"").append(emojis[i]).append("\",");
    json.append("\"label\":\"").append(labels[i]).append("\",");
    json.append("\"count\":").append(users.size()).append(",");
    json.append("\"users\":[");
    
    for(int j = 0; j < users.size(); j++) {
        Map<String, String> user = users.get(j);
        if(j > 0) json.append(",");
        
        json.append("{");
        json.append("\"type\":\"").append(user.get("type")).append("\",");
        json.append("\"name\":\"").append(user.get("name").replace("\"", "\\\"")).append("\",");
        json.append("\"email\":\"").append(user.get("email").replace("\"", "\\\"")).append("\",");
        json.append("\"profile_pic\":\"").append(user.get("profile_pic").replace("\"", "\\\"")).append("\",");
        json.append("\"initial\":\"").append(user.get("initial").replace("\"", "\\\"")).append("\"");
        json.append("}");
    }
    
    json.append("]}");
    if(i < types.length - 1) json.append(",");
}

json.append("}");
out.print(json.toString());
%>