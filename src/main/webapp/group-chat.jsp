<%@ page language="java" contentType="text/html; charset=UTF-8"
	pageEncoding="UTF-8"%>
<%@ page
	import="com.quickchat.model.User, com.quickchat.model.Group, com.quickchat.model.GroupMessage, com.quickchat.dao.GroupDAO, com.quickchat.dao.GroupMemberDAO, com.quickchat.dao.GroupMessageDAO, com.quickchat.dao.ReactionDAO, com.quickchat.dao.ContactNameDAO, java.util.List, java.util.Map, java.sql.*, com.quickchat.utils.DatabaseConnection, java.util.ArrayList"%>
<%@ page import="com.quickchat.dao.ConversationDAO"%>
<%

    User user = (User) session.getAttribute("user");
    if (user == null) {
        response.sendRedirect("login.jsp");
        return;
    }
    
    int groupId = request.getParameter("groupId") != null ? Integer.parseInt(request.getParameter("groupId")) : 0;
    
    GroupDAO groupDAO = new GroupDAO();
    GroupMemberDAO memberDAO = new GroupMemberDAO();
    GroupMessageDAO messageDAO = new GroupMessageDAO();
    ReactionDAO reactionDAO = new ReactionDAO();
    ContactNameDAO contactNameDAO = new ContactNameDAO();
    
    Group group = groupDAO.getGroupById(groupId);
    List<User> members = memberDAO.getGroupMembers(groupId);
    List<GroupMessage> messages = messageDAO.getGroupMessages(groupId, user.getId());
    
    messageDAO.markGroupMessagesAsRead(groupId, user.getId());
    
    List<User> allUsers = new ArrayList<>();
    String sqlUsers = "SELECT id, username, display_name, profile_pic FROM users WHERE id != ? ORDER BY display_name ASC";
    try (Connection conn = DatabaseConnection.getConnection();
         PreparedStatement stmt = conn.prepareStatement(sqlUsers)) {
        stmt.setInt(1, user.getId());
        ResultSet rs = stmt.executeQuery();
        while (rs.next()) {
            User u = new User();
            u.setId(rs.getInt("id"));
            u.setUsername(rs.getString("username"));
            u.setDisplayName(rs.getString("display_name"));
            u.setProfilePic(rs.getString("profile_pic"));
            allUsers.add(u);
        }
    } catch (Exception e) {
        e.printStackTrace();
    }
    
    if (group == null || !memberDAO.isMember(groupId, user.getId())) {
        response.sendRedirect("chat.jsp");
        return;
    }
    
    String groupTheme = group.getTheme() != null ? group.getTheme() : "default";
%>
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>QuickChat - <%= group.getName() %></title>
<link rel="stylesheet"
	href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
<link rel="stylesheet" href="css/style.css">
<link rel="stylesheet" href="css/conversation_themes.css">
<script src="js/chat.js"></script>
<script src="js/theme.js"></script>
<style>
.sticker-picker-wrapper {
	position: relative;
}

.sticker-trigger-btn {
	background: var(--bg-input-msg);
	border: none;
	border-radius: 50%;
	width: 38px;
	height: 38px;
	cursor: pointer;
	display: flex;
	align-items: center;
	justify-content: center;
	color: var(--text-muted);
	transition: all 0.2s;
}

.sticker-trigger-btn:hover {
	background: var(--violet);
	color: white;
	transform: scale(1.08);
}

.sticker-picker-panel {
	position: absolute;
	bottom: 50px;
	left: 0;
	background: var(--bg-sidebar);
	border-radius: 20px;
	width: 320px;
	box-shadow: 0 8px 32px rgba(0, 0, 0, 0.18);
	border: 1px solid var(--border);
	z-index: 1000;
}

.sticker-cats-header {
	padding: 12px 14px 0 14px;
}

.sticker-cats-label {
	font-size: 10px;
	font-weight: 700;
	letter-spacing: 0.08em;
	text-transform: uppercase;
	color: var(--text-muted);
	margin-bottom: 8px;
	display: block;
}

.sticker-cats-scroll {
	display: flex;
	gap: 6px;
	overflow-x: scroll;
	padding-bottom: 12px;
	scrollbar-width: thin;
	border-bottom: 1px solid var(--border);
	cursor: grab;
}

.sticker-cats-scroll:active {
	cursor: grabbing;
}

.sticker-cats-scroll::-webkit-scrollbar {
	height: 3px;
}

.sticker-cats-scroll::-webkit-scrollbar-track {
	background: var(--bg-input-msg);
	border-radius: 10px;
}

.sticker-cats-scroll::-webkit-scrollbar-thumb {
	background: var(--violet);
	border-radius: 10px;
}

.sticker-cat-pill {
	display: flex;
	flex-direction: column;
	align-items: center;
	gap: 4px;
	padding: 7px 12px;
	border-radius: 14px;
	border: 1.5px solid transparent;
	background: var(--bg-input-msg);
	cursor: pointer;
	transition: all 0.18s ease;
	white-space: nowrap;
	min-width: 58px;
	flex-shrink: 0;
}

.sticker-cat-pill .cat-icon {
	font-size: 20px;
	line-height: 1;
}

.sticker-cat-pill .cat-name {
	font-size: 10px;
	font-weight: 600;
	color: var(--text-secondary);
}

.sticker-cat-pill:hover {
	border-color: var(--violet);
	background: var(--violet-pale);
}

.sticker-cat-pill.active {
	background: var(--violet);
	border-color: var(--violet);
}

.sticker-cat-pill.active .cat-name {
	color: #fff;
}

.sticker-grid-wrapper {
	padding: 12px 14px 14px 14px;
}

.sticker-item {
	border-radius: 12px;
	overflow: hidden;
	cursor: pointer;
	transition: transform 0.15s, box-shadow 0.15s;
	background: var(--bg-input-msg);
	display: flex;
	align-items: center;
	justify-content: center;
	aspect-ratio: 1;
}

.sticker-item:hover {
	transform: scale(1.1);
	box-shadow: 0 4px 14px rgba(109, 40, 217, 0.22);
}

.sticker-item img {
	width: 100%;
	height: 100%;
	object-fit: cover;
	border-radius: 10px;
}

.auth-logo-icon {
	width: 48px;
	height: 48px;
	margin: 0 auto;
}

#createGroupModal {
	display: none;
	position: fixed;
	top: 0;
	left: 0;
	width: 100%;
	height: 100%;
	background: rgba(0, 0, 0, 0.7);
	backdrop-filter: blur(8px);
	z-index: 9999;
	justify-content: center;
	align-items: center;
}

#createGroupModal>div {
	position: relative;
	z-index: 10000;
	background: var(--bg-sidebar);
	border-radius: 28px;
	width: 450px;
	max-width: 90vw;
	box-shadow: 0 25px 50px rgba(0, 0, 0, 0.3);
}

/* CORRECTION ZONE DE SAISIE */
.message-input-area {
	padding: 12px 20px;
	background: var(--bg-header);
	backdrop-filter: blur(18px);
	display: flex;
	align-items: center;
	gap: 10px;
	flex-shrink: 0;
	border-top: 1px solid var(--border);
	position: relative;
	z-index: 20;
	width: 100%;
	min-height: 70px;
}

.message-input-area form {
	flex: 1;
	display: flex;
	gap: 10px;
	align-items: center;
	min-width: 0;
}

.message-input-area input[name="content"], .message-input-area #messageInput
	{
	flex: 1;
	min-width: 0;
	padding: 12px 18px;
	background: var(--bg-input-msg);
	border: 1.5px solid var(--border);
	border-radius: 40px;
	outline: none;
	font-family: 'DM Sans', sans-serif;
	font-size: 14px;
	color: var(--text-primary);
}

.message-input-area input[name="content"]:focus, .message-input-area #messageInput:focus
	{
	border-color: var(--accent);
	background: var(--bg-sidebar);
	box-shadow: 0 0 0 3px rgba(37, 96, 224, .12);
}

.message-input-area button[type="submit"] {
	width: 44px;
	height: 44px;
	border-radius: 50%;
	background: var(--grad-brand);
	color: #fff;
	border: none;
	cursor: pointer;
	font-size: 16px;
	display: flex;
	align-items: center;
	justify-content: center;
	flex-shrink: 0;
	transition: transform .15s var(--bounce), box-shadow .15s;
}

.message-input-area button[type="submit"]:hover {
	transform: scale(1.1);
	box-shadow: 0 8px 24px rgba(37, 96, 224, .42);
}

.emoji-picker-wrapper, .gif-picker-wrapper, .sticker-picker-wrapper,
	.voice-picker-wrapper {
	flex-shrink: 0;
}

.emoji-trigger-btn, .gif-trigger-btn, .sticker-trigger-btn,
	.voice-trigger-btn {
	width: 38px;
	height: 38px;
	border-radius: 50%;
	background: var(--bg-input-msg);
	border: none;
	cursor: pointer;
	display: flex;
	align-items: center;
	justify-content: center;
	transition: all 0.2s;
	color: var(--text-muted);
}

.emoji-trigger-btn:hover, .gif-trigger-btn:hover, .sticker-trigger-btn:hover,
	.voice-trigger-btn:hover {
	background: var(--violet);
	color: white;
	transform: scale(1.08);
}

label[for="photoInput"] {
	width: 38px;
	height: 38px;
	border-radius: 50%;
	background: var(--bg-input-msg);
	display: flex;
	align-items: center;
	justify-content: center;
	cursor: pointer;
	flex-shrink: 0;
	transition: all 0.2s;
}

label[for="photoInput"]:hover {
	background: var(--violet);
	transform: scale(1.08);
}

label[for="photoInput"] i {
	color: var(--text-muted);
	font-size: 18px;
}

label[for="photoInput"]:hover i {
	color: white;
}
/* SOLUTION RÉACTIONS - À COPIER TELLEMENT QUEL */
.reaction-picker {
	position: relative;
	display: inline-block;
}

.reaction-picker-popup {
	position: absolute;
	bottom: 35px;
	left: 0;
	display: none;
	gap: 8px;
	padding: 10px 15px;
	background: white;
	border-radius: 30px;
	box-shadow: 0 4px 15px rgba(0, 0, 0, 0.2);
	z-index: 1000;
	white-space: nowrap;
	/* ZONE DE PONT INVISIBLE */
	padding-bottom: 20px;
	margin-bottom: -10px;
	background-clip: content-box;
}

.reaction-picker-popup span {
	font-size: 22px;
	cursor: pointer;
}

.reaction-picker-popup span:hover {
	transform: scale(1.2);
}

/* MAGIE : le menu reste ouvert au survol */
.reaction-picker:hover .reaction-picker-popup {
	display: flex;
}

.reaction-picker-popup:hover {
	display: flex;
}
</style>
</head>
<body class="theme-<%= groupTheme %>">
	<div class="app-container">
		<!-- Sidebar -->
		<div class="sidebar">
			<div class="sidebar-header">
				<div style="display: flex; align-items: center; gap: 12px;">
					<div onclick="location.href='chat.jsp'"
						style="cursor: pointer; display: flex; align-items: center; justify-content: center; width: 36px; height: 36px; border-radius: 50%; background: var(--bg-input-msg); transition: all 0.2s;"
						onmouseover="this.style.background='var(--violet)'; this.style.color='white';"
						onmouseout="this.style.background='var(--bg-input-msg)'; this.style.color='var(--text-primary)';">
						<i class="fas fa-arrow-left" style="font-size: 16px;"></i>
					</div>
					<div class="sidebar-logo">
						<svg width="42" height="42" viewBox="0 0 52 52" fill="none"
							xmlns="http://www.w3.org/2000/svg">
                            <defs>
                                <linearGradient id="groupSidebarGrad"
								x1="0%" y1="0%" x2="100%" y2="100%">
                                    <stop offset="0%"
								stop-color="#8B5CF6" />
                                    <stop offset="35%"
								stop-color="#6366F1" />
                                    <stop offset="70%"
								stop-color="#3B82F6" />
                                    <stop offset="100%"
								stop-color="#10B981" />
                                </linearGradient>
                                <linearGradient
								id="groupSidebarBoltGrad" x1="0%" y1="0%" x2="100%" y2="100%">
                                    <stop offset="0%"
								stop-color="#FCD34D" />
                                    <stop offset="100%"
								stop-color="#F59E0B" />
                                </linearGradient>
                                <filter id="groupSidebarGlow" x="-20%"
								y="-20%" width="140%" height="140%">
                                    <feGaussianBlur in="SourceAlpha"
								stdDeviation="1.5" />
                                    <feMerge>
                                        <feMergeNode in="offsetblur" />
                                        <feMergeNode in="SourceGraphic" />
                                    </feMerge>
                                </filter>
                            </defs>
                            <path
								d="M42 14C42 11.2386 39.7614 9 37 9H15C12.2386 9 10 11.2386 10 14V32C10 34.7614 12.2386 37 15 37H20L26 44L32 37H37C39.7614 37 42 34.7614 42 32V14Z"
								fill="url(#groupSidebarGrad)" stroke="rgba(255,255,255,0.5)"
								stroke-width="1.2" />
                            <path
								d="M29 18L21 26H25.5L23 34L33 23H27.5L29 18Z"
								fill="url(#groupSidebarBoltGrad)" stroke="rgba(255,215,0,0.6)"
								stroke-width="0.8" filter="url(#groupSidebarGlow)" />
                            <circle cx="32" cy="22" r="1.2"
								fill="#FCD34D" opacity="0.8" />
                            <circle cx="24" cy="30" r="1" fill="#F59E0B"
								opacity="0.7" />
                            <circle cx="35" cy="28" r="0.9"
								fill="#10B981" opacity="0.6" />
                        </svg>
					</div>
					<div class="sidebar-brand-text">
						<span class="sidebar-brand-name">QuickChat</span> <span
							class="sidebar-brand-tag">Groupes</span>
					</div>
				</div>
				<div class="profile-pic" onclick="toggleMenu()">
					<% if (user.getProfilePic() != null && !user.getProfilePic().isEmpty()) { %>
					<img
						src="<%= request.getContextPath() %>/uploads/<%= user.getProfilePic() %>"
						style="width: 100%; height: 100%; border-radius: 50%; object-fit: cover;">
					<% } else { %>
					<%= user.getInitial() %>
					<% } %>
				</div>
			</div>

			<div id="profileMenu" class="profile-menu" style="display: none;">
				<div class="profile-menu-item">
					<i class="fas fa-user"></i><span><%= user.getDisplayName() %></span>
				</div>
				<div class="profile-menu-item">
					<i class="fas fa-envelope"></i><span><%= user.getEmail() %></span>
				</div>
				<div class="profile-menu-divider"></div>
				<div class="profile-menu-item" onclick="showEditNameModal()">
					<i class="fas fa-pen"></i><span>Changer mon pseudo</span>
				</div>
				<div class="profile-menu-item"
					onclick="document.getElementById('profilePicInput').click();">
					<i class="fas fa-camera"></i><span>Changer ma photo</span>
				</div>
				<div class="profile-menu-divider"></div>
				<a href="logout" class="profile-menu-item logout-item"><i
					class="fas fa-sign-out-alt"></i><span>Se déconnecter</span></a>
			</div>

			<div class="search-bar">
				<div class="search-box">
					<i class="fas fa-search"></i><input type="text" id="searchInput"
						placeholder="Rechercher...">
				</div>
			</div>

			<div class="contacts-list">
				<div
					style="padding: 10px 18px 5px; font-size: 11px; font-weight: 600; color: var(--text-muted);">📋
					MES GROUPES</div>
				<%
                    List<Group> userGroupsList = groupDAO.getUserGroups(user.getId());
                    GroupMessageDAO groupMsgDAO = new GroupMessageDAO();
                    ConversationDAO convArchiveDAO = new ConversationDAO();
                    
                    for (Group g : userGroupsList) {
                        boolean isArchived = convArchiveDAO.isGroupArchived(user.getId(), g.getId());
                        if (!isArchived) {
                            int unreadCount = groupMsgDAO.countUnreadGroupMessages(g.getId(), user.getId());
                %>
				<a href="group-chat.jsp?groupId=<%= g.getId() %>"
					class="contact-item <%= (groupId == g.getId()) ? "active" : "" %>">
					<div class="contact-avatar">
						<i class="fas fa-users" style="font-size: 18px;"></i>
					</div>
					<div class="contact-info">
						<div class="contact-name"><%= g.getName() %></div>
						<div class="contact-preview">
							<span><%= g.getDescription() != null && !g.getDescription().isEmpty() ? g.getDescription() : "Groupe" %></span>
						</div>
					</div>
					<div class="contact-time">
						<% if (unreadCount > 0) { %><div class="unread-badge"><%= unreadCount %></div>
						<% } %>
					</div>
				</a>
				<%      }
                    } 
                    
                    boolean hasActiveGroup = false;
                    for (Group g : userGroupsList) {
                        if (!convArchiveDAO.isGroupArchived(user.getId(), g.getId())) {
                            hasActiveGroup = true;
                            break;
                        }
                    }
                    if (!hasActiveGroup) { %>
				<div
					style="padding: 15px 20px; text-align: center; color: var(--text-muted); font-size: 12px;">
					<i class="fas fa-users" style="margin-bottom: 5px; display: block;"></i>
					Aucun groupe actif
				</div>
				<% } %>

				<div
					style="padding: 15px 20px; border-top: 1px solid var(--border); margin-top: 10px;">
					<div style="font-weight: 600; margin-bottom: 5px;">
						👥 Membres (<%= members.size() %>)
					</div>
					<% for (User m : members) { 
                        String displayName = m.getDisplayName();
                        String customName = contactNameDAO.getCustomName(user.getId(), m.getId());
                        if (customName != null && !customName.isEmpty()) { displayName = customName; }
                        boolean isCreator = (group.getCreatedBy() == m.getId());
                        boolean isCurrentUser = (m.getId() == user.getId());
                        boolean isCurrentUserCreator = (group.getCreatedBy() == user.getId());
                    %>
					<div
						style="display: flex; align-items: center; justify-content: space-between; padding: 8px 0;">
						<div style="display: flex; align-items: center; gap: 10px;">
							<% if (m.getProfilePic() != null && !m.getProfilePic().isEmpty()) { %>
							<img
								src="<%= request.getContextPath() %>/uploads/<%= m.getProfilePic() %>"
								style="width: 32px; height: 32px; border-radius: 50%; object-fit: cover;">
							<% } else { %>
							<div
								style="width: 32px; height: 32px; border-radius: 50%; background: var(--grad-brand); display: flex; align-items: center; justify-content: center; color: white; font-size: 12px;"><%= m.getInitial() %></div>
							<% } %>
							<div>
								<div style="display: flex; align-items: center; gap: 6px;">
									<span><%= displayName %></span>
									<% if (isCreator) { %><span
										style="background: #10b981; color: white; font-size: 10px; padding: 2px 6px; border-radius: 20px;">👑
										Créateur</span>
									<% } %>
								</div>
								<div style="font-size: 10px; color: var(--text-muted);">
									@<%= m.getUsername() %></div>
							</div>
						</div>
						<div>
							<% if (isCurrentUser) { %>
							<button onclick="showLeaveGroupModal()"
								style="background: none; border: none; color: #ef4444; cursor: pointer; font-size: 12px; padding: 4px 8px; border-radius: 16px; background: rgba(239, 68, 68, 0.1);">
								<i class="fas fa-sign-out-alt"></i> Quitter
							</button>
							<% } else if (isCurrentUserCreator && !isCreator) { %>
							<button
								onclick="showRemoveMemberModal(<%= m.getId() %>, '<%= displayName.replace("'", "\\'") %>')"
								style="background: none; border: none; color: var(--text-muted); cursor: pointer; font-size: 12px; padding: 4px 8px; border-radius: 16px; transition: all 0.2s;"
								onmouseover="this.style.background='rgba(239, 68, 68, 0.1)'; this.style.color='#ef4444';"
								onmouseout="this.style.background='none'; this.style.color='var(--text-muted)';">
								<i class="fas fa-user-minus"></i> Exclure
							</button>
							<% } %>
						</div>
					</div>
					<% } %>
				</div>
			</div>

			<div
				style="padding: 12px 16px; border-top: 1px solid var(--border); margin-top: auto;">
				<div id="themeToggle"
					style="cursor: pointer; display: flex; align-items: center; justify-content: center; width: 38px; height: 38px; border-radius: 50%; background: var(--bg-input-msg); transition: all 0.2s; margin: 0 auto;"
					onmouseover="this.style.background='var(--violet)'; this.style.color='white';"
					onmouseout="this.style.background='var(--bg-input-msg)'; this.style.color='var(--text-primary)';"></div>
			</div>
		</div>

		<!-- Chat Area -->
		<div class="chat-area">
			<div class="chat-header" data-group-id="<%= groupId %>">
				<div class="chat-header-left">
					<div class="chat-header-avatar">
						<i class="fas fa-users"></i>
					</div>
					<div class="chat-header-info">
						<h3><%= group.getName() %></h3>
						<p><%= members.size() %>
							membres
						</p>
					</div>
				</div>
				<div class="chat-header-actions">
					<i class="fas fa-search" id="searchIcon" style="cursor: pointer;"></i>
					<i class="fas fa-palette" id="themeIcon" style="cursor: pointer;"
						onclick="showThemeModal()"></i> <i class="fas fa-user-plus"
						id="addMemberIcon" style="cursor: pointer;"
						onclick="showAddMemberModal()"></i>
					<%
                        ConversationDAO convDAO = new ConversationDAO();
                        boolean isArchived = convDAO.isGroupArchived(user.getId(), groupId);
                    %>
					<% if (isArchived) { %>
					<i class="fas fa-inbox" id="unarchiveGroupIcon"
						style="cursor: pointer;" title="Désarchiver le groupe"
						onclick="unarchiveGroup()"></i>
					<% } else { %>
					<i class="fas fa-archive" id="archiveGroupIcon"
						style="cursor: pointer;" title="Archiver le groupe"
						onclick="archiveGroup()"></i>
					<% } %>
					<i class="fas fa-trash-alt" id="deleteGroupIcon"
						style="cursor: pointer;" title="Supprimer la discussion"
						onclick="showDeleteGroupModal()"></i> <i class="fas fa-ellipsis-v"></i>
				</div>
			</div>

			<div id="searchBar"
				style="display: none; background: var(--bg-header); padding: 10px 16px; border-bottom: 1px solid var(--border);">
				<div style="display: flex; gap: 10px; align-items: center;">
					<i class="fas fa-search" style="color: var(--text-muted);"></i> <input
						type="text" id="searchInputChat"
						placeholder="Rechercher dans la conversation..."
						style="flex: 1; padding: 8px 12px; border: none; border-radius: 20px; background: var(--bg-input-msg); color: var(--text-primary); outline: none;">
					<div style="display: flex; gap: 5px; align-items: center;">
						<i class="fas fa-chevron-up" id="prevResult"
							style="cursor: pointer; color: var(--text-muted); padding: 5px;"></i>
						<span id="searchResults"
							style="font-size: 12px; color: var(--text-muted); min-width: 60px; text-align: center;"></span>
						<i class="fas fa-chevron-down" id="nextResult"
							style="cursor: pointer; color: var(--text-muted); padding: 5px;"></i>
					</div>
					<i class="fas fa-times" id="closeSearch"
						style="cursor: pointer; color: var(--text-muted);"></i>
				</div>
			</div>

			<div class="messages-container" id="messagesContainer">
				<%
                    GroupMessage pinnedGroupMessage = null;
                    if (groupId > 0) {
                        try { pinnedGroupMessage = groupMsgDAO.getPinnedMessage(groupId); } catch(Exception e) {}
                    }
                    if (pinnedGroupMessage != null) {
                %>
				<div class="pinned-message"
					style="position: sticky; top: 0; z-index: 10; background: var(--bg-input-msg); border-left: 3px solid #f59e0b; border-radius: 12px; padding: 10px 15px; margin-bottom: 15px; display: flex; align-items: center; justify-content: space-between; box-shadow: 0 2px 8px rgba(0, 0, 0, 0.05);">
					<div style="display: flex; align-items: center; gap: 10px;">
						<i class="fas fa-thumbtack"
							style="color: #f59e0b; transform: rotate(45deg);"></i>
						<div>
							<span style="font-size: 11px; color: #f59e0b; font-weight: bold;">Message
								épinglé</span>
							<div style="font-size: 13px; color: var(--text-primary);">
								<strong><%= pinnedGroupMessage.getSenderName() %></strong>:
								<%= pinnedGroupMessage.getContent() != null && pinnedGroupMessage.getContent().length() > 50 ? pinnedGroupMessage.getContent().substring(0, 50) + "..." : pinnedGroupMessage.getContent() %>
							</div>
						</div>
					</div>
					<a href="#"
						onclick="scrollToGroupMessage(<%= pinnedGroupMessage.getId() %>); return false;"
						style="font-size: 12px; color: var(--accent);">Voir le message</a>
				</div>
				<%
                    }
                %>

				<%
                    if (messages != null && !messages.isEmpty()) {
                        String lastDisplayedDateKey = "";
                        java.util.Date lastMessageDate = null;
                        
                        for (GroupMessage msg : messages) {
                            String formattedTime = "";
                            String fullDisplayDate = "";
                            boolean showSeparator = false;
                            
                            if (msg.getCreatedAt() != null && !msg.getCreatedAt().isEmpty()) {
                                try {
                                    java.text.SimpleDateFormat dbFormat = new java.text.SimpleDateFormat("yyyy-MM-dd HH:mm:ss");
                                    java.util.Date messageDate = dbFormat.parse(msg.getCreatedAt());
                                    java.util.Date now = new java.util.Date();
                                    java.text.SimpleDateFormat timeFormat = new java.text.SimpleDateFormat("HH:mm");
                                    formattedTime = timeFormat.format(messageDate);
                                    java.text.SimpleDateFormat dayKeyFormat = new java.text.SimpleDateFormat("yyyy-MM-dd");
                                    String currentDayKey = dayKeyFormat.format(messageDate);
                                    java.util.Calendar calMsg = java.util.Calendar.getInstance();
                                    java.util.Calendar calNow = java.util.Calendar.getInstance();
                                    calMsg.setTime(messageDate);
                                    calNow.setTime(now);
                                    boolean isNewDay = !currentDayKey.equals(lastDisplayedDateKey);
                                    
                                    if (isNewDay) {
                                        lastDisplayedDateKey = currentDayKey;
                                        showSeparator = true;
                                        if (calMsg.get(java.util.Calendar.YEAR) == calNow.get(java.util.Calendar.YEAR) && calMsg.get(java.util.Calendar.DAY_OF_YEAR) == calNow.get(java.util.Calendar.DAY_OF_YEAR)) {
                                            fullDisplayDate = "Aujourd'hui " + formattedTime;
                                        } else if (calMsg.get(java.util.Calendar.YEAR) == calNow.get(java.util.Calendar.YEAR) && calMsg.get(java.util.Calendar.DAY_OF_YEAR) == calNow.get(java.util.Calendar.DAY_OF_YEAR) - 1) {
                                            fullDisplayDate = "Hier " + formattedTime;
                                        } else if (calMsg.get(java.util.Calendar.YEAR) == calNow.get(java.util.Calendar.YEAR) && calNow.get(java.util.Calendar.DAY_OF_YEAR) - calMsg.get(java.util.Calendar.DAY_OF_YEAR) < 7) {
                                            String[] jours = {"Dim", "Lun", "Mar", "Mer", "Jeu", "Ven", "Sam"};
                                            fullDisplayDate = jours[calMsg.get(java.util.Calendar.DAY_OF_WEEK) - 1] + " " + formattedTime;
                                        } else if (calMsg.get(java.util.Calendar.YEAR) == calNow.get(java.util.Calendar.YEAR)) {
                                            String[] mois = {"Jan", "Fév", "Mar", "Avr", "Mai", "Juin", "Juil", "Août", "Sep", "Oct", "Nov", "Déc"};
                                            fullDisplayDate = calMsg.get(java.util.Calendar.DAY_OF_MONTH) + " " + mois[calMsg.get(java.util.Calendar.MONTH)] + " " + formattedTime;
                                        } else {
                                            String[] mois = {"Jan", "Fév", "Mar", "Avr", "Mai", "Juin", "Juil", "Août", "Sep", "Oct", "Nov", "Déc"};
                                            fullDisplayDate = calMsg.get(java.util.Calendar.DAY_OF_MONTH) + " " + mois[calMsg.get(java.util.Calendar.MONTH)] + " " + calMsg.get(java.util.Calendar.YEAR) + " " + formattedTime;
                                        }
                                    } else if (lastMessageDate != null) {
                                        long diffMs = messageDate.getTime() - lastMessageDate.getTime();
                                        long diffMinutes = diffMs / (60 * 1000);
                                        if (diffMinutes >= 60) {
                                            showSeparator = true;
                                            fullDisplayDate = formattedTime;
                                        }
                                    }
                                    lastMessageDate = messageDate;
                                } catch(Exception e) {}
                            }
                %>
				<% if (showSeparator && !fullDisplayDate.isEmpty()) { %>
				<div class="time-separator">
					<span><%= fullDisplayDate %></span>
				</div>
				<% } %>

				<div
					class="message <%= (msg.getSenderId() == user.getId()) ? "sent" : "received" %>"
					id="message-<%= msg.getId() %>">
					<% if (msg.getSenderId() != user.getId()) { %>
					<div class="message-avatar"
						onclick="openUserProfileModal(<%= msg.getSenderId() %>)"
						style="cursor: pointer;">
						<% 
                                        String senderProfilePic = "";
                                        try {
                                            java.sql.PreparedStatement stmt = DatabaseConnection.getConnection().prepareStatement("SELECT profile_pic FROM users WHERE id = ?");
                                            stmt.setInt(1, msg.getSenderId());
                                            java.sql.ResultSet rs = stmt.executeQuery();
                                            if (rs.next()) { senderProfilePic = rs.getString("profile_pic"); }
                                            rs.close(); stmt.close();
                                        } catch(Exception e) {}
                                    %>
						<% if (senderProfilePic != null && !senderProfilePic.isEmpty()) { %>
						<img
							src="<%= request.getContextPath() %>/uploads/<%= senderProfilePic %>"
							style="width: 36px; height: 36px; border-radius: 50%; object-fit: cover;">
						<% } else { %>
						<div
							style="width: 36px; height: 36px; border-radius: 50%; background: var(--grad-brand); display: flex; align-items: center; justify-content: center; color: white; font-size: 14px; font-weight: bold;">
							<%= msg.getSenderName() != null ? msg.getSenderName().substring(0, 1).toUpperCase() : "?" %>
						</div>
						<% } %>
					</div>
					<% } %>

					<div class="message-wrapper">
						<div class="message-bubble">
							<%
                                            GroupMessage repliedGroupMsg = null;
                                            if (msg.getReplyToMessageId() > 0) {
                                                try { repliedGroupMsg = groupMsgDAO.getMessageById(msg.getReplyToMessageId()); } catch(Exception e) {}
                                            }
                                            if (repliedGroupMsg != null) {
                                                String repliedContent = repliedGroupMsg.getContent();
                                                if (repliedContent == null || repliedContent.isEmpty()) repliedContent = "[Message sans texte]";
                                                if (repliedContent.length() > 60) repliedContent = repliedContent.substring(0, 60) + "...";
                                                String repliedName = repliedGroupMsg.getSenderName();
                                        %>
							<div class="replied-message-preview"
								style="background: rgba(0, 0, 0, 0.05); border-left: 3px solid var(--accent); padding: 6px 10px; margin-bottom: 8px; border-radius: 12px; font-size: 12px;">
								<span style="font-weight: bold; color: var(--accent);"><%= repliedName %></span>
								<div style="color: var(--text-muted); margin-top: 2px;"><%= repliedContent %></div>
							</div>
							<% } %>

							<% 
                                            boolean isDeletedForEveryone = msg.isDeletedForEveryone();
                                            if (isDeletedForEveryone) {
                                        %>
							<span class="deleted-message"><i class="fas fa-trash-alt"></i>
								<%= msg.getSenderName() %> a supprimé un message</span>
							<%
                                            } else {
                                                boolean isGif = msg.getFileType() != null && "gif".equals(msg.getFileType());
                                                boolean hasPhoto = msg.getFilePath() != null && !msg.getFilePath().isEmpty() && !isGif;
                                                boolean hasText = msg.getContent() != null && !msg.getContent().isEmpty();
                                                if (isGif && msg.getFilePath() != null) { 
                                        %>
							<div class="message-gif">
								<img src="<%= msg.getFilePath() %>" alt="GIF"
									onclick="openImageModal(this.src)"
									style="max-width: 200px; max-height: 200px; border-radius: 12px; cursor: pointer;">
							</div>
							<%
                                                }
                                                if (hasText && !"[GIF]".equals(msg.getContent())) { 
                                        %>
							<%= msg.getContent().replace("\n", "<br>") %>
							<%
                                                }
                                                if (hasPhoto) { 
                                        %>
							<div class="message-photo">
								<img
									src="<%= request.getContextPath() %>/<%= msg.getFilePath() %>"
									alt="Photo" onclick="openImageModal(this.src)"
									style="max-width: 200px; max-height: 200px; border-radius: 12px; cursor: pointer; margin-top: 5px;">
							</div>
							<%
                                                }
                                            }
                                        %>
						</div>

						<% if (!formattedTime.isEmpty()) { %>
						<div class="message-info">
							<span class="message-time"><%= formattedTime %></span> <span
								class="message-sender"><%= msg.getSenderName() %></span>
							<% if (msg.getCreatedAt() != null && msg.getUpdatedAt() != null && !msg.getCreatedAt().equals(msg.getUpdatedAt())) { %>
							<span class="edited-badge">(modifié)</span>
							<% } %>
						</div>
						<% } %>

						<div class="message-reactions" id="reactions-<%= msg.getId() %>">
							<%
                                            Map<String, Integer> reactions = reactionDAO.getReactionsForMessage(msg.getId());
                                            if (!reactions.isEmpty()) {
                                        %>
							<div class="reactions-bar">
								<% for (Map.Entry<String, Integer> entry : reactions.entrySet()) { 
                                                    String emoji = "";
                                                    if ("like".equals(entry.getKey())) emoji = "👍";
                                                    else if ("love".equals(entry.getKey())) emoji = "❤️";
                                                    else if ("laugh".equals(entry.getKey())) emoji = "😂";
                                                    else if ("wow".equals(entry.getKey())) emoji = "😮";
                                                    else if ("sad".equals(entry.getKey())) emoji = "😢";
                                                %>
								<span class="reaction-badge"
									onclick="toggleReaction(<%= msg.getId() %>, '<%= entry.getKey() %>', 0, <%= groupId %>)"><%= emoji %>
									<%= entry.getValue() %></span>
								<% } %>
							</div>
							<% } %>
						</div>

						<div class="message-actions">
							<div class="reaction-picker">
								<i class="far fa-smile-wink" onclick="return false;"></i>
								<div class="reaction-picker-popup">
									<span
										onclick="addReaction(<%= msg.getId() %>, 'like', 0, <%= groupId %>)">👍</span>
									<span
										onclick="addReaction(<%= msg.getId() %>, 'love', 0, <%= groupId %>)">❤️</span>
									<span
										onclick="addReaction(<%= msg.getId() %>, 'laugh', 0, <%= groupId %>)">😂</span>
									<span
										onclick="addReaction(<%= msg.getId() %>, 'wow', 0, <%= groupId %>)">😮</span>
									<span
										onclick="addReaction(<%= msg.getId() %>, 'sad', 0, <%= groupId %>)">😢</span>
								</div>
							</div>
							<% String safeContent = msg.getContent() != null ? msg.getContent().replace("'", "\\'").replace("\n", " ") : ""; %>
							<a href="#"
								onclick="replyToGroupMessage(<%= msg.getId() %>, '<%= safeContent %>', '<%= msg.getSenderName() %>'); return false;">💬
								Répondre</a> <a href="#"
								onclick="pinGroupMessage(<%= msg.getId() %>, <%= groupId %>); return false;">📌
								Épingler</a>
							<div class="delete-menu-wrapper">
								<a href="#" class="delete-trigger"
									onclick="toggleDeleteMenu(this); return false;">🗑️
									Supprimer</a>
								<div class="delete-menu" style="display: none;">
									<a href="#"
										onclick="deleteGroupMessage(<%= msg.getId() %>, <%= groupId %>, 'me'); return false;">📱
										Supprimer pour moi</a>
									<% if (msg.getSenderId() == user.getId()) { %>
									<a href="#"
										onclick="deleteGroupMessage(<%= msg.getId() %>, <%= groupId %>, 'everyone'); return false;">🌍
										Supprimer pour tout le monde</a>
									<% } %>
								</div>
							</div>
						</div>

						<div id="editGroupForm<%= msg.getId() %>" class="edit-form"
							style="display: none;">
							<form action="editGroupMessage" method="post">
								<input type="hidden" name="messageId" value="<%= msg.getId() %>">
								<input type="hidden" name="groupId" value="<%= groupId %>">
								<input type="text" name="content"
									value="<%= msg.getContent() != null ? msg.getContent() : "" %>">
								<button type="submit">OK</button>
								<button type="button"
									onclick="hideEditGroupForm(<%= msg.getId() %>)">Annuler</button>
							</form>
						</div>
					</div>
				</div>
				<% } 
                    } else { %>
				<div class="no-selection">
					<i class="fas fa-comments"
						style="font-size: 48px; margin-bottom: 15px; display: block;"></i>
					<p>Aucun message. Commencez la discussion !</p>
				</div>
				<% } %>
			</div>

			<div class="message-input-area">
				<input type="hidden" id="replyToGroupMessageId" value="">
				<div id="replyGroupPreview"
					style="display: none; background: var(--bg-input-msg); border-radius: 12px; padding: 8px 12px; margin-bottom: 8px; border-left: 3px solid var(--accent);">
					<div
						style="display: flex; justify-content: space-between; align-items: center;">
						<div>
							<span
								style="font-size: 11px; font-weight: bold; color: var(--accent);">Répondre
								à <span id="replyToGroupName"></span>
							</span>
							<div
								style="font-size: 12px; color: var(--text-muted); margin-top: 2px;"
								id="replyGroupPreviewContent"></div>
						</div>
						<button type="button" onclick="cancelGroupReply()"
							style="background: none; border: none; cursor: pointer; color: var(--text-muted); font-size: 18px;">&times;</button>
					</div>
				</div>

				<div class="emoji-picker-wrapper">
					<button type="button" class="emoji-trigger-btn"
						id="emojiTriggerBtn" title="Ajouter un emoji">
						<i class="fas fa-smile"></i>
					</button>
					<div class="emoji-picker-panel" id="emojiPickerPanel"></div>
				</div>

				<div class="gif-picker-wrapper">
					<button type="button" class="gif-trigger-btn" id="gifTriggerBtn"
						title="Ajouter un GIF">
						<i class="fas fa-file-image"></i><span
							style="font-size: 10px; font-weight: bold;">GIF</span>
					</button>
					<div class="gif-picker-panel" id="gifPickerPanel"
						style="display: none;">
						<div style="padding: 12px;">
							<div style="display: flex; gap: 8px; margin-bottom: 12px;">
								<input type="text" id="gifSearchInput"
									placeholder="Rechercher un GIF…"
									style="flex: 1; padding: 8px 12px; border: 1px solid var(--border); border-radius: 20px; background: var(--bg-input-msg); color: var(--text-primary); outline: none;">
								<button id="searchGifBtn"
									style="background: var(--violet); color: white; border: none; border-radius: 20px; padding: 8px 16px; cursor: pointer;">🔍</button>
							</div>
							<div id="gifResults"
								style="display: grid; grid-template-columns: repeat(2, 1fr); gap: 8px; max-height: 300px; overflow-y: auto; padding: 4px;"></div>
							<div style="margin-top: 8px; text-align: center;">
								<a href="#" onclick="loadTrendingGifs();return false;"
									style="font-size: 11px; color: var(--text-muted);">Tendances
									🔥</a>
							</div>
						</div>
					</div>
				</div>

				<div class="sticker-picker-wrapper">
					<button type="button" class="sticker-trigger-btn"
						id="stickerTriggerBtn" title="Stickers">
						<i class="fas fa-face-grin-stars" style="font-size: 18px;"></i>
					</button>
					<div class="sticker-picker-panel" id="stickerPickerPanel"
						style="display: none;">
						<div class="sticker-cats-header">
							<span class="sticker-cats-label">Catégories</span>
							<div class="sticker-cats-scroll">
								<button class="sticker-cat-pill active" data-cat="love">
									<span class="cat-icon">😻</span><span class="cat-name">Amour</span>
								</button>
								<button class="sticker-cat-pill" data-cat="happy">
									<span class="cat-icon">😄</span><span class="cat-name">Joyeux</span>
								</button>
								<button class="sticker-cat-pill" data-cat="sad">
									<span class="cat-icon">😿</span><span class="cat-name">Triste</span>
								</button>
								<button class="sticker-cat-pill" data-cat="funny">
									<span class="cat-icon">😂</span><span class="cat-name">Drôle</span>
								</button>
								<button class="sticker-cat-pill" data-cat="angry">
									<span class="cat-icon">😡</span><span class="cat-name">Colère</span>
								</button>
								<button class="sticker-cat-pill" data-cat="cool">
									<span class="cat-icon">😎</span><span class="cat-name">Cool</span>
								</button>
								<button class="sticker-cat-pill" data-cat="animal">
									<span class="cat-icon">🐾</span><span class="cat-name">Animaux</span>
								</button>
								<button class="sticker-cat-pill" data-cat="food">
									<span class="cat-icon">🍕</span><span class="cat-name">Food</span>
								</button>
							</div>
						</div>
						<div class="sticker-grid-wrapper">
							<div id="stickerGrid"
								style="display: grid; grid-template-columns: repeat(4, 1fr); gap: 8px; max-height: 260px; overflow-y: auto; scrollbar-width: thin;"></div>
						</div>
					</div>
				</div>

				<label for="photoInput" style="cursor: pointer;"><i
					class="fas fa-image"
					style="color: #a78bfa; font-size: 22px; cursor: pointer;"></i></label> <input
					type="file" id="photoInput" accept="image/*" style="display: none;">

				<form action="sendGroupMessage" method="post" id="messageForm"
					style="flex: 1; display: flex; gap: 10px;">
					<input type="hidden" name="groupId" value="<%= groupId %>">
					<input type="hidden" name="replyToMessageId"
						id="replyToGroupMessageIdInput" value=""> <input
						type="text" name="content" id="messageInput"
						placeholder="Écrivez votre message..." required autocomplete="off">
					<button type="submit">
						<i class="fas fa-paper-plane"></i>
					</button>
				</form>
			</div>
		</div>
	</div>

	<form action="uploadGroupPhoto" method="post"
		enctype="multipart/form-data" id="groupPhotoUploadForm"
		style="display: none;">
		<input type="hidden" name="groupId" id="groupPhotoGroupId"> <input
			type="text" name="caption" id="groupPhotoCaption"> <input
			type="file" name="photo" id="groupPhotoFileInput">
	</form>

	<!-- Modales -->
	<div id="editNameModal"
		style="display: none; position: fixed; top: 0; left: 0; width: 100%; height: 100%; background: rgba(0, 0, 0, 0.5); z-index: 1001; justify-content: center; align-items: center;">
		<div
			style="background: var(--bg-sidebar); padding: 30px; border-radius: 16px; width: 300px;">
			<h3>Changer mon pseudo</h3>
			<input type="text" id="newDisplayName" placeholder="Nouveau pseudo"
				style="width: 100%; padding: 10px; margin-bottom: 20px;">
			<div style="display: flex; gap: 10px;">
				<button onclick="updateDisplayName()">Enregistrer</button>
				<button onclick="closeNameModal()">Annuler</button>
			</div>
		</div>
	</div>

	<div id="forwardModal"
		style="display: none; position: fixed; top: 0; left: 0; width: 100%; height: 100%; background: rgba(0, 0, 0, 0.5); z-index: 1002; justify-content: center; align-items: center;">
		<div
			style="background: var(--bg-sidebar); padding: 30px; border-radius: 16px; width: 350px;">
			<h3>📤 Transférer le message</h3>
			<div
				style="background: var(--bg-input-msg); padding: 12px; border-radius: 12px; margin-bottom: 20px;">
				<p id="forwardMessagePreview"></p>
			</div>
			<select id="forwardContactSelect"
				style="width: 100%; padding: 10px; margin-bottom: 15px;">
				<option value="">-- Sélectionner un contact --</option>
				<% for (User u : members) { if (u.getId() != user.getId()) { %>
				<option value="<%= u.getId() %>"><%= u.getDisplayName() %></option>
				<% } } %>
			</select>
			<div style="display: flex; gap: 10px;">
				<button onclick="submitForward()">Transférer</button>
				<button onclick="closeForwardModal()">Annuler</button>
			</div>
		</div>
	</div>

	<div id="addMemberModal"
		style="display: none; position: fixed; top: 0; left: 0; width: 100%; height: 100%; background: rgba(0, 0, 0, 0.5); z-index: 1002; justify-content: center; align-items: center;">
		<div
			style="background: var(--bg-sidebar); border-radius: 24px; padding: 24px; width: 450px; max-height: 80vh; display: flex; flex-direction: column;">
			<h3>➕ Ajouter des membres</h3>
			<input type="text" id="searchUserInput"
				placeholder="Rechercher un utilisateur..."
				style="width: 100%; padding: 12px; border-radius: 24px; margin-bottom: 15px;">
			<div
				style="display: flex; gap: 10px; margin-bottom: 15px; border-bottom: 1px solid var(--border);">
				<button id="tabContactsBtn" onclick="switchTab('contacts')"
					style="flex: 1; background: none; border: none; padding: 10px; cursor: pointer; color: var(--violet); font-weight: 600; border-bottom: 2px solid var(--violet);">📇
					Tous les utilisateurs</button>
				<button id="tabSearchBtn" onclick="switchTab('search')"
					style="flex: 1; background: none; border: none; padding: 10px; cursor: pointer; color: var(--text-muted);">🔍
					Rechercher</button>
			</div>
			<div id="contactsList"
				style="max-height: 400px; overflow-y: auto; margin-bottom: 15px;">
				<% if (allUsers != null && !allUsers.isEmpty()) { 
                    for (User potentialMember : allUsers) { 
                        boolean isAlreadyMember = false;
                        for (User m : members) { if (m.getId() == potentialMember.getId()) { isAlreadyMember = true; break; } }
                        if (!isAlreadyMember) {
                %>
				<div
					style="display: flex; justify-content: space-between; align-items: center; padding: 12px; border-bottom: 1px solid var(--border);">
					<div style="display: flex; align-items: center; gap: 12px;">
						<% if (potentialMember.getProfilePic() != null && !potentialMember.getProfilePic().isEmpty()) { %>
						<img
							src="<%= request.getContextPath() %>/uploads/<%= potentialMember.getProfilePic() %>"
							style="width: 40px; height: 40px; border-radius: 50%; object-fit: cover;">
						<% } else { %>
						<div
							style="width: 40px; height: 40px; border-radius: 50%; background: var(--grad-brand); display: flex; align-items: center; justify-content: center; color: white; font-weight: bold;"><%= potentialMember.getInitial() %></div>
						<% } %>
						<div>
							<strong><%= potentialMember.getDisplayName() %></strong>
							<div style="font-size: 11px; color: var(--text-muted);">
								@<%= potentialMember.getUsername() %></div>
						</div>
					</div>
					<button
						onclick="addMemberWithFeedback(<%= potentialMember.getId() %>, '<%= potentialMember.getDisplayName().replace("'", "\\'") %>', this)"
						style="background: var(--violet); color: white; border: none; border-radius: 20px; padding: 6px 16px; cursor: pointer;">Ajouter</button>
				</div>
				<% } } } else { %>
				<div
					style="text-align: center; padding: 40px; color: var(--text-muted);">
					<i class="fas fa-user-friends"
						style="font-size: 40px; margin-bottom: 10px; display: block;"></i>Aucun
					autre utilisateur disponible
				</div>
				<% } %>
			</div>
			<div id="searchResultsDiv"
				style="max-height: 400px; overflow-y: auto; margin-bottom: 15px; display: none;"></div>
			<button onclick="closeAddMemberModal()"
				style="width: 100%; padding: 12px; border-radius: 24px; background: var(--bg-input-msg); border: none; cursor: pointer;">Fermer</button>
		</div>
	</div>

	<div id="leaveGroupModal"
		style="display: none; position: fixed; top: 0; left: 0; width: 100%; height: 100%; background: rgba(0, 0, 0, 0.5); z-index: 1003; justify-content: center; align-items: center;">
		<div
			style="background: var(--bg-sidebar); border-radius: 24px; padding: 24px; width: 350px; text-align: center;">
			<div style="font-size: 48px; margin-bottom: 16px;">🚪</div>
			<h3>Quitter le groupe</h3>
			<p style="margin-bottom: 24px;">
				Êtes-vous sûr de vouloir quitter "<%= group.getName() %>" ?
			</p>
			<div style="display: flex; gap: 12px; justify-content: center;">
				<button onclick="leaveGroup()"
					style="background: #ef4444; color: white; border: none; padding: 10px 24px; border-radius: 24px; cursor: pointer;">Oui,
					quitter</button>
				<button onclick="closeLeaveGroupModal()"
					style="background: var(--bg-input-msg); border: none; padding: 10px 24px; border-radius: 24px; cursor: pointer;">Annuler</button>
			</div>
		</div>
	</div>

	<div id="removeMemberModal"
		style="display: none; position: fixed; top: 0; left: 0; width: 100%; height: 100%; background: rgba(0, 0, 0, 0.5); z-index: 1003; justify-content: center; align-items: center;">
		<div
			style="background: var(--bg-sidebar); border-radius: 24px; padding: 24px; width: 350px; text-align: center;">
			<div style="font-size: 48px; margin-bottom: 16px;">⚠️</div>
			<h3>Exclure un membre</h3>
			<p style="margin-bottom: 24px;">
				Êtes-vous sûr de vouloir exclure <strong id="removeMemberName"></strong>
				du groupe ?
			</p>
			<div style="display: flex; gap: 12px; justify-content: center;">
				<button onclick="confirmRemoveMember()"
					style="background: #ef4444; color: white; border: none; padding: 10px 24px; border-radius: 24px; cursor: pointer;">Oui,
					exclure</button>
				<button onclick="closeRemoveMemberModal()"
					style="background: var(--bg-input-msg); border: none; padding: 10px 24px; border-radius: 24px; cursor: pointer;">Annuler</button>
			</div>
		</div>
	</div>

	<!-- Sélecteur de thème -->
	<div id="themeModal"
		style="display: none; position: fixed; top: 0; left: 0; width: 100%; height: 100%; background: rgba(0, 0, 0, 0.7); backdrop-filter: blur(8px); z-index: 1002; justify-content: center; align-items: center;">
		<div
			style="background: var(--bg-sidebar); border-radius: 28px; width: 500px; max-width: 90vw; max-height: 85vh; overflow-y: auto; box-shadow: 0 25px 50px rgba(0, 0, 0, 0.3);">
			<div
				style="padding: 20px 24px 12px; border-bottom: 1px solid var(--border);">
				<h3 style="font-size: 20px; font-weight: 800;">🎨 Personnaliser
					la discussion</h3>
				<p>Choisissez un thème pour cette conversation</p>
			</div>
			<div
				style="padding: 20px 24px; display: grid; grid-template-columns: repeat(2, 1fr); gap: 16px;">
				<div onclick="selectGroupTheme('default')"
					class="theme-preview-card" data-theme="default"
					style="cursor: pointer; border-radius: 20px; overflow: hidden; border: 2px solid var(--border);">
					<div style="height: 120px; background: #eef0f8; padding: 12px;">
						<div
							style="background: white; border-radius: 18px; padding: 8px 12px; width: 80%; margin-bottom: 8px;">
							<span>Message reçu</span>
						</div>
						<div
							style="background: linear-gradient(135deg, #7c3aed, #2563eb); border-radius: 18px; padding: 8px 12px; width: 70%; margin-left: auto; color: white;">
							<span>Message envoyé</span>
						</div>
					</div>
					<div style="padding: 10px; text-align: center;">
						<span>Défaut</span>
					</div>
				</div>
				<div onclick="selectGroupTheme('ocean')" class="theme-preview-card"
					data-theme="ocean"
					style="cursor: pointer; border-radius: 20px; overflow: hidden; border: 2px solid var(--border);">
					<div style="height: 120px; background: #e0f7fa; padding: 12px;">
						<div
							style="background: rgba(255, 255, 255, 0.9); border-radius: 18px; padding: 8px 12px; width: 80%; margin-bottom: 8px;">
							<span>Bonjour !</span>
						</div>
						<div
							style="background: linear-gradient(135deg, #0891b2, #155e75); border-radius: 18px; padding: 8px 12px; width: 70%; margin-left: auto; color: white;">
							<span>Salut ! 👋</span>
						</div>
					</div>
					<div style="padding: 10px; text-align: center;">
						<span>🌊 Océan</span>
					</div>
				</div>
				<div onclick="selectGroupTheme('rose')" class="theme-preview-card"
					data-theme="rose"
					style="cursor: pointer; border-radius: 20px; overflow: hidden; border: 2px solid var(--border);">
					<div style="height: 120px; background: #fff1f2; padding: 12px;">
						<div
							style="background: rgba(255, 255, 255, 0.9); border-radius: 18px; padding: 8px 12px; width: 80%; margin-bottom: 8px;">
							<span>💕 Coucou</span>
						</div>
						<div
							style="background: linear-gradient(135deg, #e11d48, #9d174d); border-radius: 18px; padding: 8px 12px; width: 70%; margin-left: auto; color: white;">
							<span>❤️ Je t'aime</span>
						</div>
					</div>
					<div style="padding: 10px; text-align: center;">
						<span>💕 Amour</span>
					</div>
				</div>
				<div onclick="selectGroupTheme('forest')" class="theme-preview-card"
					data-theme="forest"
					style="cursor: pointer; border-radius: 20px; overflow: hidden; border: 2px solid var(--border);">
					<div style="height: 120px; background: #ecfdf5; padding: 12px;">
						<div
							style="background: rgba(255, 255, 255, 0.9); border-radius: 18px; padding: 8px 12px; width: 80%; margin-bottom: 8px;">
							<span>🌿 Bonjour</span>
						</div>
						<div
							style="background: linear-gradient(135deg, #059669, #065f46); border-radius: 18px; padding: 8px 12px; width: 70%; margin-left: auto; color: white;">
							<span>🍃 Salut</span>
						</div>
					</div>
					<div style="padding: 10px; text-align: center;">
						<span>🌲 Forêt</span>
					</div>
				</div>
				<div onclick="selectGroupTheme('sunset')" class="theme-preview-card"
					data-theme="sunset"
					style="cursor: pointer; border-radius: 20px; overflow: hidden; border: 2px solid var(--border);">
					<div style="height: 120px; background: #fff7ed; padding: 12px;">
						<div
							style="background: rgba(255, 255, 255, 0.9); border-radius: 18px; padding: 8px 12px; width: 80%; margin-bottom: 8px;">
							<span>🌅 Bonsoir</span>
						</div>
						<div
							style="background: linear-gradient(135deg, #f97316, #dc2626); border-radius: 18px; padding: 8px 12px; width: 70%; margin-left: auto; color: white;">
							<span>✨ Magnifique</span>
						</div>
					</div>
					<div style="padding: 10px; text-align: center;">
						<span>🌅 Coucher de soleil</span>
					</div>
				</div>
				<div onclick="selectGroupTheme('midnight')"
					class="theme-preview-card" data-theme="midnight"
					style="cursor: pointer; border-radius: 20px; overflow: hidden; border: 2px solid var(--border);">
					<div style="height: 120px; background: #eff6ff; padding: 12px;">
						<div
							style="background: rgba(255, 255, 255, 0.9); border-radius: 18px; padding: 8px 12px; width: 80%; margin-bottom: 8px;">
							<span>🌙 Bonne nuit</span>
						</div>
						<div
							style="background: linear-gradient(135deg, #1e40af, #2563eb); border-radius: 18px; padding: 8px 12px; width: 70%; margin-left: auto; color: white;">
							<span>⭐ Étoiles</span>
						</div>
					</div>
					<div style="padding: 10px; text-align: center;">
						<span>🌙 Nuit étoilée</span>
					</div>
				</div>
				<div onclick="selectGroupTheme('aurora')" class="theme-preview-card"
					data-theme="aurora"
					style="cursor: pointer; border-radius: 20px; overflow: hidden; border: 2px solid var(--border);">
					<div
						style="height: 120px; background: linear-gradient(145deg, #fdf4ff, #e0e7ff); padding: 12px;">
						<div
							style="background: rgba(255, 255, 255, 0.9); border-radius: 18px; padding: 8px 12px; width: 80%; margin-bottom: 8px;">
							<span>✨ Magique</span>
						</div>
						<div
							style="background: linear-gradient(145deg, #06b6d4, #8b5cf6, #ec4899); border-radius: 18px; padding: 8px 12px; width: 70%; margin-left: auto; color: white;">
							<span>🌈 Aurore</span>
						</div>
					</div>
					<div style="padding: 10px; text-align: center;">
						<span>✨ Aurore boréale</span>
					</div>
				</div>
				<div onclick="selectGroupTheme('cherry')" class="theme-preview-card"
					data-theme="cherry"
					style="cursor: pointer; border-radius: 20px; overflow: hidden; border: 2px solid var(--border);">
					<div style="height: 120px; background: #fdf2f8; padding: 12px;">
						<div
							style="background: rgba(255, 255, 255, 0.9); border-radius: 18px; padding: 8px 12px; width: 80%; margin-bottom: 8px;">
							<span>🌸 Bonjour</span>
						</div>
						<div
							style="background: linear-gradient(135deg, #f472b6, #db2777); border-radius: 18px; padding: 8px 12px; width: 70%; margin-left: auto; color: white;">
							<span>🌺 Kawaii</span>
						</div>
					</div>
					<div style="padding: 10px; text-align: center;">
						<span>🌸 Cerisier</span>
					</div>
				</div>
				<div onclick="selectGroupTheme('cosmic')" class="theme-preview-card"
					data-theme="cosmic"
					style="cursor: pointer; border-radius: 20px; overflow: hidden; border: 2px solid var(--border);">
					<div style="height: 120px; background: #0f0f23; padding: 12px;">
						<div
							style="background: rgba(255, 255, 255, 0.15); border-radius: 18px; padding: 8px 12px; width: 80%; margin-bottom: 8px;">
							<span style="color: white;">🔮 Cosmos</span>
						</div>
						<div
							style="background: linear-gradient(135deg, #a855f7, #5b21b6); border-radius: 18px; padding: 8px 12px; width: 70%; margin-left: auto; color: white;">
							<span>🌌 Galaxie</span>
						</div>
					</div>
					<div style="padding: 10px; text-align: center;">
						<span>🌌 Cosmique</span>
					</div>
				</div>
				<div onclick="selectGroupTheme('golden')" class="theme-preview-card"
					data-theme="golden"
					style="cursor: pointer; border-radius: 20px; overflow: hidden; border: 2px solid var(--border);">
					<div style="height: 120px; background: #fffbeb; padding: 12px;">
						<div
							style="background: rgba(255, 255, 255, 0.9); border-radius: 18px; padding: 8px 12px; width: 80%; margin-bottom: 8px;">
							<span>✨ Luxe</span>
						</div>
						<div
							style="background: linear-gradient(135deg, #d97706, #92400e); border-radius: 18px; padding: 8px 12px; width: 70%; margin-left: auto; color: white;">
							<span>💛 Doré</span>
						</div>
					</div>
					<div style="padding: 10px; text-align: center;">
						<span>✨ Doré</span>
					</div>
				</div>
				<div onclick="selectGroupTheme('basketball')"
					class="theme-preview-card" data-theme="basketball"
					style="cursor: pointer; border-radius: 20px; overflow: hidden; border: 2px solid var(--border);">
					<div style="height: 120px; background: #fff7ed; padding: 12px;">
						<div
							style="background: rgba(255, 255, 255, 0.9); border-radius: 18px; padding: 8px 12px; width: 80%; margin-bottom: 8px;">
							<span>🏀 Match ce soir ?</span>
						</div>
						<div
							style="background: linear-gradient(135deg, #f97316, #c2410c); border-radius: 18px; padding: 8px 12px; width: 70%; margin-left: auto; color: white;">
							<span>💪 Dunk !</span>
						</div>
					</div>
					<div style="padding: 10px; text-align: center;">
						<span>🏀 Basketball</span>
					</div>
				</div>
			</div>
			<div
				style="padding: 16px 24px 24px; border-top: 1px solid var(--border);">
				<button onclick="closeThemeModal()"
					style="width: 100%; padding: 12px; background: #e0e0e0; border: none; border-radius: 40px; cursor: pointer;">Fermer</button>
			</div>
		</div>
	</div>

	<form action="uploadProfilePic" method="post"
		enctype="multipart/form-data" id="uploadForm" style="display: none;">
		<input type="file" id="profilePicInput" name="profilePic"
			accept="image/*" onchange="this.form.submit();">
	</form>

	<div id="createGroupBtn" onclick="openCreateGroupModal()"
		style="cursor: pointer; display: flex; align-items: center; justify-content: center; width: 38px; height: 38px; border-radius: 50%; background: var(--bg-input-msg); transition: all 0.2s;"
		onmouseover="this.style.background='var(--violet)'; this.style.color='white';"
		onmouseout="this.style.background='var(--bg-input-msg)'; this.style.color='var(--text-primary)';">
		<i class="fas fa-users" style="font-size: 18px;"></i>
	</div>

	<div id="createGroupModal"
		style="display: none; position: fixed; top: 0; left: 0; width: 100%; height: 100%; background: rgba(0, 0, 0, 0.7); backdrop-filter: blur(8px); z-index: 2000; justify-content: center; align-items: center;">
		<div
			style="background: var(--bg-sidebar); border-radius: 28px; width: 450px; max-width: 90vw; box-shadow: 0 25px 50px rgba(0, 0, 0, 0.3);">
			<div style="padding: 24px;">
				<div style="text-align: center; margin-bottom: 20px;">
					<div style="width: 48px; height: 48px; margin: 0 auto;">
						<svg viewBox="0 0 52 52" fill="none" width="48" height="48">
							<path
								d="M42 14C42 11.2386 39.7614 9 37 9H15C12.2386 9 10 11.2386 10 14V32C10 34.7614 12.2386 37 15 37H20L26 44L32 37H37C39.7614 37 42 34.7614 42 32V14Z"
								fill="url(#grad)" stroke="rgba(255,255,255,0.5)"
								stroke-width="1.2" />
							<defs>
							<linearGradient id="grad" x1="0%" y1="0%" x2="100%" y2="100%">
							<stop offset="0%" stop-color="#8B5CF6" />
							<stop offset="100%" stop-color="#10B981" /></linearGradient></defs></svg>
					</div>
					<h3 style="margin-top: 12px; font-size: 22px; font-weight: 700;">Créer
						un groupe</h3>
					<p style="color: var(--text-muted); font-size: 13px;">Créez un
						espace pour discuter en groupe</p>
				</div>
				<form id="createGroupForm" action="createGroup" method="post"
					style="display: flex; flex-direction: column; gap: 16px;">
					<input type="text" name="groupName" placeholder="Nom du groupe"
						required
						style="width: 100%; padding: 12px; border: 1px solid var(--border); border-radius: 24px; background: var(--bg-input-msg); color: var(--text-primary); outline: none;">
					<textarea name="description" placeholder="Description (optionnel)"
						rows="3"
						style="width: 100%; padding: 12px; border: 1px solid var(--border); border-radius: 20px; background: var(--bg-input-msg); color: var(--text-primary); outline: none; resize: none;"></textarea>
					<button type="submit"
						style="background: var(--violet); color: white; border: none; padding: 12px; border-radius: 40px; font-weight: 600; cursor: pointer;">Créer
						le groupe</button>
				</form>
				<div style="margin-top: 16px; text-align: center;">
					<button onclick="closeCreateGroupModal()"
						style="background: none; border: none; color: var(--text-muted); cursor: pointer; font-size: 14px;">
						<i class="fas fa-times"></i> Annuler
					</button>
				</div>
			</div>
		</div>
	</div>

	<div id="userProfileModal"
		style="display: none; position: fixed; top: 0; left: 0; width: 100%; height: 100%; background: rgba(0, 0, 0, 0.7); backdrop-filter: blur(8px); z-index: 2000; justify-content: center; align-items: center;">
		<div
			style="background: var(--bg-sidebar); border-radius: 32px; width: 380px; max-width: 90vw; box-shadow: 0 25px 50px rgba(0, 0, 0, 0.3);">
			<div style="position: absolute; top: 16px; right: 16px;">
				<button onclick="closeUserProfileModal()"
					style="background: var(--bg-input-msg); border: none; border-radius: 50%; width: 36px; height: 36px; cursor: pointer; color: var(--text-muted);">
					<i class="fas fa-times"></i>
				</button>
			</div>
			<div style="padding: 32px 24px 24px; text-align: center;">
				<div style="margin-bottom: 20px;">
					<div id="profileModalAvatar"
						style="width: 140px; height: 140px; margin: 0 auto; border-radius: 50%; background: var(--grad-brand); display: flex; align-items: center; justify-content: center; color: white; font-size: 48px; font-weight: bold; box-shadow: 0 8px 28px rgba(37, 96, 224, .3); border: 4px solid rgba(255, 255, 255, 0.9); overflow: hidden;"></div>
				</div>
				<h2 id="profileModalName"
					style="font-family: 'Syne', sans-serif; font-size: 22px; font-weight: 700; color: var(--text-primary); margin-bottom: 6px;"></h2>
				<div id="profileModalAdminBadge"
					style="display: none; margin-bottom: 10px;">
					<span
						style="background: linear-gradient(135deg, #f59e0b, #d97706); color: white; font-size: 12px; padding: 4px 12px; border-radius: 20px; display: inline-flex; align-items: center; gap: 6px;"><i
						class="fas fa-crown"></i> Administrateur</span>
				</div>
				<p id="profileModalUsername"
					style="font-size: 14px; color: var(--text-muted); margin-bottom: 16px;"></p>
				<div style="height: 1px; background: var(--border); margin: 20px 0;"></div>
				<div id="profileModalAddedByDiv"
					style="display: flex; align-items: center; justify-content: center; gap: 8px; margin-bottom: 12px;">
					<i class="fas fa-user-plus"
						style="color: var(--accent); font-size: 14px;"></i><span
						style="font-size: 13px; color: var(--text-secondary);">Ajouté
						par</span><span id="profileModalAddedBy"
						style="font-size: 13px; font-weight: 500; color: var(--text-primary);"></span>
				</div>
				<div
					style="display: flex; align-items: center; justify-content: center; gap: 8px;">
					<i class="fas fa-calendar-alt"
						style="color: var(--accent); font-size: 14px;"></i><span
						style="font-size: 13px; color: var(--text-secondary);">Membre
						depuis</span><span id="profileModalMemberSince"
						style="font-size: 13px; font-weight: 500; color: var(--text-primary);"></span>
				</div>
				<button onclick="closeUserProfileModal()"
					style="width: 100%; margin-top: 28px; padding: 12px; background: var(--bg-input-msg); border: 1px solid var(--border); border-radius: 40px; cursor: pointer;">Fermer</button>
			</div>
		</div>
	</div>

	<div id="archiveGroupModal"
		style="display: none; position: fixed; top: 0; left: 0; width: 100%; height: 100%; background: rgba(0, 0, 0, 0.5); z-index: 1003; justify-content: center; align-items: center;">
		<div
			style="background: var(--bg-sidebar); border-radius: 28px; padding: 28px; width: 380px; text-align: center;">
			<div style="font-size: 56px; margin-bottom: 16px;">📦</div>
			<h3>Archiver le groupe</h3>
			<p>
				Le groupe "<%= group.getName() %>" sera déplacé dans les archives.
			</p>
			<div
				style="display: flex; gap: 12px; justify-content: center; margin-top: 20px;">
				<button onclick="confirmArchiveGroup()"
					style="background: var(--violet); color: white; border: none; padding: 10px 24px; border-radius: 40px;">Archiver</button>
				<button onclick="closeArchiveGroupModal()"
					style="background: var(--bg-input-msg); border: none; padding: 10px 24px; border-radius: 40px;">Annuler</button>
			</div>
		</div>
	</div>

	<div id="deleteGroupConvModal"
		style="display: none; position: fixed; top: 0; left: 0; width: 100%; height: 100%; background: rgba(0, 0, 0, 0.5); z-index: 1003; justify-content: center; align-items: center;">
		<div
			style="background: var(--bg-sidebar); border-radius: 28px; padding: 28px; width: 380px; text-align: center;">
			<div style="font-size: 56px; margin-bottom: 16px;">🗑️</div>
			<h3>Supprimer la discussion ?</h3>
			<p>
				Tous les messages seront supprimés <strong>uniquement pour
					vous</strong>.
			</p>
			<div
				style="display: flex; gap: 12px; justify-content: center; margin-top: 20px;">
				<button onclick="confirmDeleteGroupConv()"
					style="background: #ef4444; color: white; border: none; padding: 10px 24px; border-radius: 40px;">Supprimer</button>
				<button onclick="closeDeleteGroupConvModal()"
					style="background: var(--bg-input-msg); border: none; padding: 10px 24px; border-radius: 40px;">Annuler</button>
			</div>
		</div>
	</div>

	<script>
    
        function openCreateGroupModal() { document.getElementById('createGroupModal').style.display = 'flex'; }
        function closeCreateGroupModal() { document.getElementById('createGroupModal').style.display = 'none'; }
        document.addEventListener('DOMContentLoaded', function() { var btn = document.getElementById('createGroupBtn'); if(btn) btn.onclick = function(e) { e.preventDefault(); e.stopPropagation(); openCreateGroupModal(); return false; }; });
        function toggleMenu() { var menu = document.getElementById('profileMenu'); if(menu) menu.style.display = menu.style.display === 'none' ? 'block' : 'none'; }
        document.addEventListener('click', function(e) { var menu = document.getElementById('profileMenu'); var pic = document.querySelector('.profile-pic'); if(menu && pic && !pic.contains(e.target) && !menu.contains(e.target)) menu.style.display = 'none'; });
        function scrollToBottom() { var container = document.getElementById('messagesContainer'); if(container) container.scrollTop = container.scrollHeight; } scrollToBottom();
        function showEditGroupMessageForm(messageId, content) { var form = document.getElementById('editGroupForm' + messageId); if(form) form.style.display = 'block'; }
        function hideEditGroupForm(messageId) { var form = document.getElementById('editGroupForm' + messageId); if(form) form.style.display = 'none'; }
        function deleteGroupMessage(messageId, groupId, type) { var form = document.createElement('form'); form.method = 'POST'; form.action = 'deleteGroupMessage'; var i1=document.createElement('input'); i1.type='hidden'; i1.name='messageId'; i1.value=messageId; var i2=document.createElement('input'); i2.type='hidden'; i2.name='groupId'; i2.value=groupId; var i3=document.createElement('input'); i3.type='hidden'; i3.name='type'; i3.value=type; form.appendChild(i1); form.appendChild(i2); form.appendChild(i3); document.body.appendChild(form); form.submit(); }
        function toggleSearchBar() { var bar = document.getElementById('searchBar'); if(bar) bar.style.display = bar.style.display === 'none' ? 'block' : 'none'; }
        var searchIcon = document.getElementById('searchIcon'); if(searchIcon) searchIcon.addEventListener('click', toggleSearchBar);
        function addMemberWithFeedback(userId, userName, btn) { btn.innerHTML = '<i class="fas fa-spinner fa-spin"></i>'; btn.disabled = true; var form = document.createElement('form'); form.method='POST'; form.action='addGroupMember'; var i1=document.createElement('input'); i1.type='hidden'; i1.name='groupId'; i1.value=<%= groupId %>; var i2=document.createElement('input'); i2.type='hidden'; i2.name='userId'; i2.value=userId; form.appendChild(i1); form.appendChild(i2); document.body.appendChild(form); form.submit(); }
        var currentTab = 'contacts';
        function switchTab(tab) { currentTab = tab; var contactsBtn=document.getElementById('tabContactsBtn'); var searchBtn=document.getElementById('tabSearchBtn'); var contactsDiv=document.getElementById('contactsList'); var searchDiv=document.getElementById('searchResultsDiv'); var searchInput=document.getElementById('searchUserInput'); if(tab==='contacts'){ contactsBtn.style.color='var(--violet)'; contactsBtn.style.borderBottom='2px solid var(--violet)'; searchBtn.style.color='var(--text-muted)'; searchBtn.style.borderBottom='none'; contactsDiv.style.display='block'; searchDiv.style.display='none'; searchInput.placeholder='Rechercher un utilisateur...'; searchInput.value=''; searchDiv.innerHTML=''; } else { searchBtn.style.color='var(--violet)'; searchBtn.style.borderBottom='2px solid var(--violet)'; contactsBtn.style.color='var(--text-muted)'; contactsBtn.style.borderBottom='none'; contactsDiv.style.display='none'; searchDiv.style.display='block'; searchInput.placeholder='Rechercher un utilisateur...'; searchInput.value=''; searchDiv.innerHTML='<div style="text-align: center; padding: 20px;">🔍 Tapez au moins 2 caractères pour rechercher</div>'; } }
        function showAddMemberModal() { document.getElementById('addMemberModal').style.display = 'flex'; currentTab='contacts'; var contactsBtn=document.getElementById('tabContactsBtn'); var searchBtn=document.getElementById('tabSearchBtn'); var contactsDiv=document.getElementById('contactsList'); var searchDiv=document.getElementById('searchResultsDiv'); var searchInput=document.getElementById('searchUserInput'); contactsBtn.style.color='var(--violet)'; contactsBtn.style.borderBottom='2px solid var(--violet)'; searchBtn.style.color='var(--text-muted)'; searchBtn.style.borderBottom='none'; contactsDiv.style.display='block'; searchDiv.style.display='none'; searchInput.placeholder='Rechercher un utilisateur...'; searchInput.value=''; searchDiv.innerHTML=''; }
        function closeAddMemberModal() { document.getElementById('addMemberModal').style.display = 'none'; }
        var searchTimeout; var searchUserInput = document.getElementById('searchUserInput'); if(searchUserInput){ searchUserInput.addEventListener('keyup', function(){ clearTimeout(searchTimeout); var keyword = this.value.trim(); var searchDiv = document.getElementById('searchResultsDiv'); if(currentTab === 'search'){ if(keyword.length < 2){ if(searchDiv) searchDiv.innerHTML = '<div style="text-align: center; padding: 20px;">🔍 Tapez au moins 2 caractères pour rechercher</div>'; return; } searchTimeout = setTimeout(function(){ fetch('searchUsers?keyword=' + encodeURIComponent(keyword) + '&groupId=<%= groupId %>').then(r=>r.json()).then(data=>{ if(!searchDiv) return; if(data.length===0){ searchDiv.innerHTML='<div style="text-align: center; padding: 20px;">😕 Aucun utilisateur trouvé</div>'; return; } var html=''; for(var i=0;i<data.length;i++){ var u=data[i]; var picHtml=''; if(u.profilePic && u.profilePic!=='') picHtml='<img src="uploads/'+u.profilePic+'" style="width:40px;height:40px;border-radius:50%;object-fit:cover;">'; else picHtml='<div style="width:40px;height:40px;border-radius:50%;background:var(--grad-brand);display:flex;align-items:center;justify-content:center;color:white;font-weight:bold;">'+(u.username?u.username.charAt(0).toUpperCase():'?')+'</div>'; html+='<div style="display:flex;justify-content:space-between;align-items:center;padding:12px;border-bottom:1px solid var(--border);"><div style="display:flex;align-items:center;gap:12px;">'+picHtml+'<div><strong>'+u.username+'</strong></div></div><button onclick="addMemberWithFeedback('+u.id+', \''+u.username.replace(/'/g,"\\'")+'\', this)" style="background:var(--violet);color:white;border:none;border-radius:20px;padding:6px 16px;cursor:pointer;">Ajouter</button></div>'; } searchDiv.innerHTML=html; }).catch(err=>{ console.error(err); if(searchDiv) searchDiv.innerHTML='<div style="text-align:center;padding:20px;color:red;">Erreur de recherche</div>'; }); },300); } }); }
        function showEditNameModal() { document.getElementById('editNameModal').style.display = 'flex'; }
        function closeNameModal() { document.getElementById('editNameModal').style.display = 'none'; }
        function updateDisplayName() { var newName = document.getElementById('newDisplayName').value; if(!newName.trim()){ alert('Veuillez entrer un pseudo'); return; } var form=document.createElement('form'); form.method='POST'; form.action='updateDisplayName'; var input=document.createElement('input'); input.type='hidden'; input.name='displayName'; input.value=newName; form.appendChild(input); document.body.appendChild(form); form.submit(); }
        var forwardMessageId = null;
        function showForwardModal(messageId, content, groupId) { forwardMessageId = messageId; document.getElementById('forwardMessagePreview').innerHTML = content; document.getElementById('forwardModal').style.display = 'flex'; }
        function closeForwardModal() { document.getElementById('forwardModal').style.display = 'none'; }
        function submitForward() { var select = document.getElementById('forwardContactSelect'); var receiverId = select.value; if(!receiverId){ alert('Sélectionnez un destinataire'); return; } var form=document.createElement('form'); form.method='POST'; form.action='forwardMessage'; var i1=document.createElement('input'); i1.type='hidden'; i1.name='messageId'; i1.value=forwardMessageId; var i2=document.createElement('input'); i2.type='hidden'; i2.name='receiverId'; i2.value=receiverId; form.appendChild(i1); form.appendChild(i2); document.body.appendChild(form); form.submit(); }
        function addReaction(messageId, reaction, receiverId, groupId) {
            fetch('reaction', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/x-www-form-urlencoded',
                },
                body: 'messageId=' + encodeURIComponent(messageId) + 
                      '&receiverId=' + encodeURIComponent(receiverId) + 
                      '&reaction=' + encodeURIComponent(reaction) + 
                      '&action=add'
            })
            .then(response => response.text())
            .then(data => {
                setTimeout(function() {
                    location.reload();
                }, 200);
            })
            .catch(error => {
                console.error('Erreur:', error);
            });
            
            return false;
        }

        function toggleReaction(messageId, reaction, receiverId, groupId) {
            addReaction(messageId, reaction, receiverId, groupId);
            return false;
        }
        function toggleReaction(messageId, reaction, receiverId, groupId) { addReaction(messageId, reaction, receiverId, groupId); }
        function showReactionPicker(element) { var popup = element.querySelector('.reaction-picker-popup'); if(popup) popup.style.display = 'flex'; }
        function hideReactionPickerDelayed(element) { setTimeout(function(){ var popup = element.querySelector('.reaction-picker-popup'); if(popup) popup.style.display = 'none'; },300); }
        function hideReactionPicker(element) { var popup = element.parentElement.querySelector('.reaction-picker-popup'); if(popup) popup.style.display = 'none'; }
        function cancelHideReactionPicker() {}
        function toggleDeleteMenu(element) { var menu = element.nextElementSibling; if(menu) menu.style.display = menu.style.display === 'block' ? 'none' : 'block'; }
        function openImageModal(src) { var modal = document.createElement('div'); modal.style.position='fixed'; modal.style.top='0'; modal.style.left='0'; modal.style.width='100%'; modal.style.height='100%'; modal.style.backgroundColor='rgba(0,0,0,0.9)'; modal.style.zIndex='2000'; modal.style.display='flex'; modal.style.alignItems='center'; modal.style.justifyContent='center'; modal.style.cursor='pointer'; var img=document.createElement('img'); img.src=src; img.style.maxWidth='90%'; img.style.maxHeight='90%'; modal.appendChild(img); modal.onclick=function(){ document.body.removeChild(modal); }; document.body.appendChild(modal); }
        var memberToRemove = null;
        function showLeaveGroupModal() { document.getElementById('leaveGroupModal').style.display = 'flex'; }
        function closeLeaveGroupModal() { document.getElementById('leaveGroupModal').style.display = 'none'; }
        function leaveGroup() { var form=document.createElement('form'); form.method='POST'; form.action='leaveGroup'; var input=document.createElement('input'); input.type='hidden'; input.name='groupId'; input.value=<%= groupId %>; form.appendChild(input); document.body.appendChild(form); form.submit(); }
        function showRemoveMemberModal(userId, userName) { memberToRemove = userId; document.getElementById('removeMemberName').innerHTML = userName; document.getElementById('removeMemberModal').style.display = 'flex'; }
        function closeRemoveMemberModal() { document.getElementById('removeMemberModal').style.display = 'none'; memberToRemove = null; }
        function confirmRemoveMember() { if(!memberToRemove) return; var form=document.createElement('form'); form.method='POST'; form.action='removeGroupMember'; var i1=document.createElement('input'); i1.type='hidden'; i1.name='groupId'; i1.value=<%= groupId %>; var i2=document.createElement('input'); i2.type='hidden'; i2.name='userId'; i2.value=memberToRemove; form.appendChild(i1); form.appendChild(i2); document.body.appendChild(form); form.submit(); }
        function applyGroupTheme(theme) { const themes=['default','ocean','rose','forest','midnight','sunset','aurora','cherry','cosmic','golden','basketball']; themes.forEach(t=>{ document.body.classList.remove('theme-'+t); }); document.body.classList.add('theme-'+theme); var gid=<%= groupId %>; fetch('updateGroupTheme',{method:'POST',headers:{'Content-Type':'application/x-www-form-urlencoded'},body:'groupId='+gid+'&theme='+theme}).then(res=>{ if(res.ok){ closeThemeModal(); setTimeout(function(){ window.location.reload(); },500); } }); }
        function selectGroupTheme(theme) { document.querySelectorAll('.theme-preview-card').forEach(card=>{ card.classList.toggle('active',card.getAttribute('data-theme')===theme); }); applyGroupTheme(theme); }
        function showThemeModal() { var modal = document.getElementById('themeModal'); if(modal){ modal.style.display='flex'; var currentTheme = document.body.className.match(/theme-([a-z-]+)/); currentTheme = currentTheme ? currentTheme[1] : 'default'; document.querySelectorAll('.theme-preview-card').forEach(card=>{ card.classList.toggle('active',card.getAttribute('data-theme')===currentTheme); }); } }
        function closeThemeModal() { var modal = document.getElementById('themeModal'); if(modal) modal.style.display = 'none'; }
        function showArchiveGroupModal() { var modal = document.getElementById('archiveGroupModal'); if(modal) modal.style.display = 'flex'; }
        function closeArchiveGroupModal() { var modal = document.getElementById('archiveGroupModal'); if(modal) modal.style.display = 'none'; }
        function archiveGroup() { showArchiveGroupModal(); }
        function confirmArchiveGroup() { var gid=<%= groupId %>; fetch('archiveGroup',{method:'POST',headers:{'Content-Type':'application/x-www-form-urlencoded'},body:'groupId='+gid}).then(res=>{ if(res.ok) window.location.href='chat.jsp?archived=success'; }); }
        function showDeleteGroupModal() { var modal = document.getElementById('deleteGroupConvModal'); if(modal) modal.style.display = 'flex'; }
        function closeDeleteGroupConvModal() { var modal = document.getElementById('deleteGroupConvModal'); if(modal) modal.style.display = 'none'; }
        function confirmDeleteGroupConv() { var gid=<%= groupId %>; fetch('deleteGroupConversation',{method:'POST',headers:{'Content-Type':'application/x-www-form-urlencoded'},body:'groupId='+gid}).then(res=>{ if(res.ok) window.location.href='chat.jsp?deleted=success'; }); }
        function restoreGroupConversation() { var gid=<%= groupId %>; if(confirm("Voulez-vous restaurer cette discussion ?")) fetch('restoreGroupConversation',{method:'POST',headers:{'Content-Type':'application/x-www-form-urlencoded'},body:'groupId='+gid}).then(res=>{ if(res.ok) window.location.reload(); }); }
        function unarchiveGroup() { var gid=<%= groupId %>; if(confirm("Voulez-vous désarchiver ce groupe ?")) fetch('unarchiveGroup',{method:'POST',headers:{'Content-Type':'application/x-www-form-urlencoded'},body:'groupId='+gid}).then(res=>{ if(res.ok) window.location.href='chat.jsp?unarchived=success'; }); }
        let gifPickerVisible = false;
        document.addEventListener('DOMContentLoaded', function() { var gifTrigger = document.getElementById('gifTriggerBtn'); var gifPanel = document.getElementById('gifPickerPanel'); var searchBtn = document.getElementById('searchGifBtn'); var searchInput = document.getElementById('gifSearchInput'); if(gifTrigger && gifPanel){ gifTrigger.addEventListener('click',function(e){ e.stopPropagation(); gifPickerVisible=!gifPickerVisible; gifPanel.style.display=gifPickerVisible?'block':'none'; if(gifPickerVisible) loadTrendingGifs(); }); } if(searchBtn){ searchBtn.addEventListener('click',function(){ var q = searchInput ? searchInput.value.trim() : ''; if(q) searchGifs(q); else loadTrendingGifs(); }); } if(searchInput){ searchInput.addEventListener('keypress',function(e){ if(e.key==='Enter'){ var q=this.value.trim(); if(q) searchGifs(q); else loadTrendingGifs(); } }); } document.addEventListener('click',function(e){ if(gifPanel && gifPickerVisible){ if(gifTrigger && !gifTrigger.contains(e.target) && !gifPanel.contains(e.target)){ gifPanel.style.display='none'; gifPickerVisible=false; } } }); });
        function loadTrendingGifs() { var api='tQcwxW98yKeti6Wq5b5Zc2WEHtPeoequ'; var resultsDiv=document.getElementById('gifResults'); if(!resultsDiv) return; resultsDiv.innerHTML='<div style="text-align:center;padding:20px;"><i class="fas fa-spinner fa-spin"></i> Chargement...</div>'; fetch('https://api.giphy.com/v1/gifs/trending?api_key='+api+'&limit=20&rating=g').then(r=>r.json()).then(data=>{ if(data.data && data.data.length>0) displayGifs(data.data); else resultsDiv.innerHTML='<div style="text-align:center;padding:20px;">Aucun GIF</div>'; }).catch(()=>{ resultsDiv.innerHTML='<div style="text-align:center;padding:20px;">Erreur</div>'; }); }
        function searchGifs(q) { var api='tQcwxW98yKeti6Wq5b5Zc2WEHtPeoequ'; var resultsDiv=document.getElementById('gifResults'); if(!resultsDiv) return; resultsDiv.innerHTML='<div style="text-align:center;padding:20px;"><i class="fas fa-spinner fa-spin"></i> Recherche...</div>'; fetch('https://api.giphy.com/v1/gifs/search?api_key='+api+'&q='+encodeURIComponent(q)+'&limit=20&rating=g').then(r=>r.json()).then(data=>{ if(data.data && data.data.length>0) displayGifs(data.data); else resultsDiv.innerHTML='<div style="text-align:center;padding:20px;">Aucun GIF</div>'; }).catch(()=>{ resultsDiv.innerHTML='<div style="text-align:center;padding:20px;">Erreur</div>'; }); }
        function displayGifs(gifs) { var resultsDiv=document.getElementById('gifResults'); if(!resultsDiv) return; var html=''; for(var i=0;i<gifs.length;i++){ var url=gifs[i].images.fixed_height_small.url; html+='<div style="cursor:pointer; margin:4px; display:inline-block; width:calc(50% - 8px);" onclick="sendGroupGif(\''+url.replace(/'/g,"\\'")+'\')"><img src="'+url+'" style="width:100%; border-radius:12px;"></div>'; } resultsDiv.innerHTML=html; }
        function sendGroupGif(gifUrl) { var gid=<%= groupId %>; var form=document.createElement('form'); form.method='POST'; form.action='sendGroupGif'; form.style.display='none'; var i1=document.createElement('input'); i1.type='hidden'; i1.name='groupId'; i1.value=gid; var i2=document.createElement('input'); i2.type='hidden'; i2.name='gifUrl'; i2.value=gifUrl; form.appendChild(i1); form.appendChild(i2); document.body.appendChild(form); form.submit(); }
        var groupPhotoInput = document.getElementById('photoInput'); if(groupPhotoInput){ groupPhotoInput.addEventListener('change',function(e){ var file=e.target.files[0]; if(file){ var gid=<%= groupId %>; var caption=document.getElementById('messageInput')?document.getElementById('messageInput').value:''; var pgid=document.getElementById('groupPhotoGroupId'); var gcap=document.getElementById('groupPhotoCaption'); var gfile=document.getElementById('groupPhotoFileInput'); var form=document.getElementById('groupPhotoUploadForm'); if(!pgid || !gcap || !gfile || !form){ alert("Erreur technique"); return; } pgid.value=gid; gcap.value=caption; var dt=new DataTransfer(); dt.items.add(file); gfile.files=dt.files; form.submit(); } }); }
        var currentGroupReplyMessageId = null;
        function replyToGroupMessage(messageId, content, senderName) { currentGroupReplyMessageId = messageId; document.getElementById('replyGroupPreview').style.display='block'; document.getElementById('replyToGroupName').innerText=senderName; var previewText=content.length>60?content.substring(0,60)+"...":content; document.getElementById('replyGroupPreviewContent').innerText=previewText; document.getElementById('replyToGroupMessageId').value=messageId; document.getElementById('replyToGroupMessageIdInput').value=messageId; document.getElementById('messageInput').focus(); }
        function cancelGroupReply() { currentGroupReplyMessageId=null; document.getElementById('replyGroupPreview').style.display='none'; document.getElementById('replyToGroupMessageId').value=''; document.getElementById('replyToGroupMessageIdInput').value=''; }
        function pinGroupMessage(messageId, groupId) { fetch('pinGroupMessage',{method:'POST',headers:{'Content-Type':'application/x-www-form-urlencoded'},body:'messageId='+messageId+'&groupId='+groupId}).then(res=>{ if(res.ok) location.reload(); else alert('Erreur lors de l\'épinglage'); }); }
        function scrollToGroupMessage(messageId) { var el=document.getElementById('message-'+messageId); if(el){ el.scrollIntoView({behavior:'smooth',block:'center'}); el.style.backgroundColor='rgba(245,158,11,0.2)'; setTimeout(function(){ el.style.backgroundColor=''; },2000); } }
        function openUserProfileModal(userId) { fetch('getUserProfile?userId='+userId).then(r=>r.json()).then(data=>{ if(data.success){ var avatar=document.getElementById('profileModalAvatar'); if(data.profilePic && data.profilePic!=='') avatar.innerHTML='<img src="<%= request.getContextPath() %>/uploads/'+data.profilePic+'" style="width:100%;height:100%;border-radius:50%;object-fit:cover;">'; else avatar.innerHTML=data.initial; document.getElementById('profileModalName').textContent=data.displayName; document.getElementById('profileModalUsername').textContent='@'+data.username; document.getElementById('profileModalMemberSince').textContent=data.memberSince; fetch('getGroupMemberInfo?groupId=<%= groupId %>&userId='+userId).then(r=>r.json()).then(md=>{ if(md.success){ var adminBadge=document.getElementById('profileModalAdminBadge'); var addedDiv=document.getElementById('profileModalAddedByDiv'); if(md.isCreator){ adminBadge.style.display='block'; if(addedDiv) addedDiv.style.display='none'; }else{ adminBadge.style.display='none'; if(addedDiv) addedDiv.style.display='flex'; document.getElementById('profileModalAddedBy').textContent=md.addedBy||'Membre'; } } }); document.getElementById('userProfileModal').style.display='flex'; } }); }
        function closeUserProfileModal() { document.getElementById('userProfileModal').style.display='none'; }
        document.addEventListener('click',function(e){ var modal=document.getElementById('userProfileModal'); if(e.target===modal) closeUserProfileModal(); });
        var stickerPickerVisible=false;
        var stickerTriggerBtn=document.getElementById('stickerTriggerBtn');
        var stickerPickerPanel=document.getElementById('stickerPickerPanel');
        var stickerGrid=document.getElementById('stickerGrid');
        var currentStickerCat='love';
        var stickerCategories={ love:{name:'Amour',keyword:'love cute sticker kiss'}, happy:{name:'Joyeux',keyword:'happy celebration sticker excited'}, sad:{name:'Triste',keyword:'sad crying broken heart sticker'}, funny:{name:'Drôle',keyword:'funny lol laughing sticker meme'}, angry:{name:'Colère',keyword:'angry mad frustrated sticker'}, cool:{name:'Cool',keyword:'cool sunglasses dancing sticker'}, animal:{name:'Animaux',keyword:'cute cat dog animal sticker'}, food:{name:'Food',keyword:'pizza burger food sticker'} };
        if(stickerTriggerBtn && stickerPickerPanel){ stickerTriggerBtn.addEventListener('click',function(e){ e.stopPropagation(); stickerPickerVisible=!stickerPickerVisible; stickerPickerPanel.style.display=stickerPickerVisible?'block':'none'; if(stickerPickerVisible) loadGroupStickers('love'); }); }
        document.addEventListener('click',function(e){ if(stickerPickerPanel && stickerPickerVisible){ if(!stickerPickerPanel.contains(e.target) && !stickerTriggerBtn.contains(e.target)){ stickerPickerPanel.style.display='none'; stickerPickerVisible=false; } } });
        document.querySelectorAll('.sticker-cat-pill').forEach(function(btn){ btn.addEventListener('click',function(e){ e.stopPropagation(); document.querySelectorAll('.sticker-cat-pill').forEach(function(b){ b.classList.remove('active'); }); this.classList.add('active'); currentStickerCat=this.getAttribute('data-cat'); loadGroupStickers(currentStickerCat); }); });
        function loadGroupStickers(cat){ if(!stickerGrid) return; var api='tQcwxW98yKeti6Wq5b5Zc2WEHtPeoequ'; var catData=stickerCategories[cat]; if(!catData) return; stickerGrid.innerHTML='<div style="text-align:center;padding:20px;"><i class="fas fa-spinner fa-spin"></i> Chargement...</div>'; fetch('https://api.giphy.com/v1/stickers/search?api_key='+api+'&q='+encodeURIComponent(catData.keyword)+'&limit=20&rating=g').then(r=>r.json()).then(data=>{ if(data.data && data.data.length>0){ var html=''; for(var i=0;i<data.data.length;i++){ var url=data.data[i].images.fixed_height_small.url; html+='<div class="sticker-item" onclick="sendGroupSticker(\''+url.replace(/'/g,"\\'")+'\')"><img src="'+url+'" style="width:60px;height:60px;border-radius:12px;"></div>'; } stickerGrid.innerHTML=html; }else{ stickerGrid.innerHTML='<div style="text-align:center;padding:20px;">Aucun sticker</div>'; } }).catch(()=>{ stickerGrid.innerHTML='<div style="text-align:center;padding:20px;">Erreur chargement</div>'; }); }
        function sendGroupSticker(stickerUrl){ var gid=<%= groupId %>; fetch('sendGroupGif',{method:'POST',headers:{'Content-Type':'application/x-www-form-urlencoded'},body:'groupId='+gid+'&gifUrl='+encodeURIComponent(stickerUrl)}).then(res=>{ if(res.ok) location.reload(); else alert('Erreur lors de l\'envoi du sticker'); }).catch(err=>{ console.error(err); alert('Erreur lors de l\'envoi'); }); stickerPickerPanel.style.display='none'; stickerPickerVisible=false; }
   
        </script>
</body>
</html>